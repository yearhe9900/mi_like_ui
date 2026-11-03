import 'dart:math' as math;

/// 列表行几何（**跨组件共享规格**）—— 设置行 / 偏好行 / 弹框操作列表同一套
/// 「前导图标 + 主文案 + 副标题（可选）+ 尾随」行模式。
///
/// 本类放在 theme 层，是为了让**组件层不必反向依赖浮层**：此前
/// `MiPreferenceTileMetrics` 直接引 `MiDialogListMetrics.rowHeight`，而
/// `MiDialogListMetrics` 在 `src/overlays/`（上层），等于组件层向上要几何。
/// 现在真源在这里，`MiDialogListMetrics` 的同名字段改为**同源转发**，
/// 数值与对外 API 均不变。
///
/// 取值口径：主文案行距 23.2 是弹框正文的行距度量（见
/// `MiDialogMetrics.messageLinePitch`）；行留白 12、副标题行距 18、间隙 3、
/// 图标 22 均为**推导值**（通行操作菜单密度，推导过程见
/// `MiDialogListMetrics` 的类注释）。
class MiRowMetrics {
  MiRowMetrics._();

  /// 行上下留白。
  static const double paddingY = 12.0;

  /// 前导图标边长（不顶满主文案行距）。
  static const double iconSize = 22.0;

  /// 主文案行距（= 弹框正文行距度量）。
  static const double mainLinePitch = 23.2;

  /// 副标题行距。
  static const double subtitleLinePitch = 18.0;

  /// 主文案与副标题之间的间隙。
  static const double subtitleGap = 3.0;

  /// 行高：无副标题 = 2×留白 + max(主行距, 图标) = 47.2；有副标题 =
  /// 2×留白 + 主行距 + 间隙 + 副行距 = 68.2。
  static double heightFor({required bool hasSubtitle}) =>
      2 * paddingY +
      (hasSubtitle
          ? mainLinePitch + subtitleGap + subtitleLinePitch
          : math.max(mainLinePitch, iconSize));
}
