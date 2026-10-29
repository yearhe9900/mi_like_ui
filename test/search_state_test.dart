import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_like_ui/demo/demo_app.dart';
import 'package:mi_like_ui/demo/mock_pages.dart';
import 'package:mi_like_ui/mi_like_ui.dart';

/// 搜索态（点按搜索栏 → 输入态）的几何 / 动效 / 交互。
///
/// 参考录屏「短信」搜索（592×1280 @24fps）实测值见
/// `search_cancel_metrics.dart` 与 `MiTopBarMetrics` 的搜索态段。

const double _w = 393;

/// 带搜索栏 + 胶囊行的可变宿主（`searchActive` 由它自己翻转）。
class _Host extends StatefulWidget {
  const _Host({
    this.themeMode = MiThemeMode.light,
    this.tabs = const ['推荐', '背屏'],
    this.onCancel,
    this.autofocus = false,
    this.controller,
    this.cancelInset,
    this.showBlur = false,
  });

  final MiThemeMode themeMode;
  final List<String>? tabs;
  final VoidCallback? onCancel;
  final bool autofocus;
  final TextEditingController? controller;
  final double? cancelInset;
  final bool showBlur;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool searching = false;
  final FocusNode focus = FocusNode();

  /// 进入 / 退出搜索态：给测试用（`setState` 是 protected，不能从外部调）。
  void openSearch() => setState(() => searching = true);
  void closeSearch() => setState(() => searching = false);

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Color(0xFFF3F3F3))),
            MiTopBar(
              key: const ValueKey('bar'),
              themeMode: widget.themeMode,
              searchHint: '搜索主题',
              searchActive: searching,
              searchAutofocus: widget.autofocus,
              searchController: widget.controller,
              searchFocusNode: focus,
              onSearchTap: () => setState(() => searching = true),
              onSearchCancel: () {
                widget.onCancel?.call();
                setState(() => searching = false);
              },
              tabs: widget.tabs,
              showSurface: false,
              showBlur: widget.showBlur,
              searchCancelInset:
                  widget.cancelInset ?? MiSearchCancelMetrics.trailingInset,
            ),
          ],
        ),
      ),
    );
  }
}

/// 取消钮当前淡入系数（组件自己的 `fade`，不是父级 `Opacity` —— 圆钮里有
/// backdrop 磨砂，saveLayer 会把它清空）。
double _cancelFade(WidgetTester tester) =>
    tester.widget<MiSearchCancelButton>(find.byType(MiSearchCancelButton)).fade;

MiTopBar _bar(WidgetTester tester) =>
    tester.widget<MiTopBar>(find.byKey(const ValueKey('bar')));

/// 顶栏磨砂段（满宽 `ClipRect + BackdropFilter`）的矩形 —— 段位 / 盒高一一对应。
///
/// 只取满宽的那些：搜索栏、胶囊行、取消钮各有自己的（窄）backdrop。
List<Rect> _bandRects(WidgetTester tester) {
  final rects = <Rect>[];
  for (final element in find.byType(BackdropFilter).evaluate()) {
    final rect = tester.getRect(find.byElementPredicate((e) => identical(e, element)));
    if (rect.left == 0 && rect.right == _w) rects.add(rect);
  }
  return rects;
}

