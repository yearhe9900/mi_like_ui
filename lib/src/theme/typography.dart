import 'package:flutter/painting.dart';

import 'colors.dart';
import 'theme_mode.dart';

/// 全局文字样式 token。
///
/// 组件内文字一律引用这里预置的 [TextStyle]，字号/字重不在组件里散落。
class MiTypography {
  MiTypography._();

  /// 导航栏标签：视频实测 CJK 字高 31px → 10.5dp、Medium 字重。
  static const TextStyle navLabel = TextStyle(
    color: MiColors.foreground,
    fontSize: 10.5,
    height: 1.0,
    fontWeight: FontWeight.w500,
  );

  /// 按明暗模式取导航栏标签样式（字面量模式下与 [navLabel] 一致）。
  static TextStyle navLabelFor(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? navLabel : navLabel.copyWith(color: MiColors.foregroundLight);

  /// 胶囊分类标签：截图实测 CJK 字面 pitch 43px → 13.85dp、Medium 字重。
  ///
  /// 标签色随选中态 + 明暗模式变化，由 `pill_tab_bar` 从
  /// `theme/pill_tab_tokens.dart` 取色，故此样式不预置颜色。
  static const TextStyle pillLabel = TextStyle(
    fontSize: 13.85,
    height: 1.0,
    fontWeight: FontWeight.w500,
  );
}
