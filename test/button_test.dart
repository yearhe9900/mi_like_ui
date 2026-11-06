import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；若导出缺失会在这里暴露。
import 'package:mi_like_ui/mi_like_ui.dart';

/// MiButton：实测配方（关注按钮明暗同为 #4980F7）、几何（28.3 高、
/// 2 字文案 ≈60 宽）、推导态（tonal / disabled）与点按行为。
void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFF3F3F3), // 亮色页底实测 #F3F3F3
          body: Center(child: child),
        ),
      );

  Color fillOf(WidgetTester tester, String label) {
    final container = tester.widget<AnimatedContainer>(
      find.ancestor(of: find.text(label), matching: find.byType(AnimatedContainer)),
    );
    return (container.decoration! as ShapeDecoration).color!;
  }

  testWidgets('filled button matches the measured follow button', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 200);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(const MiButton(
        label: '关注',
        themeMode: MiThemeMode.dark,
        onPressed: _noop,
      )),
    );
    await tester.pump(const Duration(milliseconds: 300));

    const dark = MiButtonPalette.dark;
    const light = MiButtonPalette.light;
    // 实测 #4980F7：明暗两套配方同值（参考图两色一致）
    expect(dark.filledFill, const Color(0xFF4980F7));
    expect(light.filledFill, dark.filledFill);
    expect(fillOf(tester, '关注'), dark.filledFill);
    expect(dark.filledLabel, Colors.white);

    // 标签 13dp Medium（实测墨高 35px / em≈40px）
    final text = tester.widget<Text>(find.text('关注'));
    expect(text.style!.fontSize, 13);
    expect(text.style!.fontWeight, FontWeight.w500);
    expect(text.style!.color, dark.filledLabel);

    // 几何：高 28.3；宽度 = 文案 + 左右各 17dp（内容自适应胶囊）。
    // 不写死「2×13 + 2×17 = 60」：真实字体下「关注」13dp 两字实测 ≈60 宽，
    // 但本 SDK 测试字体的 CJK 字面 advance ≈1.019em（13dp 两字 = 26.5），
    // 写死 60 会随测试字体度量误报。这里锁的是「内边距 + 收缩到内容」契约。
    final size = tester.getSize(find.byType(MiButton));
    expect(size.height, closeTo(MiButtonMetrics.height, 0.01));
    expect(
      size.width,
      closeTo(
        tester.getSize(find.text('关注')).width +
            2 * MiButtonMetrics.horizontalPadding,
        0.01,
      ),
    );
    expect(size.width, lessThan(393), reason: '宽度必须随内容收缩，不被父级拉满');
  });

  testWidgets('tonal & disabled pick their derived palette', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 200);
    addTearDown(tester.view.reset);

    const light = MiButtonPalette.light;

    await tester.pumpWidget(
      wrap(const MiButton(
        label: '已关注',
        variant: MiButtonVariant.tonal,
        themeMode: MiThemeMode.light,
        onPressed: _noop,
      )),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(fillOf(tester, '已关注'), light.tonalFill);
    expect(tester.widget<Text>(find.text('已关注')).style!.color, light.tonalLabel);

    await tester.pumpWidget(
      wrap(const MiButton(
        label: '关注',
        themeMode: MiThemeMode.light,
        onPressed: _noop,
      )),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(fillOf(tester, '关注'), light.filledFill);

    // onPressed = null → 禁用态配色（推导：onSurface@12% / @38%）
    await tester.pumpWidget(
      wrap(const MiButton(label: '关注', themeMode: MiThemeMode.light, onPressed: null)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(fillOf(tester, '关注'), light.disabledFill);
    expect(tester.widget<Text>(find.text('关注')).style!.color, light.disabledLabel);
  });

  testWidgets('tap fires onPressed', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 200);
    addTearDown(tester.view.reset);

    var taps = 0;
    await tester.pumpWidget(
      wrap(MiButton(label: '关注', onPressed: () => taps++)),
    );
    await tester.tap(find.text('关注'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, 1);
  });

  testWidgets('图标：定尺 16dp、图文间距 6dp，宽度含图标', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 200);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(const MiButton(
        label: '关注',
        icon: Icon(Icons.add),
        themeMode: MiThemeMode.dark,
        onPressed: _noop,
      )),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.getSize(find.byType(Icon)),
      const Size(MiButtonMetrics.iconSize, MiButtonMetrics.iconSize),
    );
    expect(
      tester.getSize(find.byType(MiButton)).width,
      closeTo(
        MiButtonMetrics.iconSize +
            MiButtonMetrics.iconGap +
            tester.getSize(find.text('关注')).width +
            2 * MiButtonMetrics.horizontalPadding,
        0.01,
      ),
    );
  });

  testWidgets('enabled = false：禁用配方且不触发回调', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 200);
    addTearDown(tester.view.reset);

    const light = MiButtonPalette.light;
    var taps = 0;
    await tester.pumpWidget(
      wrap(MiButton(
        label: '关注',
        enabled: false,
        themeMode: MiThemeMode.light,
        onPressed: () => taps++,
      )),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(fillOf(tester, '关注'), light.disabledFill);
    expect(
      tester.widget<Text>(find.text('关注')).style!.color,
      light.disabledLabel,
    );
    await tester.tap(find.text('关注'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, 0);
  });

  testWidgets('minWidth：宽度抬到调用方给的下限', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 200);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(const MiButton(
        label: '确定',
        minWidth: 120,
        themeMode: MiThemeMode.dark,
        onPressed: _noop,
      )),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.getSize(find.byType(MiButton)).width, closeTo(120, 0.01));
    // 高度不因最小宽而变。
    expect(
      tester.getSize(find.byType(MiButton)).height,
      closeTo(MiButtonMetrics.height, 0.01),
    );
  });

  testWidgets('text 形态：无填充 + 强调色标签', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 200);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(const MiButton(
        label: '取消',
        variant: MiButtonVariant.text,
        themeMode: MiThemeMode.light,
        onPressed: _noop,
      )),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(fillOf(tester, '取消'), MiTransparencyTokens.clear);
    expect(tester.widget<Text>(find.text('取消')).style!.color, MiColors.accent);
  });

  testWidgets('large 档：高 40、内边距 20、标签 15dp', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 200);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(const MiButton(
        label: '开始',
        size: MiButtonSize.large,
        themeMode: MiThemeMode.dark,
        onPressed: _noop,
      )),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final size = tester.getSize(find.byType(MiButton));
    expect(size.height, closeTo(MiButtonMetrics.largeHeight, 0.01));
    expect(
      size.width,
      closeTo(
        tester.getSize(find.text('开始')).width +
            2 * MiButtonMetrics.largeHorizontalPadding,
        0.01,
      ),
    );
    expect(
      tester.widget<Text>(find.text('开始')).style!.fontSize,
      MiTypography.buttonLabelLarge.fontSize,
    );
  });

  test('const construction stays available', () {
    const button = MiButton(label: '关注', onPressed: _noop);
    expect(button.label, '关注');
    expect(button.variant, MiButtonVariant.filled);
    // null = 跟随 MiTheme；未声明 MiTheme 时默认深色（行为不变）。
    expect(button.themeMode, isNull);
    expect(button.onPressed, isNotNull);
  });
}

void _noop() {}
