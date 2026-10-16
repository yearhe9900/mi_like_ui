import 'package:flutter/painting.dart';

import 'theme_mode.dart';

/// 按钮配色 token（明暗双配方）。
///
/// **filled（主按钮）= 实测**：「我的关注」页关注按钮，亮/暗两张完整截图
/// （1220x2656）填充同为 **#4980F7**、标签纯白 —— 主按钮不随明暗换配方，
/// 两张参考图唯一不同的只有页面底色。
///
/// **tonal（次级 / 已关注）与 disabled（禁用）在参考图中未出现，属推导
/// 样式**，取值一律复用已实测的 MIUI 表面灰与墨色：
///  * tonal 填充 = 分类页搜索栏实测灰（亮 #E7E7E7 / 暗 #242424），
///    标签 = 胶囊标签实测墨色（亮 #161616 / 暗 #F3F3F3）；
///  * disabled = Material 常规 onSurface@12% 填充 + @38% 文字
///    （前景色取 `MiColors.foregroundFor` 的两模式实测值，逐色写成
///    字面量以便 const 配方）。
///
/// 胶囊无描边无投影，与参考图一致。
class MiButtonPalette {
  const MiButtonPalette({
    required this.filledFill,
    required this.filledLabel,
    required this.tonalFill,
    required this.tonalLabel,
    required this.disabledFill,
    required this.disabledLabel,
  });

  /// 主按钮填充（实测 #4980F7，明暗同值）。
  final Color filledFill;

  /// 主按钮标签（实测纯白，明暗同值）。
  final Color filledLabel;

  /// 次级按钮填充（推导：搜索栏实测灰）。
  final Color tonalFill;

  /// 次级按钮标签（推导：胶囊标签实测墨色）。
  final Color tonalLabel;

  /// 禁用态填充（推导：onSurface@12%）。
  final Color disabledFill;

  /// 禁用态标签（推导：onSurface@38%）。
  final Color disabledLabel;

  /// 深色配方。
  static const MiButtonPalette dark = MiButtonPalette(
    filledFill: Color(0xFF4980F7),
    filledLabel: Color(0xFFFFFFFF),
    tonalFill: Color(0xFF242424),
    tonalLabel: Color(0xFFF3F3F3),
    disabledFill: Color(0x1FF5F5F5), // #F5F5F5 @12%
    disabledLabel: Color(0x61F5F5F5), // #F5F5F5 @38%
  );

  /// 浅色配方。
  static const MiButtonPalette light = MiButtonPalette(
    filledFill: Color(0xFF4980F7),
    filledLabel: Color(0xFFFFFFFF),
    tonalFill: Color(0xFFE7E7E7),
    tonalLabel: Color(0xFF161616),
    disabledFill: Color(0x1F050505), // #050505 @12%
    disabledLabel: Color(0x61050505), // #050505 @38%
  );

  /// 按明暗模式取配方。
  static MiButtonPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;
}
