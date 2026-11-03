import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel。
import 'package:mi_like_ui/mi_like_ui.dart';

/// `MiBottomSheet` 契约测试（参考实现值，无本库实机素材；口径见 metrics）。
///
/// 判据约定：
///  * 打开：弹簧滑入后**贴底**（表面下缘 = 屏底）、铺满屏宽、标题可见；
///  * 关闭：先要经过**滑出动画**，收口后才回调 `onDismissed` 并注销弹层；
///  * 遮罩点按 / 手柄下拉到位 → `onDismissRequest`（是否真收起由宿主决定）；
///  * 上拉受阻尼（抽屉已贴底）；禁用下拉时下拉也只是阻尼回弹；
///  * 宽屏限宽并居中；无 `MiPopupHost` 时就地渲染（既有单组件用法不破）。
void main() {
  const Size phone = Size(393, 856);

  void setWindow(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Widget sheet({
    required bool show,
    required VoidCallback onDismissRequest,
    VoidCallback? onDismissed,
    bool enableDragDismiss = true,
  }) =>
      MiBottomSheet(
        show: show,
        title: '选择操作',
        onDismissRequest: onDismissRequest,
        onDismissed: onDismissed,
        enableDragDismiss: enableDragDismiss,
        themeMode: MiThemeMode.dark,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('抽屉内容'),
        ),
      );

  /// 带宿主的页面（与 demo 外壳同口径）。
  Widget shell({
    required bool show,
    required VoidCallback onDismissRequest,
    VoidCallback? onDismissed,
    bool enableDragDismiss = true,
    bool host = true,
  }) {
    final content = Stack(
      children: [
        const Positioned.fill(
          child: Scaffold(body: Center(child: Text('页面内容'))),
        ),
        sheet(
          show: show,
          onDismissRequest: onDismissRequest,
          onDismissed: onDismissed,
          enableDragDismiss: enableDragDismiss,
        ),
      ],
    );
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: host ? MiPopupHost(child: content) : content,
    );
  }

  testWidgets('打开：贴底、铺满屏宽、标题可见', (tester) async {
    setWindow(tester, phone);
    await tester.pumpWidget(shell(show: true, onDismissRequest: () {}));
    await tester.pumpAndSettle();

    final surface = tester.getRect(find.byKey(MiBottomSheet.surfaceKey));
    expect(surface.bottom, closeTo(phone.height, 0.5), reason: '下缘贴屏底');
    expect(surface.width, closeTo(phone.width, 0.5), reason: '手机档铺满屏宽');
    expect(surface.top, greaterThan(phone.height / 2), reason: '抽屉从底部起');
    // 高 = 手柄热区 + 标题行 + 内容（内容 = 24 上下留白 + 一行字）。
    final contentHeight = tester.getSize(find.text('抽屉内容')).height + 48;
    expect(
      surface.height,
      closeTo(
        MiBottomSheetMetrics.handleAreaHeight +
            MiBottomSheetMetrics.titleTop +
            MiBottomSheetMetrics.titleBottom +
            MiTypography.dialogTitle.fontSize! +
            contentHeight,
        1.0,
      ),
    );
    expect(find.text('选择操作'), findsOneWidget);
    expect(find.text('抽屉内容'), findsOneWidget);
  });

  testWidgets('遮罩点按：请求收起 → 滑出后才注销并回调', (tester) async {
    setWindow(tester, phone);

    var show = true;
    var requests = 0;
    var dismissed = 0;
    await tester.pumpWidget(StatefulBuilder(
      builder: (context, setState) => shell(
        show: show,
        onDismissRequest: () {
          requests++;
          setState(() => show = false);
        },
        onDismissed: () => dismissed++,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(MiBottomSheet.scrimKey));
    await tester.pump();
    expect(requests, 1);
    expect(dismissed, 0, reason: '滑出动画期间不得提前回调');

    // 动画途中仍挂载（不瞬移 / 不闪）。
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byKey(MiBottomSheet.surfaceKey), findsOneWidget);

    await tester.pumpAndSettle();
    expect(dismissed, 1);
    expect(find.byKey(MiBottomSheet.surfaceKey), findsNothing);
  });

  testWidgets('手柄下拉到位：请求收起', (tester) async {
    setWindow(tester, phone);

    var requests = 0;
    await tester.pumpWidget(
      shell(show: true, onDismissRequest: () => requests++),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byKey(MiBottomSheet.handleKey), const Offset(0, 200));
    await tester.pump();

    expect(requests, 1);
    // 宿主没接收起：抽屉弹回原位（不留半截）。
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(MiBottomSheet.surfaceKey)).bottom,
      closeTo(phone.height, 0.5),
    );
  });

  testWidgets('上拉受阻尼（抽屉已贴底）', (tester) async {
    setWindow(tester, phone);

    var requests = 0;
    await tester.pumpWidget(
      shell(show: true, onDismissRequest: () => requests++),
    );
    await tester.pumpAndSettle();
    final baseline = tester.getRect(find.byKey(MiBottomSheet.surfaceKey)).top;

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(MiBottomSheet.handleKey)),
    );
    // 逐步移动（首步吃掉手势 slop）：总位移 −100，松手也不该触发收起。
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(0, -25));
      // 拖动位移经注册表推到帧末，宿主下一帧才重建 —— 两帧后量。
      await tester.pump();
      await tester.pump();
    }
    final moved =
        baseline - tester.getRect(find.byKey(MiBottomSheet.surfaceKey)).top;
    expect(moved, greaterThan(0), reason: '上拉应有一点点跟随（表达到头了）');
    expect(moved, lessThan(40), reason: '上拉位移要被阻尼折减');

    await gesture.up();
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(
      tester.getRect(find.byKey(MiBottomSheet.surfaceKey)).top,
      closeTo(baseline, 0.5),
      reason: '松手回弹到就位位置',
    );
  });

  testWidgets('禁用下拉：下拉不触发请求，且阻尼回弹', (tester) async {
    setWindow(tester, phone);

    var requests = 0;
    await tester.pumpWidget(
      shell(
        show: true,
        onDismissRequest: () => requests++,
        enableDragDismiss: false,
      ),
    );
    await tester.pumpAndSettle();
    final baseline = tester.getRect(find.byKey(MiBottomSheet.surfaceKey)).top;

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(MiBottomSheet.handleKey)),
    );
    // 逐步下移（首步吃掉手势 slop）：总位移 240 也不该触发收起。
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      await tester.pump();
    }
    expect(
      tester.getRect(find.byKey(MiBottomSheet.surfaceKey)).top - baseline,
      greaterThan(0),
      reason: '禁用下拉时仍要跟随一点点（表达到头了）',
    );
    expect(
      tester.getRect(find.byKey(MiBottomSheet.surfaceKey)).top - baseline,
      lessThan(60),
      reason: '禁用下拉时位移要被阻尼折减',
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(
      tester.getRect(find.byKey(MiBottomSheet.surfaceKey)).top,
      closeTo(baseline, 0.5),
    );
  });

  testWidgets('宽屏：限宽居中（不铺通栏）', (tester) async {
    setWindow(tester, const Size(1024, 768));
    await tester.pumpWidget(shell(show: true, onDismissRequest: () {}));
    await tester.pumpAndSettle();

    final surface = tester.getRect(find.byKey(MiBottomSheet.surfaceKey));
    expect(surface.width, closeTo(MiBottomSheetMetrics.maxWidth, 0.5));
    expect(surface.center.dx, closeTo(512, 0.5), reason: '宽屏居中');
    expect(surface.bottom, closeTo(768, 0.5));
  });

  testWidgets('无宿主：就地渲染（单组件用法不破）', (tester) async {
    setWindow(tester, phone);
    await tester.pumpWidget(
      shell(show: true, onDismissRequest: () {}, host: false),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(MiBottomSheet.surfaceKey), findsOneWidget);
    expect(find.text('抽屉内容'), findsOneWidget);
  });

  testWidgets('show 初始为 false：不渲染任何层', (tester) async {
    setWindow(tester, phone);
    await tester.pumpWidget(shell(show: false, onDismissRequest: () {}));
    await tester.pumpAndSettle();

    expect(find.byKey(MiBottomSheet.surfaceKey), findsNothing);
    expect(find.byKey(MiBottomSheet.scrimKey), findsNothing);
    expect(find.text('页面内容'), findsOneWidget);
  });
}
