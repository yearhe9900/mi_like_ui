import 'dart:ui';

/// `MiSwitch` 配色 —— **不新造色值**：开启档 = `MiColors.accent`、
/// 关闭档 = `MiTransparencyTokens.switchTrackOffFor`，本文件只收明暗
/// 同色的常量零件。
class MiSwitchPalette {
  const MiSwitchPalette._();

  /// 钮体（明暗同色：白钮 —— Material / HyperOS 开关同款观感，推导）。
  static const Color knob = Color(0xFFFFFFFF);
}
