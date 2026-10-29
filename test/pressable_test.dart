import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_like_ui/mi_like_ui.dart';

/// `MiPressable` 契约测试（统一反馈包装件）。
///
/// 判据约定：
///  * **按压状态机**：按下 → pressed、抬起 / 取消 → 复原；`pressBuilder`
///    恒定调用（结构恒定 —— 静止态黄金图零变化的前提）；
///  * **禁用**（onPressed == null）：不进按压态、回调不触发；手势层仍挂
///    （吸收命中不响应）；
///  * **悬停**：默认挂叠色层 + 手型光标（复用 `MiHoverFeedback`），
///    `hover: false` 关闭、禁用自动失效；
///  * **焦点**：默认挂焦点环 + Enter / Space 激活（复用 `MiFocusRing`），
///    `focus: false` 关闭、禁用不参与焦点。
void main() {
  void setWindow(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
  }

  // 压色指示：pressBuilder 按 pressed 换底色，测试读它断言状态机。
  const targetKey = Key('pb-target');
  const indicatorKey = Key('pb-indicator');
  const idle = Color(0xFF00FF00);
  const down = Color(0xFFFF0000);

  Color indicatorColor(WidgetTester tester) =>
      tester.widget<ColoredBox>(find.byKey(indicatorKey)).color;

  Finder target() => find.byKey(targetKey);

  Widget harness({
    VoidCallback? onPressed,
    bool withIndicator = false,
    bool hover = true,
    bool focus = true,
    MiThemeMode mode = MiThemeMode.dark,
    ValueChanged<bool>? onHoverChanged,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MiPressable(
              onPressed: onPressed,
              pressBuilder: withIndicator
                  ? (context, pressed, child) => ColoredBox(
                        key: indicatorKey,
                        color: pressed ? down : idle,
                        child: child,
                      )
                  : null,
              hover: hover,
              focus: focus,
              mode: mode,
              onHoverChanged: onHoverChanged,
              child: const SizedBox(key: targetKey, width: 80, height: 40),
            ),
          ),
        ),
      );

  /// 焦点环当前描边色（未聚焦 = 全透明），口径同 `keyboard_test`。
  Color ringColor(WidgetTester tester) {
    final ring = tester.widget<AnimatedContainer>(
      find.byKey(MiFocusRing.ringKey).first,
    );
    final border = (ring.decoration! as BoxDecoration).border! as Border;
    return border.top.color;
  }

  group('按压状态机', () {
    testWidgets('按下进按压态、抬起复原；tap 触发一次回调', (tester) async {
      setWindow(tester, const Size(400, 300));
      addTearDown(tester.view.reset);

      var taps = 0;
      await tester.pumpWidget(
        harness(onPressed: () => taps++, withIndicator: true),
      );
      expect(indicatorColor(tester), idle, reason: '静止态 = 未按压');

      final gesture = await tester.startGesture(tester.getCenter(target()));
      await tester.pump();
      expect(indicatorColor(tester), down, reason: '按下应进按压态');

      await gesture.up();
      await tester.pump();
      expect(indicatorColor(tester), idle, reason: '抬起应回到未按压');
      expect(taps, 1);
    });

    testWidgets('取消（gesture.cancel）复原且不触发回调', (tester) async {
      setWindow(tester, const Size(400, 300));
      addTearDown(tester.view.reset);

      var taps = 0;
      await tester.pumpWidget(
        harness(onPressed: () => taps++, withIndicator: true),
      );

      final gesture = await tester.startGesture(tester.getCenter(target()));
      await tester.pump();
      expect(indicatorColor(tester), down);

      await gesture.cancel();
      await tester.pump();
      expect(indicatorColor(tester), idle, reason: '取消应复原');
      expect(taps, 0, reason: '取消不应触发回调');
    });

    testWidgets('禁用：不进按压态、回调不触发；pressBuilder 仍恒定调用', (tester) async {
      setWindow(tester, const Size(400, 300));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(onPressed: null, withIndicator: true));
      // 结构恒定：禁用时 builder 仍被调用（pressed 恒 false），指示层可找到。
      expect(find.byKey(indicatorKey), findsOneWidget);
      expect(indicatorColor(tester), idle);

      final gesture = await tester.startGesture(tester.getCenter(target()));
      await tester.pump();
      expect(indicatorColor(tester), idle, reason: '禁用不进按压态');
      await gesture.up();
      await tester.pumpAndSettle();
      expect(indicatorColor(tester), idle);
    });
  });

  group('悬停反馈', () {
    testWidgets('默认开启：悬停叠色 + 手型光标 + onHoverChanged，离开复原', (tester) async {
      setWindow(tester, const Size(400, 300));
      addTearDown(tester.view.reset);

      final hovered = <bool>[];
      await tester.pumpWidget(
        harness(onPressed: () {}, onHoverChanged: hovered.add),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(target()));
      await tester.pump();

      final overlay = tester.widget<AnimatedContainer>(
        find.byKey(MiHoverFeedback.overlayKey).first,
      );
      expect(
        (overlay.decoration! as BoxDecoration).color,
        MiTransparencyTokens.hoverOverlayFor(MiThemeMode.dark),
        reason: '悬停叠色 = 按压高光的 60%（桌面推导语义）',
      );
      expect(hovered, [true]);

      // 限定在包装件子树内 —— 应用外壳自己还有一个 MouseRegion（basic 光标）。
      final mouse = tester.widget<MouseRegion>(
        find
            .descendant(
              of: find.byType(MiPressable),
              matching: find.byType(MouseRegion),
            )
            .first,
      );
      expect(mouse.cursor, SystemMouseCursors.click);

      await gesture.removePointer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(hovered, [true, false]);
    });

    testWidgets('hover: false 不挂悬停层；禁用自动失效', (tester) async {
      setWindow(tester, const Size(400, 300));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(onPressed: () {}, hover: false));
      expect(
        find.descendant(
          of: find.byType(MiPressable),
          matching: find.byType(MouseRegion),
        ),
        findsNothing,
      );

      // 禁用：MiHoverFeedback(enabled: false) 直接返回子级 —— 无叠色、无光标。
      await tester.pumpWidget(harness(onPressed: null));
      await tester.pumpAndSettle();
      expect(find.byKey(MiHoverFeedback.overlayKey), findsNothing);
      expect(
        find.descendant(
          of: find.byType(MiPressable),
          matching: find.byType(MouseRegion),
        ),
        findsNothing,
      );
    });
  });

  group('键盘焦点', () {
    testWidgets('默认开启：聚焦出环、Enter / Space 激活、失焦复原', (tester) async {
      setWindow(tester, const Size(400, 300));
      addTearDown(tester.view.reset);

      var activated = 0;
      await tester.pumpWidget(harness(onPressed: () => activated++));
      await tester.pumpAndSettle();

      // 自建 FocusNode（MiFocusRing 内部）；限定在环内查找。
      FocusNode nodeOf(WidgetTester t) => t
          .widget<Focus>(
            find.descendant(
              of: find.byType(MiFocusRing),
              matching: find.byType(Focus),
            ),
          )
          .focusNode!;

      expect(ringColor(tester), Colors.transparent, reason: '未聚焦描边全透明');

      nodeOf(tester).requestFocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(ringColor(tester), isNot(Colors.transparent), reason: '聚焦出环');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(activated, 2, reason: 'Enter / Space 都应激活');

      nodeOf(tester).unfocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(ringColor(tester), Colors.transparent, reason: '失焦复原');
    });

    testWidgets('focus: false 不挂焦点环；禁用同样无环', (tester) async {
      setWindow(tester, const Size(400, 300));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(onPressed: () {}, focus: false));
      expect(find.byKey(MiFocusRing.ringKey), findsNothing);

      await tester.pumpWidget(harness(onPressed: null));
      await tester.pumpAndSettle();
      expect(find.byKey(MiFocusRing.ringKey), findsNothing);
    });
  });
}
