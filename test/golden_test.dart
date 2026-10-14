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
}
