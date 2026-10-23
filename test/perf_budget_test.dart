import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_like_ui/mi_like_ui.dart';
import 'package:mi_like_ui/demo/demo_app.dart';

/// 每帧模糊预算回归。
///
/// `BackdropFilter` 是每帧都要重算的全 QUAD 高斯：滚动时 backdrop 一变就得重新
/// 模糊，帧预算里最贵的一块。这里把「一次 build 里的模糊层数 + 覆盖面积 dp²」
/// 钉成阈值 —— 面积按 **dp²** 计（与 dpr 无关），守住 2026-10-17 这轮优化的
/// 成果，防止以后改回「8 段全画」或给每个胶囊各挂一个 filter。
///
/// 另外锁住两条**零视觉差异**的省帧规则：
///  1. 深色顶栏在叠色完全不透明段（0…63.6dp，α = 1.000 纯黑）之内不画模糊；
///  2. σ 固定的 filter 走缓存复用（同一 σ 拿到的 `ImageFilter` 是同一实例）。
///
/// 2026-10-20 起头部区形态（搜索栏 + 胶囊行）改成**一整段恒定 σ** 铺满整条栏
/// （首页亮/暗截图实测，见 `MiTopBar.uniformBlurBands`）：层数 7 → 2
///（栏 + 导航），面积反而上升 —— 恒定 σ 意味着整条栏都要算，不像渐进曲线那样
/// 尾部几段被剔除。**一次大 filter 比多次小 filter 便宜**（每次都是一趟全 QUAD
/// 高斯 + 一个 saveLayer），所以总成本仍是下降的，但面积阈值要按新形态重标。
class _BlurStat {
  const _BlurStat(this.count, this.area);

  final int count;
  final double area;

  @override
  String toString() =>
      'filters=$count, area=${area.toStringAsFixed(0)}dp²';
}

