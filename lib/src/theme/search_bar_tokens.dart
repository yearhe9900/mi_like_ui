import 'package:flutter/painting.dart';

import 'colors.dart';
import 'theme_mode.dart';
import 'transparency_tokens.dart';

/// 搜索栏配色 token（完整截图实测，明暗双配方）。
///
/// 明暗两套均 1:1 实测自主题商店分类页完整截图（881x1920，亮/暗各一张，
/// 几何完全一致：栏 y=117..215、左右 inset ≈12、stadium 圆角）。
///
/// 填充是**半透明**表面，与玻璃透明体系同一语言（0-255 字节 alpha +
/// `Color.fromARGB`，同 [MiTransparencyTokens]）；平底（纯色背景）合成
/// 结果 = 截图实测实色，半透明仅在背后有内容时透出：
///  * 亮：黑 @13 叠页底 #F3F3F3 → 合成 #E7E7E7（实测反推 a=12.6≈13）；
///  * 暗：白 @36 叠页底 #000000 → 合成 #242424（实测反推 a=36）。
///
/// **不是**胶囊未选中的 [MiTransparencyTokens.fillAlphaSubtle]（15）档：
/// 代入 15 平底合成亮 #E5E5E5 / 暗 #0F0F0F，暗色较实测 #242424 偏差
/// 21 级，故搜索栏用实测反推的专档（13 / 36），不套 subtle。
/// backdrop 磨砂 sigma 由组件取 [MiTransparencyTokens.blurSigma]，
/// 与底部导航栏 `MiGlassNavBar`、胶囊标签同源（见 `search_bar.dart`）。
///
/// 文字色取笔画核心像素中位数（亮 #848484 / 暗 #6D6D6D，JPEG 边缘
/// 振铃只有核心值可信）；放大镜墨色明暗两图同值 #9A9A9A（双图交叉
/// 实测 #9A/#9B），不随模式变色。
///
/// ## 搜索态（同一张录屏的第二态，2026-10-20 实测）
///
/// 点按搜索栏后进入搜索态：占位文字与放大镜**不变**（都留在原位），多出一个
/// 输入光标和一个取消钮。两个新颜色各自单独实测：
///  * [caret] 光标 = 强调蓝。录屏稳态像素 rgb(60,130,246)，与主按钮实测
///    #4980F7 同族（差值来自细笔画的边缘混色 + 视频压缩），故直接引用
///    [MiColors.accent]，不另立一档；
///  * [cancelInk] 取消钮叉号 = **前景墨色**（实测纯黑 0/255），**不是**放大镜
///    那档灰 #9A9A9A —— 同一页里放大镜实测 167、叉号实测 0，两者差了一整档，
///    不能共用 [icon]。
class MiSearchBarPalette {
  const MiSearchBarPalette({
    required this.fill,
    required this.hint,
    required this.icon,
    required this.caret,
    required this.cancelInk,
  });

  /// 半透明填充（平底合成 = 实测 #E7E7E7 / #242424）。
  final Color fill;

  /// 占位文字色（实测笔画核心）。
  final Color hint;

  /// 放大镜图标墨色（明暗同值，截图实测）。
  final Color icon;

  /// 输入光标色（搜索态，实测强调蓝）。
  final Color caret;

  /// 取消钮叉号墨色（搜索态，实测前景墨色 —— 比放大镜深一整档）。
  final Color cancelInk;

  /// 深色配方（暗色截图实测：平底合成 #242424）。
  static const MiSearchBarPalette dark = MiSearchBarPalette(
    fill: Color.fromARGB(
        MiTransparencyTokens.fillAlphaSearchDark, 255, 255, 255),
    hint: Color(0xFF6D6D6D),
    icon: Color(0xFF9A9A9A),
    caret: MiColors.accent,
    cancelInk: MiColors.foreground,
  );

  /// 浅色配方（亮色截图实测：平底合成 #E7E7E7）。
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
