import 'package:flutter/animation.dart';

import '../../../theme/gradient_blur_tokens.dart';
import '../../../theme/motion_tokens.dart';

/// [MiTopBar] 的几何与折叠动效规格（设计度量，393dp 设计宽）。
///
/// 规格值取自 1220×2656 参考素材，换算系数 s = 393 / 1220 = 0.32213：
///
/// | 项目                     | 素材 px       | dp         |
/// |--------------------------|---------------|------------|
/// | 返回圆钮直径             | 137           | 44.1       |
/// | 返回圆钮左内边距         | 37            | 11.9       |
/// | app bar 行垂心（距屏顶） | 236           | 76.0       |
/// | 返回箭头墨迹包围盒       | 36 x 66       | 11.6 x 21.3 |
/// | 返回箭头笔画宽度         | 6.36          | 2.05       |
/// | 返回箭头墨心 x           | 101.4         | 32.65      |
/// | 大标题墨迹包围盒         | 482 x 92      | 155.3 x 29.6 |
/// | 大标题墨左 / 墨心 y      | 92 / 412.5    | 29.6 / 132.9 |
/// | 大标题字面 advance（CJK）| 98.8          | 31.83      |
/// | 紧凑标题墨迹包围盒       | 273 x 52      | 87.9 x 16.75 |
/// | 紧凑标题墨心             | 609.5 / 235.5 | 196.4 / 75.9 |
/// | 紧凑标题字面 advance     | 55.9          | 18.0       |
/// | 压色全不透明段下沿       | 197           | 63.6       |
/// | 压色完全透明处           | 400           | 128.9      |
/// | 内容首行顶缘（静止态）   | 568           | 183.0      |
///
/// 行为规格：
///
///  * **大标题随内容滚动**：位移与列表滚动 1:1 联动（逐帧位移相等），
///    非锚定缩小；
///  * **大标题叠加独立淡出**（[largeTitleFade]）：滚动位移之外整体不透明度
///    单调下降（沿字高方向比例一致），在滚动 ≈20dp 内归零；
///  * **紧凑标题衔接淡入**（[compactTitleFade]）：在大标题归零后（≈20dp）
///    开始，约 27.4dp 处完成，两段不重叠；
///  * **返回箭头**为 45° 圆角两臂（端头与顶点均圆角）：墨迹盒 =
///    (L + w) × (2L + w)，L = 9.63dp、w = 2.05dp → 11.68 × 21.31dp；
///    墨心较圆钮中心左偏 1.3dp（光学偏置，非度量误差）；
///  * **标题落点以 `Baseline` 锚定**（[titleBaselineY]）：墨心相对基线的
///    比例在中文各字体间稳定（0.35…0.36em），而基线在行盒内的位置随字体
///    度量变化（可差 0.14em）—— 因此布局期直接锚定基线，落点与字体族无关。
///
/// 规格经多组参考素材交叉验证（标题墨心偏差 ≤ 0.6dp）；文字样式见
/// `theme/typography.dart`，材质与配色见 `theme/top_bar_tokens.dart`，
/// 返回箭头绘制见 `icons/nav_icons.dart`。
class MiTopBarMetrics {
  MiTopBarMetrics._();

  // ── 状态栏让位 / app bar 行 ────────────────────────────────────────────
  /// 状态栏让位（= 行垂心 76.0 − 行高/2；度量状态栏图标墨带 18.7…33.5dp
  /// 垂心 26.1dp，与该让位一致）。
  static const double statusBarHeight = 53.8;

  /// app bar 行高 = 返回圆钮直径。
  static const double barHeight = 44.1;

  // ── 返回圆钮 ──────────────────────────────────────────────────────────
  /// 圆钮直径（度量 137px；按压态下边缘覆盖和 136.9px 互证）。
  static const double backDiameter = 44.1;

  /// 圆钮左内边距（度量 37px，与页面内容边距同档）。
  static const double backInset = 11.9;

  /// 圆钮垂心距屏顶（度量 236px）。
  static const double backCenterY = 76.0;

  /// 圆钮水平中心（= [backInset] + [backDiameter] / 2 = 33.95）。
  static const double backCenterX = 33.95;

  /// 返回箭头墨迹包围盒（建模值 = 阈值度量 36x66px + 圆角端头 AABB）。
  static const double chevronWidth = 11.68;
  static const double chevronHeight = 21.31;

  /// 返回箭头笔画宽（垂直笔宽，度量横切 9px → 9·sin45° = 6.36px）。
  static const double chevronStroke = 2.05;

  /// 箭头墨心相对圆钮中心的水平偏移（度量 −4.1px ≈ −1.3dp，光学左偏）。
  static const double chevronCenterDx = -1.3;

