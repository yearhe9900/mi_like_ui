import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../dialog/dialog_metrics.dart';

/// [MiPullUpPanel] 的几何与动效规格。
///
/// 参考素材：HyperOS 拨号键盘唤起录屏两段 —— ①1220×2656 暗色、②0.25×
/// 慢速 884×1920 浅色（慢速后有效帧率仍 24fps，展开 ~0.54s / 收回 ~0.19s，
/// 两段结论互相印证）。统一换算 `dp = px × 393 / 素材宽`，动画逐帧量取
///（bbox 帧间差分 + 逐点透明度反解）。**度量**与**推导/拟合**逐项标注：
///
///  * **面板**：宽 = 屏宽 − 2×24（左右 24.2 / 23.8 取均）、圆角 33.0（五点
///    圆拟合残差 <0.3dp）、底距屏底 90.0（底缘实测 y=766dp）、表面
///    #2C2C2C 暗 / #FFFFFF 浅（两段素材分别实测）、**带投影**（浅色下缘外
///    压暗 14 级 / 上缘仅 3 级 → 黑 @0.12、blur 14、下偏 4；暗色黑底上不可
///    分辨，推导同值）、无压暗遮罩（面板外页底像素不变）；
///  * **唤起动画**（度量拟合）：面板在 ~0.53s 内从触发按钮位置**等比放大**
///    到终态，~0.33s 处过冲 ~1.3% 后回落 —— 典型欠阻尼弹簧；按过冲比
///    `exp(−πζ/√(1−ζ²)) = 0.013` 与峰值时刻 `π/ωd = 0.33s` 反解
///    ζ ≈ 0.81、ωn ≈ 16.2，取 stiffness 260 / damping 26 / mass 1
///    （ζ = 0.807，过冲 1.4%）。**慢速素材复核：展开全程不淡入**
///    （逐点透明度反解 q≡1），淡出只发生在收回；
///  * **轨迹**（逐帧拟合，残差 ±10dp 内）：等比缩放，但缩放原点不是按钮
///    圆心而是**移动的原点** —— 横向原点恒定在「终态右缘 − 20.9dp」（素材
///    全帧拟合恒定，±1dp），纵向原点由按钮圆心随进度 lerp 到「终态底缘 −
///    90dp」（这一点正是素材里面板向上长的观感来源：中段比「绕按钮中心
///    放大」高 ~34dp）。拟合采样：t=0.22/0.48/0.86 三帧位置误差 ≤11dp；
///  * **收回**（拟合，慢速素材复核）：同一原点路径的**反向弹簧**（临界阻尼
///    stiffness 530 / damping 46，~0.19s 缩回按钮）+ **淡出 = 回收进度**
///    （两段反解：慢速 42ms 处几何 0.82 / 透明 0.84，暗色 41ms 处 0.72/0.72
///    —— 不透明度与几何同弹簧）；收口后交宿主移除；
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

  /// 投影模糊半径 14.0（度量拟合：浅色素材下缘外压暗剖面 14 级@+2dp →
  /// 0@+14dp，对上 σ≈7 即 BoxShadow blurRadius 14 的边缘衰减）。
  static const double shadowBlurRadius = 14.0;

  /// 投影下偏 4.0（度量拟合：下缘压暗 14 级 vs 上缘仅 ~3 级的不对称量）。
  static const double shadowOffsetY = 4.0;

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

  /// 缩放原点距**终态右缘** 20.9dp（拟合：素材全帧横向原点恒为 348.3 =
  /// 终态右缘 369.2 − 20.9，±1dp）。
  static const double originOffsetX = 20.9;

  /// 横向原点抵达终值的进度阈值 0.20（拟合盲区推导：素材首个可见帧已在
  /// t≈0.22 且原点恒定，之前原点不可见 —— 取 t∈[0,0.2] 从按钮圆心线性靠到
  /// 终值，让面板第一帧就「从按钮里长出来」，任意位置的按钮都成立）。
  static const double originXArrivalT = 0.20;

  /// 缩放原点距**终态底缘** = [bottomGap]（拟合 89.4 ≈ 度量 90）：纵向原点
  /// 终点 = 屏底 − 2×[bottomGap]。
  //（originOffsetY 复用 bottomGap，不另立常量。）

  /// 收回弹簧刚度 530（拟合：临界阻尼 ζ≈1，0.041/0.082s 处剩余进度
  /// 0.77/0.45 与 e^{-ωt}(1+ωt)（ω=√530≈23）吻合，总时长 ~0.19s）。
  static const double closeStiffness = 530;

  /// 收回弹簧阻尼 46（临界阻尼 2√530 ≈ 46.3，无过冲 —— 素材收回帧无回摆）。
  static const double closeDamping = 46;

  /// 动画上界 1.2（推导：`AnimationController` 会把值钳在 [lower, upper] 内，
  /// 不放开上界会把 ~1.4% 的弹簧过冲抹平；1.2 给过冲留足余量）。
  static const double springUpperBound = 1.2;
}
