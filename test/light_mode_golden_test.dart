import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；demo 层测试直接引示例代码。
import 'package:mi_like_ui/mi_like_ui.dart';

import 'package:mi_like_ui/demo/demo_app.dart';

// 亮色参考截图的三种典型背景（881×1920 实测色）：暗卡 / 灰白照片卡 / 蓝卡，
// 页面底色 #F7F7F7（新参考图平坦底色实测）—— 玻璃透射差异靠这些背景读出来。
Widget lightBackdrop() {
  return Container(
    color: const Color(0xFFF7F7F7),
    padding: const EdgeInsets.fromLTRB(20, 120, 20, 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: Container(color: const Color(0xFF3C3C40))),
        const SizedBox(width: 12),
        Expanded(child: Container(color: const Color(0xFFB9C2CC))),
        const SizedBox(width: 12),
        Expanded(child: Container(color: const Color(0xFF6E8FE0))),
      ],
    ),
  );
}

List<MiGlassNavItem> itemsInk(Color ink) => [
      MiGlassNavItem(label: '首页', painter: RollerIconPainter(ink)),
      MiGlassNavItem(label: '分类', painter: GridSparkleIconPainter(ink)),
      MiGlassNavItem(label: '我的', painter: SmileyBeretIconPainter(ink)),
    ];

Widget lightFrame(int selected, {MiGlassNavFab? fab}) {
  final ink = MiColors.foregroundFor(MiThemeMode.light);
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: lightBackdrop()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24.2,
            child: MiGlassNavBar(
              items: itemsInk(ink),
              selectedIndex: selected,
              onTap: (_) {},
              themeMode: MiThemeMode.light,
              fab: fab,
            ),
          ),
        ],
      ),
    ),
  );
}

MiGlassNavFab lightFab() => MiGlassNavFab(
      tabIndex: 0,
      child: CustomPaint(
        painter: GridDotsIconPainter(const Color(0xFFFFFFFF)),
        size: const Size.square(18.2),
      ),
    );

void main() {
  testWidgets('light bar renders with the light palette (fab shown)', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 160 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(lightFrame(0, fab: lightFab()));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(MiGlassNavBar), matchesGoldenFile('goldens/light_bar_home.png'));
  });

  testWidgets('light bar on another tab (fab hidden)', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 160 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(lightFrame(2, fab: lightFab()));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(MiGlassNavBar), matchesGoldenFile('goldens/light_bar_mine.png'));
  });

  testWidgets('demo mode switch in 我的 page flips the whole frame', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(520, 940);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();

    // 初始深色：手机框 Scaffold 底色 #08080A
    var scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFF08080A));
    expect(
      tester.widget<MiGlassNavBar>(find.byType(MiGlassNavBar)).themeMode,
      MiThemeMode.dark,
    );

    // 进「我的」页，模式切换入口在页面顶部
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // 切到浅色：底色与导航栏配方整体翻转
    scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFFFAFAFA));
    expect(
      tester.widget<MiGlassNavBar>(find.byType(MiGlassNavBar)).themeMode,
      MiThemeMode.light,
    );

    // 再切回深色
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFF08080A));
  });

  testWidgets('demo light mode golden on 我的 page', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    // 参考机逻辑尺寸（393×856）：示例外壳在 compact 档按 1:1 铺满，
    // 黄金图即完整手机画面（不再是被窗口裁掉一半的 260×470）。
    tester.view.physicalSize = const Size(393 * 2, 856 * 2);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await expectLater(find.byType(DemoHome), matchesGoldenFile('goldens/demo_light_mine.png'));
  });
}