  /// 返回圆钮按压反馈：度量 0.4s 内 0 → 25% → 83% → 100%（easeOut 形），
  /// 松开后在 0.3s 内消失（8.4s 帧 13 级 → 8.7s 帧 0 级）。
  ///
  /// 同源转发自 [MiMotionTokens]（统一动效配置），新代码请直接取 token。
  static const int pressFadeInMs = MiMotionTokens.pressFadeInMs;
  static const int pressFadeOutMs = MiMotionTokens.pressFadeOutMs;

  // ── 大标题 ────────────────────────────────────────────────────────────
  /// 墨心相对**基线**的比例（本机 simhei 0.360 / msyh 0.350 / simsun 0.355
  /// 度量，含 2 字与 5 字样本）。CJK 方块字按字面设计，该比值跨中文字体
  /// 很稳 —— 这是标题垂直落点唯一依赖的字体假设。
  static const double titleInkAboveBaseline = 0.355;

  /// 大标题墨心距屏顶（度量 412.5px = 132.88dp，静止态；第二样本「设置」页
  /// 复核 133.50dp）。
  static const double largeTitleInkCenterY = 132.9;

  /// 大标题行盒左缘（度量墨左 92px − 字面左边距 6.4px = 85.6px；与
  /// 「页边距 11.9 + 16」的复合估计一致，取度量值）。
  static const double largeTitleLeadingInset = 27.6;

  /// 紧凑标题墨心距屏顶（度量 235.5px，与圆钮垂心相差 0.1dp）。
  static const double compactTitleInkCenterY = 75.9;

  /// 由墨心反推的**基线**目标值：`墨心 + [titleInkAboveBaseline]·em`。
  ///
  /// 标题的垂直落点交给 `Baseline(baselineType: alphabetic)` 在**布局期**
  /// 求解 —— 它会把子级基线放到「距该 box 顶端 [titleBaselineY] 处」，与
  /// 字体度量无关（本 SDK 的 `StrutStyle` 无 ascent/descent 参数，行盒内的
  /// 基线位置只能由字体决定，故不能用 strut 钉）。[fontSize] 传对应标题的
  /// 字号（`MiTypography.topBarLargeTitle` / `topBarCompactTitle`）。
  static double titleBaselineY(double inkCenterY, double fontSize) =>
      inkCenterY + titleInkAboveBaseline * fontSize;

  /// 组件自身高度：大标题墨心 + 一整行 `em` —— 够高不裁标题。
  ///
  /// 基线的实际落点由 `Baseline` 在布局期求得（不同字体下标题盒的顶/底会
  /// 差几个 dp），故高度取这个保守定值，不随字体变化。
  static double componentHeight(double largeTitleFontSize) =>
      largeTitleInkCenterY + largeTitleFontSize;

  // ── 顶栏遮罩 / 磨砂 ───────────────────────────────────────────────────
  /// 材质盒高（磨砂层与叠色层共用）：128.9dp。
  ///
  /// 取自深色参考页（叠色全不透明段下沿 63.6dp，此后按 1.5 次幂渐隐至 0）。
  /// 浅色参考页的两个材质层都比它早收尾 —— 叠色 α 到 122.4dp 归零、磨砂
  /// 遮罩到 119.0dp 归零（各自度量，故浅色渐变的最后一个 stop 落在
  /// 122.4/128.9 = 0.94957，其后再补一个 0 值 stop 到盒底）。
  static const double scrimHeight = 128.9;

  /// 深色参考页叠色全不透明段下沿（浅色页无实心段，顶部 α 仅 0.650）。
  static const double scrimSolidBottom = 63.6;

  /// 低于该 σ 的模糊段**不绘制**：高斯半径 < 1dp 落在亚像素，渲染结果与
  /// 「不模糊」在任意 dpr 下都不可分辨（度量 σ 曲线尾部 0.76 / 0.27 即属此列）。
  ///
  /// 权威定义在 [MiGradientBlurProfile.minVisibleSigma]（模糊属内容区、已抽成
  /// `MiGradientBlur`），这里转发保持旧引用可用。省帧依据之一（另一条见
  /// [MiTopBarPalette.scrimOpaqueBottom]）；两条都只剔除**视觉上不存在**的段，
  /// 不改动任何可见像素。
  static const double minVisibleBlurSigma = MiGradientBlurProfile.minVisibleSigma;

  // ── 内容 ──────────────────────────────────────────────────────────────
  /// 内容首行（**卡片**类）在静止态的顶缘：素材页首行卡片填充顶缘
  /// 568px = 183.0dp（硬边：亮度 0 → 135 单行跳变，左右两张预览卡一致）
  /// —— 宿主给滚动内容的上内边距；大标题（墨底 147.7dp）与它留 35.3dp 空档。
  static const double contentTopInset = 183.0;

