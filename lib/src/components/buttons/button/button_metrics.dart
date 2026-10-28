/// [MiButton] 的几何规格（设计度量，393dp 设计宽）。
///
/// 规格取自 1220×2656 参考素材（明暗各一组，几何一致），换算系数
/// s = 393 / 1220 = 0.32213：
///
/// | 项目               | 素材 px     | dp          |
/// |--------------------|-------------|-------------|
/// | 按钮尺寸           | 186 x 88    | 59.9 x 28.3 |
/// | 圆角               | 44 (= h/2)  | stadium     |
/// | 标签墨迹（2 字）   | 73 x 35     | 23.5 x 11.3 |
/// | 标签字号（CJK em） | ~40         | ~13         |
/// | 左右内边距         | ~53         | ~17         |
/// | 列表行距           | 174         | 56.1        |
///
/// 说明：
///
///  * stadium 圆角（两端半圆同心）；
///  * 宽度内容自适应：标签 advance 2×13dp + 左右 2×17dp ≈ 60dp
///    （度量值 59.9dp），非定宽按钮；
///  * 字号 / 字重见 `theme/typography.dart`（`MiTypography.buttonLabel`），
///    配色见 `theme/button_tokens.dart`。
class MiButtonMetrics {
  MiButtonMetrics._();

  /// 按钮高度（度量 88px）。
  static const double height = 28.3;

  /// 左右内边距（度量 (186 - 80) / 2 = 53px ≈ 17dp）。
  static const double horizontalPadding = 17;

  /// 列表行距（度量 174px，参考页头像行的行间节奏，demo 行高沿用）。
  static const double listRowPitch = 56.1;

  /// 按压 / 状态切换过渡 200ms `easeOut`（**推导值**：参考素材无按压帧，
  /// 按本库按压反馈语义取快闪档；与胶囊标签选中淡入同值同曲线）。
  static const int pressDurationMs = 200;
}
