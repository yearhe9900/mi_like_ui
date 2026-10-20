import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；demo 层直接引示例代码。
import 'package:mi_like_ui/mi_like_ui.dart';
import 'package:mi_like_ui/demo/mock_pages.dart';

/// 首页「搜索栏 + 胶囊按钮的磨砂效果」（2026-10-20 亮/暗完整截图实测形态）。
///
/// 参考图的三条硬事实，这里逐条钉住：
///  1. 搜索栏与胶囊行**悬浮**在高频横幅上（横幅从屏顶 y = 0 起铺）；
///  2. 头部区磨砂是**一整段恒定 σ**，从 y = 0 铺满到栏底（实测 152dp，
///     本 demo = `occupiedHeight` 156dp），往下内容立刻清晰；
///  3. 胶囊行底就是磨砂底 —— 再往下滚进来的横幅 / 卡片是锐利的。
///
/// 这层模糊是**内容区自己的**（`MiTopBar.showBlur` 复用 `MiGradientBlur` 的
/// 分段思路），所以断言写在 demo 层：组件层只保证「一段满宽、σ = token」。
void main() {
  Future<void> pumpHome(WidgetTester tester, MiThemeMode mode) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 856);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: mode == MiThemeMode.dark
            ? ThemeData.dark(useMaterial3: true)
            : ThemeData.light(useMaterial3: true),
        home: Scaffold(body: MockPage(0, themeMode: mode)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder bandBlurs() => find.descendant(
        of: find.byType(MiTopBar),
        matching: find.byType(BackdropFilter),
      );

  testWidgets('横幅铺到屏顶，搜索栏 / 胶囊行由顶栏产出并悬浮其上', (tester) async {
    await pumpHome(tester, MiThemeMode.dark);

    final hero = find.byKey(const ValueKey('homeHero'));
    expect(hero, findsOneWidget);
    final heroRect = tester.getRect(hero);
    expect(heroRect.top, 0, reason: '横幅必须从屏顶（含状态栏后面）起铺');
    expect(heroRect.width, 393, reason: '横幅通栏，不吃页边距');
    expect(heroRect.height, 186, reason: '底缘实测 ≈186dp');

    // 列表**不**给头部让位：横幅与区块一起从头部后方滚过
    expect(
      (tester.widget<ListView>(find.byType(ListView)).padding as EdgeInsets).top,
      0,
      reason: '留给头部让位就没有内容能被磨砂糊到',
    );

    final bar = find.byType(MiTopBar);
    expect(bar, findsOneWidget);
    expect(
      find.descendant(of: bar, matching: find.byType(MiSearchBar)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.byType(MiPillTabBar)),
      findsOneWidget,
    );
    // 页面里没有第二份（顶栏之外不该再 new 一个）
    expect(find.byType(MiSearchBar), findsOneWidget);
    expect(find.byType(MiPillTabBar), findsOneWidget);

    // 悬浮：搜索栏顶 56；胶囊行顶 56 + 44.1 + 16 = 116.1 —— 都在横幅内部
    expect(tester.getTopLeft(find.byType(MiSearchBar)).dy, closeTo(56, 0.01));
    expect(
      tester.getTopLeft(find.byType(MiPillTabBar)).dy,
      closeTo(56 + 44.1 + 16, 0.01),
    );

    // 顶栏整块压在横幅之上（Stack 顺序：列表在前、头部在后）
    expect(find.byType(MiTopBar), findsOneWidget);
  });

  testWidgets('头部区磨砂 = 一整段恒定 σ、0…栏底，胶囊行底即糊／清晰分界', (tester) async {
    for (final mode in MiThemeMode.values) {
      await pumpHome(tester, mode);

      final filters = bandBlurs().evaluate().toList();
      expect(filters, hasLength(1), reason: '$mode：头部区只有一段（恒定 σ）');

      final rect = tester.getRect(bandBlurs());
      expect(rect.left, 0);
      expect(rect.width, 393, reason: '磨砂满宽（含胶囊行两侧的间隙）');
      expect(rect.top, 0, reason: '从屏顶开始糊，状态栏后面一样糊');
      expect(
        rect.height,
        closeTo(156, 0.01),
        reason: '$mode：一直糊到栏底（= 胶囊行底），往下立刻清晰',
      );

      final filter = tester.widget<BackdropFilter>(bandBlurs()).filter;
      const sigma = MiTopBarPalette.blurSigma;
      expect(filter, ImageFilter.blur(sigmaX: sigma, sigmaY: sigma));

      // 胶囊行底 == 磨砂底：两者必须同源，否则会出现「胶囊下面还糊着」的断层
      final pillBottom = tester.getRect(find.byType(MiPillTabBar)).bottom;
      expect(pillBottom, closeTo(rect.bottom, 0.01));
    }
  });

  testWidgets('上滚时头部不动、横幅从它后方经过（磨砂有内容可糊）', (tester) async {
    await pumpHome(tester, MiThemeMode.light);

    final barTop = tester.getTopLeft(find.byType(MiTopBar)).dy;
    final pillTop = tester.getTopLeft(find.byType(MiPillTabBar)).dy;
    final heroTop = tester.getTopLeft(find.byKey(const ValueKey('homeHero'))).dy;

    // 静止态：横幅 0…186 跨越磨砂底（156）—— 上半被糊、下半锐利，一眼可见
    expect(heroTop, 0);
    expect(
      tester.getRect(find.byKey(const ValueKey('homeHero'))).bottom,
      greaterThan(156),
      reason: '横幅必须伸到磨砂带以外，否则看不出「到栏底就清晰」',
    );

    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byType(MiTopBar)).dy, barTop);
    expect(tester.getTopLeft(find.byType(MiPillTabBar)).dy, pillTop);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('homeHero'))).dy,
      lessThan(heroTop),
      reason: '横幅上滚 → 其内容进入头部区，被那层恒定 σ 磨开',
    );
  });
}
