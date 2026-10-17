import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../icons/nav_icons.dart';
import '../../../theme/top_bar_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/typography.dart';
import 'top_bar_metrics.dart';

/// 小米「大标题折叠」顶部导航栏（深/浅色双模式）。
///
/// **材质**（磨砂 + 叠色）实测自亮色「我的」页录屏，**折叠几何**（大标题 /
/// 紧凑标题 / 返回圆钮）实测自 HyperOS 设置「显示与亮度」页录屏 ——
/// 几何见 [MiTopBarMetrics]，材质 / 配色见 `theme/top_bar_tokens.dart`。
///
/// ## 材质：渐进磨砂（不是纯色遮罩）
///
/// 顶栏 = **backdrop 高斯模糊**（σ 沿 y 递减：[MiTopBarPalette.blurSigma]
/// 5.37dp 起，到 119dp 归零）+ **叠色** [MiTopBarPalette.scrimGradient]。
/// 栏顶全强度模糊、越往下越锐利，119dp 以下完全清晰。
///
/// 实现是 **8 段定 σ 阶梯**（[MiTopBarPalette.blurBands]）：每段
/// `ClipRect → BackdropFilter(σ_i)`，σ_i 取实测 σ(y) 曲线在该段中点的值。
/// Flutter 没有"位置相关模糊"，而唯一的替代（渐变 `ShaderMask` / `Opacity`
/// 削弱模糊层）会引入新的 saveLayer 并把 backdrop 变空 —— 实测遮罩 alpha
/// 恒 1 时模糊正常，一旦出现 <1 的 alpha 模糊**整段消失**。因此只能分段
/// 近似：段高 ≤ 17dp、相邻 σ 比 ≤ 1.5，台阶肉眼不可见。
///
/// ⚠️ 上一版曾判定"顶栏是纯色遮罩、无 backdrop 模糊"，该结论**已废弃**：
/// 当时的证据（沿蓝卡做纵向取样得亮度斜坡、卡片下缘 3px 硬跳变）都取自
/// 模糊带**之下**的平坦色块 —— 平坦区在模糊下亮度不变、且本来就在带外，
/// 无法区分"有模糊"与"无模糊"。本轮改用**高频内容**（头像照片 / 圆角方块
/// 的竖直边缘）才测出模糊。
///
/// ## 折叠行为（实测，非套用 iOS/Material 惯例）
///
///  * **大标题属于滚动内容**：其质心位移与列表滚动位移逐帧相等，即随内容
///    1:1 上移（不是钉在栏上缩小）；
///  * 大标题在此之上还有一条**独立淡出曲线**（位移 ≈20dp 内归零），
///    紧凑标题在大标题归零后才开始淡入（≈20→27.4dp），两段不重叠；
///  * 返回圆钮按压反馈 = ⌀44.1 圆盘、白 @9.4%，0.42s easeOut 淡入 /
///    0.3s 淡出。
///
/// ## 用法
///
/// 本组件**不自带滚动**，由宿主提供当前滚动位移（受控组件，与
/// [MiPillTabBar] 的 `selectedIndex` 同风格），叠在滚动内容之上：
///
/// ```dart
/// Stack(children: [
///   ListView(controller: _c, padding: const EdgeInsets.only(
///     top: MiTopBarMetrics.contentTopInset), children: [...]),
///   Positioned(top: 0, left: 0, right: 0,
///     child: MiTopBar(title: '显示与亮度', scrollOffset: _offset, onBack: ...)),
/// ])
/// ```
///
/// **纯材质形态**：参考录屏（亮色「我的」页）的顶栏**不内嵌任何组件** ——
/// 传 `title: null` 即只有磨砂 + 叠色，不绘制标题，组件高度收到
/// [MiTopBarMetrics.scrimHeight]：
///
/// ```dart
/// Positioned(top: 0, left: 0, right: 0, child: MiTopBar())
/// ```
///
/// ⚠️ **必须用 `Positioned` 钉在顶部**（或保证外层给出的是紧约束）。若把它
/// 留作外层 `Stack` 的**非定位子级**，该 `Stack` 就会按它收缩成 393×152.8
/// 而不是撑满，一旦再处于 loose 约束的上级里（如 `Center`、
/// `AnimatedSwitcher` 内部那个 `alignment: center` 的 `Stack`），整页会被
/// 居中到屏幕正中：顶栏跑到屏幕中间、页底与滚动内容只剩 152.8dp 高。
/// 2026-10-16 实机截图实测该偏移 = (856 − 152.8) / 2 = 351.6dp。
///
/// 磨砂层只覆盖顶部 [MiTopBarMetrics.scrimHeight]，其下内容照常透出。
/// 除返回圆钮外整体不参与手势，滚动内容可从顶栏下方正常拖动。
///
/// **坐标原点 = 屏幕顶端**：实测几何已包含 [MiTopBarMetrics.statusBarHeight]
/// 的状态栏让位，宿主把它铺在屏幕顶部即可，顶部不要再叠加 `SafeArea` 内边距
/// （否则整体会下移、大标题与圆钮的实测垂心失效）。
///
/// [themeMode] 为空时跟随环境 `Theme.of(context).brightness`。
///
/// **返回圆钮默认不显示**（顶层页无返回，如参考截图「设置」首页）：需要时
/// 传 `showBack: true`，其可点性再由 [onBack] 决定（null = 只显示、不可点）。
///
/// 两条标题都用 `Baseline`（alphabetic）把**基线钉到实测反推的目标值**
/// （见 [MiTopBarMetrics.titleBaselineY]），使墨心落点不随字体族的
/// ascent/descent 漂移（详见 metrics 类文档）。
class MiTopBar extends StatelessWidget {
  const MiTopBar({
    super.key,
    this.title,
    this.showBack = false,
    this.onBack,
    this.themeMode,
    this.scrollOffset = 0,
  }) : assert(scrollOffset >= 0, 'scrollOffset 不能为负（未滚动时传 0）');

