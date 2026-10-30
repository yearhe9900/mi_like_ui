import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_like_ui/mi_like_ui.dart';

/// 设置行组（MiSettingsCard / MiSettingsRow / MiSettingsTile）回归。
///
/// 判据约定：
///  * 行高下限 56（min-height 语义：内容更高时随内容增高）；内边距按
///    [MiSettingsMetrics] 逐值对上；
///  * 按压 = 整行满铺高亮带（[MiSettingsPalette.pressFor]，120ms easeOut），
///    松开渐隐；状态机由 MiPressable 提供（禁用态不进按压、回调不触发）；
///  * chevron（[ForwardChevronIconPainter]）只在可点且无尾部时显示；
///  * 明暗配方走 [MiTheme]（可被根部声明统一驱动）。
void main() {
  Widget wrap(Widget child, {MiThemeData? theme}) => MaterialApp(
        // 深色环境：与库默认（未包 MiTheme 取深色）一致，判据稳定。
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          backgroundColor: Colors.black,
          body: theme == null ? child : MiTheme(data: theme, child: child),
        ),
      );

  /// 包一层定宽，避免 Row 在测试窗口（800 宽）里拉满影响几何判据。
  Widget bounded(Widget child, {MiThemeData? theme}) =>
      wrap(Center(child: SizedBox(width: 393, child: child)), theme: theme);

  Finder rowWith(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byType(MiSettingsRow),
      );

  Finder chevrons() => find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is ForwardChevronIconPainter,
      );

  /// 行内按指定填充色的 AnimatedContainer（悬停层 / 焦点环也是
  /// AnimatedContainer，按 decoration 的颜色区分按压带）。
  Finder bands(Color color) => find.byWidgetPredicate(
        (w) =>
            w is AnimatedContainer &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == color,
      );

  group('几何', () {
    testWidgets('行高下限 56；内边距按度量（副标题行 v:10）', (tester) async {
      await tester.pumpWidget(bounded(
        const MiSettingsCard(children: [
          MiSettingsRow(label: '显示与亮度'),
          MiSettingsRow(label: '蓝牙', subtitle: '已连接'),
        ]),
      ));
      // 无副标题行：内容矮于下限 → 撑到 56。
      final plain = tester.getSize(rowWith('显示与亮度'));
      expect(plain.height, MiSettingsMetrics.rowHeight);
      // 副标题行内层容器带 10 上下内边距（内容高度随字体，不硬编码总高）。
      final subtitleRow = tester.widget<Container>(
        find.descendant(
          of: rowWith('蓝牙'),
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.padding is EdgeInsets,
          ),
        ),
      );
      expect(
        subtitleRow.padding,
        const EdgeInsets.symmetric(
          horizontal: MiSettingsMetrics.rowInsetX,
          vertical: MiSettingsMetrics.rowBlockPaddingY,
        ),
      );
    });

    testWidgets('前导块与 chevron 墨盒逐值对上度量', (tester) async {
      await tester.pumpWidget(bounded(
        const MiSettingsCard(children: [
          MiSettingsRow(
            label: '无线局域网',
            leading: MiSettingsTile(Icons.wifi, Color(0xFF2F9BFF)),
            onTap: _noop,
          ),
        ]),
      ));
      final tile = tester.getSize(find.byType(MiSettingsTile));
      expect(tile.width, MiSettingsMetrics.tileSide);
      expect(tile.height, MiSettingsMetrics.tileSide);
      final chevron = tester.getSize(chevrons());
      expect(chevron.width, MiSettingsMetrics.chevronWidth);
      expect(chevron.height, MiSettingsMetrics.chevronHeight);
    });
  });

  group('交互', () {
    testWidgets('按压出现高亮带，松开渐隐', (tester) async {
      await tester.pumpWidget(bounded(
        const MiSettingsCard(children: [
          MiSettingsRow(label: '关于手机', onTap: _noop),
        ]),
      ));
      // 静止态：无按压带。
      expect(bands(MiSettingsPalette.pressFor(MiThemeMode.dark)), findsNothing);
      final gesture = await tester.startGesture(
        tester.getCenter(rowWith('关于手机')),
      );
      await tester.pump();
      // 按下：整行满铺 = 深色配方 pressFor。
      expect(bands(MiSettingsPalette.pressFor(MiThemeMode.dark)), findsOneWidget);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 150));
      expect(bands(MiSettingsPalette.pressFor(MiThemeMode.dark)), findsNothing);
    });

    testWidgets('无 onTap 纯展示行：无按压带、无 chevron', (tester) async {
      await tester.pumpWidget(bounded(
        const MiSettingsCard(children: [
          MiSettingsRow(label: '版本号', value: '1.0.0'),
        ]),
      ));
      await tester.tap(rowWith('版本号'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(bands(MiSettingsPalette.pressFor(MiThemeMode.dark)), findsNothing);
      expect(chevrons(), findsNothing);
    });

    testWidgets('有 trailing 时 chevron 让位', (tester) async {
      await tester.pumpWidget(bounded(
        const MiSettingsCard(children: [
          MiSettingsRow(
            label: '自动旋转',
            trailing: Switch(value: true, onChanged: _noopBool),
          ),
        ]),
      ));
      expect(chevrons(), findsNothing);
    });

    testWidgets('键盘焦点环 + Enter 激活（MiPressable 三态之一）', (tester) async {
      var taps = 0;
      await tester.pumpWidget(bounded(
        MiSettingsCard(children: [
          MiSettingsRow(label: '账号', onTap: () => taps++),
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

  group('主题', () {
    testWidgets('MiTheme 声明 light 后按压带换浅色配方', (tester) async {
      await tester.pumpWidget(bounded(
        const MiSettingsCard(children: [
          MiSettingsRow(label: '显示与亮度', onTap: _noop),
        ]),
        theme: const MiThemeData(mode: MiThemeMode.light),
      ));
      await tester.startGesture(tester.getCenter(rowWith('显示与亮度')));
      await tester.pump();
      expect(
        bands(MiSettingsPalette.pressFor(MiThemeMode.light)),
        findsOneWidget,
      );
      expect(bands(MiSettingsPalette.pressFor(MiThemeMode.dark)), findsNothing);
    });
  });
}

void _noop() {}
void _noopBool(bool _) {}
