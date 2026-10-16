import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；demo 层直接引示例代码。
import 'package:mi_like_ui/mi_like_ui.dart';
import 'package:mi_like_ui/demo/demo_app.dart';
import 'package:mi_like_ui/demo/mock_pages.dart';

/// README 预览图生成器（不是回归测试）。
///
/// 黄金图测试环境无 CJK 字体（标签渲染为方框），README 展示图需要真实
/// 文字——这里加载 Windows 中文字体后按明/暗两套样式截图到 `doc/preview/`。
///
/// 重新生成：`flutter test --update-goldens test/preview_capture_test.dart`
/// （本机无中文字体时跳过加载，图会退化为方框标签）。
Future<void> _loadCjkFont(WidgetTester tester) async {
  final file = File(r'C:\Windows\Fonts\simhei.ttf');
  if (!file.existsSync()) return;
  final bytes = file.readAsBytesSync();
  final loader = FontLoader('Roboto')
    ..addFont(Future<ByteData>.value(bytes.buffer.asByteData()));
  await tester.runAsync(loader.load);
}

/// 导航栏特写帧：渐变/卡片背景 + 3 tab + 预留空位圆钮（首页选中）。
Widget _barFrame(MiThemeMode mode) {
  final light = mode == MiThemeMode.light;
  final ink = MiColors.foregroundFor(mode);
  final items = [
    MiGlassNavItem(label: '首页', painter: RollerIconPainter(ink)),
    MiGlassNavItem(label: '分类', painter: GridSparkleIconPainter(ink)),
    MiGlassNavItem(label: '我的', painter: SmileyBeretIconPainter(ink)),
  ];
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: light
                // 浅色：近白底 + 三张彩色卡（与亮色黄金图同构）
                ? Container(
                    color: const Color(0xFFF7F7F7),
                    padding: const EdgeInsets.fromLTRB(20, 120, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: Container(color: const Color(0xFF3C3C40))),
                        const SizedBox(width: 12),
                        Expanded(child: Container(color: const Color(0xFFB9C2CC))),
                        const SizedBox(width: 12),
                        Expanded(child: Container(color: const Color(0xFF6E8FE0))),
                      ],
                    ),
                  )
                // 深色：紫粉渐变（与暗色黄金图同构）
                : const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF3A2352), Color(0xFFC4567A), Color(0xFF2A1220)],
                      ),
                    ),
                  ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24.2,
            child: MiGlassNavBar(
              items: items,
              selectedIndex: 0,
              onTap: (_) {},
              themeMode: mode,
              fab: MiGlassNavFab(
                tabIndex: 0,
                child: CustomPaint(
                  painter: GridDotsIconPainter(const Color(0xFFFFFFFF)),
                  size: const Size.square(18.2),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('README preview: dark & light bar closeups', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(393 * 2, 160 * 2);
    addTearDown(tester.view.reset);
    await _loadCjkFont(tester);

    await tester.pumpWidget(_barFrame(MiThemeMode.dark));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MiGlassNavBar),
      matchesGoldenFile('../doc/preview/nav_dark.png'),
    );

    await tester.pumpWidget(_barFrame(MiThemeMode.light));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MiGlassNavBar),
      matchesGoldenFile('../doc/preview/nav_light.png'),
    );
  });

  testWidgets('README preview: dark & light demo pages', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(520, 940);
    addTearDown(tester.view.reset);
    await _loadCjkFont(tester);

    // 深色：进「我的」页（模式切换卡片 + 内容卡）
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(DemoHome),
      matchesGoldenFile('../doc/preview/demo_dark.png'),
    );

    // 浅色：同页切模式
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(DemoHome),
      matchesGoldenFile('../doc/preview/demo_light.png'),
    );
  });

  testWidgets('README preview: pill tab closeups (light & dark)', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(393 * 2, 96 * 2);
    addTearDown(tester.view.reset);
    await _loadCjkFont(tester);

    // 胶囊条特写（页底 = 分类页实测底色）
    Widget strip(MiThemeMode mode) => MaterialApp(
          home: Scaffold(
            backgroundColor: mode == MiThemeMode.light
                ? const Color(0xFFF3F3F3)
                : const Color(0xFF000000),
            body: Align(
              alignment: Alignment.topCenter,
              child: MiPillTabBar(
                labels: const ['Logo 展示', '按钮展示', '示例三', '示例四'],
                selectedIndex: 0,
                onTap: (_) {},
                themeMode: mode,
              ),
            ),
          ),
        );

    await tester.pumpWidget(strip(MiThemeMode.light));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MiPillTabBar),
      matchesGoldenFile('../doc/preview/pill_light.png'),
    );

    await tester.pumpWidget(strip(MiThemeMode.dark));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MiPillTabBar),
      matchesGoldenFile('../doc/preview/pill_dark.png'),
    );
  });

  testWidgets('README preview: showcase page (light & dark)', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(393 * 2, 856 * 2);
    addTearDown(tester.view.reset);
    await _loadCjkFont(tester);

    Future<void> capture(MiThemeMode mode, String file) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mode == MiThemeMode.dark
              ? ThemeData.dark(useMaterial3: true)
              : ThemeData.light(useMaterial3: true),
          home: Scaffold(body: MockPage(1, themeMode: mode)),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(MockPage), matchesGoldenFile(file));
    }

    await capture(MiThemeMode.light, '../doc/preview/showcase_light.png');
    await capture(MiThemeMode.dark, '../doc/preview/showcase_dark.png');
  });

  testWidgets('README preview: button closeups (light & dark)', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(393 * 2, 132 * 2);
    addTearDown(tester.view.reset);
    await _loadCjkFont(tester);

    // 按钮特写（页底 = 「我的关注」页实测底色，三态：主 / 次级 / 禁用）
    Widget strip(MiThemeMode mode) {
      final light = mode == MiThemeMode.light;
      return MaterialApp(
        theme: light
            ? ThemeData.light(useMaterial3: true)
            : ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          backgroundColor: light ? const Color(0xFFF3F3F3) : const Color(0xFF000000),
          body: Center(
            child: Column(
              key: const ValueKey('buttonStrip'),
              mainAxisSize: MainAxisSize.min,
              children: [
                MiButton(label: '关注', themeMode: mode, onPressed: () {}),
                const SizedBox(height: 12),
                MiButton(
                  label: '已关注',
                  variant: MiButtonVariant.tonal,
                  themeMode: mode,
                ),
                const SizedBox(height: 12),
                MiButton(label: '关注', themeMode: mode, onPressed: null),
              ],
            ),
          ),
        ),
      );
    }

    final stripFinder = find.byKey(const ValueKey('buttonStrip'));

    await tester.pumpWidget(strip(MiThemeMode.light));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(MiButton), findsNWidgets(3));
    await expectLater(stripFinder, matchesGoldenFile('../doc/preview/button_light.png'));

    await tester.pumpWidget(strip(MiThemeMode.dark));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(stripFinder, matchesGoldenFile('../doc/preview/button_dark.png'));
  });

  testWidgets('README preview: top bar closeups (top-level & secondary)', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(393 * 2, 744 * 2);
    addTearDown(tester.view.reset);
    await _loadCjkFont(tester);

    // 三格形态对照（每格逻辑高 240）：
    //  ① 顶层页「设置」= **默认形态**（`showBack` 不传 → 无返回圆钮）：首行是
    //     搜索栏 → 内容顶缘实测 168.5dp；
    //  ② 次级页「显示与亮度」= `showBack: true`（带返回圆钮）：首行是卡片 →
    //     内容顶缘实测 183dp，与参考录屏同构；
    //  ③ 同②但滚动 105dp：大标题已随内容上移并归零、紧凑标题居中浮现，内容
    //     穿到遮罩里 —— 直接看到「实心段 + 1.5 次幂渐隐裙边」，并佐证它没有
    //     磨砂（卡片在裙边内是亮度斜坡 + 硬边，不是模糊拖尾）。
    Widget frame(MiThemeMode mode) {
      final light = mode == MiThemeMode.light;
      Widget panel({
        required String title,
        required bool showBack,
        required double shift,
        double topInset = MiTopBarMetrics.contentTopInset,
        Widget? first,
      }) =>
          Stack(
            children: [
              Positioned.fill(
                child: _topBarBackdrop(
                  mode,
                  shift,
                  topInset: topInset,
                  first: first,
                ),
              ),
              // 与 demo 同样用 Positioned 钉顶（顶栏若作非定位子级，外层
              // Stack 会按它收缩而不是撑满）
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: MiTopBar(
                  title: title,
                  showBack: showBack,
                  scrollOffset: shift,
                  themeMode: mode,
                  onBack: () {},
                ),
              ),
            ],
          );
      return MaterialApp(
        theme: light
            ? ThemeData.light(useMaterial3: true)
            : ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          backgroundColor:
              light ? const Color(0xFFF3F3F3) : const Color(0xFF000000),
          body: Column(
            key: const ValueKey('topBarPreview'),
            children: [
              Expanded(
                child: panel(
                  title: '设置',
                  showBack: false,
                  shift: 0,
                  topInset: MiTopBarMetrics.searchBarTopInset,
                  first: MiSearchBar(hint: '搜索设置项', themeMode: mode),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: panel(title: '显示与亮度', showBack: true, shift: 0),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: panel(title: '显示与亮度', showBack: true, shift: 105),
              ),
            ],
          ),
        ),
      );
    }

    final preview = find.byKey(const ValueKey('topBarPreview'));

    await tester.pumpWidget(frame(MiThemeMode.light));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      preview,
      matchesGoldenFile('../doc/preview/top_bar_light.png'),
    );

    await tester.pumpWidget(frame(MiThemeMode.dark));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      preview,
      matchesGoldenFile('../doc/preview/top_bar_dark.png'),
    );
  });

  testWidgets('README preview: theme card closeups (light & dark)', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(393 * 2, 264 * 2);
    addTearDown(tester.view.reset);
    await _loadCjkFont(tester);

    // 主题卡特写（页底 = 首页实测底色；3 列实测壁纸主色渐变占位）
    Widget frame(MiThemeMode mode) => MaterialApp(
          theme: mode == MiThemeMode.light
              ? ThemeData.light(useMaterial3: true)
              : ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            backgroundColor: mode == MiThemeMode.light
                ? const Color(0xFFF3F3F3)
                : const Color(0xFF000000),
            body: Padding(
              padding: const EdgeInsets.fromLTRB(11.9, 20, 11.9, 0),
              child: Row(
                key: const ValueKey('cardStrip'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0)
                      const SizedBox(width: MiThemeCardMetrics.columnGap),
                    Expanded(child: _previewCard(i)),
                  ],
                ],
              ),
            ),
          ),
        );

    final strip = find.byKey(const ValueKey('cardStrip'));

    await tester.pumpWidget(frame(MiThemeMode.light));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      strip,
      matchesGoldenFile('../doc/preview/card_light.png'),
    );

    await tester.pumpWidget(frame(MiThemeMode.dark));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      strip,
      matchesGoldenFile('../doc/preview/card_dark.png'),
    );
  });
}

