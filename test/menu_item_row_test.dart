import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；若导出缺失会在这里暴露。
import 'package:mi_like_ui/mi_like_ui.dart';

/// `MiMenuItemRow` 契约测试（菜单行的公开形态，`MiuixDropdownImpl` 的对应物）。
///
/// 判据约定：
///  * 行尾装饰由状态推导（勾号 > 回退左箭头 > 级联右箭头），且**不参与行高**
///    —— 20dp 的勾号撑高 15.9dp 文案行是 issue #6 的回归点；
///  * 首 / 末行上下内边距取更松的一档（参考实现口径）；
///  * 禁用 = 墨色降档 + 不响应，语义仍标 button；
///  * 按压高亮走 `MiPressable` 的 `pressBuilder`（实色，不引 saveLayer）。
void main() {
  void setWindow(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  // 恒宽 280：行是 Row 布局，需要一个有界父级才谈得上「收缩 / 限宽」。
  Widget harness(Widget child) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 280, child: child),
          ),
        ),
      );

  Color labelColor(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.color!;

  double rowHeight(WidgetTester tester) =>
      tester.getSize(find.byType(MiMenuItemRow)).height;

  /// 行内所有 `AnimatedContainer` 里是否有按压色（pressBuilder 那层）。
  /// 不按位置取：焦点环 / 悬停层同样是 `AnimatedContainer`，按色值判断最稳。
  bool hasPressColor(WidgetTester tester) => tester
      .widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byType(MiMenuItemRow),
          matching: find.byType(AnimatedContainer),
        ),
      )
      .any((box) =>
          box.decoration is BoxDecoration &&
          (box.decoration as BoxDecoration).color == MiMenuPalette.dark.pressed);

  /// 参考口径：中间行 = 上下 12 + 主文案行盒 15.9（引擎取整，容差 0.2）。
  double middleHeight() => MiMenuMetrics.rowPadY * 2 + 15.9;

  testWidgets('默认行：无行尾装饰，文案取主 / 次级墨色，行高只由文案块决定',
      (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      harness(
        const MiMenuItemRow(
          label: '名称',
          themeMode: MiThemeMode.dark,
        ),
      ),
    );

    expect(find.byKey(MiMenuItemRow.checkKey), findsNothing);
    expect(find.byKey(MiMenuItemRow.chevronKey), findsNothing);
    expect(find.byKey(MiMenuItemRow.backChevronKey), findsNothing);
    expect(labelColor(tester, '名称'), MiMenuPalette.dark.label);
    expect(rowHeight(tester), closeTo(middleHeight(), 0.2));
  });

  testWidgets('副文案：次级墨色，且不影响主文案墨色', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      harness(
        const MiMenuItemRow(
          label: '名称',
          subtitle: '按名称排序',
          themeMode: MiThemeMode.light,
        ),
      ),
    );

    expect(labelColor(tester, '名称'), MiMenuPalette.light.label);
    expect(labelColor(tester, '按名称排序'), MiMenuPalette.light.secondary);
  });

  testWidgets('选中：勾号出现、主文案换强调色，行高与普通行一致', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      harness(
        const MiMenuItemRow(
          label: '名称',
          selected: true,
          themeMode: MiThemeMode.dark,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(MiMenuItemRow.checkKey), findsOneWidget);
    expect(find.byKey(MiMenuItemRow.chevronKey), findsNothing);
    expect(labelColor(tester, '名称'), MiMenuPalette.dark.selectedLabel);
    // 回归（issue #6）：勾号墨盒不参与行高。
    expect(rowHeight(tester), closeTo(middleHeight(), 0.2));
    expect(
      tester.getSemantics(find.text('名称')).flagsCollection.isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('级联触发器：右箭头；与选中同给时勾号优先', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      harness(
        const MiMenuItemRow(
          label: '排序方式',
          hasChildren: true,
          themeMode: MiThemeMode.dark,
        ),
      ),
    );
    expect(find.byKey(MiMenuItemRow.chevronKey), findsOneWidget);
    expect(find.byKey(MiMenuItemRow.checkKey), findsNothing);

    await tester.pumpWidget(
      harness(
        const MiMenuItemRow(
          label: '排序方式',
          selected: true,
          hasChildren: true,
          themeMode: MiThemeMode.dark,
        ),
      ),
    );
    expect(find.byKey(MiMenuItemRow.checkKey), findsOneWidget,
        reason: '勾号优先于级联箭头');
    expect(find.byKey(MiMenuItemRow.chevronKey), findsNothing);
  });

  testWidgets('回退行：左箭头', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      harness(
        const MiMenuItemRow(
          label: '排序方式',
          subtitle: '名称',
          showBackArrow: true,
          themeMode: MiThemeMode.dark,
        ),
      ),
    );

    expect(find.byKey(MiMenuItemRow.backChevronKey), findsOneWidget);
    expect(find.byKey(MiMenuItemRow.chevronKey), findsNothing);
    expect(find.byKey(MiMenuItemRow.checkKey), findsNothing);
  });

  testWidgets('首 / 末行上下内边距更松（比中间行高 16dp）', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      harness(
        const MiMenuItemRow(label: '名称', themeMode: MiThemeMode.dark),
      ),
    );
    final middle = rowHeight(tester);

    await tester.pumpWidget(
      harness(
        const MiMenuItemRow(
          label: '名称',
          isFirst: true,
          themeMode: MiThemeMode.dark,
        ),
      ),
    );
    final edge = rowHeight(tester);

    expect(edge - middle, closeTo(16, 0.2));
    expect(
      edge,
      closeTo(MiMenuMetrics.rowEdgePadY * 2 + 15.9, 0.2),
    );
  });

  testWidgets('禁用：不响应点按，语义仍是按钮', (tester) async {
    setWindow(tester, const Size(400, 300));

    var taps = 0;
    await tester.pumpWidget(
      harness(
        MiMenuItemRow(
          label: '名称',
          enabled: false,
          themeMode: MiThemeMode.dark,
          onTap: () => taps++,
        ),
      ),
    );

    expect(labelColor(tester, '名称'), MiMenuPalette.dark.disabled);

    await tester.tap(find.text('名称'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 0);

    expect(
      tester.getSemantics(find.text('名称')).flagsCollection.isButton,
      isTrue,
    );
  });

  testWidgets('按压：高亮色 = palette.pressed，抬起复原', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      harness(
        MiMenuItemRow(
          label: '名称',
          themeMode: MiThemeMode.dark,
          onTap: () {},
        ),
      ),
    );
    expect(hasPressColor(tester), isFalse, reason: '静止态不带按压色');

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('名称')),
    );
    await tester.pump();
    expect(hasPressColor(tester), isTrue, reason: '按下进按压态');

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(hasPressColor(tester), isFalse, reason: '抬起复原');
  });

  test('别名 MiDropdownImpl 与 MiMenuItemRow 同一类型', () {
    const MiMenuItemRow row = MiDropdownImpl(label: '排序');
    expect(row, isA<MiMenuItemRow>());
    expect(row.label, '排序');
    expect(row.themeMode, isNull);
  });

  testWidgets('MiMenu 的行由本件渲染（面板不再自带行实现）', (tester) async {
    setWindow(tester, const Size(400, 400));

    final controller = MiMenuController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MiMenu(
              controller: controller,
              groups: const [
                MiMenuGroup([
                  MiMenuItem(label: '名称', selected: true),
                  MiMenuItem(label: '大小'),
                ]),
              ],
              onSelected: (_) {},
              themeMode: MiThemeMode.dark,
              child: MiButton(
                label: '排序',
                themeMode: MiThemeMode.dark,
                onPressed: controller.toggle,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('排序'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(MiMenuItemRow), findsNWidgets(2));
    expect(find.byKey(MiMenuItemRow.checkKey), findsOneWidget);
  });
}
