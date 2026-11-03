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

  testWidgets('拖拽：越过行程中点即切换（受控上抛）', (tester) async {
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

    // 分步移动：单次大位移会被 touch slop（18）整段吃掉。
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MiSwitch)),
    );
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(15, 0));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();

    expect(reported, isTrue, reason: '拖过中点应回调 true');
    await tester.pumpWidget(build());
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(
      knobLeft(tester),
      moreOrLessEquals(
        MiSwitchMetrics.knobInset + MiSwitchMetrics.travel,
        epsilon: 0.05,
      ),
      reason: '归位到右端',
    );
  });

  testWidgets('拖拽：未越过中点则弹回原位、不回调', (tester) async {
    setWindow(tester, const Size(400, 300));

    var calls = 0;
    await tester.pumpWidget(
      harness(value: false, onChanged: (_) => calls++),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MiSwitch)),
    );
    await tester.pump();
    // 总位移 25 → 扣掉 slop 后约 7dp，进度 ≈ 0.35 < 0.5。
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(5, 0));
    await tester.pump();
    final dragging = knobLeft(tester);
    expect(dragging, greaterThan(MiSwitchMetrics.knobInset),
        reason: '拖拽中钮体应跟手');

    await gesture.up();
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(calls, 0, reason: '未过中点不切换');
    expect(
      knobLeft(tester),
      moreOrLessEquals(MiSwitchMetrics.knobInset, epsilon: 0.05),
      reason: '弹回左端',
    );
  });

  testWidgets('按压：钮体放大到参考档，松开回原尺寸', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(harness(onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(MiSwitch.knobKey)).width,
      moreOrLessEquals(MiSwitchMetrics.knobSize, epsilon: 0.01),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MiSwitch)),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(MiSwitch.knobKey)).width,
      moreOrLessEquals(
        MiSwitchMetrics.knobSize * MiSwitchMetrics.knobScaleActive,
        epsilon: 0.05,
      ),
      reason: '按下时放大到 knobScaleActive',
    );

    await gesture.up();
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(
      tester.getSize(find.byKey(MiSwitch.knobKey)).width,
      moreOrLessEquals(MiSwitchMetrics.knobSize, epsilon: 0.01),
      reason: '松开回原尺寸',
    );
  });

  testWidgets('RTL：钮体从右端起算、拖拽方向镜像', (tester) async {
    setWindow(tester, const Size(400, 300));

    var value = false;
    Widget build() => MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: MiSwitch(
                  value: value,
                  themeMode: MiThemeMode.dark,
                  onChanged: (v) => value = v,
                ),
              ),
            ),
          ),
        );
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    // 关态时钮体贴右缘：左缘 = 轨道宽 − 内缩 − 钮径。
    final switchRect = tester.getRect(find.byType(MiSwitch));
    double rightGap() =>
        switchRect.right - tester.getRect(find.byKey(MiSwitch.knobKey)).right;
    expect(
      rightGap(),
      moreOrLessEquals(MiSwitchMetrics.knobInset, epsilon: 0.05),
      reason: 'RTL 关态钮体贴右缘',
    );

    // 向左拖（RTL 的「开」方向）。
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MiSwitch)),
    );
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(-15, 0));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
    expect(value, isTrue, reason: 'RTL 向左拖 = 开');

    await tester.pumpWidget(build());
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(
      switchRect.right - tester.getRect(find.byKey(MiSwitch.knobKey)).right,
      moreOrLessEquals(
        MiSwitchMetrics.trackWidth -
            MiSwitchMetrics.knobInset -
            MiSwitchMetrics.knobSize,
        epsilon: 0.05,
      ),
      reason: 'RTL 开态钮体贴左缘',
    );
  });
}
