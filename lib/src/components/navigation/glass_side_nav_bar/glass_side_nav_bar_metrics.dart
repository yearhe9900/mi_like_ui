import '../../../theme/dimens.dart';
import '../glass_nav_bar/glass_nav_bar_metrics.dart';

/// [MiGlassSideNavBar] 的几何规格（**推导值**）。
///
/// 参考素材中没有侧边导航栏样张，因此不引入新的度量值，而是把
/// [MiGlassNavMetrics] 的已度量规格按语义换算到纵向，保证两种导航形态
/// 视觉同源：
///
/// | 参数 | 取值 | 来源 |
/// |------|------|------|
/// | `railWidth` | **95.4** | `cellWidth 82.2 + 2 × barInnerPad 6.6`（一格占位 → 栏宽） |
/// | `itemWidth` | **82.2** | `MiGlassNavMetrics.cellWidth`（内容宽度不变） |
/// | `itemHeight` | **49.3** | `barHeight 55.4 − 2 × pillInsetV 3.05`（选中胶囊高度） |
/// | `itemGap` | **8** | [MiDimens.spaceSm]（条目间隙，底部栏无间隙） |
/// | `railInnerPad` | **6.6** | `MiGlassNavMetrics.barInnerPad` |
/// | `railMargin` | **25.5** | `MiGlassNavMetrics.barMarginH`（侧向留白） |
/// | `iconSize / iconHeight / iconLabelGap` | 24 / 23.2 / 5.5 | 与底部栏一致 |
///
/// 栏体收缩到内容高（`railHeightFor(n)`）、位置由宿主给（建议贴顶、距左缘
/// [railMargin]）；选中胶囊圆角 = `itemHeight / 2`，栏体圆角 = 胶囊圆角 +
/// 内边距（内外圈等距 [railInnerPad]，见 [railRadius]）。
///
/// 动效参数不在此重复：飞行 / 弹性沉降 / 按压 / 拖拽复用
/// [MiGlassNavMetrics]（仅轴向换为纵向），两种形态手感一致。
class MiGlassSideNavMetrics {
  MiGlassSideNavMetrics._();

  /// 栏宽（= 底部栏一格 + 两侧内边距）。
  static const double railWidth =
      MiGlassNavMetrics.cellWidth + 2 * MiGlassNavMetrics.barInnerPad;

  /// 条目（选中胶囊）宽度 = 底部栏度量格宽。
  static const double itemWidth = MiGlassNavMetrics.cellWidth;

  /// 条目（选中胶囊）高度 = 底部栏度量胶囊高度。
  static const double itemHeight =
      MiGlassNavMetrics.barHeight - 2 * MiGlassNavMetrics.pillInsetV;

  /// 条目之间的纵向间隙。
  static const double itemGap = MiDimens.spaceSm;

  /// 栏体内边距（条目到栏体边缘）。
  static const double railInnerPad = MiGlassNavMetrics.barInnerPad;

  /// 栏体到页面左缘的留白（与底部栏的侧向留白同源）。
  static const double railMargin = MiGlassNavMetrics.barMarginH;

  /// 侧栏占用列的总宽 = 留白 + 栏宽；示例用它给内容让位。
  static const double gutterWidth = railMargin + railWidth;

  /// 内容列与侧栏之间的**分隔留白**（推导值，参考素材无横屏样张）。
  ///
  /// 栏体是浮在页面底色上的玻璃面板，内容列的横幅又通栏满铺 —— 两者
  /// 相贴（间距 0）时没有呼吸感（实机反馈：横屏下左栏与内容无分隔）。
  /// 取 [MiDimens.spaceXxl]（24，与栏体左留白 25.5 同档），示例外壳在
  /// [gutterWidthFor] 之外再让出这一档。
  static const double contentSeparation = MiDimens.spaceXxl;

  // ── 展开态（带文字标签，桌面档）──────────────────────────────────────────
  //
  // 参考素材同样没有展开态样张，以下全部是**推导值**：只沿用已度量的
  // 纵向节奏（条目高 / 内边距 / 间隙），横向按「图标 + 文字」的通行
  // 桌面侧栏形态给值。

  /// 展开态栏宽 **176**：按展开态实际字号 `MiTypography.navLabel`（10.5dp，
  /// 与底部栏同款）重推 ——
  ///
  /// `2×内缩 18 + 图标 24 + 间距 12 + 标签 + 2×栏内边距 6.6`：
  ///  * 2 字（首页 / 分类 / 我的）→ 标签 21 → 栏 **106.2**；
  ///  * 6 字 → 标签 63 → 栏 **148.2**；
  ///  * 7 字 → 标签 73.5 → 栏 **158.7**；
  ///  * 8 字 → 标签 84 → 栏 **169.2**。
  ///
  /// 取 176 = 8 字上限 169.2 再留一档余量（西文混排 / 字距）。首版取的 240
  /// 是**错的**：推导时把标签当成 13.85dp（那是 `pillLabel` 胶囊标签的字号）
  /// 又翻倍留量，实际展开态用 10.5dp —— 结果「首页」的选中胶囊 70% 是空白。
  ///
  /// 与 Material / Windows Settings 常驻侧栏（200…320）比偏窄，但那两家的
  /// 标签普遍 6…8 字且字号 13…14；本库标签 10.5dp、常见 2…4 字，宽度该跟着
  /// 内容走而不是跟着别人的栏走。
  static const double expandedRailWidth = 176;

