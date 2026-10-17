import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；若导出缺失会在这里暴露。
import 'package:mi_like_ui/mi_like_ui.dart';
import 'package:mi_like_ui/demo/mock_pages.dart';

const String kTitle = '显示与亮度';

/// 顶栏叠在纯黑内容之上（与参考页同底），默认 393x240 逻辑像素。
///
/// [showBack] 默认 true：本文件大部分用例针对返回圆钮（几何 / 交互），
/// 而组件默认值是 false（顶层页无返回），故 harness 显式打开；
/// 「默认不显示」本身另有专门用例。
Widget harness({
  String? title = kTitle,
  double offset = 0,
  MiThemeMode? mode = MiThemeMode.dark,
  bool showBack = true,
  VoidCallback? onBack,
  VoidCallback? onBackgroundTap,
  Widget? searchBar,
  Widget? tabBar,
  String? searchHint,
  List<String>? tabs,
  int selectedTab = 0,
  ValueChanged<int>? onTabChanged,
  VoidCallback? onSearchTap,
  PreferredSizeWidget? header,
  bool showSurface = true,
  bool showBlur = true,
  double headerInset = MiTopBarMetrics.headerInset,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBackgroundTap,
              child: const ColoredBox(color: Color(0xFF000000)),
            ),
          ),
          MiTopBar(
            title: title,
            showBack: showBack,
            scrollOffset: offset,
            themeMode: mode,
            onBack: onBack,
            searchBar: searchBar,
            tabBar: tabBar,
            searchHint: searchHint,
            tabs: tabs,
            selectedTab: selectedTab,
            onTabChanged: onTabChanged,
            onSearchTap: onSearchTap,
            header: header,
            showSurface: showSurface,
            showBlur: showBlur,
            headerInset: headerInset,
          ),
        ],
      ),
    ),
  );
}

/// 两条标题同文案，按字号区分（大标题 31.83 / 紧凑标题 18.0）。
Finder titleText(TextStyle style) => find.byWidgetPredicate(
      (w) => w is Text && w.data == kTitle && w.style?.fontSize == style.fontSize,
    );

Finder get _large => titleText(MiTypography.topBarLargeTitle);
Finder get _compact => titleText(MiTypography.topBarCompactTitle);

Finder get _scrimDark => find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).gradient ==
              MiTopBarPalette.dark.scrimGradient,
    );

Finder get _scrimLight => find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).gradient ==
              MiTopBarPalette.light.scrimGradient,
    );

Finder get _chevron => find.descendant(
      of: find.byType(MiTopBar),
      matching: find.byType(CustomPaint),
    );

Finder get _backHitArea => find.descendant(
      of: find.byType(MiTopBar),
      matching: find.byType(GestureDetector),
    );

Finder get _pressDisc => find.ancestor(
      of: find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle,
      ),
      matching: find.byType(AnimatedOpacity),
    );

double _opacityOf(WidgetTester tester, Finder finder) => tester
    .widget<Opacity>(find.ancestor(of: finder, matching: find.byType(Opacity)))
    .opacity;

/// 紧凑标题外层那个 `Padding`（最近祖先，即组件里包 `Center` 的那个）。
EdgeInsets _compactPadding(WidgetTester tester) => tester
    .widgetList<Padding>(
      find.ancestor(of: _compact, matching: find.byType(Padding)),
    )
    .first
    .padding as EdgeInsets;

/// 标题的**基线目标值** = `Baseline` 组件的 `baseline` 参数（基线距组件顶端）。
///
/// 不用 `RenderObject.getDistanceToBaseline`：本 SDK 对这个方法有「只能在
/// **父级正在 layout / paint 时**调用」的断言（`box.dart` 里的 owner /
/// debugActiveLayout 检查），在测试体里调会直接抛断言。改断言组件的**输入
/// 契约** —— `RenderBaseline` 已保证「子级基线落在此参数处」，故入参正确
/// ⇔ 落点正确。
double _baselineArgOf(WidgetTester tester, Finder textFinder) => tester
    .widget<Baseline>(
      find.ancestor(of: textFinder, matching: find.byType(Baseline)),
    )
    .baseline;

/// 大标题基线的实测目标值（= 墨心 132.9 + 0.355em）。
double get _largeBaseline => MiTopBarMetrics.titleBaselineY(
      MiTopBarMetrics.largeTitleInkCenterY,
      MiTypography.topBarLargeTitle.fontSize!,
    );

/// 紧凑标题基线的实测目标值（= 墨心 75.9 + 0.355em）。
double get _compactBaseline => MiTopBarMetrics.titleBaselineY(
      MiTopBarMetrics.compactTitleInkCenterY,
      MiTypography.topBarCompactTitle.fontSize!,
    );

void _size(WidgetTester tester, [Size size = const Size(393, 240)]) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

