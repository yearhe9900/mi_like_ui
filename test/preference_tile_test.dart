import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel。
import 'package:mi_like_ui/mi_like_ui.dart';

/// `MiPreferenceTile` 契约测试（推导组件；行模式与弹框列表行同族）。
void main() {
  void setWindow(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Widget harness({VoidCallback? onTap, Widget? trailing}) => MaterialApp(
        home: Scaffold(
          body: MiPreferenceTile(
            leading: const Icon(Icons.wifi, size: 22),
            title: 'WLAN',
            subtitle: '已连接 Mi-5G',
            trailing: trailing ?? const Icon(Icons.chevron_right),
            onTap: onTap,
            showDivider: true,
            themeMode: MiThemeMode.dark,
          ),
        ),
      );

  testWidgets('渲染：图标 + 标题 + 副标题 + 尾随 + 分隔线（行高走弹框列表档）', (tester) async {
    setWindow(tester, const Size(393, 856));
    await tester.pumpWidget(harness(onTap: () {}));

    expect(find.text('WLAN'), findsOneWidget);
    expect(find.text('已连接 Mi-5G'), findsOneWidget);
    expect(find.byIcon(Icons.wifi), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    // 行高 = 弹框列表行有副标题档。
    final tile = tester.getRect(find.byType(MiPreferenceTile));
    expect(tile.height, moreOrLessEquals(
      MiDialogListMetrics.rowHeight(hasSubtitle: true) + 1,
      epsilon: 0.01,
    ));
  });

  testWidgets('点按触发 onTap；尾随开关独立交互', (tester) async {
    setWindow(tester, const Size(393, 856));

    var taps = 0;
    var switches = 0;
    await tester.pumpWidget(harness(
      onTap: () => taps++,
      trailing: MiSwitch(
        value: false,
        onChanged: (_) => switches++,
        themeMode: MiThemeMode.dark,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('WLAN'));
    expect(taps, 1);

    await tester.tap(find.byType(MiSwitch));
    await tester.pumpAndSettle();
    expect(switches, 1, reason: '尾随开关吃自己的手势');
  });

  testWidgets('onTap == null：只展示（不参与焦点、无按压语义）', (tester) async {
    setWindow(tester, const Size(393, 856));
    await tester.pumpWidget(harness());

    expect(find.byKey(MiFocusRing.ringKey), findsNothing);
    final semantics = tester.getSemantics(find.text('WLAN'));
    expect(semantics.hasFlag(SemanticsFlag.isButton), isFalse);
  });
}
