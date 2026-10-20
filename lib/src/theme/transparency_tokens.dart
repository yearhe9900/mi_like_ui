import 'package:flutter/painting.dart';

import 'colors.dart';
import 'theme_mode.dart';

/// **统一的透明 / 磨砂配置** —— 全项目的 alpha、blur σ、玻璃膜色只能来自这里。
///
/// 透明效果是这套 UI 的主线（顶栏叠色、渐进磨砂、玻璃导航栏、搜索栏、
/// 胶囊行都靠它），参数散在各组件 token 里时最容易出现「同一个值抄两遍、
/// 改一处漏一处」。因此约定：
///
///  * **数值只在这里定义**（alpha / σ / 膜色 / 曲线采样色）；
///  * 组件 token（`MiGlassPalette`、`MiTopBarPalette`、`MiSearchBarPalette`、
///    `MiPillTabPalette`、`MiGradientBlurProfile`）只负责**引用这些常量** +
///    自己的几何（stops、圆角、段高）；
///  * 组件里不得出现 `withOpacity` / `fromRGBO` / 带 alpha 的十六进制色 ——
///    由 `test/transparency_config_test.dart` 扫描源码守门。
///
/// alpha 优先用 0-255 字节表示（配合 `Color.fromARGB` 精确构造，避开 double
/// 量化的字节误差）；而**实测值本身就是小数**的地方（录屏反解出的 0.63 /
/// 0.094 等）保留 double + `Color.fromRGBO`，与实测口径一致，也避免
/// 0.63 → 161/255 这类取整偏差让黄金图漂移。
class MiTransparencyTokens {
  MiTransparencyTokens._();

  // ══ 一、模糊 σ（dp）══════════════════════════════════════════════════════

  /// backdrop 磨砂 sigma（**零件自带**那层：玻璃导航栏 / 搜索栏 / 胶囊行；明暗通用）。
  static const double blurSigma = 28;

  /// 顶栏渐进曲线的**平台段** σ（dp）。取 10-90% 边缘宽度 42.7px 换算：
  /// σ = 42.7 / 2.563 × 0.32213 = 5.37dp（频谱比法在 67.5dp 给出 4.34dp、
  /// 90dp 处 1.85dp，与衰减曲线一致）。
  static const double blurSigmaTop = 5.37;

  /// 低于该 σ 的模糊段**不绘制**：高斯半径 < 1dp 落在亚像素，渲染结果与
  /// 「不模糊」在任意 dpr 下都不可分辨（实测曲线尾部 0.76 / 0.27 即属此列）。
  static const double minVisibleSigma = 0.5;

  /// 渐进曲线从顶部到「完全清晰」的**名义**跨度（dp）。
  ///
  /// 这是 128.9dp 材质盒上量出来的值；作用区更高时曲线会**等比拉伸**到
  /// 区底归零（形状固定、范围跟着走），见 `MiGradientBlur.bandsFor`。
  static const double nominalBlurExtent = 119;

  /// 顶栏渐进曲线的 **8 档 σ**（dp），顺序 = 从栏顶到栏底。
  ///
  /// 取实测控制点 (0, 5.37) (35, 5.37) (50, 4.96) (67.5, 4.34) (90, 1.85)
  /// (103, 0.76) (119, 0) 的分段线性插值在段中点处的值。段高与段位是几何，
  /// 见 `MiGradientBlurProfile.bands`；本表是它们的**强度来源**。
  static const List<double> blurSigmaRamp = <double>[
    5.37, // 平台段 0…35
    5.15,
    4.68, // 50.1dp 测点 4.96
    3.80, // 67.5dp 测点 4.34
    2.50,
    1.45, // 90.0dp 测点 1.85
    0.70, // 103dp 测点 0.76
    0.30,
  ];

  // ══ 二、表面填充 alpha（0-255 字节）══════════════════════════════════════

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

  /// 搜索栏填充 alpha（平底页低调档，与胶囊同一套语言但更薄）：
  ///
  ///  * 暗：白 @36 叠纯黑页底 → 合成 #242424（实测反推 a=36）；
  ///  * 亮：黑 @13 叠页底 #F3F3F3 → 合成 #E7E7E7（实测反推 a=12.6≈13）。
  static const int fillAlphaSearchDark = 36;
  static const int fillAlphaSearchLight = 13;

  /// 禁用态 alpha（**推导（非实测）** —— 参考图没有禁用态，取 Material 常规
  /// 做法）：填充 onSurface @31/255 ≈ 12%、文字 onSurface @97/255 ≈ 38%。
  static const int disabledFillAlpha = 0x1F; // 31 → 12.2%
  static const int disabledLabelAlpha = 0x61; // 97 → 38.0%

