import 'package:flutter/painting.dart';

import 'colors.dart';
import 'theme_mode.dart';

/// **统一的透明 / 磨砂配置** —— 全库的 alpha、blur σ、玻璃膜色只定义于此。
///
/// 透明效果贯穿本库（顶栏压色、渐进磨砂、玻璃导航栏、搜索栏、胶囊行、
/// 弹框），参数分散定义易出现「同值多处、改一漏一」。因此约定：
///
///  * **数值只在这里定义**（alpha / σ / 膜色 / 曲线采样色）；
///  * 组件令牌（`MiGlassPalette`、`MiTopBarPalette`、`MiSearchBarPalette`、
///    `MiPillTabPalette`、`MiGradientBlurProfile`）只负责引用这些常量 +
///    自身几何（stops、圆角、段高）；
///  * 组件层不得出现 `withOpacity` / `fromRGBO` / 带 alpha 的十六进制色，
///    由 `test/transparency_config_test.dart` 扫描源码约束。
///
/// alpha 表示：优先用 0-255 字节（配 `Color.fromARGB` 精确构造）；度量值
/// 本身为小数的（如 0.63 / 0.094）保留 double + `Color.fromRGBO`，避免
/// 字节取整偏差导致视觉回归漂移。
class MiTransparencyTokens {
  MiTransparencyTokens._();

  // ══ 一、模糊 σ（dp）══════════════════════════════════════════════════════

  /// backdrop 磨砂 sigma（**零件自带**那层：玻璃导航栏 / 搜索栏 / 胶囊行；明暗通用）。
  ///
  /// **9.0dp ≈ 28px**（1220×2656 素材实测）：滚动对齐帧**合成模糊匹配**
  ///（同一内容先清晰掠过栏上方、再被栏玻璃覆盖 → 逐 σ/透射比重建比对，
  /// `.workbuddy/nav_glass_fit.py`，取图标/文字之外的纯净条）给出
  /// σ = 26…30px（谷值 26px，跨帧组复现、残差 <2.3）；含图标/高亮的窗口
  /// 会把 UI 像素当成内容，拟合出的 15…21px 是过拟合。历史修订：28 曾被
  /// 误当 dp 用（28dp 会糊 3 倍），10.3 / 5.5 是两轮修偏 —— 真值 ≈28px。
  static const double blurSigma = 9.0;

  /// 顶栏渐进曲线的**平台段** σ（dp）。取 10-90% 边缘宽度 42.7px 换算：
  /// σ = 42.7 / 2.563 × 0.32213 = 5.37dp（频谱比法在 67.5dp 给出 4.34dp、
  /// 90dp 处 1.85dp，与衰减曲线一致）。
  static const double blurSigmaTop = 5.37;

  /// 头部区形态（搜索栏 + 胶囊行悬浮在内容上）磨砂曲线的**平台段** σ（dp）。
  ///
  /// **8.5dp**（1220×2656 明暗双素材实测）：横幅侧边（理想竖直阶跃，
  /// 区外实测宽度仅 1.4px）的 erf 拟合在 35…48dp 深度给出 7.57 / 8.21 /
  /// 9.02dp（亮色左缘，拟合残差 <900）与 6.0…6.9dp（暗色右缘，低对比
  /// 弱样本）—— 与「我的」页顶部那条 5.37dp 是**两页各自的度量结果**
  /// （同深浅两页顶部 α 不同的先例，见 [MiTopBarPalette]）。
  static const double blurSigmaHeaderTop = 8.5;

  /// 头部区磨砂曲线的**名义**跨度（dp）—— 从栏顶到完全清晰的归零点。
  ///
  /// **158dp**：胶囊行底（152dp）再往下约 6dp 羽化收尾（实测：155dp 处
  /// 横幅上缘 10-90 宽仅 3.5px ≈ σ0.4dp、162dp 处 1.4px 已锐利；胶囊正
  /// 下方 148…155dp 处横幅文字仍轻微发虚）。**不是硬切**——旧口径
  /// 「胶囊底缘以下立刻锐利」出自 884×1920 低清素材，本轮 1220×2656
  /// 原生素材在 3× 放大下可见渐变收尾。
  static const double headerBlurNominalExtent = 158;

