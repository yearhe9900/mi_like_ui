import 'dart:ui';

import 'colors.dart';
import 'dialog_tokens.dart';
import 'theme_mode.dart';

/// Snackbar 配色（明暗双配方）—— **不新造色值**，全部引用既有 token：
///
///  * 表面与弹出面板同值（暗 #2C2C2C / 亮 #FFFFFF —— 系统浮层表面同一
///    档，出处见 `MiPullUpPanel` 度量注释）；
///  * 正文墨色 = 弹框标题墨色（`MiDialogPalette.title`，实测墨色）；
///  * 动作色 = [MiColors.accent]（明暗同色，全库强调同一档）。
class MiSnackbarPalette {
  const MiSnackbarPalette._(this.surface, this.text, this.action);

  /// 浮层表面（不透明；暗底不投影、亮底投轻影，见 metrics）。
  final Color surface;

  /// 正文墨色。
  final Color text;

  /// 动作文字（强调色）。
  final Color action;

  /// 按明暗模式取配方。
  static MiSnackbarPalette of(MiThemeMode mode) => mode == MiThemeMode.dark
      ? MiSnackbarPalette._(
          const Color(0xFF2C2C2C),
          MiDialogPalette.dark.title,
          MiColors.accent,
        )
      : MiSnackbarPalette._(
          const Color(0xFFFFFFFF),
          MiDialogPalette.light.title,
          MiColors.accent,
        );
}
