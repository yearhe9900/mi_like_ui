import 'package:flutter/material.dart';

import '../theme/theme_mode.dart';
import '../theme/transparency_tokens.dart';

/// 指针悬停反馈（桌面 / 接鼠标的平板）。
///
/// 参考素材来自触屏手机，没有悬停样张 —— 这一层是**推导**出来的桌面
/// 语义：可点区域在鼠标进入时叠一层极淡的实色（[MiTransparencyTokens.
/// hoverOverlayFor]，按压高光的 60%），并给出手型光标；移出复原。
///
/// 实现约束（本项目已踩过的坑）：
///  * 叠色用**实色 `AnimatedContainer`** 而不是 `Opacity` / `FadeTransition`
///    —— 后者会引入 `saveLayer`，本库的磨砂子树里一旦出现 saveLayer，
///    下层 `BackdropFilter` 的 backdrop 直接变空（磨砂消失）；
///  * 未悬停时叠色是**全透明**而不是「不挂这个子树」：结构恒定，鼠标进出
///    不会引起子树重建（黄金图也因此逐像素不变）。
///
/// [enabled] 为 false 时不挂 `MouseRegion`（触屏形态不需要光标），
/// 也不显示叠色。
class MiHoverFeedback extends StatefulWidget {
  const MiHoverFeedback({
    super.key,
    required this.child,
    this.mode,
    this.borderRadius,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 150),
    this.onHoverChanged,
  }) : assert(duration > Duration.zero);

  /// 叠色层的 key（测试用来读当前叠色；不是公开 API 语义）。
  static const Key overlayKey = Key('mi-hover-overlay');

  /// 悬停态变化回调（true = 进入）。
  ///
  /// 供需要「悬停时才显示额外 UI」的宿主用（如卡片的悬停快捷操作）——
  /// 悬停状态只在本组件里维护一份，不重复挂 `MouseRegion`。
  final ValueChanged<bool>? onHoverChanged;

  /// 叠色形状跟随的圆角（如胶囊 / 圆角卡）；null = 直角。
  final BorderRadius? borderRadius;

  /// 悬停时长（淡入淡出，与桌面惯例的 100~200ms 同量级）。
  final Duration duration;

  /// 子级（保持原尺寸；叠色覆盖其边界）。
  final Widget child;

  /// 明暗模式；null = 跟随环境 `Theme` 亮度。
  final MiThemeMode? mode;

  /// 是否启用悬停反馈。
  final bool enabled;

  @override
  State<MiHoverFeedback> createState() => _MiHoverFeedbackState();
}

class _MiHoverFeedbackState extends State<MiHoverFeedback> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final mode = widget.mode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!_hovered) {
          setState(() => _hovered = true);
          widget.onHoverChanged?.call(true);
        }
      },
      onExit: (_) {
        if (_hovered) {
          setState(() => _hovered = false);
          widget.onHoverChanged?.call(false);
        }
      },
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                key: MiHoverFeedback.overlayKey,
                duration: widget.duration,
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: _hovered
                      ? MiTransparencyTokens.hoverOverlayFor(mode)
                      : Colors.transparent,
                  borderRadius: widget.borderRadius,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
