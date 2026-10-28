import '../../../theme/motion_tokens.dart';
import '../../../theme/typography.dart';

/// [MiDialog] 的几何与动效规格（设计度量，393dp 设计宽）。
///
/// 规格取自两组系统弹框参考素材（1220×2656 与 881×1920，各含明暗），
/// 统一换算 `dp = px × 393 / 素材宽`；两组素材存在 ≤2.4dp 的排版差异，
/// 垂直节奏取高分辨率一组。
///
///  * **卡片**：宽 369.2（左右边距 11.9）、圆角 49.3（圆弧拟合）、底部
///    留白 32.9、按钮区下留白 24.1、无投影；
///  * **文字落点以 `Baseline` 锚定**（与 [MiTopBarMetrics] 同法）：墨心
///    相对基线恒为 0.355em（中文各字体间稳定），布局期锚定基线后落点与
///    字体族无关；
///  * **按钮行**：高 49.9、圆角 15.0、行内缩 24.2、按钮间距 12.6、
///    双钮等宽（154.1 = (369.2 − 2×24.2 − 12.6) / 2）；
///  * **排版**：标题 18.0dp、正文 / 按钮标签 15.9dp、正文行距 23.2dp。
class MiDialogMetrics {
  MiDialogMetrics._();

  // ── 卡片 ────────────────────────────────────────────────────────────────

  /// 卡片左右边距（度量 36.5px×0.32213 = 11.76…11.9dp，与页边距 11.9 同值）。
  static const double sideMargin = 11.9;

  /// 卡片圆角（度量正圆拟合 R = 153px = 49.3dp）。
  static const double cardRadius = 49.3;

  /// 卡片距屏幕底缘（度量 32.9dp，含手势条让位；顶部位置为镜像推导）。
  ///
  /// 真机上再以安全区兜底：`max(edgeInset, 安全区 + 12)` —— 参考机手势条
  /// 高约 21dp，21 + 12 = 33 ≈ 度量 32.9，两解在参考机上不可分辨。
  static const double edgeInset = 32.9;

  /// 卡片高下限（**推导值**，非度量 —— issue #1 的「高度上限」只约束上限，
  /// 这里同时给 clamp 一个下限）：卡片可用高（屏高 − 上下让位）低于此值时
  /// （极端横屏 / 小窗）宁可让卡贴住安全区，也保住一块可读高度，避免卡被
  /// 压成一条。120 = 标题一行 + 一行内容 + 上下留白的最小可读组合。
  static const double minCardHeight = 120.0;

  /// 按钮盒下缘到卡片底（度量 24.1dp）。
  static const double bottomPad = 24.1;

  /// 卡片宽（= 393 − 2×[sideMargin]）。
  static const double cardWidth = 369.2;

  // ── 宽屏档（桌面，推导值） ────────────────────────────────────────────────
  //
  // 参考素材只有手机档（369.2 宽 / 49.3 圆角是**度量**）；桌面弹窗的通行
  // 形态是「居中窄卡」（Material / Windows Settings / macOS Alerts 同款），
  // 以下两项是布局常量而非度量值。

  /// 桌面档卡片**最大**宽度 440：正文行长控制在 ~40 字内（可读性上限），
  /// 又不至于像手机卡那样贴边。
  static const double wideCardMaxWidth = 440;

  /// 桌面档卡片圆角 16（手机档 49.3 是「底部贴边圆角卡」的度量；居中卡
  /// 没有「贴边」语义，改用通行的 16）。
  static const double wideCardRadius = 16;

  /// 卡片宽是否进入桌面档（按容器宽判定，与 [MiBreakpoints.desktop] 同值）。
  static bool isWide(double containerWidth) => containerWidth >= 1024;

  // ── 标题 / 正文 ─────────────────────────────────────────────────────────

  /// 墨心相对基线的比例（同 `MiTopBarMetrics.titleInkAboveBaseline`，见类注释）。
  static const double inkAboveBaseline = 0.355;

  /// 标题墨心距卡片顶（度量 36.4dp；主题商店弹框 38.8，整块低 2.4）。
  static const double titleInkCenterY = 36.4;

  /// 正文首行墨心距卡片顶（度量 75.55dp；主题商店弹框 78.1）。
  static const double messageInkCenterY = 75.55;

  /// 正文行距（度量行墨心 75.55 → 98.1，ink-top 间距 23.2dp）。
  static const double messageLinePitch = 23.2;

  /// 正文文本框左右内缩（度量首字墨左 28.3…29.3dp − 字面左边距 ≈ 28.0）。
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

  /// 正文**滚动区**（仅卡片高被 clamp 的路径）内首行基线。
  ///
  /// 滚动区顶端取「首行墨心 − 行距/2」（行盒上缘的推算位），因此区内基线
  /// 恒等于 `messageBaseline −（messageInkCenterY − 行距/2）` ≡ 17.24 ——
  /// 与标题行数无关（多行标题把区顶与基线一起下移，差值不变）。
  static double get messageScrollBaseline =>
      messageBaseline - (messageInkCenterY - messageLinePitch / 2);

  // ── 按钮行 ──────────────────────────────────────────────────────────────

  /// 双行正文时按钮盒顶缘距卡片顶（度量 133.0dp）。
  ///
  /// 行数每 ±1，按钮行随之 ±[messageLinePitch]：主题商店单行弹框按钮顶
  /// 113.3 + 整块 2.4 回调 ≈ 115.7，与 133.0 − 23.2 = 109.8 差 5.9dp ——
  /// 两 app 的 builder 本就有 2.4dp 级差，此处取联系人节奏一条线走到底。
  static const double actionsTopY = 133.0;

  /// 按钮高（度量 155px×0.32213 = 49.9dp，两 app 一致）。
  static const double actionHeight = 49.9;

  /// 按钮圆角（度量正圆拟合 R = 46.5px = 15.0dp）。
  static const double actionRadius = 15.0;

  /// 按钮行左右内缩（度量 24.2/23.8dp，取 24.2）。
  static const double actionRowInset = 24.2;

  /// 按钮间距（度量 12.6dp）。
  static const double actionGap = 12.6;

  /// 按钮标签墨心距按钮盒顶（度量 25.0dp = 盒高之半 24.95，居中）。
  static double get actionLabelBaseline =>
      actionHeight / 2 + inkAboveBaseline * MiTypography.dialogAction.fontSize!;

  /// 按压态过渡时长（ms）。**度量**（按压参考素材 24.31fps）：按下后逐帧
  /// 进度 47/80/96/100%（f29…f32），拟合 150ms easeOutQuad（mean|Δ|=0.02）；
  /// 回弹镜像同值（素材里松手即执行关闭、未见回弹，属**推导**）。
  ///
  /// 叠色配方（黑/白 @0.12，只压填充不碰标签）见
  /// [MiTransparencyTokens.dialogPressAlpha]。
  ///
  /// 同源转发自 [MiMotionTokens]（统一动效配置），新代码请直接取 token。
  static const int pressDurationMs = MiMotionTokens.pressMs;

  /// 按钮盒顶缘（[lines] = 正文行数）：双行度量 133.0，行数每 ±1 平移一行距。
  static double actionsTopFor(int lines) =>
      actionsTopY + (lines - 2) * messageLinePitch;

  /// 卡片高（[lines] = 正文行数）：双行度量 207.1dp。
  static double cardHeightFor(int lines) =>
      actionsTopFor(lines) + actionHeight + bottomPad;
}
