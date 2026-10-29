import 'package:flutter/animation.dart';

import '../../../theme/motion_tokens.dart';

/// `MiSwitch` 的几何 / 动效规格（**全部推导值**，无实机素材）。
///
/// 取值口径：
///  * 轨道 52×32、钮 ⌀26（内缩 3，行程 20）：通行开关档
///    （Material 3 track 52×32 同尺寸；HyperOS 开关观感接近），stadium 端头
///    走 [MiSquircleBorder] 的真半圆口径；
///  * 吸附弹簧 [snap]：Folme 口径 `miSpring(damping: 1.0, response: 0.35)`
///    —— 临界阻尼、无过冲，与「开关啪一下到位」的观感一致（推导；
///    `MiMotionTokens.miSpring` 换算）；
///  * 禁用透明 0.38（Material 禁用档通行值）；
///  * 轨道色见 `MiTransparencyTokens.switchTrackOffFor`（关闭档 @12% 推导）
///    与 `MiColors.accent`（开启档 = 全库强调色，明暗同色）。
///
/// 素材到位后应复核：轨道 / 钮尺寸、吸附弹簧参数、是否有扩散涟漪
///（本版无涟漪 —— 无素材不发明）。
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

  /// 禁用态整体透明（Material 禁用档通行值，推导）。
  static const double disabledOpacity = 0.38;
}
