import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../dialog/dialog_metrics.dart';

/// [MiPullUpPanel] 的几何与动效规格。
///
/// 参考素材：HyperOS 拨号键盘唤起录屏（1220×2656，24.3fps，明暗无对照 ——
/// 只有暗色）。统一换算 `dp = px × 393 / 1220`，动画逐帧量取（面板 bbox
/// 帧间差分）。**度量**与**推导/拟合**逐项标注：
///
///  * **面板**：宽 = 屏宽 − 2×24（左右 24.2 / 23.8 取均）、圆角 33.0（五点
///    圆拟合残差 <0.3dp）、底距屏底 90.0（底缘实测 y=766dp）、表面 #2C2C2C 不透明、无压暗遮罩
///    （面板外页底像素不变）、无投影；
///  * **唤起动画**（度量拟合）：面板在 ~0.53s 内从触发按钮位置**等比放大**
///    到终态，~0.33s 处过冲 ~1.3% 后回落 —— 典型欠阻尼弹簧；按过冲比
///    `exp(−πζ/√(1−ζ²)) = 0.013` 与峰值时刻 `π/ωd = 0.33s` 反解
///    ζ ≈ 0.81、ωn ≈ 16.2，取 stiffness 260 / damping 26 / mass 1
///    （ζ = 0.807，过冲 1.4%）；
///  * **轨迹**（推导近似）：素材逐帧轨迹是「等比缩放 + 位移」的合成（中段
///    存在 ±30dp 级的非等比残差，系统动画同时在移动锚点）。本库取语义清晰
///    的**以触发按钮圆心为原点的等比放大** —— 首帧/稳态与素材一致，中段
///    残差不影响观感；
///  * **起点**：按钮直径 54.1（度量）；按钮圆心 (327.0, 803.7)（度量），
///    换算成距右缘 66.0 / 距屏底 52.3 的默认锚点（推导：便于任意屏宽复用）。
class MiPullUpPanelMetrics {
  MiPullUpPanelMetrics._();

  // ── 面板几何 ───────────────────────────────────────────────────────────

  /// 面板左右内缩 24.0（度量 24.2 / 23.8 取均；素材两帧内排版抖动 ±0.4dp）。
  static const double panelInset = 24.0;

  /// 面板圆角 33.0（度量：左缘 x(y) 五点圆拟合 R = 32.9…33.1，残差 <0.3dp）。
  static const double panelRadius = 33.0;

  /// 面板底缘距屏底 90.0（度量：静止帧底缘 y = 766dp，856 − 766，正好落在
  /// 参考机底部导航栏之上）。真机上再与安全区取大兜底。
  static const double bottomGap = 90.0;

  /// 面板顶最小让位 24.0（推导：与 [panelInset] 对称，钳制可用高的上界）。
  static const double topMinInset = 24.0;

  /// 宽屏档（容器宽 ≥ 1024）面板宽上限 440（**推导值**：素材只有手机档，
  /// 沿用 `MiDialogMetrics` 宽屏「居中窄卡」的限宽口径，避免 1366 宽上出
  /// 一块 1318dp 的横条）。
  static const double wideMaxWidth = 440;

  /// 面板实际宽：手机档 = 屏宽 − 2×[panelInset]；宽屏档再 clamp 到
  /// [wideMaxWidth]。
  static double panelWidthFor(double screenWidth) {
    final raw = screenWidth - 2 * panelInset;
    return MiDialogMetrics.isWide(screenWidth)
        ? math.min(wideMaxWidth, raw)
        : raw;
  }

  /// 面板高上限：屏高 − 顶让位（安全区兜底）− [bottomGap]。
  static double maxHeightFor(double screenHeight, double safeTop) =>
      screenHeight - math.max(topMinInset, safeTop) - bottomGap;

  // ── 触发点（唤起锚点）─────────────────────────────────────────────────

  /// 触发按钮直径 54.1（度量：绿色圆钮 54.1×54.1）—— 起点尺寸与默认缩放
  /// 分母。
  static const double triggerDiameter = 54.1;

  /// 默认锚点距屏右缘 66.0（推导：素材按钮圆心 x = 327.0 = 393 − 66.0）。
  static const double anchorRightMargin = 66.0;

  /// 默认锚点距屏底 52.3（推导：素材按钮圆心 y = 803.7 = 856 − 52.3）。
  static const double anchorBottomMargin = 52.3;

  /// 默认锚点（触发按钮圆心）：距右缘 [anchorRightMargin]、距屏底
  /// [anchorBottomMargin]。调用方知道真实按钮位置时应传全局坐标覆盖它。
  static Offset defaultAnchorFor(double screenWidth, double screenHeight) =>
      Offset(screenWidth - anchorRightMargin, screenHeight - anchorBottomMargin);

  /// 起点缩放 = 按钮直径 / 面板终态宽。
  static double scaleFor(double collapsedSize, double panelWidth) =>
      collapsedSize / panelWidth;

  // ── 唤起动效（弹簧，度量拟合）─────────────────────────────────────────

  /// 弹簧刚度 260（拟合：ζ ≈ 0.81、ωn ≈ 16.2 → k = ωn² ≈ 263，取整）。
  static const double springStiffness = 260;

  /// 弹簧阻尼 26（拟合：c = 2ζωn ≈ 26.2；ζ = c / 2√(km) = 0.807，过冲 1.4%）。
  static const double springDamping = 26;

  /// 弹簧质量 1（单位质量归一）。
  static const double springMass = 1;

  /// 名义收口时长 600ms（拟合稳态 ~0.53s + 余量；`AnimationController` 只拿
  /// 它做兜底，实际由 `SpringSimulation` 驱动到收敛）。
  static const int springSettleMs = 600;

  /// 动画上界 1.2（推导：`AnimationController` 会把值钳在 [lower, upper] 内，
  /// 不放开上界会把 ~1.4% 的弹簧过冲抹平；1.2 给过冲留足余量）。
  static const double springUpperBound = 1.2;
}
