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
}

void _noop(int _) {}
