import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；若导出缺失会在这里暴露。
import 'package:mi_like_ui/mi_like_ui.dart';

/// 黄金图脚手架：3 列卡片按参考网格排布（页边距 / 列距取实测 11.9）。
class CardGridHarness extends StatelessWidget {
  const CardGridHarness({super.key, required this.mode});

  final MiThemeMode mode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: mode == MiThemeMode.light
          ? ThemeData.light(useMaterial3: true)
          : ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: mode == MiThemeMode.light
            ? const Color(0xFFF3F3F3) // 亮色页底实测 #F3F3F3
            : const Color(0xFF000000), // 暗色页底实测 #000000
        body: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11.9, 20, 11.9, 0),
            child: Row(
              key: const ValueKey('cardGrid'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < titles.length; i++) ...[
                  if (i > 0) const SizedBox(width: MiThemeCardMetrics.columnGap),
                  Expanded(child: card(i)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 单卡脚手架：定宽 115.5（实测 3 列卡宽），供几何断言。
class CardSoloHarness extends StatelessWidget {
  const CardSoloHarness({super.key, required this.mode});

  final MiThemeMode mode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: mode == MiThemeMode.light
          ? ThemeData.light(useMaterial3: true)
          : ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: mode == MiThemeMode.light
            ? const Color(0xFFF3F3F3)
            : const Color(0xFF000000),
        body: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            child: SizedBox(width: 115.5, child: card(0)),
          ),
        ),
      ),
    );
  }
}

const List<String> titles = ['雾林晨光', '落日熔金', '云端暮色'];

/// 实测壁纸主色渐变占位（同 demo 首卡组）。
const List<List<Color>> wallpapers = [
  [Color(0xFF6A7A61), Color(0xFF587132)],
  [Color(0xFF918D80), Color(0xFF746656)],
  [Color(0xFFB6B9C4), Color(0xFF8E7377)],
];

Widget card(int i, {MiThemeMode? mode, VoidCallback? onTap}) => MiThemeCard(
      title: titles[i],
      themeMode: mode,
      onTap: onTap,
      preview: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: wallpapers[i],
          ),
        ),
      ),
    );

void main() {
  testWidgets('light cards match the light screenshot palette', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 264 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CardGridHarness(mode: MiThemeMode.light));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byKey(const ValueKey('cardGrid')),
      matchesGoldenFile('goldens/theme_card_light.png'),
    );
  });

  testWidgets('dark cards match the dark palette', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393 * 3, 264 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CardGridHarness(mode: MiThemeMode.dark));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byKey(const ValueKey('cardGrid')),
      matchesGoldenFile('goldens/theme_card_dark.png'),
    );
  });

  testWidgets('geometry matches the measured values', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CardSoloHarness(mode: MiThemeMode.dark));
    await tester.pump(const Duration(milliseconds: 300));

    // 图区按实测宽高比定高（宽 115.5 → 高 ≈210.6）
    final image = tester.getRect(find.byType(AspectRatio));
    expect(image.width, closeTo(115.5, 0.01));
    expect(
      image.width / image.height,
      closeTo(MiThemeCardMetrics.imageAspectRatio, 1e-6),
    );
    expect(image.height, closeTo(210.6, 0.5));

    // 预览内容铺满图区（AspectRatio 给子级 tight 约束）
    final preview = tester.getRect(find.byType(DecoratedBox));
    expect(preview.left, closeTo(image.left, 0.01));
    expect(preview.top, closeTo(image.top, 0.01));
    expect(preview.width, closeTo(image.width, 0.01));
    expect(preview.height, closeTo(image.height, 0.01));

    // 标题左对齐 + 实测内缩 / 图→题实测间距
    final title = tester.getRect(find.text(titles[0]));
    expect(
      title.left - image.left,
      closeTo(MiThemeCardMetrics.titleIndent, 0.5),
    );
    expect(
      title.top - image.bottom,
      closeTo(MiThemeCardMetrics.titleTopGap, 0.5),
    );
  });

  testWidgets('title style follows the screenshot measurements', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CardSoloHarness(mode: MiThemeMode.light));
    await tester.pump(const Duration(milliseconds: 300));

    final text = tester.widget<Text>(find.text(titles[0]));
    // 13.85dp Medium 单行省略（pitch 31px 实测）
    expect(text.style!.fontSize, 13.85);
    expect(text.style!.fontWeight, FontWeight.w500);
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    // 浅色墨色 = 框架前景色近黑（截图最暗值 0）
    expect(text.style!.color, MiColors.foregroundFor(MiThemeMode.light));
  });

  testWidgets('themeMode falls back to ambient brightness', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 400);
    addTearDown(tester.view.reset);

    // 浅色环境下未传 themeMode → 跟随环境取近黑
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(body: SizedBox(width: 115.5, child: card(0))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.widget<Text>(find.text(titles[0])).style!.color,
      MiColors.foregroundLight,
    );

    // 显式 dark 覆盖环境 → 近白
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(
          body: SizedBox(width: 115.5, child: card(0, mode: MiThemeMode.dark)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.widget<Text>(find.text(titles[0])).style!.color,
      MiColors.foreground,
    );
  });

  testWidgets('tap fires onTap for the whole card', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 400);
    addTearDown(tester.view.reset);

    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 115.5,
              child: card(0, onTap: () => taps++),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // 点标题（卡内任意位置）即触发
    await tester.tap(find.text(titles[0]));
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, 1);

    // 点图区同样触发（opaque 手势覆盖整卡）
    final image = tester.getRect(find.byType(AspectRatio));
    await tester.tapAt(image.center);
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, 2);
  });

  test('const construction stays available', () {
    // 构造保持 const（无 .length / 字段求值断言的回归锁）
    const cardConst = MiThemeCard(title: 'a', preview: FlutterLogo());
    expect(cardConst.title, 'a');
    expect(cardConst.onTap, isNull);
    expect(cardConst.themeMode, isNull);
    expect(
      MiThemeCardMetrics.imageAspectRatio,
      closeTo(259 / 472, 1e-12),
    );
  });
}