/// 顶栏预览的背景内容：设置页行卡（参考页配色），按 [shift] 上移模拟滚动。
///
/// 行卡只是**预览用的 mock 内容**（非框架组件）：首行顶缘取实测
/// [topInset]（静止态与对应参考页同构）、行距取参考页实测 53.2dp、饱和蓝
/// #3B6BF5 最能显形遮罩的亮度斜坡。[first] 可换掉首行（顶层页是搜索栏，
/// 用框架组件 [MiSearchBar] 顶替第一张行卡）。
Widget _topBarBackdrop(
  MiThemeMode mode,
  double shift, {
  double topInset = MiTopBarMetrics.contentTopInset,
  Widget? first,
}) {
  final light = mode == MiThemeMode.light;
  final neutral = light ? const Color(0xFFFFFFFF) : const Color(0xFF242424);
  Widget row(Color color) => Container(
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      );
  return ClipRect(
    child: Transform.translate(
      offset: Offset(0, -shift),
      child: Padding(
        // 左右 11.9 = 参考页实测内容边距
        padding: EdgeInsets.fromLTRB(11.9, topInset, 11.9, 0),
        child: Column(
          children: [
            if (first != null) ...[first, const SizedBox(height: 12)],
            row(const Color(0xFF3B6BF5)),
            const SizedBox(height: 9.2), // 行距 53.2 实测
            row(const Color(0xFF3B6BF5)),
            const SizedBox(height: 9.2),
            row(neutral),
            const SizedBox(height: 9.2),
            row(neutral),
            const SizedBox(height: 9.2),
            row(neutral),
          ],
        ),
      ),
    ),
  );
}

/// 主题卡特写的 3 张占位卡（实测壁纸主色渐变 + 示例标题）。
const List<String> _cardPreviewTitles = ['雾林晨光', '落日熔金', '云端暮色'];
const List<List<Color>> _cardPreviewWallpapers = [
  [Color(0xFF6A7A61), Color(0xFF587132)],
  [Color(0xFF918D80), Color(0xFF746656)],
  [Color(0xFFB6B9C4), Color(0xFF8E7377)],
];

Widget _previewCard(int i) => MiThemeCard(
      title: _cardPreviewTitles[i],
      preview: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _cardPreviewWallpapers[i],
          ),
        ),
      ),
    );
