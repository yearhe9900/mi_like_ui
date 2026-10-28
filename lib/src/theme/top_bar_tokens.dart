import 'package:flutter/painting.dart';

import 'colors.dart';
import 'gradient_blur_tokens.dart';
import 'theme_mode.dart';
import 'transparency_tokens.dart';

/// 顶部导航栏 [MiTopBar] 的**材质**（磨砂 + 叠色）与配色 token。
///
/// 材质由两层组成，两层都逐帧度量：
///  1. **磨砂**：backdrop 高斯模糊，σ 沿 y 递减（栏顶 5.37dp → 119dp 归零），
///     以分段定 σ 的阶梯实现（见 [MiTopBarPalette.blurBands]）；
///  2. **叠色**：[MiTopBarPalette.scrimGradient] —— 顶部最深、向下渐隐。
///
/// ## 磨砂（本轮新增，度量）
///
/// Source: 1220×2656 亮色「我的」页素材（24.26 fps，采样密度
/// s = 393/1220 = 0.32213 dp/px）。**顶栏内不内嵌任何组件**，
/// 因此可以纯粹观察材质本身：
///
///  * 头像（圆形照片，直径 87dp）随滚动进入栏内后边缘被抹开，而它在栏外
///    时边缘只有 1.4px 宽 —— 这是 backdrop 模糊的直接证据；
///  * 模糊强度沿 y **向下衰减**：以头像竖直边缘（水平剖面，**不受纵向
///    滚动运动模糊影响**）的 10-90% 宽度换算
///    （高斯阶跃 w₁₀₋₉₀ ≈ 2.563σ），并用「同行锐利内容 + 频谱比
///    log(S₁/S₀) = −2π²σ²f²」两种独立方法交叉验证：
///
///    | y (dp) | 有效 σ (dp) | 说明 |
///    |--------|-------------|------|
///    | 0…35   | 5.30…5.37   | 平台段 → 即实现用的 σ |
///    | 50.1   | 4.96        | 开始衰减 |
///    | 67.5   | 4.34        | |
///    | 90.0   | 1.85        | |
///    | 102.9  | 0.76        | |
///    | 108.7  | 0.27        | |
///    | ≥119   | 0           | 完全锐利 |
///
/// 模糊是**连续渐隐**而非硬边：平台段的 10-90 宽度（42.7px）比中段
/// （67.5dp 处 34.5px）宽 —— 这正是「模糊结果按 m 与原内容混合」的
/// 特征（m<1 时台阶跳变落在 10-90 带内，宽度收敛到 2.08σ）。
///
/// ⚠️ 实现上**做不到**原生的"连续衰减"：Flutter 的 backdrop 模糊只支持
/// 定 σ，而用半透明遮罩（`ShaderMask` / `Opacity`）去按位置削弱它会让
/// backdrop 失效（详见 [MiTopBarPalette.blurBands]）。故用 8 段定 σ 阶梯
/// 近似，段高 ≤ 17dp、相邻 σ 比 ≤ 1.5。
///
/// ## 叠色
///
/// **亮色配方（本轮度量）**：叠色 = **页底色 #F3F3F3**，α 由 0.650（栏顶）
/// 平滑衰减到 0（122.4dp）。依据是两处平坦区的交叉验证 ——
///  * 同帧页底 #F3F3F3(243) 在栏内**全程不变**（243→243）：排除白色叠色；
///  * 白色卡片填充 255 在栏内 80dp 处读 **249** = 255 − (255−243)×0.50，
///    而同帧栏外读 255 —— 只有「叠色 = 页底色、α(80dp) ≈ 0.50」能同时
///    解释这两点（白色叠色会把页底抬亮，纯黑叠色会把卡片压到 ~243）。
///  α(y) 曲线取自 1-D 逐行反卷积（同行锐利剖面高斯模糊 ↔ 带内剖面做
///  最小二乘），再经保序回归（PAVA）单调平滑；下方 stop 逐行注明 (y, α)。
///
/// **深色配方（沿用既有度量）**：取自 1220×2656 HyperOS 设置「显示与亮度」
/// 页素材 —— 该页栏顶是**不透明黑**：沿蓝卡平坦填充做纵向取样得透射比
/// 0.01…1.00（y = 64.4…128.9dp）。平坦色块在模糊下亮度不变，故该透射比
/// 只能来自叠色，α 顶部 ≈ 1.0。深浅两页的顶部 α 不同（1.0 vs 0.65）是
/// **两页各自的度量结果**，不做归一：磨砂材质共用，叠色各随其参考页。
///
/// 磨砂阶梯的一段：`[top, top + height)` 区间内用定 σ 的 backdrop 模糊。
///
/// 定义已搬到 [MiTopBarBlurBand] 的**权威位置** `gradient_blur_tokens.dart`
/// （这层渐进模糊属于内容区、不属于顶栏）；此处 export 保持旧引用可用。
export 'gradient_blur_tokens.dart'
    show MiTopBarBlurBand, MiGradientBlurProfile, MiHeaderBlurProfile;

