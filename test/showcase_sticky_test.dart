import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；demo 层直接引示例代码。
import 'package:mi_like_ui/mi_like_ui.dart';
import 'package:mi_like_ui/demo/mock_pages.dart';

/// 「分类」展示页吸顶行为：搜索框 + 胶囊标签行悬浮吸顶，
/// 网格上滚时从胶囊后方经过（透明/磨砂透射展示位）。
void main() {
  testWidgets('pill row stays pinned while the grid scrolls behind it',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 856);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const Scaffold(body: MockPage(1, themeMode: MiThemeMode.dark)),
      ),
    );
    await tester.pumpAndSettle();

    // 归属：搜索栏与胶囊行都是 **MiTopBar 的子树**（由顶栏自己产出），
    // 页面不再 new 这两个组件、也不再自己拼吸顶 Column。
    final bar = find.byType(MiTopBar);
    expect(bar, findsOneWidget);
    expect(
      find.descendant(of: bar, matching: find.byType(MiSearchBar)),
      findsOneWidget,
      reason: '分类页的搜索栏必须在顶部导航栏内部',
    );
    expect(
      find.descendant(of: bar, matching: find.byType(MiPillTabBar)),
      findsOneWidget,
      reason: '分类页的胶囊按钮必须在顶部导航栏内部',
    );
    // 页面里没有第二个（顶栏之外不该再有一份）
    expect(find.byType(MiSearchBar), findsOneWidget);
    expect(find.byType(MiPillTabBar), findsOneWidget);

    // 初始：标签行吸附搜索框下方 = 56 + 44.1 + 16 = 116.1
    final pillTop = tester.getTopLeft(find.byType(MiPillTabBar)).dy;
    expect(pillTop, closeTo(56 + 44.1 + 16, 0.01));

    // 内容让位由顶栏自己算（occupiedHeight 156 + 胶囊行底 → 内容 12）
    final list = tester.widget<ListView>(find.byType(ListView));
    expect((list.padding as EdgeInsets).top, closeTo(168, 0.01));

    // 上滚网格：标题滚进胶囊行后方，胶囊行原地不动
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byType(MiPillTabBar)).dy, pillTop);
    // 「Logo 展示」同时是胶囊标签与分组标题，这里取滚动网格里的分组标题
    //（标签在吸顶头部内、不上滚）。
    final sectionTitle = find.descendant(
      of: find.byType(ListView),
      matching: find.text('Logo 展示'),
    );
    expect(tester.getTopLeft(sectionTitle).dy, lessThan(pillTop));

    // 吸顶后标签仍可点（头部悬浮在滚动内容之上，命中测试不受影响）
    const dark = MiPillTabPalette.dark;
    await tester.tap(find.text('示例三'));
    await tester.pump(const Duration(milliseconds: 300));
    final container = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.text('示例三'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect((container.decoration! as ShapeDecoration).color, dark.selectedFill);
  });
}
