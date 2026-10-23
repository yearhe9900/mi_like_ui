import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_like_ui/mi_like_ui.dart';
import 'package:mi_like_ui/demo/demo_app.dart';
import 'package:mi_like_ui/demo/mock_pages.dart';

/// 桌面键盘回归（可达性）。
///
/// 判据约定：
///  * **⌘/Ctrl + K 聚焦搜索**：桌面应用的通行约定（VS Code / macOS 设置页）；
///  * **Esc 退出**：搜索态 / 推入页退出，未搜索时交给系统；
///  * **focus ring**：Tab 聚焦可点元素时在边界外画强调描边（实色
///    `AnimatedContainer`，不引 `Opacity` / saveLayer —— 磨砂子树的已知坑）；
///  * **键盘激活**：焦点在按钮上时 Enter / Space 触发 onPressed；
///  * **手机档不受影响**：compact 下不挂快捷键作用域（无物理键盘），
///    子树逐像素不变。
void main() {
  void setWindow(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
  }

  /// 发送「修饰键 + 主键」组合（本 SDK 的 `sendKeyEvent` 不带修饰键参数）。
  ///
  /// 顺序 = 修饰键 down → 主键 down/up → 修饰键 up（真实键盘时序）。
  Future<void> sendCombo(
    WidgetTester tester,
    LogicalKeyboardKey modifier,
    LogicalKeyboardKey key,
  ) async {
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(modifier);
  }

  /// 焦点环当前描边色（未聚焦 = 全透明）。
  Color ringColor(WidgetTester tester) {
    final ring = tester.widget<AnimatedContainer>(
      find.byKey(MiFocusRing.ringKey).first,
    );
    final border = (ring.decoration! as BoxDecoration).border! as Border;
    return border.top.color;
  }

  group('MiFocusRing', () {
    testWidgets('未聚焦时描边全透明（结构恒定、黄金图零变化）', (tester) async {
      setWindow(tester, const Size(400, 300));
      addTearDown(tester.view.reset);

      var pressed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MiFocusRing(
                onActivate: () => pressed++,
                borderRadius: BorderRadius.circular(8),
                child: const SizedBox(width: 80, height: 40),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 描边层始终存在（结构恒定），只是颜色全透明
      expect(find.byKey(MiFocusRing.ringKey), findsOneWidget);
      expect(ringColor(tester), Colors.transparent);
      // 磨砂子树里不许有 saveLayer 来源（Opacity）
      expect(
        find.descendant(
          of: find.byType(MiFocusRing),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
      expect(pressed, 0);
    });

    testWidgets('聚焦后画强调描边、失焦复原；Enter / Space 激活', (tester) async {
      setWindow(tester, const Size(400, 300));
      addTearDown(tester.view.reset);

      var pressed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MiFocusRing(
                onActivate: () => pressed++,
                borderRadius: BorderRadius.circular(8),
                child: const SizedBox(width: 80, height: 40),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 请求焦点（等价于 Tab 走到它）：MiFocusRing 自建的 FocusNode
      //（find.byType(Focus) 会先命中 MaterialApp 自己的，必须限定在环内）
      Finder ringFocus() => find.descendant(
            of: find.byType(MiFocusRing),
            matching: find.byType(Focus),
          );
      FocusNode nodeOf(WidgetTester t) =>
          t.widget<Focus>(ringFocus()).focusNode!;

      nodeOf(tester).requestFocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(ringColor(tester), isNot(Colors.transparent), reason: '聚焦应出现描边');

      // Enter / Space 激活
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(pressed, 2);

      // 失焦：描边回到透明
      nodeOf(tester).unfocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(ringColor(tester), Colors.transparent);
    });

    testWidgets('enabled: false 不参与焦点（无描边、不响应按键）', (tester) async {
      setWindow(tester, const Size(400, 300));
      addTearDown(tester.view.reset);

      var pressed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              // disabled 时直接返回 child —— 连描边层都不挂
              child: MiFocusRing(
                enabled: false,
                onActivate: () => pressed++,
                child: const SizedBox(width: 80, height: 40),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(MiFocusRing.ringKey), findsNothing);
      // disabled 时连 Focus 都不挂（build 直接返回 child，原样透传）
      expect(
        find.descendant(
          of: find.byType(MiFocusRing),
          matching: find.byType(Focus),
        ),
        findsNothing,
      );
    });
  });

  group('MiButton 键盘可达性', () {
    testWidgets('Tab 聚焦出描边、Enter 激活、禁用态无描边', (tester) async {
      setWindow(tester, const Size(400, 300));
      addTearDown(tester.view.reset);

      var pressed = 0;
      Widget button({VoidCallback? onPressed}) => MaterialApp(
            home: Scaffold(
              body: Center(
                child: MiButton(
                  label: '关注',
                  onPressed: onPressed,
                  themeMode: MiThemeMode.dark,
                ),
              ),
            ),
          );

      await tester.pumpWidget(button(onPressed: () => pressed++));
      await tester.pumpAndSettle();

      // 聚焦按钮里的 MiFocusRing
      final ringFocus = find
          .descendant(of: find.byType(MiButton), matching: find.byType(MiFocusRing))
          .first;
      final focusNode = tester
          .widget<Focus>(
            find.descendant(of: ringFocus, matching: find.byType(Focus)).first,
          )
          .focusNode!;
      focusNode.requestFocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(ringColor(tester), isNot(Colors.transparent));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(pressed, 1);

      // 禁用态：MiFocusRing.enabled = false → 没有描边层也没有 Focus
      await tester.pumpWidget(button());
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(MiButton),
          matching: find.byKey(MiFocusRing.ringKey),
        ),
        findsNothing,
      );
    });
  });

  group('示例应用快捷键（桌面档）', () {
    testWidgets('⌘K / Ctrl+K 聚焦搜索（首页 = 推入搜索页）', (tester) async {
      setWindow(tester, const Size(1366, 768));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      expect(find.byType(DemoSearchPage), findsNothing);

      // Ctrl + K（测试环境是 Windows/Linux 语义）
      await sendCombo(tester, LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyK);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byType(DemoSearchPage), findsOneWidget, reason: '⌘K 应推入搜索页');
    });

    testWidgets('⌘K 进入原地搜索态、Esc 退出（分类页）', (tester) async {
      setWindow(tester, const Size(1366, 768));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('分类').last);
      await tester.pumpAndSettle();

      // 进搜索态（不能 pumpAndSettle：光标闪烁定时器不会停）
      await sendCombo(tester, LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyK);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // 搜索态：内容被页底色盖住（showcaseSearchCover）
      expect(find.byKey(const ValueKey('showcaseSearchCover')), findsOneWidget);

      // Esc 退出
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('showcaseSearchCover')), findsNothing);
    });

    testWidgets('搜索页里 Esc 返回（路由弹出）', (tester) async {
      setWindow(tester, const Size(1366, 768));
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      // 点搜索栏推入（与 ⌘K 同一路径）
      await tester.tap(find.byType(MiSearchBar).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byType(DemoSearchPage), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byType(DemoSearchPage), findsNothing, reason: 'Esc 应弹出搜索页');
    });

    testWidgets('宽屏动作区有 ⌘K 提示徽标；手机档没有动作区', (tester) async {
      addTearDown(tester.view.reset);

      // 桌面：动作区（含快捷键徽标）出现
      setWindow(tester, const Size(1366, 768));
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();
      expect(find.text('Ctrl K'), findsOneWidget);

      // 手机：动作区不渲染（几何逐像素不变）
      setWindow(tester, const Size(393, 856));
      await tester.pumpWidget(DemoApp(key: UniqueKey()));
      await tester.pumpAndSettle();
      expect(find.text('Ctrl K'), findsNothing);
      expect(find.text('⌘K'), findsNothing);
    });
  });

  group('MiSearchShortcuts（组件级）', () {
    testWidgets('⌘K / Ctrl+K 触发 onFocusSearch，Esc 触发 onEscape', (tester) async {
      setWindow(tester, const Size(800, 600));
      addTearDown(tester.view.reset);

      var focusSearches = 0;
      var escapes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiSearchShortcuts(
            onFocusSearch: () => focusSearches++,
            onEscape: () => escapes++,
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await sendCombo(tester, LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyK);
      expect(focusSearches, 1, reason: '⌘K（macOS 语义）');
      await sendCombo(tester, LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyK);
      expect(focusSearches, 2, reason: 'Ctrl K（Windows/Linux 语义）');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(escapes, 1);
    });

    testWidgets('onEscape = null 时不注册 Esc（交给系统）', (tester) async {
      setWindow(tester, const Size(800, 600));
      addTearDown(tester.view.reset);

      var focusSearches = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiSearchShortcuts(
            onFocusSearch: () => focusSearches++,
            onEscape: null,
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Esc 不抛异常、不触发任何回调（没有注册绑定）
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await sendCombo(tester, LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyK);
      expect(focusSearches, 1);
    });
  });
}
