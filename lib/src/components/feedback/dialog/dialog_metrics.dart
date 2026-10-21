import '../../../theme/typography.dart';

/// 弹框几何 token（1:1 实测自 MIUI 系统弹框参考图）。
///
/// 采样口径：参考截图 1220×2656（联系人「删除联系人」，原生分辨率）与
/// 881×1920（主题商店「删除1项资源」，缩放图）四张（各明/暗），统一换算
/// `dp = px × 393 / 图宽`。**垂直节奏以联系人弹框为准**（原生分辨率，
/// 精度最高）；主题商店弹框整块文字低约 2.4dp、少一行正文后卡片矮 19.7dp，
/// 两 app 的 builder 略有出入，交叉复核见各类注释。
///
/// 三条主线：
///  * **卡片**：宽 369.2（左右各 11.9，与实测页边距同值）、圆角 49.3
///    （正圆拟合 rms 0.99px，squircle 拟合差 6 倍，排除超级椭圆）、
///    底部留白 32.9、按钮区下留白 24.1、无投影；
///  * **文字落点由 `Baseline` 钉死**（同 [MiTopBarMetrics] 的做法）：
///    墨心相对基线 `0.355em` 跨中文字体很稳（simhei 0.360 / msyh 0.350 /
///    simsun 0.355），基线在行盒内的位置却只由字体度量决定 —— 用
///    `Baseline(baselineType: alphabetic)` 把基线放到「墨心 + 0.355em」，
///    墨心落点即与字体族无关；
///  * **按钮行**：高 49.9、圆角 15.0（正圆拟合 rms 0.16px）、行内缩 24.2、
///    按钮间 12.6、双钮等宽（154.1 = (369.2 − 2×24.2 − 12.6) / 2）。
///
/// 字号（自相关 + 纯 CJK 字面模板匹配）：标题 18.0（= 顶栏紧凑标题同档）、
/// 正文 / 按钮标签 15.9。正文行距 23.2（首行墨心 75.55 → 次行 98.1 的
/// ink-top 间距；同一行盒内两行差只可能是行高）。
class MiDialogMetrics {
  MiDialogMetrics._();

  // ── 卡片 ────────────────────────────────────────────────────────────────

  /// 卡片左右边距（实测 36.5px×0.32213 = 11.76…11.9dp，与页边距 11.9 同值）。
  static const double sideMargin = 11.9;

  /// 卡片圆角（实测正圆拟合 R = 153px = 49.3dp）。
  static const double cardRadius = 49.3;

  /// 卡片距屏幕底缘（实测 32.9dp，含手势条让位；顶部位置为镜像推导）。
  ///
  /// 真机上再以安全区兜底：`max(edgeInset, 安全区 + 12)` —— 参考机手势条
  /// 高约 21dp，21 + 12 = 33 ≈ 实测 32.9，两解在参考机上不可分辨。
  static const double edgeInset = 32.9;

  /// 按钮盒下缘到卡片底（实测 24.1dp）。
  static const double bottomPad = 24.1;

  /// 卡片宽（= 393 − 2×[sideMargin]）。
  static const double cardWidth = 369.2;

  // ── 标题 / 正文 ─────────────────────────────────────────────────────────

  /// 墨心相对基线的比例（同 `MiTopBarMetrics.titleInkAboveBaseline`，见类注释）。
  static const double inkAboveBaseline = 0.355;

  /// 标题墨心距卡片顶（实测 36.4dp；主题商店弹框 38.8，整块低 2.4）。
  static const double titleInkCenterY = 36.4;

  /// 正文首行墨心距卡片顶（实测 75.55dp；主题商店弹框 78.1）。
  static const double messageInkCenterY = 75.55;

  /// 正文行距（实测行墨心 75.55 → 98.1，ink-top 间距 23.2dp）。
  static const double messageLinePitch = 23.2;

  /// 正文文本框左右内缩（实测首字墨左 28.3…29.3dp − 字面左边距 ≈ 28.0）。
  static const double messageInset = 28.0;

  /// 由墨心反推基线目标值（`Baseline` 从自身顶端量起）。
  static double baselineFor(double inkCenterY, double fontSize) =>
      inkCenterY + inkAboveBaseline * fontSize;

  /// 标题基线目标值。
  static double get titleBaseline =>
      baselineFor(titleInkCenterY, MiTypography.dialogTitle.fontSize!);

  /// 正文首行基线目标值（行 2 起由行距 `messageLinePitch` 顺推）。
  static double get messageBaseline =>
      baselineFor(messageInkCenterY, MiTypography.dialogMessage.fontSize!);

  // ── 按钮行 ──────────────────────────────────────────────────────────────

  /// 双行正文时按钮盒顶缘距卡片顶（实测 133.0dp）。
  ///
  /// 行数每 ±1，按钮行随之 ±[messageLinePitch]：主题商店单行弹框按钮顶
  /// 113.3 + 整块 2.4 回调 ≈ 115.7，与 133.0 − 23.2 = 109.8 差 5.9dp ——
  /// 两 app 的 builder 本就有 2.4dp 级差，此处取联系人节奏一条线走到底。
  static const double actionsTopY = 133.0;

  /// 按钮高（实测 155px×0.32213 = 49.9dp，两 app 一致）。
  static const double actionHeight = 49.9;

  /// 按钮圆角（实测正圆拟合 R = 46.5px = 15.0dp）。
  static const double actionRadius = 15.0;

  /// 按钮行左右内缩（实测 24.2/23.8dp，取 24.2）。
  static const double actionRowInset = 24.2;

  /// 按钮间距（实测 12.6dp）。
  static const double actionGap = 12.6;

  /// 按钮标签墨心距按钮盒顶（实测 25.0dp = 盒高之半 24.95，居中）。
  static double get actionLabelBaseline =>
      actionHeight / 2 + inkAboveBaseline * MiTypography.dialogAction.fontSize!;

  /// 按钮盒顶缘（[lines] = 正文行数）：双行实测 133.0，行数每 ±1 平移一行距。
  static double actionsTopFor(int lines) =>
      actionsTopY + (lines - 2) * messageLinePitch;

  /// 卡片高（[lines] = 正文行数）：双行实测 207.1dp。
  static double cardHeightFor(int lines) =>
      actionsTopFor(lines) + actionHeight + bottomPad;
}
