import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；若导出缺失会在这里暴露。
import 'package:mi_like_ui/mi_like_ui.dart';

/// `MiFloatingActionButton` 契约测试（浮动操作按钮；几何 / 投影为参考实现值，
/// 口径见 `MiFloatingActionButtonMetrics`）。
///
/// 判据约定：
///  * **边长由父级约束决定**：松父级下至少 60dp（参考实现的 defaultMinSize），
///    父级给更紧的约束按父级走 —— 导航栏槽位 ⌀55.4 就走这条；
///  * 投影走 `MiSquircleShadowPainter`（`showShadow` 可关），**不是**
///    `BoxShadow` 直接挂在装饰上；
///  * 按压换填充（`dialogPressedFill` 预合成，不引 saveLayer）；
///  * 导航栏槽位圆钮 = 本组件（无投影那档）。
void main() {
  void setWindow(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Widget loose(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  /// 按 key 取填充层（装饰即圆底本身）。
  DecoratedBox fillOf(WidgetTester tester) =>
      tester.widget<DecoratedBox>(find.byKey(MiFloatingActionButton.fillKey));

  Color fillColor(WidgetTester tester) =>
      (fillOf(tester).decoration as ShapeDecoration).color!;

  /// 转投影画笔（`showShadow: true` 时的那一层）。
  Finder shadowOf() => find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is MiSquircleShadowPainter,
      );

  testWidgets('松父级：边长取下限 60dp，默认填充是度量绿', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      loose(
        const MiFloatingActionButton(
          themeMode: MiThemeMode.dark,
          onPressed: _noop,
          child: Icon(Icons.add),
        ),
      ),
    );

    final size = tester.getSize(find.byType(MiFloatingActionButton));
    expect(size, const Size(MiFloatingActionButtonMetrics.size,
        MiFloatingActionButtonMetrics.size));
    expect(fillColor(tester), MiColors.fabGreenFor(MiThemeMode.dark));
    // 默认带投影（参考实现的 shadowElevation）。
    expect(shadowOf(), findsOneWidget);
  });

  testWidgets('父级约束优先：槽位多大就多大（导航栏 ⌀55.4 的契约）',
      (tester) async {
    setWindow(tester, const Size(400, 300));

    const slot = MiGlassNavMetrics.fabDiameter;
    await tester.pumpWidget(
      loose(
        const SizedBox(
          width: slot,
          height: slot,
          child: MiFloatingActionButton(
            themeMode: MiThemeMode.dark,
            onPressed: _noop,
            child: Icon(Icons.add),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(MiFloatingActionButton.fillKey)),
      const Size(slot, slot),
      reason: 'minSize 是下限不是定值：父级更紧时按父级走',
    );
  });

  testWidgets('color 覆盖填充；showShadow: false 时没有投影层', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      loose(
        const MiFloatingActionButton(
          color: Color(0xFF123456),
          showShadow: false,
          themeMode: MiThemeMode.dark,
          onPressed: _noop,
          child: Icon(Icons.add),
        ),
      ),
    );

    expect(fillColor(tester), const Color(0xFF123456));
    expect(shadowOf(), findsNothing);
  });

  testWidgets('按压换填充（预合成压色），松开回原填充', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      loose(
        const MiFloatingActionButton(
          themeMode: MiThemeMode.dark,
          onPressed: _noop,
          child: Icon(Icons.add),
        ),
      ),
    );
    final base = fillColor(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MiFloatingActionButton)),
    );
    await tester.pump();
    expect(
      fillColor(tester),
      MiTransparencyTokens.dialogPressedFill(base, MiThemeMode.dark),
      reason: '按压 = 填充换压色（与弹框按钮同一配方）',
    );

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(fillColor(tester), base);
  });

  testWidgets('点按回调只在可点时触发；enabled: false 等同禁用', (tester) async {
    setWindow(tester, const Size(400, 300));

    var taps = 0;
    await tester.pumpWidget(
      loose(
        MiFloatingActionButton(
          themeMode: MiThemeMode.dark,
          onPressed: () => taps++,
          child: const Icon(Icons.add),
        ),
      ),
    );
    await tester.tap(find.byType(MiFloatingActionButton));
    await tester.pump();
    expect(taps, 1);

    await tester.pumpWidget(
      loose(
        const MiFloatingActionButton(
          themeMode: MiThemeMode.dark,
          enabled: false,
          onPressed: _noop,
          child: Icon(Icons.add),
        ),
      ),
    );
    await tester.tap(find.byType(MiFloatingActionButton));
    await tester.pump();
    expect(taps, 1, reason: 'enabled: false 不响应');

    await tester.pumpWidget(
      loose(
        const MiFloatingActionButton(
          themeMode: MiThemeMode.dark,
          onPressed: null,
          child: Icon(Icons.add),
        ),
      ),
    );
    await tester.tap(find.byType(MiFloatingActionButton));
    await tester.pump();
    expect(taps, 1, reason: 'onPressed == null 不响应');

    // 语义：仍是按钮，但标不可用（读屏要能定位它、知道它点不动）。
    final sem = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(MiFloatingActionButton),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(sem.properties.button, isTrue);
    expect(sem.properties.enabled, isFalse);
  });

  testWidgets('内容色向下传：未设色的 Text 取前景墨色', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      loose(
        const MiFloatingActionButton(
          themeMode: MiThemeMode.light,
          onPressed: _noop,
          child: Text('新建'),
        ),
      ),
    );
    // Text.style 是调用方给的原始样式（这里没给 → null）；真正生效的是
    // `DefaultTextStyle` 合并后的结果，落在 RichText 的 span 上。
    final rich = tester.widget<RichText>(
      find.descendant(
        of: find.byType(MiFloatingActionButton),
        matching: find.byType(RichText),
      ),
    );
    expect(rich.text.style!.color, MiColors.foregroundFor(MiThemeMode.light));
  });

  testWidgets('导航栏槽位圆钮就是本组件（且不带投影）', (tester) async {
    setWindow(tester, const Size(400, 300));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MiGlassNavBar(
              themeMode: MiThemeMode.dark,
              items: const [
                MiGlassNavItem(label: '首页', painter: _StubPainter()),
                MiGlassNavItem(label: '分类', painter: _StubPainter()),
                MiGlassNavItem(label: '我的', painter: _StubPainter()),
              ],
              selectedIndex: 0,
              onTap: (_) {},
              fab: const MiGlassNavFab(
                tabIndex: 0,
                child: Icon(Icons.add),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fab = find.descendant(
      of: find.byType(MiGlassNavBar),
      matching: find.byType(MiFloatingActionButton),
    );
    expect(fab, findsOneWidget);
    // 槽位：直径 = 栏高度量，投影关掉（圆钮是玻璃栏体的一部分）。
    expect(
      tester.getSize(find.byKey(MiFloatingActionButton.fillKey)),
      const Size.square(MiGlassNavMetrics.fabDiameter),
    );
    expect(shadowOf(), findsNothing);
  });
}

void _noop() {}

/// 占位图标 painter（本测试不关心形状）。
class _StubPainter extends CustomPainter {
  const _StubPainter();

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(_StubPainter oldDelegate) => false;
}
