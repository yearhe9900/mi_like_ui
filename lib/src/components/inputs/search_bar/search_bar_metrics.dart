/// [MiSearchBar] 的几何规格（设计度量，393dp 设计宽）。
///
/// 规格取自 881×1920 参考素材（明暗各一组，几何一致），换算系数
/// s = 393 / 881 = 0.44608：
///
/// | 项目                 | 素材 px | dp    |
/// |----------------------|---------|-------|
/// | 栏高                 | 99      | 44.2  |
/// | 图标墨盒（放大镜）   | 40 x 40 | 17.8  |
/// | 图标左缘内缩         | 34.5    | 15.4  |
/// | 图文间距             | 27      | 12.0  |
/// | 占位文字字号（CJK）  | 37      | 16.5  |
/// | 图标笔画             | 4       | 1.8   |
///
/// 说明（明暗两组交叉一致）：
///
///  * 栏高取 44.1dp（99px 度量 44.2dp，与另一组素材 137px × 0.32213 =
///    44.1dp 互证）；
///  * stadium 圆角（半径钳位后渲染即 stadium）；
///  * 图标与占位文字垂直居中（度量垂心偏移 0.0dp）；
///  * 页面级左右边距属内容边距（11.9dp），由调用方以 `Padding` 提供，
///    组件自身占满可用宽；
///  * 图标内部几何（镜片圆 + 45° 手柄）见 [lensCenter] / [lensRadius]，
///    随 [iconSize] 等比缩放。
///
/// 文字样式见 `theme/typography.dart`（[MiTypography.searchHint]），
/// 配色见 `theme/search_bar_tokens.dart`。
class MiSearchBarMetrics {
  MiSearchBarMetrics._();

  /// 栏高（44.1：与 1220px 截图互证 + 吸顶测试钉值）。
  static const double barHeight = 44.1;

  /// 图标距栏左内边距（34.5px）。
  static const double contentInset = 15.4;

  /// 放大镜包围盒边长（40px 见方）。
  static const double iconSize = 17.8;

  /// 图标右缘 → 占位文字左缘（27px，恰为 MiDimens.spaceMd 12）。
  static const double iconGap = 12.0;

  /// 放大镜笔画宽（4px，round cap）。
  static const double iconStroke = 1.8;

  /// 镜片圆心（相对 icon box 左上；设计单位 = iconSize 基准）。
  static const double lensCenter = 6.9;

  /// 镜片圆半径（笔画中心线，度量 13.2~14px ≈ 6.0）。
  static const double lensRadius = 6.0;

  /// 搜索态输入光标高度（度量 32px ≈ 21.3dp，栏高 44.1 的 48%，垂心居中）。
  ///
  /// 与 [barHeight] 一起把光标钉死：Flutter 默认光标高随字体行盒算，
  /// 换字体族就会漂；这里给的是度量绝对值。
  static const double caretHeight = 21.3;
}
