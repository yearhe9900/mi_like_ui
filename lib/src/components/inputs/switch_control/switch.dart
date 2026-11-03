import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../theme/colors.dart';
import '../../../theme/switch_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../utils/pressable.dart';
import '../../../utils/squircle.dart';
import 'switch_metrics.dart';

/// 开关（`MiSwitch`）：轨道 + 圆钮的二值开关，吸附弹簧切换。
///
/// 几何 / 动效**全部为推导值**（[MiSwitchMetrics] 注明每项口径，触屏
/// 素材无开关样张 —— 按 Material 3 通行档 + Folme 弹簧口径推导，素材
/// 到位后复核）；配色只引用既有 token：开启档 = [MiColors.accent]
///（全库强调同色）、关闭档 = `MiTransparencyTokens.switchTrackOffFor`
///（onSurface @12% state layer）。
///
/// ## 交互
///
///  * **点按 / Enter / Space 切换**（经 [MiPressable] 的按压状态机、
///    悬停叠色与焦点环）；[onChanged] 为 null = 禁用：不可点、不可聚焦、
///    不可拖、整体降到禁用透明档；
///  * **水平拖拽切换**（对齐上游 flutter_miuix `MiuixSwitch`）：钮体跟手
///    走到哪算哪（轨道色同步插值），松手时越过行程中点即吸附到另一端，
///    未越过则弹回原端；拖拽被系统取消（父级手势抢占）同样弹回；
///  * **钮体在按压 / 拖拽态放大** [MiSwitchMetrics.knobScaleActive]（1.127，
///    参考实现值），松开回原尺寸 —— 这是本件的按压视觉；触屏点按没有
///    悬停叠色，靠这层放大给到触感反馈；
///  * **RTL 镜像**：拖拽方向取反、钮体从右端起算（与 `Directionality` 同步）。
///
/// 切换动效 = 钮体沿行程的**吸附弹簧**（临界阻尼无过冲，
/// [MiSwitchMetrics.snap]，`AnimationController.animateWith(SpringSimulation)`
/// 驱动，轨道色随行程插值）；无涟漪 —— 扩散涟漪属素材语义，不发明。
/// 触感（`HapticFeedback`）**不代发**：与 `MiPullUpPanel` / `MiCheckbox`
/// 同口径，需要时由调用方在 `onChanged` 里自行触发。
class MiSwitch extends StatefulWidget {
  const MiSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.themeMode,
  });

  /// 钮体的 key（测试用来读行程位置；不是公开 API 语义）。
  static const Key knobKey = Key('mi-switch-knob');

  /// 当前开关态。
  final bool value;

  /// 切换回调（null = 禁用）；参数为切换后的新值。
  final ValueChanged<bool>? onChanged;

  /// 明暗模式；null = 跟随环境 `Theme` 亮度。
  final MiThemeMode? themeMode;

  @override
  State<MiSwitch> createState() => _MiSwitchState();
}

