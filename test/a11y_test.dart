import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_like_ui/mi_like_ui.dart';

/// 无障碍回归：语义选中态 + 系统大字体（TextScaler）。
///
/// 判据约定：
///  * 导航条目 / 胶囊标签是「按钮 + 选中态」语义 —— 读屏用户需要知道
///    哪一项当前选中（此前只有裸 GestureDetector，语义树上无选中信息）；
///  * 大字体（TextScaler）下组件不抛异常、不溢出崩溃，标签仍可见 ——
///    阅读类用户是系统大字体的高发人群，本库排版（height: 1.0 + 基线
///    锚定）需要有回归锁。
void main() {
  /// 取某语义节点的选中态。
  bool selectedOf(WidgetTester tester, String label) {
    final node = tester.getSemantics(find.text(label));
    return node.flagsCollection.isSelected == Tristate.isTrue;
  }

  bool isButton(SemanticsNode node) => node.flagsCollection.isButton;

  group('语义选中态', () {
    testWidgets('胶囊行：每项 button + selected，选中只给当前项', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MiPillTabBar(
            labels: ['推荐', '关注', '收藏'],
            selectedIndex: 1,
            onTap: _noopInt,
          ),
        ),
      ));
      expect(selectedOf(tester, '推荐'), isFalse);
      expect(selectedOf(tester, '关注'), isTrue);
      expect(selectedOf(tester, '收藏'), isFalse);
      for (final label in ['推荐', '关注', '收藏']) {
        expect(isButton(tester.getSemantics(find.text(label))), isTrue);
      }
    });

    testWidgets('玻璃底栏：条目 button + selected', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MiGlassNavBar(
            items: [
              MiGlassNavItem(label: '首页', painter: RollerIconPainter(Colors.white)),
              MiGlassNavItem(label: '分类', painter: GridSparkleIconPainter(Colors.white)),
            ],
            selectedIndex: 0,
            onTap: _noopInt,
          ),
        ),
      ));
      expect(selectedOf(tester, '首页'), isTrue);
      expect(selectedOf(tester, '分类'), isFalse);
    });

    testWidgets('玻璃侧栏：条目 button + selected', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MiGlassSideNavBar(
            items: [
              MiGlassNavItem(label: '首页', painter: RollerIconPainter(Colors.white)),
              MiGlassNavItem(label: '分类', painter: GridSparkleIconPainter(Colors.white)),
            ],
            selectedIndex: 1,
            onTap: _noopInt,
          ),
        ),
      ));
      expect(selectedOf(tester, '首页'), isFalse);
      expect(selectedOf(tester, '分类'), isTrue);
    });

    testWidgets('设置行：可点行是 button，展示行不是', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 393,
            child: MiSettingsCard(children: [
              MiSettingsRow(label: '关于手机', onTap: _noop),
              MiSettingsRow(label: '版本号', value: '1.0.0'),
            ]),
          ),
        ),
      ));
      expect(isButton(tester.getSemantics(find.text('关于手机'))), isTrue);
      expect(isButton(tester.getSemantics(find.text('版本号'))), isFalse);
    });
  });

  group('系统大字体（TextScaler）', () {
    /// 在 N× 字体下泵入组件（MediaQuery.textScaler 通道），断言不抛异常
    /// 且标签仍可见。
    Future<void> pumpScaled(
      WidgetTester tester,
      double scale,
      Widget child,
    ) async {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData().copyWith(textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: child),
        ),
      ));
    }

    testWidgets('胶囊行 2.0× 不崩溃、标签可见', (tester) async {
      await pumpScaled(
        tester,
        2.0,
        const MiPillTabBar(
          labels: ['推荐', '关注'],
          selectedIndex: 0,
          onTap: _noopInt,
        ),
      );
      expect(find.text('推荐'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('设置行 1.5× 不崩溃、主副文案可见', (tester) async {
      await pumpScaled(
        tester,
        1.5,
        const SizedBox(
          width: 393,
          child: MiSettingsCard(children: [
            MiSettingsRow(
              label: '显示与亮度',
              subtitle: '自动调节亮度、深色模式',
              onTap: _noop,
            ),
          ]),
        ),
      );
      expect(find.text('显示与亮度'), findsOneWidget);
      expect(find.text('自动调节亮度、深色模式'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('按钮 2.0× 不崩溃、标签可见', (tester) async {
      await pumpScaled(
        tester,
        2.0,
        const Center(child: MiButton(label: '关注', onPressed: _noop)),
      );
      expect(find.text('关注'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('玻璃底栏 1.5× 不崩溃、标签可见', (tester) async {
      await pumpScaled(
        tester,
        1.5,
        Align(
          alignment: Alignment.bottomCenter,
          child: MiGlassNavBar(
            items: [
              MiGlassNavItem(
                  label: '首页', painter: RollerIconPainter(Colors.white)),
              MiGlassNavItem(
                  label: '分类', painter: GridSparkleIconPainter(Colors.white)),
            ],
            selectedIndex: 0,
            onTap: _noopInt,
          ),
        ),
      );
      expect(find.text('首页'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

void _noop() {}
void _noopInt(int _) {}
