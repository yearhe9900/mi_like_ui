import 'dart:math' as math;

/// [MiGlassNavBar] 的几何与动效规格（设计度量，393dp 设计宽）。
///
/// 规格取自 1220×2656 参考素材，换算系数 s = 393 / 1220 = 0.32213：
///
/// | 项目                  | 素材 px        | dp         |
/// |-----------------------|----------------|------------|
/// | 栏体尺寸              | 1062 x 172     | 342 x 55.4 |
/// | 栏体左右边距          | 79             | 25.5       |
/// | 格宽                  | 255            | 82.1       |
/// | 胶囊（静止）          | 277 x 153      | 89.3 x 49.3 |
/// | 胶囊 / 格宽比         | 277/255 = 1.086 | —         |
/// | 胶囊垂直内缩          | ~10            | 3.05       |
/// | 图标墨盒              | ~68 x 72       | 21.9 x 23.2 |
/// | 标签字高（CJK）       | 31             | 10.5       |
/// | 图标与标签间距        | 17             | 5.5        |
///
/// FAB 规格（3 tab + 圆钮素材补充）：
///
/// | 项目          | 素材 px       | dp              |
/// |---------------|---------------|-----------------|
/// | 格宽          | 252           | 81              |
/// | FAB 直径      | 171           | 55.1 ≈ 栏高     |
/// | 栏体与 FAB 间距 | 37          | 11.9            |
///
/// 格宽不随 tab 数变化，栏体宽度 = 内容宽（n × 格宽 + 2 × 内边距）、整体
/// 水平居中；tab 超过 4 个时格宽收缩以适配 [barMarginH] 的最大栏宽。
///
/// 动效规格（24.3fps 素材逐帧跟踪）：
///
///  * **飞行**：位置曲线 ≈ `Curves.easeOutSine`，时长 = 260ms +
///    20ms × 跨格数（度量 260~340ms）；
///  * **果冻形变**：飞行中胶囊最宽 +35%、最矮 −7.5%（3 格跳变度量
///    380×142px 对静止 282×153px），峰值约在 t = 0.3；
///  * **弹性沉降**：胶囊越过目标后回弹阻尼收敛（~350ms），中心过冲峰值
///    为格宽的 3.7%、宽度反向收缩 −2.2%（高度反向，比率 0.214）；
///    包络 sin(π·s^0.6)·exp(−1.2·s)，在 s = 0 与 s = 1 处恰为 0 ——
///    静止帧与迁移前逐像素一致；
///  * **端点钳制**：胶囊矩形钳制于 [pillInsetV]…barW − [pillInsetV]，
///    端部 tab 的过冲转化为额外宽度压缩（度量 −5.8%，中部 −2.2%）。
///
/// 文字样式见 `theme/typography.dart`，颜色见 `theme/colors.dart`，
/// 玻璃材质配方见 `theme/glass_tokens.dart`。
class MiGlassNavMetrics {
  static const double barMarginH = 25.5;
  static const double barHeight = 55.4;
  static const double barInnerPad = 6.6;
  static const double pillInsetV = 3.05;

  /// 标称 tab 格宽（视频 255px / 252px ≈ 82dp，不随 tab 数变化）。
  static const double cellWidth = 82.2;

  /// Pill width from the equidistance constraint: settled on an end tab the
  /// pill's cap must stay CONCENTRIC with the bar's cap (both cap centers on
  /// x = barHeight/2), so the pill-to-bar gap is exactly [pillInsetV] all
  /// around the rounded end — tip included — instead of varying 2.25..3.05.
  /// At the reference grid: 82.2 + 2*(6.6-3.05) = 89.3 dp (ratio 1.086).
  /// (Raw video measure 282 px included the 1 px stroke halo; the geometric
  /// equidistant width 277 px falls within that halo uncertainty.)
  static double pillWidth(double cellW) => cellW + 2 * (barInnerPad - pillInsetV);
  static const double iconHeight = 23.2;
  static const double iconLabelGap = 5.5;