class _MiSwitchState extends State<MiSwitch>
    with SingleTickerProviderStateMixin {
  /// 钮体行程进度 0…1（无界 controller：吸附弹簧可带轻微越界观感）。
  late final AnimationController _ctrl = AnimationController.unbounded(
    vsync: this,
    value: widget.value ? 1 : 0,
  );

  /// 指针按下 / 拖拽中（驱动钮体放大）。原始指针事件走 [Listener]，不参与
  /// 手势竞技场 —— 点按仍归 [MiPressable] 的 tap、拖拽归内层 drag 识别器，
  /// 两者互不抢。
  bool _active = false;

  /// 当前是否 RTL 布局：拖拽方向与钮体定位据此镜像。
  bool get _isRtl => Directionality.of(context) == TextDirection.rtl;

  @override
  void didUpdateWidget(MiSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animateTo(widget.value ? 1 : 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _ctrl.animateWith(
      SpringSimulation(MiSwitchMetrics.snap, _ctrl.value, target, 0),
    );
  }

  void _setActive(bool value) {
    if (_active == value) return;
    setState(() => _active = value);
  }

  void _toggle() => widget.onChanged?.call(!widget.value);

  void _onDragStart() {
    // 停掉在跑的吸附弹簧，让钮体从当前实际位置接着跟手。
    _ctrl.stop();
  }

  void _onDragUpdate(double dx) {
    final delta = _isRtl ? -dx : dx;
    final next =
        (_ctrl.value + delta / MiSwitchMetrics.travel).clamp(0.0, 1.0);
    if (next != _ctrl.value) _ctrl.value = next;
  }

  void _onDragEnd() {
    final wantsOn = _ctrl.value >= MiSwitchMetrics.dragSwitchThreshold;
    if (wantsOn != widget.value) widget.onChanged?.call(!widget.value);
    // 归位推迟到帧末：宿主同帧接受新值 → 弹到新端；拒绝（受控值不变）→
    // 弹回原端。两者都由最新 `widget.value` 决定，无需猜。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = widget.value ? 1.0 : 0.0;
      if ((_ctrl.value - target).abs() > 0.001) _animateTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.themeMode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    final enabled = widget.onChanged != null;
    final trackOff = MiTransparencyTokens.switchTrackOffFor(mode);
    const trackOn = MiColors.accent;
    final knobShadow = mode == MiThemeMode.dark
        ? const <BoxShadow>[]
        : const <BoxShadow>[
            // 钮体轻投影（浅色推导档：面板投影同色源，blur / 偏移取小件口径）。
            BoxShadow(
              color: MiTransparencyTokens.panelShadow,
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ];

    return Semantics(
      toggled: widget.value,
      enabled: enabled,
      // 禁用整体降透明（Material 禁用档通行值）；本件子树无 backdrop
      // 磨砂，Opacity 的 saveLayer 不破坏任何 BackdropFilter。
      child: Opacity(
        opacity: enabled ? 1 : MiSwitchMetrics.disabledOpacity,
        child: Listener(
          onPointerDown: enabled ? (_) => _setActive(true) : null,
          onPointerUp: enabled ? (_) => _setActive(false) : null,
          onPointerCancel: enabled ? (_) => _setActive(false) : null,
          child: MiPressable(
            onPressed: enabled ? _toggle : null,
            mode: mode,
            borderRadius:
                BorderRadius.circular(MiSwitchMetrics.trackHeight / 2),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart:
                  enabled ? (_) => _onDragStart() : null,
              onHorizontalDragUpdate:
                  enabled ? (d) => _onDragUpdate(d.delta.dx) : null,
              onHorizontalDragEnd: enabled ? (_) => _onDragEnd() : null,
              onHorizontalDragCancel: enabled ? _onDragEnd : null,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  final progress = _ctrl.value.clamp(0.0, 1.0);
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: _active ? 1 : 0),
                    duration: const Duration(
                      milliseconds: MiSwitchMetrics.scaleMs,
                    ),
                    curve: MiSwitchMetrics.scaleCurve,
                    builder: (context, active, __) {
                      final scale =
                          1 + (MiSwitchMetrics.knobScaleActive - 1) * active;
                      final size = MiSwitchMetrics.knobSize * scale;
                      // 放大以钮体中心为锚（不往右下方长）。
                      final left = MiSwitchMetrics.knobInset +
                          MiSwitchMetrics.travel * progress -
                          (size - MiSwitchMetrics.knobSize) / 2;
                      return SizedBox(
                        width: MiSwitchMetrics.trackWidth,
                        height: MiSwitchMetrics.trackHeight,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: Color.lerp(trackOff, trackOn, progress),
                            shape: const MiSquircleBorder(
                              MiSwitchMetrics.trackHeight / 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: _isRtl ? null : left,
                                right: _isRtl ? left : null,
                                top: (MiSwitchMetrics.trackHeight - size) / 2,
                                child: DecoratedBox(
                                  key: MiSwitch.knobKey,
                                  decoration: ShapeDecoration(
                                    color: MiSwitchPalette.knob,
                                    shape: const CircleBorder(),
                                    shadows: knobShadow,
                                  ),
                                  child: SizedBox.square(dimension: size),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
