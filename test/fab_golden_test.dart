import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// tests consume the public barrel only — if an export is missing it shows up
// right here
import 'package:mi_like_ui/mi_like_ui.dart';

// 3-tab layout (the reserved circular-button slot only supports ≤3 tabs)
List<MiGlassNavItem> items3() => [
      MiGlassNavItem(label: '首页', painter: RollerIconPainter(const Color(0xFFF5F5F5))),
      MiGlassNavItem(label: '分类', painter: GridSparkleIconPainter(const Color(0xFFF5F5F5))),
      MiGlassNavItem(label: '我的', painter: SmileyBeretIconPainter(const Color(0xFFF5F5F5))),
    ];

MiGlassNavFab demoFab({int tabIndex = 0}) => MiGlassNavFab(
      tabIndex: tabIndex,
      child: CustomPaint(
        painter: GridDotsIconPainter(const Color(0xFFFFFFFF)),
        size: const Size.square(18.2),
      ),
    );

Widget frame3(int selected, ValueChanged<int> onTap, {MiGlassNavFab? fab}) {
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
            child: MiGlassNavBar(
              items: items3(),
              selectedIndex: selected,
              onTap: onTap,
              fab: fab,
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('fab shown on its configured tab', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 160 * 3);
    addTearDown(tester.view.reset);

    // 首页（fab 配置 tab）选中：圆钮显示，栏体左移让出空位
    await tester.pumpWidget(frame3(0, (_) {}, fab: demoFab()));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(MiGlassNavBar), matchesGoldenFile('goldens/fab_shown.png'));
  });

  testWidgets('fab hidden on other tabs', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 160 * 3);
    addTearDown(tester.view.reset);

    // 分类选中：圆钮收起，栏体回中
    await tester.pumpWidget(frame3(1, (_) {}, fab: demoFab()));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(MiGlassNavBar), matchesGoldenFile('goldens/fab_hidden.png'));
  });

  testWidgets('fab pop-in + bar shift mid-animation', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 160 * 3);
    addTearDown(tester.view.reset);

    var selected = 1;
    await tester.pumpWidget(StatefulBuilder(
      builder: (context, setState) =>
          frame3(selected, (i) => setState(() => selected = i), fab: demoFab()),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    // 切回「首页」触发显示动画；60ms 时按钮缩放+淡入约 3/4、
    // 栏体位移约一半（easeOutCubic 165ms / easeOutQuad 205ms）
    await tester.tap(find.text('首页'));
    await tester.pump(); // rebuild: didUpdateWidget starts the controllers
    await tester.pump(const Duration(milliseconds: 60));
    await expectLater(find.byType(MiGlassNavBar), matchesGoldenFile('goldens/fab_pop_mid.png'));
    await tester.pumpAndSettle();
  });

  testWidgets('fab unsupported with more than 3 tabs', (tester) async {
    // items 数量校验在 initState 断言（const 构造断言不支持 .length 求值）
    final items = [
      for (var i = 0; i < 4; i++)
        MiGlassNavItem(label: 'tab$i', painter: RollerIconPainter(const Color(0xFFF5F5F5))),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiGlassNavBar(
            items: items,
            selectedIndex: 0,
            onTap: (_) {},
            fab: demoFab(),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('fab.tabIndex must be a valid tab', (tester) async {
    // 范围校验在 initState 断言（const 构造断言不支持参数字段访问）
    await tester.pumpWidget(frame3(0, (_) {}, fab: demoFab(tabIndex: 3)));
    expect(tester.takeException(), isA<AssertionError>());
  });
}
