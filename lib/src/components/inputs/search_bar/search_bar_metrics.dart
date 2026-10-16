/// [MiSearchBar] 的几何参数：1:1 实测自亮/暗分类页完整截图。
///
/// Source: 881x1920 px full screenshots of the theme-store 分类页
/// (light & dark — geometry identical). Scale to a 393 dp design width:
/// s = 393 / 881 = 0.44608.
///
/// | item                     | shot px  | dp       |
/// |--------------------------|----------|----------|
/// | bar height               | 99       | 44.2     |
/// | icon box (magnifier)     | 40 x 40  | 17.8     |
/// | icon leading inset       | 34.5     | 15.4     |
/// | icon ↔ text gap          | 27       | 12.0     |
/// | hint advance (CJK em)    | 37       | 16.5     |
/// | icon stroke              | 4        | 1.8      |
///
/// 实测要点（亮/暗两图交叉一致）：
///  * 栏高 99px ≈ 44.2dp；框架取 44.1 —— 与 1220px 版截图（137px ×
///    0.32213 = 44.1）互证，且分类页吸顶测试钉住 `56 + 44.1 + 16`；
///  * stadium 圆角（左缘 AA 剖面 dy2→dy40 内收完 = 半径 ≈ 高/2），
///    取 [MiDimens.radiusPill]（半径钳位后渲染即 stadium）；
///  * 图标与占位文字**垂心居中**（实测垂心偏移 +0.0dp）：图标
///    dyTop 13.4 / 文字 dyTop 14.3 与 (44.1 − 内容高)/2 一致；
///  * 页面级左右 inset ≈12dp 属页面内容边距（11.9），由调用方
///    Padding 提供，组件自身占满可用宽；
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

  /// 镜片圆半径（笔画中心线，实测 13.2~14px ≈ 6.0）。
  static const double lensRadius = 6.0;
}
