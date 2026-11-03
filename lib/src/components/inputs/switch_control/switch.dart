import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../theme/colors.dart';
import '../../../theme/motion_tokens.dart';
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
/// （onSurface @12% state layer）。
///
/// 交互经 [MiPressable]：点按 / Enter / Space 切换（[onChanged] 为
/// null = 禁用：不可点、不可聚焦、整体降到禁用透明档）。切换动效 =
/// 钮体沿行程的**吸附弹簧**（临界阻尼无过冲，[MiSwitchMetrics.snap]，
/// `AnimationController.animateWith(SpringSimulation)` 驱动，轨道色随
/// 行程插值）；无涟漪 —— 扩散涟漪属素材语义，不发明。
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

class _MiSwitchState extends State<MiSwitch> with SingleTickerProviderStateMixin {
  /// 钮体行程进度 0…1（无界 controller：吸附弹簧可带轻微越界观感）。
  late final AnimationController _ctrl = AnimationController.unbounded(
    vsync: this,
    value: widget.value ? 1 : 0,
  );

  @override
  void didUpdateWidget(MiSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _ctrl.animateWith(
        SpringSimulation(
          MiSwitchMetrics.snap,
          _ctrl.value,
          widget.value ? 1 : 0,
          0,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
        child: MiPressable(
          onPressed: enabled ? () => widget.onChanged!(!widget.value) : null,
          mode: mode,
          borderRadius: BorderRadius.circular(MiSwitchMetrics.trackHeight / 2),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, knob) {
              final t = _ctrl.value.clamp(0.0, 1.0);
              return SizedBox(
                width: MiSwitchMetrics.trackWidth,
                height: MiSwitchMetrics.trackHeight,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: Color.lerp(trackOff, trackOn, t),
                    shape: const MiSquircleBorder(
                      MiSwitchMetrics.trackHeight / 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: MiSwitchMetrics.knobInset +
                            t * MiSwitchMetrics.travel,
                        top: MiSwitchMetrics.knobInset,
                        child: knob!,
                      ),
                    ],
                  ),
                ),
              );
            },
            child: DecoratedBox(
              key: MiSwitch.knobKey,
              decoration: ShapeDecoration(
                color: MiSwitchPalette.knob,
                shape: const CircleBorder(),
                shadows: knobShadow,
              ),
              child: const SizedBox.square(
                dimension: MiSwitchMetrics.knobSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
