import 'package:flutter/painting.dart';

import 'colors.dart';
import 'settings_tokens.dart';
import 'theme_mode.dart';
import 'transparency_tokens.dart';

/// 菜单配色令牌（明暗双配方）。
///
/// **不新造色值**，全部落在既有 token 上：
///
///  * 面板填充 = 弹框卡片填充（`MiDialogPalette.surface` 同值：暗 #242424 /
///    亮 #FFFFFF）—— 同一层「浮起来的面」，菜单与弹框并排出现时不该有两个白；
///  * 主文案 = 前景主色（[MiColors.foregroundFor]）；
///  * 副文案 = 设置行副文同一档（[MiSettingsPalette.secondaryFor]，主墨 @55%）；
///  * 选中文案 / 勾号 = 品牌强调色（[MiColors.accent]，全库唯一强调档）；
///  * 禁用文案 = onSurface @38%（[MiTransparencyTokens.disabledLabelDark]）；
///  * 分隔线 = 弹框操作列表分隔线（onSurface @0.08）；
///  * 按压高亮 = 弹框按钮按压叠色压到面板填充上的**预合成实色**（不引 saveLayer）；
///  * 遮罩 = [MiTransparencyTokens.menuScrimProgressFor]。
///
/// **参考来源**：`flutter_miuix`（Apache-2.0）的 `MiuixDropdownDefaults`
/// （上游 compose-miuix 的 HyperOS 下拉规格）。本库**无菜单实机素材**，
/// 几何与动效按参考实现采用（见 `MiMenuMetrics`），配色改走本库既有 token。
///
/// 两个配方是 `static final`（不是 `const`）：副文案色由
/// [MiSettingsPalette.secondaryFor] 按模式算出来，与设置行共用同一份计算，
/// 避免把「主墨 @55%」这个配方抄第二遍。
class MiMenuPalette {
  const MiMenuPalette._({
    required this.surface,
    required this.label,
    required this.secondary,
    required this.selectedLabel,
    required this.disabled,
    required this.divider,
    required this.pressed,
  });

  /// 面板填充（浮起来的表面）。
  final Color surface;

  /// 主文案墨色。
  final Color label;

  /// 副文案墨色。
  final Color secondary;

  /// 选中项的主文案 + 勾号墨色。
  final Color selectedLabel;

  /// 禁用项墨色（主 / 副文案同档）。
  final Color disabled;

  /// 分组分隔线。
  final Color divider;

  /// 行按压高亮（预合成实色，直接铺）。
  final Color pressed;

  /// 深色配方。
  static final MiMenuPalette dark = MiMenuPalette._(
    surface: MiTransparencyTokens.menuSurfaceDark,
    label: MiColors.foreground,
    secondary: MiSettingsPalette.secondaryFor(MiThemeMode.dark),
    selectedLabel: MiColors.accent,
    disabled: MiTransparencyTokens.disabledLabelDark,
    divider: MiTransparencyTokens.dialogDividerDark,
    pressed: MiTransparencyTokens.menuPressDark,
  );

  /// 浅色配方。
  static final MiMenuPalette light = MiMenuPalette._(
    surface: MiTransparencyTokens.menuSurfaceLight,
    label: MiColors.foregroundLight,
    secondary: MiSettingsPalette.secondaryFor(MiThemeMode.light),
    selectedLabel: MiColors.accent,
    disabled: MiTransparencyTokens.disabledLabelLight,
    divider: MiTransparencyTokens.dialogDividerLight,
    pressed: MiTransparencyTokens.menuPressLight,
  );

  /// 按明暗模式取配方。
  static MiMenuPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;

  /// 按明暗 + 遮罩淡入进度取遮罩色（进度由菜单组件下发）。
  static Color scrimFor(MiThemeMode mode, double progress) =>
      MiTransparencyTokens.menuScrimProgressFor(mode, progress);
}
