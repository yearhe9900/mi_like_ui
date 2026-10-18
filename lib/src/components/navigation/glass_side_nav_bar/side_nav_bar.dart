import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/glass_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../theme/typography.dart';
import '../../../utils/cell_grid.dart';
import '../../../utils/filter_cache.dart';
import '../glass_nav_bar/glass_nav_bar.dart' show MiGlassNavFab, MiGlassNavItem;
import '../glass_nav_bar/glass_nav_bar_metrics.dart';
import 'side_nav_bar_metrics.dart';
import 'side_nav_bar_painter.dart';

/// 小米主题商店风格的玻璃悬浮**侧边**导航栏（桌面模式的底部栏替身）。
///
/// 与 [MiGlassNavBar] 是**同一套导航语义的另一种布局**：
///  * 条目类型同为 [MiGlassNavItem]（标签 + 任意图标 painter）——调用方传
///    同一份 items，图标与标签一字不改；
///  * 选中态同为零位移之外的**胶囊透镜**（不另改图标/标签颜色）；
///  * `onTap(index)` 回调与底部栏完全相同，路由跳转行为不变；
///  * 选中胶囊的飞行 / 弹性沉降 / 按压缩圈 / 拖拽跟手全部复用
///    [MiGlassNavMetrics]（曲线与时长逐帧同源），只把**轴换成纵向**：
///    飞行方向由 x 变 y，果冻形变由「宽拉伸 + 高压缩」变「高拉伸 + 宽压缩」。
///
/// ## 什么时候用它
///
/// 画面容器宽达到导航断点（`MiBreakpoints.usesSideNav`，**> 600**）时取代
/// 底部栏；手机 / 窄窗仍用 [MiGlassNavBar]。两者**不要同时显示**。
/// 切换是整棵子树替换（不做淡入淡出）：`Opacity` / `FadeTransition` 会给
/// 含 `BackdropFilter` 的子树引入 saveLayer，磨砂会在切换期间直接消失
/// （本项目已实测的坑）。
///
/// ## 与底部栏的两处刻意差异
///
///  1. **圆钮（[fab]）挂在栏尾下方、栏体不让位**：底部栏的「栏体平移让位」
///     是为横向一排 tab 的居中腾挪设计的；侧栏锚定左上、栏体不动，圆钮
///     纵向排在栏体下方（间距 [MiGlassSideNavMetrics.fabGap]、直径
///     [MiGlassSideNavMetrics.fabDiameter]，均沿用底部栏实测）。显隐契约
///     与底部栏完全一致：选中 [MiGlassNavFab.tabIndex] 对应条目时缩放+
///     淡入弹出（同一 [MiGlassNavMetrics.fabPopMs] / easeOutCubic 曲线），
///     切走收起。槽位**恒定预留**（收起不改组件高度，无布局跳动）。
///  2. **栏体竖向收缩到内容高**（[MiGlassSideNavMetrics.railHeightFor]），
///     摆放位置由宿主决定（示例贴顶 + 距左缘 [MiGlassSideNavMetrics.railMargin]
///     一档留白）—— 对应底部栏「栏宽 = 内容宽、位置由宿主给」的同构做法。
///
/// 玻璃材质配方与底部栏同源（[MiGlassPalette] + [MiTransparencyTokens]），
/// 整条栏只挂**一个** `BackdropFilter`（每帧全 QUAD 高斯，层数预算见
/// `test/perf_budget_test.dart`）。图标颜色由调用方传入 painter，需与
/// [MiColors.foregroundFor] 保持一致。
///
/// **高度随条目数线性增长**（`2×内边距 + n×条目高 + (n−1)×间隙`，见
/// [MiGlassSideNavMetrics.railHeightFor]）：条目多到放不下时应由宿主给滚动
/// 容器，本组件不做内部滚动（底部栏同样按内容宽直接铺开）。
class MiGlassSideNavBar extends StatefulWidget {
  const MiGlassSideNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.fab,
    this.themeMode = MiThemeMode.dark,
  });
  // items 数量、fab 适配与 fab.tabIndex 范围校验均在 initState：const 构造
  // 断言不支持 `.length` / 参数字段求值（放构造器会封死 const 构造，
  // 同 MiGlassNavBar）。

  /// 导航条目（与底部栏共用 [MiGlassNavItem]，调用方传同一份即可）。
  final List<MiGlassNavItem> items;

  /// 选中条目下标。
  final int selectedIndex;

  /// 点按 / 拖拽选中的回调（与底部栏语义一致：只报目标下标，不改自身状态）。
  final ValueChanged<int> onTap;

  /// 预留空位圆形按钮（与底部栏同款绿色圆钮）；null = 不启用。
  ///
  /// 选中 [MiGlassNavFab.tabIndex] 对应条目时在**栏尾下方**弹出，
  /// 切走收起；显隐动画曲线与时长与底部栏逐帧同源。
  final MiGlassNavFab? fab;

  /// 明暗模式：决定玻璃材质配方与标签墨色（默认深色）。
  final MiThemeMode themeMode;

  @override
  State<MiGlassSideNavBar> createState() => _MiGlassSideNavBarState();
}

