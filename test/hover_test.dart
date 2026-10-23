import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_like_ui/mi_like_ui.dart';

/// 指针悬停回归（桌面语义）。
///
/// 判据约定：
///  * **默认零像素变化**：未悬停时叠色是全透明 —— 结构恒定（不是"不挂子树"），
///    所以黄金图与触屏行为都不受影响；
///  * **悬停可读**：进入后叠色 = `MiTransparencyTokens.hoverOverlayFor(mode)`
///    （亮 = 黑 @5.6%、暗 = 白 @5.6%），移出复原；
///  * **不引入 saveLayer**：叠色必须是实色 `AnimatedContainer`，子树里不允许
///    出现 `Opacity` / `FadeTransition`（那会让下层磨砂的 backdrop 变空）。
void main() {
  /// 让鼠标进入 / 离开某个组件，并把 150ms 淡入淡出走完。
  Future<TestGesture> hover(
    WidgetTester tester,
    Finder target, {
    bool enter = true,
  }) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(
      enter ? tester.getCenter(target) : const Offset(-40, -40),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    return mouse;
  }

  /// 手型光标所在的 MouseRegion（悬停可点的唯一标志）。
  Finder clickCursor() => find.byWidgetPredicate(
        (w) => w is MouseRegion && w.cursor == SystemMouseCursors.click,
      );

  Color overlayColor(WidgetTester tester) {
    final overlay = tester.widget<AnimatedContainer>(
      find.byKey(MiHoverFeedback.overlayKey).first,
    );
    final decoration = overlay.decoration! as BoxDecoration;
    return decoration.color!;
  }

  Widget card({VoidCallback? onTap, MiThemeMode mode = MiThemeMode.dark}) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox(
            width: 200,
            child: MiThemeCard(
              title: '雾林晨光',
              themeMode: mode,
              onTap: onTap,
              preview: const ColoredBox(color: Color(0xFF6A7A61)),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('未悬停时叠色全透明（结构与像素都不变）', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(card(onTap: () {}));
    // 叠色层始终存在，只是全透明
    expect(find.byKey(MiHoverFeedback.overlayKey), findsOneWidget);
    expect(overlayColor(tester), Colors.transparent);
    // 磨砂子树里不许有 saveLayer 来源
    expect(
      find.descendant(
        of: find.byType(MiThemeCard),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });

  testWidgets('悬停：暗色叠白 5.6%，移出复原', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(card(onTap: () {}));
    final mouse = await hover(tester, find.byType(MiThemeCard));
    expect(
      overlayColor(tester),
      MiTransparencyTokens.hoverOverlayFor(MiThemeMode.dark),
    );
    expect(overlayColor(tester).a, closeTo(0.056, 0.01));

    // 移出
    await mouse.moveTo(const Offset(-40, -40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(overlayColor(tester), Colors.transparent);
  });

  testWidgets('亮色叠黑（方向与按压同源）', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(card(onTap: () {}, mode: MiThemeMode.light));
    await hover(tester, find.byType(MiThemeCard));
    expect(
      overlayColor(tester),
      MiTransparencyTokens.hoverOverlayFor(MiThemeMode.light),
    );
  });

  testWidgets('不可点时没有悬停层（onTap == null → 直接返回原卡片）', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(card());
    expect(find.byKey(MiHoverFeedback.overlayKey), findsNothing);
    expect(find.byType(MiHoverFeedback), findsNothing);
  });

  testWidgets('按钮：可点有悬停、禁用无悬停', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 200);
    addTearDown(tester.view.reset);

    Widget button({VoidCallback? onPressed}) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: MiButton(
                label: '关注',
                onPressed: onPressed,
                themeMode: MiThemeMode.dark,
              ),
            ),
          ),
        );

    await tester.pumpWidget(button(onPressed: () {}));
    await hover(tester, find.byType(MiButton));
    expect(
      overlayColor(tester),
      MiTransparencyTokens.hoverOverlayFor(MiThemeMode.dark),
    );

    // 禁用态：不挂悬停层（也就没有手型光标与叠色）
    await tester.pumpWidget(button());
    await tester.pumpAndSettle();
    expect(find.byKey(MiHoverFeedback.overlayKey), findsNothing);
    // 也没有手型光标（enabled: false 时不挂 MouseRegion）
    expect(clickCursor(), findsNothing);
  });

  testWidgets('胶囊行：未选中胶囊有悬停，选中胶囊没有', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 200);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MiPillTabBar(
              labels: const ['推荐', '背屏', '小部件'],
              selectedIndex: 0,
              onTap: (_) {},
              themeMode: MiThemeMode.dark,
            ),
          ),
        ),
      ),
    );

    // 3 个胶囊里只有 2 个未选中挂了悬停层
    expect(find.byKey(MiHoverFeedback.overlayKey), findsNWidgets(2));
  });
}
