import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../overlay/mi_popup_host.dart';
import '../../../theme/dialog_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../theme/typography.dart';
import '../../../utils/pressable.dart';
import '../../../utils/squircle.dart';
import 'dialog_list_metrics.dart';
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

/// 弹框形态。
enum MiDialogLayout {
  /// 按钮行（默认，**度量形态**）：0…3 个横排等宽按钮（[MiDialog.actions]）。
  buttons,

  /// 纵向操作列表（**推导形态**，issue #1）：每项一行 = 可选前导图标 +
  /// 主文案 + 可选副标题（[MiDialog.items]），项间分隔线、危险项整行红字；
  /// 标题左对齐最多两行；[MiDialog.actions] 可与列表同用（列表下方一排
  /// 按钮，如「取消」）。几何见 [MiDialogListMetrics]。
  list,
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

/// 操作列表条目声明（[MiDialogLayout.list] 形态；主文案 + 可选图标 /
/// 副标题 + 点按回调）。
///
/// ```dart
/// MiDialogItem(
///   label: '删除',
///   subtitle: '从书架移除并删除本地文件',
///   destructive: true, // 整行（文案 + 副标题 + 图标）红字
///   icon: Icon(Icons.delete_outline, size: 22),
///   onPressed: close,
/// ),
/// ```
class MiDialogItem {
  const MiDialogItem({
    required this.label,
    this.subtitle,
    this.icon,
    this.destructive = false,
    this.onPressed,
  });

  /// 项主文案（单行，超出 ellipsis；样式 = 按钮标签 15.9 w500）。
  final String label;

  /// 项副标题（可选；单行 ellipsis；样式 = [MiTypography.dialogItemSubtitle]）。
  final String? subtitle;

  /// 前导图标（可选，边长取 [MiDialogListMetrics.rowIconSize] 22 —— 传入的
  /// widget 会被约束到 22×22；图标颜色走 `IconTheme`，随行墨色 / 危险色）。
  final Widget? icon;

  /// 危险项：整行（主文案 + 副标题 + 图标）红字（度量红 `destructiveActionLabel`）。
  final bool destructive;

  /// 点按回调；为 null 时该行不可点且无按压反馈（同按钮契约）。
  final VoidCallback? onPressed;
}

/// 布局期算好的卡片几何（行数、卡片高、列表顶 / 行区总高、是否被 clamp）。
class _MiDialogCardSpec {
  const _MiDialogCardSpec({
    required this.messageLines,
    required this.titleLines,
    required this.cardWidth,
    required this.radius,
    required this.cardHeight,
    required this.listTop,
    required this.rowsHeight,
    required this.clamped,
    required this.reserveIconColumn,
  });

