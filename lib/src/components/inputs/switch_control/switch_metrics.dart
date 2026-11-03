import 'package:flutter/animation.dart';

import '../../../theme/dimens.dart';
import '../../../theme/motion_tokens.dart';

/// `MiSwitch` 的几何 / 动效规格。
///
/// 取值口径（几何 / 弹簧为**推导值**，交互放大与拖拽阈值为**参考实现值**）：
///  * 轨道 52×32、钮 ⌀26（内缩 3，行程 20）：通行开关档
///    （Material 3 track 52×32 同尺寸；HyperOS 开关观感接近），stadium 端头
///    走 [MiSquircleBorder] 的真半圆口径；
///  * 吸附弹簧 [snap]：Folme 口径 `miSpring(damping: 1.0, response: 0.35)`
///    —— 临界阻尼、无过冲，与「开关啪一下到位」的观感一致（推导；
///    `MiMotionTokens.miSpring` 换算）；
///  * 按压 / 拖拽放大 [knobScaleActive]、拖拽阈值 [dragSwitchThreshold]：
///    **参考实现值**（对齐 flutter_miuix `MiuixSwitch` / 上游 Kotlin），
///    本库无开关素材可量 —— 素材到位后按实机复核；
///  * 禁用透明 0.38（Material 禁用档通行值）；
///  * 轨道色见 `MiTransparencyTokens.switchTrackOffFor`（关闭档 @12% 推导）
///    与 `MiColors.accent`（开启档 = 全库强调色，明暗同色）。
///
/// 素材到位后应复核：轨道 / 钮尺寸、吸附弹簧参数、放大倍数与拖拽阈值、
/// 是否有扩散涟漪（本版无涟漪 —— 无素材不发明）。
class MiSwitchMetrics {
  MiSwitchMetrics._();

  /// 轨道宽 / 高。
  static const double trackWidth = 52;
  static const double trackHeight = 32;

  /// 钮内缩与直径（行程 = 宽 − 钮 − 2×内缩）。
  static const double knobInset = 3;
  static const double knobSize = trackHeight - 2 * knobInset; // 26
  static const double travel = trackWidth - knobSize - 2 * knobInset; // 20

  /// 吸附弹簧（Folme 口径，推导）：临界阻尼、无过冲。
  static final SpringDescription snap = miSpring(damping: 1.0, response: 0.35);

  /// 钮体在**按压 / 拖拽态**的放大倍数（**参考实现值**：flutter_miuix
  /// `MiuixSwitchDefaults.thumbScaleActive` = 1.127，与上游 Kotlin 一致；
  /// 本库无开关素材可量）。放大只作用于钮体，轨道不动。
  static const double knobScaleActive = 1.127;

  /// 放大过渡沿用全库按压档（**同源转发** [MiMotionTokens.pressMs] /
  /// [MiMotionTokens.pressCurve]）：按压语言全库统一，不另造时长。
  static const int scaleMs = MiMotionTokens.pressMs;
  static const Curve scaleCurve = MiMotionTokens.pressCurve;

  /// 拖拽切换阈值（占行程比例）：越过中点即吸附到另一端。
  /// **参考实现值**：上游判据 `|dragOffset| > 行程/2`，故取 0.5。
  static const double dragSwitchThreshold = 0.5;

  /// 禁用态整体透明（**推导**；**同源转发** [MiDimens.disabledOpacity] ——
  /// 表单控件三件共用一档，历史 API 保留以免调用点改动）。
  static const double disabledOpacity = MiDimens.disabledOpacity;
}
