/// 全局间距 / 圆角 token（随组件增长而扩充）。
///
/// 约定：4 的倍数阶梯；组件内外边距、圆角优先取这里，其次才允许组件自定义。
class MiDimens {
  MiDimens._();

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double spaceXxl = 24;

  static const double radiusSm = 8;
  static const double radiusMd = 14;
  static const double radiusLg = 20;

  /// 胶囊形（全圆角），如按钮/搜索框。
  static const double radiusPill = 999;
}
