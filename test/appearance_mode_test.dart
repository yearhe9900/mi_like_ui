import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；demo 层直接引示例代码。
import 'package:mi_like_ui/mi_like_ui.dart';
import 'package:mi_like_ui/demo/demo_app.dart';
// 内部画笔：只用来把「勾号落在哪一项」读成数值（不属公开 API）。
import 'package:mi_like_ui/src/overlays/menu/menu_painter.dart';

import 'support/appearance.dart';

/// 外观模式三档（浅色 / 深色 / 跟随系统）的契约测试。
///
/// 口径：**偏好**（[DemoAppearance]）与**解析后的明暗**（[MiThemeMode]）是
/// 两个概念 —— 行里显示的、菜单里勾选的都是偏好；画面翻不翻面看解析结果。
void main() {
  /// 进「我的」页（外观模式行所在页）。
  Future<void> openMine(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 856);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
  }

  /// 画面当前解析出的明暗（导航栏玻璃配方与外壳同源）。
  MiThemeMode frameMode(WidgetTester tester) =>
      tester.widget<MiGlassNavBar>(find.byType(MiGlassNavBar)).themeMode!;

  /// 打开菜单（不选）。
  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.text('外观模式'));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  /// 菜单里勾号所在项的中心 y（勾号 = 单选菜单的选中标记）。
  double checkCenterY(WidgetTester tester, Finder panel) {
    final check = find.descendant(
      of: panel,
      matching: find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is MiMenuCheckPainter,
      ),
    );
    expect(check, findsOneWidget);
    return tester.getCenter(check).dy;
  }

  testWidgets('默认深色；菜单三档单选，勾选跟着偏好', (tester) async {
    await openMine(tester);
    expect(appearanceValueText(tester), '深色');
    expect(frameMode(tester), MiThemeMode.dark);

    await openMenu(tester);
    final panel = find.byKey(MiMenu.panelKey);
    expect(panel, findsOneWidget);
    for (final label in ['浅色', '深色', '跟随系统']) {
      expect(
        find.descendant(of: panel, matching: find.text(label)),
        findsOneWidget,
      );
    }
    // 勾号落在「深色」那一行（当前偏好），不是别的项
    expect(
      checkCenterY(tester, panel),
      closeTo(
        tester.getCenter(find.descendant(of: panel, matching: find.text('深色'))).dy,
        1.0,
      ),
    );
  });

  testWidgets('选浅色：行值文与整帧配色一起翻面', (tester) async {
    await openMine(tester);
    await pickAppearance(tester, DemoAppearance.light);

    expect(appearanceValueText(tester), '浅色');
    expect(frameMode(tester), MiThemeMode.light);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xFFFAFAFA),
    );

    // 再选深色：行值文与底色一起回去
    await pickAppearance(tester, DemoAppearance.dark);
    expect(appearanceValueText(tester), '深色');
    expect(frameMode(tester), MiThemeMode.dark);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xFF08080A),
    );
  });

  testWidgets('跟随系统：亮暗由平台亮度决定，系统翻面即时生效', (tester) async {
    // 测试环境默认平台亮度 = light
    await openMine(tester);
    await pickAppearance(tester, DemoAppearance.system);
    expect(appearanceValueText(tester), '跟随系统');
    expect(frameMode(tester), MiThemeMode.light);

    // 系统切到深色：不必回菜单，画面自己跟
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();
    expect(appearanceValueText(tester), '跟随系统');
    expect(frameMode(tester), MiThemeMode.dark);

    // 系统切回浅色
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(frameMode(tester), MiThemeMode.light);
  });

  testWidgets('显式档不受系统影响（选了浅色，系统翻深仍浅）', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await openMine(tester);
    await pickAppearance(tester, DemoAppearance.light);
    expect(frameMode(tester), MiThemeMode.light);

    // 系统在深色与浅色之间来回：显式浅色纹丝不动
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(frameMode(tester), MiThemeMode.light);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(frameMode(tester), MiThemeMode.light);
  });
}
