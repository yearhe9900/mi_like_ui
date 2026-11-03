/// `MiSlider` 的几何 / 交互规格（**全部推导值**，无实机素材）。
///
/// 取值口径：
///  * 轨道高 4、拇指 ⌀20：Material 3 同档（通行滑条尺寸）；
///  * 命中高 32（拇指外扩触区，通行 44 命中区的折中 —— 滑条是连续拖拽
///    控件，上下扩到 32 已够指针命中）；
///  * 键盘步长 = (max − min) / 20（方向键一格，推导）；[divisions] 给出
///    时按档吸附（拖拽与键盘同口径）；
///  * 活动段 = `MiColors.accent`、非活动段 = onSurface @12%（开关关闭档
///    同档 state layer，`MiTransparencyTokens.switchTrackOffFor` 复用）；
///  * 拇指白钮 + 浅色轻投影（开关钮同口径）。
class MiSliderMetrics {
  MiSliderMetrics._();

  /// 轨道高 / 拇指直径 / 命中高。
  static const double trackHeight = 4;
  static const double thumbSize = 20;
  static const double hitHeight = 32;

  /// 键盘步长的分母（推导：一格 = 全程 1/20）。
  static const double keyboardSteps = 20;
}
