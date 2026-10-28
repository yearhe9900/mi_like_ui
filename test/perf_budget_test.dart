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
/// 2026-10-27 **实测渐变批**：头部区形态（搜索栏 + 胶囊行）改按实测渐进
/// 曲线分段定 σ（`MiHeaderBlurProfile`：平台 8.5dp → 线性衰减 → 羽化收尾，
/// 推翻「恒定 σ」旧口径）：层数 2 → 10（9 段 + 导航），面积不变。
///
/// 2026-10-27 **实机反馈批**：搜索栏 / 胶囊改为**始终自绘自己的玻璃**
///（own backdrop + 内缘亮边，素材里胶囊内比缝隙处更糊、边缘一圈受光亮边）
/// → 每帧再 +2 层（搜索栏 1 + 胶囊条合并裁切 1），面积 = 零件两块
/// 投影面积。首页 / 分类 10 → **12 层**；总成本仍受 σScale（滚动中随速度
/// 实时降 σ）与 `MiFilterCache` 复用约束。
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
    // 首页 = 头部区形态（悬浮搜索栏 + 胶囊行压在高频横幅上）：9 段渐进 σ
    // 覆盖 0…156dp + 搜索栏玻璃 1 层 + 胶囊条玻璃 1 层 + 侧栏 1 层 = 12 层。
    final home = await measure(tester, const Size(768, 1280));
    expect(home.count, lessThanOrEqualTo(12), reason: '首页 $home');
    expect(home.area, lessThanOrEqualTo(165000), reason: '首页 $home');

    // 分类页同一形态（搜索栏 + 胶囊行吸顶、无压色）→ 与首页同预算。
    final showcase = await measure(tester, const Size(768, 1280), tab: '分类');
    expect(showcase.count, lessThanOrEqualTo(12), reason: '分类页 $showcase');
    expect(showcase.area, lessThanOrEqualTo(165000), reason: '分类页 $showcase');

    final mine = await measure(tester, const Size(768, 1280), tab: '我的');
    expect(mine.count, lessThanOrEqualTo(6), reason: '我的 $mine');
    expect(mine.area, lessThanOrEqualTo(55000), reason: '我的 $mine');
  });

  testWidgets('深色·手机 393×856：模糊层数 / 面积预算', (tester) async {
    addTearDown(tester.view.reset);
    // 手机档：头部区 9 段（393 × 156）+ 搜索栏 + 胶囊条 + 底栏 = 12 层
    final phone = await measure(tester, const Size(393, 856));
    expect(phone.count, lessThanOrEqualTo(12), reason: '首页 $phone');
    expect(phone.area, lessThanOrEqualTo(111000), reason: '首页 $phone');
  });

  testWidgets('深色·桌面 1366×768：侧栏只多一层模糊', (tester) async {
    addTearDown(tester.view.reset);
    // 桌面档（实测分层，`scratch_perf_print_test` 量的每层几何）：
    //  * 顶栏磨砂 1120 × **124** = 138,880 —— 列宽 1366 − 201.5 = 1164.5 已触
    //    内容列上限 1120；高 124 = 桌面 `headerTopInset` **24** + 搜索栏 44.1
    //    + 间隙 16 + 胶囊行 39.9（⚠️ 不是手机的 156：上一批按 156 估算出
    //    214,182 是**错的**，那会高估 35k）；
    //  * 展开侧栏 176 × 177.1 = 31,170（栏宽从 240 收到 176）。
    //  合计 **208,387dp² / 12 层**（头部区 9 段 + 搜索栏 + 胶囊条 + 侧栏）。
    //
    // 2026-10-27 实机反馈批：零件自绘玻璃 +2 层 + 零件面积；阈值按实测值
    // +3% 重标（与手机 / 平板档同一幅度）。
    final desktop = await measure(tester, const Size(1366, 768));
    expect(desktop.count, lessThanOrEqualTo(12), reason: '桌面 $desktop');
    expect(desktop.area, lessThanOrEqualTo(215000), reason: '桌面 $desktop');

    // 分类页同一形态 → 同预算
    final showcase = await measure(tester, const Size(1366, 768), tab: '分类');
    expect(showcase.count, lessThanOrEqualTo(12), reason: '桌面分类 $showcase');
    expect(showcase.area, lessThanOrEqualTo(215000), reason: '桌面分类 $showcase');

    // 「我的」= 大标题形态的**渐进曲线**（5 段 × 1120 宽，σ 阶梯在压色实心
    // 段之下先剔掉 3 段）+ 展开栏 → 实测 6 层 / 92,174。
    final mine = await measure(tester, const Size(1366, 768), tab: '我的');
    expect(mine.count, lessThanOrEqualTo(6), reason: '桌面我的 $mine');
    expect(mine.area, lessThanOrEqualTo(95000), reason: '桌面我的 $mine');
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
