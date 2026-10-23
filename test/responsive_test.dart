import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；demo 层直接引示例代码。
import 'package:mi_like_ui/mi_like_ui.dart';
import 'package:mi_like_ui/demo/demo_app.dart';
import 'package:mi_like_ui/demo/mock_pages.dart';

/// 自适应（响应式）回归：断点判定 / 等比缩放画布 / 示例外壳三档布局 /
/// 网格列数 / 窗口实时变化。
///
/// 判据约定：
///  * **不溢出** = `tester.takeException()` 为 null（`RenderFlex overflowed`
///    在 debug 下会记为 FlutterError，被这里捕获）；
///  * **不变形** = 渲染宽高比恒等于设计宽高比（compact/medium 档）；
///  * **不丢内容** = 关键部件（导航栏 / 卡片）的渲染矩形完整落在窗口内。
void main() {
  group('MiBreakpoints', () {
    test('窗口三档边界', () {
      expect(MiBreakpoints.ofWidth(0), MiWindowSize.compact);
      expect(MiBreakpoints.ofWidth(320), MiWindowSize.compact);
      expect(MiBreakpoints.ofWidth(599.99), MiWindowSize.compact);
      expect(MiBreakpoints.ofWidth(600), MiWindowSize.medium);
      expect(MiBreakpoints.ofWidth(1023.99), MiWindowSize.medium);
      expect(MiBreakpoints.ofWidth(1024), MiWindowSize.expanded);
      expect(MiBreakpoints.ofWidth(3000), MiWindowSize.expanded);
    });

    test('列数按容器宽断点，并 clamp 到 [1, maxColumns]', () {
      int cols(double w, {int maxColumns = 12}) => MiBreakpoints.columnsFor(
            w,
            compact: 3,
            medium: 4,
            expanded: 6,
            maxColumns: maxColumns,
          );
      expect(cols(393), 3);
      expect(cols(599), 3);
      expect(cols(600), 4);
      expect(cols(1023), 4);
      expect(cols(1024), 6);
      // 非法/极端值不产生 0 列，也不无限扩列
      expect(
        MiBreakpoints.columnsFor(120, compact: 0, medium: 0, expanded: 0),
        1,
      );
      expect(cols(4000, maxColumns: 5), 5);
    });

    test('单元宽上限：列数向上取整，单元宽恒 ≤ 上限', () {
      // 1056 内容宽、单元上限 210、列距 11.9 → 5 列（每列 201.4）
      expect(
        MiBreakpoints.columnsForMaxCell(
          1056,
          maxCellWidth: 210,
          itemSpacing: 11.9,
          minColumns: 1,
        ),
        5,
      );
      // 单元宽验证：任意宽下 (w − (n−1)g)/n ≤ maxCellWidth
      for (final w in <double>[393, 704, 1056, 1600, 2200]) {
        final n = MiBreakpoints.columnsForMaxCell(
          w,
          maxCellWidth: 210,
          itemSpacing: 11.9,
          minColumns: 2,
        );
        final cell = (w - (n - 1) * 11.9) / n;
        expect(cell, lessThanOrEqualTo(210 + 1e-9), reason: 'w=$w n=$n');
        expect(n, greaterThanOrEqualTo(2), reason: '断点台阶是下限');
      }
      // 断点台阶比上限算出来的更大时，守台阶（不因为上限砍列）
      expect(
        MiBreakpoints.columnsForMaxCell(
          393,
          maxCellWidth: 60,
          itemSpacing: 11.9,
          minColumns: 3,
          maxColumns: 6,
        ),
        6,
      );
      // 上限拦得住：超宽屏不无限扩列
      expect(
        MiBreakpoints.columnsForMaxCell(
          6000,
          maxCellWidth: 100,
          itemSpacing: 0,
          minColumns: 1,
          maxColumns: 8,
        ),
        8,
      );
      // 非有限宽度退回下限
      expect(
        MiBreakpoints.columnsForMaxCell(
          double.infinity,
          maxCellWidth: 210,
          minColumns: 4,
        ),
        4,
      );
    });
  });

  group('MiContentColumn', () {
    testWidgets('限宽 1120 + 水平居中 + 纵向撑满', (tester) async {
      Future<Rect> render(Size window) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = window;
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MiContentColumn(
                child: ColoredBox(
                  key: ValueKey('column'),
                  color: Colors.black,
                ),
              ),
            ),
          ),
        );
        return tester.getRect(find.byKey(const ValueKey('column')));
      }

      addTearDown(tester.view.reset);
      // 宽窗口：限到 1120 并居中（两侧各 (1366−1120)/2 = 123）
      var rect = await render(const Size(1366, 768));
      expect(rect.width, closeTo(MiBreakpoints.contentMaxWidth, 0.01));
      expect(rect.left, closeTo(123, 0.01));
      expect(rect.height, closeTo(768, 0.01), reason: '纵向撑满，不垂直居中');

      // 窄窗口：不生效（手机 / 平板画面不会变小）
      rect = await render(const Size(393, 856));
      expect(rect.width, closeTo(393, 0.01));
      expect(rect.left, closeTo(0, 0.01));
    });
  });

  group('MiScaledCanvas', () {
    test('scaleFor 取两方向较小者、只缩不放', () {
      const design = Size(393, 856);
      // 宽受限
      expect(MiScaledCanvas.scaleFor(const Size(200, 800), design),
          closeTo(200 / 393, 1e-9));
      // 高受限
      expect(MiScaledCanvas.scaleFor(const Size(800, 400), design),
          closeTo(400 / 856, 1e-9));
      // 空间足够：按上限 1x，不放大
      expect(MiScaledCanvas.scaleFor(const Size(800, 1000), design), 1.0);
      // 显式放开上限：仍取两方向较小者（这里高受限）
      expect(
        MiScaledCanvas.scaleFor(const Size(800, 1000), design, maxScale: 2),
        closeTo(1000 / 856, 1e-9),
      );
      // 两方向都无界：不无限放大
      expect(
        MiScaledCanvas.scaleFor(const Size(double.infinity, double.infinity), design),
        1.0,
      );
    });

    testWidgets('画布按设计尺寸布局、按比例渲染，且完整落在父级内', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(200, 400);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiScaledCanvas(
              designSize: const Size(393, 856),
              child: const ColoredBox(
                key: ValueKey('canvas'),
                color: Colors.black,
              ),
            ),
          ),
        ),
      );

      // 布局尺寸 = 设计尺寸（逻辑尺寸不变，只改渲染尺寸）
      final logical = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('canvas')),
      ).size;
      expect(logical, const Size(393, 856));

      // 渲染尺寸 = 等比缩放到 200×400 内（高受限 → 高撑满 400）
      final rect = tester.getRect(find.byKey(const ValueKey('canvas')));
      expect(rect.height, closeTo(400, 0.01));
      expect(rect.width, closeTo(393 * 400 / 856, 0.01));
      expect(rect.width / rect.height, closeTo(393 / 856, 1e-6));
      expect(tester.takeException(), isNull);
    });
  });

  group('DemoStage 外壳三档', () {
    test('compact 手机全屏 = 1:1，小窗等比缩小且不溢出', () {
      // 参考机全屏：完全 1:1（不留边距）
      var frame = DemoStage.sizeFor(const Size(393, 856));
      expect(frame.logical, DemoStage.designCanvas);
      expect(frame.rendered, DemoStage.designCanvas);
      expect(frame.isScaled, isFalse);
      expect(frame.scale, 1.0);

      // 桌面小窗：整机缩进去，宽高比不变
      frame = DemoStage.sizeFor(const Size(260, 470));
      expect(frame.rendered.width, lessThanOrEqualTo(260.001));
      expect(frame.rendered.height, lessThanOrEqualTo(470.001));
      expect(frame.rendered.width / frame.rendered.height,
          closeTo(393 / 856, 1e-9));
      expect(frame.isScaled, isTrue);

      // 极小窗：继续缩，仍不溢出
      frame = DemoStage.sizeFor(const Size(120, 300));
      expect(frame.rendered.width, lessThanOrEqualTo(120.001));
      expect(frame.rendered.height, lessThanOrEqualTo(300.001));
      expect(frame.rendered.width / frame.rendered.height,
          closeTo(393 / 856, 1e-9));
    });

    test('medium 平板：铺满窗口（不再有小手机框 / 外围卡片）', () {
      // 800×1000 平板竖屏：画面 = 窗口
      final frame = DemoStage.sizeFor(const Size(800, 1000));
      expect(frame.logical, const Size(800, 1000));
      expect(frame.rendered, frame.logical);
      expect(frame.isScaled, isFalse);

      // 实机尺寸（2026-10-18 平板截图 1536×2560 @2x → 768×1280 逻辑）：
      // 画面 = 768×1280（此前是居中的 720×1232 卡片）
      final pad = DemoStage.sizeFor(const Size(768, 1280));
      expect(pad.logical, const Size(768, 1280));
      expect(pad.rendered, pad.logical);
      expect(pad.isScaled, isFalse);
    });

    test('expanded 桌面：铺满窗口且不超出', () {
      final wide = DemoStage.sizeFor(const Size(1366, 768));
      expect(wide.logical, const Size(1366, 768));
      expect(wide.rendered, wide.logical); // 1x，不缩放
      expect(wide.rendered.width, lessThanOrEqualTo(1366.001));
      expect(wide.rendered.height, lessThanOrEqualTo(768.001));

      // 刚好过断点：同样铺满
      final edge = DemoStage.sizeFor(const Size(1024, 768));
      expect(edge.logical, const Size(1024, 768));

      // 宽而极矮：不再有"最小舞台高"，画面就是窗口，内容自己滚动
      final squat = DemoStage.sizeFor(const Size(1400, 420));
      expect(squat.logical, const Size(1400, 420));
      expect(squat.rendered, squat.logical);
      expect(squat.rendered.height, lessThanOrEqualTo(420.001));
      expect(squat.rendered.width, lessThanOrEqualTo(1400.001));
    });
  });

  group('示例应用（DemoHome）实际渲染', () {
    /// 设定窗口逻辑尺寸（dpr = 1 → physicalSize 即逻辑尺寸）。
    void setWindow(WidgetTester tester, Size size) {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
    }

    testWidgets('260×470 小窗：整机完整可见、无溢出', (tester) async {
      setWindow(tester, const Size(260, 470));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final nav = tester.getRect(find.byType(MiGlassNavBar));
      expect(nav.left, greaterThanOrEqualTo(-0.01));
      expect(nav.right, lessThanOrEqualTo(260.01));
      expect(nav.bottom, lessThanOrEqualTo(470.01));
      // 整机（页面区）也在窗口内
      final page = tester.getRect(find.byType(MockPage));
      expect(page.width, lessThanOrEqualTo(260.01));
      expect(page.height, lessThanOrEqualTo(470.01));
    });

    testWidgets('393×856 手机：画面 1:1、顶栏与底栏位置不变', (tester) async {
      setWindow(tester, const Size(393, 856));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // 画面宽 393 ≤ 导航断点 600 → 仍是底部栏
      expect(find.byType(MiGlassNavBar), findsOneWidget);

      final page = tester.getRect(find.byType(MockPage));
      expect(page.width, closeTo(393, 0.01));
      expect(page.height, closeTo(856, 0.01));
    });

    testWidgets('768×1280 平板：画面铺满可用空间、无溢出', (tester) async {
      setWindow(tester, const Size(768, 1280));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final page = tester.getRect(find.byType(MockPage));
      // 画面 = 窗口 768×1280（铺满、无外围卡片）；画面宽 > 导航断点 600 →
      // 用侧栏，页面让出 120.9 的侧栏列。
      expect(
        page.width,
        closeTo(768 - MiGlassSideNavMetrics.gutterWidth, 0.01),
      );
      expect(page.height, closeTo(1280, 0.01));
      expect(page.left, closeTo(MiGlassSideNavMetrics.gutterWidth, 0.01));
      expect(page.left, greaterThanOrEqualTo(0));
      expect(page.right, lessThanOrEqualTo(768.01));
      expect(page.bottom, lessThanOrEqualTo(1280.01));
    });

    testWidgets('窗口尺寸实时变化会重排（无需重建 App）', (tester) async {
      setWindow(tester, const Size(393, 856));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(MockPage)).width, closeTo(393, 0.01));

      // 手机 → 桌面：画面铺满窗口、底部栏换成侧栏；**内容列**限宽 1120 居中
      //（列宽 = min(窗口 − 侧栏列, 1120)，两侧留白相等）。
      setWindow(tester, const Size(1366, 768));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final wide = tester.getRect(find.byType(MockPage));
      final area = 1366 - MiGlassSideNavMetrics.gutterWidth;
      final column = math.min(area, MiBreakpoints.contentMaxWidth);
      expect(wide.width, closeTo(column, 0.01));
      expect(
        wide.left,
        closeTo(MiGlassSideNavMetrics.gutterWidth + (area - column) / 2, 0.01),
      );

      // 桌面 → 小窗：又缩回等比 contain
      setWindow(tester, const Size(240, 400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final small = tester.getRect(find.byType(MockPage));
      expect(small.width, lessThanOrEqualTo(240.01));
      expect(small.width / small.height, closeTo(393 / 856, 1e-3));
    });
  });

  group('内容层断点', () {
    /// 在指定窗口宽度下渲染首页，数出主题卡首行有几张。
    Future<int> firstRowCards(WidgetTester tester, double width) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            body: MockPage(0, key: UniqueKey(), themeMode: MiThemeMode.dark),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final cards = find.byType(MiThemeCard);
      final count = cards.evaluate().length;
      final firstTop = tester.getTopLeft(cards.at(0)).dy;
      var n = 0;
      for (var i = 0; i < count; i++) {
        if ((tester.getTopLeft(cards.at(i)).dy - firstTop).abs() < 0.5) n++;
      }
      return n;
    }

    testWidgets('主题卡网格 3 / 3 / 6 列（6 张卡按断点 3+3 或整排）', (tester) async {
      addTearDown(tester.view.reset);
      expect(await firstRowCards(tester, 393), 3); // compact：与参考截图同款
      expect(await firstRowCards(tester, 800), 3); // medium：6 张卡 3+3，不出现 4+2 缺角
      expect(await firstRowCards(tester, 1200), 6); // expanded：横版整排 6 张
    });

    testWidgets('展示页网格 4 / 6 / 8 列且不溢出', (tester) async {
      addTearDown(tester.view.reset);
      Future<int> columns(double width) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(useMaterial3: true),
            home: Scaffold(
              body: MockPage(1, key: UniqueKey(), themeMode: MiThemeMode.dark),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 网格首行 = MiResponsiveGrid 直接生成的第一行 Row；
        // 其 children 交替为 [格子, 间距, 格子, …] → 列数 = (n + 1) / 2。
        final grid = find.byType(MiResponsiveGrid);
        expect(grid, findsOneWidget);
        final firstRow = tester.widget<Row>(
          find.descendant(of: grid, matching: find.byType(Row)).first,
        );
        return (firstRow.children.length + 1) ~/ 2;
      }

      expect(await columns(393), 4); // compact
      expect(await columns(800), 6); // medium
      expect(await columns(1200), 8); // expanded
    });
  });

  group('MiResponsiveGrid', () {
    Widget gridWith({required double width, required int count}) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: MiResponsiveGrid(
                compactColumns: 3,
                mediumColumns: 4,
                expandedColumns: 6,
                itemSpacing: 10,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < count; i++)
                    SizedBox(key: ValueKey(i), height: 20),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('等分列宽、末行留空不拉伸、不溢出', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 400);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(gridWith(width: 300, count: 7));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      const cellWidth = (300 - 2 * 10) / 3; // 93.33
      final a = tester.getTopLeft(find.byKey(const ValueKey(0)));
      final b = tester.getTopLeft(find.byKey(const ValueKey(1)));
      final d = tester.getTopLeft(find.byKey(const ValueKey(3)));
      // 3 列：列宽 93.33、相邻列起点差 = 列宽 + 间距 10
      expect(b.dx - a.dx, closeTo(cellWidth + 10, 0.01));
      // 第 4 项回到第一列、落到下一行
      expect(d.dx, closeTo(a.dx, 0.01));
      expect(d.dy, greaterThan(a.dy));
      // 每格宽 = 列宽（Expanded 等分，末行只有 1 项也不被拉满行）
      expect(
        tester.getSize(find.byKey(const ValueKey(0))).width,
        closeTo(cellWidth, 0.01),
      );
    });

    testWidgets('宽容器换到 6 列', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 400);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(gridWith(width: 1100, count: 7));
      await tester.pumpAndSettle();
      final a = tester.getTopLeft(find.byKey(const ValueKey(0)));
      final e = tester.getTopLeft(find.byKey(const ValueKey(5)));
      final f = tester.getTopLeft(find.byKey(const ValueKey(6)));
      expect(e.dy, closeTo(a.dy, 0.01)); // 第 6 项仍在首行
      expect(f.dy, greaterThan(a.dy)); // 第 7 项换行
    });
  });

  group('MiViewport', () {
    testWidgets('随窗口尺寸变化重建', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(393, 856);
      addTearDown(tester.view.reset);

      final seen = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final viewport = MiViewport.of(context);
              seen.add(viewport.windowSize.name);
              return Text(viewport.windowSize.name);
            },
          ),
        ),
      );
      expect(find.text('compact'), findsOneWidget);

      tester.view.physicalSize = const Size(800, 856);
      await tester.pumpAndSettle();
      expect(find.text('medium'), findsOneWidget);

      tester.view.physicalSize = const Size(1400, 900);
      await tester.pumpAndSettle();
      expect(find.text('expanded'), findsOneWidget);
      expect(seen, ['compact', 'medium', 'expanded']);
    });
  });
}
