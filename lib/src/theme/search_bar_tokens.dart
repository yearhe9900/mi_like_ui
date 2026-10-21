import 'package:flutter/painting.dart';

import 'colors.dart';
import 'theme_mode.dart';
import 'transparency_tokens.dart';

/// 搜索栏配色令牌（明暗双配方）。
///
/// 明暗两套均为设计度量值（分类页参考素材，明暗几何一致）。
///
/// 填充为**半透明**表面，与玻璃透明体系同一语言（0-255 字节 alpha +
/// `Color.fromARGB`）；纯色背景上合成结果为实色，背后有内容时透出：
///
///  * 亮：黑 @13 叠页底 #F3F3F3 → #E7E7E7；
///  * 暗：白 @36 叠页底 #000000 → #242424。
///
/// 与胶囊未选中的 [MiTransparencyTokens.fillAlphaSubtle]（15）不同档：
/// subtle 合成结果为亮 #E5E5E5 / 暗 #0F0F0F，与搜索栏实色不符，故独立
/// 取值（13 / 36）。backdrop 磨砂 σ 取 [MiTransparencyTokens.blurSigma]，
/// 与导航栏、胶囊标签同源。
///
/// 文字色（亮 #848484 / 暗 #6D6D6D）取笔画核心像素；放大镜墨色明暗同值
/// #9A9A9A，不随模式变色。
///
/// ## 搜索态
///
/// 输入态下占位文字与放大镜保持原位，新增两个取色：
///
///  * [caret] 光标 = 强调蓝（[MiColors.accent] 同族色）；
///  * [cancelInk] 取消钮叉号 = **前景墨色**（可点控件实心前景），与放大镜
///    的图标灰（[icon]）不同档，不可共用。
class MiSearchBarPalette {
  const MiSearchBarPalette({
    required this.fill,
    required this.hint,
    required this.icon,
    required this.caret,
    required this.cancelInk,
  });

  /// 半透明填充（平底合成 = 度量 #E7E7E7 / #242424）。
  final Color fill;

  /// 占位文字色（度量笔画核心）。
  final Color hint;

  /// 放大镜图标墨色（明暗同值，素材度量）。
  final Color icon;

  /// 输入光标色（搜索态，度量强调蓝）。
  final Color caret;

  /// 取消钮叉号墨色（搜索态，度量前景墨色 —— 比放大镜深一整档）。
  final Color cancelInk;

  /// 深色配方（暗色素材度量：平底合成 #242424）。
  static const MiSearchBarPalette dark = MiSearchBarPalette(
    fill: Color.fromARGB(
        MiTransparencyTokens.fillAlphaSearchDark, 255, 255, 255),
    hint: Color(0xFF6D6D6D),
    icon: Color(0xFF9A9A9A),
    caret: MiColors.accent,
    cancelInk: MiColors.foreground,
  );

  /// 浅色配方（亮色素材度量：平底合成 #E7E7E7）。
  static const MiSearchBarPalette light = MiSearchBarPalette(
    fill: Color.fromARGB(MiTransparencyTokens.fillAlphaSearchLight, 0, 0, 0),
    hint: Color(0xFF848484),
    icon: Color(0xFF9A9A9A),
    caret: MiColors.accent,
    cancelInk: MiColors.foregroundLight,
  );

  /// 按明暗模式取配方。
  static MiSearchBarPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;
}
