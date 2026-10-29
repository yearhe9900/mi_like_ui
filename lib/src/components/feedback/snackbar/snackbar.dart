import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../overlay/mi_popup_host.dart';
import '../../../theme/snackbar_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../theme/typography.dart';
import '../../../utils/pressable.dart';
import '../../../utils/squircle.dart';
import 'snackbar_metrics.dart';

/// 轻量消息条（`MiSnackbar`）：贴屏底的自动收起提示条，可带一个文字动作。
///
/// 几何与时序**全部为推导值**（[MiSnackbarMetrics] 注明每项取值口径），
/// 配色全部引用既有 token（[MiSnackbarPalette]）。
///
/// ## 用法
///
/// 推荐经 `MiSnackbar.show(context, message: …)` 投放到最近的
/// [MiPopupHost]：不打扰页面栈、新消息**同类替换**旧消息（顶掉后播完
/// 出场动画即移除）。无宿主时也可直接当组件用（置于页面栈顶层的
/// `Positioned.fill`，与 `MiDialog` 同宿主约定），自行管理移除。
///
/// ## 动效与绘制契约
///
///  * 入场：自下滑入 24dp（300ms `easeOut`）+ 淡入；出场镜像
///    （200ms `easeIn`）；常驻 [MiSnackbarMetrics.durationMs] 后自动收起，
///    点按动作钮同样触发收起（通行惯例推导）；
///  * 淡入淡出走 `FadeTransition` —— **本件子树不含 backdrop 磨砂**，
///    saveLayer 不会破坏任何 `BackdropFilter`（「磨砂子树禁 Opacity」
///    规则的适用边界）；勿把本件嵌进磨砂子树；
///  * 位移走 `Transform.translate`（绘制期平移，不引 saveLayer）。
class MiSnackbar extends StatefulWidget {
  const MiSnackbar({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.themeMode,
    this.duration = const Duration(
      milliseconds: MiSnackbarMetrics.durationMs,
    ),
    this.controller,
    this.onDismissed,
  });

  /// 向最近的 [MiPopupHost] 投放一条消息（同类替换：新消息顶掉旧消息）。
  ///
  /// 需要先挂 [MiPopupHost]（assert 提示）；返回的 controller 可提前收起。
  static MiSnackbarController show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    MiThemeMode? themeMode,
    Duration duration = const Duration(
      milliseconds: MiSnackbarMetrics.durationMs,
    ),
  }) {
    final registry = MiPopupScope.maybeOf(context);
    assert(
      registry != null,
      'MiSnackbar.show 需要最近祖先挂载 MiPopupHost（弹层单点渲染层）',
    );
    registry!.removeByTag(snackbarPopupTag);
    final controller = MiSnackbarController();
    registry.add(
      MiPopupHandle(
        tag: snackbarPopupTag,
        modal: false,
        build: (context) => MiSnackbar(
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
          themeMode: themeMode,
          duration: duration,
          controller: controller,
          onDismissed: () => registry.removeByTag(snackbarPopupTag),
        ),
      ),
    );
    return controller;
  }

  /// 消息正文（最多两行，超出 ellipsis）。
  final String message;

  /// 动作文字（null = 无动作）；点按触发 [onAction] 并收起。
  final String? actionLabel;

  /// 动作回调。
  final VoidCallback? onAction;

  /// 明暗模式；null = 跟随环境 `Theme` 亮度。
  final MiThemeMode? themeMode;

  /// 常驻时长（到时自动收起）。
  final Duration duration;

  /// 可编程收起（可选）。
  final MiSnackbarController? controller;

  /// 出场动画收口后的回调（宿主据此移除；就地用法据此改可见性）。
  final VoidCallback? onDismissed;

  @override
  State<MiSnackbar> createState() => _MiSnackbarState();
}

/// [MiSnackbar] 的可编程收起句柄（同 `MiPullUpPanelController` 语义）。
class MiSnackbarController {
  MiSnackbarController();

  _MiSnackbarState? _state;

  /// 播完出场动画后回调 `onDismissed`（宿主移除条目）。
  void dismiss() => _state?.dismiss();
}

/// Snackbar 在 [MiPopupRegistry] 里的同类标签（新消息顶旧消息）。
const String snackbarPopupTag = 'mi-snackbar';

class _MiSnackbarState extends State<MiSnackbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: MiSnackbarMetrics.slideInMs),
    reverseDuration: const Duration(milliseconds: MiSnackbarMetrics.slideOutMs),
  );
  Timer? _timer;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _ctrl.forward();
    _timer = Timer(widget.duration, dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller?._state = null;
    _ctrl.dispose();
    super.dispose();
  }

  void _completeDismiss() {
    if (_notified || !mounted) return;
    _notified = true;
    widget.onDismissed?.call();
  }

  /// 收起（自动到时 / 点按动作 / controller 共用一条路径）。
  void dismiss() {
    _timer?.cancel();
    if (_ctrl.isDismissed) return;
    _ctrl.reverse().whenComplete(_completeDismiss);
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.themeMode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    final palette = MiSnackbarPalette.of(mode);
    final width = math.min(
      MediaQuery.sizeOf(context).width -
          2 * MiSnackbarMetrics.horizontalMargin,
      MiSnackbarMetrics.maxWidth,
    );
    final bottom = MediaQuery.paddingOf(context).bottom +
        MiSnackbarMetrics.bottomOffset;
    final actionLabel = widget.actionLabel;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _ctrl,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            // 位移走 Transform（绘制期平移，不引 saveLayer）。
            builder: (context, child) => Transform.translate(
              offset: Offset(0, (1 - _ctrl.value) * MiSnackbarMetrics.slideOffset),
              child: child,
            ),
            child: Semantics(
              container: true,
              liveRegion: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: width,
                  minHeight: MiSnackbarMetrics.minHeight,
                ),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: palette.surface,
                    shape: MiSquircleBorder(MiSnackbarMetrics.radius),
                    // 浅色轻投影（弹出面板同口径）；暗色不投影（黑底不可分辨）。
                    shadows: mode == MiThemeMode.dark
                        ? const <BoxShadow>[]
                        : const <BoxShadow>[
                            BoxShadow(
                              color: MiTransparencyTokens.panelShadow,
                              blurRadius: MiSnackbarMetrics.shadowBlur,
                              offset: Offset(0, MiSnackbarMetrics.shadowOffsetY),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MiSnackbarMetrics.paddingH,
                      vertical: MiSnackbarMetrics.paddingV,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: MiTypography.dialogMessage
                                .copyWith(color: palette.text),
                          ),
                        ),
                        if (actionLabel != null) ...[
                          const SizedBox(width: MiSnackbarMetrics.actionGap),
                          MiPressable(
                            onPressed: () {
                              widget.onAction?.call();
                              dismiss();
                            },
                            mode: mode,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                actionLabel,
                                maxLines: 1,
                                style: MiTypography.dialogAction
                                    .copyWith(color: palette.action),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