/// 墨色沿用框架前景色 [MiColors.foreground]（度量标题笔画内部 246）；
/// 返回圆钮按压反馈为**白 @9.4%**（叠纯黑底度量 24 级，圆盘内均匀），
/// 浅色配方取同 alpha 的反相黑 @9.4%。
class MiTopBarPalette {  const MiTopBarPalette({
    required this.scrimGradient,
    required this.ink,
    required this.pressHighlight,
    this.scrimOpaqueBottom = 0,
  });

  /// 顶栏叠色：纵向渐变，顶部最深 → 各自度量处完全透明（渐变坐标按
  /// 遮罩盒高 [MiTopBarMetrics.scrimHeight] = 128.9dp 归一化）。
  final Gradient scrimGradient;

  /// 标题墨色 / 返回箭头墨色。
  final Color ink;

  /// 返回圆钮按压反馈圆盘底色（半径 = 圆钮半径，度量平坦无角向变化）。
  final Color pressHighlight;

  /// 叠色**完全不透明**段的下沿（dp，距栏顶）。其上区域的模糊结果被 100%
  /// 遮住 —— 渲染时可以直接跳过那几段 backdrop 模糊（零视觉差异的省帧优化，
  /// 见 [MiTopBarBlurBand] 与 `MiTopBar.build`）。
  ///
  /// * 深色配方：scrim 顶部 α = 1.000（纯黑）直到 63.6dp（stops 0.4934 ×
  ///   128.9）→ **63.6**；
  /// * 浅色配方：顶部 α = 0.650，全段半透明 → **0**（一段都不能省）。
  final double scrimOpaqueBottom;

  // ── 磨砂材质（明暗通用） ────────────────────────────────────────────────
  // 权威定义在共享的透明配置 `transparency_tokens.dart` + 曲线结构
  // `gradient_blur_tokens.dart`（这层渐进模糊属于内容区，见 `MiGradientBlur`）；
  // 这里转发保持旧引用可用，取值与文档见那两个文件。

  /// 栏顶**平台段**的 blur σ（dp）= [MiGradientBlurProfile.sigma]（5.37）。
  static const double blurSigma = MiGradientBlurProfile.sigma;

  /// 度量 σ(y) 的**分段强度表** = [MiGradientBlurProfile.bands]。
  static final List<MiTopBarBlurBand> blurBands =
      MiGradientBlurProfile.bands;

