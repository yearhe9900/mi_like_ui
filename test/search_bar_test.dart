import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；若导出缺失会在这里暴露。
import 'package:mi_like_ui/mi_like_ui.dart';

/// 平底合成：半透明填充叠在纯色页底上（模拟截图实测环境，
/// out = bg·(255−α)/255 + fg·α/255，四舍五入到字节）。
Color _compose(Color bg, Color fill) {
  final a = fill.alpha;
  int ch(int b, int f) => ((b * (255 - a) + f * a) / 255).round();
  return Color.fromARGB(
    255,
    ch(bg.red, fill.red),
    ch(bg.green, fill.green),
    ch(bg.blue, fill.blue),
  );
}

/// 可交互脚手架；[mode] 为空时走「跟随环境 Theme」路径。
Widget _harness({
  MiThemeMode? mode,
  VoidCallback? onTap,
  ThemeData? theme,
  bool overContent = false,
}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      backgroundColor: mode == MiThemeMode.light || theme?.brightness == Brightness.light
          ? const Color(0xFFF3F3F3)
          : const Color(0xFF000000),
      body: Align(
        alignment: Alignment.topCenter,
        child: MiSearchBar(
          hint: '搜索主题 / 壁纸 / 图标',
          themeMode: mode,
          onTap: onTap,
          overContent: overContent,
        ),
      ),
    ),
  );
}

