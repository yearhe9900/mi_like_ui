import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_like_ui/mi_like_ui.dart';
// 白盒回归测试：故意深入内部 painter 读取胶囊几何（未从 barrel 导出）。
// 目标是锁住"拖拽果冻拉伸的衰减必须平滑"这一行为 —— 早期实现用
// Timer 到期单帧归零，慢拖停顿时胶囊宽度一次掉 ~5dp，肉眼可见跳动。
import 'package:mi_like_ui/src/components/navigation/glass_nav_bar/glass_nav_bar_painter.dart';

List<MiGlassNavItem> items() => [
      MiGlassNavItem(label: '首页', painter: RollerIconPainter(const Color(0xFFF5F5F5))),
      MiGlassNavItem(label: '分类', painter: GridSparkleIconPainter(const Color(0xFFF5F5F5))),
      MiGlassNavItem(label: '每日精选', painter: CardsStarIconPainter(const Color(0xFFF5F5F5))),
      MiGlassNavItem(label: '我的', painter: SmileyBeretIconPainter(const Color(0xFFF5F5F5))),
    ];

Widget frame(int selected, ValueChanged<int> onTap) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2E3A8C), Color(0xFFD06A8A), Color(0xFF111114)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24.2,
            child: MiGlassNavBar(items: items(), selectedIndex: selected, onTap: onTap),
          ),
        ],
      ),
    ),
  );
}

/// 当前帧胶囊宽度（逻辑 px），从 [GlassBarPainter] 直接读取。
double pillWidth(WidgetTester tester) {
  for (final w in tester.widgetList<CustomPaint>(find.byType(CustomPaint))) {
    if (w.painter is GlassBarPainter) return (w.painter as GlassBarPainter).pillWidth;
  }
  throw StateError('GlassBarPainter not found');
}

void main() {
  testWidgets('pause mid-drag: jelly bleeds off smoothly, no single-frame pop', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 160 * 3);
    addTearDown(tester.view.reset);

    var selected = 0;
    await tester.pumpWidget(StatefulBuilder(
      builder: (context, setState) => frame(selected, (i) => setState(() => selected = i)),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    final c0 = tester.getCenter(find.text('首页'));
    final c2 = tester.getCenter(find.text('每日精选'));
    // 与黄金图拖拽测试同路径：两格 + 18px slop，小步拆分保证吸附目标确定
    final dx = c2.dx - c0.dx + 18.0;
    final gesture = await tester.startGesture(c0);
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(Offset(dx / 12, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }

    // 手指停住不动：80ms hold 后果冻应在 ~180ms 内平滑衰减
    final widths = <double>[];
    for (var i = 0; i < 26; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      widths.add(pillWidth(tester));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    // 停顿前拉伸应存在（衰减有东西可衰）
    final drop = widths.first - widths.last;
    expect(drop, greaterThan(3.5), reason: '果冻拉伸应先存在再衰减，实际首尾差 $drop');
    expect(drop, lessThan(6.5), reason: '衰减总量应约等于 dragStretchMax·pillW，实际 $drop');

    // 核心断言：任何单帧宽度变化不得突跳（旧实现单帧掉 ~5dp）
    for (var i = 1; i < widths.length; i++) {
      final step = (widths[i] - widths[i - 1]).abs();
      expect(
        step,
        lessThanOrEqualTo(2.0),
        reason: '第 $i 帧宽度突变 $step dp（帧值 ${widths[i - 1]} -> ${widths[i]}）',
      );
    }
    // 平滑衰减还应单调不增（容差 0.05 吸收浮点噪声）
    for (var i = 1; i < widths.length; i++) {
      expect(
        widths[i],
        lessThanOrEqualTo(widths[i - 1] + 0.05),
        reason: '第 $i 帧宽度回弹：${widths[i - 1]} -> ${widths[i]}',
      );
    }
  });

  testWidgets('release mid-drag: residual jelly carries into the snap without a pop', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 160 * 3);
    addTearDown(tester.view.reset);

    var selected = 0;
    await tester.pumpWidget(StatefulBuilder(
      builder: (context, setState) => frame(selected, (i) => setState(() => selected = i)),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    final c0 = tester.getCenter(find.text('首页'));
    final c2 = tester.getCenter(find.text('每日精选'));
    final dx = c2.dx - c0.dx + 18.0;
    final gesture = await tester.startGesture(c0);
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(Offset(dx / 12, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final beforeUp = pillWidth(tester);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 16));
    final afterUp = pillWidth(tester);
    await tester.pumpAndSettle();

    // 松手瞬间不得把残余果冻一次打掉（旧实现 -5dp 弹跳）；飞行果冻/
    // 按压释放本身的缓动在首帧贡献很小，2dp 足以分开两者
    expect(
      (afterUp - beforeUp).abs(),
      lessThanOrEqualTo(2.0),
      reason: '松手首帧宽度跳变 ${afterUp - beforeUp} dp（$beforeUp -> $afterUp）',
    );
    expect(selected, 2, reason: 'release over 每日精选 must select tab 2');
  });
}
