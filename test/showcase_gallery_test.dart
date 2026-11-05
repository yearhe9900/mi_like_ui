import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；demo 层测试直接引示例代码。
import 'package:mi_like_ui/mi_like_ui.dart';
import 'package:mi_like_ui/demo/mock_pages.dart';

/// 「分类」展示页的「组件展示 / 弹层与效果」两组：四组胶囊标签全部是
/// **真实组件陈列**（不再有「示例三 / 示例四」占位组），这里锁定两组新
/// 内容的可交互契约：
///
///  * 组件展示 —— 搜索栏两态 + 取消钮 fade、设置行、三态反馈、响应式网格；
///  * 弹层与效果 —— 声明式弹框入口透传、命令式 `showMiDialog` 拿下标、
///    弹出面板唤起 / 收回、渐进模糊 σ 缩放。
void main() {
  /// 渲染「分类」页（默认胶囊下标 0 = Logo 展示）。
  Future<void> pumpShowcase(
    WidgetTester tester, {
    ValueChanged<MiDialogPosition>? onShowDialog,
    VoidCallback? onShowListDialog,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 856);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        // 弹层单点渲染层：与 demo 外壳同口径 —— 页面内投放的 snackbar
        // 等浮层注册到宿主（无宿主时 MiSnackbar.show 断言失败）。
        home: MiPopupHost(
          child: Scaffold(
            body: MockPage(
              1,
              themeMode: MiThemeMode.dark,
              onShowDialog: onShowDialog,
              onShowListDialog: onShowListDialog,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 切到指定胶囊分组（吸顶头部里的胶囊标签）。
  Future<void> switchTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// 把目标滚到可见（末节内容在浮动底栏让位之后，需先滚出栏外）。
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  /// 展示页的滚动体（页内 `ListView`；命中多个 `Scrollable`，取第一个）。
  Finder showcaseScrollable() => find
      .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
      .first;

  /// 逐行滚到可见再操作：吸顶头部会盖住顶缘，`ensureVisible` 的落点可能
  /// 被头部 / 浮动底栏吃掉，这里按行步进滚动。
  Future<void> revealRow(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      120,
      scrollable: showcaseScrollable(),
    );
    await tester.pumpAndSettle();
  }

  group('「组件展示」组', () {
    testWidgets('搜索栏：静态态 + 输入态 + 取消钮随输入态 fade', (tester) async {
      await pumpShowcase(tester);
      await switchTab(tester, '组件展示');

      // 顶栏自带一条搜索栏 + 本组陈列两条（静态态 + 输入态）。
      expect(find.byType(MiSearchBar), findsNWidgets(3));
      expect(find.byType(MiSearchCancelButton), findsOneWidget);

      // 未聚焦且无输入：取消钮 fade = 0（仍占位排版，只动 alpha ——
      // 圆钮内含 backdrop 磨砂，不能套 Opacity）。
      var cancel = tester.widget<MiSearchCancelButton>(
        find.byType(MiSearchCancelButton),
      );
      expect(cancel.fade, 0);
      expect(cancel.onTap, isNull);

      // 点输入态搜索栏 → 聚焦 → 淡入到 fade = 1。
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      cancel = tester.widget<MiSearchCancelButton>(
        find.byType(MiSearchCancelButton),
      );
      expect(cancel.fade, 1);
      expect(cancel.onTap, isNotNull);

      // 输入：状态同步（取消钮保持可见）。
      await tester.enterText(find.byType(TextField), '雾林');
      await tester.pumpAndSettle();

      // 点取消钮：清空 + 失焦 → 淡出回 0。
      await tester.tap(find.byType(MiSearchCancelButton));
      await tester.pumpAndSettle();
      cancel = tester.widget<MiSearchCancelButton>(
        find.byType(MiSearchCancelButton),
      );
      expect(cancel.fade, 0);
      expect(find.text('雾林'), findsNothing);
    });

    testWidgets('设置行：值文 / 开关尾部 / 副标题三态都在', (tester) async {
      await pumpShowcase(tester);
      await switchTab(tester, '组件展示');

      expect(find.text('WLAN'), findsOneWidget);
      expect(find.text('蓝牙'), findsOneWidget);
      expect(find.text('个人热点'), findsOneWidget);

      // 尾部开关已换成本库的 MiSwitch（不再是 Material Switch）。
      final bluetoothRow = find.ancestor(
        of: find.text('蓝牙'),
        matching: find.byType(MiSettingsRow),
      );
      final wifiSwitch =
          find.descendant(of: bluetoothRow, matching: find.byType(MiSwitch));
      expect(wifiSwitch, findsOneWidget);

      final before = tester.widget<MiSwitch>(wifiSwitch).value;
      await tester.tap(wifiSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<MiSwitch>(wifiSwitch).value, !before);
    });

    testWidgets('开关：开 / 关 / 禁用三态陈列都在', (tester) async {
      await pumpShowcase(tester);
      await switchTab(tester, '组件展示');

      Finder switchOf(String label) => find.descendant(
            of: find.ancestor(
              of: find.text(label),
              matching: find.byType(MiSettingsRow),
            ),
            matching: find.byType(MiSwitch),
          );

      await revealRow(tester, switchOf('已开启'));
      expect(tester.widget<MiSwitch>(switchOf('已开启')).value, isTrue);
      expect(tester.widget<MiSwitch>(switchOf('已关闭')).value, isFalse);

      await revealRow(tester, find.text('禁用态（开关）'));
      expect(
        tester.widget<MiSwitch>(switchOf('禁用态（开关）')).onChanged,
        isNull,
        reason: 'onChanged 为 null = 禁用态',
      );

      await revealRow(tester, switchOf('已关闭'));
      await tester.tap(switchOf('已关闭'));
      await tester.pumpAndSettle();
      expect(tester.widget<MiSwitch>(switchOf('已关闭')).value, isTrue);
    });

    testWidgets('复选框：三态陈列，点按即切换（半选 → 全选）', (tester) async {
      await pumpShowcase(tester);
      await switchTab(tester, '组件展示');

      // 复选框一节在列表下方：逐行滚到可见再点（吸顶头部会盖住顶缘，
      // 直接 ensureVisible 的落点会被头部吃掉）。
      Finder boxOf(String label) => find.descendant(
            of: find.ancestor(
              of: find.text(label),
              matching: find.byType(MiSettingsRow),
            ),
            matching: find.byType(MiCheckbox),
          );

      await revealRow(tester, find.text('全部同步'));
      expect(tester.widget<MiCheckbox>(boxOf('全部同步')).value, isTrue);
      await tester.tap(boxOf('全部同步'));
      await tester.pumpAndSettle();
      expect(tester.widget<MiCheckbox>(boxOf('全部同步')).value, isFalse);

      await revealRow(tester, find.text('部分选中（半选）'));
      expect(tester.widget<MiCheckbox>(boxOf('部分选中（半选）')).value, isNull);
      await tester.tap(boxOf('部分选中（半选）'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MiCheckbox>(boxOf('部分选中（半选）')).value,
        isTrue,
        reason: '半选点一下即全选',
      );

      await revealRow(tester, find.text('禁用态（复选框）'));
      expect(tester.widget<MiCheckbox>(boxOf('禁用态（复选框）')).onChanged, isNull);
    });

    testWidgets('三态反馈：按压计数走 MiPressable', (tester) async {
      await pumpShowcase(tester);
      await switchTab(tester, '组件展示');

      // 三态反馈一节在列表下方：先滚到可见。
      await reveal(tester, find.text('按我'));

      expect(find.text('按我'), findsOneWidget);
      await tester.tap(find.text('按我'));
      await tester.pumpAndSettle();
      expect(find.text('按了 1 次'), findsOneWidget);

      // 三格陈列各自独立（悬停叠色 / 焦点环两格仍在）。
      expect(find.textContaining('MiHoverFeedback'), findsOneWidget);
      expect(find.textContaining('MiFocusRing'), findsOneWidget);
    });

    testWidgets('响应式网格：本组也有网格陈列（列数随容器宽）', (tester) async {
      await pumpShowcase(tester);
      await switchTab(tester, '组件展示');
      // 顶栏之外：本组的响应式网格（手机档 4 列）。
      expect(find.byType(MiResponsiveGrid), findsOneWidget);
    });

    testWidgets('菜单：偏好行展开 → 选中项回填值文', (tester) async {
      await pumpShowcase(tester);
      await switchTab(tester, '组件展示');
      await revealRow(tester, find.text('排序方式'));

      // 行自身仍是触发器（菜单不劫持点按）：点行开菜单。
      await tester.tap(find.text('排序方式'));
      await tester.pumpAndSettle();
      expect(find.byKey(MiMenu.panelKey), findsOneWidget);
      expect(find.text('修改时间'), findsOneWidget);

      await tester.tap(find.text('默认'));
      await tester.pumpAndSettle();
      expect(find.byKey(MiMenu.panelKey), findsNothing);
      // 值文回填成「默认」（此时页面上只剩这一处）。
      expect(find.text('默认'), findsOneWidget);
    });

    testWidgets('菜单：级联二级选择回填值文', (tester) async {
      await pumpShowcase(tester);
      await switchTab(tester, '组件展示');
      // 「分享」在同页另有悬浮工具栏按钮同名，按设置行收窄到菜单触发行。
      final shareRow = find.descendant(
        of: find.byType(MiSettingsRow),
        matching: find.text('分享'),
      );
      await revealRow(tester, shareRow);

      await tester.tap(shareRow);
      await tester.pumpAndSettle();
      expect(find.text('分享到'), findsOneWidget);

      await tester.tap(find.text('分享到'));
      await tester.pumpAndSettle();
      expect(find.text('微信'), findsOneWidget);

      await tester.tap(find.text('微信'));
      await tester.pumpAndSettle();
      expect(find.byKey(MiMenu.panelKey), findsNothing);
      expect(find.text('微信'), findsOneWidget);
    });
  });

  group('「弹层与效果」组', () {
    testWidgets('声明式弹框：入口透传外壳（位置逐个对应）', (tester) async {
      final shown = <MiDialogPosition>[];
      var listShown = 0;
      await pumpShowcase(
        tester,
        onShowDialog: shown.add,
        onShowListDialog: () => listShown++,
      );
      await switchTab(tester, '弹层与效果');

      await tester.tap(find.text('底部弹框（默认）'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('顶部弹框'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('居中弹框'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('操作列表弹框（纵向）'));
      await tester.pumpAndSettle();

      expect(
        shown,
        [
          MiDialogPosition.bottom,
          MiDialogPosition.top,
          MiDialogPosition.center,
        ],
      );
      expect(listShown, 1);
    });

    testWidgets('命令式弹框：await 拿被点按钮下标', (tester) async {
      await pumpShowcase(tester);
      await switchTab(tester, '弹层与效果');
      await reveal(tester, find.text('删除联系人（await 拿下标）'));

      await tester.tap(find.text('删除联系人（await 拿下标）'));
      await tester.pumpAndSettle();

      // 弹框出现在根导航器上（showMiDialog 契约）。
      expect(find.byType(MiDialog), findsOneWidget);
      expect(find.text('删除联系人'), findsWidgets);
      expect(find.text('确定从本地和云端同时删除“方太安装师傅”吗？'), findsOneWidget);

      // 点「删除」（actions[1]）→ 回传下标 1。
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(find.byType(MiDialog), findsNothing);
      expect(find.text('被点的是第 1 个按钮'), findsOneWidget);
    });

    testWidgets('命令式弹框：点遮罩关闭 → 回传 null', (tester) async {
      await pumpShowcase(tester);
      await switchTab(tester, '弹层与效果');
      await reveal(tester, find.text('删除联系人（await 拿下标）'));

      await tester.tap(find.text('删除联系人（await 拿下标）'));
      await tester.pumpAndSettle();
      expect(find.byType(MiDialog), findsOneWidget);

      // 遮罩在弹框之外的任意点。
      await tester.tapAt(const Offset(196, 120));
      await tester.pumpAndSettle();
      expect(find.byType(MiDialog), findsNothing);
      expect(find.text('弹框被关闭（点遮罩 / 系统返回）'), findsOneWidget);
    });

    testWidgets('弹出面板：从触发行弹起（高 240）、点面板外收回', (tester) async {
      await pumpShowcase(tester);
      await switchTab(tester, '弹层与效果');
      await reveal(tester, find.text('从按钮弹起（自定义高 240）'));

      expect(find.byType(MiPullUpPanel), findsNothing);

      await tester.tap(find.text('从按钮弹起（自定义高 240）'));
      await tester.pumpAndSettle();

      final panel = find.byType(MiPullUpPanel);
      expect(panel, findsOneWidget);
      expect(tester.widget<MiPullUpPanel>(panel).height, 240);
      // 面板内容（demo 层）。
      expect(find.text('主题装扮'), findsOneWidget);

      // 点面板外（面板之上、内容区）→ 反向弹簧收回 → 卸载。
      await tester.tapAt(const Offset(196, 300));
      await tester.pumpAndSettle();
      expect(find.byType(MiPullUpPanel), findsNothing);
    });

    testWidgets('底部弹窗：贴底滑入、点遮罩收起', (tester) async {
      await pumpShowcase(tester);
      await switchTab(tester, '弹层与效果');
      await reveal(tester, find.text('贴底滑入（手柄 + 遮罩）'));

      expect(find.byType(MiBottomSheet), findsOneWidget);
      // 未打开时不渲染任何层。
      expect(find.byKey(MiBottomSheet.surfaceKey), findsNothing);

      await tester.tap(find.text('贴底滑入（手柄 + 遮罩）'));
      await tester.pumpAndSettle();
      expect(find.byKey(MiBottomSheet.surfaceKey), findsOneWidget);
      expect(find.text('选择操作'), findsOneWidget);

      // 点遮罩（抽屉之上）→ 宿主置 show false → 滑出收口后注销。
      await tester.tapAt(const Offset(196, 120));
      await tester.pumpAndSettle();
      expect(find.byKey(MiBottomSheet.surfaceKey), findsNothing);
    });

    testWidgets('渐进模糊：σ 缩放滑杆改 MiGradientBlur.sigmaScale', (tester) async {
      await pumpShowcase(tester);
      await switchTab(tester, '弹层与效果');
      await reveal(tester, find.byType(Slider));

      final blur = find.byType(MiGradientBlur);
      expect(blur, findsOneWidget);
      expect(tester.widget<MiGradientBlur>(blur).sigmaScale, 1.0);

      final slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChanged!(0.6);
      await tester.pumpAndSettle();
      expect(tester.widget<MiGradientBlur>(blur).sigmaScale, 0.6);
    });
  });
}
