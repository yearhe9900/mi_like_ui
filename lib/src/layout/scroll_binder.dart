import 'package:flutter/material.dart';

/// 滚动位移作用域：把子树内最近一层滚动的位移广播给消费者（如 `MiTopBar`）。
///
/// 由 [MiScrollBinder] 产出；直接读 [MiScrollBinder.offsetOf] 即可，本类
/// 不单独使用。
class MiScrollScope extends InheritedNotifier<ValueNotifier<double>> {
  const MiScrollScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  /// 当前位移（dp）；通过依赖注册实现「位移变化 → 消费者重建」。
  static double? maybeOffsetOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MiScrollScope>()
      ?.notifier
      ?.value;
}

/// 滚动接线件：包住滚动内容与其消费者（顶栏），免去逐页手写的
/// `NotificationListener` / `ScrollController` + `setState` 样板。
///
/// ```dart
/// MiScrollBinder(
///   child: Stack(children: [
///     Positioned.fill(child: ListView(...)),   // 滚动内容
///     Positioned(top: 0, child: MiTopBar(...)), // scrollOffset 不用传
///   ]),
/// )
/// ```
///
/// **契约**：
///  * 只取 **depth == 0 且 [axis] 方向**的滚动通知 —— 滚动体的直接后代
///    （嵌套在外层滚动里的内层滚动 depth ≥ 1 不驱动），且胶囊行这类
///    横向滚动不会误驱动竖向折叠（[axis] 也可反过来取横向）；
///  * 位移更新走 `ValueNotifier`（等值去重，不逐帧重建整页），消费者
///    通过 [MiScrollScope] 只重建自己一层 —— 与手写
///    `ValueListenableBuilder` 等价；
///  * 不接管滚动体：`Scrollbar` / `ScrollController` 等仍由页面自持；
///  * 无滚动时位移恒 0（与 `MiTopBar` 旧默认行为一致）。
class MiScrollBinder extends StatefulWidget {
  const MiScrollBinder({
    super.key,
    required this.child,
    this.axis = Axis.vertical,
  });

  /// 被包住的子树（滚动内容 + 消费者同在此内）。
  final Widget child;

  /// 驱动消费者的滚动方向（默认竖向折叠）。
  final Axis axis;

  /// 读当前作用域位移（dp）；无作用域返回 null。供消费者在 build 中
  /// 调用（自动注册依赖，位移变化时重建）。
  static double? offsetOf(BuildContext context) => MiScrollScope.maybeOffsetOf(context);

  @override
  State<MiScrollBinder> createState() => _MiScrollBinderState();
}

class _MiScrollBinderState extends State<MiScrollBinder> {
  /// 位移源：等值不通知（拖到同一像素不会重建消费者）。
  final ValueNotifier<double> _offset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  bool _onNotification(ScrollNotification notification) {
    // depth == 0：只认最近一层滚动（见类文档契约）；方向过滤避免横向
    // 滚动体（胶囊行 / 横滑卡片）驱动竖向折叠。
    if (notification.depth == 0 &&
        notification.metrics.axis == widget.axis) {
      final pixels = notification.metrics.pixels;
      if (pixels.isFinite && pixels != _offset.value) {
        _offset.value = pixels;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: MiScrollScope(
        notifier: _offset,
        child: widget.child,
      ),
    );
  }
}
