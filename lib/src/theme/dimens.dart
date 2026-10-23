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

  /// 宽屏页边距（**推导值**）：手机档按素材度量 11.9 / 20，平板与桌面没有
  /// 样张，取 32 —— 24 在 1000dp 以上的画布里会让内容顶到边缘，40 又吃掉了
  /// 卡片列宽；32 与主题卡列距（11.9）在同一比例阶梯上。
  static const double spaceXxxl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 14;
  static const double radiusLg = 20;

  /// 胶囊形（全圆角），如按钮/搜索框。
  static const double radiusPill = 999;
}
