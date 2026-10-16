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
  String title = kTitle,
  double offset = 0,
  MiThemeMode? mode = MiThemeMode.dark,
  bool showBack = true,
  VoidCallback? onBack,
  VoidCallback? onBackgroundTap,
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

/// 文字盒内**基线**距盒顶的距离（标题垂直落点由 `Baseline` 组件按它求解，
/// 故这是唯一与字体无关的可断言量：`rect.top + 该值` = 基线距屏顶）。
double _baselineOf(WidgetTester tester, Finder finder) => tester
    .renderObject<RenderBox>(finder)
    .getDistanceToBaseline(TextBaseline.alphabetic)!;

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

      await tester.pumpWidget(harness());

      // 大标题：行盒左 27.6、基线钉在 144.2（= 墨心 132.9 + 0.355em）
      final large = tester.getRect(_large);
      expect(large.left, closeTo(MiTopBarMetrics.largeTitleLeadingInset, 0.01));
      expect(large.height, closeTo(MiTypography.topBarLargeTitle.fontSize!, 0.01));
      expect(
        large.top + _baselineOf(tester, _large),
        closeTo(_largeBaseline, 0.01),
      );
      expect(_opacityOf(tester, _large), 1.0);

      // 紧凑标题：屏内水平居中、基线 82.29、静止态全透明
      final compact = tester.getRect(_compact);
      expect(compact.center.dx, closeTo(393 / 2, 0.01));
      expect(
        compact.top + _baselineOf(tester, _compact),
        closeTo(_compactBaseline, 0.01),
      );
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
      final restCompactBaseline = _baselineOf(tester, _compact);
      final restCompactCenterX = tester.getRect(_compact).center.dx;

      await tester.pumpWidget(harness(offset: 40));
      expect(tester.getRect(_large).top, closeTo(restTop - 40, 0.01));
      expect(_opacityOf(tester, _large), 0.0);
      expect(_opacityOf(tester, _compact), 1.0);

      // 紧凑标题位置不随滚动变化（基线 + 屏心都不动）
      expect(_baselineOf(tester, _compact), closeTo(restCompactBaseline, 0.01));
      expect(_compactBaseline, closeTo(restCompactBaseline, 0.01));
      expect(
        tester.getRect(_compact).center.dx,
        closeTo(restCompactCenterX, 0.01),
      );
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
        tester.getRect(_large).top + _baselineOf(tester, _large),
        closeTo(_largeBaseline - MiTopBarMetrics.collapsedOffset, 0.01),
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
      await tester.pumpWidget(harness(onBackgroundTap: () => background++));

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

  test('const 构造保持可用', () {
    const bar = MiTopBar(title: kTitle);
    expect(bar.title, kTitle);
    expect(bar.scrollOffset, 0);
    expect(bar.themeMode, isNull);
    expect(bar.showBack, isFalse);
    expect(bar.onBack, isNull);

    const withBack = MiTopBar(title: kTitle, showBack: true);
    expect(withBack.showBack, isTrue);
  });
}
