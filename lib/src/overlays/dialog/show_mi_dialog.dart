import 'package:flutter/material.dart';

import 'dialog.dart';

/// 命令式弹出 [MiDialog]：`await` 拿结果，免去页面自己 Stack 挂浮层 +
/// 状态管理显隐的样板。
///
/// ```dart
/// final i = await showMiDialog(
///   context,
///   dialog: MiDialog(
///     title: '删除联系人',
///     message: '确定从本地和云端同时删除吗？',
///     actions: [
///       MiDialogAction(label: '取消', onPressed: () {}),
///       MiDialogAction(
///         label: '删除',
///         style: MiDialogActionStyle.destructive,
///         onPressed: () {},
///       ),
///     ],
///   ),
/// );
/// // i = 被点按钮下标；null = 点遮罩 / 系统返回关闭
/// ```
///
/// **契约**：
///  * 返回值：按钮形态 = `actions` 下标、列表形态 = `items` 下标；
///    点遮罩 / 系统返回键（Android 返回、桌面 Esc 不在路由层管）= `null`；
///  * 原 `onPressed` 回调仍会执行（先回调、后关闭），声明式用法与命令式
///    用法可以共用同一份 `MiDialog` 配置；
///  * 挂在**根导航器**上（与 `showDialog` 同口径），嵌套导航器（桌面侧栏
///    局部路由）里的页面弹框不会被子路由盖住；
///  * 零转场时长：`MiDialog` 自身无进场动画（度量素材只到静止态，不发明
///    动画），与声明式 `if (visible) MiDialog(…)` 的出现方式逐帧一致。
///
/// 仍在 Stack 里手挂 `MiDialog`（声明式）也完全支持 —— 需要跨帧共享显隐
/// 状态、或弹框与页面同帧渲染（截图 / golden）时用那种。
Future<int?> showMiDialog(
  BuildContext context, {
  required MiDialog dialog,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<int>(
    PageRouteBuilder<int>(
      opaque: false,
      // 遮罩由 MiDialog 自绘（onScrimTap 处理点按）；路由层不叠颜色，
      // 下层页面保持可见（弹框语义）。
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, _, __) => _withResult(context, dialog, navigator),
    ),
  );
}

/// 重造一份 [MiDialog]：遮罩点按与按钮 / 列表项点按都关路由并回传下标。
Widget _withResult(
  BuildContext context,
  MiDialog dialog,
  NavigatorState navigator,
) {
  void pop(int? result) {
    // 路由可能已被遮罩 / 返回键先关（连点竞态），重复 pop 会抛。
    if (navigator.canPop()) navigator.pop(result);
  }

  return MiDialog(
    title: dialog.title,
    message: dialog.message,
    layout: dialog.layout,
    position: dialog.position,
    messageAlign: dialog.messageAlign,
    themeMode: dialog.themeMode,
    actions: [
      for (var i = 0; i < dialog.actions.length; i++)
        MiDialogAction(
          label: dialog.actions[i].label,
          style: dialog.actions[i].style,
          onPressed: dialog.actions[i].onPressed == null
              ? null
              : () {
                  dialog.actions[i].onPressed!();
                  pop(i);
                },
        ),
    ],
    items: [
      for (var i = 0; i < dialog.items.length; i++)
        MiDialogItem(
          label: dialog.items[i].label,
          subtitle: dialog.items[i].subtitle,
          icon: dialog.items[i].icon,
          destructive: dialog.items[i].destructive,
          onPressed: dialog.items[i].onPressed == null
              ? null
              : () {
                  dialog.items[i].onPressed!();
                  pop(i);
                },
        ),
    ],
    onScrimTap: () => pop(null),
  );
}