  /// 展开态条目（选中胶囊）宽 = 栏宽 − 2×内边距 = 162.8。
  static const double expandedItemWidth = expandedRailWidth - 2 * railInnerPad;

  /// 展开态条目内容（图标左缘）到胶囊左缘的内缩。
  static const double expandedItemInset = 18;

  /// 展开态图标 → 标签间距（[MiDimens.spaceMd] 档）。
  static const double expandedIconLabelGap = MiDimens.spaceMd;

  /// 展开态侧栏占用列的总宽（= 留白 + 展开栏宽 = 201.5）。
  static const double expandedGutterWidth = railMargin + expandedRailWidth;

  /// 侧栏列宽（按形态取窄栏 / 展开栏），示例外壳给内容让位时用它。
  static double gutterWidthFor({bool expanded = false}) =>
      expanded ? expandedGutterWidth : gutterWidth;

  /// 内容列的左缘让位 = 侧栏列 + 分隔留白（[contentSeparation]）。
  ///
  /// 示例外壳与几何测试同源取用，避免两处各算一份。
  static double contentInsetFor({bool expanded = false}) =>
      gutterWidthFor(expanded: expanded) + contentSeparation;

  /// 栏体宽（按形态取窄栏 / 展开栏）。
  static double railWidthFor({bool expanded = false}) =>
      expanded ? expandedRailWidth : railWidth;

  /// 条目（选中胶囊）宽（按形态取）。
  static double itemWidthFor({bool expanded = false}) =>
      expanded ? expandedItemWidth : itemWidth;

  /// 条目纵向步进（胶囊高 + 间隙）。
  static const double pitch = itemHeight + itemGap;

  /// 选中胶囊圆角（短轴全圆角）。
  static const double pillRadius = itemHeight / 2;

  /// 栏体圆角：**以内圈胶囊为准等距外扩**（`胶囊圆角 + 内边距` = 31.25）。
  ///
  /// 曾用「全圆角 stadium」`railWidth / 2`（= 47.7）——但那与内圈胶囊
  /// （圆角 24.65、顶部条目中心 y 31.25）**不同心**：栏体端头半圆的圆心在
  /// (47.7, 47.7)，胶囊顶角圆弧的圆心在 (31.25, 31.25)，两圆心距 23.26 <
  /// 47.7 − 24.65 = 23.05 不成立 ⇒ 两圆弧相交，胶囊肩部与栏体轮廓的间距
  /// 从侧边/顶端的 6.6 一路收缩到 0（甚至轻微穿出被裁）——「内外圈间距」
  /// 四周不一致。
  ///
  /// 改为圆角 = 内圈圆角 + 间距后，栏体端头圆弧与胶囊顶角圆弧**同心**
  /// （圆心同为 (31.25, 31.25) / 底部同理），外缘在四周与胶囊恒距
  /// [railInnerPad] = 6.6 —— 与底部栏「pill 端头与栏体端头同心、间距恒
  /// [MiGlassNavMetrics.pillInsetV]」是同一条等距原则（内外圈间距一致，
  /// 以内圈为准）。
  static const double railRadius = pillRadius + railInnerPad;

  /// 图标墨盒尺寸（与底部栏一致）。
  static const double iconSize = 24;
  static const double iconHeight = MiGlassNavMetrics.iconHeight;
  static const double iconLabelGap = MiGlassNavMetrics.iconLabelGap;

  /// 栏体高度：`2 × 内边距 + n × 条目高 + (n − 1) × 间隙`。
  static double railHeightFor(int count) {
    assert(count > 0, 'count 必须为正');
    return 2 * railInnerPad + count * itemHeight + (count - 1) * itemGap;
  }

  /// 预留空位圆钮直径 = 底部栏度量（171px ≈ 栏高 170px）。
  static const double fabDiameter = MiGlassNavMetrics.fabDiameter;

  /// 圆钮到栏尾的间距 = 底部栏度量（37px）。
  static const double fabGap = MiGlassNavMetrics.fabGap;

  /// 配置了圆钮时组件的总高 = 栏体高 + 间距 + 圆钮直径。
  ///
  /// 圆钮槽位**恒定预留**（收起时只是 Opacity 0，不改布局高度）——
  /// 显隐不会引起任何几何跳动。
  static double heightFor(int count, {bool hasFab = false}) =>
      railHeightFor(count) + (hasFab ? fabGap + fabDiameter : 0);
}