  final int messageLines;
  final int titleLines;
  final double cardWidth;
  final double radius;
  final double cardHeight;
  final double listTop;
  final double rowsHeight;
  final bool clamped;
  final bool reserveIconColumn;
}

/// 模态弹框（明暗双模式，遮罩 + 卡片一体）。
///
/// 由全屏遮罩与弹框卡片组成：位置三档、两种形态（横排按钮 / 纵向操作列表）、
/// 按钮三种形态、按压动效，卡片高度随正文行数自适应并**受屏内高度上限约束**。
/// 几何与配色规格见 [MiDialogMetrics] / [MiDialogListMetrics] /
/// `theme/dialog_tokens.dart`；标题 / 正文 / 按钮标签的垂直落点以
/// `Baseline` 锚定，跨字体稳定。
///
/// ```dart
/// // 按钮形态（度量）
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
///
/// // 纵向操作列表形态（推导形态 —— 下游「长按图书 → 操作面板」）
/// MiDialog(
///   layout: MiDialogLayout.list,
///   title: '图书操作',
///   items: [
///     MiDialogItem(
///       label: '收藏到书架',
///       subtitle: '在书架顶部置顶显示',
///       icon: Icon(Icons.star_outline, size: 22),
///       onPressed: close,
///     ),
///     MiDialogItem(label: '删除', subtitle: '删除本地文件', destructive: true,
///       onPressed: close),
///   ],
///   actions: [MiDialogAction(label: '取消', onPressed: close)],
///   onScrimTap: close,
/// );
/// ```
///
/// ## 行为
///
///  * **位置**（[position]）：底部（默认）/ 顶部（让开安全区）/ 居中；
///  * **形态**（[layout]）：[MiDialogLayout.buttons]（默认）0…3 个横排等宽
///    按钮；[MiDialogLayout.list] 纵向操作列表 —— 每项可选前导图标 + 主
///    文案 + 可选副标题（[items]），项间 1dp 分隔线、危险项整行红字，标题
///    左对齐最多两行（[MiDialogListMetrics.titleMaxLines]）；列表与
///    [actions] 可同用（按钮行恒在列表下方、钉在卡底）；
///  * **正文对齐**（[messageAlign]）：默认居中，多行左对齐场景传
///    [TextAlign.start]；正文行数决定卡片高度（行距 23.2dp）；
///  * **按钮**（[actions]，0…3 个等宽均分）：形态见 [MiDialogActionStyle]；
///    `onPressed` 为 `null` 的按钮不可点且无按压反馈；列表项同契约；
///  * **高度上限**：卡片高**先算后摆**，超出屏内可用高（屏高 − 上下让位，
///    下限 [MiDialogMetrics.minCardHeight]）时 clamp 到可用高 —— 超长正文 /
///    超长列表不再顶出屏幕：正文区 / 列表区转为内部滚动，标题与按钮行保持
///    可见；
///  * **遮罩**：点按触发 [onScrimTap]（`null` = 不响应），是否收起由宿主
///    决定；组件不接管自身移除，宿主可自配出场动画；
///  * **按压动效**：按钮按下时填充叠按压色（亮色压暗 / 暗色提亮，@0.12），
///    标签不变、不缩放，150ms `easeOutQuad` 过渡，松开同值回弹
///    （[MiDialogMetrics.pressDurationMs]）；列表项整行同配方。
///
/// 规格取自系统弹框设计度量（明暗两组素材）；正文对齐两种形态均有参考
/// 依据，故开放为参数。**列表形态无参考素材，全部几何为推导值**
/// （[MiDialogListMetrics] 类注释）。
class MiDialog extends StatelessWidget {
  const MiDialog({
    super.key,
    this.title,
    this.message,
    this.actions = const <MiDialogAction>[],
    this.items = const <MiDialogItem>[],
    this.layout = MiDialogLayout.buttons,
    this.position = MiDialogPosition.bottom,
    this.messageAlign = TextAlign.center,
    this.themeMode,
    this.onScrimTap,
  });

  /// 标题（按钮形态：居中单行；列表形态：左对齐最多两行）。
  final String? title;

  /// 正文（随宽换行；对齐见 [messageAlign]）。
  final String? message;

  /// 底部按钮行（0…3 个，等宽均分；两种形态通用）。
  final List<MiDialogAction> actions;

  /// 操作列表条目（仅 [MiDialogLayout.list] 形态生效）。
  final List<MiDialogItem> items;

  /// 形态（默认 [MiDialogLayout.buttons]）。
  final MiDialogLayout layout;

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

  /// 标题行数（仅列表形态需要真实排版求解 —— 标题最多
  /// [MiDialogListMetrics.titleMaxLines] 行，超出以 ellipsis 截断；按钮形态
  /// 恒单行）。
  int _titleLineCount(BuildContext context, double cardWidth) {
    if (title == null) return 0;
    if (layout == MiDialogLayout.buttons) return 1;
    final painter = TextPainter(
      text: TextSpan(text: title, style: _listTitleStyle),
      textDirection: Directionality.of(context),
    )..layout(maxWidth: cardWidth - 2 * MiDialogListMetrics.rowInsetX);
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    return math.max(1, math.min(lines, MiDialogListMetrics.titleMaxLines));
  }

  /// 列表行区总高（行高定值，先算后摆 —— 见 [MiDialogListMetrics]）。
  double get _rowsHeight {
    var height = 0.0;
    for (var i = 0; i < items.length; i++) {
      if (i > 0) height += MiDialogListMetrics.dividerThickness;
      height += MiDialogListMetrics.rowHeight(
        hasSubtitle: items[i].subtitle != null,
      );
    }
    return height;
  }

  /// 列表标题样式：左对齐 + 多行行距 [MiDialogListMetrics.titleLinePitch]
  /// 并进 `height`（首行墨心仍是度量 36.4 —— `Baseline` 锚定不受 `height`
  /// 影响，行 2 起按行距顺推）。
  TextStyle get _listTitleStyle => MiTypography.dialogTitle.copyWith(
        height:
            MiDialogListMetrics.titleLinePitch /
            MiTypography.dialogTitle.fontSize!,
      );

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
  Widget build(BuildContext context) => MiPopup(
        show: true,
        builder: _body,
      );

