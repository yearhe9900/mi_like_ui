import 'package:flutter/animation.dart';

import '../../../theme/motion_tokens.dart';

/// `MiSlider` 的几何 / 动效规格。
///
/// 取值口径三分（与 `MiSwitchMetrics` 同构）：
///
///  * **推导值（本库无滑条样张）**：[trackHeight] / [thumbSize] /
///    [hitHeight] / [keyboardSteps] / [keyPointSize] —— 按 Material 3 同档
///    细轨滑条 + 本库度量体系推导；
///  * **参考实现值（对齐 flutter_miuix `MiuixSlider` / 上游 Kotlin）**：
///    [thumbScaleActive]（`thumbScaleActive` = 1.127）、[magnetThreshold]
///    （`magnetThreshold` = 0.02）、[settle]（上游
///    `spring(dampingRatio = 0.96, stiffness = 322)`，按 Folme 口径换算
///    response ≈ 0.35s，二者等价）；本库无素材可量，素材到位后按实机复核；
///  * **同源转发**：[scaleMs] / [scaleCurve] 取全库按压档
///    （[MiMotionTokens.pressMs] / [MiMotionTokens.pressCurve]）—— 按压
///    放大沿用同一套「按压语言」，不另造时长。
///
/// 配色见 `theme/slider_tokens.dart`（白钮 / 关键点）与
/// `MiTransparencyTokens.switchTrackOffFor`（非活动轨道）。
class MiSliderMetrics {
  MiSliderMetrics._();

  /// 轨道高 / 拇指直径 / 命中高。
  static const double trackHeight = 4;
  static const double thumbSize = 20;
  static const double hitHeight = 32;

  /// 键盘步长的分母（推导：一格 = 全程 1/20）。
  static const double keyboardSteps = 20;

  /// 关键点直径（**推导**）：轨道高的 1.2 倍 —— 直径 4.8 对 4 高的轨道上下
  /// 各露头 0.4dp，既能看出「这里有刻度」，又不会长成纽扣。
  static const double keyPointSize = 4.8;

  /// 拇指在**按下 / 拖拽 / 悬停于拇指上**时的放大倍数（**参考实现值**：
  /// flutter_miuix `MiuixSliderDefaults.thumbScaleActive` = 1.127，与上游
  /// Kotlin `ThumbScaleAnimationSpec` 视觉一致）。
  static const double thumbScaleActive = 1.127;

  /// 放大过渡（**同源转发**全库按压档）。
  static const int scaleMs = MiMotionTokens.pressMs;
  static const Curve scaleCurve = MiMotionTokens.pressCurve;

  /// 磁性吸附阈值（**参考实现值**）：拖到距关键点小于「全程 2%」即吸过去，
  /// 与上游 `MiuixSlider.magnetThreshold` 默认值一致。
  static const double magnetThreshold = 0.02;

  /// 点击跳转 / 外部值变更后的收敛弹簧（**参考实现值**，见类文档换算式）：
  /// 阻尼比 0.96（近乎临界阻尼，只留一丝回弹感）。
  static final SpringDescription settle =
      miSpring(damping: 0.96, response: 0.35);
}
