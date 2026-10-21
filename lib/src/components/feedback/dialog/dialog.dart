import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/dialog_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../theme/typography.dart';
import 'dialog_metrics.dart';

/// 弹框位置（三档）。默认 [MiDialogPosition.bottom]，与参考图一致。
enum MiDialogPosition {
  /// 贴顶（**推导（非实测）** —— 参考图只有底部档，取底部 32.9dp 的镜像，
  /// 真机上再以安全区兜底让开状态栏）。
  top,

  /// 垂直居中（**推导（非实测）**，对齐方式同样镜像自参考图的留白节奏）。
  center,

  /// 贴底（实测：卡片底缘距屏幕底 32.9dp，含手势条让位）。
  bottom,
}

/// 弹框按钮形态。
enum MiDialogActionStyle {
  /// 中性：表面灰填充 + 次级文字（实测「取消」）。
  neutral,

  /// 主按钮：强调蓝填充 + 白字（实测「确定」）。
  filled,

  /// 破坏性：中性填充 + 红字（实测「删除」）。
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

/// 小米系统弹框（明暗双模式、三档位置，遮罩 + 卡片一体）。
///
/// 1:1 实测自两张 MIUI 系统弹框参考图（联系人「删除联系人」、主题商店
/// 「删除1项资源」，各含亮/暗）：卡片宽 369.2 / 圆角 49.3 / 高随正文行数
/// 增长（双行实测 207.1），标题 / 正文 / 按钮标签的**墨心落点全部由
/// `Baseline` 钉死**（见 [MiDialogMetrics]），底缘距屏幕 32.9dp。
///
/// ## 两个参考弹框的差异与取舍
///
/// 两 app 的 dialog builder 并不完全一致，组件按**联系人弹框**（原生
/// 分辨率、精度最高）一条节奏走到底：
///  * 正文对齐两图不同（联系人 start、主题商店 center）→ 做成参数
///    [messageAlign]，默认 [TextAlign.center]；
///  * 主题商店弹框整块文字低 2.4dp、少一行时卡片矮 19.7dp（行距 23.2
///    的 0.9 行），差值如实记在 [MiDialogMetrics]，不折中。
///
/// ## 位置（[position]）
///
/// [MiDialogPosition.bottom] 为默认档（实测）；top / center 为推导：
/// top 镜像底部 32.9dp 并以安全区兜底（让开状态栏），center 垂直居中。
///
/// ## 按压动效（实测）
///
/// 参考图为静态截图、一度无动效实测，2026-10-21 用户补了**按压录屏**（24.31fps，
/// 1220×2656）后补齐：按下时**填充叠一层按压色**（亮 = 黑 @0.12 压暗、暗 =
/// 白 @0.12 提亮，Material state layer / 本项目返回钮按压同一语言）、
/// **标签不变、不缩放**，150ms `easeOutQuad` 进入（逐帧 47/80/96/100%
/// 拟合）；松开同值回弹（录屏里松手即执行关闭、未见回弹，属推导）。
/// 遮罩点按触发 [onScrimTap]，由宿主决定是否收起；录屏里松手后弹框还有一段
/// ~80ms 的下滑收尾，属**宿主收起动画**，组件不接管移除。
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

  /// 底部按钮行（0…3 个，等宽均分；间距/盒高实测）。
  final List<MiDialogAction> actions;

  /// 位置（默认 [MiDialogPosition.bottom]）。
  final MiDialogPosition position;

  /// 正文对齐（默认居中，取自主题商店弹框；联系人弹框为
  /// [TextAlign.start]，两图实测不一致）。
  final TextAlign messageAlign;

  /// 明暗模式；为空时跟随环境 `Theme.of(context).brightness`。
  final MiThemeMode? themeMode;

  /// 遮罩点按回调（null = 遮罩不吃点按）。
  final VoidCallback? onScrimTap;

  /// 正文行数（按正文宽度排版求解 —— 卡片高与按钮行位置都随行数走，
  /// 同一排版环境下确定性可复现）。
  int _messageLineCount(BuildContext context) {
    final text = message;
    if (text == null || text.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: _messageStyle(MiDialogPalette.of(_modeOf(context))),
      ),
      textDirection: Directionality.of(context),
    )..layout(
        maxWidth:
            MiDialogMetrics.cardWidth - 2 * MiDialogMetrics.messageInset,
      );
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
        // 行距是实测几何（23.2dp），由 metrics 供给并进 `height`。
        height: MiDialogMetrics.messageLinePitch /
            MiTypography.dialogMessage.fontSize!,
      );

  @override
  Widget build(BuildContext context) {
    final mode = _modeOf(context);
    final palette = MiDialogPalette.of(mode);
    final lines = _messageLineCount(context);
    final cardHeight = MiDialogMetrics.cardHeightFor(lines);
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        // 遮罩：整屏压暗（实测亮 α0.20 / 暗 α0.60），吃点按由宿主收起。
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
              final bottomOffset = math.max(
                MiDialogMetrics.edgeInset,
                safeBottom,
              );
              final topOffset = math.max(MiDialogMetrics.edgeInset, safeTop);
              return Stack(
                children: [
                  Positioned(
                    left: MiDialogMetrics.sideMargin,
                    right: MiDialogMetrics.sideMargin,
                    height: cardHeight,
                    top: switch (position) {
                      MiDialogPosition.top => topOffset,
                      MiDialogPosition.bottom => maxH - bottomOffset - cardHeight,
                      MiDialogPosition.center => (maxH - cardHeight) / 2,
                    },
                    child: _card(context, palette, mode, lines),
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
  ) {
    final messageText = message;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(MiDialogMetrics.cardRadius),
        ),
        // 裁剪圆角：按钮 / 文字都不出圈（`Clip.antiAlias` 恒定，避免状态切换
        // 增删裁剪层重建子树）。
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MiDialogMetrics.cardRadius),
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
                      width: MiDialogMetrics.cardWidth -
                          2 * MiDialogMetrics.messageInset,
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

/// 弹框按钮本体：实测圆角 15.0 / 盒高 49.9，标签墨心 = 盒心（Baseline 钉）。
///
/// 按压态只把填充过渡到压色（见 [MiTransparencyTokens.dialogPressedFill]，
/// 150ms easeOutQuad），标签与几何不动 —— 与录屏实测一致。
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
