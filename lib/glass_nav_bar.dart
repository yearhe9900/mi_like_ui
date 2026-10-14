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
/// | pill (settled)           | 282 x 153       | 90.8 x 49.3 |
/// | pill / cell width ratio  | 282/255 = 1.106 | -       |
/// | pill vertical inset      | ~10             | 3.05    |
/// | icon box                 | ~68 x 72        | 21.9 x 23.2 |
/// | label font (CJK glyph h) | 31              | 10.5    |
/// | icon-label gap           | 17              | 5.5     |
///
/// Motion (tracked at 24.3 fps):
///  * position curve ≈ Curves.easeOutSine (best fit, no overshoot)
///  * duration = 260 ms + 20 ms per cell travelled (measured 260~340 ms)
///  * jelly squash & stretch: mid-flight the pill grows up to +35% wider
///    and -7.5% shorter (3-cell jump measured 380x142 px vs 282x153 px),
///    peak deformation around t = 0.3 of the animation.
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
  static const double pillWidthOverCell = 282 / 255;
  static const double pillInsetV = 3.05;
  static const double iconHeight = 23.2;
  static const double iconLabelGap = 5.5;
  static const double labelFontSize = 10.5;

  static const double maxJellyCells = 3;
  static const double jellyStretch = 0.35;
  static const double jellySquash = 0.075;

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

class _GlassNavBarState extends State<GlassNavBar> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _from = 0;
  double _to = 0;
  double _travelCells = 0;

  @override
  void initState() {
    super.initState();
    _from = _to = widget.selectedIndex.toDouble();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
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
      _ctrl.duration = Duration(milliseconds: (260 + 20 * _travelCells).round());
      _ctrl.forward(from: 0);
    }
  }

  double get _currentPos {
    if (_ctrl.value <= 0) return _from;
    return _from + (_to - _from) * Curves.easeOutSine.transform(_ctrl.value);
  }

  @override
  void dispose() {
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
            final pillW = cellW * GlassNavMetrics.pillWidthOverCell;
            final pillH = GlassNavMetrics.barHeight - 2 * GlassNavMetrics.pillInsetV;

            return ClipRRect(
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
                      animation: _ctrl,
                      builder: (context, _) {
                        final t = _ctrl.value;
                        final bell = math.sin(math.pi * math.pow(t, 0.8).toDouble());
                        final distF = (_travelCells / GlassNavMetrics.maxJellyCells).clamp(0.0, 1.0);
                        final w = pillW * (1 + GlassNavMetrics.jellyStretch * distF * bell);
                        final h = pillH * (1 - GlassNavMetrics.jellySquash * distF * bell);
                        final cx = GlassNavMetrics.barInnerPad + cellW * (_currentPos + 0.5);
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
                        ],
                      ),
                    ),
                  ],
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