  // ══ 三、玻璃膜（压在内容上）══════════════════════════════════════════════

  /// 玻璃膜 alpha（**压在内容上**时垫在低调填充之下那层）：亮 = 页底色
  /// #F3F3F3 @153/255，暗 = 纯黑 @167/255。
  ///
  /// 反解口径是**最终合成值**（膜 + 低调填充两层叠完，与截图对比胶囊内侧/
  /// 同 y 间隙）：
  ///  * 亮：间隙 167、胶囊内侧 200 → `0.9412×(167 + 76a) = 200` → a ≈ 0.60；
  ///  * 暗：间隙 170、胶囊内侧 70 → `0.9412×170×(1−a) + 15 = 70` → a ≈ 0.655。
  /// 光靠磨砂白不过去：模糊只改变局部对比、不改局部均值，+33 级（亮）
  /// / −100 级（暗）的落差只能来自膜本身。
  ///
  /// 注意这**不是**「同一个配方的 alpha 不同」：平底页（分类页静止态）的胶囊
  /// 读作「比页底略暗的 #E5E5E5」，压在高频内容上的胶囊读作「比背景亮/暗
  /// 一大截的磨砂片」。膜取页底色，垫在同色页底上恒等于没垫 —— 所以两态由
  /// **背景**区分，不需要一个跟着滚动位置翻转的状态开关。
  static const int veilAlphaLight = 153;
  static const int veilAlphaDark = 167;

  /// 页底色（亮 #F3F3F3 / 暗 #000000）—— 玻璃膜取这个色，明暗自洽。
  ///
  /// 值定义在 [MiColors]（页底是全局语义，不止玻璃膜在用），这里转发以免
  /// 同一个色值散落两处。
  static const Color veilBaseLight = MiColors.pageBackgroundLight;
  static const Color veilBaseDark = MiColors.pageBackgroundDark;

  /// 按明暗模式取玻璃膜颜色（压在内容上的搜索栏 / 未选胶囊填充）。
  static Color veilFor(MiThemeMode mode) => mode == MiThemeMode.dark
      ? veilBaseDark.withAlpha(veilAlphaDark)
      : veilBaseLight.withAlpha(veilAlphaLight);

  /// 把一档「低调填充」压到玻璃膜之上，预合成成一个等效单色。
  ///
  /// 压在内容上的表面是**两层**：先垫膜、再叠原来的低调填充。alpha 合成满足
  /// 结合律，所以可以先 `alphaBlend` 成一个颜色，不必真的多一个 render object
  /// （也就不会给磨砂子树加 saveLayer）。
  ///
  /// 关键性质：**平底页观感不变**。膜取的就是页底色，垫在同色页底上等于没垫，
  /// 合成结果与原填充只差浮点舍入（亮色胶囊 228.7 vs 229、暗色 15.0 vs 15）。
  /// 于是「有内容压上来才显出玻璃片」这件事由背景决定，而不是靠一个状态开关 ——
  /// 同一份配色在静止态与滚动态都成立。
  static Color veiledFill(Color fill, MiThemeMode mode) =>
      Color.alphaBlend(fill, veilFor(mode));

  // ══ 四、顶栏压色（scrim）═════════════════════════════════════════════════

  /// 压色基色：暗 = 纯黑、亮 = 页底色 #F3F3F3（实测反推 —— 同帧页底在栏内
  /// **全程不变**，排除「白色叠加」）。
  static const Color scrimBaseDark = Color(0xFF000000);
  static const Color scrimBaseLight = Color(0xFFF3F3F3);

  /// 深色压色曲线（HyperOS 设置「显示与亮度」页录屏逐帧实测；顶部不透明）：
  /// α 1.000 → 1.000 → 0.956 → 0.875 → 0.770 → 0.646 → 0.506 → 0.351 →
  /// 0.182 → 0.000。前两档同为 1.000 = 顶部实心平台段（到 63.6dp）。
  /// 各档对应的 y（dp）见 `MiTopBarPalette.dark.scrimGradient.stops`。
  static const List<Color> scrimGradientDark = <Color>[
    Color.fromRGBO(0, 0, 0, 1.000), // y   0.0dp
    Color.fromRGBO(0, 0, 0, 1.000), // y  63.6dp（实心段下沿）
    Color.fromRGBO(0, 0, 0, 0.956), // y  71.8dp
    Color.fromRGBO(0, 0, 0, 0.875), // y  79.9dp
    Color.fromRGBO(0, 0, 0, 0.770), // y  88.1dp
    Color.fromRGBO(0, 0, 0, 0.646), // y  96.3dp
    Color.fromRGBO(0, 0, 0, 0.506), // y 104.4dp
    Color.fromRGBO(0, 0, 0, 0.351), // y 112.6dp
    Color.fromRGBO(0, 0, 0, 0.182), // y 120.7dp
    Color.fromRGBO(0, 0, 0, 0.000), // y 128.9dp
  ];

