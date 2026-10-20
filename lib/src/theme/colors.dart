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

  /// 强调蓝：主按钮填充（「我的关注」页亮/暗两张截图实测同为 #4980F7），
  /// 也是搜索态输入光标的取色（参考录屏实测 rgb(60,130,246)，同一族强调色，
  /// 差值来自视频压缩 / 细笔画的边缘混色）。
  static const Color accent = Color(0xFF4980F7);

  /// 页底色（浅色）：主题商店首页/分类页实测 #F3F3F3，玻璃膜的基色同源。
  static const Color pageBackgroundLight = Color(0xFFF3F3F3);

  /// 页底色（深色）：实测纯黑（OLED 直接关灯，不是深灰）。
  static const Color pageBackgroundDark = Color(0xFF000000);

  /// 按明暗模式取页底色。
  static Color pageBackgroundFor(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? pageBackgroundDark : pageBackgroundLight;

  /// 强调绿（深色）：预留空位圆形按钮底色（暗色视频实测 rgb(37,191,67)）。
  static const Color fabGreen = Color(0xFF25BF43);

  /// 强调绿（浅色）：亮色参考图实测 #66CB61（1220×308 采样）。
  static const Color fabGreenLight = Color(0xFF66CB61);

  /// 按明暗模式取强调绿。
  static Color fabGreenFor(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? fabGreen : fabGreenLight;
}
