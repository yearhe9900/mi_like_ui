import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../../theme/colors.dart';
import '../../../theme/mi_theme.dart';
import '../../../theme/slider_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../foundations/focus_ring.dart';
import '../../../foundations/hover_feedback.dart';
import '../switch_control/switch_metrics.dart';
import 'slider_metrics.dart';

/// 连续 / 分档滑条（`MiSlider`）。
///
/// 几何**全部为推导值**（[MiSliderMetrics] 逐项注明口径：Material 3 同档
/// 轨道 / 拇指，触屏素材无滑条样张）；配色只引用既有 token（活动段 =
/// [MiColors.accent]、非活动段 = 开关关闭档同源 state layer、拇指 / 选中
/// 关键点 = 开关白钮同口径，见 `theme/slider_tokens.dart`）。
///
/// ## 交互
///
///  * **拖拽**：`onHorizontalDrag*` + **`globalToLocal` 坐标系换算**取值 ——
///    不用 `details.delta` 累加（累加会在拖出控件边界 / 手势接管后漂移，
///    flutter_miuix `slider_drag_test` 的同款回归教训）；拖拽中拇指**直接
///    跟手**（不每帧起弹簧），拖拽值经 [onChanged] 上抛，**受控**组件；
///  * **点按跳转**（对齐上游 flutter_miuix `MiuixSlider`）：点哪落哪，落点
///    由 [MiSliderMetrics.settle] 弹簧收敛；宿主不接受该值（受控值未变）时
///    下一帧弹回宿主值 —— 与 `MiSwitch` 的拖拽归位同一套判据；
///  * **分档**：[divisions] 给出时拖拽 / 点按 / 键盘都按档吸附；
///  * **关键点**：[keyPoints] 给出即显示（画在轨道上，越过的点用选中色）；
///    [showKeyPoints] 为 true 时改显示 [divisions] 的等分刻度；
///    [magnetThreshold] 内**磁吸**到最近的关键点（参考实现值 2%）；
///  * **键盘**：Tab 聚焦出 [MiFocusRing]，← / → 按步长增减（全程 /20，
///    分档时按档步长）；悬停走 [MiHoverFeedback]；
///  * **拇指放大** [MiSliderMetrics.thumbScaleActive]（1.127，参考实现值）：
///    按下 / 拖拽 / 指针悬停在拇指上时放大，其余回落 —— 拖拽语言与
///    `MiSwitch` 同档；
///  * **方向**：[reverseDirection] 反转取值方向，RTL 下自动再镜像一次
///    （与 `Directionality` 同步）；
///  * **禁用**（[onChanged] 为 null）：不可拖、不可点、不可聚焦，整体降
///    禁用透明档（与 `MiSwitch` 同口径）。
///
/// 触感（`HapticFeedback`）**不代发**：与 `MiSwitch` / `MiCheckbox` 同口径，
/// 需要「过档 / 到端点」的触感时由调用方在 [onChanged] / [onChangeEnd] 里
/// 自行触发（本库不发明触感时机）。
class MiSlider extends StatefulWidget {
  const MiSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.keyPoints,
    this.showKeyPoints = false,
    this.magnetThreshold = MiSliderMetrics.magnetThreshold,
    this.reverseDirection = false,
    this.themeMode,
    this.focusNode,
  }) : assert(max > min, 'max 必须大于 min');

  /// 拇指的 key（测试用来读位置 / 放大倍数；不是公开 API 语义）。
  static const Key thumbKey = Key('mi-slider-thumb');

  /// 第 [index] 个关键点的 key（测试用，同上）。
  static Key keyPointKey(int index) =>
      ValueKey<String>('mi-slider-key-point-$index');

  /// 当前值（受控）。
  final double value;

  /// 值变更回调（连续拖拽逐帧上抛；null = 禁用）。
  final ValueChanged<double>? onChanged;

  /// 一次取值交互结束（拖拽松手 / 点按落点）时回调；null = 不通知。
  ///
  /// 与 [onChanged] 的分工：需要「松手才算数」的副作用（持久化、触感、
  /// 埋点）放这里，别在逐帧的 [onChanged] 里做。
  final VoidCallback? onChangeEnd;

  /// 取值范围（[min, max]）。
  final double min;

  final double max;

  /// 档数（null = 连续；给出时拖拽 / 点按 / 键盘都按档吸附）。
  ///
  /// 与上游 flutter_miuix 的口径换算：本库 `divisions` = n 档（含两端），
  /// 对应上游 `steps` = n − 2（中间台阶数）。
  final int? divisions;

  /// 关键点（值列表，须落在 [min, max] 内；给出即显示，不依赖
  /// [showKeyPoints]）。
  final List<double>? keyPoints;

  /// 显示 [divisions] 的等分刻度（[keyPoints] 为空时生效）。
  final bool showKeyPoints;

  /// 磁性吸附阈值（占全程比例）；拖到距关键点小于该比例即吸过去。
  final double magnetThreshold;

  /// 反转取值方向（true = 右大左小）；RTL 下自动再镜像一次。
  final bool reverseDirection;

  /// 明暗模式；null = 跟随环境 `Theme` 亮度。
  final MiThemeMode? themeMode;

  /// 外部键盘焦点节点（挂在最外层 —— Enter / Space 由环消费，
  /// ← / → 由本层消费，事件沿焦点链冒泡）；null = 自建。
  final FocusNode? focusNode;

  @override
  State<MiSlider> createState() => _MiSliderState();
}

