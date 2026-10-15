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
                labels: const ['示例一', '示例二', '示例三', '示例四'],
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
}
