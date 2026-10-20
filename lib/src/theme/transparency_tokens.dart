import 'package:flutter/painting.dart';

import 'theme_mode.dart';

/// 统一透明/磨砂效果 token —— 玻璃类组件共享的「透明语言」。
///
/// 组件专属的材质配方（遮罩/透镜/描边等）留在各自 token 文件
/// （[MiGlassTokens]、[MiPillTabPalette]），本文件只收**跨组件共用**
/// 的透明参数，保证导航栏、胶囊标签等组件的透明效果同源同感：
///
///  * [blurSigma] —— backdrop 磨砂高斯模糊强度（所有 BackdropFilter 取此值）；
///  * 表面填充 alpha —— 半透明表面（胶囊等）的填充透明度，
///    平底（纯色背景）合成结果 = 截图实测实色，推导见各常量注释；
///  * [veilFor] —— **压在内容上**（照片/视频从下方经过）时那层玻璃膜。
///
/// alpha 以 0-255 字节表示（配合 `Color.fromARGB` 精确构造，
/// 避免 double opacity 的字节量化误差）。
class MiTransparencyTokens {
  MiTransparencyTokens._();

  /// 背景高斯模糊 sigma（所有 backdrop 磨砂组件同源；明暗通用）。
  static const double blurSigma = 28;

  /// 表面填充 alpha（未选中/低调表面）：onSurface @15/255 ≈ 6%，
  /// 明暗共用同一档（同为「onSurface @6%」语义）。
  ///
  ///  * 暗：白 @15 叠纯黑页底 #000000 → 合成 #0F0F0F（暗截图实测）；
  ///  * 亮：黑 @15 叠页底 #F3F3F3 → 合成 #E5E5E5（亮截图实测）。
  static const int fillAlphaSubtle = 15;

  /// 表面填充 alpha（选中/高亮表面）——高不透明，明暗各一档：
  ///
  ///  * 暗：白 @230 叠纯黑页底 #000000 → 合成 #E6E6E6（暗截图实测）；
  ///  * 亮：黑 @196 叠页底 #F3F3F3 → 合成 #383838（亮截图实测）。
  static const int fillAlphaStrongDark = 230;
  static const int fillAlphaStrongLight = 196;

  /// 玻璃膜 alpha（**压在内容上**的搜索栏 / 未选胶囊）：亮 = 页底色
  /// #F3F3F3 @117/255，暗 = 纯黑 @150/255。
  ///
  /// 与上面两档是**两种状态**，不是同一个配方的 alpha 不同 —— 平底页
  /// （分类页）的胶囊读作「比页底略暗的 #E5E5E5」，压在高频照片上的胶囊
  /// 读作「比背景亮/暗一大截的磨砂片」（首页截图实测）：
  ///  * 亮：胶囊内侧 ≈200、同 y 间隙 ≈167 → 反解 0.46（页底色叠上去，
  ///    0.46×243 + 0.54×167 = 202）；
  ///  * 暗：胶囊内侧 ≈70、同 y 间隙 ≈170 → 反解 0.59（0.41×170 = 70）。
  /// 光靠磨砂白不过去：模糊只改变局部对比、不改局部均值，+33 级（亮）
  /// / −100 级（暗）的落差只能来自膜本身。
  static const int veilAlphaLight = 117;
  static const int veilAlphaDark = 150;

  /// 页底色（亮 #F3F3F3 / 暗 #000000）—— 玻璃膜取这个色，明暗自洽。
  static const Color veilBaseLight = Color(0xFFF3F3F3);
  static const Color veilBaseDark = Color(0xFF000000);

  /// 按明暗模式取玻璃膜颜色（压在内容上的搜索栏 / 未选胶囊填充）。
  static Color veilFor(MiThemeMode mode) => mode == MiThemeMode.dark
      ? veilBaseDark.withAlpha(veilAlphaDark)
      : veilBaseLight.withAlpha(veilAlphaLight);
}

