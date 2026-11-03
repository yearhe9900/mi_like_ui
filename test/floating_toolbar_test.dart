import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel。
import 'package:mi_like_ui/mi_like_ui.dart';

/// `MiFloatingToolbar` 契约测试（参考实现值，无本库实机素材；口径见 metrics）。
///
/// 判据约定：
///  * 外留白 12（横）/ 8（纵）：工具栏外框比内容大一圈；
///  * 表面 / 描边 / 投影取自既有 token；描边与投影各有开关；
///  * 容器**吃掉点击**：点在表面上不会穿透到背后内容，内部按钮仍能胜出。
void main() {
  void setWindow(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(600, 400);
    addTearDown(tester.view.reset);
  }

  Widget harness({
    bool showDivider = false,
    bool showShadow = true,
    MiThemeMode mode = MiThemeMode.dark,
    VoidCallback? onBackgroundTap,
    Widget? child,
  }) =>
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBackgroundTap,
                  child: const ColoredBox(color: Color(0xFF101010)),
                ),
              ),
              Center(
                child: MiFloatingToolbar(
                  showDivider: showDivider,
                  showShadow: showShadow,
                  themeMode: mode,
                  child: child ??
                      const SizedBox(width: 120, height: 40),
                ),
              ),
            ],
          ),
        ),
      );

  ShapeDecoration surfaceOf(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MiFloatingToolbar),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return box.decoration as ShapeDecoration;
  }

  testWidgets('几何：外留白 12 / 8，圆角 50', (tester) async {
    setWindow(tester);
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(MiFloatingToolbar)),
      const Size(120 + 24, 40 + 16),
    );
    final shape = surfaceOf(tester).shape as MiSquircleBorder;
    expect(shape.cornerRadius, MiFloatingToolbarMetrics.cornerRadius);
  });

  testWidgets('配色：表面取设置卡档，描边 / 投影取既有 token', (tester) async {
    setWindow(tester);
    await tester.pumpWidget(harness(showDivider: true));
    await tester.pumpAndSettle();

    final palette = MiFloatingToolbarPalette.of(MiThemeMode.dark);
    final decoration = surfaceOf(tester);
    expect(decoration.color, palette.surface);
    expect(
      (decoration.shape as MiSquircleBorder).side.width,
      MiFloatingToolbarMetrics.dividerWidth,
    );
    expect((decoration.shape as MiSquircleBorder).side.color, palette.divider);

    // 投影走 squircle 路径投影（不套 elevation 语义）。
    final shadows = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((p) => p.painter is MiSquircleShadowPainter);
    expect(shadows, hasLength(1));
    final painter = shadows.first.painter! as MiSquircleShadowPainter;
    expect(painter.shadows.single.blurRadius,
        MiFloatingToolbarMetrics.shadowBlurRadius);
    expect(painter.shadows.single.color, palette.shadow);
  });

  testWidgets('开关：无描边 / 无投影时不画', (tester) async {
    setWindow(tester);
    await tester.pumpWidget(harness(showDivider: false, showShadow: false));
    await tester.pumpAndSettle();

    expect((surfaceOf(tester).shape as MiSquircleBorder).side,
        BorderSide.none);
    expect(
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .where((p) => p.painter is MiSquircleShadowPainter),
      isEmpty,
    );
  });

  testWidgets('命中：表面吃掉点击，内部按钮仍胜出', (tester) async {
    setWindow(tester);
    var background = 0;
    var inner = 0;
    await tester.pumpWidget(harness(
      onBackgroundTap: () => background++,
      child: SizedBox(
        width: 120,
        height: 40,
        child: Center(
          child: GestureDetector(
            key: const Key('inner-action'),
            // 空 SizedBox 不参与命中测试 —— 内层按 opaque 才吃得到点击。
            behavior: HitTestBehavior.opaque,
            onTap: () => inner++,
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // 表面内的空白处：被工具栏吃掉，不穿透。
    final rect = tester.getRect(find.byType(MiFloatingToolbar));
    await tester.tapAt(Offset(rect.left + 20, rect.center.dy));
    await tester.pumpAndSettle();
    expect(background, 0, reason: '点表面不应穿透到背后内容');

    // 内部按钮：照常响应。
    await tester.tap(find.byKey(const Key('inner-action')));
    await tester.pumpAndSettle();
    expect(inner, 1);

    // 外留白之外：正常落到背景。
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(background, 1);
  });
}
