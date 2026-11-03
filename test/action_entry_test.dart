import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_like_ui/mi_like_ui.dart';

/// 纵向动作条目（MiActionEntry / MiActionEntryRow）回归。
///
/// 判据约定：
///  * 几何按 [MiActionEntryMetrics] 逐值对上（22dp 图标 + 3dp 间隙 +
///    `MiTypography.navLabel` 文字）；
///  * 按压 = 整格淡出至 0.55（MReader 自拼件口径，瞬时）；禁用 = 降透明
///    至全库禁用档 ≈38%，回调不触发；状态机由 MiPressable 提供；
///  * 高亮态（active）图标与文字走强调色；
///  * 三态（悬停 / 焦点 / 按压）与 MiPressable 同一套开关。
void main() {
  Widget wrap(Widget child, {MiThemeData? theme}) => MaterialApp(
        // 深色环境：与库默认一致，判据稳定。
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          backgroundColor: Colors.black,
          body: theme == null ? child : MiTheme(data: theme, child: child),
        ),
      );

  /// 包一层定宽，避免 Row 在测试窗口（800 宽）里拉满影响几何判据。
  Widget bounded(Widget child, {MiThemeData? theme}) =>
      wrap(Center(child: SizedBox(width: 393, child: child)), theme: theme);

  Finder entryWith(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byType(MiActionEntry),
      );

  /// 条目内图标（IconTheme 下发墨色，Icon 自身不带 color 参数）。
  Finder iconOf(String label) => find.descendant(
        of: entryWith(label),
        matching: find.byType(Icon),
      );

  /// 当前墨色（IconTheme 是按压 / 禁用淡出的下发层，在条目子树内）。
  Color inkOf(WidgetTester tester, String label) =>
      tester.widget<IconTheme>(
        find.descendant(
          of: entryWith(label),
          matching: find.byType(IconTheme),
        ),
      ).data.color!;

  /// 标签墨色（pressBuilder 下发的 DefaultTextStyle 层）。
  TextStyle labelStyleOf(WidgetTester tester, String label) =>
      tester.widget<DefaultTextStyle>(
        find.descendant(
          of: entryWith(label),
          matching: find.byType(DefaultTextStyle),
        ),
      ).style;

  group('几何', () {
    testWidgets('图标 22、间隙 3、标签 navLabel 同档', (tester) async {
      await tester.pumpWidget(bounded(
        const MiActionEntryRow(entries: [
          MiActionEntry(icon: Icons.menu_book_outlined, label: '目录', onPressed: _noop),
        ]),
      ));
      final icon = tester.getSize(iconOf('目录'));
      expect(icon.width, MiActionEntryMetrics.iconSize);
      expect(icon.height, MiActionEntryMetrics.iconSize);

      // 间隙 = 图标与标签之间的 SizedBox（条目内可能还有别的盒）。
      final gap = tester.widget<SizedBox>(
        find.descendant(
          of: entryWith('目录'),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.height == MiActionEntryMetrics.iconLabelGap,
          ),
        ),
      );
      expect(gap.height, MiActionEntryMetrics.iconLabelGap);

      final style = labelStyleOf(tester, '目录');
      expect(style.fontSize, MiTypography.navLabel.fontSize);
      expect(style.fontWeight, MiTypography.navLabel.fontWeight);
    });

    testWidgets('行高等于度量；条目等分（Expanded 每格同宽）', (tester) async {
      await tester.pumpWidget(bounded(
        const MiActionEntryRow(entries: [
          MiActionEntry(icon: Icons.menu_book_outlined, label: '目录', onPressed: _noop),
          MiActionEntry(icon: Icons.dark_mode_outlined, label: '夜间', onPressed: _noop),
          MiActionEntry(icon: Icons.tune, label: '设置', onPressed: _noop),
        ]),
      ));
      final row = tester.getSize(find.byType(MiActionEntryRow));
      expect(row.height, MiActionEntryMetrics.rowHeight);
      // 等分：三格同宽 = 393 / 3。
      final w1 = tester.getSize(entryWith('目录')).width;
      final w2 = tester.getSize(entryWith('夜间')).width;
      final w3 = tester.getSize(entryWith('设置')).width;
      expect(w1, closeTo(w2, 0.001));
      expect(w2, closeTo(w3, 0.001));
      expect(w1, closeTo(393 / 3, 0.001));
    });
  });

  group('交互', () {
    testWidgets('按压整格淡出 0.55，松开复原', (tester) async {
      await tester.pumpWidget(bounded(
        const MiActionEntryRow(entries: [
          MiActionEntry(icon: Icons.tune, label: '设置', onPressed: _noop),
        ]),
      ));
      // 静止态：前景墨色不透明。
      expect(inkOf(tester, '设置').a, closeTo(1.0, 0.001));

      final gesture =
          await tester.startGesture(tester.getCenter(entryWith('设置')));
      await tester.pump();
      expect(
        inkOf(tester, '设置').a,
        closeTo(MiActionEntryMetrics.pressFade, 0.001),
      );
      await gesture.up();
      await tester.pump();
      expect(inkOf(tester, '设置').a, closeTo(1.0, 0.001));
    });

    testWidgets('点按触发回调', (tester) async {
      var taps = 0;
      await tester.pumpWidget(bounded(
        MiActionEntryRow(entries: [
          MiActionEntry(
            icon: Icons.menu_book_outlined,
            label: '目录',
            onPressed: () => taps++,
          ),
        ]),
      ));
      await tester.tap(entryWith('目录'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('禁用（onPressed null）：降透明、不触发回调', (tester) async {
      var taps = 0;
      await tester.pumpWidget(bounded(
        MiActionEntryRow(entries: [
          MiActionEntry(
            icon: Icons.more_horiz,
            label: '更多',
            onPressed: taps == 0 ? null : () => taps++,
          ),
        ]),
      ));
      expect(
        inkOf(tester, '更多').a,
        closeTo(MiActionEntryMetrics.disabledFade, 0.001),
      );
      await tester.tap(entryWith('更多'));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('键盘焦点环 + Enter 激活（MiPressable 三态之一）', (tester) async {
      var taps = 0;
      await tester.pumpWidget(bounded(
        MiActionEntryRow(entries: [
          MiActionEntry(
            icon: Icons.tune,
            label: '设置',
            onPressed: () => taps++,
          ),
        ]),
      ));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(const Duration(milliseconds: 150));
      final ring = tester.widget<AnimatedContainer>(
        find.byKey(MiFocusRing.ringKey),
      );
      final decoration = ring.decoration! as BoxDecoration;
      // 深色模式焦点环 = 白描边。
      expect(decoration.border!.top.color, Colors.white);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
    });
  });

  group('高亮与主题', () {
    testWidgets('active 条目图标与文字走强调色', (tester) async {
      await tester.pumpWidget(bounded(
        const MiActionEntryRow(entries: [
          MiActionEntry(
            icon: Icons.dark_mode_outlined,
            label: '夜间',
            active: true,
            onPressed: _noop,
          ),
          MiActionEntry(icon: Icons.tune, label: '设置', onPressed: _noop),
        ]),
      ));
      final accent = MiTheme.accentOf(tester.element(entryWith('夜间')));
      expect(inkOf(tester, '夜间'), accent);
      expect(labelStyleOf(tester, '夜间').color, accent);
      // 非高亮条目仍是前景墨色。
      expect(
        inkOf(tester, '设置'),
        MiColors.foregroundFor(MiThemeMode.dark),
      );
    });

    testWidgets('MiTheme 声明 light 后墨色换浅色配方', (tester) async {
      // 无 MiTheme 时跟随环境 Theme 亮度（深色环境）。
      await tester.pumpWidget(bounded(
        const MiActionEntryRow(entries: [
          MiActionEntry(icon: Icons.tune, label: '设置', onPressed: _noop),
        ]),
      ));
      expect(
        inkOf(tester, '设置'),
        MiColors.foregroundFor(MiThemeMode.dark),
      );

      await tester.pumpWidget(wrap(
        const MiActionEntryRow(entries: [
          MiActionEntry(icon: Icons.tune, label: '设置', onPressed: _noop),
        ]),
        theme: const MiThemeData(mode: MiThemeMode.light),
      ));
      expect(
        inkOf(tester, '设置'),
        MiColors.foregroundFor(MiThemeMode.light),
      );
    });
  });
}

void _noop() {}