  /// 低于该 σ 的模糊段**不绘制**：高斯半径 < 1dp 落在亚像素，渲染结果与
  /// 「不模糊」在任意 dpr 下都不可分辨（度量曲线尾部 0.76 / 0.27 即属此列）。
  static const double minVisibleSigma = 0.5;

  /// 渐进曲线从顶部到「完全清晰」的**名义**跨度（dp）。
  ///
  /// 这是 128.9dp 材质盒上量出来的值；作用区更高时曲线会**等比拉伸**到
  /// 区底归零（形状固定、范围跟着走），见 `MiGradientBlur.bandsFor`。
  static const double nominalBlurExtent = 119;

  /// 顶栏渐进曲线的 **8 档 σ**（dp），顺序 = 从栏顶到栏底。
  ///
  /// 取度量控制点 (0, 5.37) (35, 5.37) (50, 4.96) (67.5, 4.34) (90, 1.85)
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

  /// 头部区磨砂曲线的 **9 档 σ**（dp），顺序 = 从栏顶到栏底。
  ///
  /// 曲线形状：**平台段 8.5dp 到 35dp，此后线性衰减到 158dp 归零**
  /// （σ(y) = 8.5·(158−y)/123）。由本轮实测锚点拟合：
  /// (35…48dp, 7.6…9.0)、(100…113dp, 3.2…4.4)、(155dp, ≈0.4)、
  /// (≥162dp, 0) —— 线性模型对四个锚区的预测 8.0 / 7.6 / 4.2 / 3.3 /
  /// 0.5 全部落在实测邻域（详见 [MiHeaderBlurProfile]）。
  ///
  /// 尾部两档（1.65 / 0.72）较线性真值（1.73 / 0.55）略作圆整：
  /// 让相邻 σ 比 < 2.4（段边界不显台阶），且 σ<2dp 的绝对差肉眼不可辨。
  static const List<double> blurSigmaHeaderRamp = <double>[
    8.50, // 平台段 0…35
    7.98,
    7.04,
    6.09,
    5.10,
    4.08,
    2.91,
    1.65,
    0.72, // 尾段 142…158（羽化收尾）
  ];

  // ══ 一·二、磨砂饱和度 ════

  /// 磨砂**后**的饱和度控制预留 token（**恒等 1.0**，黄金图零变化）。
  ///
  /// HyperOS `textureBlur` 的色控语言是「模糊 → 饱和 / 亮度调整」两段式；
  /// 本库磨砂走 `BackdropFilter` 路线，当前 SDK（3.47）无色控组合入口
  ///（无 `ImageFilter.colorFilter` 工厂，`ImageFilter.matrix` 是几何变换）
  /// —— 本 token 现阶段**无消费方**，仅作单一来源预留（SDK 能力审计见
  /// `MiFilterCache` 文档）。两条合法接入路径：SDK 补上色控工厂后在
  /// `MiFilterCache.blur` 组合；或纹理玻璃路线（快照 + `ColorFilter.matrix`）
  /// 落地时直用。
  ///
  /// 不要在这里发明非 1.0 的值：既无 SDK 入口，也没有饱和度实机样张
  ///（透明体系度量只反解了 σ 与叠色） —— 两头都缺真值。
  static const double blurSaturation = 1.0;

  // ══ 二、表面填充 alpha（0-255 字节）══════════════════════════════════════

  /// 表面填充 alpha（未选中/低调表面）：onSurface @15/255 ≈ 6%，
  /// 明暗共用同一档（同为「onSurface @6%」语义）。
  ///
  ///  * 暗：白 @15 叠纯黑页底 #000000 → 合成 #0F0F0F（暗素材度量）；
  ///  * 亮：黑 @15 叠页底 #F3F3F3 → 合成 #E5E5E5（亮素材度量）。
  static const int fillAlphaSubtle = 15;

