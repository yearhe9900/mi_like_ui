import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel。
import 'package:mi_like_ui/mi_like_ui.dart';

/// `MiSlider` 契约测试（推导组件；几何口径见 metrics）。
///
/// 判据约定：
///  * 拖拽取值走**坐标系换算**（globalToLocal），拖到哪算哪、不累加
///    delta（flutter_miuix slider_drag_test 同款回归）；
///  * 分档吸附；键盘 ← / → 按步长增减；禁用全关。
void main() {
  void setWindow(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  // 滑条恒宽 300，起点 x = (400−300)/2 = 50。
  Widget harness({
    required double value,
    required ValueChanged<double> onChanged,
    int? divisions,
    FocusNode? focusNode,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: MiSlider(
                value: value,
                onChanged: onChanged,
                divisions: divisions,
                focusNode: focusNode,
                themeMode: MiThemeMode.dark,
              ),
            ),
          ),
        ),
      );

  testWidgets('拖拽：按下 / 拖动即按坐标取值（受控上抛）', (tester) async {
    setWindow(tester, const Size(400, 300));

    final reported = <double>[];
    await tester.pumpWidget(
      harness(value: 0, onChanged: reported.add),
    );

    // 从滑条中心拖到 x=200 → (200−50)/300 = 0.5。
    final gesture = await tester.startGesture(const Offset(50, 150));
    await tester.pump();
    await gesture.moveTo(const Offset(200, 150));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(reported, isNotEmpty);
    expect(reported.last, moreOrLessEquals(0.5, epsilon: 0.02));
  });

  testWidgets('分档：拖拽按档吸附（5 档 → 0/0.25/…）', (tester) async {
    setWindow(tester, const Size(400, 300));

    final reported = <double>[];
    await tester.pumpWidget(
      harness(value: 0, onChanged: reported.add, divisions: 5),
    );

    final gesture = await tester.startGesture(const Offset(50, 150));
    await tester.pump();
    // 拖到 0.4×300+50 = 170 → 0.4 吸附到 0.5（5 档步长 0.25）。
    await gesture.moveTo(const Offset(170, 150));
    await tester.pump();
    await gesture.up();

    expect(reported.last, moreOrLessEquals(0.5));
  });

  testWidgets('键盘：Tab 聚焦后 ← / → 按步长增减', (tester) async {
    setWindow(tester, const Size(400, 300));

    final reported = <double>[];
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      harness(value: 0.5, onChanged: reported.add, focusNode: node),
    );
    await tester.pumpAndSettle();

    node.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(reported.length, 1);
    expect(
      reported.last,
      moreOrLessEquals(0.5 + 1 / MiSliderMetrics.keyboardSteps),
    );

    // 受控组件：把新值喂回再按 ←（同 switch 测试口径）。
    await tester.pumpWidget(
      harness(value: reported.last!, onChanged: reported.add, focusNode: node),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(reported.length, 2);
    expect(reported.last, moreOrLessEquals(0.5));
  });

  testWidgets('禁用：不可拖、降透明', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: MiSlider(value: 0.5, onChanged: null),
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(MiSlider),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      moreOrLessEquals(MiSwitchMetrics.disabledOpacity),
    );

    final gesture = await tester.startGesture(const Offset(50, 150));
    await tester.pump();
    await gesture.moveTo(const Offset(250, 150));
    await tester.pump();
    await gesture.up();
    // 无回调上抛（受控值不变即静止）。
    expect(find.byType(MiSlider), findsOneWidget);
  });
}
