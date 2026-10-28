import '../../../theme/motion_tokens.dart';

/// [MiSearchCancelButton] 的几何规格（设计度量，393dp 设计宽）。
///
/// 规格取自搜索态参考素材（592×1280 @24fps），以同一帧搜索栏高度
/// （66px ↔ 44.1dp）标定换算系数 s = 66 / 44.1 = 1.4966 px/dp，保证
/// 与静态搜索栏的栏高一致：
///
/// | 项目                  | 素材 px | dp   | 说明 |
/// |-----------------------|---------|------|------|
/// | 取消钮直径            | 66      | 44.1 | 等于栏高 |
/// | 搜索栏 ↔ 取消钮 间隙  | 15      | 10.0 | |
/// | 取消钮右缘距屏幕右缘  | 0       | 0.0  | 贴屏幕右缘 |
/// | 叉号墨盒              | 26 x 25 | 17.0 | 取方 17.0 |
/// | 叉号笔画宽            | 4(正交) | 1.9  | 45° 笔画水平弦 w·√2 = 4px |
///
/// 右缘 0dp（贴边）经同行几何闭合校验：左缘 21 + 搜索栏 491 + 间隙 15 +
/// 直径 66 = 593 ≈ 屏宽 592（±1px AA）；圆在纵向同为 66px 高、未被帧
/// 边界裁切，位置为参考实现的真实摆放。需要留白时覆盖
/// `MiTopBar.searchCancelInset`（默认即本值）。
///
/// [diameter] 与 `MiSearchBarMetrics.barHeight` 同值（44.1dp，两处由测试
/// 钉住），使「搜索栏 + 取消钮」行在任何时候自动垂直居中对齐。
class MiSearchCancelMetrics {
  MiSearchCancelMetrics._();

  /// 圆钮直径（66px = 44.1dp，与 [barHeight] 同值）。
  static const double diameter = 44.1;

  /// 搜索栏右缘 → 圆钮左缘（15px ≈ 10.0dp）。
  static const double barGap = 10.0;

  /// 圆钮右缘距屏幕右缘（度量 0 —— 见类文档的闭合算式）。
  static const double trailingInset = 0.0;

  /// 叉号墨盒边长（26×25px，取方 17.0dp）。
  static const double glyphSize = 17.0;

  /// 叉号笔画宽（45° 水平弦 4px → 正交 ≈ 2.83px ≈ 1.9dp）。
  static const double glyphStroke = 1.9;

  /// 按压反馈淡入时长（推导：沿用返回圆钮度量 420ms，同一套按压语言）。
  ///
  /// 同源转发自 [MiMotionTokens]（统一动效配置），新代码请直接取 token。
  static const int pressFadeInMs = MiMotionTokens.pressFadeInMs;

  /// 按压反馈淡出时长（推导：同上，度量 300ms）。
  static const int pressFadeOutMs = MiMotionTokens.pressFadeOutMs;
}