  /// 内容首行是**搜索栏**时的顶缘：度量自参考截图「设置」首页搜索栏顶缘
  /// 523px = 168.5dp（同页卡片组顶缘 224.85dp，组间距 12.24dp）。
  /// 搜索栏比卡片类首行高 14.5dp，两个值都来自整机度量，故分档给出。
  static const double searchBarTopInset = 168.5;

  // ── 头部插槽区（内容形态） ─────────────────────────────────────────────
  //
  // 顶栏除了「大标题 + 材质」，还可以**内嵌头部组件**（搜索栏 / 胶囊标签行 /
  // 任意自定义头部）—— 分类页就是这种形态：搜索栏 + 胶囊行吸顶悬浮，网格
  // 从胶囊后方滚过。这一区的几何全部度量自分类页完整截图（1220×2656，
  // s = 393/1220 = 0.32213）。

  /// 插槽区相对**屏幕顶端**的起始位置 = 状态栏让位（度量 56dp）。
  ///
  /// 与 [statusBarHeight]（53.8，由大标题墨心反推的行垂心让位）是两回事：
  /// 那个服务于大标题几何，这个服务于「搜索栏顶缘 y = 56」的度量值。
  /// 真机 / 平板安全区更高时取更大者，见 [headerTopInsetFor]。
  static const double headerTopInset = 56.0;

  /// 插槽区起始位置：安全区高于 [headerTopInset] 时取安全区。
  ///
  /// 让刘海屏不压住头部内容；桌面窗口（padding = 0）仍是 56。
  static double headerTopInsetFor(double safeAreaTop, {double topInset = headerTopInset}) =>
      safeAreaTop > topInset ? safeAreaTop : topInset;

  /// 桌面档插槽区起始位置 **24**（**推导值**）。
  ///
  /// 参考素材只有手机档（状态栏让位 56 是**度量**）；桌面窗口没有状态栏，
  /// 继续留 56 会在窗口顶部悬出一条无意义的空带。取 24：与桌面应用栏
  /// （macOS toolbars / Windows Settings header）16…32 的通行留白同档，
  /// 且与宽屏页边距 32 在同一比例阶梯上。示例在 expanded 档传它。
  static const double desktopHeaderTopInset = 24;

  /// 搜索栏底 → 胶囊标签行顶（度量 49px ≈ 15.8dp，取 16）。
  static const double searchBarGap = 16.0;

  /// 胶囊标签行底 → 滚动内容首行（分类页度量间距 12dp）。
  static const double headerContentGap = 12.0;

  /// 插槽左右页边距（度量 37px = 11.9dp，与页面内容边距同档）。
  ///
  /// 只作用于 [MiTopBar.searchBar] / [MiTopBar.header]：胶囊标签行要能
  /// 横向出血滚动到屏幕边缘（它在内部自带同值的 `edgeInset`），套内外边距
  /// 会把第 4 个胶囊多裁一截。
  static const double headerInset = 11.9;

  /// 搜索栏插槽默认高度 = `MiSearchBarMetrics.barHeight`（44.1）。
  ///
  /// 两个常量同值是有意的重复：metrics 类保持纯数据、不 import 组件层
  ///（`MiTopBar` 自身为了产出内置搜索栏会 import `inputs/search_bar`，但
  /// 几何表不需要跟着耦合）。跨层一致由测试 `top_bar_test.dart` 钉住
  ///（改一处漏另一处会红）。
  static const double searchBarSlotHeight = 44.1;

  /// 胶囊标签行插槽默认高度 = `MiPillTabMetrics.pillHeight`（39.9）；同上，
  /// 跨层同值由测试钉住。
  static const double tabBarSlotHeight = 39.9;

  /// 内缘亮边激活的滚动距离（dp，**推导映射**）。
  ///
  /// 素材实测是**内容接近度**阈值：内容距栏底 ≤≈20dp 时玻璃进入激活态
  /// （亮边亮起，翻转在 1 帧内完成；同一段录屏里内容距 20.6dp 时亮边 = 0、
  /// 20.0dp 时已满）。顶栏不知道内容布局，按标准布局换算成滚动位移：
  /// `rimProgress = clamp(scrollOffset / 20, 0, 1)` —— 静止时亮边不亮
  /// （实机反馈：不能常亮），内容向栏靠近的过程中渐亮，进入栏区后保持。
  static const double rimFadeDistance = 20.0;

  // ── 折叠动效（逐帧度量查找表） ─────────────────────────────────────────
  /// 大标题不透明度：`(滚动位移 dp, 墨迹峰值比)`。
  ///
  /// 由 32 帧连续采样（位移由帧间相位相关独立测得，非假定）：
  /// 位移 0→20dp 内淡出完毕，且中段下降最快（S 形）。
  static const List<(double, double)> largeTitleFade = [
    (0.00, 1.000),
    (1.93, 0.924),
    (5.80, 0.627),
    (9.02, 0.368),
    (9.99, 0.318),
    (10.95, 0.272),
    (11.92, 0.230),
    (13.21, 0.175),
    (14.17, 0.142),
    (15.46, 0.121),
    (16.11, 0.096),
    (19.97, 0.000),
  ];