  /// 亮色压色曲线（本轮实测，α 0.650 → 0）：0.650 → 0.634 → 0.606 → 0.594 →
  /// 0.577 → 0.530 → 0.501 → 0.427 → 0.314 → 0.183 → 0.055 → 0.000。
  /// 全段半透明 → 一段模糊都不能省（对比深色有 63.6dp 实心段可跳过）。
  static const List<Color> scrimGradientLight = <Color>[
    Color.fromRGBO(243, 243, 243, 0.650), // y   0.0dp
    Color.fromRGBO(243, 243, 243, 0.634), // y  33.5dp
    Color.fromRGBO(243, 243, 243, 0.606), // y  41.2dp
    Color.fromRGBO(243, 243, 243, 0.594), // y  56.7dp
    Color.fromRGBO(243, 243, 243, 0.577), // y  72.2dp
    Color.fromRGBO(243, 243, 243, 0.530), // y  79.9dp
    Color.fromRGBO(243, 243, 243, 0.501), // y  87.6dp
    Color.fromRGBO(243, 243, 243, 0.427), // y  95.4dp
    Color.fromRGBO(243, 243, 243, 0.314), // y 103.1dp
    Color.fromRGBO(243, 243, 243, 0.183), // y 110.8dp
    Color.fromRGBO(243, 243, 243, 0.055), // y 118.5dp
    Color.fromRGBO(243, 243, 243, 0.000), // y 122.4dp（以下只剩磨砂）
  ];

  /// 返回按钮按压圆盘的柔和高光 alpha（白 @9.4%，420ms 淡入 / 300ms 淡出）。
  static const double pressHighlightAlpha = 0.094;

  /// 按压高光色：暗 = 白、亮 = 黑（同为 9.4%）。
  static const Color pressHighlightDark =
      Color.fromRGBO(255, 255, 255, pressHighlightAlpha);
  static const Color pressHighlightLight =
      Color.fromRGBO(0, 0, 0, pressHighlightAlpha);

  // ══ 五、玻璃导航栏（栏体遮罩 / 透镜 / 外缘）════════════════════════════════

  /// 深色：栏体遮罩 20,20,20 @0.63（实测透射模型 out = 0.37·in + 12.6）。
  static const double glassScrimAlpha = 0.63;

  /// 深色：透镜暗化层 @0.40（留 ~60% 内容透射）。
  static const double glassLensShadeAlpha = 0.40;

  /// 深色：透镜白茶色调 @0.118。
  static const double glassLensTintAlpha = 0.118;

  /// 深色：透镜内描边 @0.08（浅色真值为无描边 —— 见 `glassLensStrokeLightAlpha`）。
  static const double glassLensStrokeAlpha = 0.08;

  /// 深色：玻璃体外缘高光 @0.10。
  static const double glassRimAlpha = 0.10;

  /// 亮色：栏体遮罩垂直渐变三档 α（上→中→下）0.61 → 0.76 → 0.80，色 #FBFBFB。
  static const double glassScrimLightAlphaTop = 0.61;
  static const double glassScrimLightAlphaMid = 0.76;
  static const double glassScrimLightAlphaBottom = 0.80;

  /// 亮色：选中胶囊（暖灰玻璃体 #E6E6E7）垂直渐变三档 α 0.66 → 0.78 → 0.82。
  static const double glassLensTintLightAlphaTop = 0.66;
  static const double glassLensTintLightAlphaMid = 0.78;
  static const double glassLensTintLightAlphaBottom = 0.82;

  /// 亮色：透镜暗化层全透明、描边无（录屏真值：胶囊边缘是干净的亮度阶跃，
  /// 白描边会在外沿形成亮环、吃掉与栏体的间距可读性，2026-10-16 移除）。
  static const double glassLensShadeLightAlpha = 0;
  static const double glassLensStrokeLightAlpha = 0;

  /// 亮色：外缘纯白高光 @1.0（实测峰值 255）。
  static const double glassRimLightAlpha = 1.0;

  /// 亮色：栏体投影（下缘近处约 −8 级、~50px 内衰减完）。
  static const Color glassShadowLight = Color(0x0F000000);
}
