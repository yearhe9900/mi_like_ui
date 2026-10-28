import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；若导出缺失会在这里暴露。
import 'package:mi_like_ui/mi_like_ui.dart';

/// 可交互测试脚手架：选中态由外部 state 驱动（模拟真实使用方）。
class PillHarness extends StatefulWidget {
  const PillHarness({
    super.key,
    required this.labels,
    required this.themeMode,
  });

  final List<String> labels;
  final MiThemeMode themeMode;

  @override
  State<PillHarness> createState() => _PillHarnessState();
}

class _PillHarnessState extends State<PillHarness> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: widget.themeMode == MiThemeMode.light
            ? const Color(0xFFF3F3F3) // 亮色页底实测 #F3F3F3
            : const Color(0xFF000000), // 暗色页底实测 #000000
        body: Align(
          alignment: Alignment.topCenter,
          child: MiPillTabBar(
            labels: widget.labels,
            selectedIndex: _selected,
            onTap: (i) => setState(() => _selected = i),
            themeMode: widget.themeMode,
          ),
        ),
      ),
    );
  }
}

const List<String> four = ['示例一', '示例二', '示例三', '示例四'];

void main() {
  testWidgets('light pills match the light screenshot palette', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 80 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PillHarness(labels: four, themeMode: MiThemeMode.light));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(find.byType(MiPillTabBar), matchesGoldenFile('goldens/pill_light.png'));
  });

  testWidgets('dark pills match the dark screenshot palette', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 80 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PillHarness(labels: four, themeMode: MiThemeMode.dark));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(find.byType(MiPillTabBar), matchesGoldenFile('goldens/pill_dark.png'));
  });

  testWidgets('tap switches the selected pill', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 80);
    addTearDown(tester.view.reset);

    const light = MiPillTabPalette.light;
    await tester.pumpWidget(const PillHarness(labels: four, themeMode: MiThemeMode.light));

    Color fillOf(String label) {
      final text = tester.widget<Text>(find.text(label));
      // 胶囊 = Text 的上级 AnimatedContainer
      final container = tester.widget<AnimatedContainer>(
        find.ancestor(of: find.text(label), matching: find.byType(AnimatedContainer)),
      );
      final box = container.decoration! as BoxDecoration;
      // 选中态颜色与标签色一致切换
      expect(
        (text.style!.color == light.selectedLabel) == (box.color == light.selectedFill),
        isTrue,
      );
      return box.color!;
    }

    expect(fillOf('示例一'), light.selectedFill);
    expect(fillOf('示例三'), light.unselectedFill);

    await tester.tap(find.text('示例三'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(fillOf('示例一'), light.unselectedFill);
    expect(fillOf('示例三'), light.selectedFill);
  });

  testWidgets('row scrolls when labels overflow the viewport', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 80);
    addTearDown(tester.view.reset);

    const long = ['示例一', '示例二', '示例三', '示例四', '示例五', '示例六'];
    await tester.pumpWidget(const PillHarness(labels: long, themeMode: MiThemeMode.light));
    expect(tester.takeException(), isNull);

    final scrollable = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
    expect(scrollable.scrollDirection, Axis.horizontal);

    // 滚到行尾后能点到最后一个标签
    await tester.drag(find.byType(SingleChildScrollView), const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('示例六'));
    await tester.pump(const Duration(milliseconds: 300));

    const light = MiPillTabPalette.light;
    final container = tester.widget<AnimatedContainer>(
      find.ancestor(of: find.text('示例六'), matching: find.byType(AnimatedContainer)),
    );
    expect((container.decoration! as BoxDecoration).color, light.selectedFill);
  });

  testWidgets('selectedIndex out of range asserts at build', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 80);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiPillTabBar(labels: four, selectedIndex: 4, onTap: (_) {}),
        ),
      ),
    );
    expect(tester.takeException(), isA<AssertionError>());
  });

  test('const construction stays available', () {
    // 构造断言若含 .length / 参数字段求值会封死 const 构造（回归锁）
    const bar = MiPillTabBar(labels: ['a', 'b'], selectedIndex: 1, onTap: _noop);
    expect(bar.labels, hasLength(2));
    expect(bar.selectedIndex, 1);
    expect(bar.itemWidth, MiPillTabMetrics.itemWidth);
  });

  /// 压在内容上时垫**行区玻璃膜带**（issue #4①）：膜是独立一层（同胶囊
  /// 栅格裁形、上下缘羽化），胶囊填充两态同值（不再逐胶囊预合成膜）。
  testWidgets('overContent lays a row veil band under identical fills',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 80);
    addTearDown(tester.view.reset);

    Color fillOf(String label) => (tester
            .widget<AnimatedContainer>(find.ancestor(
                of: find.text(label), matching: find.byType(AnimatedContainer)))
            .decoration! as BoxDecoration)
        .color!;

    for (final mode in MiThemeMode.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: MiPillTabBar(
                labels: four,
                selectedIndex: 0,
                onTap: _noop,
                themeMode: mode,
                overContent: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final palette = MiPillTabPalette.of(mode);
      expect(fillOf(four[0]), palette.selectedFill); // 选中档两态同款
      // 未选填充两态同值（膜不再叠进填充）
      expect(fillOf(four[1]), palette.unselectedFill);

      // 膜带：同胶囊栅格裁形（ClipPath）+ 垂直渐变（两端 veil @0 羽化）
      final band = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MiPillTabBar),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is DecoratedBox &&
                    w.decoration is BoxDecoration &&
                    (w.decoration! as BoxDecoration).gradient != null,
              ),
            )
            .first,
      );
      final gradient = (band.decoration! as BoxDecoration).gradient!
          as LinearGradient;
      expect(gradient.colors[0], MiTransparencyTokens.veilFeatherFor(mode));
      expect(gradient.colors[0].alpha, 0);
      expect(gradient.colors[1], MiTransparencyTokens.veilFor(mode));
      // 羽化高 8dp（推导）→ stop = 8 / 39.9
      expect(
        gradient.stops![1],
        closeTo(MiPillTabMetrics.veilFeatherHeight /
            MiPillTabMetrics.pillHeight, 0.001),
      );
      // 磨砂 + 膜带 = 2 个 ClipPath（同一套栅格）
      expect(find.descendant(
        of: find.byType(MiPillTabBar),
        matching: find.byType(ClipPath),
      ), findsNWidgets(2));
    }

    // 平底页（overContent=false）：无膜带、未选填充仍是低调 6%
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: MiPillTabBar(
              labels: four,
              selectedIndex: 0,
              onTap: _noop,
              themeMode: MiThemeMode.dark,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.descendant(
        of: find.byType(MiPillTabBar),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).gradient != null,
        ),
      ),
      findsNothing,
    );
    expect(
      fillOf(four[1]),
      MiPillTabPalette.of(MiThemeMode.dark).unselectedFill,
    );
  });

  /// 自适应宽度档（issue #3）：clamp(文字自然宽 + 2×16, 87.6, 175.2)；
  /// 行宽 = Σ widths + (n−1)×gap；三遍栅格共用同一宽序列（golden 锁对齐）。
  testWidgets('adaptive widths clamp text + 2×inset into [min, max]',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 80);
    addTearDown(tester.view.reset);

    // 测试字体每字符 advance = 字号 13.85：
    //  1字 = 13.85 + 32 = 45.85 → 鉗到下限 87.6；
    //  6字 = 83.10 + 32 = 115.10；
    //  12字 = 166.2 + 32 = 198.2 → 鉗到上限 175.2。
    const labels = ['短', '六个字的标签', '十二个字的标签示例标签示例'];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: MiPillTabBar(
              labels: labels,
              selectedIndex: 0,
              onTap: _noop,
              themeMode: MiThemeMode.dark,
              itemWidthMode: MiPillItemWidth.adaptive,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    double widthOf(String label) => tester
        .widget<AnimatedContainer>(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        )
        .constraints!
        .maxWidth;
    expect(widthOf(labels[0]), closeTo(87.6, 0.01));
    expect(widthOf(labels[1]), closeTo(115.1, 0.1));
    expect(widthOf(labels[2]), closeTo(175.2, 0.01));

    // 行宽 = Σ widths + 2×gap；超上限标签在胶囊内 ellipsis 截断
    final strip = tester
        .widgetList<SizedBox>(
          find.descendant(
            of: find.byType(MiPillTabBar),
            matching: find.byType(SizedBox),
          ),
        )
        .firstWhere((w) => w.height == MiPillTabMetrics.pillHeight);
    expect(
      strip.width,
      closeTo(87.6 + 115.1 + 175.2 + 2 * MiPillTabMetrics.gap, 0.1),
    );
    expect(
      tester.widget<Text>(find.text(labels[2])).overflow,
      TextOverflow.ellipsis,
    );
  });

  /// 自适应档渲染 golden：填充 / 磨砂裁形 / 内缘亮边三遍对齐同一宽序列。
  testWidgets('adaptive pills render aligned (dark golden)', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 80 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: Align(
            alignment: Alignment.topCenter,
            child: MiPillTabBar(
              labels: const ['短', '六个字的标签', '十二个字的标签示例标签示例'],
              selectedIndex: 0,
              onTap: _noop,
              themeMode: MiThemeMode.dark,
              itemWidthMode: MiPillItemWidth.adaptive,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MiPillTabBar),
      matchesGoldenFile('goldens/pill_adaptive_dark.png'),
    );
  });
}

void _noop(int _) {}
