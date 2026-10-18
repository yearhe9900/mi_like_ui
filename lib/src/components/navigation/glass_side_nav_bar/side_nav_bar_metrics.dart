import '../../../theme/dimens.dart';
import '../glass_nav_bar/glass_nav_bar_metrics.dart';

/// [MiGlassSideNavBar] 的几何参数。
///
/// ## 全部为「推导（非实测）」
///
/// 参考素材（1220×2656 录屏 / 截图）里**只有底部导航栏**，没有侧边导航栏
/// 的样张。所以这里不引入任何新的像素读数，而是把底部栏**已实测的 token
/// 按语义搬到纵向**，保证两种形态在视觉上同源：
///
/// | 参数 | 取值 | 来源 |
/// |------|------|------|
/// | `railWidth` | **95.4** | `cellWidth 82.2 + 2 × barInnerPad 6.6` —— 底部栏一格再加两侧内边距，即「横向一格占位」原样转成栏宽 |
/// | `itemWidth` | **82.2** | `MiGlassNavMetrics.cellWidth`（实测格宽，胶囊里的内容宽度不变） |
/// | `itemHeight` | **49.3** | `barHeight 55.4 − 2 × pillInsetV 3.05`（实测选中胶囊高度，内容栈 icon+gap+label 高度不变） |
/// | `itemGap` | **8** | [MiDimens.spaceSm]：底部栏格子紧邻无间隙，纵向需要一档间隙分隔条目 |
/// | `railInnerPad` | **6.6** | `MiGlassNavMetrics.barInnerPad`（栏体到内容的内边距） |
/// | `railMargin` | **25.5** | `MiGlassNavMetrics.barMarginH`（悬浮边缘留白，底栏是距屏底 24.2/侧向 25.5 一档，这里取侧向值） |
/// | `iconSize / iconHeight / iconLabelGap` | 24 / 23.2 / 5.5 | 与底部栏完全相同（图标墨盒、笔画、间距一字不改） |
///
/// 栏体本身**收缩到内容高**（`railHeightFor(n)`），位置由宿主给（示例：贴顶、
/// 距左缘 [railMargin] 一档留白）—— 与底部栏「栏宽 = 内容宽、位置由宿主给」
/// 同构；选中胶囊圆角取 `itemHeight / 2`，栏体圆角 = **胶囊圆角 + 内边距**
/// （以内圈为准等距外扩，内外圈间距四周恒 [railInnerPad]，见 [railRadius]）。
///
/// 动效参数不在本类重复：飞行 / 弹性沉降 / 按压 / 拖拽全部复用
/// [MiGlassNavMetrics]（只把轴换成纵向），两种形态手感才会一致。
class MiGlassSideNavMetrics {
  MiGlassSideNavMetrics._();

  /// 栏宽（= 底部栏一格 + 两侧内边距）。
  static const double railWidth =
      MiGlassNavMetrics.cellWidth + 2 * MiGlassNavMetrics.barInnerPad;

  /// 条目（选中胶囊）宽度 = 底部栏实测格宽。
  static const double itemWidth = MiGlassNavMetrics.cellWidth;

  /// 条目（选中胶囊）高度 = 底部栏实测胶囊高度。
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
  /// [MiGlassNavMetrics.pillInsetV]」是同一条等距原则（2026-10-18 用户
  /// 反馈：平板模式内外圈间距应一致，以内圈为准）。
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

  /// 预留空位圆钮直径 = 底部栏实测（171px ≈ 栏高 170px）。
  static const double fabDiameter = MiGlassNavMetrics.fabDiameter;

  /// 圆钮到栏尾的间距 = 底部栏实测（37px）。
  static const double fabGap = MiGlassNavMetrics.fabGap;

  /// 配置了圆钮时组件的总高 = 栏体高 + 间距 + 圆钮直径。
  ///
  /// 圆钮槽位**恒定预留**（收起时只是 Opacity 0，不改布局高度）——
  /// 显隐不会引起任何几何跳动。
  static double heightFor(int count, {bool hasFab = false}) =>
      railHeightFor(count) + (hasFab ? fabGap + fabDiameter : 0);
}
