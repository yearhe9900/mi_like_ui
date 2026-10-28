import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；demo 层直接引示例代码。
import 'package:mi_like_ui/mi_like_ui.dart';
import 'package:mi_like_ui/demo/demo_app.dart';
import 'package:mi_like_ui/demo/mock_pages.dart';
// 内部画笔：只用来把「选中胶囊落在哪个槽位」读成数值（不属公开 API）。
import 'package:mi_like_ui/src/components/navigation/glass_side_nav_bar/side_nav_bar_painter.dart';

/// 宽屏**内容列**在给定窗口下的几何（`MiContentColumn` 1120dp 上限 + 居中）：
/// 返回两侧留白与列宽。内容让位（侧栏列 + 分隔留白，桌面档展开态）先被
/// 扣掉，剩下的区域再决定列宽。
({double gutter, double width}) contentColumn(Size window) {
  final inset = MiGlassSideNavMetrics.contentInsetFor(
    expanded: MiBreakpoints.usesExpandedRail(window.width),
  );
  final area = window.width - inset;
  final width = math.min(area, MiBreakpoints.contentMaxWidth);
  return (gutter: (area - width) / 2, width: width);
}

/// 宽屏导航回归：侧边导航栏的几何 / 选中态 / 回调，以及示例应用在
/// **导航断点两侧**的形态切换（底部栏 ⇄ 侧栏）。
///
/// 断点口径照抄 MReader 主壳层（`lib/ui/home_shell.dart`）：
/// `LayoutBuilder` 读**外壳自己的容器宽**、`maxWidth > 600` 才切侧栏 ——
/// 所以平板（中等宽）也用侧栏，只有手机竖屏 / 窄窗留底栏。
///
/// 判据约定：
///  * **形态唯一** = 任何容器宽下底部栏与侧栏**恰好出现一个**；
///  * **边界严格大于** = 画面容器宽 600 → 底栏，602 → 侧栏；
///  * **布局不错位** = 页面在侧栏右侧的内容列里（列宽 ≤ 1120、居中、两侧
///    留白相等）、侧栏左缘留白 25.5、贴顶，且不溢出（`takeException() == null`）；
///  * **行为一致** = 点条目回调的下标与页面切换结果和底部栏相同；
///  * **切形态不丢状态** = 跨断点来回改变窗口尺寸后，页面滚动位置保持不变。
void main() {
  void setWindow(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
  }

  List<MiGlassNavItem> items(MiThemeMode mode) {
    final ink = MiColors.foregroundFor(mode);
    return [
      MiGlassNavItem(label: '首页', painter: RollerIconPainter(ink)),
      MiGlassNavItem(label: '分类', painter: GridSparkleIconPainter(ink)),
      MiGlassNavItem(label: '我的', painter: SmileyBeretIconPainter(ink)),
    ];
  }

  Widget harness({
    int selected = 0,
    ValueChanged<int>? onTap,
    MiThemeMode mode = MiThemeMode.dark,
    MiGlassNavFab? fab,
  }) {
    return MaterialApp(
      theme: mode == MiThemeMode.dark
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
      home: Scaffold(
        // 亮色配方在深底上也能看清外缘高光/投影，故两套模式共用同一底。
        backgroundColor: const Color(0xFF101014),
        body: Center(
          child: MiGlassSideNavBar(
            items: items(mode),
            selectedIndex: selected,
            onTap: onTap ?? (_) {},
            fab: fab,
            themeMode: mode,
          ),
        ),
      ),
    );
  }

  /// 条目 [i] 静止时胶囊中心的纵坐标（与组件内同一公式）。
  double slotCenter(int i) =>
      MiGlassSideNavMetrics.railInnerPad +
      MiGlassSideNavMetrics.itemHeight / 2 +
      MiGlassSideNavMetrics.pitch * i;

  /// 测试用圆钮（子级用文本，方便取几何中心）。
  MiGlassNavFab demoFab({VoidCallback? onTap}) => MiGlassNavFab(
        tabIndex: 0,
        onTap: onTap ?? () {},
        child: const Text('圆钮'),
      );

  SideNavPainter pillPainter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(MiGlassSideNavBar),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((w) => w.painter)
      .whereType<SideNavPainter>()
      .single;

  double pageScrollOffset(WidgetTester tester) => tester
      .state<ScrollableState>(
        find
            .descendant(of: find.byType(MockPage), matching: find.byType(Scrollable))
            .first,
      )
      .position
      .pixels;

  group('MiGlassSideNavMetrics（推导值，与底部栏同源）', () {
    test('栏宽 / 条目高 / 列宽沿用底部栏实测 token', () {
      expect(
        MiGlassSideNavMetrics.railWidth,
        closeTo(
          MiGlassNavMetrics.cellWidth + 2 * MiGlassNavMetrics.barInnerPad,
          1e-9,
        ),
      );
      expect(MiGlassSideNavMetrics.itemWidth, MiGlassNavMetrics.cellWidth);
      expect(
        MiGlassSideNavMetrics.itemHeight,
        closeTo(
          MiGlassNavMetrics.barHeight - 2 * MiGlassNavMetrics.pillInsetV,
          1e-9,
        ),
      );
      // 图标墨盒 / 图标到标签间距与底部栏一字不改（两种形态图标同大）
      expect(MiGlassSideNavMetrics.iconHeight, MiGlassNavMetrics.iconHeight);
      expect(MiGlassSideNavMetrics.iconLabelGap, MiGlassNavMetrics.iconLabelGap);
      expect(
        MiGlassSideNavMetrics.gutterWidth,
        closeTo(MiGlassSideNavMetrics.railMargin + MiGlassSideNavMetrics.railWidth, 1e-9),
      );
    });

    test('栏高 = 2×内边距 + n×条目高 + (n−1)×间隙', () {
      expect(
        MiGlassSideNavMetrics.railHeightFor(3),
        closeTo(2 * 6.6 + 3 * 49.3 + 2 * 8, 1e-9),
      );
      expect(
        MiGlassSideNavMetrics.railHeightFor(5) -
            MiGlassSideNavMetrics.railHeightFor(4),
        closeTo(MiGlassSideNavMetrics.itemHeight + MiGlassSideNavMetrics.itemGap, 1e-9),
      );
    });

    test('展开态：176dp 带文字栏（推导值），条目宽 = 栏宽 − 2×内边距', () {
      expect(MiGlassSideNavMetrics.expandedRailWidth, 176);
      expect(
        MiGlassSideNavMetrics.expandedItemWidth,
        closeTo(176 - 2 * MiGlassSideNavMetrics.railInnerPad, 1e-9),
      );
      // 装得下 8 个汉字标签：2×内缩 + 图标 + 间距 + 8×标签字号 ≤ 条目宽
      const labelChars = 8;
      final contentNeeded = 2 * MiGlassSideNavMetrics.expandedItemInset +
          MiGlassSideNavMetrics.iconSize +
          MiGlassSideNavMetrics.expandedIconLabelGap +
          labelChars * MiTypography.navLabel.fontSize!;
      expect(
        contentNeeded,
        lessThanOrEqualTo(MiGlassSideNavMetrics.expandedItemWidth),
        reason: '8 字标签应装得下（留一档余量）',
      );
      // 「首页」这类 2 字标签：尾部空白应显著小于首版 240 的 133.8dp
      final shortLabelContent = 2 * MiGlassSideNavMetrics.expandedItemInset +
          MiGlassSideNavMetrics.iconSize +
          MiGlassSideNavMetrics.expandedIconLabelGap +
          2 * MiTypography.navLabel.fontSize!;
      final trailing = MiGlassSideNavMetrics.expandedItemWidth - shortLabelContent;
      expect(trailing, lessThan(80), reason: '2 字标签尾部空白应 < 80dp');
      expect(
        MiGlassSideNavMetrics.expandedGutterWidth,
        closeTo(
          MiGlassSideNavMetrics.railMargin +
              MiGlassSideNavMetrics.expandedRailWidth,
          1e-9,
        ),
      );
      // 断点：容器宽 ≥ 1024 才展开（平板竖屏让出栏宽不划算）
      expect(MiBreakpoints.usesExpandedRail(1023), isFalse);
      expect(MiBreakpoints.usesExpandedRail(1024), isTrue);
      expect(MiBreakpoints.usesExpandedRail(768), isFalse);
      // 形态取值helper
      expect(MiGlassSideNavMetrics.railWidthFor(), MiGlassSideNavMetrics.railWidth);
      expect(
        MiGlassSideNavMetrics.railWidthFor(expanded: true),
        MiGlassSideNavMetrics.expandedRailWidth,
      );
      expect(
        MiGlassSideNavMetrics.gutterWidthFor(expanded: true),
        MiGlassSideNavMetrics.expandedGutterWidth,
      );
    });

    test('栏体圆角以内圈胶囊为准等距外扩（内外圈间距四周恒 6.6）', () {      // 端头圆弧与胶囊顶角圆弧**同心**：圆心 y 同为 内边距 + 胶囊半径，
      // 间距 = 半径差 = 内边距。旧值 railWidth/2 = 47.7 与内圈不同心，
      // 肩部间距会从 6.6 收缩到 0（两圆弧相交）—— 用户反馈平板模式
      // 内外圈间距应一致，以内圈为准。
      expect(
        MiGlassSideNavMetrics.railRadius,
        closeTo(MiGlassSideNavMetrics.pillRadius + MiGlassSideNavMetrics.railInnerPad, 1e-9),
      );
      expect(MiGlassSideNavMetrics.railRadius, closeTo(31.25, 1e-9));
      // 圆钮几何沿用底部栏实测（直径 = 栏高、间距 11.9）
      expect(MiGlassSideNavMetrics.fabDiameter, MiGlassNavMetrics.fabDiameter);
      expect(MiGlassSideNavMetrics.fabGap, MiGlassNavMetrics.fabGap);
      // 槽位恒定预留：hasFab 只加一段定高，显隐不改布局
      expect(
        MiGlassSideNavMetrics.heightFor(3, hasFab: true),
        closeTo(
          MiGlassSideNavMetrics.railHeightFor(3) +
              MiGlassSideNavMetrics.fabGap +
              MiGlassSideNavMetrics.fabDiameter,
          1e-9,
        ),
      );
      expect(
        MiGlassSideNavMetrics.heightFor(3),
        closeTo(MiGlassSideNavMetrics.railHeightFor(3), 1e-9),
      );
    });
  });

  group('MiGlassSideNavBar', () {
    testWidgets('按声明尺寸渲染：栏体收缩到内容高、条目等距排布', (tester) async {
      setWindow(tester, const Size(400, 600));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(MiGlassSideNavBar));
      expect(size.width, closeTo(MiGlassSideNavMetrics.railWidth, 0.01));
      expect(
        size.height,
        closeTo(MiGlassSideNavMetrics.railHeightFor(3), 0.01),
      );

      // 三个条目纵向等距，间距 = itemGap
      final railTop = tester.getTopLeft(find.byType(MiGlassSideNavBar)).dy;
      final c0 = tester.getCenter(find.text('首页')).dy;
      final c1 = tester.getCenter(find.text('分类')).dy;
      final c2 = tester.getCenter(find.text('我的')).dy;
      expect(c1 - c0, closeTo(MiGlassSideNavMetrics.pitch, 0.01));
      expect(c2 - c1, closeTo(MiGlassSideNavMetrics.pitch, 0.01));
      // 首条目：内边距 + 半个条目高（标签不是条目圆心，故与胶囊中心差一档
      // icon/gap 偏移，这里只锁「首条目在栏顶内边距之内」）
      expect(c0 - railTop, greaterThan(MiGlassSideNavMetrics.railInnerPad));
      expect(c2 - railTop, lessThan(size.height - MiGlassSideNavMetrics.railInnerPad));
    });

    testWidgets('点按回调下标，选中胶囊落到对应槽位（首/中/尾都对齐）', (tester) async {
      setWindow(tester, const Size(400, 600));
      addTearDown(tester.view.reset);

      final tapped = <int>[];
      await tester.pumpWidget(harness(onTap: tapped.add));
      await tester.pumpAndSettle();

      // 首帧即稳态：选中 0 的胶囊就在 0 号槽位
      expect(pillPainter(tester).pillCenterY, closeTo(slotCenter(0), 0.01));
      expect(pillPainter(tester).pillHeight, closeTo(MiGlassSideNavMetrics.itemHeight, 0.01));
      expect(pillPainter(tester).pillWidth, closeTo(MiGlassSideNavMetrics.itemWidth, 0.01));

      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      expect(tapped, [2]);

      // 受控组件：调用方回传新的 selectedIndex 后才移动
      await tester.pumpWidget(harness(selected: 2, onTap: tapped.add));
      await tester.pumpAndSettle();
      expect(pillPainter(tester).pillCenterY, closeTo(slotCenter(2), 0.01));

      await tester.tap(find.text('分类'));
      await tester.pumpAndSettle();
      expect(tapped, [2, 1]);
      await tester.pumpWidget(harness(selected: 1, onTap: tapped.add));
      await tester.pumpAndSettle();
      expect(pillPainter(tester).pillCenterY, closeTo(slotCenter(1), 0.01));
    });

    testWidgets('纵向拖拽吸附最近条目（与底部栏横向拖拽同一套吸附）', (tester) async {
      setWindow(tester, const Size(400, 600));
      addTearDown(tester.view.reset);

      final tapped = <int>[];
      await tester.pumpWidget(harness(onTap: tapped.add));
      await tester.pumpAndSettle();

      // 从栏体中心（= 1 号条目）向下拖两格 → 吸附到末条目
      const dragDy = MiGlassSideNavMetrics.pitch * 2;
      await tester.drag(find.byType(MiGlassSideNavBar), const Offset(0, dragDy));
      await tester.pumpAndSettle();
      expect(tapped, [2]);
    });

    testWidgets('只挂一个磨砂层、不引入额外遮罩（每帧模糊预算）', (tester) async {
      setWindow(tester, const Size(400, 600));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      final rail = find.byType(MiGlassSideNavBar);
      expect(
        find.descendant(of: rail, matching: find.byType(BackdropFilter)),
        findsOneWidget,
      );
      // 半透明遮罩会让 backdrop 变空（本项目已实测的坑）
      expect(
        find.descendant(of: rail, matching: find.byType(ShaderMask)),
        findsNothing,
      );
      // 条目 3 个图标 + 1 个胶囊画笔
      expect(
        find.descendant(of: rail, matching: find.byType(CustomPaint)),
        findsNWidgets(4),
      );
    });

    testWidgets('亮色配方可用（投影/渐变不报错）', (tester) async {
      setWindow(tester, const Size(400, 600));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(mode: MiThemeMode.light));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(pillPainter(tester).palette.scrimGradient, isNotNull);
    });

    testWidgets('展开态：176dp 带文字栏，胶囊满宽、纵向节奏与窄栏同源', (tester) async {
      setWindow(tester, const Size(400, 600));
      addTearDown(tester.view.reset);

      Widget wideHarness({int selected = 0}) => MaterialApp(
            theme: ThemeData.dark(useMaterial3: true),
            home: Scaffold(
              backgroundColor: const Color(0xFF101014),
              body: Center(
                child: MiGlassSideNavBar(
                  items: items(MiThemeMode.dark),
                  selectedIndex: selected,
                  onTap: (_) {},
                  themeMode: MiThemeMode.dark,
                  expanded: true,
                ),
              ),
            ),
          );

      await tester.pumpWidget(wideHarness());
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(MiGlassSideNavBar));
      expect(
        size.width,
        closeTo(MiGlassSideNavMetrics.expandedRailWidth, 0.01),
      );
      // 纵向节奏与窄栏一致（同 itemHeight / itemGap / railInnerPad）
      expect(
        size.height,
        closeTo(MiGlassSideNavMetrics.railHeightFor(3), 0.01),
      );
      // 胶囊：满条目宽、落 0 号槽位
      expect(
        pillPainter(tester).pillWidth,
        closeTo(MiGlassSideNavMetrics.expandedItemWidth, 0.01),
      );
      expect(pillPainter(tester).pillCenterY, closeTo(slotCenter(0), 0.01));

      // 标签在图标右侧（横排），三种点击语义不变
      // （CustomPaint 里第一个是胶囊画笔，条目图标跟在其后）
      final icon = tester.getTopLeft(
        find
            .descendant(
              of: find.byType(MiGlassSideNavBar),
              matching: find.byType(CustomPaint),
            )
            .at(1),
      );
      final label = tester.getTopLeft(find.text('首页'));
      expect(label.dx, greaterThan(icon.dx));

      final tapped = <int>[];
      await tester.pumpWidget(wideHarness(selected: 1));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            backgroundColor: const Color(0xFF101014),
            body: Center(
              child: MiGlassSideNavBar(
                items: items(MiThemeMode.dark),
                selectedIndex: 1,
                onTap: tapped.add,
                themeMode: MiThemeMode.dark,
                expanded: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(pillPainter(tester).pillCenterY, closeTo(slotCenter(1), 0.01));
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      expect(tapped, [2]);

      // 只挂一个磨砂层（展开栏同样每帧只糊一次）
      expect(
        find.descendant(
          of: find.byType(MiGlassSideNavBar),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
    });
  });

  group('预留空位圆钮（MiGlassNavFab，与底部栏同契约）', () {
    testWidgets('圆钮挂在栏尾下方：水平居中 / 间距 fabGap / 槽位恒定预留', (tester) async {
      setWindow(tester, const Size(400, 700));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(selected: 0, fab: demoFab()));
      await tester.pumpAndSettle();

      final railFinder = find.byType(MiGlassSideNavBar);
      final size = tester.getSize(railFinder);
      expect(size.width, closeTo(MiGlassSideNavMetrics.railWidth, 0.01));
      // 配置圆钮后组件总高 = 栏体高 + 间距 + 直径（槽位恒定预留）
      expect(
        size.height,
        closeTo(MiGlassSideNavMetrics.heightFor(3, hasFab: true), 0.01),
      );

      // 圆钮中心：水平对齐栏体中线，纵向在栏尾下方一个间距 + 半径
      final center = tester.getCenter(find.text('圆钮'));
      final railTopLeft = tester.getTopLeft(railFinder);
      expect(center.dx, closeTo(railTopLeft.dx + size.width / 2, 0.01));
      expect(
        center.dy,
        closeTo(
          railTopLeft.dy +
              MiGlassSideNavMetrics.railHeightFor(3) +
              MiGlassSideNavMetrics.fabGap +
              MiGlassSideNavMetrics.fabDiameter / 2,
          0.01,
        ),
      );
      // 首帧即稳态：选中「首页」圆钮完全显示
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(of: find.text('圆钮'), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 1.0);
    });

    testWidgets('切到其它条目收起、切回弹出；收起不改组件高度、不吃点击', (tester) async {
      setWindow(tester, const Size(400, 700));
      addTearDown(tester.view.reset);

      var taps = 0;
      await tester.pumpWidget(harness(selected: 0, fab: demoFab(onTap: () => taps++)));
      await tester.pumpAndSettle();
      final shownHeight = tester.getSize(find.byType(MiGlassSideNavBar)).height;
      final fabCenter = tester.getCenter(find.text('圆钮'));

      // 切到「分类」：镜像收起（reverse 时间镜像），槽位仍在、高度不变
      await tester.pumpWidget(harness(selected: 1, fab: demoFab(onTap: () => taps++)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MiGlassSideNavBar)).height,
        closeTo(shownHeight, 0.01),
        reason: '收起不应引起布局跳动（槽位恒定预留）',
      );
      final hidden = tester.widget<Opacity>(
        find
            .ancestor(of: find.text('圆钮'), matching: find.byType(Opacity)),
      );
      expect(hidden.opacity, 0.0);
      // 收起后圆钮整体 IgnorePointer：点在圆钮位置不触发回调、不吞下层点击
      await tester.tapAt(fabCenter);
      await tester.pumpAndSettle();
      expect(taps, 0, reason: '收起的圆钮不应吃点击');

      // 切回「首页」：弹回完全显示，点击恢复
      await tester.pumpWidget(harness(selected: 0, fab: demoFab(onTap: () => taps++)));
      await tester.pumpAndSettle();
      final back = tester.widget<Opacity>(
        find
            .ancestor(of: find.text('圆钮'), matching: find.byType(Opacity)),
      );
      expect(back.opacity, 1.0);
      await tester.tap(find.text('圆钮'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('圆钮点按回调触发', (tester) async {
      setWindow(tester, const Size(400, 700));
      addTearDown(tester.view.reset);

      var taps = 0;
      await tester.pumpWidget(harness(selected: 0, fab: demoFab(onTap: () => taps++)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('圆钮'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('超过 3 个条目 / tabIndex 越界：initState 断言', (tester) async {
      // 数量与范围校验在 initState 断言（const 构造断言不支持 .length 求值）
      final fourItems = [
        for (var i = 0; i < 4; i++)
          MiGlassNavItem(
            label: 'tab$i',
            painter: RollerIconPainter(MiColors.foregroundFor(MiThemeMode.dark)),
          ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiGlassSideNavBar(
              items: fourItems,
              selectedIndex: 0,
              onTap: (_) {},
              fab: demoFab(),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());

      // fab.tabIndex 越界（构造期无法校验，initState 断言）
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => MiGlassSideNavBar(
                items: items(MiThemeMode.dark),
                selectedIndex: 0,
                onTap: (_) {},
                fab: MiGlassNavFab(
                  tabIndex: 3,
                  onTap: () {},
                  child: const Text('圆钮'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });
  });

  group('导航形态断点（照 MReader：容器宽 > 600）', () {
    test('usesSideNav 严格大于 600，与 MReader 的 maxWidth > 600 同口径', () {
      expect(MiBreakpoints.navRail, 600);
      expect(MiBreakpoints.usesSideNav(0), isFalse);
      expect(MiBreakpoints.usesSideNav(393), isFalse);
      expect(MiBreakpoints.usesSideNav(599.99), isFalse);
      expect(MiBreakpoints.usesSideNav(600), isFalse, reason: '正好 600 仍走底栏');
      expect(MiBreakpoints.usesSideNav(600.01), isTrue);
      expect(MiBreakpoints.usesSideNav(768), isTrue, reason: '平板也用侧栏');
      expect(MiBreakpoints.usesSideNav(1366), isTrue);
    });

    test('枚举口径：medium / expanded 都用侧栏（600 边界点除外）', () {
      expect(MiWindowSize.compact.usesSideNav, isFalse);
      expect(MiWindowSize.medium.usesSideNav, isTrue);
      expect(MiWindowSize.expanded.usesSideNav, isTrue);
      // 桌面档判定仍是 1024（只用于舞台加宽等桌面专属样式）
      expect(MiBreakpoints.desktop, 1024);
      expect(MiWindowSize.medium.isDesktop, isFalse);
      expect(MiWindowSize.expanded.isDesktop, isTrue);
    });
  });

  group('铺满窗口 / 边到边（平板、桌面）', () {
    testWidgets('平板：画面 = 窗口，没有外围卡片（页面顶到 0、铺满高）',
        (tester) async {
      setWindow(tester, const Size(768, 1280));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final page = tester.getRect(find.byType(MockPage));
      expect(page.top, closeTo(0, 0.01), reason: '页面顶缘应贴窗口顶（无 24dp 卡片留白）');
      expect(page.height, closeTo(1280, 0.01));
      expect(page.right, closeTo(768, 0.01));

      // 外壳不再画圆角卡片：装饰的圆角为 0、无投影
      final box = tester.widget<Container>(
        find
            .ancestor(of: find.byType(MockPage), matching: find.byType(Container))
            .last,
      );
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.zero);
      expect(decoration.boxShadow ?? const [], isEmpty);
    });

    testWidgets('状态栏：透明 + 图标亮度随明暗翻转', (tester) async {
      setWindow(tester, const Size(393, 856));
      addTearDown(tester.view.reset);

      SystemUiOverlayStyle overlay() => tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find
                .descendant(
                  of: find.byType(DemoHome),
                  matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
                )
                .first,
          )
          .value;

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      // 深色：透明状态栏 + 浅色图标
      expect(overlay().statusBarColor, Colors.transparent);
      expect(overlay().statusBarIconBrightness, Brightness.light);
      expect(overlay().systemNavigationBarColor, Colors.transparent);

      // 切浅色：图标翻成深色（否则浅底上看不见）
      await tester.tap(find.text('我的').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(overlay().statusBarIconBrightness, Brightness.dark);
    });

    testWidgets('边到边：侧栏让开状态栏、底栏在手势条之上（不叠加安全区）',
        (tester) async {
      addTearDown(tester.view.reset);

      // 平板 + 40dp 状态栏：侧栏顶 = 40 + 25.5
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(768, 1280);
      tester.view.padding = FakeViewPadding(top: 40);
      await tester.pumpWidget(DemoApp(key: UniqueKey()));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(MiGlassSideNavBar)).top,
        closeTo(40 + MiGlassSideNavMetrics.railMargin, 0.01),
      );

      // 手机 + 20dp 手势条：底栏仍浮起 24.2（**不叠加**安全区——参考截图里
      // 系统手势条就落在这 24.2 之内；叠加会顶到 45dp、手势条悬在空档里）
      tester.view.physicalSize = const Size(393, 856);
      tester.view.padding = FakeViewPadding(bottom: 20);
      await tester.pumpWidget(DemoApp(key: UniqueKey()));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(MiGlassNavBar)).bottom,
        closeTo(856 - 24.2, 0.01),
      );

      // 画面里只有系统手势条：示例不再自绘 Home 指示条（自绘一条 + 系统一条
      // = 真机两条，2026-10-20 反馈）
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.constraints?.maxWidth ?? 0) == 138 &&
              (w.constraints?.maxHeight ?? 0) == 5,
        ),
        findsNothing,
      );

      // 三键导航（48dp 安全区比 24.2 还大）：栏抬到按键上方，不压按键
      tester.view.padding = FakeViewPadding(bottom: 48);
      await tester.pumpWidget(DemoApp(key: UniqueKey()));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(MiGlassNavBar)).bottom,
        closeTo(856 - 48, 0.01),
      );
    });
  });

  group('宽屏模式（DemoHome 导航形态切换）', () {
    /// 在给定窗口尺寸下渲染示例，返回该窗口下画面的**容器宽**。
    Future<double> frameWidth(WidgetTester tester, Size window) async {
      setWindow(tester, window);
      await tester.pumpWidget(DemoApp(key: UniqueKey()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$window');
      return DemoStage.sizeFor(window).logical.width;
    }

    testWidgets('手机 / 窄窗（画面 ≤ 600）：仍是底部导航栏', (tester) async {
      addTearDown(tester.view.reset);

      for (final window in const [
        Size(393, 856), // 参考机竖屏：手机画布 393
        Size(260, 470), // 桌面小窗：手机画布等比缩小
        Size(600, 900), // 边界：画面正好 600 → 仍底栏（严格大于才切）
      ]) {
        final width = await frameWidth(tester, window);
        expect(
          width <= MiBreakpoints.navRail,
          isTrue,
          reason: '$window 的画面宽 $width 应落在底栏档',
        );
        expect(find.byType(MiGlassNavBar), findsOneWidget, reason: '$window');
        expect(find.byType(MiGlassSideNavBar), findsNothing, reason: '$window');
      }
    });

    testWidgets('平板 / 桌面（画面 > 600）：底部栏换成侧栏', (tester) async {
      addTearDown(tester.view.reset);

      for (final window in const [
        Size(601, 900), // 边界上沿：画面 601 → 侧栏（窄栏）
        Size(650, 900), // 平板窄窗（窄栏）
        Size(768, 1280), // 平板竖屏（实机尺寸，窄栏）
        Size(1023, 768), // 中等宽（窄栏最后一档）
        Size(1366, 768), // 桌面（展开栏）
      ]) {
        final width = await frameWidth(tester, window);
        expect(
          width > MiBreakpoints.navRail,
          isTrue,
          reason: '$window 的画面宽 $width 应落在侧栏档',
        );
        expect(find.byType(MiGlassNavBar), findsNothing, reason: '$window');
        expect(find.byType(MiGlassSideNavBar), findsOneWidget, reason: '$window');
        // 页面在侧栏右侧的内容列里：列宽 ≤ 1120、两侧留白相等
        final page = tester.getRect(find.byType(MockPage));
        final rail = tester.getRect(find.byType(MiGlassSideNavBar));
        final col = contentColumn(window);
        final inset = MiGlassSideNavMetrics.contentInsetFor(
          expanded: MiBreakpoints.usesExpandedRail(window.width),
        );
        expect(page.width, closeTo(col.width, 0.01), reason: '$window');
        expect(
          page.left,
          closeTo(inset + col.gutter, 0.01),
          reason: '$window',
        );
        expect(page.left - rail.left, greaterThan(0), reason: '$window');
        expect(page.right, lessThanOrEqualTo(window.width + 0.01), reason: '$window');
      }
    });

    testWidgets('桌面 1366×768：画面铺满窗口（无外围卡片）、展开侧栏贴顶留白',
        (tester) async {
      const window = Size(1366, 768);
      setWindow(tester, window);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final rail = tester.getRect(find.byType(MiGlassSideNavBar));
      final page = tester.getRect(find.byType(MockPage));
      final col = contentColumn(window);

      // 铺满：画面 = 窗口，四周没有留白 / 圆角卡片（页面底色仍铺满窗口，
      // 只是内容列限宽 1120 并居中）
      expect(rail.left, closeTo(MiGlassSideNavMetrics.railMargin, 0.01));
      // 桌面档（≥1024）换**展开栏**：176dp 带文字标签
      expect(
        rail.width,
        closeTo(MiGlassSideNavMetrics.expandedRailWidth, 0.01),
      );
      expect(
        rail.top,
        closeTo(MiGlassSideNavMetrics.railMargin, 0.01),
        reason: '侧栏应贴顶、距窗口顶缘一档留白（测试环境安全区为 0）',
      );
      // 展开栏的条目 = 图标在左、标签在右（桌面常驻侧栏形态）
      final firstItem = find.descendant(
        of: find.byType(MiGlassSideNavBar),
        matching: find.text('首页'),
      );
      // 条目图标（CustomPaint 里第一个是胶囊画笔，条目图标跟在其后）
      final iconTopLeft = tester.getTopLeft(
        find
            .descendant(
              of: find.byType(MiGlassSideNavBar),
              matching: find.byType(CustomPaint),
            )
            .at(1),
      );
      final labelTopLeft = tester.getTopLeft(firstItem);
      expect(
        labelTopLeft.dx,
        greaterThan(iconTopLeft.dx),
        reason: '展开栏标签应在图标右侧',
      );
      expect(
        labelTopLeft.dy,
        closeTo(iconTopLeft.dy + (MiGlassSideNavMetrics.iconHeight - 10.5) / 2, 1.5),
        reason: '展开栏图标与标签应垂直居中对齐',
      );
      expect(page.left,
          closeTo(
            MiGlassSideNavMetrics.contentInsetFor(expanded: true) + col.gutter,
            0.01),
          reason: '页面应落在展开侧栏右侧的内容列里（列宽上限 1120 + 居中）');
      expect(page.top, closeTo(0, 0.01));
      // 展开栏让出 201.5 后剩 1366 − 201.5 = 1164.5 > 1120 → 列宽取**上限**
      // 1120（栏收窄后腾出的空间反而先触到列宽封顶）
      expect(
        col.width,
        closeTo(MiBreakpoints.contentMaxWidth, 0.01),
        reason: '剩余宽超过内容列上限，应封顶在 1120',
      );
      expect(page.width, closeTo(col.width, 0.01));
      expect(page.height, closeTo(window.height, 0.01));
      // 内容完整落在窗口内
      expect(rail.right, lessThanOrEqualTo(window.width + 0.01));
      expect(page.right, lessThanOrEqualTo(window.width + 0.01));
    });

    testWidgets('侧栏：条目点击切页（与底部栏同一份 items / 回调）', (tester) async {
      setWindow(tester, const Size(1366, 768));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      final rail = find.byType(MiGlassSideNavBar);
      double pill() => tester
          .widgetList<CustomPaint>(
            find.descendant(of: rail, matching: find.byType(CustomPaint)),
          )
          .map((w) => w.painter)
          .whereType<SideNavPainter>()
          .single
          .pillCenterY;

      // 首页 → 分类：分类页 = 组件展示库（顶栏内嵌胶囊标签行）
      await tester.tap(find.descendant(of: rail, matching: find.text('分类')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(MiPillTabBar), findsOneWidget);
      expect(pill(), closeTo(slotCenter(1), 0.5));

      // 分类 → 我的：出现外观模式卡片
      await tester.tap(find.descendant(of: rail, matching: find.text('我的')));
      await tester.pumpAndSettle();
      expect(find.text('外观模式'), findsOneWidget);
      expect(pill(), closeTo(slotCenter(2), 0.5));
    });

    testWidgets('平板 / 桌面：绿色圆钮随「首页」选中显隐、点按唤起弹出面板', (tester) async {
      setWindow(tester, const Size(1366, 768));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final rail = find.byType(MiGlassSideNavBar);
      // 圆钮 = 侧栏子树里唯一的圆形 Container（绿色底，与底部栏同色 token）
      final fabCircle = find.descendant(
        of: rail,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      expect(fabCircle, findsOneWidget);
      final deco = tester.widget<Container>(fabCircle).decoration! as BoxDecoration;
      expect(deco.color, MiColors.fabGreenFor(MiThemeMode.dark));

      // 点按唤起弹出面板（与底部栏形态同一份 fab 声明），圆钮同步变深
      // （度量 #131313）；面板锚在圆钮圆心、弹簧唤起后收口。
      await tester.tap(fabCircle);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(MiPullUpPanel), findsOneWidget);
      expect(find.text('快捷操作'), findsOneWidget);
      final opened = tester.widget<Container>(fabCircle).decoration! as BoxDecoration;
      expect(opened.color, const Color(0xFF131313));

      // 切到「分类」→ 面板随切走收起、圆钮也收起（缩放到 0 + IgnorePointer）
      await tester.tap(find.descendant(of: rail, matching: find.text('分类')));
      await tester.pumpAndSettle();
      expect(find.byType(MiPullUpPanel), findsNothing);
      final hidden = tester.widget<Opacity>(
        find
            .ancestor(of: fabCircle, matching: find.byType(Opacity)),
      );
      expect(hidden.opacity, 0.0);

      // 切回「首页」→ 弹回（面板已收起，圆钮回绿）
      await tester.tap(find.descendant(of: rail, matching: find.text('首页')));
      await tester.pumpAndSettle();
      expect(find.byType(MiPullUpPanel), findsNothing);
      final closed = tester.widget<Container>(fabCircle).decoration! as BoxDecoration;
      expect(closed.color, MiColors.fabGreenFor(MiThemeMode.dark));
      final shown = tester.widget<Opacity>(
        find
            .ancestor(of: fabCircle, matching: find.byType(Opacity)),
      );
      expect(shown.opacity, 1.0);
    });

    testWidgets('跨断点来回切换：形态正确、页面滚动位置保留（不重建页面）', (tester) async {
      setWindow(tester, const Size(1366, 768));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      expect(find.byType(MiGlassSideNavBar), findsOneWidget);

      // 在侧栏档滚一段，记下位置。**按可滚范围取**、不写死位移：首页内容
      // 长度会随演示内容调整（2026-10-20 起首屏是 186dp 横幅 + 区块），宽窗口
      // 上 `-320` 会直接撞到 maxScrollExtent，断点切换后"位置保留"就无从对比。
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(MockPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent * 0.5);
      await tester.pumpAndSettle();
      final scrolled = pageScrollOffset(tester);
      expect(scrolled, greaterThan(0));

      // → 手机：底部栏回来，页面仍停在原处
      setWindow(tester, const Size(393, 856));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(MiGlassNavBar), findsOneWidget);
      expect(find.byType(MiGlassSideNavBar), findsNothing);
      expect(pageScrollOffset(tester), closeTo(scrolled, 0.01));

      // → 平板（侧栏档的另一个尺寸）：位置依旧
      setWindow(tester, const Size(768, 1280));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(MiGlassSideNavBar), findsOneWidget);
      expect(pageScrollOffset(tester), closeTo(scrolled, 0.01));

      // → 桌面：同上
      setWindow(tester, const Size(1366, 768));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(MiGlassSideNavBar), findsOneWidget);
      expect(find.byType(MiGlassNavBar), findsNothing);
      expect(pageScrollOffset(tester), closeTo(scrolled, 0.01));
    });
  });

  testWidgets('「我的」设置行：按压整行满铺高亮带、松开渐隐并触发点按反馈',
      (tester) async {
    setWindow(tester, const Size(1366, 768));
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();
    // 进「我的」（侧栏档）：设置页风格分组卡片
    final rail = find.byType(MiGlassSideNavBar);
    await tester.tap(find.descendant(of: rail, matching: find.text('我的')));
    await tester.pumpAndSettle();

    Color? fillOf(String label) => (
            tester
                .widget<AnimatedContainer>(
                  find
                      .ancestor(
                        of: find.text(label),
                        matching: find.byType(AnimatedContainer),
                      )
                      .first,
                )
                .decoration! as BoxDecoration
              )
              .color;

    // 静止：行底透明（卡片色透出）
    expect(fillOf('WLAN'), Colors.transparent);

    // 按下 → 渐变到按压高亮带（设置页风格：整行满铺、暗 #3A3A3A）
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('WLAN')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(fillOf('WLAN'), const Color(0xFF3A3A3A));

    // 松开 → 渐隐回透明；点按触发占位反馈（SnackBar，demo 同款交互）
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(fillOf('WLAN'), Colors.transparent);
    expect(find.text('WLAN 被点击'), findsOneWidget);
  });
}
