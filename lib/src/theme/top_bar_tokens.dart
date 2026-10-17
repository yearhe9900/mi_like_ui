import 'package:flutter/painting.dart';

import 'colors.dart';
import 'theme_mode.dart';

/// 顶部导航栏 [MiTopBar] 的**材质**（磨砂 + 叠色）与配色 token。
///
/// 材质由两层组成，两层都逐帧实测：
///  1. **磨砂**：backdrop 高斯模糊，σ = [blurSigma]，强度按 [blurMask]
///     的纵向 alpha 渐变从栏顶的 1 衰减到 0（"渐进模糊"）；
///  2. **叠色**：[MiTopBarPalette.scrimGradient] —— 顶部最深、向下渐隐。
///
/// ## 磨砂（本轮新增，实测）
///
/// Source: 1220×2656 亮色「我的」页录屏（24.26 fps，采样密度
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
/// 特征（m<1 时台阶跳变落在 10-90 带内，宽度收敛到 2.08σ）。故实现为
/// 「定 σ 的 BackdropFilter + 纵向 alpha 遮罩」，[blurMask] 的 m(y) 即由
/// 上式逐行反解（1.00 @0…35dp → 0.67 @67.5dp → 0.30 @90dp → 0 @119dp）。
///
/// ## 叠色
///
/// **亮色配方（本轮实测）**：叠色 = **页底色 #F3F3F3**，α 由 0.650（栏顶）
/// 平滑衰减到 0（122.4dp）。判据是两处平坦区的交叉验证 ——
///  * 同帧页底 #F3F3F3(243) 在栏内**全程不变**（243→243）：排除白色叠色；
///  * 白色卡片填充 255 在栏内 80dp 处读 **249** = 255 − (255−243)×0.50，
///    而同帧栏外读 255 —— 只有「叠色 = 页底色、α(80dp) ≈ 0.50」能同时
///    解释这两点（白色叠色会把页底抬亮，纯黑叠色会把卡片压到 ~243）。
///  α(y) 曲线取自 1-D 逐行反卷积（同行锐利剖面高斯模糊 ↔ 带内剖面做
///  最小二乘），再经保序回归（PAVA）单调平滑；下方 stop 逐行注明 (y, α)。
///
/// **深色配方（沿用既有实测）**：取自 1220×2656 HyperOS 设置「显示与亮度」
/// 页录屏 —— 该页栏顶是**不透明黑**：沿蓝卡平坦填充做纵向取样得透射比
/// 0.01…1.00（y = 64.4…128.9dp）。平坦色块在模糊下亮度不变，故该透射比
/// 只能来自叠色，α 顶部 ≈ 1.0。深浅两页的顶部 α 不同（1.0 vs 0.65）是
/// **两页各自的实测结果**，不做归一：磨砂材质共用，叠色各随其参考页。
///
/// 墨色沿用框架前景色 [MiColors.foreground]（实测标题笔画内部 246）；
/// 返回圆钮按压反馈为**白 @9.4%**（叠纯黑底实测 24 级，圆盘内均匀），
/// 浅色配方取同 alpha 的反相黑 @9.4%。
class MiTopBarPalette {
  const MiTopBarPalette({
    required this.scrimGradient,
    required this.ink,
    required this.pressHighlight,
  });

  /// 顶栏叠色：纵向渐变，顶部最深 → 各自实测处完全透明（渐变坐标按
  /// 遮罩盒高 [MiTopBarMetrics.scrimHeight] = 128.9dp 归一化）。
  final Gradient scrimGradient;

  /// 标题墨色 / 返回箭头墨色。
  final Color ink;

  /// 返回圆钮按压反馈圆盘底色（半径 = 圆钮半径，实测平坦无角向变化）。
  final Color pressHighlight;

