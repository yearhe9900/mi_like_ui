import 'package:flutter/painting.dart';

import 'colors.dart';
import 'theme_mode.dart';

/// 设置行组令牌（明暗双配方）。
///
/// **全部为推导值**（demo 样张目测，无逐像素度量 —— 与本库导航 / 顶栏的
/// 度量值不同级，数值升级为度量后在此替换并标注原始记录）：
///  * 卡片填充：亮纯白 / 暗 #1E1E1E（比页底高一档的表面层）；
///  * 按压高亮带：亮 #E7E7E7 / 暗 #3A3A3A（与搜索框填充同一灰语言）。
///
/// 副文 / 值文 / chevron 墨色为 onSurface 的 alpha 档（0.55 / 0.30），
/// 随明暗自动成立，不按模式分家。
class MiSettingsPalette {
  const MiSettingsPalette._();

  /// 卡片填充。
  static Color cardFor(MiThemeMode mode) =>
      mode == MiThemeMode.light ? const Color(0xFFFFFFFF) : const Color(0xFF1E1E1E);

  /// 按压高亮带。
  static Color pressFor(MiThemeMode mode) =>
      mode == MiThemeMode.light ? const Color(0xFFE7E7E7) : const Color(0xFF3A3A3A);

  /// 主文案墨色（前景主色，明暗取 [MiColors.foregroundFor]）。
  static Color labelFor(MiThemeMode mode) => MiColors.foregroundFor(mode);

  /// 副文 / 值文墨色（主墨 @55%）。
  static Color secondaryFor(MiThemeMode mode) =>
      labelFor(mode).withValues(alpha: 0.55);

  /// chevron 墨色（主墨 @30%）。
  static Color chevronFor(MiThemeMode mode) =>
      labelFor(mode).withValues(alpha: 0.30);
}
