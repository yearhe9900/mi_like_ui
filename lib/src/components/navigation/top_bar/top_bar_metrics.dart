/// [MiTopBar] 的几何 / 折叠动效参数：1:1 逐帧实测自参考录屏。
///
/// Source frame: 1220x2656 px screen recording (HyperOS 设置「显示与亮度」
/// 页, 24.32 fps). Scale to a 393 dp design width: s = 393 / 1220 = 0.32213.
///
/// | item                        | video px        | dp         |
/// |-----------------------------|-----------------|------------|
/// | 返回圆钮直径                | 137             | 44.1       |
/// | 返回圆钮左内边距            | 37              | 11.9       |
/// | app bar 行垂心（距屏顶）    | 236             | 76.0       |
/// | 返回箭头墨迹包围盒          | 36 x 66         | 11.6 x 21.3 |
/// | 返回箭头笔画（垂直笔宽）    | 6.36            | 2.05       |
/// | 返回箭头墨心 x              | 101.4           | 32.65      |
/// | 大标题墨迹包围盒            | 482 x 92        | 155.3 x 29.6 |
/// | 大标题墨左 / 墨心 y         | 92 / 412.5      | 29.6 / 132.9 |
/// | 大标题字面 advance（CJK em）| 98.8            | 31.83      |
/// | 紧凑标题墨迹包围盒          | 273 x 52        | 87.9 x 16.75 |
/// | 紧凑标题墨心（屏水平中心）  | 609.5 / 235.5   | 196.4 / 75.9 |
/// | 紧凑标题字面 advance        | 55.9            | 18.0       |
/// | 遮罩全不透明段下沿          | 197             | 63.6       |
/// | 遮罩完全透明处              | 400             | 128.9      |
/// | 内容首行顶缘（静止态）      | 568             | 183.0      |
///
/// 实测要点：
///  * **大标题属于滚动内容**：逐帧相位相关测出的大标题质心位移与滚动位移
///    逐帧相等（-6/-18/-28/-31/-37/-45px 对同一组滚动量），即它随列表
///    1:1 上移，不是钉在栏上缩小；
///  * **大标题另有一条独立淡出曲线**（见 [largeTitleFade]）：位移之外墨迹
///    峰值还随滚动单调下降，且沿字高方向比例一致（逐行比对 8 行比率无
///    自上而下的梯度），故是整体不透明度而非遮罩覆盖；
///  * 大标题完全消失（滚动 ≈20dp）之后紧凑标题才开始淡入（见
///    [compactTitleFade]），两段**不重叠**；
///  * 返回箭头为 45° 两臂（逐行左缘 −4px/4px），端头与顶点均为**圆角**
///    （顶点行左缘 83→85 回退，圆角顶点墨左 = 顶点 x − 笔宽/2）；
///    由此可反解墨迹盒 = (L + w) x (2L + w)，L=9.63dp、w=2.05dp →
///    11.68 x 21.31dp，与阈值实测 11.6 x 21.3dp 吻合（±0.08dp）；
///  * 返回箭头墨心比圆钮中心**左偏 1.3dp**（实测，光学偏置；非测量误差：
///    圆钮边缘在 x≈37.5/173.5px，中心 105.5px，箭头墨心 101.4px）；
///  * 标题的**垂心落点由 `Baseline` 在布局期钉死**（见 [titleBaselineY]）：
///    墨心相对**基线**的比例在各中文字体间很稳（本机 simhei / msyh /
///    simsun 实测 0.35…0.36em，含 2 字与 5 字样本），而基线在**行盒**内的
///    位置只能由字体度量决定（本 SDK 的 `StrutStyle` 没有 ascent/descent
///    参数，`height` 只按比例缩放 ascent/descent、改不了二者之比），
///    字体间可差 0.14em（参考录屏 MiSans ≈0.807，Android CJK 回退
///    字体 ≈0.95）—— 故不预设行盒内的基线位置，直接用 `Baseline` 把基线
///    放到目标值（墨心仍是实测值，见 [largeTitleInkCenterY]）。
///
/// 第二样本交叉验证：参考截图「设置」首页（同为 1220×2656）大标题墨心
/// 133.50dp（模型 132.9，差 0.6dp）、墨盒 186×90px、墨左 29.64dp。
///
/// 文字样式见 `theme/typography.dart`，配色 / 遮罩见
/// `theme/top_bar_tokens.dart`，返回箭头见 `icons/nav_icons.dart`。
class MiTopBarMetrics {
  MiTopBarMetrics._();

