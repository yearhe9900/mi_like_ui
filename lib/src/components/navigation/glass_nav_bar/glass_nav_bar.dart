import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/glass_tokens.dart';
import '../../../theme/typography.dart';
import '../../../utils/cell_grid.dart';
import 'glass_nav_bar_metrics.dart';
import 'glass_nav_bar_painter.dart';

/// 导航栏的一个 tab：文字标签 + 任意图标 painter。
class MiGlassNavItem {
  const MiGlassNavItem({required this.label, required this.painter});

  final String label;
  final CustomPainter painter;
}

/// 小米主题商店风格的深色玻璃悬浮底部导航栏（可复用组件）。
///
/// 交互（均为视频逐帧实测）：
///  * 点按切换：胶囊果冻飞行 + 弹簧沉降（参数见 [MiGlassNavMetrics]）；
///  * 按压缩圈：胶囊宽 -3% / 高 -7.5%，被按 tab 瞬时变暗 55%；
///  * 拖拽切换：胶囊 1:1 跟手 + 速度拉伸，松手吸附最近 tab。
///
/// 玻璃材质配方见 `theme/glass_tokens.dart`。
class MiGlassNavBar extends StatefulWidget {
  const MiGlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<MiGlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  State<MiGlassNavBar> createState() => _MiGlassNavBarState();
}

class _MiGlassNavBarState extends State<MiGlassNavBar> with TickerProviderStateMixin {
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
      duration: const Duration(milliseconds: MiGlassNavMetrics.pressMs),
    );
  }

  @override
  void didUpdateWidget(covariant MiGlassNavBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      // start from wherever the pill currently is, so rapid taps can
      // retarget mid-flight without jumps
      _from = _currentPos;
      _to = widget.selectedIndex.toDouble();
      _travelCells = (_to - _from).abs();
      _ctrl.duration = Duration(
        milliseconds: (MiGlassNavMetrics.flightBaseMs +
                    MiGlassNavMetrics.flightPerCellMs * _travelCells)
                .round() +
            MiGlassNavMetrics.settleMs.round(),
      );
      _ctrl.forward(from: 0);
    }
  }

  /// Fraction of controller time spent in the flight phase (the rest is the
  /// settle tail).
  double get _flightFraction {
    final flightMs =
        MiGlassNavMetrics.flightBaseMs + MiGlassNavMetrics.flightPerCellMs * _travelCells;
    return flightMs / (flightMs + MiGlassNavMetrics.settleMs);
  }

  /// Pill centre in cell units at controller value [t] (0..1 over flight +
  /// settle). During the settle tail the centre overshoots the target by
  /// [MiGlassNavMetrics.settleOvershoot]·cellW·wave(s) in the travel direction.
  double _posAt(double t) {
    if (t <= 0) return _from;
    final ff = _flightFraction;
    if (t <= ff) {
      return _from + (_to - _from) * Curves.easeOutSine.transform(t / ff);
    }
    final s = (t - ff) / (1 - ff);
    return _to +
        (_to - _from).sign * MiGlassNavMetrics.settleOvershoot * MiGlassNavMetrics.settleWave(s);
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
        .clamp(0.0, MiGlassNavMetrics.dragStretchMax);
    _stretchDecay?.cancel();
    _stretchDecay = Timer(const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _dragStretch = 0);
    });
    setState(() => _pressedIndex = nearestCell(pos, n));
  }

  void _dragEnd() {
    _stretchDecay?.cancel();
    final n = widget.items.length;
    final from = _dragPos!;
    final target = nearestCell(from, n);
    _dragPos = null;
    _dragStretch = 0;
    // snap to the nearest tab with the usual flight+settle animation
    _from = from;
    _to = target.toDouble();
    _travelCells = (_to - _from).abs();
    _ctrl.duration = Duration(
      milliseconds: (MiGlassNavMetrics.flightBaseMs +
                  MiGlassNavMetrics.flightPerCellMs * _travelCells)
              .round() +
          MiGlassNavMetrics.settleMs.round(),
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
      padding: const EdgeInsets.symmetric(horizontal: MiGlassNavMetrics.barMarginH),
      child: SizedBox(
        height: MiGlassNavMetrics.barHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barW = constraints.maxWidth;
            final cellW = (barW - 2 * MiGlassNavMetrics.barInnerPad) / widget.items.length;
            final pillW = MiGlassNavMetrics.pillWidth(cellW);
            const pillH = MiGlassNavMetrics.barHeight - 2 * MiGlassNavMetrics.pillInsetV;

            int indexAt(double dx) => cellIndexAt(
                  dx: dx,
                  leadingInset: MiGlassNavMetrics.barInnerPad,
                  cellWidth: cellW,
                  count: widget.items.length,
                );

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
                  borderRadius: BorderRadius.circular(MiGlassNavMetrics.barHeight / 2),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: MiGlassTokens.blurSigma,
                      sigmaY: MiGlassTokens.blurSigma,
                    ),
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
                              squash = MiGlassNavMetrics.settleSquashRatio * _dragStretch;
                            } else if (t <= ff) {
                              // flight: bell-shaped jelly squash & stretch
                              final p = t / ff;
                              final bell = math.sin(math.pi * math.pow(p, 0.8).toDouble());
                              final distF =
                                  (_travelCells / MiGlassNavMetrics.maxJellyCells).clamp(0.0, 1.0);
                              stretch = MiGlassNavMetrics.jellyStretch * distF * bell;
                              squash = MiGlassNavMetrics.jellySquash * distF * bell;
                            } else {
                              // settle tail: position overshoot + width undershoot
                              final f = MiGlassNavMetrics.settleWave((t - ff) / (1 - ff));
                              stretch = -MiGlassNavMetrics.settleSquash * f;
                              squash = -MiGlassNavMetrics.settleSquash *
                                  MiGlassNavMetrics.settleSquashRatio *
                                  f;
                            }

                            // press squeeze ("缩圈"): the pill shrinks while a
                            // finger is down, on top of any flight/drag shape.
                            final press = _pressCtrl.value;
                            stretch -= MiGlassNavMetrics.pressSquashW * press;
                            squash += MiGlassNavMetrics.pressSquashH * press;

                            var w = pillW * (1 + stretch);
                            final h = pillH * (1 - squash);
                            var cx = MiGlassNavMetrics.barInnerPad +
                                cellW * ((_dragPos ?? _posAt(t)) + 0.5);

                            // Clamp the pill rect to the equidistant gap bounds.
                            // At the end tabs the overshoot/flight-stretch hits
                            // this wall and renders as width compression
                            // (measured -5.8% vs -2.2% mid-bar).
                            var left = cx - w / 2;
                            var right = cx + w / 2;
                            const minLeft = MiGlassNavMetrics.pillInsetV;
                            final maxRight = barW - MiGlassNavMetrics.pillInsetV;
                            if (left < minLeft) left = minLeft;
                            if (right > maxRight) right = maxRight;
                            w = right - left;
                            cx = (left + right) / 2;

                            return CustomPaint(
                              painter: GlassBarPainter(
                                pillCenterX: cx,
                                pillWidth: w,
                                pillHeight: h,
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: MiGlassNavMetrics.barInnerPad),
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
                                          ? MiGlassNavMetrics.pressDimOpacity
                                          : 1.0,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CustomPaint(
                                            painter: widget.items[i].painter,
                                            size: const Size(24, MiGlassNavMetrics.iconHeight),
                                          ),
                                          const SizedBox(height: MiGlassNavMetrics.iconLabelGap),
                                          Text(widget.items[i].label, style: MiTypography.navLabel),
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