  /// 表面填充 alpha（选中/高亮表面）——高不透明，明暗各一档：
  ///
  ///  * 暗：白 @230 叠纯黑页底 #000000 → 合成 #E6E6E6（暗素材度量）；
  ///  * 亮：黑 @196 叠页底 #F3F3F3 → 合成 #383838（亮素材度量）。
  static const int fillAlphaStrongDark = 230;
  static const int fillAlphaStrongLight = 196;

  /// 搜索栏填充 alpha（平底页低调档，与胶囊同一套语言但更薄）：
  ///
  ///  * 暗：白 @36 叠纯黑页底 → 合成 #242424（反解 a=36）；
  ///  * 亮：黑 @13 叠页底 #F3F3F3 → 合成 #E7E7E7（反解 a=12.6≈13）。
  static const int fillAlphaSearchDark = 36;
  static const int fillAlphaSearchLight = 13;

  /// 禁用态 alpha（**推导值** —— 参考素材没有禁用态，取 Material 常规
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

  // ── 三·二、胶囊行区膜带（issue #4①：只覆胶囊行区、上下缘羽化）────────
  //
  // 旧口径是逐胶囊预合成膜（`veiledFill`）：膜边界绑死胶囊形状，行区上下
  // 缘是硬边。素材口径是膜带**只覆盖胶囊行那一段**、上下缘羽化（与头部
  // 磨砂的羽化收尾同一语言），行外与胶囊间隙不垫。羽化端点即 veil 色
  // @0（与中段同色相、零 alpha，渐变两端自然收净）。

  /// 膜带羽化端点（veil @0）：亮 = 页底色 @0、暗 = 纯黑 @0。
  static const Color veilFeatherLight = Color.fromRGBO(243, 243, 243, 0);
  static const Color veilFeatherDark = Color.fromRGBO(0, 0, 0, 0);

  /// 按明暗取膜带羽化端点色。
  static Color veilFeatherFor(MiThemeMode mode) => mode == MiThemeMode.dark
      ? veilFeatherDark
      : veilFeatherLight;

  /// 玻璃片**内缘亮边** alpha（搜索栏 / 未选中胶囊；明暗各一档）。
  ///
  /// 边缘受光的「逐渐变亮」效果：贴玻璃体边缘内侧约 1dp 的白色亮边，
  /// 向内渐变收尾（边缘细扫实测：亮边峰值比玻璃体内部高 +25…38 级、
  /// 1…1.3dp 内回落；外侧仅 1px 微溢）。反解（白 @a 叠玻璃体内值）：
  ///  * 暗：胶囊内 140 → 峰 173（a≈0.26）、搜索栏内 24 → 峰 62（a≈0.16）
  ///    → 取 0.22；
  ///  * 亮：搜索栏内 162 → 峰 200（a≈0.41）、胶囊内 178 → 峰 211（a≈0.42）
  ///    → 取 0.40。
  ///
  /// **选中胶囊不画**：近实心填充上亮边弱到不可辨（暗实心 +4 级、
  /// 亮实心 +6…17 级，均在 JPEG 采样噪声邻域）。
  static const double surfaceRimAlphaDark = 0.22;
  static const double surfaceRimAlphaLight = 0.40;

  /// 按明暗模式取玻璃片内缘亮边颜色。
  ///
  /// [progress] = 亮边激活进度（0…1）：**内容靠近顶栏一定程度才亮**
  /// （参考实测：内容距栏底 ≤≈20dp 时玻璃进入激活态、亮边亮起；静止
  /// 且内容较远时实测亮边 = 0），由顶栏按滚动位置下发，见
  /// `MiTopBarMetrics.rimFadeDistance`。
  static Color surfaceRimFor(MiThemeMode mode, {double progress = 1.0}) {
    final a = (mode == MiThemeMode.dark
            ? surfaceRimAlphaDark
            : surfaceRimAlphaLight) *
        progress.clamp(0.0, 1.0);
    return Color.fromRGBO(255, 255, 255, a);
  }

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

  /// 压色基色：暗 = 纯黑、亮 = 页底色 #F3F3F3（反解 —— 同帧页底在栏内
  /// **全程不变**，排除「白色叠加」）。
  static const Color scrimBaseDark = Color(0xFF000000);
  static const Color scrimBaseLight = Color(0xFFF3F3F3);

