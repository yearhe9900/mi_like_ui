import 'package:flutter/painting.dart';

import 'colors.dart';
import 'dialog_tokens.dart';
import 'theme_mode.dart';
import 'transparency_tokens.dart';

/// 复选框配色令牌（明暗双配方）—— **不新造色值**，全部引用既有 token：
///
///  * 选中填充 = [MiColors.accent]（全库强调同一档：主按钮、滑条活动段、
///    搜索光标同色；复选框没有理由再开一档蓝）；
///  * 勾号墨色 = 白（`MiDialogPalette.filledActionLabel`，度量精确 #FFFFFF）
///    —— 强调蓝填充上的唯一可读档；
///  * 未选圆底 = [MiTransparencyTokens.controlOffFillFor]（onSurface @12%，
///    与开关关闭轨同一 state layer 档，见该常量注释）。
///
/// **参考来源**：`flutter_miuix` 的 `MiuixCheckboxDefaults`（其源自 HyperOS
/// 组件规格）—— 三态（开 / 关 / 半选）、⌀26 圆底、勾号 trim 动效。
/// 本库**无复选框实机素材**，故几何与动效按参考实现采用（[MiCheckboxMetrics]
/// 逐项标注「参考实现，非本库度量」），配色改走本库既有 token。
class MiCheckboxPalette {
  const MiCheckboxPalette._({
    required this.checkedFill,
    required this.checkInk,
    required this.uncheckedFill,
  });

  /// 选中态圆底填充（强调色，明暗同值）。
  final Color checkedFill;

  /// 勾号 / 半选横杠墨色（压在同色强调填充上）。
  final Color checkInk;

  /// 未选态圆底填充（onSurface @12% state layer）。
  final Color uncheckedFill;

  /// 按明暗模式取配方。
  static MiCheckboxPalette of(MiThemeMode mode) => mode == MiThemeMode.dark
      ? MiCheckboxPalette._(
          checkedFill: MiColors.accent,
          checkInk: MiDialogPalette.dark.filledActionLabel,
          uncheckedFill: MiTransparencyTokens.controlOffFillFor(mode),
        )
      : MiCheckboxPalette._(
          checkedFill: MiColors.accent,
          checkInk: MiDialogPalette.light.filledActionLabel,
          uncheckedFill: MiTransparencyTokens.controlOffFillFor(mode),
        );
}
