import '../../feedback/dialog/dialog_list_metrics.dart';

/// `MiPreferenceTile` 的几何规格（**推导值**，与弹框列表行同族复用）。
///
/// 设置行与弹框操作列表是同一套「前导图标 + 主文案 + 副标题 + 尾随」
/// 行模式 —— 行高直接复用 [MiDialogListMetrics.rowHeight]（47.2 / 68.2，
/// 有 / 无副标题），图标 22 与间距同档；页面级内边距为推导（触屏素材
/// 无设置页样张，取通行 16dp 行内边距）。
class MiPreferenceTileMetrics {
  MiPreferenceTileMetrics._();

  /// 行内边距（推导：通行 16dp）。
  static const double paddingH = 16;

  /// 前导图标尺寸（弹框列表行同档 22）。
  static const double iconSize = 22;

  /// 图标与文字间距。
  static const double iconGap = 12;

  /// 标题与副标题的行间紧缩（推导）。
  static const double titleSubtitleGap = 2;

  /// 文字列与尾随控件的间距。
  static const double trailingGap = 12;

  /// 分隔线与行内边距对齐（推导：与文字列同列起收）。
  static const double dividerInset = paddingH;

  /// 行高（有 / 无副标题两档）—— 弹框列表行同源。
  static double heightFor({required bool hasSubtitle}) =>
      MiDialogListMetrics.rowHeight(hasSubtitle: hasSubtitle);
}
