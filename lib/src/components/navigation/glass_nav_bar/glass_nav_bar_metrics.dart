import 'dart:math' as math;

/// [MiGlassNavBar] 的几何 / 动效参数：1:1 逐帧实测自参考视频。
///
/// Source frame: 1220x2656 px screen recording (Xiaomi theme store app).
/// Scale to a 393 dp design width: s = 393 / 1220 = 0.32213.
///
/// | item                     | video px        | dp      |
/// |--------------------------|-----------------|---------|
/// | bar size                 | 1062 x 172      | 342 x 55.4 |
/// | bar side margin          | 79              | 25.5    |
/// | tab cell width           | 255             | 82.1    |
/// | pill (settled)           | 277 x 153       | 89.3 x 49.3 |
/// | pill / cell width ratio  | 277/255 = 1.086 | -       |
/// | pill vertical inset      | ~10             | 3.05    |
/// | icon box                 | ~68 x 72        | 21.9 x 23.2 |
/// | label font (CJK glyph h) | 31              | 10.5    |
/// | icon-label gap           | 17              | 5.5     |
///
/// Motion (tracked at 24.3 fps, pixel ground truth):
///  * flight phase: position curve ≈ Curves.easeOutSine (best fit),
///    duration = 260 ms + 20 ms per cell travelled (measured 260~340 ms)
///  * jelly squash & stretch: mid-flight the pill grows up to +35% wider
///    and -7.5% shorter (3-cell jump measured 380x142 px vs 282x153 px),
///    peak deformation around t = 0.3 of the animation.
///  * settle tail (the end-of-flight behaviour, measured on the 1px
///    luminance ground truth of JUMP1/JUMP4/JUMP6): the pill does NOT dead
///    land — it springs past the target and damps back over ~350 ms.
///    Centre overshoot peaks at 3.7% of a cell width while the width dips
///    -2.2% (height reacts inversely, ratio 0.214). The wave
///    sin(π·s^0.6)·exp(-1.2·s) fits the envelope and is exactly 0 at both
///    s = 0 and s = 1, so the settled frame is pixel-identical to before.
///  * end clamp: the pill rect is clamped to [pillInsetV, barW-pillInsetV]
///    (the equidistant gap bounds). At the end tabs the overshoot hits that
///    wall and turns into extra width compression instead: measured
///    rendered width -5.8% at the ends vs -2.2% mid-bar, which the model +
///    clamp reproduces.
///
/// 文字样式见 `theme/typography.dart`，颜色见 `theme/colors.dart`，
/// 玻璃材质配方见 `theme/glass_tokens.dart`。
class MiGlassNavMetrics {
  static const double barMarginH = 25.5;
  static const double barHeight = 55.4;
  static const double barInnerPad = 6.6;
  static const double pillInsetV = 3.05;

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
  // in flight, +5.6% width at fast drag, 0 when holding still.
  static const double dragStretchMax = 0.056;

  // --- spring settle tail (see class doc) ---------------------------------
  static const double flightBaseMs = 260;
  static const double flightPerCellMs = 20;
  static const double settleMs = 350;

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
}
