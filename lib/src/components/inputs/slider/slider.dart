import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/colors.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../utils/focus_ring.dart';
import '../../../utils/hover_feedback.dart';
import '../switch_control/switch_metrics.dart';
import 'slider_metrics.dart';

/// 连续 / 分档滑条（`MiSlider`）。
///
/// 几何**全部为推导值**（[MiSliderMetrics] 注明口径：Material 3 同档
/// 轨道 / 拇指，触屏素材无滑条样张）；配色只引用既有 token（活动段 =
/// [MiColors.accent]、非活动段 = 开关关闭档同源 state layer、拇指 = 开关
/// 白钮同口径）。
///
/// 交互：
///  * 拖拽：`onHorizontalDrag*` + **`globalToLocal` 坐标系换算**取值 ——
///    不用 `details.delta` 累加（累加会在拖出控件边界 / 手势接管后漂移，
///    flutter_miuix `slider_drag_test` 的同款回归教训）；拖拽值经
///    [onChanged] 上抛，**受控**组件（值由调用方持有）；
///  * 键盘：Tab 聚焦出 [MiFocusRing]，← / → 按步长增减（全程 /20，
///    [divisions] 给出时按档吸附）；悬停走 [MiHoverFeedback]；
///  * 禁用（[onChanged] 为 null）：不可拖、不可聚焦，整体降禁用透明档
///    （与 `MiSwitch` 同口径）。
class MiSlider extends StatelessWidget {
  const MiSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.themeMode,
    this.focusNode,
  }) : assert(max > min);

  /// 当前值（受控）。
  final double value;

  /// 值变更回调（连续拖拽逐帧上抛；null = 禁用）。
  final ValueChanged<double>? onChanged;

  /// 取值范围（[min, max]）。
  final double min;

  final double max;

  /// 档数（null = 连续；给出时拖拽 / 键盘都按档吸附）。
  final int? divisions;

  /// 明暗模式；null = 跟随环境 `Theme` 亮度。
  final MiThemeMode? themeMode;

  /// 外部键盘焦点节点（挂在最外层 —— Enter / Space 由环消费，
  /// ← / → 由本层消费，事件沿焦点链冒泡）；null = 自建。
  final FocusNode? focusNode;

  double get _t => ((value - min) / (max - min)).clamp(0.0, 1.0);

  /// 按档吸附一个原始值。
  double _snap(double v) {
    final d = divisions;
    if (d == null || d <= 1) return v.clamp(min, max);
    final step = (max - min) / (d - 1);
    return (min + ((v - min) / step).round() * step).clamp(min, max);
  }

  /// 键盘步长（一格 = 全程 /20；分档时直接用档步长）。
  double get _keyboardStep =>
      divisions != null && divisions! > 1
          ? (max - min) / (divisions! - 1)
          : (max - min) / MiSliderMetrics.keyboardSteps;

  /// 全局 x → 值（**坐标系换算取值**，不累加 delta）。
  double _valueAt(RenderBox box, double globalDx, double width) {
    final dx = box.globalToLocal(Offset(globalDx, 0)).dx;
    return _snap(min + (dx / width).clamp(0.0, 1.0) * (max - min));
  }

  @override
  Widget build(BuildContext context) {
    final mode = themeMode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    final enabled = onChanged != null;
    const trackTop =
        (MiSliderMetrics.hitHeight - MiSliderMetrics.trackHeight) / 2;
    final thumbTop =
        (MiSliderMetrics.hitHeight - MiSliderMetrics.thumbSize) / 2;
    final inactive = MiTransparencyTokens.switchTrackOffFor(mode);
    final knobShadow = mode == MiThemeMode.dark
        ? const <BoxShadow>[]
        : const <BoxShadow>[
            BoxShadow(
              color: MiTransparencyTokens.panelShadow,
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ];

    // 键盘：← / → 按步长增减（事件沿焦点链冒泡到本层，MiFocusRing 只
    // 消费 Enter / Space）。
    Widget child = Focus(
      focusNode: focusNode,
      // 不作独立 Tab 停靠点：焦点环自带一停；本层只作为 ← / → 的
      // 冒泡接收器（事件沿焦点链上行，环只消费 Enter / Space）。
      skipTraversal: true,
      onKeyEvent: !enabled
          ? null
          : (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              final step = _keyboardStep;
              if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                  event.logicalKey == LogicalKeyboardKey.arrowUp) {
                onChanged!((value + step).clamp(min, max));
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                  event.logicalKey == LogicalKeyboardKey.arrowDown) {
                onChanged!((value - step).clamp(min, max));
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
      child: SizedBox(
        height: MiSliderMetrics.hitHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 非活动轨道。
                Positioned(
                  left: 0,
                  right: 0,
                  top: trackTop,
                  height: MiSliderMetrics.trackHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: inactive,
                      borderRadius:
                          BorderRadius.circular(MiSliderMetrics.trackHeight / 2),
                    ),
                  ),
                ),
                // 活动轨道。
                Positioned(
                  left: 0,
                  top: trackTop,
                  width: width * _t,
                  height: MiSliderMetrics.trackHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: MiColors.accent,
                      borderRadius:
                          BorderRadius.circular(MiSliderMetrics.trackHeight / 2),
                    ),
                  ),
                ),
                // 拇指（白钮 + 浅色轻投影）。
                Positioned(
                  left: width * _t - MiSliderMetrics.thumbSize / 2,
                  top: thumbTop,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFFFFFF),
                      shape: const CircleBorder(),
                      shadows: knobShadow,
                    ),
                    child: const SizedBox.square(
                      dimension: MiSliderMetrics.thumbSize,
                    ),
                  ),
                ),
                // 拖拽命中层（覆盖整条触区）。
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: !enabled
                        ? null
                        : (details) => onChanged!(
                            _valueAt(
                              context.findRenderObject()! as RenderBox,
                              details.globalPosition.dx,
                              width,
                            ),
                          ),
                    onHorizontalDragUpdate: !enabled
                        ? null
                        : (details) => onChanged!(
                            _valueAt(
                              context.findRenderObject()! as RenderBox,
                              details.globalPosition.dx,
                              width,
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    // 悬停 + 焦点（桌面语义，推导同惯例）；禁用两态全关。
    child = MiHoverFeedback(enabled: enabled, mode: mode, child: child);
    child = MiFocusRing(
      enabled: enabled,
      mode: mode,
      borderRadius: BorderRadius.circular(MiSliderMetrics.hitHeight / 2),
      child: child,
    );

    // 禁用整体降透明（开关同口径）；本件子树无 backdrop 磨砂。
    return Semantics(
      container: true,
      child: Opacity(
        opacity: enabled ? 1 : MiSwitchMetrics.disabledOpacity,
        child: child,
      ),
    );
  }
}
