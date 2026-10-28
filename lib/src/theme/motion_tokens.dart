import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// 动效令牌：跨组件复用的动效规格（弹簧 / 时长 / 曲线）的统一来源。
///
/// 与 [MiTransparencyTokens] 同构 —— 透明参数只定义在那里，跨组件的动效
/// 数值只定义在这里；组件私有动效留在各 `*_metrics.dart`（如玻璃栏飞行 /
/// 果冻形变、顶栏搜索转场），实现层不许裸写时长 / 弹簧字面量，由
/// `test/motion_config_test.dart` 扫描约束。
///
/// **语义命名**：名字说的是「什么时候用」，不是「数值是多少」——新组件
/// 复用同一套反馈时引用同一个名字，而不是抄一遍数字。
///
/// 已迁走的旧常量（`MiTopBarMetrics.pressFadeInMs` 等）以**同源转发**保留，
/// 调用点零改动；新代码请直接取本类。
class MiMotionTokens {
  MiMotionTokens._();

  // ── 按压反馈（全库统一的「按压语言」）─────────────────────────────────

  /// 按压叠色淡入 420ms（**度量**：顶栏返回圆钮 0.4s 内 0 → 25% → 83% →
  /// 100% 的 easeOut 形；原始记录见 `MiTopBarMetrics.pressFadeInMs`）。
  /// 搜索取消钮推导沿用同值 —— 两者构成同一套按压语言，改一处须同步另一处。
  static const int pressFadeInMs = 420;

  /// 按压叠色淡出 300ms（**度量**：松开后 0.3s 内消失，8.4s 帧 13 级 →
  /// 8.7s 帧 0 级）。
  static const int pressFadeOutMs = 300;

  /// 按压反馈曲线（度量序列 0 → 25% → 83% → 100% 的 easeOut 形拟合）。
  static const Curve pressFadeCurve = Curves.easeOut;

  /// 按压叠色过渡 150ms（**度量**：弹框按钮 24.31fps 逐帧进度 47/80/96/100%
  /// 拟合 150ms easeOutQuad，mean|Δ| = 0.02；原始记录见
  /// `MiDialogMetrics.pressDurationMs`）。叠色配方（黑 / 白 @0.12，只压填充
  /// 不碰标签）见 [MiTransparencyTokens.dialogPressAlpha]。
  static const int pressMs = 150;

  /// 按压叠色曲线（同上拟合）。
  static const Curve pressCurve = Curves.easeOutQuad;

  // ── 弹出面板弹簧（素材拟合，拨号键盘唤起录屏）────────────────────────

  /// 展开弹簧：ζ ≈ 0.807、过冲 ~1.4%、~0.53s 收敛（欠阻尼；过冲比
  /// exp(−πζ/√(1−ζ²)) = 0.013 与峰值时刻 π/ωd = 0.33s 反解 ζ ≈ 0.81、
  /// ωn ≈ 16.2 → k = ωn² ≈ 263 取整 260，c = 2ζωn ≈ 26.2 取 26）。
  /// Folme 口径换算（见 [miSpring]）：≈ damping 0.81 / response 0.39s。
  static const SpringDescription panelExpand = SpringDescription(
    mass: 1,
    stiffness: 260,
    damping: 26,
  );

  /// 收回弹簧：临界阻尼（ζ ≈ 1，无过冲 —— 素材收回帧无回摆），~0.19s 缩回
  /// （慢速素材 0.041 / 0.082s 处剩余进度 0.77 / 0.45 与 e^{−ωt}(1+ωt)、
  /// ω = √530 ≈ 23 吻合；c = 2√530 ≈ 46.3 取 46）。
  static const SpringDescription panelCollapse = SpringDescription(
    mass: 1,
    stiffness: 530,
    damping: 46,
  );
}

/// Folme / HyperOS 口径的弹簧换算：阻尼比 + 响应时间 → Flutter 弹簧。
///
/// 设计侧规格习惯说「阻尼 0.85、响应 0.4s」，Flutter 直说 stiffness /
/// damping；本函数按 `stiffness = (2π/response)²`、`mass = 1` 换算（Folme
/// 官方口径；思路参考 flutter_miuix `theme/miuix_motion.dart`（Apache-2.0），
/// 按本库度量驱动风格重写）。已有度量值（如 [MiMotionTokens.panelExpand]）
/// 不强迁 —— 它们是素材拟合的真源，两边注释互写换算关系即可。
SpringDescription miSpring({
  required double damping,
  required double response,
}) {
  final stiffness = math.pow(2.0 * math.pi / response, 2).toDouble();
  return SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: stiffness,
    ratio: damping,
  );
}
