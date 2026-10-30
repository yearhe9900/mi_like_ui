/// 设置行组几何与动效规格（推导值 —— demo 样张目测，见
/// `theme/settings_tokens.dart` 类注释的度量状态说明）。
class MiSettingsMetrics {
  MiSettingsMetrics._();

  /// 分组卡片圆角。
  static const double cardRadius = 20;

  /// 行高下限（副标题行随内容增高）。
  static const double rowHeight = 56;

  /// 行左右内边距。
  static const double rowInsetX = 16;

  /// 副标题行的上下内边距。
  static const double rowBlockPaddingY = 10;

  /// 前导块与文案间距。
  static const double leadingGap = 14;

  /// 值文 / 尾部与文案间距。
  static const double trailingGap = 8;

  /// chevron 与值文 / 尾部间距（无尾部时与文案间距）。
  static const double chevronGap = 10;

  /// 主 / 副文案行距。
  static const double subtitleGap = 3;

  /// 前导图标块边长 / 圆角。
  static const double tileSide = 38;
  static const double tileRadius = 10;

  /// 主文案字号。
  static const double labelSize = 16;

  /// 副文案字号。
  static const double subtitleSize = 13;

  /// 值文字号。
  static const double valueSize = 14;

  /// chevron 墨盒（前进箭头 = 返回箭头的水平镜像，同墨盒尺寸）。
  static const double chevronWidth = 11.7;
  static const double chevronHeight = 21.3;

  /// 按压高亮带淡入时长（推导：MIUI 行按压为快闪档 ~120ms easeOut）。
  static const int pressDurationMs = 120;
}
