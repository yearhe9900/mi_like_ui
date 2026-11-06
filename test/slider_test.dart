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
    List<double>? keyPoints,
    bool showKeyPoints = false,
    bool reverseDirection = false,
    VoidCallback? onChangeEnd,
    TextDirection direction = TextDirection.ltr,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Directionality(
              textDirection: direction,
              child: SizedBox(
                width: 300,
                child: MiSlider(
                  value: value,
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                  divisions: divisions,
                  keyPoints: keyPoints,
                  showKeyPoints: showKeyPoints,
                  reverseDirection: reverseDirection,
                  focusNode: focusNode,
                  themeMode: MiThemeMode.dark,
                ),
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

  testWidgets('点按：落到点击位置并上抛', (tester) async {
    setWindow(tester, const Size(400, 300));

    final reported = <double>[];
    await tester.pumpWidget(harness(value: 0, onChanged: reported.add));
    await tester.pumpAndSettle();

    // 点在中点：local 150 → (150 − 10) / 280 = 0.5（拇指半径贴边换算）。
    await tester.tapAt(const Offset(200, 150));
    await tester.pumpAndSettle();

    expect(reported, isNotEmpty);
    expect(reported.last, moreOrLessEquals(0.5, epsilon: 0.01));
  });

  testWidgets('几何：拇指圆心贴着轨道两端（不越出轨道）', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(harness(value: 0, onChanged: (_) {}));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(MiSlider));
    expect(
      tester.getCenter(find.byKey(MiSlider.thumbKey)).dx,
      moreOrLessEquals(rect.left + MiSliderMetrics.thumbSize / 2, epsilon: 0.6),
      reason: '取值 0 时拇指应内切左缘，不应探出控件外',
    );

    await tester.pumpWidget(harness(value: 1, onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.byKey(MiSlider.thumbKey)).dx,
      moreOrLessEquals(rect.right - MiSliderMetrics.thumbSize / 2, epsilon: 0.6),
    );
  });

  testWidgets('关键点：给出即陈列，越过的点换选中色', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      harness(
        value: 0.6,
        onChanged: (_) {},
        keyPoints: const [0.25, 0.75],
      ),
    );
    await tester.pumpAndSettle();

    Color colorOf(int i) =>
        (tester.widget<DecoratedBox>(find.byKey(MiSlider.keyPointKey(i)))
                .decoration as ShapeDecoration)
            .color!;

    expect(find.byKey(MiSlider.keyPointKey(1)), findsOneWidget);
    expect(find.byKey(MiSlider.keyPointKey(2)), findsNothing);
    // 0.25 已被越过（活动段一侧）→ 选中色；0.75 尚未 → 未选中色。
    expect(colorOf(0), MiSliderPalette.keyPointOn);
    expect(colorOf(1), MiSliderPalette.keyPointOffFor(MiThemeMode.dark));
  });

  testWidgets('分档：showKeyPoints 展示等分刻度', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      harness(
        value: 0,
        onChanged: (_) {},
        divisions: 3,
        showKeyPoints: true,
      ),
    );
    await tester.pumpAndSettle();

    // 3 档 = 0 / 0.5 / 1 三个刻度。
    expect(find.byKey(MiSlider.keyPointKey(0)), findsOneWidget);
    expect(find.byKey(MiSlider.keyPointKey(2)), findsOneWidget);
    expect(find.byKey(MiSlider.keyPointKey(3)), findsNothing);
  });

  testWidgets('磁性吸附：阈值内吸到最近关键点', (tester) async {
    setWindow(tester, const Size(400, 300));

    final reported = <double>[];
    await tester.pumpWidget(
      harness(
        value: 0,
        onChanged: reported.add,
        keyPoints: const [0.5],
      ),
    );
    await tester.pumpAndSettle();

    // 原始 0.511（local 153），距 0.5 只有 0.011 < 阈值 0.02 → 吸到 0.5。
    final gesture = await tester.startGesture(const Offset(50, 150));
    await tester.pump();
    await gesture.moveTo(const Offset(203, 150));
    await tester.pump();
    await gesture.up();

    expect(reported.last, moreOrLessEquals(0.5, epsilon: 0.001));
  });

  testWidgets('方向：reverseDirection 翻转，RTL 再镜像一次', (tester) async {
    setWindow(tester, const Size(400, 300));

    final reversed = <double>[];
    await tester.pumpWidget(
      harness(value: 0, onChanged: reversed.add, reverseDirection: true),
    );
    await tester.pumpAndSettle();
    // 反向 + 点左端 → 取最大值。
    await tester.tapAt(const Offset(52, 150));
    await tester.pumpAndSettle();
    expect(reversed.last, moreOrLessEquals(1, epsilon: 0.01));

    final rtl = <double>[];
    await tester.pumpWidget(
      harness(
        value: 0,
        onChanged: rtl.add,
        direction: TextDirection.rtl,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(52, 150));
    await tester.pumpAndSettle();
    expect(rtl.last, moreOrLessEquals(1, epsilon: 0.01),
        reason: 'RTL 下左端是「大」端');

    // 反向 + RTL 抵消 → 左端回到最小值。
    final both = <double>[];
    await tester.pumpWidget(
      harness(
        value: 1,
        onChanged: both.add,
        reverseDirection: true,
        direction: TextDirection.rtl,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(52, 150));
    await tester.pumpAndSettle();
    expect(both.last, moreOrLessEquals(0, epsilon: 0.01));
  });

  testWidgets('onChangeEnd：一次拖拽只通知一次', (tester) async {
    setWindow(tester, const Size(400, 300));

    var ends = 0;
    await tester.pumpWidget(
      harness(
        value: 0,
        onChanged: (_) {},
        onChangeEnd: () => ends++,
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(50, 150));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(ends, 1);
  });

  testWidgets('拇指：拖拽中放大到参考档，松手回原尺寸', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(harness(value: 0, onChanged: (_) {}));
    await tester.pumpAndSettle();

    double thumbScale() => tester
        .widget<Transform>(find.byKey(MiSlider.thumbKey))
        .transform
        .getMaxScaleOnAxis();

    expect(thumbScale(), moreOrLessEquals(1, epsilon: 0.001));

    final gesture = await tester.startGesture(const Offset(60, 150));
    await tester.pump();
    await gesture.moveBy(const Offset(20, 0));
    // 第一帧只让 ticker 起跳，第二帧才推进动画时间（同 switch 测试口径）。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      thumbScale(),
      moreOrLessEquals(MiSliderMetrics.thumbScaleActive, epsilon: 0.005),
    );

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(thumbScale(), moreOrLessEquals(1, epsilon: 0.005));
  });
}
