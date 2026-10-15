import 'package:flutter/painting.dart';

import 'theme_mode.dart';

/// 全局颜色 token（框架级，跨组件共用）。
///
/// 新组件取色一律引用这里，不在组件内散落字面量颜色。
class MiColors {
  MiColors._();

  /// 前景主色（深色模式）：图标、标签等近白内容色（视频实测 #F5F5F5）。
  static const Color foreground = Color(0xFFF5F5F5);

  /// 前景主色（浅色模式）：图标、标签等近黑内容色（亮色截图实测 ≈#050505）。
  static const Color foregroundLight = Color(0xFF050505);

  /// 按明暗模式取前景主色。
  static Color foregroundFor(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? foreground : foregroundLight;

  /// 强调绿：预留空位圆形按钮底色（视频实测 rgb(37,191,67)，明暗通用）。
  static const Color fabGreen = Color(0xFF25BF43);
}