  /// 深色压色曲线（HyperOS 设置「显示与亮度」页素材逐帧度量；顶部不透明）：
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

  /// 亮色压色曲线（本轮度量，α 0.650 → 0）：0.650 → 0.634 → 0.606 → 0.594 →
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

  // ══ 四·二、指针悬停（桌面 / 平板接鼠标时）════════════════════════════════

  /// 悬停叠色 alpha（**推导值**，非度量）。
  ///
  /// 参考素材来自触屏手机，没有悬停样张。取值依据：桌面惯例取按压高光的
  /// 40~60%，这里取 60%（`0.094 × 0.6 ≈ 0.056`）—— 要能读出「这里可点」，
  /// 又不能接近选中态的实心填充（玻璃胶囊近不透明）而与之混淆。
  static const double hoverOverlayAlpha = 0.056;

  /// 悬停叠色：暗 = 白、亮 = 黑（同按压的方向约定）。
  static const Color hoverOverlayDark =
      Color.fromRGBO(255, 255, 255, hoverOverlayAlpha);
  static const Color hoverOverlayLight =
      Color.fromRGBO(0, 0, 0, hoverOverlayAlpha);

  /// 按明暗取悬停叠色。
  static Color hoverOverlayFor(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? hoverOverlayDark : hoverOverlayLight;

  // ══ 四·三、卡片悬停快捷操作条（桌面）═════════════════════════════════════

  /// 悬停快捷操作条的底色（**推导值**，非度量）。
  ///
  /// 参考素材来自触屏手机，没有悬停样张。取黑 @45%：操作条要压在**任意**
  /// 预览图上（照片 / 渐变 / 纯色都可能），黑色半透明是唯一在明暗两种
  /// 预览图上都能让白色标签保持可读的方案（与视频播放器控制条同款做法）。
  static const Color cardQuickActionsScrim = Color.fromRGBO(0, 0, 0, 0.45);

  // ══ 五、玻璃导航栏（栏体遮罩 / 透镜 / 外缘）════════════════════════════════

  /// 深色：栏体遮罩 20,20,20 @0.76（透射 t≈0.24）。
  ///
  /// 实测区间：合成匹配 LS（亮内容纯净条）t = 0.246…0.298 → a 0.70…0.754；
  /// 均值守恒法（模糊保均值）a = 0.70…0.71。**取区间实端 0.76**（实机观感
  /// 反馈：参考是「糊而不透」，取下沿 0.70 看着偏透；参考亮色配方也是
  /// 上轻下重的渐变，深色实端更接近整体观感）。
  static const double glassScrimAlpha = 0.76;

  /// 深色：选中块暗化层 @0.40 —— 压在**未开洞**的栏体玻璃之上（暗色选中
  /// 块是高磨砂块，不开洞，见 [MiGlassPalette.lensCutsScrim]）。
  static const double glassLensShadeAlpha = 0.40;

  /// 深色：选中块白茶色调 @0.28。
  ///
  /// **2026-10-27 实测**（滚动对齐帧多点回归，胶囊全宽无字带）：参考暗色
  /// 选中块是**高磨砂块** —— (c, t) ≈ (84, 0.05)，内容几乎不透出；旧口径
  /// 「开洞 + 白@0.118」会得到 (30, 0.53) = 透镜窗口，把背后彩色内容直接
  /// 透出来（实机反馈截图正是这个观感）。不开洞 + 暗化 0.4 + 白@0.28 合成
  /// 后 (c, t) ≈ (78, 0.10)，落在实测邻域。
  static const double glassLensTintAlpha = 0.28;

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

  /// 亮色：透镜暗化层全透明、无描边（描边会在外沿形成亮环、影响与栏体的
  /// 间距可读性）。
  static const double glassLensShadeLightAlpha = 0;
  static const double glassLensStrokeLightAlpha = 0;

  /// 亮色：外缘纯白高光 @1.0（度量峰值 255）。
  static const double glassRimLightAlpha = 1.0;

  /// 亮色：栏体投影（下缘近处约 −8 级、~50px 内衰减完）。
  static const Color glassShadowLight = Color(0x0F000000);

  // ══ 六、弹框（遮罩 / 次级文字）════════════════════════════════════════════

  /// 弹框遮罩 alpha（黑，明暗各一档，度量）：
  ///
  ///  * 亮：白页底 → #CCCCCC（204/255 = 0.8 透射）→ α = 0.20；
  ///  * 暗：同一缩略图内容暗/亮均值比恒为 0.500（5 块采样 0.497…0.501）
  ///    → (1−α暗)/(1−0.20) = 0.5 → α = 0.60。
  static const double dialogScrimAlphaLight = 0.20;
  static const double dialogScrimAlphaDark = 0.60;

  /// 弹框遮罩色（黑 @ 上述 alpha）。
  static const Color dialogScrimLight =
      Color.fromRGBO(0, 0, 0, dialogScrimAlphaLight);
  static const Color dialogScrimDark =
      Color.fromRGBO(0, 0, 0, dialogScrimAlphaDark);

  /// 按明暗模式取弹框遮罩色。
  static Color dialogScrimFor(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dialogScrimDark : dialogScrimLight;

  /// 弹框次级文字（正文 + 中性按钮标签）alpha：onSurface @0.80。
  ///
  /// 反解口径：同一批像素在**两种填充**上读数差 ≈6 级（正文压卡片
  /// #242424 读 #D0…D4、按钮标签压填充 #434343 读 #D8），固定灰读不出
  /// 这个差、只有 alpha 合成能 —— 按 α=0.80 预测 211 / 217，双模式四组
  /// 读数全部落进 mode 邻域（亮：51 / 48 对 #333 / #303）。
  static const double dialogTextSecondaryAlpha = 0.80;

  /// 弹框次级文字色（纯白 / 纯黑 @ 上述 alpha；标题为同基准 1.0 不透明）。
  static const Color dialogTextSecondaryDark =
      Color.fromRGBO(255, 255, 255, dialogTextSecondaryAlpha);
  static const Color dialogTextSecondaryLight =
      Color.fromRGBO(0, 0, 0, dialogTextSecondaryAlpha);

  /// 弹框操作列表**分隔线** alpha（**推导值**，非度量：参考素材只有按钮式
  /// 弹框，没有「纵向操作列表」形态的样张）。取 onSurface @0.08：分隔线要
  /// 能读出「两项之间有界」，又不能重到在卡片填充（#FFFFFF / #242424）上
  /// 形成第二根横线去抢文字 —— 行菜单的通行区间是 6%…10%，取中值。
  static const double dialogDividerAlpha = 0.08;

  /// 弹框分隔线色（黑 @0.08 亮 / 白 @0.08 暗，压在卡片填充上合成）。
  static const Color dialogDividerLight =
      Color.fromRGBO(0, 0, 0, dialogDividerAlpha);
  static const Color dialogDividerDark =
      Color.fromRGBO(255, 255, 255, dialogDividerAlpha);

  /// 按明暗模式取弹框分隔线色。
  static Color dialogDividerFor(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dialogDividerDark : dialogDividerLight;

  // ══ 七、弹框按钮按压（state layer）════════════════════════════════════════

  /// 按钮按压态叠色 alpha（Material state layer 语言：亮 = 黑压、暗 = 白提，
  /// 与 [pressHighlightAlpha] 的返回钮按压同一套方向）。
  ///
  /// **亮色度量**（按压参考素材 24.31fps，1220×2656）：「确定」蓝填充
  /// (52,129,254) → (46,113,226)，等比 ×0.88 ≡ 黑 @0.12；白字核心 255
  /// **不变**（叠色只压填充、在标签之下）；按钮盒边缘不动（无缩放）。
  /// 逐帧进度 47/80/96/100% 拟合 150ms easeOutQuad（mean|Δ|=0.02）。
  /// 暗色反向提亮为推导（Material state layer / 返回钮按压同语言）。
  static const double dialogPressAlpha = 0.12;

  /// 按压叠色（黑 @0.12 亮 / 白 @0.12 暗），只压填充、不碰标签。
  static const Color dialogPressLight =
      Color.fromRGBO(0, 0, 0, dialogPressAlpha);
  static const Color dialogPressDark =
      Color.fromRGBO(255, 255, 255, dialogPressAlpha);

  /// 按明暗模式取按压叠色。
  static Color dialogPressFor(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dialogPressDark : dialogPressLight;

  /// 按压态填充：把按压叠色压到 [fill] 上（预合成单色，不引 saveLayer）。
  static Color dialogPressedFill(Color fill, MiThemeMode mode) =>
      Color.alphaBlend(dialogPressFor(mode), fill);

  // ══ 七·二、弹出面板（`MiPullUpPanel`）════════════════════════════════════

  /// 弹出面板**无压暗遮罩**（**度量**：唤起录屏逐帧实测 —— 面板外页底像素
  /// 保持原值，内容列表亮度不变）。仍保留一层全屏透明命中层，让面板外
  /// 点按能交给宿主收起（语义同弹框 `onScrimTap`，只是不压暗）。
  static const Color panelScrim = Color(0x00000000);

  /// 全透明端点（零叠色配方档的渐变端色，如
  /// `MiTopBarPalette.transparent`）—— 组件层要表达「透明」一律引用它，
  /// 不自写字面量（守门测试扫描口径）。
  static const Color clear = Color(0x00000000);

  /// 弹出面板投影 alpha（**度量拟合**，0.25× 慢速浅色素材：面板下缘外 +2dp
  /// 处压暗 14 级、+6dp 压 10 级、+14dp 归零，上缘仅 ~3 级 → 黑 @0.12、
  /// blur σ≈7、下偏 4dp 的边缘剖面可同时对上两侧读数）。暗色素材黑底上
  /// **不可分辨**（同配方压在 #000 上无视觉差异 —— 推导同值）。
  static const double panelShadowAlpha = 0.12;

  /// 弹面投影色（黑 @ 上述 alpha，明暗同值）。
  static const Color panelShadow =
      Color.fromRGBO(0, 0, 0, panelShadowAlpha);

  // ── 页面推入（`MiCardPageRoute`）────────────────────────────────────────
  //
  // 下层页压暗：度量取「同一像素在转场前后的亮度比」。参考素材里下层页
  // 的平坦区（页底）全程稳定在 0.64 倍亮度 → 黑 @0.36 的等效值。按转场
  // 进度线性插值时，0.36 落在进度 0.65 附近，故终值取 0.55。
  //
  // **只压色、不加 `Opacity`**：半透明 `Opacity` 会给含 `BackdropFilter`
  // 的子树引入 saveLayer，使 backdrop 变空、磨砂失效；半透明纯色填充只是
  // 一次普通绘制，不做离屏合成。

  /// 页面推入转场里下层页压暗的**终值** alpha（线性 0 → 本值）。
  static const double pushDimAlphaMax = 0.55;

  /// 推入转场进度 [progress]（0…1）对应的下层页压暗色。
  static Color pushDimAt(double progress) => Color.fromRGBO(
        0,
        0,
        0,
        (pushDimAlphaMax * progress.clamp(0.0, 1.0)),
      );

  // ══ 八、开关（`MiSwitch`）════════════════════════════════════════════

  /// 开关**关闭档**轨道填充 alpha（**推导值**：onSurface @31/255 ≈ 12%，
  /// Material 3 off-track 同档；与「表面填充 onSurface @6%」同族、高一档
  /// 对比 —— 触屏素材无开关样张，按通行 state layer 档位推导）。
  static const double switchTrackOffAlpha = 31 / 255;

  /// 开关关闭档轨道色（亮 = 黑 @12% / 暗 = 白 @12%，state layer 同语言）。
  static Color switchTrackOffFor(MiThemeMode mode) => mode == MiThemeMode.dark
      ? Color.fromRGBO(255, 255, 255, switchTrackOffAlpha)
      : Color.fromRGBO(0, 0, 0, switchTrackOffAlpha);
}
