import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_like_ui/demo/demo_app.dart';
import 'package:mi_like_ui/demo/mock_pages.dart';
import 'package:mi_like_ui/mi_like_ui.dart';

/// 页面推入转场（[MiCardPageRoute]）—— 几何 / 时值 / 两种角色 / 终态零图层。
void main() {
  const pageKey = ValueKey('incoming');
  const hostKey = ValueKey('host');
  const w = 393.0;
  const h = 856.0;

  Future<void> pumpHost(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(w, h);
    addTearDown(tester.view.reset);
    // 宿主首页**也用本路由**：下层页的视差靠 secondaryAnimation，
    // 平台自带路由没有这个钩子。
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        initialRoute: '/',
        onGenerateRoute: (settings) => MiCardPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            key: hostKey,
            body: Center(
              child: TextButton(
                onPressed: () => navigatorKey.currentState!.push(
                  MiCardPageRoute<void>(
                    builder: (_) => const Scaffold(
                      key: pageKey,
                      body: SizedBox.expand(),
                    ),
                  ),
                ),
                child: const Text('push'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double leftOf(WidgetTester tester, Key key) =>
      tester.getTopLeft(find.byKey(key)).dx;

  group('几何与时值', () {
    test('时值 / 圆角 / 视差都是度量值', () {
      expect(MiCardPageRouteMetrics.durationMs, 400);
      // 素材 190px ÷ 3.104 px/dp = 61.2
      expect(MiCardPageRouteMetrics.cornerRadius, moreOrLessEquals(61.2));
      expect(MiCardPageRouteMetrics.parallaxFraction, 0.25);
      expect(MiCardPageRouteMetrics.dimAlpha, moreOrLessEquals(0.55));
      // 位置曲线 = easeOutCubic
      expect(
        MiCardPageRouteMetrics.motion.transform(0.5),
        moreOrLessEquals(Curves.easeOutCubic.transform(0.5)),
      );
    });

    test('压暗随进度线性淡入，两端夹紧', () {
      expect(MiTransparencyTokens.pushDimAt(0).a, 0);
      expect(
        MiTransparencyTokens.pushDimAt(1).a,
        moreOrLessEquals(MiTransparencyTokens.pushDimAlphaMax, epsilon: 0.01),
      );
      expect(
        MiTransparencyTokens.pushDimAt(0.5).a,
        moreOrLessEquals(MiTransparencyTokens.pushDimAlphaMax * 0.5,
            epsilon: 0.01),
      );
      // 越界不炸
      expect(MiTransparencyTokens.pushDimAt(-1).a, 0);
      expect(MiTransparencyTokens.pushDimAt(2).a,
          moreOrLessEquals(MiTransparencyTokens.pushDimAlphaMax, epsilon: 0.01));
    });

    testWidgets('新页起手整页在右缘外、400ms 归位到 0', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.text('push'));
      await tester.pump();
      await tester.pump();
      expect(leftOf(tester, pageKey), moreOrLessEquals(w, epsilon: 1),
          reason: '起手 = FractionalTranslation(+1)，整页在右缘外');
      // 半程：easeOutCubic 已经走掉 87.5%，故只要求落在中间区间
      await tester.pump(const Duration(milliseconds: 100));
      final mid = leftOf(tester, pageKey);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(w));
      await tester.pump(const Duration(milliseconds: 300));
      expect(leftOf(tester, pageKey), moreOrLessEquals(0, epsilon: 0.5));
    });

    testWidgets('转场中前缘有 61.2 圆角，归位后不再裁剪', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.text('push'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final clip = tester.widget<ClipRRect>(
        find
            .ancestor(
              of: find.byKey(pageKey),
              matching: find.byType(ClipRRect),
            )
            .first,
      );
      expect(
        clip.borderRadius,
        BorderRadius.circular(MiCardPageRouteMetrics.cornerRadius),
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.ancestor(
          of: find.byKey(pageKey),
          matching: find.byType(ClipRRect),
        ),
        findsNothing,
        reason: '归位后不加任何图层：静止页逐像素不变',
      );
    });

    testWidgets('转场中铺全屏压暗，归位后撤掉', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.text('push'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final dim = MiTransparencyTokens.pushDimAt(0.5).a;
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is ColoredBox &&
              w.color.r == 0 &&
              w.color.g == 0 &&
              w.color.b == 0 &&
              (w.color.a - dim).abs() < 0.02,
        ),
        findsWidgets,
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color.a > 0 && w.color.a < 0.9,
        ),
        findsNothing,
        reason: '归位后不再留半透明层（否则静止页多一次全屏绘制）',
      );
    });

    testWidgets('下层页按 0.25 × 页宽左移，且不缩放', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.text('push'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final visual = Curves.easeOutCubic.transform(0.5);
      expect(
        leftOf(tester, hostKey),
        moreOrLessEquals(-MiCardPageRouteMetrics.parallaxFraction * w * visual),
      );
      // 高度不变 → 只平移、没缩放
      expect(
        tester.getSize(find.byKey(hostKey)).height,
        moreOrLessEquals(h),
      );
      await tester.pumpAndSettle();
    });
  });

  group('进出与栈行为', () {
    testWidgets('返回时新页滑回右缘并出栈', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      expect(find.byKey(pageKey), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final mid = leftOf(tester, pageKey);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(w));

      await tester.pumpAndSettle();
      expect(find.byKey(pageKey), findsNothing);
      // 下层页回到原位
      expect(leftOf(tester, hostKey), moreOrLessEquals(0, epsilon: 0.5));
    });

    testWidgets('压暗层不吃手势', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.text('push'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final dimBox = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color.r == 0 && w.color.a > 0,
      );
      expect(
        tester
            .widget<IgnorePointer>(
              find.ancestor(of: dimBox, matching: find.byType(IgnorePointer))
                  .first,
            )
            .ignoring,
        isTrue,
      );
      await tester.pumpAndSettle();
    });
  });

  group('示例接线', () {
    testWidgets('点首页搜索栏推入搜索页，返回圆钮出栈', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(w, h);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MiSearchBar));
      // 光标闪烁是不停的定时器：不用 pumpAndSettle，按固定时长推进
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 420));
      expect(find.byType(DemoSearchPage), findsOneWidget);
      // 首页留在栈里（`maintainState`）：被上层不透明路由盖住 → offstage，
      // 但 State 没销毁，返回不重建、滚动位置不丢
      expect(find.byType(DemoHome, skipOffstage: false), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('searchBack')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 420));
      expect(find.byType(DemoSearchPage), findsNothing);
      expect(find.byType(MiSearchBar), findsOneWidget);
    });

    testWidgets('搜索页头部几何：圆钮 / 输入框 / 搜索钮 三者等高对齐', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(w, h);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MiSearchBar));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 420));

      final back = tester.getRect(find.byKey(const ValueKey('searchBack')));
      final field = tester.getRect(find.byKey(const ValueKey('searchField')));
      expect(back.width, moreOrLessEquals(MiSearchBarMetrics.barHeight));
      expect(back.height, moreOrLessEquals(MiSearchBarMetrics.barHeight));
      // 输入框与圆钮同一水平中心（度量：三者中心都在 y = 74.15dp）
      expect(field.center.dy, moreOrLessEquals(back.center.dy, epsilon: 0.5));
      // 左缘 11.9、圆钮 → 输入框 11.0
      expect(back.left, moreOrLessEquals(11.9, epsilon: 0.2));
      expect(field.left - back.right, moreOrLessEquals(11.0, epsilon: 0.2));
    });
  });

  group('宽屏档（桌面 ≥1024：淡入 + 4dp 抬起，推导值）', () {
    /// 宽屏宿主：同 pumpHost 但窗口 1366×768。
    Future<void> pumpWideHost(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1366, 768);
      addTearDown(tester.view.reset);
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          initialRoute: '/',
          onGenerateRoute: (settings) => MiCardPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(
              key: hostKey,
              body: Center(
                child: TextButton(
                  onPressed: () => navigatorKey.currentState!.push(
                    MiCardPageRoute<void>(
                      builder: (_) => const Scaffold(
                        key: pageKey,
                        body: SizedBox.expand(),
                      ),
                    ),
                  ),
                  child: const Text('push'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    test('时值 / 位移 / 圆角常量（推导值）', () {
      expect(MiCardPageRouteMetrics.wideDurationMs, 220);
      expect(
        MiCardPageRouteMetrics.wideVisualFraction,
        moreOrLessEquals(220 / 400),
      );
      expect(MiCardPageRouteMetrics.wideRiseDp, 4);
      expect(MiCardPageRouteMetrics.wideCornerRadius, 16);
      // 判定阈值与桌面断点同值
      expect(MiCardPageRouteMetrics.isWide(1023), isFalse);
      expect(MiCardPageRouteMetrics.isWide(1024), isTrue);
    });

    testWidgets('起手：4dp 抬起 + 同色幕布盖满；不横移、不压暗下层', (tester) async {
      await pumpWideHost(tester);
      await tester.tap(find.text('push'));
      await tester.pump();
      await tester.pump();

      // 不横移：新页左缘仍在 0（手机档起手在右缘外 = 屏宽）
      expect(leftOf(tester, pageKey), moreOrLessEquals(0, epsilon: 0.5),
          reason: '桌面档不横移');
      // 4dp 抬起：新页顶缘在 +4
      expect(
        tester.getTopLeft(find.byKey(pageKey)).dy,
        moreOrLessEquals(MiCardPageRouteMetrics.wideRiseDp, epsilon: 0.5),
      );
      // 同色幕布（页底色实色，不是 Opacity/FadeTransition —— 磨砂子树的坑）
      final veil = tester.widget<ColoredBox>(
        find.byKey(MiCardPageRoute.wideVeilKey),
      );
      expect(veil.color.a, greaterThan(0.9), reason: '起手幕布应近乎不透明');
      // 子树里不许出现 FadeTransition（saveLayer 会清空磨砂底图）
      expect(
        find.ancestor(
          of: find.byKey(pageKey),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );

      // 幕布不吃点击（IgnorePointer 包着）
      expect(
        find.ancestor(
          of: find.byKey(MiCardPageRoute.wideVeilKey),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );
    });

    testWidgets('220ms 视觉落定：位移归零、幕布撤掉、无裁剪（零额外图层）',
        (tester) async {
      await pumpWideHost(tester);
      await tester.tap(find.text('push'));
      await tester.pump();
      // 视觉曲线只走前 55%（220ms）；多泵几帧到绝对稳态
      await tester.pump(const Duration(milliseconds: 230));

      expect(
        tester.getTopLeft(find.byKey(pageKey)).dy,
        moreOrLessEquals(0, epsilon: 0.5),
        reason: '4dp 位移应归零',
      );
      // 落定后 ClipRRect / 幕布都不在（静止页零额外绘制）
      expect(
        find.ancestor(
          of: find.byKey(pageKey),
          matching: find.byType(ClipRRect),
        ),
        findsNothing,
      );
    });

    testWidgets('桌面示例：点搜索栏推入搜索页仍正常（宽档转场接线）', (tester) async {
      await pumpWideHost(tester);
      // 换成完整示例（宽屏档会走 _MiPushWide）
      tester.view.physicalSize = const Size(1366, 768);
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MiSearchBar));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 230));
      expect(find.byType(DemoSearchPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