Future<_HostState> _pump(
  WidgetTester tester, {
  MiThemeMode mode = MiThemeMode.light,
  List<String>? tabs = const ['推荐', '背屏'],
  VoidCallback? onCancel,
  bool autofocus = false,
  TextEditingController? controller,
  double? cancelInset,
  bool showBlur = false,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(_w, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_Host(
    themeMode: mode,
    tabs: tabs,
    onCancel: onCancel,
    autofocus: autofocus,
    controller: controller,
    cancelInset: cancelInset,
    showBlur: showBlur,
  ));
  await tester.pump();
  return tester.state<_HostState>(find.byType(_Host));
}

void main() {
  group('几何', () {
    testWidgets('常规态：搜索栏吃满 headerInset、没有取消钮', (tester) async {
      await _pump(tester);
      final bar = tester.getRect(find.byType(MiSearchBar));
      expect(bar.left, moreOrLessEquals(MiTopBarMetrics.headerInset));
      expect(bar.right, moreOrLessEquals(_w - MiTopBarMetrics.headerInset));
      expect(find.byType(MiSearchCancelButton), findsNothing);
    });

    testWidgets('搜索态：让位「间隙 + 直径」，取消钮贴右缘', (tester) async {
      final host = await _pump(tester);
      host.openSearch();
      await tester.pumpAndSettle();

      final bar = tester.getRect(find.byType(MiSearchBar));
      final cancel = tester.getRect(find.byType(MiSearchCancelButton));
      // 搜索栏右缘 → 取消钮左缘 = 实测 10.0
      expect(
        cancel.left - bar.right,
        moreOrLessEquals(MiSearchCancelMetrics.barGap),
      );
      // 取消钮右缘距屏幕右缘 = 实测 0（trailingInset）
      expect(cancel.right, moreOrLessEquals(_w));
      // 取消钮直径 = 搜索栏高 44.1
      expect(cancel.width, moreOrLessEquals(MiSearchBarMetrics.barHeight));
      expect(cancel.height, moreOrLessEquals(MiSearchBarMetrics.barHeight));
      // 同一垂心
      expect(cancel.center.dy, moreOrLessEquals(bar.center.dy));
      // 搜索栏本身不动（左缘不变、高度不变）
      expect(bar.left, moreOrLessEquals(MiTopBarMetrics.headerInset));
      expect(bar.height, moreOrLessEquals(MiSearchBarMetrics.barHeight));
    });

    testWidgets('searchCancelInset 可覆盖右缘留白', (tester) async {
      final host = await _pump(tester, cancelInset: 24);
      host.openSearch();
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(MiSearchCancelButton)).right,
        moreOrLessEquals(_w - 24),
      );
    });

    testWidgets('搜索态 occupiedHeight 不含胶囊行（少 16 + 39.9）', (tester) async {
      final host = await _pump(tester);
      final ctx = tester.element(find.byType(MiSearchBar));
      expect(_bar(tester).occupiedHeight(ctx), moreOrLessEquals(156));
      host.openSearch();
      await tester.pumpAndSettle();
      expect(
        _bar(tester).occupiedHeight(ctx),
        moreOrLessEquals(MiTopBarMetrics.headerTopInset +
            MiTopBarMetrics.searchBarSlotHeight),
      );
    });
  });

  group('动效', () {
    testWidgets('转场时长内走完；起手先静止，取消钮中段才淡入', (tester) async {
      const ms = MiTopBarMetrics.searchTransitionMs;
      final host = await _pump(tester);
      final rest = tester.getRect(find.byType(MiSearchBar)).width;

      host.openSearch();
      await tester.pump();
      // 第 0 帧：几何还是原样，取消钮压根没建（不白挂 backdrop / 手势层）
      expect(tester.getRect(find.byType(MiSearchBar)).width, rest);
      expect(find.byType(MiSearchCancelButton), findsNothing);

      // 1/4 时程：位移已走掉一大半（easeOutQuint + 前 10% 静止），但取消钮
      // 还没到淡入区间（起于 35%）→ 现算 alpha 必须是 0
      await tester.pump(Duration(milliseconds: ms ~/ 4));
      final mid = tester.getRect(find.byType(MiSearchBar)).width;
      expect(mid, lessThan(rest));
      expect(mid, greaterThan(rest - 54.1)); // 还没走完
      expect(_cancelFade(tester), 0);

      // 半程：落在淡入区间（0.35…0.62）中段
      await tester.pump(Duration(milliseconds: ms ~/ 4));
      final alpha = _cancelFade(tester);
      expect(alpha, greaterThan(0));
      expect(alpha, lessThan(1));

      // 收尾：一切就位
      await tester.pump(Duration(milliseconds: ms));
      expect(
        tester.getRect(find.byType(MiSearchBar)).width,
        moreOrLessEquals(_w -
            MiTopBarMetrics.headerInset -
            (MiSearchCancelMetrics.barGap + MiSearchCancelMetrics.diameter)),
      );
      expect(_cancelFade(tester), 1);
    });

    testWidgets('转场期间材质盒高钉住：磨砂段不逐帧重排', (tester) async {
      const ms = MiTopBarMetrics.searchTransitionMs;
      final host = await _pump(tester, showBlur: true);
      final rest = _bandRects(tester);
      expect(rest, isNotEmpty, reason: '头部区磨砂是分段 ClipRect + BackdropFilter');

      host.openSearch();
      await tester.pump();
      await tester.pump(Duration(milliseconds: ms ~/ 3));
      final a = _bandRects(tester);
      await tester.pump(Duration(milliseconds: ms ~/ 3));
      final b = _bandRects(tester);

      // 盒高若随进度插值，每条段的 top / height 每帧都变 → 9 条全宽高斯每帧
      // 重跑一遍（转场丢帧的主因）。钉住后两帧矩形必须逐值相等。
      expect(a.length, rest.length);
      expect(b, a, reason: '磨砂段矩形在转场中必须恒定');
    });

    testWidgets('淡出都不套 Opacity：含磨砂的子树进 saveLayer 会丢磨砂、每帧多一次离屏',
        (tester) async {
      final host = await _pump(tester);
      host.openSearch();
      await tester.pump();
      // 走到淡入区间内（半程）：取消钮在树上、胶囊行还没退干净
      await tester.pump(
          Duration(milliseconds: MiTopBarMetrics.searchTransitionMs ~/ 2));

      final pills = tester.widget<MiPillTabBar>(find.byType(MiPillTabBar));
      expect(pills.fade, inExclusiveRange(0, 1));
      for (final target in [find.byType(MiPillTabBar), find.byType(MiSearchCancelButton)]) {
        expect(
          find.ancestor(of: target, matching: find.byType(Opacity)),
          findsNothing,
          reason: '淡出走颜色 alpha（组件 fade 参数），不是 Opacity',
        );
      }
    });

    testWidgets('退出搜索态会把取消钮与让位一起收回', (tester) async {
      final host = await _pump(tester);
      host.openSearch();
      await tester.pumpAndSettle();
      expect(find.byType(MiSearchCancelButton), findsOneWidget);

      host.closeSearch();
      await tester.pumpAndSettle();
      expect(find.byType(MiSearchCancelButton), findsNothing);
      final bar = tester.getRect(find.byType(MiSearchBar));
      expect(bar.right, moreOrLessEquals(_w - MiTopBarMetrics.headerInset));
    });
  });

  group('交互', () {
    testWidgets('点取消钮回调 onSearchCancel', (tester) async {
      var called = 0;
      final host = await _pump(tester, onCancel: () => called++);
      host.openSearch();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MiSearchCancelButton));
      await tester.pumpAndSettle();
      expect(called, 1);
      expect(find.byType(MiSearchCancelButton), findsNothing);
    });

    testWidgets('点搜索栏进入搜索态（onSearchTap）', (tester) async {
      final host = await _pump(tester);
      await tester.tap(find.byType(MiSearchBar));
      await tester.pumpAndSettle();
      expect(host.searching, isTrue);
    });
  });

  group('输入态', () {
    testWidgets('内置搜索栏换成 TextField：hint 仍在、光标色是强调蓝', (tester) async {
      final host = await _pump(tester);
      expect(find.byType(TextField), findsNothing);
      host.openSearch();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.cursorColor, MiSearchBarPalette.light.caret);
      expect(field.cursorHeight, MiSearchBarMetrics.caretHeight);
      // 实测行为：聚焦后**占位文字不消失**，与光标同现
      expect(find.text('搜索主题'), findsOneWidget);
    });

    testWidgets('能真正输入（controller 收到文字）', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final host = await _pump(tester, controller: controller);
      host.openSearch();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextField), '壁纸');
      await tester.pump();
      expect(controller.text, '壁纸');
      // 有内容后占位文字的隐藏由 `InputDecorator` 自己负责（它用
      // `FadeTransition` 而不是摘 widget，透明度不挂在通用 `Opacity` 上，
      // 所以这里只验输入真的进了 controller，不重复锁框架内部实现）
    });

    testWidgets('autofocus 生效：进入即拿到焦点（键盘会弹出）', (tester) async {
      final host = await _pump(tester, autofocus: true);
      host.openSearch();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(host.focus.hasFocus, isTrue);
    });
  });

  group('取消钮组件', () {
    testWidgets('默认尺寸 = 搜索栏高，叉号墨盒 17dp、墨色是前景墨色', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MiSearchCancelButton(
                onTap: () {},
                themeMode: MiThemeMode.light,
                frosted: false,
              ),
            ),
          ),
        ),
      );
      final box = tester.getSize(find.byType(MiSearchCancelButton));
      expect(box.width, moreOrLessEquals(MiSearchCancelMetrics.diameter));
      expect(box.height, moreOrLessEquals(MiSearchCancelMetrics.diameter));
      // 直径刻意等于搜索栏高：两处同值，改一处漏另一处会红
      expect(
        MiSearchCancelMetrics.diameter,
        moreOrLessEquals(MiSearchBarMetrics.barHeight),
      );

      final glyph = tester.widget<CustomPaint>(find.descendant(
        of: find.byType(MiSearchCancelButton),
        matching: find.byType(CustomPaint),
      ).last);
      expect(
        glyph.size.width,
        moreOrLessEquals(MiSearchCancelMetrics.glyphSize),
      );
      final painter = glyph.painter! as SearchCancelGlyphPainter;
      expect(painter.color, MiSearchBarPalette.light.cancelInk);
      // 实测叉号 0（纯黑）而放大镜 167：两者**不能**共用一档
      expect(painter.color, isNot(MiSearchBarPalette.light.icon));
    });

    testWidgets('onTap = null 时只展示、不可点', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: MiSearchCancelButton(onTap: null))),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(MiSearchCancelButton),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
    });
  });

  test('searchActive 而没有搜索栏 → 构造期断言', () {
    expect(
      () => MiTopBar(searchActive: true, tabs: const ['a']),
      throwsA(isA<AssertionError>()),
    );
  });

  group('示例外壳', () {
    testWidgets('进入搜索态收起浮动底栏，退出后装回来', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(_w, 856);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      expect(find.byType(MiGlassNavBar), findsOneWidget);

      // 原地搜索态在「分类」页演示：首页那条搜索栏改成**推入搜索页**
      // （`MiCardPageRoute`，见 card_page_route_test）。两条路径都支持。
      await tester.tap(find.descendant(
        of: find.byType(MiGlassNavBar),
        matching: find.text('分类'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MiSearchBar));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 520));
      // 搜索是聚焦态：App 级浮动底栏（连同绿色圆钮）收起
      expect(find.byType(MiGlassNavBar), findsNothing);
      expect(find.byType(MiGlassNavFab), findsNothing);

      await tester.tap(find.byType(MiSearchCancelButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 520));
      expect(find.byType(MiGlassNavBar), findsOneWidget);
    });

    testWidgets('键盘弹出不改画面尺寸（viewInsets 不吃布局）', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(_w, 856);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      final before = tester.getRect(find.byType(MockPage));

      // 模拟键盘：Insets 一下顶上来 300
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      expect(
        tester.getRect(find.byType(MockPage)),
        before,
        reason: '画面被键盘挤小 → 等比缩放会把整块画布缩水（真机反馈）',
      );
    });
  });

  testWidgets('取消钮桌面语义（推导）：悬停叠色 + 聚焦环 + Enter 退出搜索', (tester) async {
    var cancelled = 0;
    final host = await _pump(
      tester,
      mode: MiThemeMode.dark,
      onCancel: () => cancelled++,
    );
    host.openSearch();
    await tester.pumpAndSettle();

    final cancel = find.byType(MiSearchCancelButton);
    expect(cancel, findsOneWidget);

    // 悬停（鼠标进入圆钮）→ 叠色 = 按压高光的 60%（桌面推导语义）
    final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await hover.addPointer(location: tester.getCenter(cancel));
    await tester.pump();
    final overlay = tester.widget<AnimatedContainer>(
      find.descendant(of: cancel, matching: find.byKey(MiHoverFeedback.overlayKey)),
    );
    expect(
      (overlay.decoration! as BoxDecoration).color,
      MiTransparencyTokens.hoverOverlayFor(MiThemeMode.dark),
    );
    await hover.removePointer();
    await tester.pumpAndSettle();

    // 聚焦（等价 Tab 走到）→ 环；Enter 激活 → onCancel
    tester
        .widget<Focus>(
          find.descendant(of: cancel, matching: find.byType(Focus)),
        )
        .focusNode!
        .requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final ring = tester.widget<AnimatedContainer>(
      find.descendant(of: cancel, matching: find.byKey(MiFocusRing.ringKey)),
    );
    expect(
      (ring.decoration! as BoxDecoration).border!.top.color,
      isNot(Colors.transparent),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(cancelled, 1);
  });
}
