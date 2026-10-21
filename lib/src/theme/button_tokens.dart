import 'package:flutter/painting.dart';

import 'colors.dart';
import 'theme_mode.dart';
import 'transparency_tokens.dart';

/// 按钮配色令牌（明暗双配方）。
///
/// **filled（主按钮）为度量值**：填充 #4980F7 明暗同色、标签纯白（明暗
/// 两组参考素材一致，仅页面底色不同）。
///
/// **tonal（次级）与 disabled（禁用）为推导值**，复用已度量的表面灰与
/// 墨色：
///  * tonal 填充 = 搜索栏表面灰（亮 #E7E7E7 / 暗 #242424），标签 = 胶囊
///    标签墨色（亮 #161616 / 暗 #F3F3F3）；
///  * disabled = onSurface @12% 填充 + @38% 文字（Material 常规做法；
///    前景色取 `MiColors.foregroundFor`，逐色写成字面量以便 const 配方）。
///
/// 胶囊无描边、无投影。
class MiButtonPalette {
  const MiButtonPalette({
    required this.filledFill,
    required this.filledLabel,
    required this.tonalFill,
    required this.tonalLabel,
    required this.disabledFill,
    required this.disabledLabel,
  });

  /// 主按钮填充（度量 #4980F7，明暗同值）。
  final Color filledFill;

  /// 主按钮标签（度量纯白，明暗同值）。
  final Color filledLabel;

  /// 次级按钮填充（推导：搜索栏度量灰）。
  final Color tonalFill;

  /// 次级按钮标签（推导：胶囊标签度量墨色）。
  final Color tonalLabel;

  /// 禁用态填充（推导：onSurface@12%）。
  final Color disabledFill;

  /// 禁用态标签（推导：onSurface@38%）。
  final Color disabledLabel;

  /// 深色配方。
  static const MiButtonPalette dark = MiButtonPalette(
    filledFill: MiColors.accent,
    filledLabel: Color(0xFFFFFFFF),
    tonalFill: Color(0xFF242424),
    tonalLabel: Color(0xFFF3F3F3),
    disabledFill: Color.fromARGB(
        MiTransparencyTokens.disabledFillAlpha, 0xF5, 0xF5, 0xF5), // @12%
    disabledLabel: Color.fromARGB(
        MiTransparencyTokens.disabledLabelAlpha, 0xF5, 0xF5, 0xF5), // @38%
  );

  /// 浅色配方。
  static const MiButtonPalette light = MiButtonPalette(
    filledFill: MiColors.accent,
    filledLabel: Color(0xFFFFFFFF),
    tonalFill: Color(0xFFE7E7E7),
    tonalLabel: Color(0xFF161616),
    disabledFill: Color.fromARGB(
        MiTransparencyTokens.disabledFillAlpha, 0x05, 0x05, 0x05), // @12%
    disabledLabel: Color.fromARGB(
        MiTransparencyTokens.disabledLabelAlpha, 0x05, 0x05, 0x05), // @38%
  );

  /// 按明暗模式取配方。
  static MiButtonPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;
}
