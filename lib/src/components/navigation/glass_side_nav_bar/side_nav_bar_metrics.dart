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
/// 同构；栏体圆角取 `railWidth / 2`（全圆角），选中胶囊圆角取
/// `itemHeight / 2`，与底部栏的 stadium 语义一致。
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

  /// 栏体圆角（全圆角，与底部栏 stadium 同语义）。
  static const double railRadius = railWidth / 2;

  /// 选中胶囊圆角（短轴全圆角）。
  static const double pillRadius = itemHeight / 2;

  /// 图标墨盒尺寸（与底部栏一致）。
  static const double iconSize = 24;
  static const double iconHeight = MiGlassNavMetrics.iconHeight;
  static const double iconLabelGap = MiGlassNavMetrics.iconLabelGap;

  /// 栏体高度：`2 × 内边距 + n × 条目高 + (n − 1) × 间隙`。
  static double railHeightFor(int count) {
    assert(count > 0, 'count 必须为正');
    return 2 * railInnerPad + count * itemHeight + (count - 1) * itemGap;
  }
}