  /// 紧凑标题不透明度：`(滚动位移 dp, 墨迹峰值比)`。
  ///
  /// 大标题归零（≈20dp）后才开始淡入，27.4dp 起为 1.0。
  static const List<(double, double)> compactTitleFade = [
    (19.97, 0.000),
    (20.62, 0.041),
    (21.90, 0.220),
    (22.87, 0.498),
    (24.48, 0.792),
    (25.77, 0.914),
    (27.38, 0.976),
    (29.31, 1.000),
  ];

  /// 折叠完成位移 = [compactTitleFade] 末点：越过该位移后两段标题都不再变化，
  /// 故非有限位移（+∞）按此饱和处理（见 `top_bar.dart` 的位移兜底）。
  static const double collapsedOffset = 29.31;

  // ── 搜索态（点按搜索栏 → 输入态） ──────────────────────────────────────
  //
  // 全部度量自参考素材「短信」搜索（592×1280 @24fps，共 79 帧）。那一页的
  // 正常态搜索栏在大标题下方（y 252px），点按后升到状态栏下方（y 78px），
  // 位移 174px；同时右侧让出取消钮、页面内容清空、键盘升起。

  /// 搜索态转场总时长 **220**。
  ///
  /// 参考素材量到的是 480ms（起手静止 48ms + 位移 430ms），这里按**手感**压到
  /// 220ms：整段位移只有 56dp，480ms 的读法是「先等一下、再慢慢蹭过去」——
  /// 末端 `easeOutQuint` 的余量（最后 1dp 走掉五分之一时长）尤其拖。压时长
  /// **不改形状**：起手静止段（[searchMotion] 的 0.10）与取消钮淡入段
  /// （[searchCancelFadeBegin]…[searchCancelFadeEnd]）都是线性时间比例，
  /// 一起按同一比例压缩 —— 静止 48 → 22ms（约一帧，仍读得出「先停后冲」），
  /// 位移 198ms，淡入落在 77…136ms。
  static const int searchTransitionMs = 220;

  /// 位移曲线：**前 10% 静止 + easeOutQuint**，剩余 90% 走完全程。
  ///
  /// 拟合依据：逐帧位移
  /// `252 244 194 143 112 95 86 82 80 79 79 78`（px，24fps），
  /// 该模型 mean|Δ| = 0.008、最大偏差 0.046（比纯 easeOutQuint 无延迟的
  /// 0.035 / 0.35 好一个量级；easeInOut 族反而更差）。
  static const Curve searchMotion =
      Interval(0.10, 1.0, curve: Curves.easeOutQuint);

  /// 取消钮淡入区间（**线性时间**上的比例段，不受 [searchMotion] 影响）。
  ///
  /// 度量圆盘覆盖率（同 y 区域相对页底的偏离，稳态 16.7）：f26 5.36 →
  /// f27 10.53 → f28 16.04 → f29 16.4（≈稳定），即 0.32 / 0.63 / 0.96 落在
  /// 点按后 208 / 250 / 292ms。反解得「约 130ms 的淡入、起于 166ms」，
  /// 折成素材时长 480ms 的比例就是 0.35…0.62 —— 也就是**转场中段**出现，
  /// 既不跟着最后一帧一起冒出来，也不是一开始就有。本库时长压到 220ms 后
  /// 这两个比例值不变（同一比例压缩），淡入落在 77…136ms。
  static const double searchCancelFadeBegin = 0.35;

  /// 取消钮淡入区间终点。
  static const double searchCancelFadeEnd = 0.62;

  /// 大标题不透明度（[largeTitleFade] 线性插值；负位移按 0 处理）。
  static double largeTitleOpacity(double scrollOffset) =>
      _lookup(largeTitleFade, scrollOffset);

  /// 紧凑标题不透明度（[compactTitleFade] 线性插值）。
  static double compactTitleOpacity(double scrollOffset) =>
      _lookup(compactTitleFade, scrollOffset);

  /// 查找表线性插值；越界取端点值（NaN 取首端，+∞ 取末端）。
  static double _lookup(List<(double, double)> table, double x) {
    if (x.isNaN || x <= table.first.$1) return table.first.$2;
    if (x >= table.last.$1) return table.last.$2;
    for (var i = 1; i < table.length; i++) {
      final (x1, y1) = table[i];
      if (x <= x1) {
        final (x0, y0) = table[i - 1];
        return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
      }
    }
    return table.last.$2;
  }
}