class _MiGlassSideNavBarState extends State<MiGlassSideNavBar>
    with TickerProviderStateMixin {
  /// 飞行 + 沉降控制器（0…1 覆盖整段：先飞后弹）。
  late final AnimationController _ctrl;

  /// 按压缩圈控制器。
  late final AnimationController _pressCtrl;

  /// 拖拽残留果冻的淡出控制器。
  late final AnimationController _stretchCtrl;

  /// 圆钮显隐（缩放 + 淡入）控制器。
  late final AnimationController _fabCtrl;

  double _from = 0;
  double _to = 0;
  double _travelCells = 0;

  /// 手指拖拽中的连续格位（null = 空闲）。
  double? _dragPos;

  /// 拖拽果冻当前显示值与其补间起点（与底部栏同一套「绝不在单帧归零」的
  /// 处理，避免慢速拖拽时的宽度突跳）。
  double _stretchFrom = 0;
  Timer? _stretchDecay;

  /// 正在被按下的条目（图标+标签瞬时变暗）。
  int? _pressedIndex;

  double get _railHeight => MiGlassSideNavMetrics.railHeightFor(widget.items.length);

  /// 圆钮是否应显示（fab 配置的条目被选中）——与底部栏同一契约。
  bool get _showFab => widget.fab != null && widget.selectedIndex == widget.fab!.tabIndex;

  @override
  void initState() {
    super.initState();
    final fab = widget.fab;
    assert(widget.items.isNotEmpty, 'items 不能为空');
    assert(
      widget.selectedIndex >= 0 && widget.selectedIndex < widget.items.length,
      'selectedIndex 必须落在 items 范围内',
    );
    assert(
      fab == null || widget.items.length <= 3,
      '预留空位圆形按钮仅支持 3 个及以下 tab',
    );
    assert(
      fab == null || (fab.tabIndex >= 0 && fab.tabIndex < widget.items.length),
      'fab.tabIndex 必须落在 items 范围内',
    );
    _from = _to = widget.selectedIndex.toDouble();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: MiGlassNavMetrics.pressMs),
    );
    _stretchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: MiGlassNavMetrics.dragStretchDecayMs),
    );
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: MiGlassNavMetrics.fabPopMs),
    );
    // 首帧即处于稳态（配置的条目已选中则直接显示，无入场动画）
    _fabCtrl.value = _showFab ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant MiGlassSideNavBar old) {
    super.didUpdateWidget(old);
    final wasShown = old.fab != null && old.selectedIndex == old.fab!.tabIndex;
    if (wasShown != _showFab) {
      // 显示：缩放+淡入弹出；收起：同曲线 reverse 时间镜像（与底部栏一致）。
      if (_showFab) {
        _fabCtrl.forward();
      } else {
        _fabCtrl.reverse();
      }
    }
    if (old.selectedIndex != widget.selectedIndex) {
      // 从胶囊当前位置起飞：快速连点可以中途改道而不跳变（同底部栏）。
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

  /// 飞行段占控制器时长的比例（其余是沉降尾段）。
  double get _flightFraction {
    final flightMs =
        MiGlassNavMetrics.flightBaseMs + MiGlassNavMetrics.flightPerCellMs * _travelCells;
    return flightMs / (flightMs + MiGlassNavMetrics.settleMs);
  }

  /// 控制器值 [t] 处的胶囊中心（格位单位，0..n-1），含沉降段的过冲回弹。
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

  double get _liveStretch =>
      _stretchFrom * (1 - Curves.easeOutCubic.transform(_stretchCtrl.value));

  void _pressDown(int index) {
    setState(() => _pressedIndex = index);
    _pressCtrl.forward();
  }

  void _pressUp() {
    setState(() => _pressedIndex = null);
    _pressCtrl.reverse();
  }

  /// 从当前显示值开始淡出果冻（不重置、不跳变）。
  void _bleedStretch() {
    final live = _liveStretch;
    if (live <= 0) return;
    _stretchFrom = live;
    _stretchCtrl.forward(from: 0);
  }

  void _dragStart() => _dragPos = _currentPos;

  void _dragUpdate(double dy) {
    final n = widget.items.length;
    const pitch = MiGlassSideNavMetrics.pitch;
    final pos = (_dragPos! + dy / pitch).clamp(0.0, n - 1.0);
    _dragPos = pos;
    // 速度果冻：随每次移动增量增长，手指停顿后衰减。
    final live = _liveStretch;
    _stretchCtrl.stop();
    _stretchCtrl.value = 0;
    _stretchFrom =
        (live + (dy.abs() / pitch) * 0.6).clamp(0.0, MiGlassNavMetrics.dragStretchMax);
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
    _bleedStretch(); // 残留果冻在吸附飞行中淡出
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
    // 纯点击也会触发（拖拽识别器输掉竞技场但从未开始）—— 没有真实拖拽就退出
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
    _fabCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MiGlassPalette.of(widget.themeMode);
    final labelStyle = MiTypography.navLabelFor(widget.themeMode);
    final n = widget.items.length;
    final h = _railHeight;
    const railW = MiGlassSideNavMetrics.railWidth;

    // 整条栏只糊一次：胶囊透镜与遮罩都画在这一层之上（同底部栏）。
    Widget glass = ClipRRect(
      borderRadius: BorderRadius.circular(MiGlassSideNavMetrics.railRadius),
      child: BackdropFilter(
        // σ 固定 → 复用缓存的 native filter
        filter: MiFilterCache.blur(MiTransparencyTokens.blurSigma),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 模糊只给这层透明底色染上背景；下面的内容叠在它之上。
            const SizedBox.expand(),
            AnimatedBuilder(
              animation: Listenable.merge([_ctrl, _pressCtrl, _stretchCtrl]),
              builder: (context, _) {
                final t = _ctrl.value;
                final ff = _flightFraction;
                final jelly = _liveStretch;
                // 纵向形态：长轴是高度（飞行时拉伸、按压时压缩），
                // 短轴是宽度（反向形变，比例与底部栏同一套参数）。
                double stretch;
                double squash;
                if (_dragPos != null) {
                  stretch = jelly;
                  squash = MiGlassNavMetrics.settleSquashRatio * jelly;
                } else if (t <= ff) {
                  final p = t / ff;
                  final bell = math.sin(math.pi * math.pow(p, 0.8).toDouble());
                  final distF =
                      (_travelCells / MiGlassNavMetrics.maxJellyCells).clamp(0.0, 1.0);
                  stretch = MiGlassNavMetrics.jellyStretch * distF * bell;
                  squash = MiGlassNavMetrics.jellySquash * distF * bell;
                  stretch += jelly;
                  squash += MiGlassNavMetrics.settleSquashRatio * jelly;
                } else {
                  final f = MiGlassNavMetrics.settleWave((t - ff) / (1 - ff));
                  stretch = -MiGlassNavMetrics.settleSquash * f;
                  squash =
                      -MiGlassNavMetrics.settleSquash * MiGlassNavMetrics.settleSquashRatio * f;
                  stretch += jelly;
                  squash += MiGlassNavMetrics.settleSquashRatio * jelly;
                }

                // 按压缩圈（长轴 -3% / 短轴 -7.5%，与底部栏的角色映射一致）
                final press = _pressCtrl.value;
                stretch -= MiGlassNavMetrics.pressSquashW * press;
                squash += MiGlassNavMetrics.pressSquashH * press;

                var ph = MiGlassSideNavMetrics.itemHeight * (1 + stretch);
                final pw = MiGlassSideNavMetrics.itemWidth * (1 - squash);
                // 条目 i 的胶囊中心 = 内边距 + 半个条目高 + i × 步进：
                // 半条目高是「首条目中心」的偏移，步进里含间隙，故不能直接用
                // pitch × (pos + 0.5)（那样会整体下移半个间隙 = 4dp）。
                var cy = MiGlassSideNavMetrics.railInnerPad +
                    MiGlassSideNavMetrics.itemHeight / 2 +
                    MiGlassSideNavMetrics.pitch * (_dragPos ?? _posAt(t));

                // 落到首尾条目时，果冻拉伸会顶到栏体内边距：裁到边界上，
                // 表现为高度压缩（与底部栏首尾宽度压缩同一处理）。
                const minTop = MiGlassSideNavMetrics.railInnerPad;
                final maxBottom = h - MiGlassSideNavMetrics.railInnerPad;
                var top = cy - ph / 2;
                var bottom = cy + ph / 2;
                if (top < minTop) top = minTop;
                if (bottom > maxBottom) bottom = maxBottom;
                ph = bottom - top;
                cy = (top + bottom) / 2;

                return CustomPaint(
                  painter: SideNavPainter(
                    pillCenterY: cy,
                    pillWidth: pw,
                    pillHeight: ph,
                    palette: palette,
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: MiGlassSideNavMetrics.railInnerPad,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < n; i++) ...[
                    if (i > 0)
                      const SizedBox(height: MiGlassSideNavMetrics.itemGap),
                    SizedBox(
                      height: MiGlassSideNavMetrics.itemHeight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onTap(i),
                        child: Opacity(
                          // 按下条目内容变暗（实测 ~55%）
                          opacity: _pressedIndex == i
                              ? MiGlassNavMetrics.pressDimOpacity
                              : 1.0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomPaint(
                                painter: widget.items[i].painter,
                                size: const Size(
                                  MiGlassSideNavMetrics.iconSize,
                                  MiGlassSideNavMetrics.iconHeight,
                                ),
                              ),
                              const SizedBox(
                                height: MiGlassSideNavMetrics.iconLabelGap,
                              ),
                              Text(widget.items[i].label, style: labelStyle),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // 浅色配方带投影（深色为空 → 不包额外层，像素零变化）。
    if (palette.elevationShadow.isNotEmpty) {
      glass = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MiGlassSideNavMetrics.railRadius),
          boxShadow: palette.elevationShadow,
        ),
        child: glass,
      );
    }

    final rail = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => _dragStart(),
      onVerticalDragUpdate: (d) => _dragUpdate(d.primaryDelta ?? 0),
      onVerticalDragEnd: (_) => _dragEnd(),
      onVerticalDragCancel: _dragCancel,
      child: Listener(
        onPointerDown: (e) => _pressDown(
          cellIndexAt(
            dx: e.localPosition.dy,
            leadingInset: MiGlassSideNavMetrics.railInnerPad,
            cellWidth: MiGlassSideNavMetrics.pitch,
            count: n,
          ),
        ),
        onPointerUp: (_) => _pressUp(),
        onPointerCancel: (_) => _pressUp(),
        child: glass,
      ),
    );

    // 无圆钮：原样返回栏体（与旧版逐像素一致，不经过 Stack 包裹）
    final fab = widget.fab;
    if (fab == null) {
      return SizedBox(width: railW, height: h, child: rail);
    }

    // 预留空位圆钮：**挂在栏尾下方**、水平居中于栏体 —— 侧栏锚定左上，
    // 没有底部栏「整组居中」的让位语义，故栏体不动、只在下方恒定预留
    // 一个圆钮槽位（收起时 Opacity 0，显隐不产生任何布局跳动）。
    // 槽位在组件高度内（不是 Stack 溢出）：溢出到 SizedBox 外的区域
    // hitTest 会被外层 `size.contains` 拦掉，圆钮将点不动。
    const fabD = MiGlassSideNavMetrics.fabDiameter;
    return SizedBox(
      width: railW,
      height: h + MiGlassSideNavMetrics.fabGap + fabD,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: railW,
            height: h,
            child: rail,
          ),
          Positioned(
            left: (railW - fabD) / 2,
            top: h + MiGlassSideNavMetrics.fabGap,
            width: fabD,
            height: fabD,
            child: AnimatedBuilder(
              animation: _fabCtrl,
              builder: (context, _) {
                // 显示：缩放+淡入（easeOutCubic）；收起：同曲线 reverse
                // 时间镜像 —— 与底部栏圆钮逐帧同源。
                // IgnorePointer 必须**包在 GestureDetector 外面**：
                // GestureDetector 自身 opaque，若它留在命中测试里，
                // 收起后这块不可见区域仍会吞掉点击（2026-10-18 测试暴露）。
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
                            color: fab.color ?? MiColors.fabGreenFor(widget.themeMode),
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
      ),
    );
  }
}