  // ── 磨砂材质（明暗通用） ────────────────────────────────────────────────
  /// backdrop 高斯模糊 σ（dp）。取栏顶平台段 10-90% 宽度 42.7px 换算：
  /// σ = 42.7px / 2.563 × 0.32213 = 5.37dp（频谱比法在 67.5dp 处给出
  /// 4.34dp、90dp 处 1.85dp，与衰减曲线一致）。
  static const double blurSigma = 5.37;

  /// 磨砂遮罩：纵向 alpha 渐变，1 = 全强度模糊、0 = 完全锐利。
  ///
  /// 用在 `ShaderMask(blendMode: BlendMode.dstIn)` 包住 `BackdropFilter`
  /// 上：遮罩为 1 处只留模糊结果、为 0 处只留原内容 → 合成结果
  /// `(1−m)·原内容 + m·模糊(原内容)`，与实测模型同构。
  /// m(y) 由实测边缘宽度逐行反解（见类文档表格）。
  static const LinearGradient blurMask = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [
      0.0, // y   0.0dp —— m 1.000
      0.12878, // y  16.6dp —— 1.000（平台段）
      0.26843, // y  34.6dp —— 0.980
      0.38867, // y  50.1dp —— 0.850
      0.52366, // y  67.5dp —— 0.670
      0.69822, // y  90.0dp —— 0.300
      0.79829, // y 102.9dp —— 0.240
      0.84329, // y 108.7dp —— 0.140
      0.92320, // y 119.0dp —— 0.000（以下完全锐利）
    ],
    colors: [
      Color.fromRGBO(0, 0, 0, 1.000),
      Color.fromRGBO(0, 0, 0, 1.000),
      Color.fromRGBO(0, 0, 0, 0.980),
      Color.fromRGBO(0, 0, 0, 0.850),
      Color.fromRGBO(0, 0, 0, 0.670),
      Color.fromRGBO(0, 0, 0, 0.300),
      Color.fromRGBO(0, 0, 0, 0.240),
      Color.fromRGBO(0, 0, 0, 0.140),
      Color.fromRGBO(0, 0, 0, 0.000),
    ],
  );

  /// 深色配方（HyperOS 设置「显示与亮度」页录屏逐帧实测；顶部不透明）。
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
      colors: [
        Color.fromRGBO(0, 0, 0, 1.000),
        Color.fromRGBO(0, 0, 0, 1.000),
        Color.fromRGBO(0, 0, 0, 0.956),
        Color.fromRGBO(0, 0, 0, 0.875),
        Color.fromRGBO(0, 0, 0, 0.770),
        Color.fromRGBO(0, 0, 0, 0.646),
        Color.fromRGBO(0, 0, 0, 0.506),
        Color.fromRGBO(0, 0, 0, 0.351),
        Color.fromRGBO(0, 0, 0, 0.182),
        Color.fromRGBO(0, 0, 0, 0.000),
      ],
    ),
    ink: MiColors.foreground,
    pressHighlight: Color.fromRGBO(255, 255, 255, 0.094),
  );

  /// 浅色配方（**本轮实测**：叠色 = 页底色 #F3F3F3，α 0.650 → 0）。
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
      colors: [
        Color.fromRGBO(243, 243, 243, 0.650),
        Color.fromRGBO(243, 243, 243, 0.634),
        Color.fromRGBO(243, 243, 243, 0.606),
        Color.fromRGBO(243, 243, 243, 0.594),
        Color.fromRGBO(243, 243, 243, 0.577),
        Color.fromRGBO(243, 243, 243, 0.530),
        Color.fromRGBO(243, 243, 243, 0.501),
        Color.fromRGBO(243, 243, 243, 0.427),
        Color.fromRGBO(243, 243, 243, 0.314),
        Color.fromRGBO(243, 243, 243, 0.183),
        Color.fromRGBO(243, 243, 243, 0.055),
        Color.fromRGBO(243, 243, 243, 0.000),
      ],
    ),
    ink: MiColors.foregroundLight,
    pressHighlight: Color.fromRGBO(0, 0, 0, 0.094),
  );

  /// 按明暗模式取配方。
  static MiTopBarPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;
}
