import 'package:flutter/material.dart';

import '../theme/theme_mode.dart';
import 'focus_ring.dart';
import 'hover_feedback.dart';

/// [MiPressable.pressBuilder] 的签名：按当前按压态 [pressed] 包装 [child]。
typedef MiPressBuilder = Widget Function(
  BuildContext context,
  bool pressed,
  Widget child,
);

/// 可点元素的统一反馈包装件：**按压状态机 + 悬停叠色 + 键盘焦点环**。
///
/// 本件收编了此前散在四处、逐站手写的按压状态机（弹框按钮、弹框列表行、
/// 顶栏返回钮、搜索取消钮 —— 按下 / 抬起 / 取消 + 禁用门控，逻辑同构），
/// 并把已有的 [MiHoverFeedback]（悬停叠色 + 手型光标）与 [MiFocusRing]
/// （2dp 焦点环 + Enter / Space 激活）装进同一层开关 —— 可点元素一次
/// 包装就齐备三态反馈。新组件请用本件，不要再手写 `_pressed`。
///
/// **按压视觉留在组件层**（[pressBuilder]）：按压时序与颜色是各组件的
/// 度量（弹框按钮 = 填充换压色 150ms easeOutQuad；返回钮 / 取消钮 =
/// 圆盘 420ms 淡入 / 300ms 淡出 easeOut），本件只提供 `pressed` 状态；
/// 视觉取值一律引用 [MiMotionTokens] / [MiTransparencyTokens] 与组件
/// `*_metrics.dart`，不写字面量。
///
/// ## 契约
///
///  * **禁用**（[onPressed] 为 null）：不进按压态、回调不触发；手势层
///    仍挂（opaque、无回调 —— 吸收命中但不响应，与弹框 / 按钮现行的
///    禁用契约一致）。需要「禁用时穿透命中」的站点（返回钮 / 取消钮的
///    `onTap == null → IgnorePointer`）由站点自己在外层早退，语义各自
///    保留；
///  * **结构恒定**：[pressBuilder] 恒定调用（禁用时 [pressed] 恒 false），
///    未悬停时 [MiHoverFeedback] 叠色全透明、未聚焦时 [MiFocusRing]
///    描边全透明 —— 静止态逐像素不变，黄金图不受影响；
///  * **不引 saveLayer**：悬停叠色走实色层（见 [MiHoverFeedback] 文档的
///    磨砂子树约束）；按压视觉由站点 builder 沿用各自既有画法，本件不
///    代画；
///  * 语义（`Semantics(button: …)`）由站点自己包，本件不重复声明；
///  * [focusNode] 仅在 [focus] 为 true 时生效。
///
/// 嵌套顺序（自外向内）：[MiFocusRing] → 手势 → [MiHoverFeedback] →
/// 按压视觉（pressBuilder）→ 子级 —— 与 `MiButton` 迁移前的手写三层
/// 逐层等价。
class MiPressable extends StatefulWidget {
  const MiPressable({
    super.key,
    required this.child,
    this.onPressed,
    this.pressBuilder,
    this.mode,
    this.borderRadius,
    this.hover = true,
    this.focus = true,
    this.focusNode,
    this.onHoverChanged,
  });

  /// 子级（保持原尺寸；按压 / 悬停视觉覆盖其边界）。
  final Widget child;

  /// 点按回调；为 null 时进入禁用态（见类文档的禁用契约）。
  final VoidCallback? onPressed;

  /// 按压视觉包装（见类文档「按压视觉留在组件层」）；null = 无按压视觉。
  final MiPressBuilder? pressBuilder;

  /// 明暗模式，驱动悬停叠色与焦点环配色；null = 跟随环境 `Theme` 亮度。
  final MiThemeMode? mode;

  /// 悬停叠色形状与焦点环形状跟随的圆角；null = 直角。
  final BorderRadius? borderRadius;

  /// 是否启用悬停反馈（叠色 + 手型光标；禁用时自动失效）。
  final bool hover;

  /// 是否启用键盘焦点（焦点环 + Enter / Space 激活；禁用时自动失效）。
  final bool focus;

  /// 外部焦点节点（宿主想自己控制聚焦时机时传）；仅 [focus] 为 true 时生效。
  final FocusNode? focusNode;

  /// 悬停态变化回调（true = 进入），透传给 [MiHoverFeedback]。
  final ValueChanged<bool>? onHoverChanged;

  @override
  State<MiPressable> createState() => _MiPressableState();
}

class _MiPressableState extends State<MiPressable> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(MiPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 途中禁用（按压中回调变 null）：直接落回未按压，随后的 build 重建。
    if (!_enabled) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;
    final pressBuilder = widget.pressBuilder;
    if (pressBuilder != null) {
      child = pressBuilder(context, _pressed, child);
    }
    if (widget.hover) {
      child = MiHoverFeedback(
        mode: widget.mode,
        borderRadius: widget.borderRadius,
        enabled: _enabled,
        onHoverChanged: widget.onHoverChanged,
        child: child,
      );
    }
    // 手势层恒挂：禁用时 opaque、无回调（吸收命中不响应，见类文档契约）。
    child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _enabled ? widget.onPressed : null,
      onTapDown: _enabled ? (_) => _setPressed(true) : null,
      onTapUp: _enabled ? (_) => _setPressed(false) : null,
      onTapCancel: _enabled ? () => _setPressed(false) : null,
      child: child,
    );
    if (widget.focus) {
      child = MiFocusRing(
        onActivate: widget.onPressed,
        borderRadius: widget.borderRadius,
        mode: widget.mode,
        focusNode: widget.focusNode,
        enabled: _enabled,
        child: child,
      );
    }
    return child;
  }
}
