import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/glass_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../utils/squircle.dart';
import '../../../theme/typography.dart';
import '../../../utils/cell_grid.dart';
import '../../../utils/filter_cache.dart';
import '../../../utils/hover_feedback.dart';
import 'glass_nav_bar_metrics.dart';
import 'glass_nav_bar_painter.dart';

/// 导航栏的一个 tab：文字标签 + 任意图标 painter。
class MiGlassNavItem {
  const MiGlassNavItem({required this.label, required this.painter});

  final String label;
  final CustomPainter painter;
}

/// 浮动圆钮（FAB，可选），与导航栏配套。
///
/// 仅当 [MiGlassNavBar.items] ≤ 3 个时支持（超出会在构造期断言）。
/// 选中 [tabIndex] 对应 tab 时按钮以缩放 + 淡入弹出、栏体平移让出空位；
/// 切换到其它 tab 时镜像收起、栏体回中。
class MiGlassNavFab {
  const MiGlassNavFab({
    required this.tabIndex,
    required this.child,
    this.color,
    this.onTap,
  });

  /// 显示圆钮的 tab 下标；选中其它 tab 时圆钮不显示。
  final int tabIndex;

  /// 圆钮内容（图标等），居中绘制在圆内。
  final Widget child;

  /// 圆钮底色；`null` 时按 [MiGlassNavBar.themeMode] 取
  /// [MiColors.fabGreenFor]（深 #25BF43 / 浅 #66CB61）。
  final Color? color;

  /// 点按回调。
  final VoidCallback? onTap;
}

/// 玻璃悬浮底部导航栏（明暗双模式）。
///
/// 交互（动效规格见 [MiGlassNavMetrics]）：
///  * 点按切换：胶囊飞行 + 弹簧沉降；
///  * 按压反馈：胶囊宽 −3% / 高 −7.5%，被按 tab 即时压暗 55%；
///  * 拖拽切换：胶囊 1:1 跟手 + 速度拉伸，松手吸附最近 tab；
///  * 浮动圆钮（可选 [fab]）：配置 tab 选中时弹出、切走收起，栏体同步
///    平移让位（仅支持 ≤3 个 tab）。
///
/// 玻璃材质配方见 `theme/glass_tokens.dart`（按 [themeMode] 取明暗配方）；
/// 图标颜色由调用方随 painter 传入，建议取 [MiColors.foregroundFor]。
class MiGlassNavBar extends StatefulWidget {
  const MiGlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.fab,
    this.themeMode = MiThemeMode.dark,
  });
  // items 数量、fab 适配与 fab.tabIndex 范围校验均在 initState：const 构造
  // 断言不支持 .length / 参数字段求值（放构造器会封死 const 构造）

  final List<MiGlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  /// 预留空位圆形按钮；null = 不启用。
  final MiGlassNavFab? fab;

  /// 明暗模式：决定玻璃材质配方与标签墨色（默认深色）。
  final MiThemeMode themeMode;

  @override
  State<MiGlassNavBar> createState() => _MiGlassNavBarState();
}

