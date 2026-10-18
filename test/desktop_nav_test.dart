import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；demo 层直接引示例代码。
import 'package:mi_like_ui/mi_like_ui.dart';
import 'package:mi_like_ui/demo/demo_app.dart';
import 'package:mi_like_ui/demo/mock_pages.dart';
// 内部画笔：只用来把「选中胶囊落在哪个槽位」读成数值（不属公开 API）。
import 'package:mi_like_ui/src/components/navigation/glass_side_nav_bar/side_nav_bar_painter.dart';

/// 桌面模式回归：侧边导航栏的几何 / 选中态 / 回调，以及示例应用在
/// **桌面断点两侧**的导航形态切换（底部栏 ⇄ 侧栏）。
///
/// 判据约定：
///  * **形态唯一** = 任意窗口宽度下底部栏与侧栏**恰好出现一个**；
///  * **布局不错位** = 页面左缘恰为侧栏列宽（`gutterWidth`）、侧栏左缘留白
///    25.5、贴顶，且不溢出（`takeException() == null`）；
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
  });

  group('桌面模式（DemoHome 导航形态切换）', () {
    testWidgets('移动端 / 平板（< 桌面断点）：仍用底部导航栏', (tester) async {
      addTearDown(tester.view.reset);

      for (final size in const [
        Size(393, 856), // compact 手机
        Size(768, 1280), // medium 平板
        Size(1023, 768), // 断点下沿（仍属 medium）
      ]) {
        setWindow(tester, size);
        await tester.pumpWidget(DemoApp(key: UniqueKey()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$size');
        expect(find.byType(MiGlassNavBar), findsOneWidget, reason: '$size');
        expect(find.byType(MiGlassSideNavBar), findsNothing, reason: '$size');
      }
    });

    testWidgets('桌面（≥ 桌面断点）：底部栏换成侧栏，页面让位且不错位', (tester) async {
      const window = Size(1366, 768);
      setWindow(tester, window);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MiGlassNavBar), findsNothing);
      expect(find.byType(MiGlassSideNavBar), findsOneWidget);

      // 舞台水平居中、宽度上限 1000；侧栏与页面都相对舞台定位
      final stageLeft = (window.width - DemoStage.wideMaxWidth) / 2;
      final rail = tester.getRect(find.byType(MiGlassSideNavBar));
      final page = tester.getRect(find.byType(MockPage));

      expect(rail.left - stageLeft, closeTo(MiGlassSideNavMetrics.railMargin, 0.01));
      expect(rail.width, closeTo(MiGlassSideNavMetrics.railWidth, 0.01));
      // 舞台在窗口里垂直居中（上下各 gutter），侧栏再距舞台顶一档留白
      const stageTop = DemoStage.gutter;
      expect(
        rail.top - stageTop,
        closeTo(MiGlassSideNavMetrics.railMargin, 0.01),
        reason: '侧栏应贴顶、距画面顶缘一档留白',
      );
      expect(
        page.left - stageLeft,
        closeTo(MiGlassSideNavMetrics.gutterWidth, 0.01),
        reason: '页面左缘应为侧栏列宽',
      );
      expect(
        page.width,
        closeTo(DemoStage.wideMaxWidth - MiGlassSideNavMetrics.gutterWidth, 0.01),
      );
      // 内容完整落在窗口内
      expect(rail.right, lessThanOrEqualTo(window.width + 0.01));
      expect(page.right, lessThanOrEqualTo(window.width + 0.01));
    });

    testWidgets('桌面：条目点击切页（与底部栏同一份 items / 回调）', (tester) async {
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

    testWidgets('跨断点来回切换：形态正确、页面滚动位置保留（不重建页面）', (tester) async {
      setWindow(tester, const Size(1366, 768));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      expect(find.byType(MiGlassSideNavBar), findsOneWidget);

      // 在桌面档滚一段，记下位置
      await tester.drag(
        find.descendant(of: find.byType(MockPage), matching: find.byType(ListView)),
        const Offset(0, -320),
      );
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

      // → 桌面：侧栏回来，位置依旧
      setWindow(tester, const Size(1366, 768));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(MiGlassSideNavBar), findsOneWidget);
      expect(find.byType(MiGlassNavBar), findsNothing);
      expect(pageScrollOffset(tester), closeTo(scrolled, 0.01));
    });
  });
}
