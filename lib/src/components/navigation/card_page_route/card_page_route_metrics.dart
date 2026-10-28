import 'package:flutter/animation.dart';

/// [MiCardPageRoute] 的几何 / 时值规格（设计度量，393dp 设计宽）。
///
/// 规格取自搜索页推入参考素材（1220×2656 @24.31fps），换算系数
/// s = 1220 / 393 = 3.104 px/dp：
///
/// | 项目                     | 素材        | dp    | 说明 |
/// |--------------------------|-------------|-------|------|
/// | 新页起手位置             | x = 1220    | = 屏宽 | 整页从右缘外滑入，无纵向位移 |
/// | 新页前缘圆角             | R = 190px   | 61.2  | 逐帧拟合四分之一圆，残差 ≤ 2px |
/// | 下层页左移（终值）       | 0.25 × 屏宽 | —     | 见下「视差」 |
/// | 转场时长                 | 410ms       | 300   | 见下「时值」 |
///
/// ## 时值（逐帧拟合）
///
/// 逐帧量新页左缘（px）：`1101 807 536 362 214 120 65 23 9 7 3 2`，
/// 以「曲线族 × 时长 × 起手偏移」网格搜索拟合，`easeOutCubic` + 400ms
/// 的平均残差 **1.6dp**（次优 `easeOutQuart` + 500ms 为 2.1dp）。
///
/// 本库取 **300ms**：拟合最优的 400ms 与素材同为「大屏慢慢推」，整页滑完
/// 一个屏宽要 0.4s，连同键盘升起读起来是「点了以后等了一下才到位」。曲线
/// 不变（`easeOutCubic` 的形状是实测的，压缩时长不改读感 —— 前段更快、
/// 落位更早），只把尾巴截短 100ms。
///
/// ## 视差（下层页）
///
/// 模板匹配量到下层页水平位移：转场进度 0.09 / 0.35 时为 −30px / −102px，
/// 即 ≈ −0.25 × 屏宽 × 进度。**量到的是水平位移本身**；「整页横向平移、
/// 不缩放」由横幅上缘 y 在全程恒为 536px 佐证（缩放会让它下移）。
///
/// ## 圆角在终点的处理（推导）
///
/// 参考实现里圆角全程恒为 190px（进度 0.998 时仍是），归位那一帧直接消失。
/// 本库保留「全程恒定」，但**归位（进度 1）时归零** —— 此时新页已铺满整屏、
/// 下层页不再绘制，缺口不会露出来，视觉与参考一致而无跳变。
class MiCardPageRouteMetrics {
  MiCardPageRouteMetrics._();

  /// 转场时长（见类文档「时值」：实测拟合 400ms，本库取 300ms）。
  static const int durationMs = 300;

  /// 位置曲线：`Curves.easeOutCubic`（Cubic(0.215, 0.61, 0.355, 1.0)）。
  static const Curve motion = Cubic(0.215, 0.61, 0.355, 1.0);

  /// 新页前缘圆角（素材 190px = 61.2dp）。
  static const double cornerRadius = 61.2;

  /// 下层页左移比例（× 屏宽；素材 −0.25，见类文档）。
  static const double parallaxFraction = 0.25;

  /// 同一次转场里，下层页压暗的最大 alpha（线性 0 → 本值）。
  ///
  /// 素材实测：下层页同位置亮度比 0.64（进度 0.35…0.70 稳定），
  /// 即黑 @0.36；按线性插值反推终值 0.55（见 [MiTransparencyTokens.pushDimAt]）。
  static const double dimAlpha = 0.55;

  // ── 宽屏档（桌面，推导值） ────────────────────────────────────────────────
  //
  // 参考素材只有手机档（上面的度量全部来自「整页从右缘滑入 + 前缘大圆角 +
  // 下层左移视差」）。桌面窗口的通行转场是「淡入 + 极小位移」（macOS /
  // Windows 推入页 / Material 历史）—— 大圆角与视差在桌面读作「两个窗口
  // 叠在一起」，不合适。以下全部是布局常量而非度量值。

  /// 桌面档视觉时长 **220ms**。
  ///
  /// 实现上不改 [durationMs]（`transitionDuration` 在路由构造时定死、拿不到
  /// 上下文里的窗口宽），而是把视觉进度压进前 [wideVisualFraction]
  /// （220/300 ≈ 0.73）：桌面档用 `Interval(0, 0.73)` 曲线，220ms 时视觉
  /// 已落定，其后的空转不影响观感。
  static const int wideDurationMs = 220;

  /// [durationMs] 中视觉完成的比例（220 / 300 ≈ 0.73）。
  static const double wideVisualFraction = wideDurationMs / durationMs;

  /// 桌面档新页的纵向位移 **4dp**（自下而上轻微抬起；不横移、不缩放）。
  static const double wideRiseDp = 4;

  /// 桌面档新页前缘圆角 **16**（同 [MiDialogMetrics.wideCardRadius] 的通行
  /// 档；转场结束归零）。
  static const double wideCornerRadius = 16;

  /// 是否用桌面档转场（按**窗口宽**判定，与 [MiBreakpoints.desktop] 同值）。
  static bool isWide(double windowWidth) => windowWidth >= 1024;
}
