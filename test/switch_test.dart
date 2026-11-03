import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel。
import 'package:mi_like_ui/mi_like_ui.dart';

/// `MiSwitch` 契约测试（推导组件，无实机素材；几何口径见 metrics）。
///
/// 判据约定：
///  * 点按 / Enter / Space 切换，回调新值；
///  * 禁用（onChanged null）：不响应、不可聚焦；
///  * 切换后钮体**弹簧吸附到行程端点**（临界阻尼、settle 后无残余位移）。
void main() {
  void setWindow(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Widget harness({required ValueChanged<bool> onChanged, bool value = false}) =>
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MiSwitch(
              value: value,
              onChanged: onChanged,
              themeMode: MiThemeMode.dark,
            ),
          ),
        ),
      );

  /// 钮体左缘（相对开关盒）。
  double knobLeft(WidgetTester tester) {
    final switchTopLeft = tester.getRect(find.byType(MiSwitch)).topLeft;
    return tester.getTopLeft(find.byKey(MiSwitch.knobKey)).dx -
        switchTopLeft.dx;
  }

  testWidgets('点按切换：回调新值，弹簧吸附到行程端点', (tester) async {
    setWindow(tester, const Size(400, 300));

    var value = false;
    bool? reported;
    Widget build() => harness(
          value: value,
          onChanged: (v) {
            value = v;
            reported = v;
          },
        );
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MiSwitch));
    await tester.pumpWidget(build());
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(reported, isTrue, reason: '点按应回调 true');
    expect(value, isTrue);

    // settle 后钮体停在行程右端（内缩 + 行程）。
    expect(
      knobLeft(tester),
      moreOrLessEquals(
        MiSwitchMetrics.knobInset + MiSwitchMetrics.travel,
        epsilon: 0.05,
      ),
    );

    // 再点回 false：钮体回到左端内缩位。
    await tester.tap(find.byType(MiSwitch));
    await tester.pumpWidget(build());
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(reported, isFalse);
    expect(knobLeft(tester), moreOrLessEquals(MiSwitchMetrics.knobInset, epsilon: 0.05));
  });

  testWidgets('键盘：Enter / Space 切换（经 MiPressable 焦点）', (tester) async {
    setWindow(tester, const Size(400, 300));

    var flips = 0;
    await tester.pumpWidget(harness(onChanged: (_) => flips++));
    await tester.pumpAndSettle();

    tester
        .widget<Focus>(
          find.descendant(
            of: find.byType(MiPressable),
            matching: find.byType(Focus),
          ),
        )
        .focusNode!
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(flips, 2);
  });

  testWidgets('禁用：不响应点按、无焦点环、降透明', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: MiSwitch(value: true, onChanged: null),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(MiFocusRing.ringKey), findsNothing);
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(MiSwitch),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      moreOrLessEquals(MiSwitchMetrics.disabledOpacity),
    );
    final before = knobLeft(tester);
    await tester.tap(find.byType(MiSwitch));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(knobLeft(tester), before, reason: '禁用点按不应移动钮体');
  });
}
