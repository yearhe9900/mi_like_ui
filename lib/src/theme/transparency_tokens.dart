/// 统一透明/磨砂效果 token —— 玻璃类组件共享的「透明语言」。
///
/// 组件专属的材质配方（遮罩/透镜/描边等）留在各自 token 文件
/// （[MiGlassTokens]、[MiPillTabPalette]），本文件只收**跨组件共用**
/// 的透明参数，保证导航栏、胶囊标签等组件的透明效果同源同感：
///
///  * [blurSigma] —— backdrop 磨砂高斯模糊强度（所有 BackdropFilter 取此值）；
///  * 表面填充 alpha —— 半透明表面（胶囊等）的填充透明度，
///    平底（纯色背景）合成结果 = 截图实测实色，推导见各常量注释。
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
}