void main() {
  test('fill composites to the measured flat-page colors', () {
    // 亮：黑@13 叠页底 #F3F3F3 → #E7E7E7（881px 实测反推 a=12.6≈13）
    expect(MiSearchBarPalette.light.fill.alpha, 13);
    expect(
      _compose(const Color(0xFFF3F3F3), MiSearchBarPalette.light.fill),
      const Color(0xFFE7E7E7),
    );
    // 暗：白@36 叠页底 #000000 → #242424（实测反推 a=36）
    expect(MiSearchBarPalette.dark.fill.alpha, 36);
    expect(
      _compose(const Color(0xFF000000), MiSearchBarPalette.dark.fill),
      const Color(0xFF242424),
    );
  });

  /// 压在内容上时改用玻璃膜：平底页那档 5% 黑在照片上几乎读不出栏形。
  testWidgets('overContent paints the glass veil instead of the flat fill',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 300);
    addTearDown(tester.view.reset);

    for (final mode in MiThemeMode.values) {
      await tester.pumpWidget(_harness(mode: mode, overContent: true));
      final box = tester.widget<ColoredBox>(
        find
            .descendant(
                of: find.byType(MiSearchBar), matching: find.byType(ColoredBox))
            .first,
      );
      expect(box.color, MiTransparencyTokens.veilFor(mode));
      expect(box.color, isNot(MiSearchBarPalette.of(mode).fill));
    }
  });

  test('palette ink matches the measured stroke cores', () {
    // 占位文字：笔画核心中位数（亮 #848484 / 暗 #6D6D6D）
    expect(MiSearchBarPalette.light.hint, const Color(0xFF848484));
    expect(MiSearchBarPalette.dark.hint, const Color(0xFF6D6D6D));
    // 放大镜墨色：明暗两图交叉实测同值
    expect(MiSearchBarPalette.light.icon, const Color(0xFF9A9A9A));
    expect(MiSearchBarPalette.dark.icon, const Color(0xFF9A9A9A));
  });

  testWidgets('frosts the backdrop with the shared transparency token', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 300);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(mode: MiThemeMode.dark));

    // 与底部导航栏 / 胶囊同源：所有 BackdropFilter 共用 blurSigma
    expect(MiTransparencyTokens.blurSigma, 28);
    expect(
      find.descendant(of: find.byType(MiSearchBar), matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    // 半透明填充存在（透明语言 0-255 字节 alpha + Color.fromARGB）
    expect(
      tester.widget<ColoredBox>(
        find.descendant(of: find.byType(MiSearchBar), matching: find.byType(ColoredBox)),
      ).color,
      MiSearchBarPalette.dark.fill,
    );
  });

  testWidgets('geometry matches measurements', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 300);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(mode: MiThemeMode.light));

    final bar = tester.getSize(find.byType(MiSearchBar));
    expect(bar.height, closeTo(MiSearchBarMetrics.barHeight, 0.01));
    expect(bar.width, closeTo(393, 0.01));
    final barTopLeft = tester.getTopLeft(find.byType(MiSearchBar));

    // 图标：左缘 15.4、17.8 见方、垂心居中
    final icon = find.descendant(
      of: find.byType(MiSearchBar),
      matching: find.byType(CustomPaint),
    );
    expect(icon, findsOneWidget);
    final iconSize = tester.getSize(icon);
    expect(iconSize.width, closeTo(MiSearchBarMetrics.iconSize, 0.01));
    expect(iconSize.height, closeTo(MiSearchBarMetrics.iconSize, 0.01));
    final iconTopLeft = tester.getTopLeft(icon);
    expect(iconTopLeft.dx - barTopLeft.dx, closeTo(MiSearchBarMetrics.contentInset, 0.01));
    expect(
      iconTopLeft.dy + iconSize.height / 2,
      closeTo(barTopLeft.dy + bar.height / 2, 0.01),
    );

    // 占位文字：起于 15.4 + 17.8 + 12 = 45.2，字号 16.5，墨色取 palette
    final text = tester.widget<Text>(find.text('搜索主题 / 壁纸 / 图标'));
    expect(text.style!.fontSize, MiTypography.searchHint.fontSize);
    expect(text.style!.color, MiSearchBarPalette.light.hint);
    final textTopLeft = tester.getTopLeft(find.text('搜索主题 / 壁纸 / 图标'));
    expect(
      textTopLeft.dx - barTopLeft.dx,
      closeTo(MiSearchBarMetrics.contentInset + MiSearchBarMetrics.iconSize + MiSearchBarMetrics.iconGap, 0.01),
    );
    expect(
      textTopLeft.dy + text.style!.fontSize! / 2,
      closeTo(barTopLeft.dy + bar.height / 2, 0.5),
    );
  });

  testWidgets('tap invokes onTap only when provided', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 300);
    addTearDown(tester.view.reset);

    // 无 onTap：不参与手势
    await tester.pumpWidget(_harness(mode: MiThemeMode.dark));
    expect(
      find.descendant(of: find.byType(MiSearchBar), matching: find.byType(GestureDetector)),
      findsNothing,
    );

    // 有 onTap：点按触发一次
    var taps = 0;
    await tester.pumpWidget(
      _harness(mode: MiThemeMode.dark, onTap: () => taps++),
    );
    await tester.tap(find.byType(MiSearchBar));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('null themeMode follows the ambient Theme brightness', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 300);
    addTearDown(tester.view.reset);

    Color fillIn() => tester
        .widget<ColoredBox>(
          find.descendant(of: find.byType(MiSearchBar), matching: find.byType(ColoredBox)),
        )
        .color;

    await tester.pumpWidget(_harness(theme: ThemeData.light(useMaterial3: true)));
    expect(fillIn(), MiSearchBarPalette.light.fill);

    await tester.pumpWidget(_harness(theme: ThemeData.dark(useMaterial3: true)));
    // MaterialApp 的 theme 是 AnimatedTheme（默认 200ms）→ 换 theme 的当帧
    // `Theme.of` 仍是旧亮度（`ThemeData.lerp` 在 t<0.5 取前者），必须等动画走完
    await tester.pump(const Duration(milliseconds: 300));
    expect(fillIn(), MiSearchBarPalette.dark.fill);
  });

  test('const construction stays available', () {
    const bar = MiSearchBar(hint: '搜索主题 / 壁纸 / 图标');
    expect(bar.hint, '搜索主题 / 壁纸 / 图标');
    expect(bar.themeMode, isNull);
    expect(bar.onTap, isNull);
    expect(MiSearchBarMetrics.barHeight, 44.1);
  });
}
