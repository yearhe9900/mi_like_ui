import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/dialog_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../theme/typography.dart';
import 'dialog_metrics.dart';

/// 弹框位置（三档）。默认 [MiDialogPosition.bottom]。
enum MiDialogPosition {
  /// 贴顶（推导值：底部留白的镜像，真机上以安全区兜底让开状态栏）。
  top,

  /// 垂直居中（推导值）。
  center,

  /// 贴底（卡片底缘距屏 32.9dp，含手势条让位）。
  bottom,
}

/// 弹框按钮形态。
enum MiDialogActionStyle {
  /// 中性：表面灰填充 + 次级文字（度量「取消」）。
  neutral,

  /// 主按钮：强调蓝填充 + 白字（度量「确定」）。
  filled,

  /// 破坏性：中性填充 + 红字（度量「删除」）。
  destructive,
}

/// 弹框按钮声明（文案 + 形态 + 点按回调）。
class MiDialogAction {
  const MiDialogAction({
    required this.label,
    this.onPressed,
    this.style = MiDialogActionStyle.neutral,
  });

  /// 按钮文案。
  final String label;

  /// 点按回调；为 null 时按钮不可点。
  final VoidCallback? onPressed;

  /// 按钮形态。
  final MiDialogActionStyle style;
}

/// 模态弹框（明暗双模式，遮罩 + 卡片一体）。
///
/// 由全屏遮罩与弹框卡片组成：位置三档、按钮三种形态、按压动效，卡片高度
/// 随正文行数自适应。几何与配色规格见 [MiDialogMetrics] /
/// `theme/dialog_tokens.dart`；标题 / 正文 / 按钮标签的垂直落点以
/// `Baseline` 锚定，跨字体稳定。
///
/// ```dart
/// MiDialog(
///   position: MiDialogPosition.bottom,
///   title: '删除联系人',
///   message: '确定从本地和云端同时删除"方太安装师傅"吗？',
///   messageAlign: TextAlign.start,
///   actions: [
///     MiDialogAction(label: '取消', onPressed: close),
///     MiDialogAction(
///       label: '删除',
///       style: MiDialogActionStyle.destructive,
///       onPressed: close,
///     ),
///   ],
///   onScrimTap: close,
/// );
/// ```
///
/// ## 行为
///
///  * **位置**（[position]）：底部（默认）/ 顶部（让开安全区）/ 居中；
///  * **正文对齐**（[messageAlign]）：默认居中，多行左对齐场景传
///    [TextAlign.start]；正文行数决定卡片高度（行距 23.2dp）；
///  * **按钮**（[actions]，0…3 个等宽均分）：形态见 [MiDialogActionStyle]；
///    `onPressed` 为 `null` 的按钮不可点且无按压反馈；
///  * **遮罩**：点按触发 [onScrimTap]（`null` = 不响应），是否收起由宿主
///    决定；组件不接管自身移除，宿主可自配出场动画；
///  * **按压动效**：按下时填充叠按压色（亮色压暗 / 暗色提亮，@0.12），
///    标签不变、不缩放，150ms `easeOutQuad` 过渡，松开同值回弹
///    （[MiDialogMetrics.pressDurationMs]）。
///
/// 规格取自系统弹框设计度量（明暗两组素材）；正文对齐两种形态均有参考
/// 依据，故开放为参数。
class MiDialog extends StatelessWidget {
  const MiDialog({
    super.key,
    this.title,
    this.message,
    this.actions = const <MiDialogAction>[],
    this.position = MiDialogPosition.bottom,
    this.messageAlign = TextAlign.center,
    this.themeMode,
    this.onScrimTap,
  });

  /// 标题（居中，单行）。
  final String? title;

  /// 正文（随宽换行；对齐见 [messageAlign]）。
  final String? message;

  /// 底部按钮行（0…3 个，等宽均分）。
  final List<MiDialogAction> actions;

  /// 位置（默认 [MiDialogPosition.bottom]）。
  final MiDialogPosition position;

