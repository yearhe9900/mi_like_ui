import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/theme_mode.dart';

/// 键盘焦点环（桌面可达性）。
///
/// 参考素材来自触屏手机，没有键盘样张 —— 这一层是**推导**出来的桌面语义：
/// 可交互元素获得键盘焦点时，在其边界外画一圈 2dp 的强调色描边（macOS /
/// Windows / Material 3 的通行做法），让「Tab 到了哪里」可见。
///
/// 实现约束（与 [MiHoverFeedback] 同一套，见那份文档）：
///  * 描边用**实色 `AnimatedContainer`** 而不是 `Opacity` / `FadeTransition`
///    —— 后者会引入 `saveLayer`，磨砂子树里一旦出现 saveLayer，下层
///    `BackdropFilter` 的 backdrop 直接变空（本项目已实测的坑）；
///  * 未聚焦时描边是**全透明**而不是「不挂这个子树」：结构恒定，焦点进出
///    不引起子树重建（黄金图也因此逐像素不变）；
///  * 描边画在**子级边界外侧**（外扩 [ringWidth]），不遮挡内容本身。
///
/// 同时提供键盘激活语义：焦点在元素上时 **Enter / Space 触发 [onActivate]**
/// （按钮的通行键盘行为）。[enabled] 为 false 时不参与焦点遍历、无描边、
/// 不响应按键。
class MiFocusRing extends StatefulWidget {
  const MiFocusRing({
    super.key,
    required this.child,
    this.onActivate,
    this.borderRadius,
    this.mode,
    this.focusNode,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 120),
  }) : assert(duration > Duration.zero);

  /// 描边层的 key（测试用来读当前描边；不是公开 API 语义）。
  static const Key ringKey = Key('mi-focus-ring');

  /// 描边宽度（dp，**推导值**：Material 3 focus outline 是 3dp，本库胶囊 /
  /// 卡片都偏纤细，取 2）。
  static const double ringWidth = 2;

  /// 描边与子级边界之间的间隙（dp，**推导值**）。
  static const double ringGap = 2;

  /// 子级（保持原尺寸；描边画在其边界外侧）。
  final Widget child;

  /// 键盘激活回调（焦点在其上时 Enter / Space 触发）；null = 只可聚焦。
  final VoidCallback? onActivate;

  /// 描边形状跟随的圆角（向外扩 [ringWidth] + [ringGap]）；null = 直角。
  final BorderRadius? borderRadius;

  /// 明暗模式；null = 跟随环境 `Theme` 亮度。
  final MiThemeMode? mode;

  /// 外部焦点节点（宿主想自己控制聚焦时机时传）；null = 组件自建。
  final FocusNode? focusNode;

  /// 是否启用（false = 不参与焦点遍历、无描边、不响应按键）。
  final bool enabled;

  /// 描边淡入淡出时长。
  final Duration duration;

  @override
  State<MiFocusRing> createState() => _MiFocusRingState();
}

class _MiFocusRingState extends State<MiFocusRing> {
  FocusNode? _internalNode;
  bool _focused = false;

  FocusNode get _node => widget.focusNode ?? (_internalNode ??= FocusNode());

  @override
  void dispose() {
    _internalNode?.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled || widget.onActivate == null) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onActivate!.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final mode = widget.mode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    // 描边颜色：亮 = 强调蓝（在浅底上读得出），暗 = 白（同按压高光方向）。
    // 强调蓝是不透明实色（不是 alpha 层）——描边是一圈实线，不涉及透明度。
    final ringColor =
        mode == MiThemeMode.dark ? Colors.white : MiColors.accent;
    // 外扩量 = 间隙 + 描边宽：描边画在子级边界之外，不遮内容。
    const outset = MiFocusRing.ringGap + MiFocusRing.ringWidth;
    return Focus(
      focusNode: _node,
      canRequestFocus: widget.enabled,
      onFocusChange: (focused) {
        if (focused != _focused) setState(() => _focused = focused);
      },
      onKeyEvent: _handleKey,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned(
            left: -outset,
            top: -outset,
            right: -outset,
            bottom: -outset,
            child: IgnorePointer(
              child: AnimatedContainer(
                key: MiFocusRing.ringKey,
                duration: widget.duration,
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _focused ? ringColor : Colors.transparent,
                    width: MiFocusRing.ringWidth,
                  ),
                  borderRadius: widget.borderRadius == null
                      ? null
                      : BorderRadius.all(
                          Radius.circular(
                            widget.borderRadius!.topLeft.x + outset,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
