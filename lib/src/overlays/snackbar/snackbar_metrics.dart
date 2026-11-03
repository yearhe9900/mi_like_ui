/// `MiSnackbar` 的几何 / 时序规格（**全部推导值**，无实机素材）。
///
/// 取值口径（对齐本库既有度量，不新造数）：
///  * **宽**：手机档 = 屏宽 − 2×11.9（弹框卡同边距口径）；宽屏限宽 440
///    （弹框宽屏档同口径）；
///  * **圆角** 15.0（弹框按钮行圆角同档）；
///  * **正文**：`MiTypography.dialogMessage`（弹框正文 15.9dp 同源），
///    墨色复用弹框标题墨色（见 [MiSnackbarPalette]）；
///  * **内边距** 水平 16 / 垂直 14，最小高 48（单行通行条高）；
///  * **距屏底** 24（页面边距档）+ 手势条让位（`MediaQuery.padding`）；
///  * **投影**：浅色 = 弹出面板投影同口径（黑 @0.12 / blur 14 / 下偏 4，
///    颜色 `MiTransparencyTokens.panelShadow`）；暗色不投影（黑底上
///    不可分辨，同面板先例）；
///  * **时序**：常驻 2500ms（通行惯例）、滑入 300ms `easeOut` / 滑出
///    200ms `easeIn`、位移 24dp（`Transform.translate`，不引 saveLayer）。
class MiSnackbarMetrics {
  MiSnackbarMetrics._();

  /// 手机档左右边距（弹框卡同边距 11.9）。
  static const double horizontalMargin = 11.9;

  /// 宽屏限宽（弹框宽屏档同口径 440，推导）。
  static const double maxWidth = 440;

  /// 圆角（弹框按钮行 15.0 同档）。
  static const double radius = 15.0;

  /// 水平 / 垂直内边距。
  static const double paddingH = 16;
  static const double paddingV = 14;

  /// 最小高（单行通行条高，推导）。
  static const double minHeight = 48;

  /// 距屏底（页面边距档；手势条让位由 `MediaQuery.padding` 追加）。
  static const double bottomOffset = 24;

  /// 文案与动作钮的间距。
  static const double actionGap = 16;

  /// 投影（仅浅色）：blur / 下偏 —— 弹出面板投影同口径。
  static const double shadowBlur = 14;
  static const double shadowOffsetY = 4;

  /// 常驻时长（到时自动收起；通行惯例推导）。
  static const int durationMs = 2500;

  /// 入场 / 出场时长（组件私有动效的家，见 `*_metrics.dart` 约定）。
  static const int slideInMs = 300;
  static const int slideOutMs = 200;

  /// 入场位移（dp；自下滑入）。
  static const double slideOffset = 24;
}
