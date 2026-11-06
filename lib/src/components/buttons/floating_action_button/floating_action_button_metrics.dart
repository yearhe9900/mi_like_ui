import 'package:flutter/animation.dart';

import '../../../theme/motion_tokens.dart';

/// [MiFloatingActionButton] 的几何 / 投影 / 动效规格。
///
/// 取值口径：
///
///  * **参考实现值**：[size]（上游 `MiuixFloatingActionButtonDefaults`
///    `minWidth/minHeight = 60`）、[shadowBlurRadius] / [shadowOffset]
///    （上游 `shadowElevation = 4` → blur 4、下偏 elevation/2 = 2）——
///    本库**没有独立浮动操作按钮的素材**；
///  * **不与导航栏那颗圆钮互相套用**：素材里唯一出现的圆钮是底栏槽位里的
///    ⌀55.4（= `MiGlassNavMetrics.fabDiameter`，**无投影**），它是「栏体
///    的一部分」，语义、尺寸与悬浮在内容之上的通用 FAB 不是一回事 ——
///    导航栏改用本组件时显式传 `showShadow: false`，像素不变；
///  * 投影色不新造 alpha：走 `MiTransparencyTokens.panelShadow`
///    （黑 @0.12，与悬浮工具栏 / 弹出面板同一投影档 —— 上游是 0.15，本库
///    统一在 0.12 这一档，不为新件另开 alpha）；
///  * 按压过渡 [pressMs] / [pressCurve] **同源转发** [MiMotionTokens]
///    （全库按压语言：150ms easeOutQuad），压色取 `dialogPressedFill`
///    （预合成单色、不引 saveLayer）。
class MiFloatingActionButtonMetrics {
  MiFloatingActionButtonMetrics._();

  /// 最小边长（**参考实现值** 60dp）：内容更小时按 60 出图，父级给更紧的
  /// 约束时以父级为准（导航栏 ⌀55.4 就是这样被父级覆盖的）。
  static const double size = 60;

  /// 投影模糊半径（**参考实现值**：上游 shadowElevation 4 → blur 4）。
  ///
  /// 实际走 `MiSquircleShadowPainter`（`MaskFilter.blur`，σ = blur/2），
  /// 与悬浮工具栏同一套画法 —— 不用 `BoxShadow` 的 elevation 语义，
  /// 放进含磨砂的页面也不引 saveLayer。
  static const double shadowBlurRadius = 4;

  /// 投影偏移（**参考实现值**：上游 elevation/2 = 2dp 向下）。
  static const Offset shadowOffset = Offset(0, 2);

  /// 按压过渡（**同源转发** [MiMotionTokens.pressMs] / [MiMotionTokens.pressCurve]）。
  static const int pressMs = MiMotionTokens.pressMs;
  static const Curve pressCurve = MiMotionTokens.pressCurve;
}