  /// 标题文案（大标题与紧凑标题同源）。
  ///
  /// **null = 纯材质形态**：不内嵌任何组件，只画磨砂 + 叠色
  /// （与参考录屏「我的」页的顶栏一致）。
  final String? title;

  /// 是否显示返回圆钮（默认 false —— 顶层页无返回）。
  final bool showBack;

  /// 返回回调；仅在 [showBack] 为 true 时生效。
  /// null = 圆钮只显示、不可点（不参与手势、无按压反馈）。
  final VoidCallback? onBack;

  /// 明暗模式；null = 跟随环境 Theme 亮度。
  final MiThemeMode? themeMode;

  /// 当前滚动位移（dp，非负）；驱动大标题上移 + 淡出、紧凑标题淡入。
  final double scrollOffset;

  @override
  Widget build(BuildContext context) {
    final mode = themeMode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    final palette = MiTopBarPalette.of(mode);
    final title = this.title;
    // 位移兜底：NaN / 负数按未滚动处理，+∞ 饱和为折叠完成态（避免布局出现
    // 无限坐标，同时语义上「滚过头」就是折叠态）。
    final offset = scrollOffset.isNaN || scrollOffset <= 0
        ? 0.0
        : (scrollOffset.isFinite
            ? scrollOffset
            : MiTopBarMetrics.collapsedOffset);
    final largeSize = MiTypography.topBarLargeTitle.fontSize!;
    final compactSize = MiTypography.topBarCompactTitle.fontSize!;
    // 基线落点：`Baseline` 会在布局期把标题基线放到「距组件顶端 N 处」，
    // 与字体 ascent/descent 无关 —— 这是本组件对齐录屏的关键（用 `height`
    // 或 strut 都做不到：前者按比例缩放、后者本 SDK 没有 ascent/descent）。
    final largeTitleBaseline = MiTopBarMetrics.titleBaselineY(
      MiTopBarMetrics.largeTitleInkCenterY,
      largeSize,
    );
    final compactTitleBaseline = MiTopBarMetrics.titleBaselineY(
      MiTopBarMetrics.compactTitleInkCenterY,
      compactSize,
    );

    return SizedBox(
      // 有标题时到大标题墨心 + 一整行（够高不裁标题）；纯材质形态只需盖住
      // 遮罩盒本身。遮罩之外的部分保持透明。
      height: title == null
          ? MiTopBarMetrics.scrimHeight
          : MiTopBarMetrics.componentHeight(largeSize),
      width: double.infinity,
      child: Stack(
        children: [
          // 1) 磨砂：按实测 σ(y) 曲线分段，每段一个定 σ 的 backdrop 模糊。
          //    （不能用一个渐变的 ShaderMask / Opacity 去调强度 —— 那会引入
          //    新的 saveLayer，BackdropFilter 的 backdrop 变空、模糊整段消失。
          //    见 MiTopBarPalette.blurBands 的说明。）
          for (final band in MiTopBarPalette.blurBands)
            Positioned(
              left: 0,
              right: 0,
              top: band.top,
              height: band.height,
              child: IgnorePointer(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: band.sigma,
                      sigmaY: band.sigma,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          // 2) 叠色：顶部最深 → 渐隐（亮色 = 页底色 @0.65→0，深色 = 黑
          //    @1→0，两页各自实测，见 MiTopBarPalette 文档）
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: MiTopBarMetrics.scrimHeight,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: palette.scrimGradient),
              ),
            ),
          ),
          // 3) 大标题：随滚动 1:1 上移 + 按实测表淡出（钉基线 → top 恒为 0）
          if (title != null)
            Positioned(
              left: MiTopBarMetrics.largeTitleLeadingInset,
              top: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: MiTopBarMetrics.largeTitleOpacity(offset),
                  child: Baseline(
                    baseline: largeTitleBaseline - offset,
                    baselineType: TextBaseline.alphabetic,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MiTypography.topBarLargeTitleFor(mode),
                    ),
                  ),
                ),
              ),
            ),
          // 4) 紧凑标题：与返回圆钮同一行、屏内水平居中（实测 609.5px ≈ 屏心）
          if (title != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: MiTopBarMetrics.compactTitleOpacity(offset),
                  child: Padding(
                    // 显示圆钮时对称内缩（圆钮右缘），长标题居中且不与圆钮相撞；
                    // 不显示圆钮时不留内缩，居中标题可用满整屏宽。
                    padding: EdgeInsets.symmetric(
                      horizontal: showBack
                          ? MiTopBarMetrics.backInset +
                              MiTopBarMetrics.backDiameter
                          : 0,
                    ),
                    child: Center(
                      child: Baseline(
                        baseline: compactTitleBaseline,
                        baselineType: TextBaseline.alphabetic,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MiTypography.topBarCompactTitleFor(mode),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // 5) 返回圆钮（可选，组件唯一的可交互元素）
          if (showBack)
            Positioned(
              left: MiTopBarMetrics.backInset,
              top: MiTopBarMetrics.backCenterY -
                  MiTopBarMetrics.backDiameter / 2,
              child: _MiTopBarBackButton(
                palette: palette,
                onTap: onBack,
              ),
            ),
        ],
      ),
    );
  }
}