void main() {
  group('折叠曲线（逐帧实测查找表）', () {
    test('大标题：静止全显、20dp 内归零、中段下降最快', () {
      expect(MiTopBarMetrics.largeTitleOpacity(0), 1.0);
      expect(MiTopBarMetrics.largeTitleOpacity(19.97), 0.0);
      expect(MiTopBarMetrics.largeTitleOpacity(40), 0.0);
      // 实测锚点（墨迹峰值比）
      expect(MiTopBarMetrics.largeTitleOpacity(9.02), closeTo(0.368, 1e-9));
      expect(MiTopBarMetrics.largeTitleOpacity(15.46), closeTo(0.121, 1e-9));
      // 线性插值：7.41dp 落在 5.80 / 9.02 两点之间
      expect(
        MiTopBarMetrics.largeTitleOpacity(7.41),
        closeTo(0.627 + (0.368 - 0.627) * (7.41 - 5.80) / (9.02 - 5.80), 1e-9),
      );
      // 单调不增
      var prev = 2.0;
      for (var x = 0.0; x <= 30; x += 0.25) {
        final v = MiTopBarMetrics.largeTitleOpacity(x);
        expect(v, lessThanOrEqualTo(prev + 1e-12), reason: 'offset=$x');
        prev = v;
      }
    });

    test('紧凑标题：大标题归零后才淡入，27.4dp 起为 1', () {
      expect(MiTopBarMetrics.compactTitleOpacity(0), 0.0);
      expect(MiTopBarMetrics.compactTitleOpacity(19.97), 0.0);
      expect(MiTopBarMetrics.compactTitleOpacity(22.87), closeTo(0.498, 1e-9));
      expect(MiTopBarMetrics.compactTitleOpacity(29.31), 1.0);
      expect(MiTopBarMetrics.compactTitleOpacity(200), 1.0);
      var prev = -1.0;
      for (var x = 0.0; x <= 40; x += 0.25) {
        final v = MiTopBarMetrics.compactTitleOpacity(x);
        expect(v, greaterThanOrEqualTo(prev - 1e-12), reason: 'offset=$x');
        prev = v;
      }
    });

    test('两段不重叠：大标题归零处紧凑标题仍为 0', () {
      expect(MiTopBarMetrics.largeTitleOpacity(19.97), 0.0);
      expect(MiTopBarMetrics.compactTitleOpacity(19.97), 0.0);
    });

    test('非有限位移不抛异常（NaN 取首端、+∞ 取末端）', () {
      expect(MiTopBarMetrics.largeTitleOpacity(double.nan), 1.0);
      expect(MiTopBarMetrics.largeTitleOpacity(double.infinity), 0.0);
      expect(MiTopBarMetrics.compactTitleOpacity(double.infinity), 1.0);
    });
  });

  group('几何（实测值）', () {
    test('基线目标值 = 墨心 + 0.355em（字体无关的落点由 Baseline 求解）', () {
      expect(_largeBaseline, closeTo(144.20, 0.01));
      expect(_compactBaseline, closeTo(82.29, 0.01));
      // 组件高度 = 大标题墨心 + 一整行
      expect(
        MiTopBarMetrics.componentHeight(31.83),
        closeTo(164.73, 0.01),
      );
    });

    testWidgets('静止态：大标题行盒 / 紧凑标题隐形 / 遮罩 / 圆钮位置', (tester) async {
      _size(tester);

      // 必须给 onBack：`onBack == null` 时圆钮退化为 `IgnorePointer`
      // （无 GestureDetector 命中层），`_backHitArea` 会找不到控件。
      await tester.pumpWidget(harness(onBack: () {}));

      // 大标题：行盒左 27.6、基线钉在 144.2（= 墨心 132.9 + 0.355em）
      final large = tester.getRect(_large);
      expect(large.left, closeTo(MiTopBarMetrics.largeTitleLeadingInset, 0.01));
      // 行盒高 ≈ 字号（`height: 1.0`；引擎会把行高向上取整到整数像素）
      expect(large.height, closeTo(MiTypography.topBarLargeTitle.fontSize!, 0.5));
      expect(_baselineArgOf(tester, _large), closeTo(_largeBaseline, 0.01));
      expect(_opacityOf(tester, _large), 1.0);

      // 紧凑标题：屏内水平居中、基线 82.29、静止态全透明
      final compact = tester.getRect(_compact);
      expect(compact.center.dx, closeTo(393 / 2, 0.01));
      expect(_baselineArgOf(tester, _compact), closeTo(_compactBaseline, 0.01));
      expect(_opacityOf(tester, _compact), 0.0);

      // 遮罩：满宽、只高 scrimHeight
      final scrim = tester.getRect(_scrimDark);
      expect(scrim.left, 0);
      expect(scrim.width, 393);
      expect(scrim.top, 0);
      expect(scrim.height, closeTo(MiTopBarMetrics.scrimHeight, 0.01));

      // 返回圆钮命中区：⌀44.1、左 11.9、垂心 76
      final hit = tester.getRect(_backHitArea);
      expect(hit.left, closeTo(MiTopBarMetrics.backInset, 0.01));
      expect(hit.width, closeTo(MiTopBarMetrics.backDiameter, 0.01));
      expect(hit.height, closeTo(MiTopBarMetrics.backDiameter, 0.01));
      expect(hit.center.dx, closeTo(MiTopBarMetrics.backCenterX, 0.01));
      expect(hit.center.dy, closeTo(MiTopBarMetrics.backCenterY, 0.01));

      // 箭头墨盒 = 实测 11.68x21.31，墨心相对圆钮中心左偏 1.3dp
      final chevron = tester.getRect(_chevron);
      expect(chevron.width, closeTo(MiTopBarMetrics.chevronWidth, 0.01));
      expect(chevron.height, closeTo(MiTopBarMetrics.chevronHeight, 0.01));
      expect(
        chevron.center.dx,
        closeTo(
          MiTopBarMetrics.backCenterX + MiTopBarMetrics.chevronCenterDx,
          0.01,
        ),
      );
      expect(chevron.center.dy, closeTo(MiTopBarMetrics.backCenterY, 0.01));

      // 组件高度 = 大标题墨心 + 一整行（够高不裁标题，与基线落点无关）
      expect(
        tester.getRect(find.byType(MiTopBar)).height,
        closeTo(
          MiTopBarMetrics.componentHeight(
            MiTypography.topBarLargeTitle.fontSize!,
          ),
          0.01,
        ),
      );
    });

    testWidgets('滚动 40dp：大标题随内容 1:1 上移并归零，紧凑标题浮现', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness());
      final restTop = tester.getRect(_large).top;

      await tester.pumpWidget(harness(offset: 40));
      expect(tester.getRect(_large).top, closeTo(restTop - 40, 0.01));
      expect(
        _baselineArgOf(tester, _large),
        closeTo(_largeBaseline - 40, 0.01),
        reason: '大标题基线随滚动 1:1 上移',
      );
      expect(_opacityOf(tester, _large), 0.0);
      expect(_opacityOf(tester, _compact), 1.0);

      // 紧凑标题位置不随滚动变化（基线入参 + 屏心都不动）
      expect(_baselineArgOf(tester, _compact), closeTo(_compactBaseline, 0.01));
      expect(tester.getRect(_compact).center.dx, closeTo(393 / 2, 0.01));
    });

    testWidgets('过渡区间：12dp 时大标题半透明且紧凑标题仍隐', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(offset: 12));
      expect(_opacityOf(tester, _large), inInclusiveRange(0.17, 0.24));
      expect(_opacityOf(tester, _compact), 0.0);

      await tester.pumpWidget(harness(offset: 22.87));
      expect(_opacityOf(tester, _compact), closeTo(0.498, 1e-9));
    });

    testWidgets('明暗配方随 themeMode 切换，null 时跟随环境 Theme', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(mode: MiThemeMode.light));
      expect(_scrimLight, findsOneWidget);
      expect(_scrimDark, findsNothing);

      // MaterialApp 默认亮色 Theme → null 走浅色配方
      await tester.pumpWidget(harness(mode: null));
      expect(_scrimLight, findsOneWidget);
    });

    test('scrollOffset 为负 / NaN 在构造期断言', () {
      // 断言在构造期求值（harness 里是同步构造），故不经 pumpWidget
      expect(() => harness(offset: -1), throwsA(isA<AssertionError>()));
      expect(() => harness(offset: -0.1), throwsA(isA<AssertionError>()));
      expect(() => harness(offset: double.nan), throwsA(isA<AssertionError>()));
      // 合法位移不抛
      expect(() => harness(offset: 0), returnsNormally);
      expect(() => harness(offset: double.infinity), returnsNormally);
    });

    testWidgets('+∞ 饱和为折叠完成态：两段标题都到终态、布局仍是有限坐标', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(offset: double.infinity));
      expect(tester.takeException(), isNull);
      expect(_opacityOf(tester, _large), 0.0);
      expect(_opacityOf(tester, _compact), 1.0);
      expect(
        _baselineArgOf(tester, _large),
        closeTo(_largeBaseline - MiTopBarMetrics.collapsedOffset, 0.01),
      );
      // 布局仍是有限坐标（+∞ 不会渗进 top），且折叠态标题仍在组件高度内
      final rect = tester.getRect(_large);
      expect(rect.top.isFinite, isTrue);
      expect(
        rect.bottom,
        lessThanOrEqualTo(
          MiTopBarMetrics.componentHeight(
            MiTypography.topBarLargeTitle.fontSize!,
          ),
        ),
      );
    });
  });

  group('交互', () {
    testWidgets('除圆钮外整体不吃手势：标题处点击落到下层内容', (tester) async {
      _size(tester);

      var background = 0;
      var back = 0;
      await tester.pumpWidget(harness(
        onBack: () => back++,
        onBackgroundTap: () => background++,
      ));

      // 大标题墨心处
      await tester.tapAt(const Offset(120, MiTopBarMetrics.largeTitleInkCenterY));
      await tester.pump();
      expect(background, 1);
      expect(back, 0);

      // 遮罩裙边（大标题已在下沿之外、圆钮行以下）
      await tester.tapAt(const Offset(200, MiTopBarMetrics.scrimHeight - 2));
      await tester.pump();
      expect(background, 2);

      // 圆钮命中区中心 → 只触发 onBack
      await tester.tapAt(
        const Offset(MiTopBarMetrics.backCenterX, MiTopBarMetrics.backCenterY),
      );
      await tester.pump();
      expect(back, 1);
      expect(background, 2);
    });

    testWidgets('按下圆钮浮现按压圆盘，抬起后消失', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(onBack: () {}));
      expect(tester.widget<AnimatedOpacity>(_pressDisc).opacity, 0.0);

      final gesture = await tester.startGesture(
        const Offset(MiTopBarMetrics.backCenterX, MiTopBarMetrics.backCenterY),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.widget<AnimatedOpacity>(_pressDisc).opacity, 1.0);

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.widget<AnimatedOpacity>(_pressDisc).opacity, 0.0);
    });

    testWidgets('onBack = null 时圆钮不参与手势（箭头仍绘制）', (tester) async {
      _size(tester);

      var background = 0;
      await tester.pumpWidget(harness(
        onBack: null, // 显式声明：本用例正是要验证 null 的降级行为
        onBackgroundTap: () => background++,
      ));

      expect(_backHitArea, findsNothing);
      expect(
        tester.widget<CustomPaint>(_chevron).painter,
        isA<BackChevronIconPainter>(),
      );

      await tester.tapAt(
        const Offset(MiTopBarMetrics.backCenterX, MiTopBarMetrics.backCenterY),
      );
      await tester.pump();
      expect(background, 1);
    });
  });

  group('返回圆钮显示开关（showBack）', () {
    test('默认 false（顶层页无返回）——不传即不显示', () {
      const bar = MiTopBar(title: kTitle);
      expect(bar.showBack, isFalse);
      expect(bar.onBack, isNull);
    });

    testWidgets('showBack: false 时不绘制圆钮与箭头，该处点击落到下层内容', (tester) async {
      _size(tester);

      var background = 0;
      var back = 0;
      await tester.pumpWidget(harness(
        showBack: false,
        onBack: () => back++,
        onBackgroundTap: () => background++,
      ));

      // 既无命中区也无箭头墨迹（CustomPaint 只在大标题/圆钮里出现）
      expect(_backHitArea, findsNothing);
      expect(_chevron, findsNothing);

      await tester.tapAt(
        const Offset(MiTopBarMetrics.backCenterX, MiTopBarMetrics.backCenterY),
      );
      await tester.pump();
      expect(background, 1, reason: '圆钮位置不再吃手势');
      expect(back, 0, reason: '圆钮不存在，回调不该被触发');
    });

    testWidgets('showBack: true + onBack = null → 只显示、不可点', (tester) async {
      _size(tester);

      var background = 0;
      await tester.pumpWidget(harness(
        showBack: true,
        onBackgroundTap: () => background++,
      ));

      // 箭头仍绘制
      expect(
        tester.widget<CustomPaint>(_chevron).painter,
        isA<BackChevronIconPainter>(),
      );
      // 无手势层 → 点击穿透到下层
      expect(_backHitArea, findsNothing);
      await tester.tapAt(
        const Offset(MiTopBarMetrics.backCenterX, MiTopBarMetrics.backCenterY),
      );
      await tester.pump();
      expect(background, 1);
    });

    testWidgets('showBack 决定紧凑标题的对称内缩（让开圆钮 / 用满整屏宽）', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(showBack: false));
      expect(_compactPadding(tester), EdgeInsets.zero);
      expect(tester.getRect(_compact).center.dx, closeTo(393 / 2, 0.01));

      await tester.pumpWidget(harness(showBack: true));
      expect(
        _compactPadding(tester),
        const EdgeInsets.symmetric(
          horizontal: MiTopBarMetrics.backInset + MiTopBarMetrics.backDiameter,
        ),
      );
      // 对称内缩不改变屏内居中
      expect(tester.getRect(_compact).center.dx, closeTo(393 / 2, 0.01));
    });
  });

  group('demo 接入：页面壳必须撑满（实机截图回归）', () {
    // 2026-10-16 实机截图：顶栏被摆到屏幕正中，偏移 351.1dp =
    // (856 − 152.8) / 2 —— 页面壳的 Stack 里顶栏是非定位子级时，Stack 会
    // 按它收缩成 393×152.8，再被 AnimatedSwitcher（内部 center 对齐的
    // loose Stack）居中。这里锁住「撑满 + 顶栏贴屏幕顶端」。
    testWidgets('loose 约束（AnimatedSwitcher）下整页撑满、顶栏 top = 0', (tester) async {
      _size(tester, const Size(393, 856));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(
            body: AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: MockPage(2),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final page = tester.getRect(find.byType(MockPage));
      expect(page.left, 0);
      expect(page.top, 0);
      expect(page.width, 393);
      expect(page.height, 856);

      final bar = tester.getRect(find.byType(MiTopBar));
      expect(bar.top, 0);
      expect(bar.left, 0);
      expect(bar.width, 393);
      expect(
        bar.height,
        closeTo(
          MiTopBarMetrics.componentHeight(
            MiTypography.topBarLargeTitle.fontSize!,
          ),
          0.01,
        ),
      );
    });
  });

  group('磨砂材质（亮色「我的」页录屏实测）', () {
    Finder blurLayers() => find.descendant(
          of: find.byType(MiTopBar),
          matching: find.byType(BackdropFilter),
        );

    test('token：栏顶 σ = 5.37dp；阶梯按实测 σ(y) 单调递减、无缝铺满 0…119dp', () {
      expect(MiTopBarPalette.blurSigma, 5.37);

      const bands = MiTopBarPalette.blurBands;
      expect(bands, isNotEmpty);
      // 首段从 0 起、末段到 119dp 收（下缘完全锐利）
      expect(bands.first.top, 0);
      expect(bands.last.bottom, 119.0);
      // 段间无缝、无重叠
      for (var i = 1; i < bands.length; i++) {
        expect(
          bands[i].top,
          closeTo(bands[i - 1].bottom, 1e-9),
          reason: '第 $i 段与上一段之间不能有空隙/重叠（会露出未模糊的横条）',
        );
      }
      // σ 单调不增，且首段 = 平台段实测值、末段已到肉眼不可辨
      expect(bands.first.sigma, MiTopBarPalette.blurSigma);
      for (var i = 1; i < bands.length; i++) {
        expect(
          bands[i].sigma <= bands[i - 1].sigma,
          isTrue,
          reason: '磨砂强度必须向下单调不增（第 $i 段反而更强了）',
        );
        // 相邻 σ 比过大 = 段边界会出现可见的"锐度台阶"
        expect(
          bands[i - 1].sigma / bands[i].sigma,
          lessThan(2.4),
          reason: '第 ${i - 1}→$i 段 σ 落差过大，台阶会显形',
        );
      }
      expect(bands.last.sigma, lessThan(0.5));

      // 段高不宜过大：实测曲线在 90dp 附近变化最快
      for (final band in bands) {
        expect(band.height, lessThanOrEqualTo(35.0));
        expect(band.height, greaterThan(0));
      }

      // 与实测 σ(y) 曲线对齐（分段线性插值，容差 1.2dp）
      double sigmaAt(double dp) {
        const ys = [0.0, 35.0, 50.0, 67.5, 90.0, 103.0, 119.0];
        const ss = [5.37, 5.37, 4.96, 4.34, 1.85, 0.76, 0.0];
        for (var i = 1; i < ys.length; i++) {
          if (dp <= ys[i]) {
            final f = (dp - ys[i - 1]) / (ys[i] - ys[i - 1]);
            return ss[i - 1] + (ss[i] - ss[i - 1]) * f;
          }
        }
        return 0;
      }

      for (final band in bands) {
        expect(
          band.sigma,
          closeTo(sigmaAt((band.top + band.bottom) / 2), 1.2),
          reason: '${band.top}…${band.bottom}dp 段的 σ 偏离实测曲线',
        );
      }

      // 浅色叠色：页底色 #F3F3F3，α 顶部 0.650 → 122.4dp 归零
      final light = MiTopBarPalette.light.scrimGradient as LinearGradient;
      expect(light.colors.first, const Color.fromRGBO(243, 243, 243, 0.650));
      expect(
        light.stops!.last,
        closeTo(122.4 / MiTopBarMetrics.scrimHeight, 1e-5),
      );
      expect(light.colors.last.a, 0.0);

      // 深色叠色沿用既有实测（顶部不透明），未被本轮改动
      final dark = MiTopBarPalette.dark.scrimGradient as LinearGradient;
      expect(dark.colors.first.a, 1.0);
      expect(dark.stops!.last, 1.0);
    });

    testWidgets('磨砂层：每段一个定 σ 的 BackdropFilter，满宽、首尾相接', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness());

      // 忠实度关键：必须有 backdrop 模糊（上一版缺失的正是这层）。
      // 深色配方顶部 0…63.6dp 的叠色是 α=1.000 纯黑，其下的模糊 100% 不可见
      // → 渲染层跳过（见 MiTopBar.visibleBlurBands），故段数按「可见段」核。
      final bands = MiTopBar.visibleBlurBands(MiTopBarPalette.dark);
      final finder = blurLayers();
      expect(finder, findsNWidgets(bands.length));

      // 每一段：σ 用该段的值、几何与 token 一致
      for (var i = 0; i < bands.length; i++) {
        final band = bands[i];
        final widget = tester.widgetList<BackdropFilter>(finder).elementAt(i);
        expect(
          widget.filter,
          ImageFilter.blur(sigmaX: band.sigma, sigmaY: band.sigma),
          reason: '第 $i 段 σ 与 token 不一致',
        );

        final rect = tester.getRect(finder.at(i));
        expect(rect.left, 0);
        expect(rect.width, 393);
        expect(rect.top, closeTo(band.top, 0.01));
        expect(rect.height, closeTo(band.height, 0.01));
      }

      // 深色：第一段从不透明叠色下沿开始，段间无缝隙；最后一段止于曲线尾部
      // 折算到材质盒后的位置（σ=0.30 的尾段 < minVisibleBlurSigma，亚像素、
      // 不绘制）—— 曲线按「119dp → 材质盒 128.9dp」等比拉伸
      const tailScale = MiTopBarMetrics.scrimHeight / 119.0;
      final rects = [for (var i = 0; i < bands.length; i++) tester.getRect(finder.at(i))];
      expect(rects.first.top, closeTo(MiTopBarMetrics.scrimSolidBottom, 0.01));
      expect(rects.last.bottom, closeTo(109.0 * tailScale, 0.01));
      for (var i = 1; i < rects.length; i++) {
        expect(rects[i].top, closeTo(rects[i - 1].bottom, 0.01));
      }

      // 不能用半透明遮罩削弱模糊：那会让 backdrop 变空（实测过）
      expect(
        find.descendant(
          of: find.byType(MiTopBar),
          matching: find.byType(ShaderMask),
        ),
        findsNothing,
        reason: 'ShaderMask 会切断 backdrop，磨砂会整段失效',
      );

      // 叠色层仍在（磨砂之上的着色，不是替代关系）
      expect(_scrimDark, findsOneWidget);
    });

    testWidgets('纯材质形态（title: null）：不内嵌任何组件，高度收到 scrimHeight', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(title: null));

      expect(
        find.descendant(of: find.byType(MiTopBar), matching: find.byType(Text)),
        findsNothing,
      );
      expect(
        blurLayers(),
        findsNWidgets(
          MiTopBar.visibleBlurBands(MiTopBarPalette.dark).length,
        ),
      );
      expect(_scrimDark, findsOneWidget);
      expect(
        tester.getRect(find.byType(MiTopBar)).height,
        closeTo(MiTopBarMetrics.scrimHeight, 0.01),
      );

      // 无标题时滚动位移不产生任何视觉变化（不崩、不画标题）
      await tester.pumpWidget(harness(title: null, offset: 40));
      expect(find.descendant(
        of: find.byType(MiTopBar),
        matching: find.byType(Text),
      ), findsNothing);
    });

    testWidgets('无标题也可显示返回圆钮（材质 + 圆钮的次级页形态）', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(title: null, showBack: true, onBack: () {}));
      expect(find.byType(Text), findsNothing);
      final hit = tester.getRect(_backHitArea);
      expect(hit.center.dx, closeTo(MiTopBarMetrics.backCenterX, 0.01));
      expect(hit.center.dy, closeTo(MiTopBarMetrics.backCenterY, 0.01));
    });
  });

  group('头部插槽（搜索栏 / 胶囊行 / 自定义头部）', () {
    /// 真实搜索栏（分类页同款），用于几何与高度集成断言。
    Widget realSearchBar() => const MiSearchBar(
          hint: '搜索主题 / 壁纸 / 图标',
          themeMode: MiThemeMode.dark,
        );

    Widget realTabBar() => MiPillTabBar(
          labels: const ['Logo 展示', '按钮展示', '示例三', '示例四'],
          selectedIndex: 0,
          onTap: (_) {},
          themeMode: MiThemeMode.dark,
        );

    test('跨层常量同值：插槽默认高度 = 搜索栏 / 胶囊行的实测高度', () {
      // metrics 表保持纯数据（不 import 组件层），两个常量有意重复；
      // 改一处漏另一处会红
      expect(MiTopBarMetrics.searchBarSlotHeight, MiSearchBarMetrics.barHeight);
      expect(MiTopBarMetrics.tabBarSlotHeight, MiPillTabMetrics.pillHeight);
    });

    testWidgets('搜索栏 + 胶囊行：56 让位、搜索栏 11.9 边距、胶囊行满宽、两者隔 16', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showSurface: false,
        searchBar: realSearchBar(),
        tabBar: realTabBar(),
      ));

      // 搜索栏：顶部状态栏让位 56、左右页边距 11.9
      final search = tester.getRect(find.byType(MiSearchBar));
      expect(search.top, closeTo(MiTopBarMetrics.headerTopInset, 0.01));
      expect(search.left, closeTo(MiTopBarMetrics.headerInset, 0.01));
      expect(
        search.width,
        closeTo(393 - 2 * MiTopBarMetrics.headerInset, 0.01),
      );
      expect(search.height, closeTo(MiSearchBarMetrics.barHeight, 0.01));

      // 胶囊行：**满宽**（左右都不内缩 —— 靠自身 11.9 edgeInset 与搜索栏
      // 左缘对齐，同时保留横向出血滚动）
      final tabs = tester.getRect(find.byType(MiPillTabBar));
      expect(tabs.left, 0);
      expect(tabs.width, 393);
      expect(tabs.height, closeTo(MiPillTabMetrics.pillHeight, 0.01));
      expect(
        tabs.top,
        closeTo(
          MiTopBarMetrics.headerTopInset +
              MiSearchBarMetrics.barHeight +
              MiTopBarMetrics.searchBarGap,
          0.01,
        ),
      );

      // 顶栏自身高度 = 56 + 44.1 + 16 + 39.9（分类页吸顶头部的实测总高）
      expect(
        tester.getSize(find.byType(MiTopBar)).height,
        closeTo(156.0, 0.01),
      );
    });

    testWidgets('occupiedHeight 与实际布局高度一致（两种形态）', (tester) async {
      _size(tester);

      // 大标题形态：只有标题区
      await tester.pumpWidget(harness());
      var bar = tester.widget<MiTopBar>(find.byType(MiTopBar));
      var context = tester.element(find.byType(MiTopBar));
      expect(
        bar.occupiedHeight(context),
        closeTo(
          MiTopBarMetrics.componentHeight(
            MiTypography.topBarLargeTitle.fontSize!,
          ),
          0.01,
        ),
      );
      expect(
        tester.getSize(find.byType(MiTopBar)).height,
        closeTo(bar.occupiedHeight(context), 0.01),
      );

      // 吸顶头部形态：标题区 0 + 头部区
      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showSurface: false,
        searchBar: realSearchBar(),
        tabBar: realTabBar(),
      ));
      bar = tester.widget<MiTopBar>(find.byType(MiTopBar));
      context = tester.element(find.byType(MiTopBar));
      expect(bar.occupiedHeight(context), closeTo(156.0, 0.01));
      expect(
        tester.getSize(find.byType(MiTopBar)).height,
        closeTo(bar.occupiedHeight(context), 0.01),
        reason: '宿主按 occupiedHeight 给滚动内容让位，两者必须一致',
      );
    });

    testWidgets('材质两个开关各自独立：showBlur 只控磨砂、showSurface 只控叠色', (tester) async {
      // 材质铺满 156dp，窗口留宽裕防状态栏让位变化
      _size(tester, const Size(393, 400));

      Finder blurLayers() => find.descendant(
            of: find.byType(MiTopBar),
            matching: find.byType(BackdropFilter),
          );

      // ① 两个都关：零磨砂、零叠色，高度只由头部区决定
      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showSurface: false,
        showBlur: false,
        searchBar: const SizedBox.expand(),
        tabBar: const SizedBox.expand(),
      ));
      expect(blurLayers(), findsNothing, reason: '关掉磨砂就不该有模糊层');
      expect(_scrimDark, findsNothing, reason: '关掉叠色就不该有压色');
      expect(find.byType(ShaderMask), findsNothing, reason: '渐进模糊不得用遮罩实现');
      expect(
        tester.getSize(find.byType(MiTopBar)).height,
        closeTo(156.0, 0.01),
        reason: '高度只由头部区决定，材质层不占布局高度',
      );

      // ② 只开叠色：有压色、无磨砂
      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showBlur: false,
        searchBar: const SizedBox.expand(),
        tabBar: const SizedBox.expand(),
      ));
      expect(blurLayers(), findsNothing, reason: 'showBlur 关了，叠色不该带出模糊');
      expect(_scrimDark, findsOneWidget);
      expect(
        tester.getRect(_scrimDark).height,
        closeTo(156.0, 0.01),
        reason: '头部区形态的叠色铺满整条顶栏（否则搜索栏 / 胶囊四周会断层）',
      );

      // ③ 只开磨砂：有模糊、无压色；曲线拉到整条栏 156dp（形状不变）
      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showSurface: false,
        searchBar: const SizedBox.expand(),
        tabBar: const SizedBox.expand(),
      ));
      expect(
        blurLayers(),
        findsNWidgets(
          MiTopBar.visibleBlurBands(
            MiTopBarPalette.dark,
            extent: 156.0,
            underSurface: false,
          ).length,
        ),
      );
      expect(_scrimDark, findsNothing);
      expect(
        tester.getSize(find.byType(MiTopBar)).height,
        closeTo(156.0, 0.01),
        reason: '材质是盖在顶栏上的底层，不把头部区往下推',
      );
    });

    testWidgets('磨砂曲线固定 0…119dp：不随栏高拉伸，关掉叠色时上半段不跳段', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        searchBar: const SizedBox.expand(),
        tabBar: const SizedBox.expand(),
      ));

      // 磨砂两处形态（纯标题 128.9 / 头部区 156）用**同一条**实测 σ(y) 曲线，
      // 但范围拉伸到各自材质盒底 —— 曲线是内容区自己的（无顶栏的「每日精选」
      // 页顶部照样糊、到 ~120dp 自然收尾；分类页则糊到胶囊行下方），
      // 形状固定、范围跟栏高走。
      //
      // 关掉叠色时上半段裸露，必须**从 0 开始糊**（实机踩过：跳过它栏顶一片清晰）
      final bare = MiTopBar.visibleBlurBands(
        MiTopBarPalette.dark,
        underSurface: false,
      );
      expect(bare.first.top, 0);
      expect(bare.first.sigma, MiTopBarPalette.blurSigma);
      expect(bare.last.sigma, lessThan(bare.first.sigma), reason: 'σ 沿 y 递减');
      // 纯标题形态按材质盒 128.9 拉伸：曲线名义终点 119dp → 128.9，末段
      // σ = 0.30 < minVisibleBlurSigma 已被剔除（亚像素、无视觉差），
      // 所以**实际绘制的**下沿是 109 × 128.9 / 119
      const k = MiTopBarMetrics.scrimHeight / 119.0;
      expect(bare.last.bottom, closeTo(109.0 * k, 0.01));
      expect(MiTopBarPalette.blurBands.last.bottom, closeTo(119.0, 0.01));

      // 深色叠色 0…63.6dp 是 α=1 纯黑：有叠色时跳过这段省帧
      final covered = MiTopBar.visibleBlurBands(MiTopBarPalette.dark);
      expect(
        covered.first.top,
        closeTo(MiTopBarPalette.dark.scrimOpaqueBottom, 0.01),
        reason: '被不透明压色盖住的段不必算模糊（纯标题形态盒高不缩放）',
      );
      expect(covered.length, lessThan(bare.length));
      expect(covered.last.bottom, closeTo(109.0 * k, 0.01));

      // 头部区形态：同一条曲线拉到 156 才归零，且 0 起糊（那页没有压色）
      final tall = MiTopBar.visibleBlurBands(
        MiTopBarPalette.dark,
        extent: 156.0,
        underSurface: false,
      );
      expect(tall.first.top, 0);
      expect(tall.last.bottom, closeTo(109.0 * 156.0 / 119.0, 0.01));

      // 纯标题形态的叠色仍到实测材质盒 128.9
      await tester.pumpWidget(harness(offset: 40));
      expect(tester.getRect(_scrimDark).height, closeTo(128.9, 0.01));
    });

    testWidgets('header 插槽：高度取 preferredSize，左右同 headerInset', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showSurface: false,
        header: const _FixedHeader(height: 30),
      ));

      final rect = tester.getRect(find.byType(_FixedHeader));
      expect(rect.top, closeTo(MiTopBarMetrics.headerTopInset, 0.01));
      expect(rect.left, closeTo(MiTopBarMetrics.headerInset, 0.01));
      expect(rect.width, closeTo(393 - 2 * MiTopBarMetrics.headerInset, 0.01));
      expect(rect.height, closeTo(30, 0.01));
      expect(
        tester.getSize(find.byType(MiTopBar)).height,
        closeTo(MiTopBarMetrics.headerTopInset + 30, 0.01),
      );
    });

    testWidgets('headerInset 可覆盖（宽屏舞台放大页边距）', (tester) async {
      _size(tester, const Size(1000, 240));

      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showSurface: false,
        headerInset: 24,
        searchBar: realSearchBar(),
        tabBar: realTabBar(),
      ));

      final search = tester.getRect(find.byType(MiSearchBar));
      expect(search.left, closeTo(24, 0.01));
      expect(search.width, closeTo(1000 - 48, 0.01));
      // 胶囊行仍满宽 —— 左右页边距只作用于搜索栏 / 自定义头部
      expect(tester.getRect(find.byType(MiPillTabBar)).width, 1000);
    });

    testWidgets('插槽内组件照常收手势（顶栏不吃点击）', (tester) async {
      _size(tester);

      var taps = 0;
      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showSurface: false,
        searchBar: MiSearchBar(
          hint: '搜索',
          themeMode: MiThemeMode.dark,
          onTap: () => taps++,
        ),
      ));

      await tester.tap(find.byType(MiSearchBar));
      await tester.pump();
      expect(taps, 1);
    });

    test('非法组合在构造期断言', () {
      // 空顶栏：没有标题、磨砂叠色都关、也没插槽
      expect(
        () => harness(title: null, showSurface: false, showBlur: false),
        throwsA(isA<AssertionError>()),
      );
      // header 与 searchBar / tabBar 互斥
      expect(
        () => harness(header: const _FixedHeader(height: 20), searchBar: const SizedBox()),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => harness(header: const _FixedHeader(height: 20), tabBar: const SizedBox()),
        throwsA(isA<AssertionError>()),
      );
      // 页边距不能为负
      expect(
        () => harness(title: null, headerInset: -1),
        throwsA(isA<AssertionError>()),
      );
      // 合法：只有插槽
      expect(
        () => harness(title: null, showSurface: false, searchBar: const SizedBox()),
        returnsNormally,
      );
      // 合法：材质 + 插槽
      expect(
        () => harness(
          title: null,
          searchBar: const SizedBox(),
          tabBar: const SizedBox(),
        ),
        returnsNormally,
      );
    });
  });

  group('头部区由顶栏自己产出（声明式入参 searchHint / tabs）', () {
    const hint = '搜索主题 / 壁纸 / 图标';
    const labels = ['Logo 展示', '按钮展示', '示例三', '示例四'];

    testWidgets('给 searchHint 就产出 MiSearchBar，几何与插槽形态一致', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showSurface: false,
        searchHint: hint,
      ));

      final search = find.byType(MiSearchBar);
      expect(search, findsOneWidget, reason: '顶栏应自己 new 出搜索栏');
      expect(
        find.descendant(of: find.byType(MiTopBar), matching: search),
        findsOneWidget,
        reason: '搜索栏必须是顶栏的子树（不是页面拼在顶栏外面）',
      );
      expect(
        tester.widget<MiSearchBar>(search).hint,
        hint,
        reason: '占位文案透传',
      );
      final rect = tester.getRect(search);
      expect(rect.top, closeTo(MiTopBarMetrics.headerTopInset, 0.01));
      expect(rect.left, closeTo(MiTopBarMetrics.headerInset, 0.01));
      expect(rect.height, closeTo(MiSearchBarMetrics.barHeight, 0.01));
    });

    testWidgets('给 tabs 就产出 MiPillTabBar，标签与选中下标透传、满宽', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showSurface: false,
        searchHint: hint,
        tabs: labels,
        selectedTab: 1,
      ));

      final pills = find.byType(MiPillTabBar);
      expect(
        find.descendant(of: find.byType(MiTopBar), matching: pills),
        findsOneWidget,
      );
      final widget = tester.widget<MiPillTabBar>(pills);
      expect(widget.labels, labels);
      expect(widget.selectedIndex, 1);
      expect(widget.itemWidth, MiPillTabMetrics.itemWidth);
      // 胶囊行仍满宽（左右不内缩，保留横向出血滚动）
      expect(tester.getRect(pills).left, 0);
      expect(tester.getRect(pills).width, 393);
    });

    testWidgets('高度与插槽形态逐值相同：56 + 44.1 + 16 + 39.9 = 156', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showSurface: false,
        searchHint: hint,
        tabs: labels,
      ));
      final bar = tester.widget<MiTopBar>(find.byType(MiTopBar));
      final context = tester.element(find.byType(MiTopBar));
      expect(bar.hasHeaderSlot, isTrue);
      expect(bar.occupiedHeight(context), closeTo(156.0, 0.01));
      expect(
        tester.getSize(find.byType(MiTopBar)).height,
        closeTo(bar.occupiedHeight(context), 0.01),
        reason: '宿主按 occupiedHeight 让位，必须与实际高度同源',
      );
    });

    testWidgets('点按胶囊回调出下标；点按搜索栏回调 onSearchTap', (tester) async {
      _size(tester);

      int? tapped;
      var searchTaps = 0;
      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showSurface: false,
        searchHint: hint,
        onSearchTap: () => searchTaps++,
        tabs: labels,
        onTabChanged: (i) => tapped = i,
      ));

      await tester.tap(find.text('按钮展示'));
      await tester.pump();
      expect(tapped, 1);

      await tester.tap(find.byType(MiSearchBar));
      await tester.pump();
      expect(searchTaps, 1);
    });

    testWidgets('onTabChanged = null 时只展示：点按不抛错、选中态不变', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showSurface: false,
        tabs: labels,
        selectedTab: 0,
      ));

      await tester.tap(find.text('示例三'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<MiPillTabBar>(find.byType(MiPillTabBar)).selectedIndex,
        0,
      );
    });

    testWidgets('内置组件的明暗配方随顶栏 themeMode（页面不用再各传一遍）', (tester) async {
      _size(tester);

      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showSurface: false,
        mode: MiThemeMode.light,
        searchHint: hint,
        tabs: labels,
      ));

      expect(
        tester.widget<MiSearchBar>(find.byType(MiSearchBar)).themeMode,
        MiThemeMode.light,
      );
      expect(
        tester.widget<MiPillTabBar>(find.byType(MiPillTabBar)).themeMode,
        MiThemeMode.light,
        reason: 'MiPillTabBar 默认值是 dark，必须由顶栏显式覆盖',
      );
    });

    testWidgets('顶栏自己画材质时内置组件不再自绘 backdrop（整条栏只糊一次）',
        (tester) async {
      _size(tester);
      Finder barBlurs() => find.descendant(
            of: find.byType(MiTopBar),
            matching: find.byType(BackdropFilter),
          );

      // 开材质（默认）：零件交出磨砂，全栏只剩材质那段
      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        searchHint: hint,
        tabs: labels,
      ));
      expect(
        tester.widget<MiSearchBar>(find.byType(MiSearchBar)).frosted,
        isFalse,
        reason: '搜索栏在顶栏材质里，再自带一层会糊两次',
      );
      expect(
        tester.widget<MiPillTabBar>(find.byType(MiPillTabBar)).frosted,
        isFalse,
      );
      expect(
        barBlurs(),
        findsNWidgets(
          // 头部区形态：材质盒 = 整条栏 156，叠色在（默认 showSurface: true）
          MiTopBar.visibleBlurBands(MiTopBarPalette.dark, extent: 156.0).length,
        ),
        reason: '全栏只有顶栏那几条 σ(y) 段，没有零件私货',
      );
      expect(
        find.descendant(
          of: find.byType(MiSearchBar),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(MiPillTabBar),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );

      // 关掉磨砂：零件各自带 backdrop（旧形态，仅作对照）
      await tester.pumpWidget(harness(
        title: null,
        showBack: false,
        showSurface: false,
        showBlur: false,
        searchHint: hint,
        tabs: labels,
      ));
      expect(
        tester.widget<MiSearchBar>(find.byType(MiSearchBar)).frosted,
        isTrue,
      );
      expect(
        tester.widget<MiPillTabBar>(find.byType(MiPillTabBar)).frosted,
        isTrue,
      );
    });

    test('声明式入参与插槽互斥（构造期断言）', () {
      expect(
        () => harness(searchHint: hint, searchBar: const SizedBox()),
        throwsA(isA<AssertionError>()),
        reason: '搜索栏不能既内置又外传',
      );
      expect(
        () => harness(tabs: const ['a'], tabBar: const SizedBox()),
        throwsA(isA<AssertionError>()),
        reason: '胶囊行不能既内置又外传',
      );
      expect(
        () => harness(header: const _FixedHeader(height: 20), searchHint: hint),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => harness(header: const _FixedHeader(height: 20), tabs: const ['a']),
        throwsA(isA<AssertionError>()),
      );
      // 合法：只给数据
      expect(
        () => harness(
          title: null,
          showSurface: false,
          searchHint: hint,
          tabs: const ['a'],
        ),
        returnsNormally,
      );
    });
  });

  test('const 构造保持可用', () {
    const bar = MiTopBar(title: kTitle);
    expect(bar.title, kTitle);
    expect(bar.scrollOffset, 0);
    expect(bar.themeMode, isNull);
    expect(bar.showBack, isFalse);
    expect(bar.onBack, isNull);
    // 插槽默认值：不画插槽、画材质、页边距取实测 11.9
    expect(bar.searchBar, isNull);
    expect(bar.tabBar, isNull);
    expect(bar.header, isNull);
    expect(bar.showSurface, isTrue);
    expect(bar.headerInset, MiTopBarMetrics.headerInset);

    const withBack = MiTopBar(title: kTitle, showBack: true);
    expect(withBack.showBack, isTrue);
  });
}

/// 定高自定义头部（`header` 插槽的测试替身）。
class _FixedHeader extends StatelessWidget implements PreferredSizeWidget {
  const _FixedHeader({required this.height});

  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) => const ColoredBox(color: Color(0xFF123456));
}
