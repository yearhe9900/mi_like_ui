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

  testWidgets('README preview: side nav closeups (dark & light)', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(196 * 2, 236 * 2);
    addTearDown(tester.view.reset);
    await _loadCjkFont(tester);

    // 背景必须是**高频内容**（彩条 + 色块）才能看出磨砂：平坦色在模糊下不变。
    Widget frame(MiThemeMode mode) {
      final ink = MiColors.foregroundFor(mode);
      final items = [
        MiGlassNavItem(label: '首页', painter: RollerIconPainter(ink)),
        MiGlassNavItem(label: '分类', painter: GridSparkleIconPainter(ink)),
        MiGlassNavItem(label: '我的', painter: SmileyBeretIconPainter(ink)),
      ];
      return MaterialApp(
        theme: mode == MiThemeMode.light
            ? ThemeData.light(useMaterial3: true)
            : ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    for (final c in const [
                      Color(0xFF2E3A8C),
                      Color(0xFF7B4DBE),
                      Color(0xFFD06A8A),
                      Color(0xFF00B4DB),
                      Color(0xFF11998E),
                      Color(0xFFFF512F),
                    ])
                      Expanded(child: ColoredBox(color: c)),
                  ],
                ),
              ),
              Center(
                child: MiGlassSideNavBar(
                  items: items,
                  selectedIndex: 0,
                  onTap: (_) {},
                  themeMode: mode,
                ),
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(frame(MiThemeMode.dark));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MiGlassSideNavBar),
      matchesGoldenFile('../doc/preview/nav_side_dark.png'),
    );

    await tester.pumpWidget(frame(MiThemeMode.light));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MiGlassSideNavBar),
      matchesGoldenFile('../doc/preview/nav_side_light.png'),
    );
  });

  testWidgets('README preview: dark & light demo pages', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    // 参考机逻辑尺寸：示例外壳在 393×856 下 1:1 铺满，预览图即完整手机画面
    //（此前 260×470 的窗口会把 393×856 的手机框裁掉一半）。
    tester.view.physicalSize = const Size(393 * 2, 856 * 2);
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

  testWidgets('README preview: adaptive stage across breakpoints', (tester) async {
    addTearDown(tester.view.reset);
    await _loadCjkFont(tester);

    Future<void> capture(
      Size logical,
      String file, {
      bool showcase = false,
      bool light = false,
    }) async {
      // 每次换窗口尺寸都重建 App，避免复用上一档的 State（_index / _tab）。
      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize = logical * 2;
      await tester.pumpWidget(DemoApp(key: UniqueKey()));
      await tester.pumpAndSettle();
      if (showcase) {
        await tester.tap(find.text('分类').last);
        await tester.pumpAndSettle();
      }
      if (light) {
        // 模式切换入口在「我的」页顶部
        await tester.tap(find.text('我的').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
      }
      await expectLater(find.byType(DemoHome), matchesGoldenFile(file));
    }

    // compact：参考机 1:1
    await capture(const Size(393, 856), '../doc/preview/adaptive_phone.png');
    // compact：桌面小窗，整机等比缩小（不再被裁掉一半）
    await capture(
      const Size(260, 470),
      '../doc/preview/adaptive_small_window.png',
    );
    // medium：平板竖屏（实机 1536×2560 @2x → 768×1280），画面铺成内容舞台
    await capture(const Size(768, 1280), '../doc/preview/adaptive_tablet.png');
    // expanded：桌面，画面加宽成内容舞台（主题卡 6 列）
    await capture(
      const Size(1366, 768),
      '../doc/preview/adaptive_desktop.png',
    );
    // expanded：展示位网格 8 列
    await capture(
      const Size(1366, 768),
      '../doc/preview/adaptive_desktop_showcase.png',
      showcase: true,
    );
    // expanded + 浅色：侧栏在浅底上的玻璃体 / 投影（验证无拼接缝）
    await capture(
      const Size(1366, 768),
      '../doc/preview/adaptive_desktop_light.png',
      light: true,
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

    Future<void> capture(
      MiThemeMode mode,
      String file, {
      double scroll = 0,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mode == MiThemeMode.dark
              ? ThemeData.dark(useMaterial3: true)
              : ThemeData.light(useMaterial3: true),
          home: Scaffold(body: MockPage(1, themeMode: mode)),
        ),
      );
      await tester.pumpAndSettle();
      if (scroll > 0) {
        // 卷起来看吸顶头部：网格从搜索栏 / 胶囊行后方经过，整条头部区在
        // 顶栏那条渐进磨砂下一起被磨开（越往上越糊、到栏底渐隐）。
        await tester.drag(find.byType(ListView), Offset(0, -scroll));
        await tester.pumpAndSettle();
      }
      await expectLater(find.byType(MockPage), matchesGoldenFile(file));
    }

    await capture(MiThemeMode.light, '../doc/preview/showcase_light.png');
    await capture(MiThemeMode.dark, '../doc/preview/showcase_dark.png');
    await capture(
      MiThemeMode.light,
      '../doc/preview/showcase_sticky_light.png',
      scroll: 150,
    );
    await capture(
      MiThemeMode.dark,
      '../doc/preview/showcase_sticky_dark.png',
      scroll: 150,
    );
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

  testWidgets('README preview: top bar closeups (material & fold states)', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(393 * 2, 1100 * 2);
    addTearDown(tester.view.reset);
    await _loadCjkFont(tester);

    // 四格形态对照（垂直四等分）：
    //  ① **纯材质形态**（`title` 不传 → 顶栏不内嵌任何组件，与参考录屏
    //     「我的」页同构）：背后是头像 + 昵称，滚动 96dp 后头像进入栏内 ——
    //     直观看到磨砂把它抹开、且越往下越锐利（渐进模糊）；
    //  ② 顶层页「设置」静止态：无返回圆钮、首行是搜索栏 → 内容顶缘 168.5dp；
    //  ③ 次级页「显示与亮度」静止态：带返回圆钮、大标题、首行是卡片 → 183dp；
    //  ④ 同③滚动 105dp：大标题已随内容上移并归零、紧凑标题居中浮现。
    Widget frame(MiThemeMode mode) {
      final light = mode == MiThemeMode.light;
      Widget panel({
        String? title,
        required bool showBack,
        required double shift,
        double topInset = MiTopBarMetrics.contentTopInset,
        Widget? first,
        bool header = false,
      }) =>
          Stack(
            children: [
              Positioned.fill(
                child: _topBarBackdrop(
                  mode,
                  shift,
                  topInset: topInset,
                  first: first,
                  header: header,
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
                child: panel(showBack: false, shift: 96, header: true),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: panel(
                  title: '设置',
                  showBack: false,
                  shift: 0,
                  topInset: MiTopBarMetrics.searchBarTopInset,
                  first: MiSearchBar(hint: '搜索设置项', themeMode: mode),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: panel(title: '显示与亮度', showBack: true, shift: 0),
              ),
              const SizedBox(height: 16),
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

  testWidgets('README preview: home cover (blur of search bar + pills)', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(393 * 2, 856 * 2);
    addTearDown(tester.view.reset);
    await _loadCjkFont(tester);

    Future<void> capture(
      MiThemeMode mode,
      String file, {
      double scroll = 0,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: mode == MiThemeMode.dark
              ? ThemeData.dark(useMaterial3: true)
              : ThemeData.light(useMaterial3: true),
          home: Scaffold(body: MockPage(0, themeMode: mode)),
        ),
      );
      await tester.pumpAndSettle();
      if (scroll > 0) {
        // 用 `jumpTo` 精确控位移：`drag` 会带惯性，落点不可复现（黄金图会抖）
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(scroll);
        await tester.pumpAndSettle();
      }
      await expectLater(find.byType(MockPage), matchesGoldenFile(file));
    }

    // 静止态：横幅 0…186 跨越磨砂底（156）→ 上半糊、下半锐利
    await capture(MiThemeMode.light, '../doc/preview/home_light.png');
    await capture(MiThemeMode.dark, '../doc/preview/home_dark.png');
    // 上滚 20：横幅的草叶（高频）整片压在搜索栏 / 胶囊行后方 —— 磨砂最直观
    // 的一帧（平坦色块在模糊下不变：卡片不行，纹理行）。再多滚 10dp 横幅底缘
    // 就进到胶囊行里，画面会同时出现「被糊的草」和「锐利的页底」，反而费解。
    await capture(
      MiThemeMode.light,
      '../doc/preview/home_scrolled_light.png',
      scroll: 20,
    );
    await capture(
      MiThemeMode.dark,
      '../doc/preview/home_scrolled_dark.png',
      scroll: 20,
    );
  });

  testWidgets('README preview: search state (light & dark)', (tester) async {
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
          home: Scaffold(body: MockPage(0, themeMode: mode)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MiSearchBar));
      // 转场 420ms。**不能用 pumpAndSettle**：输入光标的闪烁是一个不会停的
      // 定时器，settle 会一直等下去。改为只推固定时长 —— 也顺带把光标钉在
      // 「刚点亮」那一相，截图才是确定的。
      await tester.pump();
      // 转场 480ms；再把时间停在 490ms —— 光标闪烁是「亮 500ms / 灭 500ms」，
      // 只有这一小段窗口里既走完转场又能截到光标（超过 500ms 光标就灭了）。
      await tester.pump(const Duration(milliseconds: 490));
      await expectLater(find.byType(MockPage), matchesGoldenFile(file));
    }

    await capture(MiThemeMode.light, '../doc/preview/home_search_light.png');
    await capture(MiThemeMode.dark, '../doc/preview/home_search_dark.png');
  });

  testWidgets('README preview: demo shell in search state', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 856);
    addTearDown(tester.view.reset);
    await _loadCjkFont(tester);

    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MiSearchBar));
    await tester.pump();
    // 同「搜索态」用例：不用 pumpAndSettle（光标闪烁会一直有帧）
    await tester.pump(const Duration(milliseconds: 490));
    await expectLater(
      find.byType(DemoHome),
      matchesGoldenFile('../doc/preview/demo_search_dark.png'),
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

  testWidgets('README preview: dialogs (positions x light & dark)', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(393 * 2, 856 * 2);
    addTearDown(tester.view.reset);
    await _loadCjkFont(tester);

    // 背景放**已知色块**（蓝 #3B6BF5 / 白 #FFFFFF / 灰 #808080）：遮罩是
    // 实心黑 @0.20（亮）/ @0.60（暗），色块透射后应为原色 ×0.8 / ×0.4 ——
    // 预览图直接可量，遮罩 alpha 有据可查。卡片内文按两套参考弹框复刻：
    //  * 「删除联系人」（联系人弹框）：正文 start 对齐两行、取消 + 删除（红字）；
    //  * 「删除1项资源」（主题商店弹框）：正文居中一行、取消 + 确定（蓝底白字）。
    Widget frame(
      MiThemeMode mode, {
      MiDialogPosition position = MiDialogPosition.bottom,
      bool filled = false,
    }) {
      final light = mode == MiThemeMode.light;
      return MaterialApp(
        theme: light
            ? ThemeData.light(useMaterial3: true)
            : ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          backgroundColor: light ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
          body: KeyedSubtree(
            key: const ValueKey('dialogPreview'),
            child: Stack(
              children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11.9, 60, 11.9, 60),
                  child: Column(
                    children: [
                      for (final color in const [
                        Color(0xFF3B6BF5),
                        Color(0xFF808080),
                        Color(0xFF3B6BF5),
                        Color(0xFF808080),
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              // 无 child 的 DecoratedBox 在**松约束**下取
                              // `constraints.smallest`（交叉轴松 → 宽 0）会
                              // 整块隐形；SizedBox.expand 顶满交叉轴。
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: MiDialog(
                  position: position,
                  themeMode: mode,
                  title: filled ? '删除1项资源' : '删除联系人',
                  message: filled
                      ? '确定删除所选的1项资源吗？'
                      : '确定从本地和云端同时删除“方太安装师傅”吗？',
                  messageAlign: filled ? TextAlign.center : TextAlign.start,
                  actions: [
                    const MiDialogAction(label: '取消', onPressed: _noop),
                    MiDialogAction(
                      label: filled ? '确定' : '删除',
                      style: filled
                          ? MiDialogActionStyle.filled
                          : MiDialogActionStyle.destructive,
                      onPressed: _noop,
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      );
    }

    Future<void> capture(
      MiThemeMode mode, {
      MiDialogPosition position = MiDialogPosition.bottom,
      bool filled = false,
      required String file,
    }) async {
      await tester.pumpWidget(
        frame(mode, position: position, filled: filled),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byKey(const ValueKey('dialogPreview')),
        matchesGoldenFile(file),
      );
    }

    // 底部（默认档，实测）：两套参考弹框各明/暗
    await capture(MiThemeMode.dark, file: '../doc/preview/dialog_bottom_dark.png');
    await capture(MiThemeMode.light, file: '../doc/preview/dialog_bottom_light.png');
    await capture(
      MiThemeMode.dark,
      filled: true,
      file: '../doc/preview/dialog_bottom_filled_dark.png',
    );
    await capture(
      MiThemeMode.light,
      filled: true,
      file: '../doc/preview/dialog_bottom_filled_light.png',
    );
    // 顶部 / 居中（推导档）：同「删除联系人」弹框平移
    await capture(
      MiThemeMode.dark,
      position: MiDialogPosition.top,
      file: '../doc/preview/dialog_top_dark.png',
    );
    await capture(
      MiThemeMode.light,
      position: MiDialogPosition.top,
      file: '../doc/preview/dialog_top_light.png',
    );
    await capture(
      MiThemeMode.dark,
      position: MiDialogPosition.center,
      file: '../doc/preview/dialog_center_dark.png',
    );
    await capture(
      MiThemeMode.light,
      position: MiDialogPosition.center,
      file: '../doc/preview/dialog_center_light.png',
    );
  });
}

/// 弹框预览的空回调（预览不接行为）。
void _noop() {}

/// 顶栏预览的背景内容：设置页行卡（参考页配色），按 [shift] 上移模拟滚动。
///
/// 行卡只是**预览用的 mock 内容**（非框架组件）：首行顶缘取实测 [topInset]
/// （静止态与对应参考页同构）、行距取参考页实测 53.2dp、饱和蓝 #3B6BF5
/// 最能显形叠色的亮度斜坡。[first] 可换掉首行（顶层页是搜索栏，
/// 用框架组件 [MiSearchBar] 顶替第一张行卡）。
///
/// [header] 在行卡之上加一屏"头像 + 昵称"（复刻亮色「我的」页的页头，静止态
/// 位于 110…170dp）：它同时是**磨砂的判据内容** —— 平坦色块在模糊下不变，
/// 只有这种高频内容才能看出"有没有糊"。第一格预览把 [shift] 拉到 96dp，
/// 让头像滑进栏内，直接看到它被抹开、且越往下越锐利。
///
/// 逐行用 `Positioned` 摆进 `Stack`（而不是 `Column` + `Transform`）：这些
/// 行天然比面板高（首行顶缘 168.5/183 + 5 行 257 ≫ 面板 263），`Column`
/// 会报 RenderFlex 溢出，`Stack` 只按自身边界裁剪、不报错；滚动位移直接
/// 并进每行 `top`，连 `Transform` 都省了。
Widget _topBarBackdrop(
  MiThemeMode mode,
  double shift, {
  double topInset = MiTopBarMetrics.contentTopInset,
  Widget? first,
  bool header = false,
}) {
  final light = mode == MiThemeMode.light;
  final neutral = light ? const Color(0xFFFFFFFF) : const Color(0xFF242424);
  final fg = light ? const Color(0xFF2E2E2E) : const Color(0xFFE8E8E8);
  final sub = light ? const Color(0xFF9A9A9A) : const Color(0xFF8A8A8A);
  final rows = <Widget>[];
  if (header) {
    // 页头静止位置 110…170dp（参考录屏「我的」页实测），头像 ⌀60。
    final hy = 110 - shift;
    rows.add(
      Positioned(
        left: 19.9,
        top: hy,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C8B6B), Color(0xFF3E4A33)],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 118, height: 18, color: fg),
                const SizedBox(height: 8),
                Container(width: 156, height: 12, color: sub),
              ],
            ),
          ],
        ),
      ),
    );
  }
  var y = topInset - shift;
  if (first != null) {
    rows.add(Positioned(left: 11.9, right: 11.9, top: y, child: first));
    y += MiSearchBarMetrics.barHeight + 12;
  }
  for (final color in <Color>[
    const Color(0xFF3B6BF5),
    const Color(0xFF3B6BF5),
    neutral,
    neutral,
    neutral,
  ]) {
    rows.add(
      Positioned(
        left: 11.9, // 参考页实测内容边距
        right: 11.9,
        top: y,
        height: 44,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
    y += 53.2; // 实测行距（行高 44 + 间隙 9.2）
  }
  return Stack(children: rows);
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
