import '../../theme/row_tokens.dart';
import '../../theme/typography.dart';
import 'dialog_metrics.dart';

/// [MiDialogLayout.list]（纵向操作列表）的几何规格 —— **全部为推导值**。
///
/// 参考素材（两组系统弹框明暗样张，见 [MiDialogMetrics]）只有按钮式弹框，
/// 仓库内没有「前导图标 + 主文案 + 副标题」列表形态的度量依据；取值口径：
///
///  * **与弹框既有度量同源的部分直接沿用**：项主文案行距（23.2 = 正文行距
///    度量）、墨心/基线换算（[MiDialogMetrics.baselineFor]）、按钮行与卡底
///    留白（49.9 / 24.1）、卡片圆角与遮罩（`MiDialogPalette`）；
///  * **新增密度按通行操作菜单推导**（iOS / Android action sheet、系统长按
///    菜单）：行上下留白 12、前导图标 22、副标题 ~0.82× 主文案字号。
///
/// 所有行高与文本落点都是**行顶起算的定值**（主 / 副文案各单行 + ellipsis，
/// 不参与换行）—— 列表总高可在布局前先算后摆，这是卡片高度 clamp
/// （`MiDialog` 在超高时把卡压回屏内、列表区转滚动）能成立的前提。
class MiDialogListMetrics {
  MiDialogListMetrics._();

  // ── 行几何 ─────────────────────────────────────────────────────────────

  /// 行左右内缩 20.0（推导：正文内缩 28 是纯文本口径，列表行要给前导图标
  /// 留位，取通行菜单的 ~20）。
  static const double rowInsetX = 20.0;

  /// 前导图标边长（**同源转发** [MiRowMetrics.iconSize]）。
  static const double rowIconSize = MiRowMetrics.iconSize;

  /// 图标与文字列间距 14.0（推导：菜单通行的「图标-文字」呼吸档）。
  static const double rowGap = 14.0;

  /// 行上下留白（**同源转发** [MiRowMetrics.paddingY]）。
  static const double rowPaddingY = MiRowMetrics.paddingY;

  /// 项主文案行距（**同源转发** [MiRowMetrics.mainLinePitch]；该值即正文
  /// 行距度量 [MiDialogMetrics.messageLinePitch]）。
  static const double mainLinePitch = MiRowMetrics.mainLinePitch;

  /// 副标题行距 18.0（**同源转发** [MiRowMetrics.subtitleLinePitch]）。
  static const double subtitleLinePitch = MiRowMetrics.subtitleLinePitch;

  /// 主文案与副标题之间的间隙（**同源转发** [MiRowMetrics.subtitleGap]）。
  static const double subtitleGap = MiRowMetrics.subtitleGap;

  /// 分隔线厚 1.0（推导：hairline 通行值；色见 `MiDialogPalette.divider`）。
  static const double dividerThickness = 1.0;

  /// 行高：无副标题 = 2×行留白 + max(主行距, 图标) = 47.2；有副标题 =
  /// 2×行留白 + 主行距 + 间隙 + 副行距 = 68.2（推导，见类注释）。
  ///
  /// **同源转发** [MiRowMetrics.heightFor] —— 设置行 / 偏好行与本列表共用
  /// 同一套行几何，真源在 theme 层（组件层不再为拿行高反向依赖本文件）。
  static double rowHeight({required bool hasSubtitle}) =>
      MiRowMetrics.heightFor(hasSubtitle: hasSubtitle);

  /// 项主文案墨心（行顶起算）= 行留白 + 主行距之半 = 23.6 —— 恰为单行行
  /// 高 47.2 之半（无副标题时整行垂直居中；有副标题时上承主文案）。
  static double get labelInkY => rowPaddingY + mainLinePitch / 2;

  /// 副标题墨心（行顶起算）= 行留白 + 主行距 + 间隙 + 副行距之半 = 47.2。
  static double get subtitleInkY =>
      rowPaddingY + mainLinePitch + subtitleGap + subtitleLinePitch / 2;