class _MiGlassNavBarState extends State<MiGlassNavBar> with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _pressCtrl;
  late final AnimationController _fabCtrl;
  late final AnimationController _shiftCtrl;
  double _from = 0;
  double _to = 0;
  double _travelCells = 0;

  /// continuous cell position while a finger is dragging the pill (null = idle)
  double? _dragPos;

  /// Velocity jelly while dragging. Displayed value eases to 0 with
  /// [_stretchCtrl] after a finger pause or at release — never a hard reset,
  /// which read as a single-frame width jump on slow drags. `_stretchFrom` is
  /// the tween's start value; live = from·(1-eased(t)).
  double _stretchFrom = 0;
  late final AnimationController _stretchCtrl;
  Timer? _stretchDecay;

  /// tab whose icon+label is dimmed (pressed / hovered during drag)
  int? _pressedIndex;

  /// 预留空位圆钮是否应显示（fab 配置的 tab 被选中）。
  bool get _showFab => widget.fab != null && widget.selectedIndex == widget.fab!.tabIndex;

  @override
  void initState() {
    super.initState();
    final fab = widget.fab;
    assert(widget.items.isNotEmpty, 'items 不能为空');
    assert(
      fab == null || widget.items.length <= 3,
      '预留空位圆形按钮仅支持 3 个及以下 tab',
    );
    assert(
      fab == null || (fab.tabIndex >= 0 && fab.tabIndex < widget.items.length),
      'fab.tabIndex 必须落在 items 范围内',
    );
    _from = _to = widget.selectedIndex.toDouble();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: MiGlassNavMetrics.nominalFlightFallbackMs,
      ),
    );
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: MiGlassNavMetrics.pressMs),
    );
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: MiGlassNavMetrics.fabPopMs),
    );
    _shiftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: MiGlassNavMetrics.fabShiftMs),
    );
    _stretchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: MiGlassNavMetrics.dragStretchDecayMs),
    );
    // 首帧即处于稳态（配置的 tab 已选中则直接显示，无入场动画）
    final show = _showFab;
    _fabCtrl.value = show ? 1 : 0;
    _shiftCtrl.value = show ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant MiGlassNavBar old) {
    super.didUpdateWidget(old);
    final wasShown = old.fab != null && old.selectedIndex == old.fab!.tabIndex;
    if (wasShown != _showFab) {
      // 显示：缩放+淡入弹出 / 栏体左移让位；收起：同曲线 reverse 时间镜像。
      // forward/reverse 从当前值继续，快速连点 tab 不跳变。
      if (_showFab) {
        _fabCtrl.forward();
        _shiftCtrl.forward();
      } else {
        _fabCtrl.reverse();
        _shiftCtrl.reverse();
      }
    }
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

  /// Current jelly amount (0..dragStretchMax); decays to 0 after the finger
  /// pauses ([MiGlassNavMetrics.dragStretchHoldMs]) or releases.
  double get _liveStretch =>
      _stretchFrom * (1 - Curves.easeOutCubic.transform(_stretchCtrl.value));

  /// Ease the jelly out over [MiGlassNavMetrics.dragStretchDecayMs], starting
  /// from whatever is displayed right now so the width never pops.
  void _bleedStretch() {
    final live = _liveStretch;
    if (live <= 0) return;
    _stretchFrom = live;
    _stretchCtrl.forward(from: 0);
  }

  void _dragStart(double cellW) {
    _dragPos = _currentPos;
  }

  void _dragUpdate(double dx, double cellW) {
    final n = widget.items.length;
    final pos = (_dragPos! + dx / cellW).clamp(0.0, n - 1.0);
    _dragPos = pos;
    // velocity jelly: grows with per-event dx, decays when the finger pauses
    final live = _liveStretch;
    _stretchCtrl.stop();
    _stretchCtrl.value = 0;
    _stretchFrom =
        (live + (dx.abs() / cellW) * 0.6).clamp(0.0, MiGlassNavMetrics.dragStretchMax);
    _stretchDecay?.cancel();
    _stretchDecay = Timer(
      const Duration(milliseconds: MiGlassNavMetrics.dragStretchHoldMs),
      _bleedStretch,
    );
    setState(() => _pressedIndex = nearestCell(pos, n));
  }

  void _dragEnd() {
    _stretchDecay?.cancel();
    final n = widget.items.length;
    final from = _dragPos!;
    final target = nearestCell(from, n);
    _dragPos = null;
    _bleedStretch(); // residual jelly eases out over the snap flight
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
    _bleedStretch();
    _from = from;
    _to = widget.selectedIndex.toDouble();
    _travelCells = (_to - _from).abs();
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _stretchDecay?.cancel();
    _stretchCtrl.dispose();
    _pressCtrl.dispose();
    _shiftCtrl.dispose();
    _fabCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MiGlassPalette.of(widget.themeMode);
    final labelStyle = MiTypography.navLabelFor(widget.themeMode);
    return SizedBox(
      height: MiGlassNavMetrics.barHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final n = widget.items.length;
          final screenW = constraints.maxWidth;
          // 栏体宽度=内容宽（n × 标称格宽），上限为 [barMarginH] 的最大栏宽；
          // ≥4 tab 时格宽收缩，与旧版固定 342 宽行为一致。
          final maxBarW = screenW - 2 * MiGlassNavMetrics.barMarginH;
          final cellW = math.min(
            MiGlassNavMetrics.cellWidth,
            (maxBarW - 2 * MiGlassNavMetrics.barInnerPad) / n,
          );
          final barW = 2 * MiGlassNavMetrics.barInnerPad + n * cellW;
          final pillW = MiGlassNavMetrics.pillWidth(cellW);
          const pillH = MiGlassNavMetrics.barHeight - 2 * MiGlassNavMetrics.pillInsetV;

          int indexAt(double dx) => cellIndexAt(
                dx: dx,
                leadingInset: MiGlassNavMetrics.barInnerPad,
                cellWidth: cellW,
                count: n,
              );

          // 浅色下玻璃体带投影；深色配方投影为空，不包任何额外层（视觉回归零变化）。
          Widget glass = ClipPath(
            clipper: const MiSquircleClipper(MiGlassNavMetrics.barHeight / 2),
            child: BackdropFilter(
                  // σ 固定 → 复用缓存的 native filter（每帧重建是纯开销）
                  filter: MiFilterCache.blur(MiTransparencyTokens.blurSigma),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // The blur above tints this transparent layer with the
                      // backdrop; everything below paints on top of it.
                      const SizedBox.expand(),
                      AnimatedBuilder(
                        animation: Listenable.merge([_ctrl, _pressCtrl, _stretchCtrl]),
                        builder: (context, _) {
                          final t = _ctrl.value;
                          final ff = _flightFraction;
                          // width/height scale deltas; >0 stretch = wider/shorter
                          final jelly = _liveStretch;
                          double stretch;
                          double squash;
                          if (_dragPos != null) {
                            // drag: velocity jelly (wider+shorter, as flight)
                            stretch = jelly;
                            squash = MiGlassNavMetrics.settleSquashRatio * jelly;
                          } else if (t <= ff) {
                            // flight: bell-shaped jelly squash & stretch
                            final p = t / ff;
                            final bell = math.sin(math.pi * math.pow(p, 0.8).toDouble());
                            final distF =
                                (_travelCells / MiGlassNavMetrics.maxJellyCells).clamp(0.0, 1.0);
                            stretch = MiGlassNavMetrics.jellyStretch * distF * bell;
                            squash = MiGlassNavMetrics.jellySquash * distF * bell;
                            // residual finger jelly bleeding off after release
                            stretch += jelly;
                            squash += MiGlassNavMetrics.settleSquashRatio * jelly;
                          } else {
                            // settle tail: position overshoot + width undershoot
                            final f = MiGlassNavMetrics.settleWave((t - ff) / (1 - ff));
                            stretch = -MiGlassNavMetrics.settleSquash * f;
                            squash = -MiGlassNavMetrics.settleSquash *
                                MiGlassNavMetrics.settleSquashRatio *
                                f;
                            stretch += jelly;
                            squash += MiGlassNavMetrics.settleSquashRatio * jelly;
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
                              palette: palette,
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
                                  // 悬停：桌面上「能点」必须有暗示 —— 条目本身
                                  // 没有底色，叠一层 5.6% 实色的圆角块即可
                                  //（实色叠色，不是 Opacity，磨砂不受影响）。
                                  child: MiHoverFeedback(
                                    mode: widget.themeMode,
                                    borderRadius: BorderRadius.circular(
                                      MiGlassNavMetrics.itemHoverRadius,
                                    ),
                                    child: Opacity(
                                      // pressed tab content dims (measured ~55%)
                                      opacity: _pressedIndex == i
                                          ? MiGlassNavMetrics.pressDimOpacity
                                          : 1.0,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CustomPaint(
                                            painter: widget.items[i].painter,
                                            size: const Size(
                                              24,
                                              MiGlassNavMetrics.iconHeight,
                                            ),
                                          ),
                                          const SizedBox(
                                            height:
                                                MiGlassNavMetrics.iconLabelGap,
                                          ),
                                          Text(
                                            widget.items[i].label,
                                            style: labelStyle,
                                          ),
                                        ],
                                      ),
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
              );

          if (palette.elevationShadow.isNotEmpty) {
            glass = CustomPaint(
              painter: MiSquircleShadowPainter(
                radius: MiGlassNavMetrics.barHeight / 2,
                shadows: palette.elevationShadow,
              ),
              child: glass,
            );
          }

          final bar = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => _dragStart(cellW),
            onHorizontalDragUpdate: (d) => _dragUpdate(d.primaryDelta ?? 0, cellW),
            onHorizontalDragEnd: (_) => _dragEnd(),
            onHorizontalDragCancel: _dragCancel,
            child: Listener(
              onPointerDown: (e) => _pressDown(indexAt(e.localPosition.dx)),
              onPointerUp: (_) => _pressUp(),
              onPointerCancel: (_) => _pressUp(),
              child: glass,
            ),
          );

          // 预留空位圆钮：[栏体, 间隙, 圆钮] 行整体居中 —— 圆钮弹出时栏体
          // 中心左移 (fabDiameter+fabGap)/2，圆钮原位弹出（度量 cx 恒定）。
          final fab = widget.fab;
          const fabD = MiGlassNavMetrics.fabDiameter;
          const shiftDx = -(fabD + MiGlassNavMetrics.fabGap) / 2;
          final fabCx = screenW / 2 + (barW + MiGlassNavMetrics.fabGap) / 2;

          // 无 fab 时栏体原样铺设（不经过 Transform，保证像素零变化）
          final barHost = fab == null
              ? bar
              : AnimatedBuilder(
                  animation: _shiftCtrl,
                  child: bar,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      shiftDx * Curves.easeOutQuad.transform(_shiftCtrl.value),
                      0,
                    ),
                    child: child,
                  ),
                );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: screenW / 2 - barW / 2,
                top: 0,
                width: barW,
                height: MiGlassNavMetrics.barHeight,
                child: barHost,
              ),
              if (fab != null)
                Positioned(
                  left: fabCx - fabD / 2,
                  top: 0,
                  width: fabD,
                  height: fabD,
                  child: AnimatedBuilder(
                    animation: _fabCtrl,
                    builder: (context, _) {
                      // 显示：缩放+淡入（easeOutCubic）；收起：同曲线
                      // reverse 时间镜像，与视频度量剖面一致。
                      // IgnorePointer 必须**包在 GestureDetector 外面**：
                      // GestureDetector 自身 opaque，若它留在命中测试里，
                      // 收起后这块不可见区域仍会吞掉点击（侧栏同款隐患一并修复）。
                      final t = Curves.easeOutCubic.transform(_fabCtrl.value);
                      return IgnorePointer(
                        ignoring: t == 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: fab.onTap,
                          child: Opacity(
                            opacity: t,
                            child: Transform.scale(
                              scale: t,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: fab.color ??
                                      MiColors.fabGreenFor(widget.themeMode),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: fab.child,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
