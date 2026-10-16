import 'package:flutter/painting.dart';

import 'theme_mode.dart';
import 'transparency_tokens.dart';

/// 胶囊分类标签（pill tab）配色 token（完整截图实测，明暗双配方）。
///
/// 明暗两套均 1:1 实测自主题商店分类 tab 完整截图（1220x2656，亮/暗各一
/// 张，几何完全一致）。文字色取笔画核心像素亮度（JPEG 边缘振铃会下探
/// 20+ 级，只有核心值是字面色）：
///  * 亮色：选中 #383838 + 纯白标签；未选 #E5E5E5 + 近黑
///    #161616（核心亮度中位数 22）；
///  * 暗色：选中 #E6E6E6 + 近黑 #171717 标签；未选 #0F0F0F +
///    #F3F3F3 —— 未选胶囊仅比纯黑页底 (#000000) 高约 15 级，是截图里
///    刻意的低调嵌入效果，勿"修正"为高对比灰；
///  * 胶囊无描边无投影（边缘外 1px 即回页面底色）。
///
/// 填充是**半透明**表面（与玻璃透明体系统一，见 [MiTransparencyTokens]）：
/// 未选 = onSurface@≈6%、选中 = 高不透明两档，平底（纯色背景）合成
/// 结果恰为上列实测实色，半透明仅在背后有内容时透出。
class MiPillTabPalette {
  const MiPillTabPalette({
    required this.selectedFill,
    required this.selectedLabel,
    required this.unselectedFill,
    required this.unselectedLabel,
  });

  /// 选中胶囊填充（半透明，平底合成 = 实测 #E6E6E6 / #383838）。
  final Color selectedFill;

  /// 选中胶囊标签色。
  final Color selectedLabel;

  /// 未选中胶囊填充（半透明 onSurface@≈6%，平底合成 = 实测 #0F0F0F / #E5E5E5）。
  final Color unselectedFill;

  /// 未选中胶囊标签色。
  final Color unselectedLabel;

  /// 深色配方（暗色截图实测）。
  static const MiPillTabPalette dark = MiPillTabPalette(
    selectedFill: Color.fromARGB(MiTransparencyTokens.fillAlphaStrongDark, 255, 255, 255),
    selectedLabel: Color(0xFF171717),
    unselectedFill: Color.fromARGB(MiTransparencyTokens.fillAlphaSubtle, 255, 255, 255),
    unselectedLabel: Color(0xFFF3F3F3),
  );

  /// 浅色配方（亮色截图实测）。
  static const MiPillTabPalette light = MiPillTabPalette(
    selectedFill: Color.fromARGB(MiTransparencyTokens.fillAlphaStrongLight, 0, 0, 0),
    selectedLabel: Color(0xFFFFFFFF),
    unselectedFill: Color.fromARGB(MiTransparencyTokens.fillAlphaSubtle, 0, 0, 0),
    unselectedLabel: Color(0xFF161616),
  );

  /// 按明暗模式取配方。
  static MiPillTabPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;
}