/// 返回圆钮：⌀44.1 命中区 + 箭头，按下时浮现白 @9.4% 圆盘（实测）。
///
/// 箭头墨心相对圆钮中心左偏 [MiTopBarMetrics.chevronCenterDx]（实测光学
/// 偏置，非居中）。
class _MiTopBarBackButton extends StatefulWidget {
  const _MiTopBarBackButton({required this.palette, required this.onTap});

  final MiTopBarPalette palette;
  final VoidCallback? onTap;

  @override
  State<_MiTopBarBackButton> createState() => _MiTopBarBackButtonState();
}

class _MiTopBarBackButtonState extends State<_MiTopBarBackButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: MiTopBarMetrics.backDiameter,
      height: MiTopBarMetrics.backDiameter,
      child: Stack(
        children: [
          // 按压反馈圆盘（实测平坦填充、无描边）
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _pressed ? 1 : 0,
              duration: Duration(
                milliseconds: _pressed
                    ? MiTopBarMetrics.pressFadeInMs
                    : MiTopBarMetrics.pressFadeOutMs,
              ),
              curve: Curves.easeOut,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.palette.pressHighlight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // 箭头：墨盒铺满，中心再按实测偏置平移
          Center(
            child: Transform.translate(
              offset: const Offset(MiTopBarMetrics.chevronCenterDx, 0),
              child: CustomPaint(
                painter: BackChevronIconPainter(widget.palette.ink),
                size: const Size(
                  MiTopBarMetrics.chevronWidth,
                  MiTopBarMetrics.chevronHeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final onTap = widget.onTap;
    if (onTap == null) return IgnorePointer(child: content);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: onTap,
      child: content,
    );
  }
}
