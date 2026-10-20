/// [MiSearchCancelButton] 的几何参数：1:1 实测自参考录屏的**搜索态**。
///
/// Source: 「短信」搜索录屏（592×1280 @24fps，见 README「搜索态」段）。
/// 换算取 s = 66 / 44.1 = 1.4966 px/dp —— 用**同一帧里搜索栏的高度**
/// （66px）标定，因为栏高 44.1dp 是本库已实测的既有值，这样两态的高度
/// 不会被人为拉出偏差。
///
/// | item                    | 录屏 px  | dp    | 说明 |
/// |-------------------------|----------|-------|------|
/// | 取消钮直径              | 66       | 44.1  | **等于栏高**（同一帧 65~66px，圆顶被 AA 啃掉半像素） |
/// | 搜索栏 ↔ 取消钮 间隙    | 15       | 10.0  | |
/// | 取消钮右缘距屏幕右缘    | 0        | 0.0   | 见下 |
/// | 叉号墨盒                | 26 × 25  | 17.0  | 取方 17.0 |
/// | 叉号笔画宽              | 4(正交)  | 1.9   | 45° 笔画的水平弦 = w·√2 = 4px → w ≈ 2.83px |
///
/// **右缘 0 是实测、不是漏算**：同一帧里横向四项闭合 ——
/// 左缘 21 + 搜索栏 491 + 间隙 15 + 直径 66 = 593 ≈ 屏宽 592（±1px AA）。
/// 圆在纵向同样 66px 高，说明它没有被帧边界裁掉，所以「贴着屏幕右缘」
/// 就是参考实现的真实位置。要改回留白请覆盖
/// `MiTopBar.searchCancelInset`（默认即本值）。
///
/// 与栏高的关系：[diameter] 刻意等于 `MiSearchBarMetrics.barHeight`
///（44.1，两处同值由测试钉住）—— 参考图里两者本来就一样高，取同一个数
/// 可以让「搜索栏 + 取消钮」这一行在任何时候都自动垂直居中对齐。
class MiSearchCancelMetrics {
  MiSearchCancelMetrics._();

  /// 圆钮直径（66px = 44.1dp，与 [barHeight] 同值）。
  static const double diameter = 44.1;

  /// 搜索栏右缘 → 圆钮左缘（15px ≈ 10.0dp）。
  static const double barGap = 10.0;

  /// 圆钮右缘距屏幕右缘（实测 0 —— 见类文档的闭合算式）。
  static const double trailingInset = 0.0;

  /// 叉号墨盒边长（26×25px，取方 17.0dp）。
  static const double glyphSize = 17.0;

  /// 叉号笔画宽（45° 水平弦 4px → 正交 ≈ 2.83px ≈ 1.9dp）。
  static const double glyphStroke = 1.9;

  /// 按压反馈淡入时长（推导：沿用返回圆钮实测 420ms，同一套按压语言）。
  static const int pressFadeInMs = 420;

  /// 按压反馈淡出时长（推导：同上，实测 300ms）。
  static const int pressFadeOutMs = 300;
}
