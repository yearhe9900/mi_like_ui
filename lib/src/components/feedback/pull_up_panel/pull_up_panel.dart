import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../theme/pull_up_panel_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import 'pull_up_panel_metrics.dart';

/// 弹出面板（从触发按钮弹起、长高到定形面板的模态层）。
///
/// 参考 HyperOS 拨号键盘的唤起形态：点按右下角圆钮后，一块圆角面板从按钮
/// 位置**等比放大**长到终态（弹簧，带轻微过冲），贴在底部导航栏之上；
/// 面板外**不压暗**（度量：面板外页底像素不变），面板外点按交给宿主收起。
/// 几何与动效规格见 [MiPullUpPanelMetrics]，表面配色见
/// `theme/pull_up_panel_tokens.dart`。
///
/// **高度与内容完全由调用方定义**：内容在**终态尺寸**下排版、随面板一起
/// 缩放（唤起过程中不重排版 —— 与素材一致），因此传入的内容应是终态布局。
///
/// ```dart
/// _showPanel
///   ? Positioned.fill(
///       child: MiPullUpPanel(
///         height: 320,                       // 自定义长高（null = 内容自适应）
///         anchorPoint: fabCenter,            // 触发按钮圆心（全局坐标）
///         themeMode: mode,
///         onScrimTap: close,
///         child: MyPanelContent(),
///       ),
///     )
///   : const SizedBox.shrink(),
/// ```
///
/// ## 行为
///
///  * **唤起**：挂载即从 [anchorPoint]（触发按钮圆心，全局坐标；缺省取
///    素材按钮位 —— 距右缘 66 / 距屏底 52.3）以起点尺寸 [collapsedSize]
///    （缺省 = 按钮直径 54.1）**等比放大**到终态；弹簧
///    （stiffness 260 / damping 26）~0.53s 收口、~1.3% 过冲（拟合）；
///  * **收起**：与 [MiDialog] 同契约 —— 组件不接管自身移除、无退场动画，
///    何时移除由宿主在 [onScrimTap] 等回调里决定；
///  * **高度**：[height] 给定终态高（超可用高时钳到 [maxHeight]）；为
///    `null` 时由内容自适应（同样受上限约束）。面板高上限 =
///    屏高 − 顶让位（安全区兜底）− 底距 90；
///  * **宽度**：屏宽 − 2×24（度量）；宽屏档（≥1024）再限宽 440（推导，
///    沿用弹框宽屏口径）。
class MiPullUpPanel extends StatefulWidget {
  const MiPullUpPanel({
    super.key,
    required this.child,
    this.height,
    this.maxHeight,
    this.anchorPoint,
    this.collapsedSize = MiPullUpPanelMetrics.triggerDiameter,
    this.themeMode,
    this.onScrimTap,
  });

  /// 面板内容（在终态尺寸下排版，随面板一起等比缩放）。
  final Widget child;

  /// 终态高（null = 内容自适应；两者都受 [maxHeight] 钳制）。
  final double? height;

  /// 面板高上限（null = 按 [MiPullUpPanelMetrics.maxHeightFor] 取屏内可用高）。
  final double? maxHeight;

  /// 触发按钮圆心（**全局坐标**；null = 素材按钮位推导的右下默认点）。
  final Offset? anchorPoint;

  /// 起点尺寸（触发按钮直径；素材 54.1dp）。
  final double collapsedSize;

  /// 明暗模式；为空时跟随环境 `Theme.of(context).brightness`。
  final MiThemeMode? themeMode;

  /// 面板外点按回调（null = 不响应）；是否移除由宿主决定。
  final VoidCallback? onScrimTap;

  @override
  State<MiPullUpPanel> createState() => _MiPullUpPanelState();
}

class _MiPullUpPanelState extends State<MiPullUpPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // 名义兜底时长；实际由 SpringSimulation 驱动到收敛。上界放开到 1.2：
    // 默认上界 1 会把弹簧的 ~1.4% 过冲钳平（见 springUpperBound）。
    duration: const Duration(
      milliseconds: MiPullUpPanelMetrics.springSettleMs,
    ),
    upperBound: MiPullUpPanelMetrics.springUpperBound,
  );

  @override
  void initState() {
    super.initState();
    _controller.animateWith(
      SpringSimulation(
        const SpringDescription(
          mass: MiPullUpPanelMetrics.springMass,
          stiffness: MiPullUpPanelMetrics.springStiffness,
          damping: MiPullUpPanelMetrics.springDamping,
        ),
        0, // 起点缩放比
        1, // 终态
        0, // 初速
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  MiThemeMode _modeOf(BuildContext context) =>
      widget.themeMode ??
      (Theme.of(context).brightness == Brightness.dark
          ? MiThemeMode.dark
          : MiThemeMode.light);

  @override
  Widget build(BuildContext context) {
    final palette = MiPullUpPanelPalette.of(_modeOf(context));
    final safeTop = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        // 透明命中层（**无压暗** —— 度量）：面板外点按交给宿主收起。
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onScrimTap,
            child: const ColoredBox(color: MiTransparencyTokens.panelScrim),
          ),
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;
              final panelW = MiPullUpPanelMetrics.panelWidthFor(screenW);
              final maxH = widget.maxHeight ??
                  MiPullUpPanelMetrics.maxHeightFor(screenH, safeTop);
              final anchor = widget.anchorPoint ??
                  MiPullUpPanelMetrics.defaultAnchorFor(screenW, screenH);
              final startScale = MiPullUpPanelMetrics.scaleFor(
                widget.collapsedSize,
                panelW,
              );
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  // 弹簧进度（可过冲 >1）→ 等比缩放。内容先按终态排好版，
                  // 再整层以按钮圆心为原点缩放 —— 过程中不重排版。
                  final t = _controller.value;
                  final scale = startScale + (1 - startScale) * t;
                  return Stack(
                    children: [
                      Transform(
                        transform: Matrix4.diagonal3Values(scale, scale, 1),
                        // 原点 = 锚点（子层铺满屏幕，全局坐标 == 层内坐标）。
                        origin: anchor,
                        child: Stack(
                          children: [
                            Positioned(
                              left: (screenW - panelW) / 2,
                              bottom: MiPullUpPanelMetrics.bottomGap,
                              width: panelW,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: maxH),
                                child: SizedBox(
                                  height: widget.height == null
                                      ? null
                                      : math.min(widget.height!, maxH),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: palette.surface,
                                      borderRadius: BorderRadius.circular(
                                        MiPullUpPanelMetrics.panelRadius,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        MiPullUpPanelMetrics.panelRadius,
                                      ),
                                      child: widget.child,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
