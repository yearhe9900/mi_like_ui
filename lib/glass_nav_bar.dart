import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// 1:1 metrics measured pixel-by-pixel from the reference video.
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
/// Glass physics (as measured):
///  * the bar is a heavy dark scrim over a blurred backdrop;
///  * the pill is a "glass lens" that CUTS the scrim (even-odd hole) and
///    shows the backdrop at ~60% transmission + a small white tint
///    (measured pill luminance: 30 on black content, 48 on dark content,
///    81 over bright content — never a flat color).
class GlassNavMetrics {
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
  static const double labelFontSize = 10.5;

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

  static const Color iconColor = Color(0xFFF5F5F5);
}

class GlassNavItem {
  const GlassNavItem({required this.label, required this.painter});

  final String label;
  final CustomPainter painter;
}

class GlassNavBar extends StatefulWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar> with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _pressCtrl;
  double _from = 0;
  double _to = 0;
  double _travelCells = 0;

  /// continuous cell position while a finger is dragging the pill (null = idle)
  double? _dragPos;
  double _dragStretch = 0;
  Timer? _stretchDecay;

  /// tab whose icon+label is dimmed (pressed / hovered during drag)
  int? _pressedIndex;

  @override
  void initState() {
    super.initState();
    _from = _to = widget.selectedIndex.toDouble();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: GlassNavMetrics.pressMs),
    );
  }

  @override
  void didUpdateWidget(covariant GlassNavBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      // start from wherever the pill currently is, so rapid taps can
      // retarget mid-flight without jumps
      _from = _currentPos;
      _to = widget.selectedIndex.toDouble();
      _travelCells = (_to - _from).abs();
      _ctrl.duration = Duration(
        milliseconds: (GlassNavMetrics.flightBaseMs +
                    GlassNavMetrics.flightPerCellMs * _travelCells)
                .round() +
            GlassNavMetrics.settleMs.round(),
      );
      _ctrl.forward(from: 0);
    }
  }

  /// Fraction of controller time spent in the flight phase (the rest is the
  /// settle tail).
  double get _flightFraction {
    final flightMs =
        GlassNavMetrics.flightBaseMs + GlassNavMetrics.flightPerCellMs * _travelCells;
    return flightMs / (flightMs + GlassNavMetrics.settleMs);
  }

  /// Pill centre in cell units at controller value [t] (0..1 over flight +
  /// settle). During the settle tail the centre overshoots the target by
  /// [GlassNavMetrics.settleOvershoot]·cellW·wave(s) in the travel direction.
  double _posAt(double t) {
    if (t <= 0) return _from;
    final ff = _flightFraction;
    if (t <= ff) {
      return _from + (_to - _from) * Curves.easeOutSine.transform(t / ff);
    }
    final s = (t - ff) / (1 - ff);
    return _to +
        (_to - _from).sign * GlassNavMetrics.settleOvershoot * GlassNavMetrics.settleWave(s);
  }

  double get _currentPos => _dragPos ?? _posAt(_ctrl.value);

  void _pressDown(int index) {
    setState(() => _pressedIndex = index);
    _pressCtrl.forward();
  }

  void _pressUp() {
    setState(() => _pressedIndex = null);
    _pressCtrl.reverse();
  }

  void _dragStart(double cellW) {
    _dragPos = _currentPos;
  }

  void _dragUpdate(double dx, double cellW) {
    final n = widget.items.length;
    final pos = (_dragPos! + dx / cellW).clamp(0.0, n - 1.0);
    _dragPos = pos;
    // velocity jelly: grows with per-event dx, decays when the finger pauses
    _dragStretch = (_dragStretch + (dx.abs() / cellW) * 0.6)
        .clamp(0.0, GlassNavMetrics.dragStretchMax);
    _stretchDecay?.cancel();
    _stretchDecay = Timer(const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _dragStretch = 0);
    });
    setState(() => _pressedIndex = pos.round().clamp(0, n - 1));
  }

  void _dragEnd() {
    _stretchDecay?.cancel();
    final n = widget.items.length;
    final from = _dragPos!;
    final target = from.round().clamp(0, n - 1);
    _dragPos = null;
    _dragStretch = 0;
    // snap to the nearest tab with the usual flight+settle animation
    _from = from;
    _to = target.toDouble();
    _travelCells = (_to - _from).abs();
    _ctrl.duration = Duration(
      milliseconds: (GlassNavMetrics.flightBaseMs +
                  GlassNavMetrics.flightPerCellMs * _travelCells)
              .round() +
          GlassNavMetrics.settleMs.round(),
    );
    _ctrl.forward(from: 0);
    if (target != widget.selectedIndex) widget.onTap(target);
  }

  void _dragCancel() {
    // fires even for plain taps (the drag recognizer loses the arena without
    // ever starting) — nothing to cancel unless a drag was actually live
    if (_dragPos == null) return;
    _stretchDecay?.cancel();
    final from = _dragPos!;
    _dragPos = null;
    _dragStretch = 0;
    _from = from;
    _to = widget.selectedIndex.toDouble();
    _travelCells = (_to - _from).abs();
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _stretchDecay?.cancel();
    _pressCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GlassNavMetrics.barMarginH),
      child: SizedBox(
        height: GlassNavMetrics.barHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barW = constraints.maxWidth;
            final cellW = (barW - 2 * GlassNavMetrics.barInnerPad) / widget.items.length;
            final pillW = GlassNavMetrics.pillWidth(cellW);
            const pillH = GlassNavMetrics.barHeight - 2 * GlassNavMetrics.pillInsetV;

            int indexAt(double dx) =>
                ((dx - GlassNavMetrics.barInnerPad) / cellW).floor().clamp(0, widget.items.length - 1);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => _dragStart(cellW),
              onHorizontalDragUpdate: (d) => _dragUpdate(d.primaryDelta ?? 0, cellW),
              onHorizontalDragEnd: (_) => _dragEnd(),
              onHorizontalDragCancel: _dragCancel,
              child: Listener(
                onPointerDown: (e) => _pressDown(indexAt(e.localPosition.dx)),
                onPointerUp: (_) => _pressUp(),
                onPointerCancel: (_) => _pressUp(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(GlassNavMetrics.barHeight / 2),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // The blur above tints this transparent layer with the
                        // backdrop; everything below paints on top of it.
                        const SizedBox.expand(),
                        AnimatedBuilder(
                          animation: Listenable.merge([_ctrl, _pressCtrl]),
                          builder: (context, _) {
                            final t = _ctrl.value;
                            final ff = _flightFraction;
                            // width/height scale deltas; >0 stretch = wider/shorter
                            double stretch;
                            double squash;
                            if (_dragPos != null) {
                              // drag: velocity jelly (wider+shorter, as flight)
                              stretch = _dragStretch;
                              squash = GlassNavMetrics.settleSquashRatio * _dragStretch;
                            } else if (t <= ff) {
                              // flight: bell-shaped jelly squash & stretch
                              final p = t / ff;
                              final bell = math.sin(math.pi * math.pow(p, 0.8).toDouble());
                              final distF =
                                  (_travelCells / GlassNavMetrics.maxJellyCells).clamp(0.0, 1.0);
                              stretch = GlassNavMetrics.jellyStretch * distF * bell;
                              squash = GlassNavMetrics.jellySquash * distF * bell;
                            } else {
                              // settle tail: position overshoot + width undershoot
                              final f = GlassNavMetrics.settleWave((t - ff) / (1 - ff));
                              stretch = -GlassNavMetrics.settleSquash * f;
                              squash = -GlassNavMetrics.settleSquash *
                                  GlassNavMetrics.settleSquashRatio *
                                  f;
                            }

                            // press squeeze ("缩圈"): the pill shrinks while a
                            // finger is down, on top of any flight/drag shape.
                            final press = _pressCtrl.value;
                            stretch -= GlassNavMetrics.pressSquashW * press;
                            squash += GlassNavMetrics.pressSquashH * press;

                            var w = pillW * (1 + stretch);
                            final h = pillH * (1 - squash);
                            var cx = GlassNavMetrics.barInnerPad +
                                cellW * ((_dragPos ?? _posAt(t)) + 0.5);

                            // Clamp the pill rect to the equidistant gap bounds.
                            // At the end tabs the overshoot/flight-stretch hits
                            // this wall and renders as width compression
                            // (measured -5.8% vs -2.2% mid-bar).
                            var left = cx - w / 2;
                            var right = cx + w / 2;
                            const minLeft = GlassNavMetrics.pillInsetV;
                            final maxRight = barW - GlassNavMetrics.pillInsetV;
                            if (left < minLeft) left = minLeft;
                            if (right > maxRight) right = maxRight;
                            w = right - left;
                            cx = (left + right) / 2;

                            return CustomPaint(
                              painter: _GlassBarPainter(
                                pillCenterX: cx,
                                pillWidth: w,
                                pillHeight: h,
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: GlassNavMetrics.barInnerPad),
                          child: Row(
                            children: [
                              for (var i = 0; i < widget.items.length; i++)
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => widget.onTap(i),
                                    child: Opacity(
                                      // pressed tab content dims (measured ~55%)
                                      opacity: _pressedIndex == i
                                          ? GlassNavMetrics.pressDimOpacity
                                          : 1.0,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CustomPaint(
                                            painter: widget.items[i].painter,
                                            size: const Size(24, GlassNavMetrics.iconHeight),
                                          ),
                                          const SizedBox(height: GlassNavMetrics.iconLabelGap),
                                          Text(
                                            widget.items[i].label,
                                            style: const TextStyle(
                                              color: GlassNavMetrics.iconColor,
                                              fontSize: GlassNavMetrics.labelFontSize,
                                              height: 1.0,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Paints the dark scrim (with a stadium-shaped hole where the pill is),
/// the pill glass lens and the subtle rim highlights.
class _GlassBarPainter extends CustomPainter {
  _GlassBarPainter({
    required this.pillCenterX,
    required this.pillWidth,
    required this.pillHeight,
  });

  final double pillCenterX;
  final double pillWidth;
  final double pillHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final barR = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    final pillRect = Rect.fromCenter(
      center: Offset(pillCenterX, size.height / 2),
      width: pillWidth,
      height: pillHeight,
    );
    final pillR = RRect.fromRectAndRadius(
      pillRect,
      Radius.circular(pillHeight / 2),
    );

    // 1) dark scrim with a hole where the pill sits (the pill is a lens
    //    through the scrim, which is why it brightens with the content)
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRRect(barR),
      Path()..addRRect(pillR),
    );
    canvas.drawPath(scrim, Paint()..color = const Color.fromRGBO(20, 20, 20, 0.63));

    // 2) pill lens: ~60% content transmission + small white tint
    canvas.drawRRect(pillR, Paint()..color = const Color.fromRGBO(0, 0, 0, 0.40));
    canvas.drawRRect(pillR, Paint()..color = const Color.fromRGBO(255, 255, 255, 0.118));
    canvas.drawRRect(
      pillR,
      Paint()
        ..color = const Color.fromRGBO(255, 255, 255, 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 3) bar rim highlight
    canvas.drawRRect(
      barR,
      Paint()
        ..color = const Color.fromRGBO(255, 255, 255, 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassBarPainter old) =>
      old.pillCenterX != pillCenterX ||
      old.pillWidth != pillWidth ||
      old.pillHeight != pillHeight;
}