  /// 深色配方（HyperOS 设置「显示与亮度」页素材逐帧度量；顶部不透明）。
  ///
  /// 色值（含各档 α）在 [MiTransparencyTokens.scrimGradientDark]，这里只给
  /// 几何：每档对应的 y 除以 [MiTopBarMetrics.scrimHeight] 128.9 的归一化位置。
  static const MiTopBarPalette dark = MiTopBarPalette(
    scrimGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [
        0.0, // y  0.0dp
        0.49340, // y 63.6dp  —— alpha 1.000（实心段下沿）
        0.55672, // y 71.8dp  —— 0.956
        0.62009, // y 79.9dp  —— 0.875
        0.68340, // y 88.1dp  —— 0.770
        0.74670, // y 96.3dp  —— 0.646
        0.81001, // y 104.4dp —— 0.506
        0.87339, // y 112.6dp —— 0.351
        0.93670, // y 120.7dp —— 0.182
        1.0, // y 128.9dp —— 0.000
      ],
      colors: MiTransparencyTokens.scrimGradientDark,
    ),
    ink: MiColors.foreground,
    pressHighlight: MiTransparencyTokens.pressHighlightDark,
    // 顶部 α = 1.000 纯黑直到 63.6dp（stops 0.4934 × scrimHeight 128.9）
    scrimOpaqueBottom: 63.6,
  );

  /// 浅色配方（**本轮度量**：叠色 = 页底色 #F3F3F3，α 0.650 → 0）。
  static const MiTopBarPalette light = MiTopBarPalette(
    scrimGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [
        0.0, // y   0.0dp —— alpha 0.650
        0.25989, // y  33.5dp —— 0.634
        0.31963, // y  41.2dp —— 0.606
        0.43988, // y  56.7dp —— 0.594
        0.56012, // y  72.2dp —— 0.577
        0.61986, // y  79.9dp —— 0.530
        0.67960, // y  87.6dp —— 0.501
        0.74011, // y  95.4dp —— 0.427
        0.79984, // y 103.1dp —— 0.314
        0.85958, // y 110.8dp —— 0.183
        0.91932, // y 118.5dp —— 0.055
        0.94957, // y 122.4dp —— 0.000（以下只剩磨砂，无叠色）
      ],
      colors: MiTransparencyTokens.scrimGradientLight,
    ),
    ink: MiColors.foregroundLight,
    pressHighlight: MiTransparencyTokens.pressHighlightLight,
    // 亮色叠色顶部 α 仅 0.650 → 全段半透明，模糊一段都不能省
    scrimOpaqueBottom: 0,
  );

  /// 按明暗模式取配方。
  static MiTopBarPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;

  /// **透明顶栏配方档**（推导档，非度量：素材没有透明顶栏样张；面向阅读页
  /// 这类「顶栏叠在任意内容上、靠零件亮边读分隔」的形态，如下游 MReader
  /// 阅读页）。
  ///
  /// 一档命名配方 = 零叠色（[scrimGradient] 全透明、[scrimOpaqueBottom] = 0）；
  /// 完整形态再关磨砂、亮边常驻，一行切换（墨色/按压高光随明暗取
  /// [transparentFor]）：
  ///
  /// ```dart
  /// MiTopBar(
  ///   title: '章节名',
  ///   showBlur: false,               // σ=0：栏内无磨砂
  ///   showSurface: false,            // 零叠色（本档双保险）
  ///   palette: MiTopBarPalette.transparentFor(themeMode),
  ///   rimProgress: 1.0,              // 内缘亮边常驻（默认即 1.0）
  /// )
  /// ```
  ///
  /// 栏内不压任何材质，标题 / 零件与内容的分隔只靠内缘亮边（
  /// `MiGlassRimPainter`）与墨色对比。
  static const MiTopBarPalette transparent = MiTopBarPalette(
    scrimGradient: _clearScrim,
    ink: MiColors.foreground,
    pressHighlight: MiTransparencyTokens.pressHighlightDark,
    scrimOpaqueBottom: 0,
  );

  /// 透明档（随明暗取墨色 / 按压高光；叠色两档同为零叠色）。
  static MiTopBarPalette transparentFor(MiThemeMode mode) =>
      mode == MiThemeMode.dark
          ? transparent
          : const MiTopBarPalette(
              scrimGradient: _clearScrim,
              ink: MiColors.foregroundLight,
              pressHighlight: MiTransparencyTokens.pressHighlightLight,
              scrimOpaqueBottom: 0,
            );

  /// 零叠色渐变（透明档专用：两端全透明，开 [showSurface] 也不压任何色）。
  static const LinearGradient _clearScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [MiTransparencyTokens.clear, MiTransparencyTokens.clear],
  );
}
