import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel。
import 'package:mi_like_ui/mi_like_ui.dart';
// 内部画笔（不属公共 API）：测试读三态动画的当前值。
import 'package:mi_like_ui/src/components/inputs/checkbox/checkbox_painter.dart';

/// `MiCheckbox` 契约测试（参考实现值，无本库实机素材；几何口径见 metrics）。
///
/// 判据约定：
///  * 三态点按语义：关 → 开 → 关；**半选 → 全选**（回调恒给确定态）；
///  * 勾号是连续变形：开态淡入 + trim 划开，半选变成横杠（读画笔状态）；
///  * 禁用（onChanged null）：不响应、不可聚焦、整件降透明；
///  * 语义三态：`checked` / `mixed` 都要能被读屏读出。
void main() {
  void setWindow(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(240, 240);
    addTearDown(tester.view.reset);
  }

  Widget harness({
    required bool? value,
    required ValueChanged<bool>? onChanged,
  }) =>
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: MiCheckbox(
              value: value,
              onChanged: onChanged,
              themeMode: MiThemeMode.dark,
            ),
          ),
        ),
      );

  MiCheckboxPainter painterOf(WidgetTester tester) =>
      tester.widget<CustomPaint>(find.byKey(MiCheckbox.painterKey)).painter!
          as MiCheckboxPainter;

  testWidgets('点按切换：关 → 开 → 关，勾号淡入并划开', (tester) async {
    setWindow(tester);

    bool? value = false;
    final reports = <bool>[];
    Widget build() => StatefulBuilder(
          builder: (context, setState) => harness(
            value: value,
            onChanged: (v) {
              reports.add(v);
              setState(() => value = v);
            },
          ),
        );

    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    // 关态：勾号全透明（圆底照画）。
    expect(painterOf(tester).alpha, 0);

    await tester.tap(find.byType(MiCheckbox));
    await tester.pumpAndSettle();
    expect(reports, <bool>[true], reason: '关态点按应回调 true');
    expect(painterOf(tester).alpha, closeTo(1, 1e-6));
    expect(painterOf(tester).trim, closeTo(1, 1e-6));
    expect(painterOf(tester).indeterminate, 0);

    await tester.tap(find.byType(MiCheckbox));
    await tester.pumpAndSettle();
    expect(reports, <bool>[true, false], reason: '开态点按应回调 false');
    expect(painterOf(tester).alpha, 0);
  });

  testWidgets('半选：读作横杠，点按即全选', (tester) async {
    setWindow(tester);

    bool? value;
    final reports = <bool>[];
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => harness(
          value: value,
          onChanged: (v) {
            reports.add(v);
            setState(() => value = v);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 半选：勾号可见且已收拢成横杠。
    expect(painterOf(tester).alpha, closeTo(1, 1e-6));
    expect(painterOf(tester).indeterminate, closeTo(1, 1e-6));

    await tester.tap(find.byType(MiCheckbox));
    await tester.pumpAndSettle();
    expect(reports, <bool>[true], reason: '半选点按应直接全选');
    expect(painterOf(tester).indeterminate, closeTo(0, 1e-6));
    expect(painterOf(tester).trim, closeTo(1, 1e-6));
  });

  testWidgets('语义：checked / mixed 三态可读', (tester) async {
    setWindow(tester);

    await tester.pumpWidget(harness(value: true, onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byType(MiCheckbox)).flagsCollection.isChecked,
      CheckedState.isTrue,
    );

    await tester.pumpWidget(harness(value: false, onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byType(MiCheckbox)).flagsCollection.isChecked,
      CheckedState.isFalse,
    );

    await tester.pumpWidget(harness(value: null, onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byType(MiCheckbox)).flagsCollection.isChecked,
      CheckedState.mixed,
    );
  });

  testWidgets('键盘：Enter / Space 切换（经 MiPressable 焦点）', (tester) async {
    setWindow(tester);

    final reports = <bool>[];
    await tester.pumpWidget(harness(value: false, onChanged: reports.add));
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
    expect(reports, <bool>[true, true]);
  });

  testWidgets('禁用：不响应点按、无焦点环、降透明', (tester) async {
    setWindow(tester);

    await tester.pumpWidget(harness(value: true, onChanged: null));
    await tester.pumpAndSettle();

    expect(find.byKey(MiFocusRing.ringKey), findsNothing);
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(MiCheckbox),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      closeTo(MiDimens.disabledOpacity, 1e-9),
    );

    await tester.tap(find.byType(MiCheckbox));
    await tester.pumpAndSettle();
    expect(painterOf(tester).alpha, closeTo(1, 1e-6),
        reason: '禁用点按不应改变状态');
  });

  testWidgets('几何：命中区即圆底直径', (tester) async {
    setWindow(tester);

    await tester.pumpWidget(harness(value: false, onChanged: (_) {}));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(MiCheckbox)),
      const Size.square(MiCheckboxMetrics.size),
    );
  });
}