  static const double maxJellyCells = 3;
  static const double jellyStretch = 0.35;
  static const double jellySquash = 0.075;

  /// 指针悬停时条目后面那块圆角高亮的半径（**推导值**，无桌面样张）。
  ///
  /// 条目区 ≈ [cellWidth] × [barHeight]，取 16 —— 明显小于半高（27.7，那是
  /// 胶囊形），与胶囊里的选中态形成区分：悬停是「一小块圆角」、选中是
  /// 「整格胶囊」。
  static const double itemHoverRadius = 16;

  // --- press feedback (measured on the grab frames of the video) -----------
  // While a finger is down, the pill squashes ("缩圈": width -2~3%, height
  // -7.5%) and the pressed tab's icon+label dims to ~55% opacity. The dim is
  // instant (< 1 frame), the squeeze eases over ~90 ms.
  static const double pressSquashW = 0.03;
  static const double pressSquashH = 0.075;
  static const double pressDimOpacity = 0.55;
  static const int pressMs = 90;

  // --- drag (measured) ----------------------------------------------------
  // The pill follows the finger 1:1 and shows the same wider+shorter jelly as
  // in flight, +5.6% width at fast drag, 0 when holding still. The release of
  // that jelly must never be a single-frame snap (read as a visible width
  // jump on slow drags): hold [dragStretchHoldMs] after the last movement
  // event, then ease out over [dragStretchDecayMs].
  static const double dragStretchMax = 0.056;
  static const int dragStretchHoldMs = 80;
  static const int dragStretchDecayMs = 180;

  // --- spring settle tail (see class doc) ---------------------------------
  static const double flightBaseMs = 260;
  static const double flightPerCellMs = 20;
  static const double settleMs = 350;

  /// 名义兑底时长 300ms：`AnimationController` 的占位 duration，每次飞行前
  /// 按 [flightBaseMs] + [flightPerCellMs]×跨格数重设（兑底惯例同
  /// `MiPullUpPanelMetrics.springSettleMs`）。底栏 / 侧栏共用。
  static const int nominalFlightFallbackMs = 300;

  /// Peak centre overshoot past the target, as a fraction of one cell width.
  static const double settleOvershoot = 0.037;

  /// Peak width undershoot at the target, as a fraction of the pill width.
  static const double settleSquash = 0.022;

  /// Height reacts inversely to width by this ratio (= jellySquash /
  /// jellyStretch, volume-ish conservation as measured).
  static const double settleSquashRatio = 0.214;

  /// Precomputed max of [settleWave]'s raw envelope.
  static const double _settleWavePeak = 0.7330067679563963;

  /// Normalised settle envelope: peak 1 at s ≈ 0.21, exactly 0 at s = 0 and
  /// s = 1 (so a finished animation leaves the pill dead on target).
  static double settleWave(double s) {
    final raw = math.sin(math.pi * math.pow(s, 0.6)) * math.exp(-1.2 * s);
    return raw / _settleWavePeak;
  }

  // --- reserved circular button slot (预留空位圆钮，圆钮视频度量) ----------
  // With the button shown, [bar, gap, button] forms a centred row: the bar
  // centre sits exactly (fabDiameter + fabGap)/2 left of the screen centre and
  // the button pops IN PLACE at W/2 + (barW+fabGap)/2 (measured cx = 1015 px
  // on the 1220 px screen, constant through the whole pop). The button
  // diameter matches the bar height (171 px vs 170 px bar).
  //
  // Motion (24.3 fps ground truth): button scale+alpha pop ≈ easeOutCubic
  // over 165 ms (samples 0.60/0.88/0.98/1.00 at +1..4 frames), the close is
  // the same curve reversed (1.00/0.88/0.58/0.00 — measured, time-mirrored).
  // The bar shift runs alongside on easeOutQuad over 205 ms (samples
  // 0.08/0.40/0.70/0.89/0.97/1.00), both starting on the tab-switch frame.
  static const double fabGap = 11.9;
  static const double fabDiameter = barHeight;
  static const int fabPopMs = 165;
  static const int fabShiftMs = 205;
}
