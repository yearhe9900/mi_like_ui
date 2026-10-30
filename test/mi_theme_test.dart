import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_like_ui/mi_like_ui.dart';

/// MiTheme（App 级主题注入点）回归。
///
/// 判据约定：
///  * **向后兼容**：不包 `MiTheme` 时行为与旧版逐像素一致 ——
///    默认深色型组件（按钮 / 玻璃栏 / 胶囊行）取深色，环境跟随型组件
///    （顶栏 / 搜索栏 / 弹框等）取 `Theme` 亮度；
///  * **一处声明全库生效**：根部包 `MiTheme` 后，未显式传参的组件全部
///    跟随声明的模式；
///  * **显式参数优先**：组件级 `themeMode` 仍可局部覆盖（页内并排
///    展示明暗两套样张的场景）；
///  * **品牌色注入**：`accent` / `pageBackground*` 注入后，按钮填充、
///    搜索光标、焦点环、推入转场幕布同源换色；不注入时取度量默认值。
void main() {
  /// 包一层可选 MiTheme 的脚手架（深色 Scaffold 保证亮度判据稳定）。
  Widget wrap(Widget child, {MiThemeData? theme, Brightness brightness = Brightness.dark}) {
    return MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: theme == null
            ? child
            : MiTheme(data: theme, child: child),
      ),
    );
  }

  group('向后兼容（不包 MiTheme）', () {
    testWidgets('默认深色型组件取深色配方（填充 = 度量蓝）', (tester) async {
      await tester.pumpWidget(wrap(const MiButton(label: '关注', onPressed: _noop)));
      final container = tester.widget<AnimatedContainer>(
        find.byWidgetPredicate(
          (w) =>
              w is AnimatedContainer &&
              w.decoration is ShapeDecoration &&
              (w.decoration! as ShapeDecoration).color != null,
        ),
      );
      final decoration = container.decoration! as ShapeDecoration;
      // 深色配方主按钮填充（度量 #4980F7）—— 未包 MiTheme 行为不变。
      expect(decoration.color, MiButtonPalette.of(MiThemeMode.dark).filledFill);
      expect(decoration.color, const Color(0xFF4980F7));
    });

    testWidgets('环境跟随型组件参数保持 null（跟 Theme 亮度）', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Center(
            child: SizedBox(
              width: 200,
              child: MiThemeCard(
                title: '卡',
                preview: ColoredBox(color: Colors.grey),
              ),
            ),
          ),
          brightness: Brightness.light,
        ),
      );
      // 浅色环境下未显式给参数的组件应跟环境（参数本身为 null）。
      final card = tester.widget<MiThemeCard>(find.byType(MiThemeCard));
      expect(card.themeMode, isNull);
    });
  });

  group('MiTheme 声明模式', () {
    testWidgets('未显式传参的按钮跟随声明（light）', (tester) async {
      await tester.pumpWidget(wrap(
        const MiButton(label: '关注', onPressed: _noop),
        theme: const MiThemeData(mode: MiThemeMode.light),
        // 环境故意给 dark：声明应压过环境。
        brightness: Brightness.dark,
      ));
      final button = tester.widget<MiButton>(find.byType(MiButton));
      expect(button.themeMode, isNull);
      // 解析口径：声明 light → 浅色配方的次级填充（度量 #E7E7E7）。
      expect(MiButtonPalette.of(MiThemeMode.light).tonalFill,
          const Color(0xFFE7E7E7));
    });

    testWidgets('显式参数压过 MiTheme 声明', (tester) async {
      await tester.pumpWidget(wrap(
        const MiButton(label: '关注', onPressed: _noop, themeMode: MiThemeMode.dark),
        theme: const MiThemeData(mode: MiThemeMode.light),
      ));
      final button = tester.widget<MiButton>(find.byType(MiButton));
      expect(button.themeMode, MiThemeMode.dark);
    });

    testWidgets('胶囊行 / 玻璃栏同口径跟随声明', (tester) async {
      await tester.pumpWidget(wrap(
        const MiPillTabBar(
          labels: ['推荐', '关注'],
          selectedIndex: 0,
          onTap: _noopInt,
          themeMode: null, // 显式 null 与不传同义：跟随 MiTheme
        ),
        theme: const MiThemeData(mode: MiThemeMode.light),
      ));
      final tab = tester.widget<MiPillTabBar>(find.byType(MiPillTabBar));
      expect(tab.themeMode, isNull);
    });
  });

  group('品牌色注入', () {
    testWidgets('accent 注入后主按钮填充换品牌色', (tester) async {
      const brand = Color(0xFFE94F37);
      await tester.pumpWidget(wrap(
        const MiButton(label: '关注', onPressed: _noop),
        theme: const MiThemeData(accent: brand),
      ));
      // 注入路径：palette.of(mode, accent:) 换 filledFill，其余槽位不变。
      final injected = MiButtonPalette.of(MiThemeMode.dark, accent: brand);
      expect(injected.filledFill, brand);
      expect(injected.filledLabel, MiButtonPalette.dark.filledLabel);
      expect(injected.tonalFill, MiButtonPalette.dark.tonalFill);
    });

    testWidgets('accent 注入后搜索光标换品牌色，未注入取默认', (tester) async {
      const brand = Color(0xFFE94F37);
      final injected = MiSearchBarPalette.of(MiThemeMode.light, accent: brand);
      expect(injected.caret, brand);
      expect(injected.hint, MiSearchBarPalette.light.hint);
      // 默认强调色走 const 配方（不重建实例，值仍为度量蓝）。
      final base = MiSearchBarPalette.of(MiThemeMode.light, accent: MiColors.accent);
      expect(identical(base, MiSearchBarPalette.light), isTrue);
    });

    testWidgets('焦点环浅色模式取注入强调色', (tester) async {
      const brand = Color(0xFFE94F37);
      await tester.pumpWidget(wrap(
        MiFocusRing(
          mode: MiThemeMode.light,
          onActivate: _noop,
          child: const SizedBox(width: 40, height: 40),
        ),
        theme: const MiThemeData(accent: brand),
      ));
      // 键盘聚焦后环才着色（未聚焦 = 透明占位）。
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(const Duration(milliseconds: 150));
      final ring = tester.widget<AnimatedContainer>(
        find.byKey(MiFocusRing.ringKey),
      );
      final decoration = ring.decoration! as BoxDecoration;
      expect(decoration.border!.top.color, brand);
    });

    testWidgets('pageBackground 注入影响推入转场幕布取色口径', (tester) async {
      const paper = Color(0xFFF5EEDC);
      const data = MiThemeData(
        mode: MiThemeMode.light,
        pageBackgroundLight: paper,
      );
      // 幕布取色 = MiTheme.pageBackgroundFor(context, mode)：注入值优先。
      expect(data.pageBackgroundFor(MiThemeMode.light), paper);
      // 未注入维度回落度量默认值（暗 = 纯黑）。
      expect(data.pageBackgroundFor(MiThemeMode.dark), MiColors.pageBackgroundDark);
      // 空数据 = 全库默认。
      expect(const MiThemeData().pageBackgroundFor(MiThemeMode.light),
          MiColors.pageBackgroundLight);
    });
  });

  group('MiThemeData 值语义', () {
    test('相等性与 hashCode（updateShouldNotify 依赖）', () {
      const a = MiThemeData(mode: MiThemeMode.dark, accent: Color(0xFF123456));
      const b = MiThemeData(mode: MiThemeMode.dark, accent: Color(0xFF123456));
      const c = MiThemeData(mode: MiThemeMode.light);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('merge：非空字段覆盖，空字段保留', () {
      const base = MiThemeData(mode: MiThemeMode.dark, accent: Color(0xFF111111));
      final merged = base.merge(const MiThemeData(accent: Color(0xFF222222)));
      expect(merged.mode, MiThemeMode.dark);
      expect(merged.accent, const Color(0xFF222222));
      // merge(null) 原样返回。
      expect(identical(base.merge(null), base), isTrue);
    });
  });
}

void _noop() {}
void _noopInt(int _) {}
