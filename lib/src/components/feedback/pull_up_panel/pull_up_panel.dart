import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../theme/motion_tokens.dart';
import '../../../theme/pull_up_panel_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import 'pull_up_panel_metrics.dart';

/// [MiPullUpPanel] 的显隐控制器（宿主可编程收起）。
///
/// ```dart
/// final panelController = MiPullUpPanelController();
/// // 打开：
/// setState(() => show = true);
/// // 收起（播反向弹簧 + 淡出，收口后回调 `onDismissed`）：
/// panelController.dismiss();
/// ```
class MiPullUpPanelController {
  _MiPullUpPanelState? _state;

  /// 面板当前是否挂载（打开或收起动画中）。
  bool get isVisible => _state != null;

  /// 收起面板（播收回动画；收口后触发面板的 `onDismissed`）。
  /// 未挂载时为空操作。
  void dismiss() => _state?._dismiss();
}

/// 弹出面板（从触发按钮弹起、长高到定形面板的模态层；收起时缩回按钮）。
///
/// 参考 HyperOS 拨号键盘的唤起形态（录屏逐帧度量）：点按右下圆钮后，一块
/// 圆角面板从按钮位置**等比放大**长到终态（弹簧，带轻微过冲），贴在底部
/// 导航栏之上；收起时沿同一路径**反向缩回按钮**并随进度淡出。面板外**不
/// 压暗**（度量：面板外页底像素不变），面板外点按触发收起。
/// 几何与动效规格见 [MiPullUpPanelMetrics]，表面配色见
/// `theme/pull_up_panel_tokens.dart`。
///
/// **高度与内容完全由调用方定义**：内容在**终态尺寸**下排版、随面板一起
/// 缩放（唤起/收起过程中不重排版 —— 与素材一致），因此传入的内容应是
/// 终态布局。
///
/// ```dart
/// _showPanel
///   ? Positioned.fill(
///       child: MiPullUpPanel(
///         height: 320,                       // 自定义长高（null = 内容自适应）
///         anchorPoint: fabCenter,            // 触发按钮圆心（全局坐标）
///         controller: panelController,       // 可编程收起（可选）
///         themeMode: mode,
///         onDismissed: close,                // 收回动画收口后移除
///         child: MyPanelContent(),
///       ),
///     )
///   : const SizedBox.shrink(),
/// ```
///
/// ## 行为
///
///  * **唤起**：挂载即从 [anchorPoint]（触发按钮圆心，全局坐标；缺省取
///    素材按钮位）以起点尺寸 [collapsedSize]（缺省 = 按钮直径 54.1）**等比
///    放大**到终态；缩放原点为**移动原点**（横向恒定于终态右缘 − 20.9、
///    纵向由按钮圆心 lerp 到屏底 − 2×90，逐帧拟合素材，见
///    [MiPullUpPanelMetrics] 类注释）；弹簧 ~0.53s 收口、~1.3% 过冲；
///  * **收起**：点按面板外（透明命中层）或 [MiPullUpPanelController.dismiss]
///    触发**反向弹簧**（临界阻尼 ~0.19s 缩回按钮）+ **随进度线性淡出**，
///    收口后回调 [onDismissed] —— 由宿主移除组件（组件不提前自毁）；
///  * **高度**：[height] 给定终态高（超可用高时钳到 [maxHeight]）；为
///    `null` 时由内容自适应（同样受上限约束）。面板高上限 =
///    屏高 − 顶让位（安全区兜底）− 底距 90；
///  * **宽度**：屏宽 − 2×24（度量）；宽屏档（≥1024）再限宽 440（推导）。
///
/// 触发按钮的**震动反馈**属于按钮自身（素材按键有触感），由调用方在触发
/// 回调里发 `HapticFeedback` —— 面板不越权代发。
class MiPullUpPanel extends StatefulWidget {
  const MiPullUpPanel({
    super.key,
    required this.child,
    this.height,
    this.maxHeight,
    this.anchorPoint,
    this.collapsedSize = MiPullUpPanelMetrics.triggerDiameter,
    this.themeMode,
    this.controller,
    this.onDismissed,
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

  /// 可选控制器：宿主用 [MiPullUpPanelController.dismiss] 编程收起。
  final MiPullUpPanelController? controller;

  /// 收回动画收口后的回调（宿主在此移除组件）。
  final VoidCallback? onDismissed;

  @override
  State<MiPullUpPanel> createState() => _MiPullUpPanelState();
}

class _MiPullUpPanelState extends State<MiPullUpPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // 名义兜底时长；实际由 SpringSimulation 驱动到收敛。上界放开到 1.2：
    // 默认上界 1 会把唤起弹簧的 ~1.4% 过冲钳平（见 springUpperBound）。
    duration: const Duration(
      milliseconds: MiPullUpPanelMetrics.springSettleMs,
    ),
    upperBound: MiPullUpPanelMetrics.springUpperBound,
  );

