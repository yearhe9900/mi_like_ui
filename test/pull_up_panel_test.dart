import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel。
import 'package:mi_like_ui/mi_like_ui.dart';

/// 测试画布：参考机 393×856（宽屏用例另设窗口）。
void _useCanvas(WidgetTester tester, {Size size = const Size(393, 856)}) {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.reset);
}

/// 面板测试外壳：面板挂在纯黑页底上（无压暗遮罩，页底保持原值是度量点）。
Widget _harness({
  MiThemeMode mode = MiThemeMode.dark,
  double? height = 240,
  double? maxHeight,
  Offset? anchorPoint,
  VoidCallback? onScrimTap,
  Widget? child,
}) {
  return MaterialApp(
    theme: mode == MiThemeMode.light
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true),
    home: Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: MiPullUpPanel(
        height: height,
        maxHeight: maxHeight,
        anchorPoint: anchorPoint,
        themeMode: mode,
        onScrimTap: onScrimTap,
        child: child ??
            const SizedBox(
              width: double.infinity,
              child: Text('面板内容'),
            ),
      ),
    ),
  );
}

/// 面板本体：带圆角 BoxDecoration 且填充 = palette.surface 的那只。
Finder _panel({MiThemeMode mode = MiThemeMode.dark}) => find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).color ==
              MiPullUpPanelPalette.of(mode).surface &&
          (w.decoration! as BoxDecoration).borderRadius != null,
    );

