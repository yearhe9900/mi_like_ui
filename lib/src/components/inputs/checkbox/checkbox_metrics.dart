import 'package:flutter/animation.dart';

import '../../../theme/motion_tokens.dart';

/// `MiCheckbox` 的几何 / 动效规格。
///
/// **来源说明**：本库**没有复选框实机素材**（参考素材是主题商店截图，不含
/// 表单控件）。下列数值取自 `flutter_miuix` 的 `MiuixCheckboxDefaults` 与
/// `_CheckboxPainter`（其源自 HyperOS 组件规格），属「参考实现值」，不是
/// 本库逐像素度量；素材到位后应复核并在此改写标注。
///
/// 取值口径：
///  * 圆底 ⌀26、勾号笔画 = 直径 × [checkStrokeRatio]（26 → 2.34dp）；
///  * 勾号路径画在 23×23 的**视口坐标系**里（[checkViewport]），按实际
///    直径等比映射 —— 改直径不用重排路径点；
///  * `trim` 是「沿勾号路径画到哪」的区间：收起态 `0.1…0.1`（长度为零，
///    看不到），展开态 `0.186…0.803` —— 勾号从中间长出、两端同时延伸，
///    这是源实现的手感，比「从头画到尾」更像「一笔划上」；
///  * 半选态 = 三个路径点向画布中心 y 收拢，得到一条水平横杠；横杠本身
///    沿用同一套 trim 区间，所以三态之间是连续变形，没有跳变；
///  * 三条独立时长（勾号淡入 150 / trim 300 / 半选变形 200，曲线
///    `Curves.fastOutSlowIn`）—— 淡入比 trim 快，勾号「先显形再划完」；
///  * 按压沿用本库统一按压语言（叠色，见 [pressMs] 转发 [MiMotionTokens]），
///    **不引入缩放**：源实现是 sink（缩到 0.85），本库按钮 / 弹框 / 列表行
///    的按压一律是叠色，复选框跟本库走，避免同一屏出现两种按压手感。
class MiCheckboxMetrics {
  MiCheckboxMetrics._();

  /// 圆底直径（参考实现值）。
  static const double size = 26;

  /// 勾号绘制视口边长（路径点坐标的基准）。
  static const double checkViewport = 23;

  /// 勾号三个控制点（视口坐标）：起点 → 折点 → 终点。
  static const Offset checkStart = Offset(5, 9.4);
  static const Offset checkMiddle = Offset(10.3, 14.9);
  static const Offset checkEnd = Offset(17.9, 5.1);

  /// 勾号笔画宽 = 直径 × 本比例（圆头 / 圆角连接）。
  static const double checkStrokeRatio = 0.09;

  /// trim 区间：收起态（首尾同值 = 零长度）。
  static const double trimCollapsed = 0.1;

  /// trim 区间：展开态的起点 / 终点。
  static const double trimStart = 0.186;
  static const double trimEnd = 0.803;

  /// 勾号淡入时长（ms）。
  static const int alphaMs = 150;

  /// 勾号 trim 时长（ms）。
  static const int trimMs = 300;

  /// 半选横杠变形时长（ms）。
  static const int indetMs = 200;

  /// 三态过渡曲线（源实现 `Curves.fastOutSlowIn`）。
  static const Curve transition = Curves.fastOutSlowIn;

  /// 按压叠色过渡时长 —— 转发 [MiMotionTokens.pressMs]（本库统一按压语言）。
  static const int pressMs = MiMotionTokens.pressMs;

  /// 按压叠色曲线 —— 转发 [MiMotionTokens.pressCurve]。
  static const Curve pressCurve = MiMotionTokens.pressCurve;

  /// 命中区边长 = 圆底直径（源实现只包住圆底；行级命中由宿主行提供）。
  static const double hitSize = size;
}
