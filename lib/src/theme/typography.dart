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

  /// 按钮标签：「我的关注」页实测墨高 35px、em≈40px → 13dp、Medium
  /// （笔画核心 3px ≈ 0.075em，与胶囊标签同档）。
  ///
  /// 标签色随形态 + 明暗模式变化，由 `button` 从
  /// `theme/button_tokens.dart` 取色，故此样式不预置颜色。
  static const TextStyle buttonLabel = TextStyle(
    fontSize: 13,
    height: 1.0,
    fontWeight: FontWeight.w500,
  );

  /// 搜索栏占位文字：亮/暗完整截图实测 CJK 字面 advance 37px → 16.5dp
  /// （两图交叉一致，栏内垂心居中）。墨色偏灰属次级信息，字重未见
  /// 实测证据取常规 Regular。占位色随明暗由 `theme/search_bar_tokens.dart`
  /// 供给，故此样式不预置颜色。
  static const TextStyle searchHint = TextStyle(
    fontSize: 16.5,
    height: 1.0,
    fontWeight: FontWeight.w400,
  );

  /// 顶栏大标题：录屏实测 5 字墨宽 482px、相邻字面左缘间距 98/99/100/98px
  /// → CJK 字面 advance 98.8px ≈ **31.83dp**；笔画核心 7px ⇒ 7/98.8 =
  /// 0.071em，与胶囊标签同档 Medium。墨色取框架前景色（实测笔画内部 246）。
  static const TextStyle topBarLargeTitle = TextStyle(
    color: MiColors.foreground,
    fontSize: 31.83,
    height: 1.0,
    fontWeight: FontWeight.w500,
  );

  /// 按明暗模式取大标题样式（字面量模式下与 [topBarLargeTitle] 一致）。
  static TextStyle topBarLargeTitleFor(MiThemeMode mode) => mode == MiThemeMode.dark
      ? topBarLargeTitle
      : topBarLargeTitle.copyWith(color: MiColors.foregroundLight);

  /// 顶栏紧凑标题：录屏实测 5 字墨宽 273px → advance 55.9px ≈ **18.0dp**；
  /// 笔画核心 4.5px ⇒ 0.080em，同档 Medium。与 [topBarLargeTitle] 同为中国
  /// 大陆字体度量，`height: 1.0` 下由 `MiTopBarMetrics` 按墨心定位。
  static const TextStyle topBarCompactTitle = TextStyle(
    color: MiColors.foreground,
    fontSize: 18.0,
    height: 1.0,
    fontWeight: FontWeight.w500,
  );

  /// 按明暗模式取紧凑标题样式（字面量模式下与 [topBarCompactTitle] 一致）。
  static TextStyle topBarCompactTitleFor(MiThemeMode mode) => mode == MiThemeMode.dark
      ? topBarCompactTitle
      : topBarCompactTitle.copyWith(color: MiColors.foregroundLight);

  /// 卡片标题：首页「精选主题」卡实测字符 pitch 31px → 13.85dp、Medium
  /// （笔画核心 2~3px @31px em ≈ 0.07em，与胶囊标签同档同值）。
  ///
  /// 标题墨色随明暗模式变化，由 `theme_card` 经 `MiColors.foregroundFor`
  /// 取色，故此样式不预置颜色。
  static const TextStyle cardTitle = TextStyle(
    fontSize: 13.85,
    height: 1.0,
    fontWeight: FontWeight.w500,
  );
}