  // ── 状态栏让位 / app bar 行 ────────────────────────────────────────────
  /// 状态栏让位（= 行垂心 76.0 − 行高/2；实测状态栏图标墨带 18.7…33.5dp
  /// 垂心 26.1dp，与该让位一致）。
  static const double statusBarHeight = 53.8;

  /// app bar 行高 = 返回圆钮直径。
  static const double barHeight = 44.1;

  // ── 返回圆钮 ──────────────────────────────────────────────────────────
  /// 圆钮直径（实测 137px；按压态下边缘覆盖和 136.9px 互证）。
  static const double backDiameter = 44.1;

  /// 圆钮左内边距（实测 37px，与页面内容边距同档）。
  static const double backInset = 11.9;

  /// 圆钮垂心距屏顶（实测 236px）。
  static const double backCenterY = 76.0;

  /// 圆钮水平中心（= [backInset] + [backDiameter] / 2 = 33.95）。
  static const double backCenterX = 33.95;

  /// 返回箭头墨迹包围盒（建模值 = 阈值实测 36x66px + 圆角端头 AABB）。
  static const double chevronWidth = 11.68;
  static const double chevronHeight = 21.31;

  /// 返回箭头笔画宽（垂直笔宽，实测横切 9px → 9·sin45° = 6.36px）。
  static const double chevronStroke = 2.05;

  /// 箭头墨心相对圆钮中心的水平偏移（实测 −4.1px ≈ −1.3dp，光学左偏）。
  static const double chevronCenterDx = -1.3;

  /// 返回圆钮按压反馈：实测 0.4s 内 0 → 25% → 83% → 100%（easeOut 形），
  /// 松开后在 0.3s 内消失（8.4s 帧 13 级 → 8.7s 帧 0 级）。
  static const int pressFadeInMs = 420;
  static const int pressFadeOutMs = 300;

  // ── 大标题 ────────────────────────────────────────────────────────────
  /// 墨心相对**基线**的比例（本机 simhei 0.360 / msyh 0.350 / simsun 0.355
  /// 实测，含 2 字与 5 字样本）。CJK 方块字按字面设计，该比值跨中文字体
  /// 很稳 —— 这是标题垂直落点唯一依赖的字体假设。
  static const double titleInkAboveBaseline = 0.355;

  /// 大标题墨心距屏顶（实测 412.5px = 132.88dp，静止态；第二样本「设置」页
  /// 复核 133.50dp）。
  static const double largeTitleInkCenterY = 132.9;

  /// 大标题行盒左缘（实测墨左 92px − 字面左边距 6.4px = 85.6px；与
  /// 「页边距 11.9 + 16」的复合估计一致，取实测值）。
  static const double largeTitleLeadingInset = 27.6;

  /// 紧凑标题墨心距屏顶（实测 235.5px，与圆钮垂心相差 0.1dp）。
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

  // ── 顶栏遮罩 ──────────────────────────────────────────────────────────
  /// 遮罩纵向高度：全不透明段下沿 [scrimSolidBottom] ≈ 63.6dp，此后按
  /// 1.5 次幂渐隐至 0（拟合 `m(y) = ((y−63.6)/65.3)^1.5`）。
  static const double scrimHeight = 128.9;

  /// 遮罩全不透明段下沿。
  static const double scrimSolidBottom = 63.6;

  // ── 内容 ──────────────────────────────────────────────────────────────
  /// 内容首行（**卡片**类）在静止态的顶缘：录屏页首行卡片填充顶缘
  /// 568px = 183.0dp（硬边：亮度 0 → 135 单行跳变，左右两张预览卡一致）
  /// —— 宿主给滚动内容的上内边距；大标题（墨底 147.7dp）与它留 35.3dp 空档。
  static const double contentTopInset = 183.0;

  /// 内容首行是**搜索栏**时的顶缘：实测自参考截图「设置」首页搜索栏顶缘
  /// 523px = 168.5dp（同页卡片组顶缘 224.85dp，组间距 12.24dp）。
  /// 搜索栏比卡片类首行高 14.5dp，两个值都来自整机实测，故分档给出。
  static const double searchBarTopInset = 168.5;

  // ── 折叠动效（逐帧实测查找表） ─────────────────────────────────────────
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