  /// 正文对齐（默认 [TextAlign.center]；左对齐场景传 [TextAlign.start]）。
  final TextAlign messageAlign;

  /// 明暗模式；为空时跟随环境 `Theme.of(context).brightness`。
  final MiThemeMode? themeMode;

  /// 遮罩点按回调（null = 遮罩不吃点按）。
  final VoidCallback? onScrimTap;

  /// 正文行数（按正文宽度排版求解 —— 卡片高与按钮行位置都随行数走，
  /// 同一排版环境下确定性可复现）。
  ///
  /// [cardWidth] 是卡片实际宽（桌面档限宽 440，正文行更长、行数更少）。
  int _messageLineCount(BuildContext context, double cardWidth) {
    final text = message;
    if (text == null || text.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: _messageStyle(MiDialogPalette.of(_modeOf(context))),
      ),
      textDirection: Directionality.of(context),
    )..layout(maxWidth: cardWidth - 2 * MiDialogMetrics.messageInset);
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    return lines;
  }

  MiThemeMode _modeOf(BuildContext context) =>
      themeMode ??
      (Theme.of(context).brightness == Brightness.dark
          ? MiThemeMode.dark
          : MiThemeMode.light);

  TextStyle _messageStyle(MiDialogPalette palette) => MiTypography.dialogMessage
      .copyWith(
        color: palette.secondaryText,
        // 行距是度量几何（23.2dp），由 metrics 供给并进 `height`。
        height: MiDialogMetrics.messageLinePitch /
            MiTypography.dialogMessage.fontSize!,
      );

  @override
  Widget build(BuildContext context) {
    final mode = _modeOf(context);
    final palette = MiDialogPalette.of(mode);
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        // 遮罩：整屏压暗（度量亮 α0.20 / 暗 α0.60），吃点按由宿主收起。
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onScrimTap,
            child: ColoredBox(color: palette.scrim),
          ),
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxH = constraints.maxHeight;
              final maxW = constraints.maxWidth;
              // 桌面档（容器宽 ≥ 1024）：**居中窄卡** —— 手机的「贴边圆角卡」
              // 是底部弹出形态的度量，宽屏没有这条语义（Material / Windows
              // Settings / macOS Alerts 的桌面弹窗都是居中卡）。宽度收到 440、
              // 圆角 16、位置强制居中（[position] 只在手机档生效）。
              final wide = MiDialogMetrics.isWide(maxW);
              // 卡片**实际**宽：手机档 = 容器宽 − 2×边距（参考机 393 上即度量
              // 369.2；平板上照旧撑满边距之间 —— 不 clamp，保持既有行为）；
              // 桌面档 = min(440, 容器宽 − 2×边距)。正文排版、按钮行都按它算。
              final cardWidth = wide
                  ? math.min(
                      MiDialogMetrics.wideCardMaxWidth,
                      maxW - 2 * MiDialogMetrics.sideMargin,
                    )
                  : maxW - 2 * MiDialogMetrics.sideMargin;
              final radius = wide
                  ? MiDialogMetrics.wideCardRadius
                  : MiDialogMetrics.cardRadius;
              final lines = _messageLineCount(context, cardWidth);
              final cardHeight = MiDialogMetrics.cardHeightFor(lines);
              final bottomOffset = math.max(
                MiDialogMetrics.edgeInset,
                safeBottom,
              );
              final topOffset = math.max(MiDialogMetrics.edgeInset, safeTop);
              final top = wide
                  ? (maxH - cardHeight) / 2
                  : switch (position) {
                      MiDialogPosition.top => topOffset,
                      MiDialogPosition.bottom =>
                        maxH - bottomOffset - cardHeight,
                      MiDialogPosition.center => (maxH - cardHeight) / 2,
                    };
              return Stack(
                children: [
                  Positioned(
                    // 手机档：左右各留边距（**自适应**，窄容器里不溢出 ——
                    // 度量 369.2 = 393 − 2×11.9 正是这个式子在参考机上的值）。
                    // 桌面档：居中定宽（left = (容器宽 − 卡宽) / 2）。
                    left: wide ? (maxW - cardWidth) / 2 : MiDialogMetrics.sideMargin,
                    right: wide ? null : MiDialogMetrics.sideMargin,
                    width: wide ? cardWidth : null,
                    height: cardHeight,
                    top: top,
                    child: _card(context, palette, mode, lines, cardWidth, radius),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    MiDialogPalette palette,
    MiThemeMode mode,
    int lines,
    double cardWidth,
    double radius,
  ) {
    final messageText = message;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(radius),
        ),
        // 裁剪圆角：按钮 / 文字都不出圈（`Clip.antiAlias` 恒定，避免状态切换
        // 增删裁剪层重建子树）。
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              if (title != null)
                // 标题：全宽居中，墨心 36.4（Baseline 钉基线，见 metrics）。
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Baseline(
                    baseline: MiDialogMetrics.titleBaseline,
                    baselineType: TextBaseline.alphabetic,
                    child: Center(
                      child: Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MiTypography.dialogTitle
                            .copyWith(color: palette.title),
                      ),
                    ),
                  ),
                ),
              if (messageText != null)
                // 正文：文本框内缩 28，首行墨心 75.55，行距 23.2 并进 `height`。
                Positioned(
                  top: 0,
                  left: MiDialogMetrics.messageInset,
                  right: MiDialogMetrics.messageInset,
                  child: Baseline(
                    baseline: MiDialogMetrics.messageBaseline,
                    baselineType: TextBaseline.alphabetic,
                    child: SizedBox(
                      width: cardWidth - 2 * MiDialogMetrics.messageInset,
                      child: Text(
                        messageText,
                        textAlign: messageAlign,
                        style: _messageStyle(palette),
                      ),
                    ),
                  ),
                ),
              if (actions.isNotEmpty)
                Positioned(
                  top: MiDialogMetrics.actionsTopFor(lines),
                  left: MiDialogMetrics.actionRowInset,
                  right: MiDialogMetrics.actionRowInset,
                  height: MiDialogMetrics.actionHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0)
                          const SizedBox(width: MiDialogMetrics.actionGap),
                        Expanded(
                          child: _MiDialogActionButton(
                            action: actions[i],
                            palette: palette,
                            themeMode: mode,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 弹框按钮本体：圆角 15.0 / 盒高 49.9，标签基线锚定于盒心。
///
/// 按压态将填充过渡至压色（[MiTransparencyTokens.dialogPressedFill]，
/// 150ms easeOutQuad），标签与几何不变。
class _MiDialogActionButton extends StatefulWidget {
  const _MiDialogActionButton({
    required this.action,
    required this.palette,
    required this.themeMode,
  });

  final MiDialogAction action;
  final MiDialogPalette palette;
  final MiThemeMode themeMode;

  @override
  State<_MiDialogActionButton> createState() => _MiDialogActionButtonState();
}

class _MiDialogActionButtonState extends State<_MiDialogActionButton> {
  bool _pressed = false;

  bool get _enabled => widget.action.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final palette = widget.palette;
    final (fill, labelColor) = switch (action.style) {
      MiDialogActionStyle.neutral =>
        (palette.neutralActionFill, palette.secondaryText),
      MiDialogActionStyle.filled =>
        (palette.filledActionFill, palette.filledActionLabel),
      MiDialogActionStyle.destructive =>
        (palette.neutralActionFill, palette.destructiveActionLabel),
    };
    return Semantics(
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: action.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: MiDialogMetrics.pressDurationMs),
          curve: Curves.easeOutQuad,
          decoration: BoxDecoration(
            color: _pressed
                ? MiTransparencyTokens.dialogPressedFill(
                    fill,
                    widget.themeMode,
                  )
                : fill,
            borderRadius: BorderRadius.circular(MiDialogMetrics.actionRadius),
          ),
          child: Baseline(
            baseline: MiDialogMetrics.actionLabelBaseline,
            baselineType: TextBaseline.alphabetic,
            child: Center(
              child: Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MiTypography.dialogAction.copyWith(color: labelColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