  /// 是否处于收回过程（驱动淡出 + 反向弹簧的语义）。
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _controller.animateWith(
      SpringSimulation(
        // 展开弹簧（度量拟合档案见 token 文档）。
        MiMotionTokens.panelExpand,
        0, // 起点缩放比
        1, // 终态
        0, // 初速
      ),
    );
  }

  @override
  void didUpdateWidget(covariant MiPullUpPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._state == this) {
        oldWidget.controller?._state = null;
      }
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    _controller.dispose();
    super.dispose();
  }

  /// 收起：同一原点路径的反向弹簧（临界阻尼）+ 淡出；收口后回调
  /// [MiPullUpPanel.onDismissed]（组件由宿主移除，不提前自毁）。
  void _dismiss() {
    if (_dismissing) return;
    setState(() => _dismissing = true);
    _controller
        .animateWith(
          SpringSimulation(
            MiMotionTokens.panelCollapse,
            _controller.value, // 从当前进度收回
            0,
            0,
          ),
        )
        .whenComplete(() {
      if (mounted && _dismissing) widget.onDismissed?.call();
    });
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
        // 透明命中层（**无压暗** —— 度量）：点按触发收回动画。
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _dismiss,
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
                  // 进度 t（唤起可过冲 >1；收回 1 → 0）。内容先按终态排好版，
                  // 再整层等比缩放 —— 过程中不重排版。
                  final t = _controller.value;
                  final scale = startScale + (1 - startScale) * t;
                  // 缩放原点（逐帧拟合素材，见 metrics 类注释）：
                  //  * 横向恒定：终态右缘 − 20.9；
                  //  * 纵向：按钮圆心 → 终态底缘 − 90，随 t lerp（面板向上长
                  //    的观感来源；收回时原点随 t 回到按钮，面板缩回按钮）。
                  final originXFixed =
                      (screenW + panelW) / 2 -
                      MiPullUpPanelMetrics.originOffsetX;
                  final origin = Offset(
                    // 横向：t∈[0,0.2] 从按钮圆心靠到终值（首个可见帧起恒定，
                    // 与素材 ±1dp 拟合）。
                    anchor.dx +
                        (originXFixed - anchor.dx) *
                            (t / MiPullUpPanelMetrics.originXArrivalT)
                                .clamp(0.0, 1.0),
                    // 纵向：按钮圆心 → 屏底 − 2×90 随 t lerp（面板向上长的
                    // 观感来源；收回时原点回到按钮，面板缩回按钮）。
                    anchor.dy +
                        t *
                            ((screenH -
                                    2 * MiPullUpPanelMetrics.bottomGap) -
                                anchor.dy),
                  );
                  return Stack(
                    children: [
                      Transform(
                        transform: Matrix4.diagonal3Values(scale, scale, 1),
                        origin: origin,
                        child: Opacity(
                          // 收回时随进度线性淡出（素材实测）；唤起不淡入。
                          opacity: _dismissing
                              ? t.clamp(0.0, 1.0)
                              : 1.0,
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
                                        // 轻投影（浅色度量拟合，暗色不可分辨）
                                        boxShadow: const [
                                          BoxShadow(
                                            color:
                                                MiTransparencyTokens.panelShadow,
                                            blurRadius:
                                                MiPullUpPanelMetrics
                                                    .shadowBlurRadius,
                                            offset: Offset(
                                              0,
                                              MiPullUpPanelMetrics
                                                  .shadowOffsetY,
                                            ),
                                          ),
                                        ],
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