  /// 前导图标盒顶（行顶起算）：与主文案墨心对齐（图标 22 < 行内容高 23.2，
  /// 居中对齐即可）。
  static double get iconTopY => labelInkY - rowIconSize / 2;

  /// 项主文案基线（行顶起算）。
  static double get labelBaseline => MiDialogMetrics.baselineFor(
        labelInkY,
        MiTypography.dialogAction.fontSize!,
      );

  /// 副标题基线（行顶起算）。
  static double get subtitleBaseline => MiDialogMetrics.baselineFor(
        subtitleInkY,
        MiTypography.dialogItemSubtitle.fontSize!,
      );

  // ── 标题 / 正文 / 列表的垂直落位 ──────────────────────────────────────

  /// 列表形态标题行距 23.0（推导：18dp 标题的通行 CJK 行盒 ≈1.28em。正文
  /// 的度量行距比 23.2/15.9 = 1.46 是「正文段落」节奏，标题两行取更紧的
  /// 菜单头节奏）。标题首行墨心仍是度量 36.4（`MiDialogMetrics`），行 2 起
  /// 按此行距顺推。
  static const double titleLinePitch = 23.0;

  /// 列表标题最多 2 行（推导 / 需求口径：下游操作单的标题是两行左对齐，
  /// 超出 ellipsis）。
  static const int titleMaxLines = 2;

  /// 上一块（标题 / 正文）末行墨心 → 首行项墨心的上距 18.0（推导）。行内
  /// 首行墨心又下移 行留白 + 主行距/2（23.6），合成墨心间距 41.6 —— 与
  /// 度量里「标题墨心 36.4 → 正文首行墨心 75.55」（39.2）同节奏。
  static const double listTopBelowInk = 18.0;

  /// 无标题无正文时列表顶距卡顶 16.0（推导：首行项墨心落在 39.6，与标题
  /// 墨心 36.4 同档）。
  static const double listPadTop = 16.0;

  /// 列表底（无按钮行时）距卡底 20.0（推导，按钮区下留白 24.1 的九折）。
  static const double listPadBottom = 20.0;

  /// 列表末行 → 按钮行顶 20.0（推导，与列表下留白同值，两块节奏一致）。
  static const double listActionsGap = 20.0;

  /// 标题末行墨心（卡顶起；[lines] = 标题行数）。
  static double titleInkLastFor(int lines) =>
      MiDialogMetrics.titleInkCenterY + (lines - 1) * titleLinePitch;

  /// 正文首行墨心（卡顶起，随多行标题下移）。标题 0/1 行时 = 度量 75.55
  /// （无标题也保留标题位 —— 与按钮形态同口径，不动度量）。
  static double messageInkFirstFor(int titleLines) =>
      titleLines <= 1
          ? MiDialogMetrics.messageInkCenterY
          : MiDialogMetrics.messageInkCenterY +
              (titleLines - 1) * titleLinePitch;

  /// 列表顶（卡顶起）：正文末行墨心 + 上距；无正文时 = 标题末行墨心 +
  /// 上距；两者皆无时 = 顶留白。
  static double listTopFor({
    required int titleLines,
    required int messageLines,
  }) {
    if (messageLines > 0) {
      return messageInkFirstFor(titleLines) +
          (messageLines - 1) * MiDialogMetrics.messageLinePitch +
          listTopBelowInk;
    }
    if (titleLines > 0) return titleInkLastFor(titleLines) + listTopBelowInk;
    return listPadTop;
  }

  /// 卡片高（先算后摆）：列表顶 + 行区总高 +（有按钮行时）列表-按钮间隙 +
  /// 按钮区，否则列表下留白。
  static double cardHeightFor({
    required double listTop,
    required double rowsHeight,
    required bool hasActions,
  }) =>
      hasActions
          ? listTop +
              rowsHeight +
              listActionsGap +
              MiDialogMetrics.actionHeight +
              MiDialogMetrics.bottomPad
          : listTop + rowsHeight + listPadBottom;
}
