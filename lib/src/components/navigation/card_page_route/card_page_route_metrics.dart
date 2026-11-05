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
/// | 转场时长                 | 410ms       | 220   | 本库压值，见下「时值」 |
///
/// ## 时值（逐帧拟合）
///
/// 逐帧量新页左缘（px）：`1101 807 536 362 214 120 65 23 9 7 3 2`，
/// 以「曲线族 × 时长 × 起手偏移」网格搜索拟合，`easeOutCubic` + 400ms
/// 的平均残差 **1.6dp**（次优 `easeOutQuart` + 500ms 为 2.1dp）。
///
/// 本库取 **220ms**（手感推导值：先压到 300ms，再压到 220ms）：拟合最优的
/// 400ms 与素材同为「大屏慢慢推」，整页滑完一个屏宽要 0.4s，连同键盘升起
/// 读起来是「点了以后等了一下才到位」。曲线不变（`easeOutCubic` 的形状是
/// 实测的，压缩时长不改读感 —— 前段更快、落位更早），并使转场短于系统
/// 键盘动画，让「转场 + 键盘」并行结束、不额外串联等待。
///
/// ## 退出方向（推导值）
///
/// 参考素材只录到推入。`PageRoute` 默认让 `reverseTransitionDuration` 等于
/// [durationMs]，且 `animation.value` 反向走 —— 直接反向播 [motion] 会把
/// 「快起慢停」翻成「慢起快停」：旧 300ms 档退出前 120ms 只回退 7%、前
/// 180ms 才 20%，读作「点返回没反应，然后突然弹回」。本库给退出单独
/// [reverseDurationMs] 与 [exitMotion]，按
/// `1 - exitMotion.transform(1 - progress)` 求位置，让回退量同样是快起慢停。
/// 压暗层在退出时也改为跟随该视觉进度，不留在下层慢慢褪。
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

  /// 进入（push）时长（见类文档「时值」：实测拟合 400ms，本库取 220ms）。
  static const int durationMs = 220;

  /// 退出（pop）时长 **180ms**（手感推导值）。
  ///
  /// 比进入略快：退出没有键盘升起并行，且返回手势的响应延迟更敏感。
  static const int reverseDurationMs = 180;

  /// 位置曲线：`Curves.easeOutCubic`（Cubic(0.215, 0.61, 0.355, 1.0)）。
  static const Curve motion = Cubic(0.215, 0.61, 0.355, 1.0);

  /// 退出曲线：作用于「退出已过时间」的 `easeOutCubic`（推导值）。
  ///
  /// 位置 = `1 - exitMotion.transform(e)`，e = 退出已过时间比例；形状与
  /// [motion] 同族，但作用在反方向上，避免反向播 [motion] 的长尾。
  static const Curve exitMotion = Curves.easeOutCubic;

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

  /// 桌面档视觉时长 **220ms**，与 [durationMs] 同值。
  ///
  /// 旧实现不改 [durationMs]（`transitionDuration` 在路由构造时定死、拿不到
  /// 上下文里的窗口宽），而把视觉压进前 73%（`Interval(0, 0.73)`）：视觉
  /// 落定后路由仍空转 80ms，pop 时这 80ms 表现为「画面完全不动」。现在两者
  /// 对齐，[wideVisualFraction] = 1，转场全程都有视觉进展。
  static const int wideDurationMs = 220;

  /// [durationMs] 中视觉完成的比例（= 1，见 [wideDurationMs]）。
  static const double wideVisualFraction = wideDurationMs / durationMs;

  /// 桌面档新页的纵向位移 **4dp**（自下而上轻微抬起；不横移、不缩放）。
  static const double wideRiseDp = 4;

  /// 桌面档新页前缘圆角 **16**（同 [MiDialogMetrics.wideCardRadius] 的通行
  /// 档；转场结束归零）。
  static const double wideCornerRadius = 16;

  /// 是否用桌面档转场（按**窗口宽**判定，与 [MiBreakpoints.desktop] 同值）。
  static bool isWide(double windowWidth) => windowWidth >= 1024;
}
