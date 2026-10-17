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

    final home = await measure(tester, const Size(768, 1280));
    // 顶栏 5 段 + 导航栏 1（优化前：顶栏 8 段 + 导航 1 + 搜索 1 = 10 段 / 100,073）
    expect(home.count, lessThanOrEqualTo(7), reason: '首页 $home');
    expect(home.area, lessThanOrEqualTo(82000), reason: '首页 $home');

    final showcase = await measure(tester, const Size(768, 1280), tab: '分类');
    // 顶栏 5 段（材质铺满 156dp，深色跳过不透明段后剩 5 段）+ 导航栏 1。
    // 2026-10-17 起分类页改用顶栏的统一材质：搜索栏 / 胶囊行不再各自挂
    // backdrop，改为整条头部区一次成糊 —— 层数比「零件各自玻璃」形态多，
    // 但那是「间隙与四周锐利」的旧形态被否掉的代价，面积仍在预算内。
    // 亮色配方没有实心段可省，是全 7 段材质 + 导航 1 = 8 层（本用例只测深色）。
    expect(showcase.count, lessThanOrEqualTo(6), reason: '分类页 $showcase');
    expect(showcase.area, lessThanOrEqualTo(56000), reason: '分类页 $showcase');

    final mine = await measure(tester, const Size(768, 1280), tab: '我的');
    expect(mine.count, lessThanOrEqualTo(6), reason: '我的 $mine');
    expect(mine.area, lessThanOrEqualTo(51000), reason: '我的 $mine');
  });

  testWidgets('深色·手机 393×856：模糊层数 / 面积预算', (tester) async {
    addTearDown(tester.view.reset);
    final phone = await measure(tester, const Size(393, 856));
    expect(phone.count, lessThanOrEqualTo(7), reason: '首页 $phone');
    expect(phone.area, lessThanOrEqualTo(53000), reason: '首页 $phone');
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