  /// 弹层本体：经 [MiPopup] 注册 —— 有宿主时在 [MiPopupHost] 层区渲染
  ///（弹层间 z 序 = 注册序，后开在上）；无宿主时就地渲染（既有用法
  /// 与黄金图零变化）。
  Widget _body(BuildContext context) {
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
              final titleLines = _titleLineCount(context, cardWidth);
              final lines = _messageLineCount(context, cardWidth);
              final listTop = MiDialogListMetrics.listTopFor(
                titleLines: titleLines,
                messageLines: lines,
              );
              final rowsHeight = _rowsHeight;
              // 期望高（**先算后摆**）：按钮形态随正文行数线性长（度量），
              // 列表形态 = 列表顶 + 行区 + （按钮区）。
              final desired = layout == MiDialogLayout.list
                  ? MiDialogListMetrics.cardHeightFor(
                      listTop: listTop,
                      rowsHeight: rowsHeight,
                      hasActions: actions.isNotEmpty,
                    )
                  : MiDialogMetrics.cardHeightFor(lines);
              final bottomOffset = math.max(
                MiDialogMetrics.edgeInset,
                safeBottom,
              );
              final topOffset = math.max(MiDialogMetrics.edgeInset, safeTop);
              // 高度 clamp（issue #1）：屏内可用高 = 屏高 − 上下让位；极端
              // 横屏 / 小窗可用高过低时，宁可贴住安全区也保住
              // [minCardHeight] 的可读高度，但绝不越出屏幕。
              final available = math.max(
                MiDialogMetrics.minCardHeight,
                maxH - topOffset - bottomOffset,
              );
              final cardHeight = math.min(desired, math.min(available, maxH));
              final clamped = desired > cardHeight + 0.01;
              final top = wide
                  ? (maxH - cardHeight) / 2
                  : switch (position) {
                      MiDialogPosition.top => topOffset,
                      MiDialogPosition.bottom =>
                        maxH - bottomOffset - cardHeight,
                      MiDialogPosition.center => (maxH - cardHeight) / 2,
                    };
              final spec = _MiDialogCardSpec(
                messageLines: lines,
                titleLines: titleLines,
                cardWidth: cardWidth,
                radius: radius,
                cardHeight: cardHeight,
                listTop: listTop,
                rowsHeight: rowsHeight,
                clamped: clamped,
                reserveIconColumn: items.any((item) => item.icon != null),
              );
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
                    child: _card(context, palette, mode, spec),
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
    _MiDialogCardSpec spec,
  ) {
    final messageText = message;
    final listLayout = layout == MiDialogLayout.list;
    // 正文墨心：列表形态随多行标题下移（titleLines 0/1 = 度量 75.55）。
    final messageInk = MiDialogListMetrics.messageInkFirstFor(spec.titleLines);
    // 正文滚动区（**仅 clamp 路径**）：区顶取首行墨心 − 行距/2（行盒上缘
    // 推算位），区内首行基线恒为 [MiDialogMetrics.messageScrollBaseline]。
    final messageRegionTop =
        messageInk - MiDialogMetrics.messageLinePitch / 2;
    // 正文区底：列表形态止于列表顶；按钮形态止于按钮行顶（按钮行恒钉卡底）。
    final messageBottom = listLayout
        ? spec.cardHeight - spec.listTop
        : MiDialogMetrics.actionHeight + MiDialogMetrics.bottomPad;
    // 列表区底：有按钮行时留出「列表 → 按钮」间隙 + 按钮区，否则列表下留白。
    final rowsBottom = actions.isNotEmpty
        ? MiDialogListMetrics.listActionsGap +
            MiDialogMetrics.actionHeight +
            MiDialogMetrics.bottomPad
        : MiDialogListMetrics.listPadBottom;

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: palette.surface,
          shape: MiSquircleBorder(spec.radius),
        ),
        // 裁剪圆角：按钮 / 文字都不出圈（`Clip.antiAlias` 恒定，避免状态切换
        // 增删裁剪层重建子树）。
        child: ClipPath(
          clipper: MiSquircleClipper(spec.radius),
          child: Stack(
            children: [
              if (title != null)
                listLayout ? _listTitle(palette) : _dialogTitle(palette),
              if (messageText != null)
                spec.clamped
                    // clamp 路径：正文区内部滚动（区顶让开标题、区底让开
                    // 按钮行 / 列表顶），基线落点与静止路径同值。
                    ? Positioned(
                        top: messageRegionTop,
                        left: MiDialogMetrics.messageInset,
                        right: MiDialogMetrics.messageInset,
                        bottom: messageBottom,
                        child: SingleChildScrollView(
                          child: Baseline(
                            baseline: MiDialogMetrics.messageScrollBaseline,
                            baselineType: TextBaseline.alphabetic,
                            child: Text(
                              messageText,
                              textAlign: messageAlign,
                              style: _messageStyle(palette),
                            ),
                          ),
                        ),
                      )
                    // 静止路径（原样）：全宽内缩 28，首行墨心 75.55，行距
                    // 23.2 并进 `height`。
                    : Positioned(
                        top: 0,
                        left: MiDialogMetrics.messageInset,
                        right: MiDialogMetrics.messageInset,
                        child: Baseline(
                          baseline: MiDialogMetrics.baselineFor(
                            messageInk,
                            MiTypography.dialogMessage.fontSize!,
                          ),
                          baselineType: TextBaseline.alphabetic,
                          child: SizedBox(
                            width: spec.cardWidth -
                                2 * MiDialogMetrics.messageInset,
                            child: Text(
                              messageText,
                              textAlign: messageAlign,
                              style: _messageStyle(palette),
                            ),
                          ),
                        ),
                      ),
              if (listLayout && items.isNotEmpty)
                // 列表区：区顶 = [spec.listTop]，区底让开按钮行 / 列表下留白。
                // 静止时区高恰等于行区总高（不滚）；clamp 时行区内部滚动。
                Positioned(
                  top: spec.listTop,
                  left: 0,
                  right: 0,
                  bottom: rowsBottom,
                  child: _rows(palette, mode, spec),
                ),
              if (actions.isNotEmpty)
                // 按钮行：顶缘 = 卡高 − 按钮区（静止时与度量
                // `actionsTopFor(lines)` 同值；clamp 时钉在卡底不随内容滚走）。
                Positioned(
                  top:
                      spec.cardHeight -
                      MiDialogMetrics.actionHeight -
                      MiDialogMetrics.bottomPad,
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

  /// 按钮形态标题：全宽居中，墨心 36.4（Baseline 钉基线，见 metrics）。
  Widget _dialogTitle(MiDialogPalette palette) => Positioned(
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
          style: MiTypography.dialogTitle.copyWith(color: palette.title),
        ),
      ),
    ),
  );

  /// 列表形态标题：左对齐（行内缩 20）、最多两行，首行墨心仍是度量 36.4。
  Widget _listTitle(MiDialogPalette palette) => Positioned(
    top: 0,
    left: MiDialogListMetrics.rowInsetX,
    right: MiDialogListMetrics.rowInsetX,
    child: Baseline(
      baseline: MiDialogMetrics.titleBaseline,
      baselineType: TextBaseline.alphabetic,
      child: Text(
        title!,
        maxLines: MiDialogListMetrics.titleMaxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
        style: _listTitleStyle.copyWith(color: palette.title),
      ),
    ),
  );

  /// 行区（列表形态）：行间 1dp 分隔线（左右内缩 20，色见
  /// `MiDialogPalette.divider`）；整体包在滚动视图里（静止时内容恰满、不滚）。
  Widget _rows(
    MiDialogPalette palette,
    MiThemeMode mode,
    _MiDialogCardSpec spec,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MiDialogListMetrics.rowInsetX,
                ),
                child: SizedBox(
                  height: MiDialogListMetrics.dividerThickness,
                  child: ColoredBox(color: palette.divider),
                ),
              ),
            _MiDialogListRow(
              item: items[i],
              palette: palette,
              themeMode: mode,
              reserveIconColumn: spec.reserveIconColumn,
            ),
          ],
        ],
      ),
    );
  }
}