class _MiSliderState extends State<MiSlider> with TickerProviderStateMixin {
  /// 绘制用的显示值（无界 controller：跟手时直接赋值、跳转时走弹簧）。
  late final AnimationController _valueCtrl;

  /// 拇指放大进度 0…1（有界，[MiSliderMetrics.scaleMs] 一趟）。
  late final AnimationController _scaleCtrl;

  /// 两个 controller 的合并监听，**只建一次**（build 每帧重建本组件时
  /// 不要重新 merge，否则监听反复订阅 / 退订）。
  late final Listenable _repaint;

  bool _dragging = false;
  bool _pressed = false;
  bool _hoverThumb = false;

  /// 最近一次布局宽（`LayoutBuilder` 写入；指针换算与拇指命中复用）。
  double _width = 0;

  @override
  void initState() {
    super.initState();
    // 必须在 initState 建：`late final x = AnimationController(...)` 的初始化
    // 器首次访问才跑，出生即终态会吞掉首帧的收敛动画（见 `MiTopBar` 同款坑）。
    _valueCtrl = AnimationController.unbounded(
      vsync: this,
      value: _clamp(widget.value),
    );
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: MiSliderMetrics.scaleMs),
      value: 0,
    );
    _repaint = Listenable.merge([_valueCtrl, _scaleCtrl]);
  }

  @override
  void didUpdateWidget(MiSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 拖拽中不响应外部值回灌 —— 拇指已 1:1 跟手，再起弹簧会造成双重动画。
    if (_dragging) return;
    if (oldWidget.value != widget.value ||
        oldWidget.min != widget.min ||
        oldWidget.max != widget.max) {
      _animateTo(_clamp(widget.value));
    }
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onChanged != null;

  /// 是否反转取值方向：显式参数与 RTL 各翻转一次。
  bool get _reversed =>
      widget.reverseDirection !=
      (Directionality.of(context) == TextDirection.rtl);

  double _clamp(double v) => v.clamp(widget.min, widget.max);

  void _animateTo(double target) {
    _valueCtrl.animateWith(
      SpringSimulation(MiSliderMetrics.settle, _valueCtrl.value, target, 0),
    );
  }

  // ── 值 ⇄ 位置 ────────────────────────────────────────────────────────────

  /// 拇指圆心距左缘的像素（拇指贴边：行程 = 宽 − 直径）。
  double _centerXFor(double v, double width) {
    final t = ((v - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
    final visual = _reversed ? 1 - t : t;
    return MiSliderMetrics.thumbSize / 2 + visual * _travel(width);
  }

  /// 拇指行程（可拖拽的像素长度）。
  double _travel(double width) =>
      (width - MiSliderMetrics.thumbSize).clamp(0.0, double.infinity);

  /// 指针 x → 值（**坐标系换算**，不累加 delta）。
  double _valueAt(double localDx, double width) {
    final travel = _travel(width);
    final visual = travel == 0
        ? 0.0
        : ((localDx - MiSliderMetrics.thumbSize / 2) / travel).clamp(0.0, 1.0);
    final t = _reversed ? 1 - visual : visual;
    return _quantize(widget.min + t * (widget.max - widget.min));
  }

  /// 分档吸附 / 关键点磁吸。
  double _quantize(double v) {
    final clamped = _clamp(v);
    final divisions = widget.divisions;
    if (divisions != null && divisions > 1) {
      final step = (widget.max - widget.min) / (divisions - 1);
      return _clamp(
        widget.min + ((clamped - widget.min) / step).round() * step,
      );
    }
    final points = widget.keyPoints;
    if (points == null || points.isEmpty) return clamped;
    final span = widget.max - widget.min;
    var best = _clamp(points.first);
    var bestDistance = (best - clamped).abs();
    for (final p in points.skip(1)) {
      final candidate = _clamp(p);
      final distance = (candidate - clamped).abs();
      if (distance < bestDistance) {
        best = candidate;
        bestDistance = distance;
      }
    }
    return bestDistance <= widget.magnetThreshold * span ? best : clamped;
  }

  /// 键盘步长（分档时直接用档步长，否则全程 /20）。
  double get _step =>
      widget.divisions != null && widget.divisions! > 1
          ? (widget.max - widget.min) / (widget.divisions! - 1)
          : (widget.max - widget.min) / MiSliderMetrics.keyboardSteps;

  /// 显示出来的关键点值（[keyPoints] 优先，否则按 [showKeyPoints] 展开分档）。
  List<double> get _visibleKeyPoints {
    final points = widget.keyPoints;
    if (points != null && points.isNotEmpty) return points;
    if (!widget.showKeyPoints) return const <double>[];
    final divisions = widget.divisions;
    if (divisions == null || divisions < 2) return const <double>[];
    return List<double>.generate(
      divisions,
      (i) => widget.min + (widget.max - widget.min) * i / (divisions - 1),
    );
  }

  // ── 指针 ─────────────────────────────────────────────────────────────────

  void _applyAt(double localDx) {
    final v = _valueAt(localDx, _width);
    _valueCtrl.value = v; // 跟手：不做弹簧
    widget.onChanged?.call(v);
  }

  void _onDragStart(DragStartDetails details) {
    _valueCtrl.stop();
    _dragging = true;
    _syncScale();
    _applyAt(details.localPosition.dx);
  }

  void _onDragEnd() {
    _dragging = false;
    _syncScale();
    widget.onChangeEnd?.call();
    // 以「最后一次上抛的值」为准判断宿主是否接受：接受则拇指已经在那儿
    // （无需再动），拒绝则帧末弹回宿主值。
    _settleOrRevert(_valueCtrl.value);
  }

  void _onTapUp(TapUpDetails details) {
    final v = _valueAt(details.localPosition.dx, _width);
    widget.onChanged?.call(v);
    _animateTo(v);
    widget.onChangeEnd?.call();
    _settleOrRevert(v);
  }

  /// 宿主接受 [requested] 就交给弹簧自然收敛；不接受（受控值没变）则
  /// 下一帧弹回宿主值 —— 帧末判定，无需猜宿主是否同帧 setState。
  void _settleOrRevert(double requested) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final host = _clamp(widget.value);
      if ((host - requested).abs() > 1e-6) _animateTo(host);
    });
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    _pressed = value;
    _syncScale();
  }

  void _syncScale() {
    if (!_enabled) return;
    final active = _pressed || _dragging || _hoverThumb;
    final target = active ? 1.0 : 0.0;
    if ((_scaleCtrl.value - target).abs() < 1e-3 && !_scaleCtrl.isAnimating) {
      return;
    }
    _scaleCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: MiSliderMetrics.scaleMs),
      curve: MiSliderMetrics.scaleCurve,
    );
  }

  void _onHover(PointerHoverEvent event) {
    if (!_enabled || _width == 0) return;
    // 命中半径 = 拇指半径 + 半个拇指（上游同口径）：比拇指本体宽松一档，
    // 指针贴边也算「在拇指上」。
    const hitRadius = MiSliderMetrics.thumbSize * 0.75;
    final over = (event.localPosition.dx - _centerXFor(_valueCtrl.value, _width))
            .abs() <=
        hitRadius;
    if (over == _hoverThumb) return;
    _hoverThumb = over;
    _syncScale();
  }

  void _onHoverExit(PointerExitEvent event) {
    if (!_hoverThumb) return;
    _hoverThumb = false;
    _syncScale();
  }

  // ── 构建 ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mode = MiTheme.modeOf(context, explicit: widget.themeMode);
    final enabled = _enabled;
    final inactive = MiTransparencyTokens.switchTrackOffFor(mode);
    final keyPointOff = MiSliderPalette.keyPointOffFor(mode);
    final knobShadow = mode == MiThemeMode.dark
        ? const <BoxShadow>[]
        : const <BoxShadow>[
            BoxShadow(
              color: MiTransparencyTokens.panelShadow,
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ];
    const trackTop =
        (MiSliderMetrics.hitHeight - MiSliderMetrics.trackHeight) / 2;
    const thumbTop =
        (MiSliderMetrics.hitHeight - MiSliderMetrics.thumbSize) / 2;
    const trackRadius = MiSliderMetrics.trackHeight / 2;

    // 键盘：← / → 按步长增减（事件沿焦点链冒泡到本层，MiFocusRing 只
    // 消费 Enter / Space）。
    Widget child = Focus(
      focusNode: widget.focusNode,
      // 不作独立 Tab 停靠点：焦点环自带一停；本层只作为 ← / → 的
      // 冒泡接收器（事件沿焦点链上行，环只消费 Enter / Space）。
      skipTraversal: true,
      onKeyEvent: !enabled
          ? null
          : (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              final key = event.logicalKey;
              final forward = key == LogicalKeyboardKey.arrowRight ||
                  key == LogicalKeyboardKey.arrowUp;
              final backward = key == LogicalKeyboardKey.arrowLeft ||
                  key == LogicalKeyboardKey.arrowDown;
              if (!forward && !backward) return KeyEventResult.ignored;
              final sign = (forward ? 1 : -1) * (_reversed ? -1 : 1);
              widget.onChanged!(_clamp(widget.value + sign * _step));
              return KeyEventResult.handled;
            },
      child: SizedBox(
        height: MiSliderMetrics.hitHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            _width = width;
            return MouseRegion(
              onHover: enabled ? _onHover : null,
              onExit: enabled ? _onHoverExit : null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: enabled ? (_) => _setPressed(true) : null,
                onTapUp: enabled
                    ? (details) {
                        _setPressed(false);
                        _onTapUp(details);
                      }
                    : null,
                onTapCancel: enabled ? () => _setPressed(false) : null,
                onHorizontalDragStart:
                    enabled ? (details) => _onDragStart(details) : null,
                onHorizontalDragUpdate: enabled
                    ? (details) => _applyAt(details.localPosition.dx)
                    : null,
                onHorizontalDragEnd: enabled ? (_) => _onDragEnd() : null,
                onHorizontalDragCancel: enabled ? _onDragEnd : null,
                child: AnimatedBuilder(
                  animation: _repaint,
                  builder: (context, _) {
                    const thumbRadius = MiSliderMetrics.thumbSize / 2;
                    final t = ((_valueCtrl.value - widget.min) /
                            (widget.max - widget.min))
                        .clamp(0.0, 1.0);
                    final centerX = _centerXFor(_valueCtrl.value, width);
                    final scale = 1 +
                        (MiSliderMetrics.thumbScaleActive - 1) *
                            _scaleCtrl.value;
                    final points = _visibleKeyPoints;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 非活动轨道（整条）。
                        Positioned(
                          left: 0,
                          right: 0,
                          top: trackTop,
                          height: MiSliderMetrics.trackHeight,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: inactive,
                              borderRadius:
                                  BorderRadius.circular(trackRadius),
                            ),
                          ),
                        ),
                        // 活动段：从起点侧边缘铺到拇指圆心（反向时翻过来）。
                        Positioned(
                          left: _reversed ? centerX : 0,
                          top: trackTop,
                          width: _reversed ? width - centerX : centerX,
                          height: MiSliderMetrics.trackHeight,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: MiColors.accent,
                              borderRadius:
                                  BorderRadius.circular(trackRadius),
                            ),
                          ),
                        ),
                        // 关键点（画在轨道之上、拇指之下）。
                        for (var i = 0; i < points.length; i++)
                          Positioned(
                            left: _centerXFor(points[i], width) -
                                MiSliderMetrics.keyPointSize / 2,
                            top: (MiSliderMetrics.hitHeight -
                                    MiSliderMetrics.keyPointSize) /
                                2,
                            child: DecoratedBox(
                              key: MiSlider.keyPointKey(i),
                              decoration: ShapeDecoration(
                                color: _isKeyPointReached(points[i], t)
                                    ? MiSliderPalette.keyPointOn
                                    : keyPointOff,
                                shape: const CircleBorder(),
                              ),
                              child: const SizedBox.square(
                                dimension: MiSliderMetrics.keyPointSize,
                              ),
                            ),
                          ),
                        // 拇指（白钮 + 浅色轻投影，放大以圆心为锚）。
                        Positioned(
                          left: centerX - thumbRadius,
                          top: thumbTop,
                          child: Transform.scale(
                            key: MiSlider.thumbKey,
                            scale: scale,
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                color: MiSliderPalette.thumb,
                                shape: const CircleBorder(),
                                shadows: knobShadow,
                              ),
                              child: const SizedBox.square(
                                dimension: MiSliderMetrics.thumbSize,
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
      slider: true,
      enabled: enabled,
      value: _semanticValue(widget.value),
      increasedValue: _semanticValue(_clamp(widget.value + _step)),
      decreasedValue: _semanticValue(_clamp(widget.value - _step)),
      onIncrease: enabled
          ? () => widget.onChanged!(_clamp(widget.value + _step))
          : null,
      onDecrease: enabled
          ? () => widget.onChanged!(_clamp(widget.value - _step))
          : null,
      child: Opacity(
        opacity: enabled ? 1 : MiSwitchMetrics.disabledOpacity,
        child: child,
      ),
    );
  }

  /// 关键点是否已被越过（落在活动段一侧）。
  bool _isKeyPointReached(double point, double t) {
    final pointT =
        ((point - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
    return _reversed ? pointT >= t - 1e-9 : pointT <= t + 1e-9;
  }

  /// 无障碍读出的值（整数不带小数尾巴，其余保留两位）。
  String _semanticValue(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}