void main() {
  test('度量常量（度量 / 推导逐项，见 MiPullUpPanelMetrics 类注释）', () {
    expect(MiPullUpPanelMetrics.panelInset, 24.0);
    expect(MiPullUpPanelMetrics.panelRadius, 33.0);
    expect(MiPullUpPanelMetrics.bottomGap, 90.0);
    expect(MiPullUpPanelMetrics.triggerDiameter, 54.1);
    // 默认锚点 = 素材按钮圆心 (327.0, 803.7) @393×856
    final anchor = MiPullUpPanelMetrics.defaultAnchorFor(393, 856);
    expect(anchor.dx, closeTo(327.0, 0.01));
    expect(anchor.dy, closeTo(803.7, 0.01));
    // 弹簧拟合：ζ = 26 / 2√260 = 0.807 → 过冲 ~1.4%
    expect(MiPullUpPanelMetrics.springStiffness, 260);
    expect(MiPullUpPanelMetrics.springDamping, 26);
    expect(
      MiPullUpPanelMetrics.springDamping /
          (2 *
              math.sqrt(
                MiPullUpPanelMetrics.springStiffness *
                    MiPullUpPanelMetrics.springMass,
              )),
      closeTo(0.807, 0.001),
    );
    // 面板宽 / 可用高
    expect(MiPullUpPanelMetrics.panelWidthFor(393), closeTo(345, 0.01));
    expect(MiPullUpPanelMetrics.panelWidthFor(1366), 440);
    expect(MiPullUpPanelMetrics.maxHeightFor(856, 0), 856 - 24 - 90);
    // 配色：暗 #2C2C2C（度量）/ 亮 #FFFFFF（推导）；遮罩无压暗（透明）
    expect(MiPullUpPanelPalette.dark.surface, const Color(0xFF2C2C2C));
    expect(MiPullUpPanelPalette.light.surface, const Color(0xFFFFFFFF));
    expect(MiTransparencyTokens.panelScrim.alpha, 0);
  });

  testWidgets('终态几何：宽 345、居中、底距 90、圆角 33（弹簧收口后）',
      (tester) async {
    _useCanvas(tester);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final panel = tester.getRect(_panel());
    expect(panel.width, closeTo(345, 0.5));
    expect(panel.left, closeTo(24, 0.5));
    expect(panel.height, closeTo(240, 0.5));
    expect(856 - panel.bottom, closeTo(90, 0.5));

    final deco = tester.widget<DecoratedBox>(_panel()).decoration! as BoxDecoration;
    expect(
      (deco.borderRadius as BorderRadius).topLeft.x,
      closeTo(33.0, 0.01),
    );
  });

  testWidgets('唤起：从锚点等比放大、弹簧过冲后收口（素材拟合）', (tester) async {
    _useCanvas(tester);
    await tester.pumpWidget(_harness());
    await tester.pump();

    // 首帧（t≈16ms，弹簧刚起步）：面板还很小、贴近按钮圆心
    final first = tester.getRect(_panel());
    expect(first.width, lessThan(100), reason: '起点 = 按钮直径 54.1 缩放');
    final anchor = MiPullUpPanelMetrics.defaultAnchorFor(393, 856);
    expect(
      (first.center - anchor).distance,
      lessThan(120),
      reason: '从按钮圆心弹出',
    );

    // 逐帧推到收口：记录最大宽 —— 弹簧应有 ~1.3% 过冲（345 → >347）
    var maxWidth = first.width;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      final w = tester.getRect(_panel()).width;
      if (w > maxWidth) maxWidth = w;
    }
    expect(maxWidth, greaterThan(347), reason: '弹簧过冲 ~1.3%');
    expect(maxWidth, lessThan(360), reason: '过冲幅度有限（拟合 1.4%）');
    // 收口回终态宽
    await tester.pumpAndSettle();
    expect(tester.getRect(_panel()).width, closeTo(345, 0.5));
  });

  testWidgets('自定义长高：height 定值 / null 内容自适应 / 超高钳到屏内可用高',
      (tester) async {
    _useCanvas(tester);

    // null → 内容自适应
    await tester.pumpWidget(_harness(
      height: null,
      child: const SizedBox(width: double.infinity, height: 123),
    ));
    await tester.pumpAndSettle();
    expect(tester.getRect(_panel()).height, closeTo(123, 0.5));

    // 超高 → 钳到可用高（856 − 24 − 90 = 742）
    await tester.pumpWidget(_harness(height: 2000));
    await tester.pumpAndSettle();
    expect(tester.getRect(_panel()).height, closeTo(742, 0.5));

    // maxHeight 覆盖
    await tester.pumpWidget(_harness(height: 2000, maxHeight: 400));
    await tester.pumpAndSettle();
    expect(tester.getRect(_panel()).height, closeTo(400, 0.5));
  });

  testWidgets('锚点可自定义：面板从给定圆心弹出', (tester) async {
    _useCanvas(tester);
    await tester.pumpWidget(_harness(anchorPoint: const Offset(80, 120)));
    await tester.pump();
    final first = tester.getRect(_panel());
    expect((first.center - const Offset(80, 120)).distance, lessThan(120));
    // 收口后仍是终态位（锚点只影响过程，不影响终态）
    await tester.pumpAndSettle();
    expect(tester.getRect(_panel()).left, closeTo(24, 0.5));
  });

  testWidgets('行为：面板外点按触发 onScrimTap、面板内点按命中内容（变换命中）',
      (tester) async {
    _useCanvas(tester);
    var scrimTapped = 0;
    var contentTapped = 0;
    await tester.pumpWidget(_harness(
      onScrimTap: () => scrimTapped++,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => contentTapped++,
        child: const SizedBox(width: double.infinity, height: 240),
      ),
    ));
    await tester.pumpAndSettle();

    // 面板中心 = 内容命中（等比缩放后的命中变换）
    await tester.tapAt(tester.getCenter(_panel()));
    expect(contentTapped, 1);
    expect(scrimTapped, 0);

    // 面板外左上角 = 遮罩（透明命中层）
    await tester.tapAt(const Offset(8, 8));
    expect(scrimTapped, 1);
    expect(contentTapped, 1);

    // 遮罩是**透明**的（无压暗 —— 度量）：页底仍是纯黑
    final scrim = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(MiPullUpPanel),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(scrim.color, MiTransparencyTokens.panelScrim);
  });

  testWidgets('明暗：表面随 palette（暗 #2C2C2C / 亮 #FFFFFF）', (tester) async {
    _useCanvas(tester);
    for (final mode in MiThemeMode.values) {
      await tester.pumpWidget(_harness(mode: mode));
      await tester.pumpAndSettle();
      final deco = tester
          .widget<DecoratedBox>(_panel(mode: mode))
          .decoration! as BoxDecoration;
      expect(deco.color, MiPullUpPanelPalette.of(mode).surface);
    }
  });

  testWidgets('宽屏档（1366）：面板限宽 440 居中（推导，沿用弹框宽屏口径）',
      (tester) async {
    _useCanvas(tester, size: const Size(1366, 768));
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final panel = tester.getRect(_panel());
    expect(panel.width, closeTo(440, 0.5));
    expect(panel.center.dx, closeTo(1366 / 2, 0.5));
    expect(768 - panel.bottom, closeTo(90, 0.5));
  });
}
