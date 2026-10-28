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
  MiPullUpPanelController? controller,
  VoidCallback? onDismissed,
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
        controller: controller,
        onDismissed: onDismissed,
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
          w.decoration is ShapeDecoration &&
          (w.decoration! as ShapeDecoration).color ==
              MiPullUpPanelPalette.of(mode).surface &&
          (w.decoration! as ShapeDecoration).shape is MiSquircleBorder,
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
    // 弹簧拟合：ζ = 26 / 2√260 = 0.807 → 过冲 ~1.4%（真身已迁
    // MiMotionTokens，拟合档案见彼处；此处确认面板弹簧未被改动）
    const spring = MiMotionTokens.panelExpand;
    expect(spring.stiffness, 260);
    expect(spring.damping, 26);
    expect(
      spring.damping /
          (2 * math.sqrt(spring.stiffness * spring.mass)),
      closeTo(0.807, 0.001),
    );
    // 面板宽 / 可用高
    expect(MiPullUpPanelMetrics.panelWidthFor(393), closeTo(345, 0.01));
    expect(MiPullUpPanelMetrics.panelWidthFor(1366), 440);
    expect(MiPullUpPanelMetrics.maxHeightFor(856, 0), 856 - 24 - 90);
    // 配色：暗 #2C2C2C / 亮 #FFFFFF（两段素材分别度量）；遮罩无压暗（透明）
    expect(MiPullUpPanelPalette.dark.surface, const Color(0xFF2C2C2C));
    expect(MiPullUpPanelPalette.light.surface, const Color(0xFFFFFFFF));
    expect(MiTransparencyTokens.panelScrim.alpha, 0);
    // 投影（浅色度量拟合：黑 @0.12、blur 14、下偏 4）
    expect(MiTransparencyTokens.panelShadow.alpha, closeTo(0.12 * 255, 0.5));
    expect(MiPullUpPanelMetrics.shadowBlurRadius, 14.0);
    expect(MiPullUpPanelMetrics.shadowOffsetY, 4.0);
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

    final deco = tester.widget<DecoratedBox>(_panel()).decoration! as ShapeDecoration;
    expect(
      (deco.shape as MiSquircleBorder).cornerRadius,
      closeTo(33.0, 0.01),
    );
    // 轻投影（度量拟合）：黑 @0.12、blur 14、下偏 4 —— ShapeDecoration 不带
    // boxShadow，投影由 MiSquircleShadowPainter 垫在面板底层
    final painter = tester
        .widget<CustomPaint>(
          find.ancestor(of: _panel(), matching: find.byType(CustomPaint)).first,
        )
        .painter as MiSquircleShadowPainter;
    final shadow = painter.shadows.single;
    expect(shadow.color, MiTransparencyTokens.panelShadow);
    expect(shadow.blurRadius, closeTo(14.0, 0.01));
    expect(shadow.offset, const Offset(0, 4.0));
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

  testWidgets('行为：面板外点按播收回动画（反向弹簧 + 淡出）后回调 onDismissed',
      (tester) async {
    _useCanvas(tester);
    var dismissed = 0;
    await tester.pumpWidget(_harness(
      onDismissed: () => dismissed++,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => fail('内容不该被点到'),
        child: const SizedBox(width: double.infinity, height: 240),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.getRect(_panel()).width, closeTo(345, 0.5));

    // 面板外点按 → 立即开始收回，**不**立刻回调（要等动画收口）
    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    expect(dismissed, 0);

    // 中途：宽度在缩、淡出进度 <1（反向弹簧 + 线性淡出）
    await tester.pump(const Duration(milliseconds: 40));
    final midW = tester.getRect(_panel()).width;
    expect(midW, lessThan(320), reason: '收回中（~0.19s 临界阻尼）');
    final fade = tester.widget<Opacity>(
      find
          .descendant(of: find.byType(MiPullUpPanel), matching: find.byType(Opacity))
          .first,
    );
    expect(fade.opacity, lessThan(1.0), reason: '随进度线性淡出');

    // 收口 → 回调；面板缩回起点尺寸（按钮直径 54.1）
    await tester.pumpAndSettle();
    expect(dismissed, 1);
    expect(tester.getRect(_panel()).width, closeTo(54.1, 1.0));
  });

  testWidgets('行为：面板内点按命中内容（缩放后的命中变换）', (tester) async {
    _useCanvas(tester);
    var contentTapped = 0;
    await tester.pumpWidget(_harness(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => contentTapped++,
        child: const SizedBox(width: double.infinity, height: 240),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tapAt(tester.getCenter(_panel()));
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

  testWidgets('控制器：controller.dismiss() 播收回动画并在收口回调', (tester) async {
    _useCanvas(tester);
    final controller = MiPullUpPanelController();
    var dismissed = 0;
    await tester.pumpWidget(_harness(
      controller: controller,
      onDismissed: () => dismissed++,
    ));
    await tester.pumpAndSettle();
    expect(controller.isVisible, isTrue);

    controller.dismiss();
    await tester.pump();
    expect(dismissed, 0);
    await tester.pumpAndSettle();
    expect(dismissed, 1);
    // 收口后组件仍在（由宿主决定何时卸载），控制器仍在挂载期间可用
    expect(controller.isVisible, isTrue);
  });

  testWidgets('明暗：表面随 palette（暗 #2C2C2C / 亮 #FFFFFF）', (tester) async {
    _useCanvas(tester);
    for (final mode in MiThemeMode.values) {
      await tester.pumpWidget(_harness(mode: mode));
      await tester.pumpAndSettle();
      final deco = tester
          .widget<DecoratedBox>(_panel(mode: mode))
          .decoration! as ShapeDecoration;
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