void main() {
  Future<_BlurStat> measure(
    WidgetTester tester,
    Size window, {
    String tab = '首页',
  }) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = window * 2;
    await tester.pumpWidget(DemoApp(key: UniqueKey()));
    await tester.pumpAndSettle();
    if (tab != '首页') {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
    }
    final filters = find.byType(BackdropFilter).evaluate().toList();
    var area = 0.0;
    for (final e in filters) {
      final box = e.renderObject! as RenderBox;
      area += box.size.width * box.size.height;
    }
    return _BlurStat(filters.length, area);
  }

  testWidgets('深色·平板 768×1280：每帧模糊层数 / 面积预算', (tester) async {
    addTearDown(tester.view.reset);

    // 2026-10-18 起平板：铺满窗口（768，无外围卡片）+ 用侧栏（导航断点 600，
    // 照 MReader）→ 页面列 647.1，顶栏磨砂比"卡片舞台"时代（720−48）宽一档。
    // 首页 = 头部区形态（悬浮搜索栏 + 胶囊行压在高频横幅上）：**1 段恒定 σ**
    // 覆盖 0…156dp（未压色，无从省起的整栏模糊）+ 侧栏 1 层 = 2 层。
    final home = await measure(tester, const Size(768, 1280));
    expect(home.count, lessThanOrEqualTo(3), reason: '首页 $home');
    expect(home.area, lessThanOrEqualTo(122000), reason: '首页 $home');

    // 分类页同一形态（搜索栏 + 胶囊行吸顶、无压色）→ 与首页同预算。
    final showcase = await measure(tester, const Size(768, 1280), tab: '分类');
    expect(showcase.count, lessThanOrEqualTo(3), reason: '分类页 $showcase');
    expect(showcase.area, lessThanOrEqualTo(122000), reason: '分类页 $showcase');

    final mine = await measure(tester, const Size(768, 1280), tab: '我的');
    expect(mine.count, lessThanOrEqualTo(6), reason: '我的 $mine');
    expect(mine.area, lessThanOrEqualTo(55000), reason: '我的 $mine');
  });

  testWidgets('深色·手机 393×856：模糊层数 / 面积预算', (tester) async {
    addTearDown(tester.view.reset);
    // 手机档：头部区 1 段（393 × 156 = 61,308）+ 底栏 1 层
    final phone = await measure(tester, const Size(393, 856));
    expect(phone.count, lessThanOrEqualTo(3), reason: '首页 $phone');
    expect(phone.area, lessThanOrEqualTo(78000), reason: '首页 $phone');
  });

  testWidgets('深色·桌面 1366×768：侧栏只多一层模糊', (tester) async {
    addTearDown(tester.view.reset);
    // 桌面档：铺满窗口（1366）+ 侧栏 → 内容列**限宽 1120**（`MiContentColumn`），
    // 头部区那一段 1120 × 156 = 174,720 + 侧栏 16,896 = 191,616dp²，仍只有 2 层。
    // 限宽把"面积随窗口线性增长"截断了：1366 宽时比不加限宽（1245.1 × 156）
    // 少 ~19,500dp²，再宽的窗口也不会继续涨。
    final desktop = await measure(tester, const Size(1366, 768));
    expect(desktop.count, lessThanOrEqualTo(3), reason: '桌面 $desktop');
    expect(desktop.area, lessThanOrEqualTo(196000), reason: '桌面 $desktop');

    // 分类页同一形态 → 同预算
    final showcase = await measure(tester, const Size(1366, 768), tab: '分类');
    expect(showcase.count, lessThanOrEqualTo(3), reason: '桌面分类 $showcase');
    expect(showcase.area, lessThanOrEqualTo(196000), reason: '桌面分类 $showcase');
  });

  testWidgets('深色顶栏：不透明叠色段内不绘制模糊', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(768 * 2, 1280 * 2);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(body: MiTopBar(title: '我的', scrollOffset: 0)),
      ),
    );
    await tester.pumpAndSettle();

    final barTop = tester.getTopLeft(find.byType(MiTopBar)).dy;
    final filters = find.descendant(
      of: find.byType(MiTopBar),
      matching: find.byType(BackdropFilter),
    );
    expect(filters, findsWidgets);
    for (final element in filters.evaluate()) {
      final top = (element.renderObject! as RenderBox)
              .localToGlobal(Offset.zero)
              .dy -
          barTop;
      // 深色配方的叠色在 0…63.6dp 是 α = 1.000 的纯黑，其下的模糊 100% 不可见
      expect(
        top,
        greaterThanOrEqualTo(MiTopBarMetrics.scrimSolidBottom - 0.01),
        reason: '段顶 $top 落在不透明叠色里（纯浪费）',
      );
    }
  });

  testWidgets('亮色顶栏：模糊从栏顶开始（叠色半透明，一段都不能省）',
      (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(768 * 2, 1280 * 2);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: const Scaffold(body: MiTopBar(title: '我的', scrollOffset: 0)),
      ),
    );
    await tester.pumpAndSettle();

    final barTop = tester.getTopLeft(find.byType(MiTopBar)).dy;
    final filters = find.descendant(
      of: find.byType(MiTopBar),
      matching: find.byType(BackdropFilter),
    );
    final firstTop =
        (filters.evaluate().first.renderObject! as RenderBox)
                .localToGlobal(Offset.zero)
                .dy -
            barTop;
    expect(firstTop, closeTo(0, 0.01));
  });

  testWidgets('同 σ 的 ImageFilter 跨帧复用（不每帧新建 native 对象）',
      (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(393 * 2, 856 * 2);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: MiSearchBar(hint: '搜索', themeMode: MiThemeMode.dark),
        ),
      ),
    );

    ImageFilter? filterOf() => tester
        .widget<BackdropFilter>(find.byType(BackdropFilter))
        .filter;
    final first = filterOf();

    // 强制重建（换 hint 文本不改变 σ，应拿到同一实例）
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(
          body: MiSearchBar(hint: '搜索主题', themeMode: MiThemeMode.dark),
        ),
      ),
    );
    expect(identical(first, filterOf()), isTrue);
  });
}
