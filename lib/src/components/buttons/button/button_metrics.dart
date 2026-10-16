/// [MiButton] 的几何参数：1:1 实测自「我的关注」页的关注按钮。
///
/// Source: 1220x2656 px full screenshots（亮/暗两张，按钮几何与配色完全
/// 一致，只有页面底色不同）。Scale to a 393 dp design width:
/// s = 393 / 1220 = 0.32213.
///
/// | item               | shot px     | dp          |
/// |--------------------|-------------|-------------|
/// | button size (关注) | 186 x 88    | 59.9 x 28.3 |
/// | corner radius      | 44 (= h/2)  | stadium     |
/// | label ink (关注)   | 73 x 35     | 23.5 x 11.3 |
/// | label em           | ~40         | ~13         |
/// | side padding       | ~53         | ~17         |
/// | list row pitch     | 174         | 56.1        |
///
/// 实测要点：
///  * stadium 圆角：bbox 顶行蓝像素起于 x0+44（= h/2），两端半圆同心；
///  * 宽度是**内容自适应**：「关注」advance 2×13 = 26dp + 左右 2×17dp
///    = 60dp ≈ 实测 59.9dp（非定宽按钮）；
///  * 字号 / 字重不在此处，见 `theme/typography.dart` 的
///    `MiTypography.buttonLabel`；配色见 `theme/button_tokens.dart`。
class MiButtonMetrics {
  MiButtonMetrics._();

  /// 按钮高度（实测 88px）。
  static const double height = 28.3;

  /// 左右内边距（实测 (186 - 80) / 2 = 53px ≈ 17dp）。
  static const double horizontalPadding = 17;

  /// 列表行距（实测 174px，参考页头像行的行间节奏，demo 行高沿用）。
  static const double listRowPitch = 56.1;
}
