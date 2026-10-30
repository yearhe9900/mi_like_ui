import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_like_ui/mi_like_ui.dart';

/// 命令式弹框（showMiDialog）回归。
///
/// 判据约定：
///  * `await showMiDialog` 返回被点按钮 / 列表项的下标；点遮罩关闭返回
///    null —— 页面不再手写 Stack 挂浮层 + 显隐状态；
///  * 原 `onPressed` 回调仍执行（先回调、后关闭），同一份 MiDialog 配置
///    声明式 / 命令式两用；
///  * 挂根导航器（showDialog 同口径）；零转场时长（MiDialog 自身无进场
///    动画，与声明式出现方式一致）。
void main() {
  Widget host() => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {},
              child: const Text('打开'),
            ),
          ),
        ),
      );

  /// 带按钮形态弹框的壳：返回 Future 供断言。
  Future<int?> pumpDialog(
    WidgetTester tester, {
    required List<MiDialogAction> actions,
    MiDialogLayout layout = MiDialogLayout.buttons,
    List<MiDialogItem> items = const [],
  }) {
    final future = showMiDialog(
      tester.element(find.byType(TextButton)),
      dialog: MiDialog(
        title: '删除联系人',
        message: '确定从本地和云端同时删除吗？',
        layout: layout,
        actions: actions,
        items: items,
      ),
    );
    return future;
  }

  testWidgets('按钮形态：点第 n 个按钮返回 n，原回调执行', (tester) async {
    await tester.pumpWidget(host());
    var invoked = 0;
    final future = pumpDialog(
      tester,
      actions: [
        MiDialogAction(label: '取消', onPressed: () {}),
        MiDialogAction(
          label: '删除',
          style: MiDialogActionStyle.destructive,
          onPressed: () => invoked++,
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('删除联系人'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(await future, 1, reason: '返回被点按钮下标');
    expect(invoked, 1, reason: '原回调仍执行');
    expect(find.text('删除联系人'), findsNothing, reason: '已关闭');
  });

  testWidgets('点遮罩关闭返回 null', (tester) async {
    await tester.pumpWidget(host());
    final future = pumpDialog(
      tester,
      actions: [MiDialogAction(label: '取消', onPressed: () {})],
    );
    await tester.pumpAndSettle();

    // 点遮罩（屏幕左上角，避开卡片）。
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(await future, isNull);
    expect(find.text('删除联系人'), findsNothing);
  });

  testWidgets('列表形态：点第 n 项返回 n', (tester) async {
    await tester.pumpWidget(host());
    final future = pumpDialog(
      tester,
      layout: MiDialogLayout.list,
      actions: const [],
      items: [
        MiDialogItem(label: '收藏到书架', onPressed: () {}),
        MiDialogItem(
          label: '下载到本地',
          subtitle: '离线阅读，Wi-Fi 下自动更新',
          onPressed: () {},
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('下载到本地'));
    await tester.pumpAndSettle();

    expect(await future, 1);
  });

  testWidgets('禁用按钮（onPressed null）点按不关闭', (tester) async {
    await tester.pumpWidget(host());
    final future = pumpDialog(
      tester,
      actions: [const MiDialogAction(label: '删除')],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除'));
    await tester.pump(const Duration(milliseconds: 300));

    // Future 未完成（路由还在）。
    var done = false;
    future.then((_) => done = true);
    await tester.pump();
    expect(done, isFalse);
    expect(find.text('删除联系人'), findsOneWidget);

    // 遮罩仍可关。
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(await future, isNull);
  });

  testWidgets('挂根导航器：MaterialApp navigator 里可弹', (tester) async {
    await tester.pumpWidget(host());
    final future = pumpDialog(
      tester,
      actions: [MiDialogAction(label: '好', onPressed: () {})],
    );
    await tester.pumpAndSettle();
    // 根导航器持有路由：Overlay 里存在该路由的 page。
    expect(find.byType(MiDialog), findsOneWidget);
    await tester.tap(find.text('好'));
    await tester.pumpAndSettle();
    expect(await future, 0);
  });
}
