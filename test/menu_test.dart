import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；缺导出会在这里暴露。
import 'package:mi_like_ui/mi_like_ui.dart';

/// `MiMenu` 的几何 / 开合 / 级联 / 禁用 / 遮罩契约。
///
/// 锚点一律用 200×48 的色块（可精确读盒子），宿主用 [MiPopupHost]
/// （与 demo 外壳同口径）—— 菜单的位置是「相对宿主坐标」算的，没有宿主
/// 时会退化成锚点自身坐标系，几何断言不再成立。
void main() {
  const anchorKey = Key('menu-test-anchor');

  /// 单组三级选项：A 选中、C 禁用、B 带子菜单。
  List<MiMenuGroup> groups() => const [
        MiMenuGroup([
          MiMenuItem(label: '选项 A', selected: true, value: 'a'),
          MiMenuItem(
            label: '选项 B',
            subtitle: '带子菜单',
            value: 'b',
            children: [
              MiMenuItem(label: '子项 1', value: 'b1'),
              MiMenuItem(label: '子项 2', value: 'b2'),
            ],
          ),
          MiMenuItem(label: '选项 C', enabled: false, value: 'c'),
        ]),
      ];

  Widget page({
    required MiMenuController controller,
    Alignment alignment = Alignment.topLeft,
    bool enableScrim = true,
    bool collapseOnSelect = true,
    ValueChanged<MiMenuSelection>? onSelected,
    VoidCallback? onDismissed,
  }) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: MiPopupHost(
        child: Scaffold(
          body: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.all(100),
              child: MiMenu(
                controller: controller,
                groups: groups(),
                enableScrim: enableScrim,
                collapseOnSelect: collapseOnSelect,
                onSelected: onSelected,
                onDismissed: onDismissed,
                child: const SizedBox(key: anchorKey, width: 200, height: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 打开菜单并等动画落定（注册表把通知推到帧末，首帧只是登记）。
  Future<void> open(WidgetTester tester, MiMenuController controller) async {
    controller.open();
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('展开：面板落在锚点下方、右缘与锚点对齐、宽度在 200–288 间', (tester) async {
    final controller = MiMenuController();
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 856);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(page(controller: controller));
    expect(find.byKey(MiMenu.panelKey), findsNothing);

    await open(tester, controller);

    final anchor = tester.getRect(find.byKey(anchorKey));
    final panel = tester.getRect(find.byKey(MiMenu.panelKey));
    expect(panel.top, closeTo(anchor.bottom + MiMenuMetrics.margin, 0.5));
    expect(panel.right, closeTo(anchor.right, 0.5));
    // 弹簧落定在 fraction ≈ 0.9999（Tolerance 收口），缩放层会带出
    // 0.1% 的尺寸偏差 —— 断言按 0.5dp 容差看，不追到浮点位。
    expect(panel.width, greaterThanOrEqualTo(MiMenuMetrics.minWidth - 0.5));
    expect(panel.width, lessThanOrEqualTo(MiMenuMetrics.maxWidth + 0.5));
    expect(find.text('选项 A'), findsOneWidget);
    expect(find.text('选项 C'), findsOneWidget);
  });

  testWidgets('放不下时翻到锚点上方（底缘对齐）', (tester) async {
    final controller = MiMenuController();
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 856);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      page(controller: controller, alignment: Alignment.bottomLeft),
    );
    await open(tester, controller);

    final anchor = tester.getRect(find.byKey(anchorKey));
    final panel = tester.getRect(find.byKey(MiMenu.panelKey));
    expect(panel.bottom, closeTo(anchor.top - MiMenuMetrics.margin, 0.5));
    expect(find.text('选项 A'), findsOneWidget);
  });

  testWidgets('点叶子项：回调带 value、菜单自动收起、收口后触发 onDismissed', (tester) async {
    final controller = MiMenuController();
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 856);
    addTearDown(tester.view.reset);

    MiMenuSelection? picked;
    var dismissed = 0;
    await tester.pumpWidget(
      page(
        controller: controller,
        onSelected: (s) => picked = s,
        onDismissed: () => dismissed++,
      ),
    );
    await open(tester, controller);

    await tester.tap(find.text('选项 A'));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.item.value, 'a');
    expect(picked!.path, hasLength(1));
    expect(find.byKey(MiMenu.panelKey), findsNothing);
    expect(dismissed, 1);
    expect(controller.isOpen, isFalse);
  });

  testWidgets('级联：父项展开子列表，首行返回上级，子项回调路径包含父项', (tester) async {
    final controller = MiMenuController();
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 856);
    addTearDown(tester.view.reset);

    MiMenuSelection? picked;
    await tester.pumpWidget(
      page(controller: controller, onSelected: (s) => picked = s),
    );
    await open(tester, controller);

    await tester.tap(find.text('选项 B'));
    await tester.pumpAndSettle();

    // 二级：首行 = 返回上级（同名行），下面是子项。
    expect(find.text('子项 1'), findsOneWidget);
    expect(find.text('选项 B'), findsOneWidget);
    expect(find.text('选项 A'), findsNothing);

    await tester.tap(find.text('子项 2'));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.item.value, 'b2');
    expect(picked!.path.map((e) => e.value), ['b', 'b2']);
    expect(find.byKey(MiMenu.panelKey), findsNothing);
  });

  testWidgets('级联：点首行返回一级', (tester) async {
    final controller = MiMenuController();
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 856);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(page(controller: controller));
    await open(tester, controller);

    await tester.tap(find.text('选项 B'));
    await tester.pumpAndSettle();
    expect(find.text('子项 1'), findsOneWidget);

    await tester.tap(find.text('选项 B'));
    await tester.pumpAndSettle();
    expect(find.text('子项 1'), findsNothing);
    expect(find.text('选项 A'), findsOneWidget);
  });

  testWidgets('禁用项不响应；整组禁用同理', (tester) async {
    final controller = MiMenuController();
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 856);
    addTearDown(tester.view.reset);

    var calls = 0;
    await tester.pumpWidget(
      page(controller: controller, onSelected: (_) => calls++),
    );
    await open(tester, controller);

    await tester.tap(find.text('选项 C'));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.byKey(MiMenu.panelKey), findsOneWidget);
  });

  testWidgets('点遮罩收起；enableScrim=false 时遮罩透明但仍能点外收起', (tester) async {
    final controller = MiMenuController();
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 856);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(page(controller: controller, enableScrim: false));
    await open(tester, controller);

    final scrim = tester.widget<ColoredBox>(find.byKey(MiMenu.scrimKey));
    expect(scrim.color, MiTransparencyTokens.clear);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.byKey(MiMenu.panelKey), findsNothing);
  });

  testWidgets('collapseOnSelect=false：选中后保持展开（连续操作型菜单）', (tester) async {
    final controller = MiMenuController();
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 856);
    addTearDown(tester.view.reset);

    var calls = 0;
    await tester.pumpWidget(
      page(
        controller: controller,
        collapseOnSelect: false,
        onSelected: (_) => calls++,
      ),
    );
    await open(tester, controller);

    await tester.tap(find.text('选项 A'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.byKey(MiMenu.panelKey), findsOneWidget);
    expect(controller.isOpen, isTrue);
  });

  testWidgets('多分组：组间画分隔线，禁用整组仍占位', (tester) async {
    final controller = MiMenuController();
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 856);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: MiPopupHost(
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(100),
                child: MiMenu(
                  controller: controller,
                  groups: const [
                    MiMenuGroup([MiMenuItem(label: '上层动作')]),
                    MiMenuGroup([MiMenuItem(label: '危险动作')], enabled: false),
                  ],
                  child: const SizedBox(key: anchorKey, width: 200, height: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await open(tester, controller);

    expect(find.text('上层动作'), findsOneWidget);
    expect(find.text('危险动作'), findsOneWidget);
  });
}