/// 操作列表行本体：整行可点，行高定值（无副标题 47.2 / 有副标题 68.2，
/// 见 [MiDialogListMetrics]）。
///
/// 按压态整行叠按压色（压在卡片填充上，与按钮同一套 state layer 语言），
/// 150ms easeOutQuad，文案与几何不变；`onPressed` 为 `null` 时无按压反馈。
class _MiDialogListRow extends StatelessWidget {
  const _MiDialogListRow({
    required this.item,
    required this.palette,
    required this.themeMode,
    required this.reserveIconColumn,
  });

  final MiDialogItem item;
  final MiDialogPalette palette;
  final MiThemeMode themeMode;

  /// 文字列是否整体让出图标位（任一项带图标即全员对齐 —— 混排会参差）。
  final bool reserveIconColumn;

  @override
  Widget build(BuildContext context) {
    final labelColor = item.destructive
        ? palette.destructiveActionLabel
        : palette.title;
    final subtitleColor = item.destructive
        ? palette.destructiveActionLabel
        : palette.secondaryText;
    final textLeft = reserveIconColumn
        ? MiDialogListMetrics.rowInsetX +
            MiDialogListMetrics.rowIconSize +
            MiDialogListMetrics.rowGap
        : MiDialogListMetrics.rowInsetX;
    // 按压状态机收编自 MiPressable（按下 / 抬起 / 取消 + 禁用门控）；
    // 按压视觉（整行换压色）留在此处 —— 几何与时序是本组件度量，
    // 叠色配方见 [MiTransparencyTokens.dialogPressedFill]。
    // 悬停 / 焦点为**推导**的桌面语义（整行矩形，无圆角）。
    return Semantics(
      button: true,
      enabled: item.onPressed != null,
      child: MiPressable(
        onPressed: item.onPressed,
        mode: themeMode,
        pressBuilder: (context, pressed, child) => AnimatedContainer(
          duration:
              const Duration(milliseconds: MiDialogMetrics.pressDurationMs),
          curve: Curves.easeOutQuad,
          height: MiDialogListMetrics.rowHeight(
            hasSubtitle: item.subtitle != null,
          ),
          color: pressed
              ? MiTransparencyTokens.dialogPressedFill(
                  palette.surface,
                  themeMode,
                )
              : palette.surface,
          child: child,
        ),
        child: Stack(
          children: [
            if (item.icon != null)
              Positioned(
                left: MiDialogListMetrics.rowInsetX,
                top: MiDialogListMetrics.iconTopY,
                width: MiDialogListMetrics.rowIconSize,
                height: MiDialogListMetrics.rowIconSize,
                // 图标色走 IconTheme（随行墨色 / 危险色），调用方只传形状。
                child: IconTheme(
                  data: IconThemeData(color: labelColor),
                  child: item.icon!,
                ),
              ),
            Positioned(
              top: 0,
              left: textLeft,
              right: MiDialogListMetrics.rowInsetX,
              child: Baseline(
                baseline: MiDialogListMetrics.labelBaseline,
                baselineType: TextBaseline.alphabetic,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: MiTypography.dialogAction.copyWith(
                    color: labelColor,
                  ),
                ),
              ),
            ),
            if (item.subtitle != null)
              Positioned(
                top: 0,
                left: textLeft,
                right: MiDialogListMetrics.rowInsetX,
                child: Baseline(
                  baseline: MiDialogListMetrics.subtitleBaseline,
                  baselineType: TextBaseline.alphabetic,
                  child: Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: MiTypography.dialogItemSubtitle.copyWith(
                      color: subtitleColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 弹框按钮本体：圆角 15.0 / 盒高 49.9，标签基线锚定于盒心。
///
/// 按压态将填充过渡至压色（[MiTransparencyTokens.dialogPressedFill]，
/// 150ms easeOutQuad），标签与几何不变。
class _MiDialogActionButton extends StatelessWidget {
  const _MiDialogActionButton({
    required this.action,
    required this.palette,
    required this.themeMode,
  });

  final MiDialogAction action;
  final MiDialogPalette palette;
  final MiThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final (fill, labelColor) = switch (action.style) {
      MiDialogActionStyle.neutral =>
        (palette.neutralActionFill, palette.secondaryText),
      MiDialogActionStyle.filled =>
        (palette.filledActionFill, palette.filledActionLabel),
      MiDialogActionStyle.destructive =>
        (palette.neutralActionFill, palette.destructiveActionLabel),
    };
    // 按压状态机收编自 MiPressable；按压视觉（填充换压色）留在此处 ——
    // 叠色配方与时序见 [MiTransparencyTokens.dialogPressedFill] 与
    // [MiDialogMetrics.pressDurationMs]（转发 [MiMotionTokens.pressMs]）。
    // 悬停 / 焦点为**推导**的桌面语义（触屏素材无此样张，同悬停体系
    // 惯例）：静止 / 未悬停时叠色全透明，黄金图零变化。
    return Semantics(
      button: true,
      enabled: action.onPressed != null,
      child: MiPressable(
        onPressed: action.onPressed,
        mode: themeMode,
        borderRadius: BorderRadius.circular(MiDialogMetrics.actionRadius),
        pressBuilder: (context, pressed, child) => AnimatedContainer(
          duration:
              const Duration(milliseconds: MiDialogMetrics.pressDurationMs),
          curve: Curves.easeOutQuad,
          decoration: ShapeDecoration(
            color: pressed
                ? MiTransparencyTokens.dialogPressedFill(fill, themeMode)
                : fill,
            shape: const MiSquircleBorder(MiDialogMetrics.actionRadius),
          ),
          child: child,
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
    );
  }
}
