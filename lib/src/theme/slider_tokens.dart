import 'dart:ui';

import 'theme_mode.dart';

/// `MiSlider` 配色。
///
/// **不新造主色**：活动轨道 = [MiColors.accent]（与主按钮 / 开关开启档同源）、
/// 非活动轨道 = `MiTransparencyTokens.switchTrackOffFor`（onSurface @12% state
/// layer，与开关关闭档同源）。本文件只收推导出来的零件色：
///
///  * 钮体 / 选中关键点 = 纯白（与开关钮同口径，落在强调蓝上对比足够）；
///  * 未选中关键点 = 一档中性灰（**推导值**：轨道本身是 onSurface @12%，
///    灰色点要既离开轨道又不抢眼 —— 深色 #5A5A5A / 浅色 #B4B4B4 分别相当于
///    在轨道上再提亮一档）。
class MiSliderPalette {
  const MiSliderPalette._();

  /// 钮体（明暗同色：白钮，与 `MiSwitchPalette.knob` 同口径）。
  static const Color thumb = Color(0xFFFFFFFF);

  /// 已越过（在活动段一侧）的关键点：与钮体同色，落在强调蓝上仍可辨。
  static const Color keyPointOn = Color(0xFFFFFFFF);

  /// 未越过（在非活动段一侧）的关键点（推导值，见类文档）。
  static const Color keyPointOffDark = Color(0xFF5A5A5A);
  static const Color keyPointOffLight = Color(0xFFB4B4B4);

  /// 按明暗模式取未选中关键点色。
  static Color keyPointOffFor(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? keyPointOffDark : keyPointOffLight;
}
