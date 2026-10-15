import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bottom_nav_demo/glass_nav_bar.dart';
import 'package:bottom_nav_demo/nav_bar_icons.dart';

List<GlassNavItem> items() => [
      GlassNavItem(label: '首页', painter: RollerIconPainter(const Color(0xFFF5F5F5))),
      GlassNavItem(label: '分类', painter: GridSparkleIconPainter(const Color(0xFFF5F5F5))),
      GlassNavItem(label: '每日精选', painter: CardsStarIconPainter(const Color(0xFFF5F5F5))),
      GlassNavItem(label: '我的', painter: SmileyBeretIconPainter(const Color(0xFFF5F5F5))),
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
            child: GlassNavBar(items: items(), selectedIndex: selected, onTap: onTap),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('settled pill on tab1', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 160 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(frame(0, (_) {}));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(GlassNavBar), matchesGoldenFile('goldens/settled_tab1.png'));
  });

  testWidgets('settled pill on tab4', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 160 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(frame(3, (_) {}));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(GlassNavBar), matchesGoldenFile('goldens/settled_tab4.png'));
  });

  testWidgets('mid-flight jelly stretch', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 160 * 3);
    addTearDown(tester.view.reset);

    var selected = 0;
    await tester.pumpWidget(StatefulBuilder(
      builder: (context, setState) => frame(selected, (i) => setState(() => selected = i)),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    // tap tab4 (3 cells away) and capture mid-flight
    await tester.tap(find.text('我的'));
    expect(selected, 3, reason: 'tap should have hit the 我的 tab');
    await tester.pump(); // rebuild: didUpdateWidget starts the controller ticker
    await tester.pump(const Duration(milliseconds: 110)); // advance clock -> t≈0.34 (peak jelly)
    await expectLater(find.byType(GlassNavBar), matchesGoldenFile('goldens/midflight.png'));
    await tester.pumpAndSettle();
  });

  testWidgets('press squeeze + dim on tab1', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 160 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(frame(0, (_) {}));
    await tester.pump(const Duration(milliseconds: 400));

    final gesture = await tester.startGesture(tester.getCenter(find.text('首页')));
    // press easing runs 90 ms; by 200 ms the squeeze is fully applied:
    // pill -3% width / -7.5% height, pressed tab content dimmed to 55%
    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(find.byType(GlassNavBar), matchesGoldenFile('goldens/press_tab1.png'));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('drag follows finger and snaps to nearest tab', (tester) async {
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
    // travel two cells + the ~18 px drag slop the recognizer eats before it
    // accepts; split into small steps so the dropped pending delta can never
    // change which tab we snap to (delivered pos stays in 1.5..2.5 cells)
    final dx = c2.dx - c0.dx + 18.0;
    final gesture = await tester.startGesture(c0);
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(Offset(dx / 12, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await expectLater(find.byType(GlassNavBar), matchesGoldenFile('goldens/drag_mid.png'));
    await gesture.up();
    expect(selected, 2, reason: 'release over 每日精选 must select tab 2');
    await tester.pumpAndSettle(); // snap flight + settle tail
  });
}
