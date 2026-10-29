import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../theme/typography.dart';
import '../../../utils/pressable.dart';
import '../../../utils/squircle.dart';
import 'theme_card_metrics.dart';

/// 竖向预览卡片（明暗双模式）。
///
/// 结构 = 圆角预览图 + 下方左对齐标题（几何规格见 [MiThemeCardMetrics]，
/// 标题样式见 [MiTypography.cardTitle]）：
///
///  * [preview] 按 [previewAspectRatio]（默认
///    [MiThemeCardMetrics.imageAspectRatio]，259:472）定比铺满图区 ——
///    宽随父级（需置于 `Expanded` / `SizedBox` 等有界容器，两侧皆无界会抛
///    AspectRatio 约束错误），圆角 [MiThemeCardMetrics.previewRadius]；
///  * 标题单行省略，相对图左缘内缩 [MiThemeCardMetrics.titleIndent]
///    （与区块标题同列起排），与图间距 [MiThemeCardMetrics.titleTopGap]；
///  * 标题墨色经 `MiColors.foregroundFor` 取框架前景色。
///
/// [themeMode] 为空时跟随环境 `Theme.of(context).brightness`；[onTap]
/// 为空则不参与手势（无按压 / 悬停视觉反馈）。
///
/// [previewAspectRatio] 是**横版变体**的入口：手机竖屏按度量值走竖版
/// 海报比例，桌面（低视口高、宽卡片）换成横版（如 16:10）才能在同样高度
/// 里多排一行 —— 竖版卡在 1366×768 的一屏只放得下 1.4 行。
///
/// ## 悬停快捷操作（桌面）
///
/// [quickActions] 非空时，指针悬停会在预览图**底部**滑出一条操作条
/// （黑 @45% 底 + 调用方给的按钮），移出后滑回。语义：
///
///  * **只在悬停时出现**，静止态零像素变化（黄金图不受影响）；
///  * 滑入滑出用 `AnimatedSlide`（Transform，**不引 saveLayer**）——
///    操作条压在预览图上，若用 `Opacity` 淡入，含 `BackdropFilter` 的
///    子树会被 saveLayer 清空底图（本项目已实测的坑）；预览图自身虽无
///    磨砂，但整卡常被顶栏的磨砂盖住，保持同一套约束最稳；
///  * 条内按钮的点按**不冒泡**到卡片的 [onTap]（操作与「打开」是两件事，
///    由调用方在回调里自行处理）。
class MiThemeCard extends StatefulWidget {
  const MiThemeCard({
    super.key,
    required this.title,
    required this.preview,
    this.onTap,
    this.themeMode,
    this.previewAspectRatio = MiThemeCardMetrics.imageAspectRatio,
    this.quickActions,
  }) : assert(previewAspectRatio > 0);

  /// 卡片标题（单行，超宽省略）。
  final String title;

  /// 锁屏预览内容，按图片区宽高比铺满并裁圆角。
  final Widget preview;

  /// 点按回调；null = 不参与手势。
  final VoidCallback? onTap;

  /// 明暗模式；null = 跟随环境 Theme 亮度。
  final MiThemeMode? themeMode;

  /// 预览区宽高比（宽 / 高）；默认取度量值 259:472。
  final double previewAspectRatio;

  /// 悬停快捷操作（桌面）：悬停时在预览图底部滑出的操作条内容。
  ///
  /// null 或空 = 不显示操作条（手机档 / 无悬停语义的场景）。操作条高度
  /// 取 [MiThemeCardMetrics.quickActionsHeight]，按钮由调用方自备
  /// （建议 `MiButton` 尺寸的一半或图标钮 —— 操作条只有 ~36dp 高）。
  final List<Widget>? quickActions;

  @override
  State<MiThemeCard> createState() => _MiThemeCardState();
}

class _MiThemeCardState extends State<MiThemeCard> {
  /// 悬停态（由 [MiHoverFeedback.onHoverChanged] 驱动，只维护一份）。
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final mode = widget.themeMode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    final actions = widget.quickActions;
    final hasActions = actions != null && actions.isNotEmpty;

    // 预览图区：可选的悬停操作条叠在底部（裁在图区圆角内）。
    Widget previewArea = AspectRatio(
      aspectRatio: widget.previewAspectRatio,
      child: ClipPath(
        clipper:
            const MiSquircleClipper(MiThemeCardMetrics.previewRadius),
        child: hasActions
            ? Stack(
                fit: StackFit.expand,
                children: [
                  widget.preview,
                  // 操作条：贴底、随悬停滑入滑出（Transform，无 saveLayer）。
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      // 未悬停时整体不吃点击（滑出状态在图区外，但仍要挡命中）。
                      ignoring: !_hovered,
                      child: AnimatedSlide(
                        offset: _hovered ? Offset.zero : const Offset(0, 1),
                        duration: const Duration(
                          milliseconds:
                              MiThemeCardMetrics.quickActionsSlideMs,
                        ),
                        curve: Curves.easeOutCubic,
                        child: _QuickActionsBar(
                          mode: mode,
                          children: actions,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : widget.preview,
      ),
    );

    final card = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 预览图：宽随父级、按比例定高（AspectRatio 给子级 tight 约束，
        // 任意 preview 都铺满）；ClipRRect 单层裁切 AA（preview 是任意
        // 内容，不能像纯色填充那样借 Decoration 自带圆角）。
        previewArea,
        Padding(
          padding: const EdgeInsets.only(
            left: MiThemeCardMetrics.titleIndent,
            top: MiThemeCardMetrics.titleTopGap,
          ),
          child: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MiTypography.cardTitle.copyWith(
              color: MiColors.foregroundFor(mode),
            ),
          ),
        ),
      ],
    );
    if (widget.onTap == null) return card;
    // 三态反馈统一入口：悬停叠色（兼驱动快捷条）+ Tab 焦点环 + Enter /
    // Space 激活 —— 焦点为**推导**的桌面语义，静止态零像素（环与叠色
    // 未激活时全透明，黄金图零变化）。
    return MiPressable(
      onPressed: widget.onTap,
      mode: mode,
      borderRadius: BorderRadius.circular(MiThemeCardMetrics.previewRadius),
      // 悬停态同时驱动操作条（回调里 setState；结构恒定，只改 offset）。
      onHoverChanged: hasActions
          ? (hovered) {
              if (hovered != _hovered) setState(() => _hovered = hovered);
            }
          : null,
      child: card,
    );
  }
}

/// 悬停快捷操作条本体：黑 @45% 底（[MiTransparencyTokens.
/// cardQuickActionsScrim]）+ 一行按钮。
///
/// 高度 [MiThemeCardMetrics.quickActionsHeight]，按钮水平居中、间距
/// [MiThemeCardMetrics.quickActionsGap]。底色是**实色**（一次普通绘制），
/// 不引 saveLayer。
class _QuickActionsBar extends StatelessWidget {
  const _QuickActionsBar({required this.mode, required this.children});

  final MiThemeMode mode;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MiThemeCardMetrics.quickActionsHeight,
      color: MiTransparencyTokens.cardQuickActionsScrim,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                const SizedBox(width: MiThemeCardMetrics.quickActionsGap),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
