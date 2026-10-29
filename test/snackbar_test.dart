import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel。
import 'package:mi_like_ui/mi_like_ui.dart';

/// `MiSnackbar` 与 `MiPopupHost` 弹层基建的契约测试。
///
/// 判据约定：
///  * **自动收起**：常驻 [MiSnackbarMetrics.durationMs] 后播出场动画并
///    回调 `onDismissed`（宿主据此移除）；
///  * **动作**：点按触发 `onAction` 并收起（通行惯例推导）；
///  * **宿主投放**（`MiSnackbar.show`）：同类替换（新消息顶掉旧条）、
///    出场后从注册表移除；无宿主 assert。
void main() {
  void setWindow(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  /// 就地用法的 harness：`onDismissed` 后由宿主式可见性开关移除条目
  /// （与 [MiPopupHost] 的移除契约一致 —— `find` 不看透明度，不移除
  /// 会让「已收回」断言失效）。}
  Widget inlineSnackHarness({
    required void Function(VoidCallback remove) onDismissed,
    String? actionLabel,
    VoidCallback? onAction,
    MiSnackbarController? controller,
  }) {
    var visible = true;
    return StatefulBuilder(
      builder: (context, setState) => visible
          ? MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: MiSnackbar(
                        message: '已保存到相册',
                        actionLabel: actionLabel,
                        onAction: onAction,
                        themeMode: MiThemeMode.dark,
                        controller: controller,
                        onDismissed: () => onDismissed(
                          () => setState(() => visible = false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const MaterialApp(home: SizedBox.expand()),
    );
  }

  group('就地用法（无宿主）', () {
    testWidgets('常驻时长后播出场动画并回调 onDismissed', (tester) async {
      setWindow(tester, const Size(393, 856));

      var dismissed = 0;
      await tester.pumpWidget(inlineSnackHarness(
        onDismissed: (remove) {
          dismissed++;
          remove();
        },
      ));
      await tester.pump();
      expect(find.text('已保存到相册'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: MiSnackbarMetrics.durationMs));
      await tester.pumpAndSettle();
      expect(find.text('已保存到相册'), findsNothing, reason: '出场后应已移除');
      expect(dismissed, 1);
    });

    testWidgets('动作钮：点按触发 onAction 并收起', (tester) async {
      setWindow(tester, const Size(393, 856));

      var actions = 0, dismissed = 0;
      await tester.pumpWidget(inlineSnackHarness(
        onDismissed: (remove) {
          dismissed++;
          remove();
        },
        actionLabel: '撤销',
        onAction: () => actions++,
      ));
      await tester.pump();

      await tester.tap(find.text('撤销'));
      await tester.pumpAndSettle();
      expect(actions, 1);
      expect(dismissed, 1, reason: '动作后应收回并回调移除');
    });

    testWidgets('controller.dismiss() 提前收起（计时器不再重复触发）', (tester) async {
      setWindow(tester, const Size(393, 856));

      var dismissed = 0;
      final controller = MiSnackbarController();
      await tester.pumpWidget(inlineSnackHarness(
        onDismissed: (remove) {
          dismissed++;
          remove();
        },
        controller: controller,
      ));
      await tester.pump();

      controller.dismiss();
      await tester.pumpAndSettle();
      expect(dismissed, 1);

      // 原定时到时不应再次回调（守卫幂等）。
      await tester.pump(const Duration(milliseconds: MiSnackbarMetrics.durationMs));
      await tester.pumpAndSettle();
      expect(dismissed, 1);
    });
  });

  group('宿主投放（MiSnackbar.show）', () {
    testWidgets('同类替换：新消息顶掉旧条；出场后从注册表移除', (tester) async {
      setWindow(tester, const Size(393, 856));

      late BuildContext hostContext;
      await tester.pumpWidget(
        MaterialApp(
          home: MiPopupHost(
            child: Scaffold(
              body: Builder(builder: (context) {
                hostContext = context;
                return const SizedBox.expand();
              }),
            ),
          ),
        ),
      );
      await tester.pump();

      MiSnackbar.show(hostContext, message: '第一条');
      await tester.pump();
      expect(find.text('第一条'), findsOneWidget);

      MiSnackbar.show(hostContext, message: '第二条');
      await tester.pump();
      expect(find.text('第二条'), findsOneWidget);
      expect(find.text('第一条'), findsNothing, reason: '同类替换应顶掉旧条');

      // 出场收口后条目从注册表消失（宿主层区不再有它）。
      await tester.pump(const Duration(milliseconds: MiSnackbarMetrics.durationMs));
      await tester.pumpAndSettle();
      expect(find.text('第二条'), findsNothing);
    });

    testWidgets('非模态：条目不吃下层命中（宿主包 IgnorePointer）', (tester) async {
      setWindow(tester, const Size(393, 856));

      late BuildContext hostContext;
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiPopupHost(
            child: Scaffold(
              body: Builder(builder: (context) {
                hostContext = context;
                return Center(
                  child: TextButton(
                    onPressed: () => taps++,
                    child: const Text('下层按钮'),
                  ),
                );
              }),
            ),
          ),
        ),
      );
      await tester.pump();

      MiSnackbar.show(hostContext, message: '提示');
      await tester.pump();

      // 点在下层按钮上（snackbar 在底部，位置不重叠也照点）——
      // 命中必须落到按钮。
      await tester.tap(find.text('下层按钮'));
      await tester.pump();
      expect(taps, 1);
    });
  });
}
