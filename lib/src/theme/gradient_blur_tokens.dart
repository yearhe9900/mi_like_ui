import 'package:flutter/foundation.dart';

import 'transparency_tokens.dart';

/// 顶部渐进模糊的曲线令牌（`MiGradientBlur` / `MiTopBar` 共用）。
///
/// 该层模糊属滚动内容自身的顶部磨砂，与顶栏相互独立（见 `MiGradientBlur`）。
///
/// σ(y) 曲线（设计度量，393dp 设计宽）：顶部平台段 5.37dp，50dp 处 4.96、
/// 67.5dp 处 4.34、90dp 处 1.85、103dp 处 0.76、119dp 归零。
///
/// 渐进效果以**分段定 σ 并列**实现（Flutter 不提供位置相关模糊，且对模糊
/// 层施加半透明遮罩会破坏其 backdrop）；段高 ≤ 17dp、相邻 σ 比 ≤ 1.5 时
/// 视觉无台阶。
@immutable
class MiTopBarBlurBand {
  const MiTopBarBlurBand({
    required this.top,
    required this.height,
    required this.sigma,
  });

  /// 段顶距作用区顶端的距离（dp）。
  final double top;

  /// 段高（dp）。
  final double height;

  /// 段内使用的 blur σ（dp，高斯标准差）。
  final double sigma;

  /// 段底（dp）。
  double get bottom => top + height;

  @override
  bool operator ==(Object other) =>
      other is MiTopBarBlurBand &&
      other.top == top &&
      other.height == height &&
      other.sigma == sigma;

  @override
  int get hashCode => Object.hash(top, height, sigma);

  @override
  String toString() => 'MiTopBarBlurBand($top…$bottom dp, σ=$sigma)';
}

/// 渐进模糊的曲线常量（明暗通用 —— 参考页亮/暗的模糊强度一致，差别只在
/// 顶栏那层压色）。
///
/// **σ 数值一律取自 [MiTransparencyTokens]**（统一透明配置），这里只负责
/// 「哪一段、多高」这类几何。
class MiGradientBlurProfile {
  const MiGradientBlurProfile._();

  /// 顶部**平台段**的 blur σ（dp）= [MiTransparencyTokens.blurSigmaTop]（5.37）。
  static const double sigma = MiTransparencyTokens.blurSigmaTop;

  /// 曲线从顶部到「完全清晰」的**名义**跨度（dp）= 119。
  ///
  /// 这是 128.9dp 材质盒上量出来的值；作用区更高时曲线会**等比拉伸**到
  /// 区底归零（形状固定、范围跟着走），见 `MiGradientBlur.bandsFor`。
  static const double nominalExtent = MiTransparencyTokens.nominalBlurExtent;

  /// 低于该 σ 的模糊段**不绘制**（= [MiTransparencyTokens.minVisibleSigma]）。
  static const double minVisibleSigma = MiTransparencyTokens.minVisibleSigma;

  /// 8 段定 σ 阶梯：段位 / 段高是几何（见 [_tops] / [_heights]），每段的 σ
  /// 逐档取自 [MiTransparencyTokens.blurSigmaRamp]（度量控制点分段线性插值）。
  ///
  /// 不是 `const`：σ 来自统一配置的那张表，逐档引用比把数值抄一遍可靠。
  static final List<MiTopBarBlurBand> bands =
      List<MiTopBarBlurBand>.unmodifiable(<MiTopBarBlurBand>[
    for (var i = 0; i < _tops.length; i++)
      MiTopBarBlurBand(
        top: _tops[i],
        height: _heights[i],
        sigma: MiTransparencyTokens.blurSigmaRamp[i],
      ),
  ]);

  /// 各段顶部位置（dp）。
  static const List<double> _tops = <double>[
    0, // 平台段 0…35
    35,
    50, // 50.1dp 测点 4.96
    67, // 67.5dp 测点 4.34
    78,
    90, // 90.0dp 测点 1.85
    100, // 103dp 测点 0.76
    109,
  ];

  /// 各段高度（dp）；段高 ≤ 17、相邻 σ 比 ≤ 1.5 时台阶肉眼不可见。
  static const List<double> _heights = <double>[
    35,
    15,
    17,
    11,
    12,
    10,
    9,
    10,
  ];
}

/// 头部区形态（搜索栏 + 胶囊行悬浮在滚动内容上）的磨砂曲线。
///
/// 与 [MiGradientBlurProfile]（「我的」页顶部那条，平台 5.37dp / 119dp
/// 归零）是**两套度量**：同一件事物在两个页面形态上的实测结果不同，
/// 按各自的参考页用各自的曲线（先例：深浅两页顶部压色 α 不同也不归一，
/// 见 `MiTopBarPalette`）。
///
/// ## 本轮度量（2026-10-27，1220×2656 明暗双素材，采样密度
/// s = 393/1220 = 0.32213 dp/px）
///
/// 横幅侧边是理想竖直阶跃（区外锐利样本实测 10-90 宽仅 1.3…1.6px），
/// 以其在不同深度处的 10-90 宽度（w = 2.563σ）erf 最小二乘拟合
/// （线性内容趋势 + 误差函数边缘，拟合残差 <900 的样本为准）：
///
/// | 深度 (dp) | 实测 σ (dp) | 线性模型预测 |
/// |-----------|-------------|--------------|
/// | 35…48     | 7.57…9.02   | 8.0…7.6      |
/// | 100…113   | 3.22…4.35   | 4.2…3.3      |
/// | 155       | ≈0.4        | 0.5          |
/// | ≥162      | 0           | 0            |
///
/// 即 **平台段 8.5dp 到 35dp，此后线性衰减、158dp 归零**——胶囊行底
/// （152dp）之后还有约 6dp 的羽化带，不是硬切（胶囊正下方的横幅文字
/// 仍轻微发虚、再往下才锐利；暗色素材 155dp 处横幅上缘实测 σ0.4dp）。
/// 佐证：亮色左右缘独立拟合、暗色右缘弱样本、以及滚动帧里横幅上缘穿过
/// 玻璃区时的宽度变化（502…514dp 处 1.4px、482dp 处 3.5px）指向同一曲线。
///
/// ⚠️ 旧口径「头部区是恒定 σ、胶囊底硬切」出自 884×1920 低清素材，
/// 受视频压缩软化与分辨率限制不可分辨渐变；本轮原生素材推翻该结论。
@immutable
class MiHeaderBlurProfile {
  const MiHeaderBlurProfile._();

  /// 平台段 σ（dp）= [MiTransparencyTokens.blurSigmaHeaderTop]（8.5）。
  static const double sigma = MiTransparencyTokens.blurSigmaHeaderTop;

  /// 曲线从栏顶到完全清晰的**名义**跨度（dp）= 158。
  ///
  /// 材质盒高不同时曲线**等比拉伸**到盒底归零（形状固定、范围跟着走），
  /// 与 [MiGradientBlurProfile.nominalExtent] 同一口径。
  static const double nominalExtent =
      MiTransparencyTokens.headerBlurNominalExtent;

  /// 低于该 σ 的模糊段不绘制（= [MiTransparencyTokens.minVisibleSigma]）。
  static const double minVisibleSigma = MiTransparencyTokens.minVisibleSigma;

  /// 9 段定 σ 阶梯：段位 / 段高是几何（[_tops] / [_heights]），每段 σ
  /// 逐档取自 [MiTransparencyTokens.blurSigmaHeaderRamp]（曲线在段中点的值，
  /// 尾部两档圆整保证相邻比 < 2.4）。
  static final List<MiTopBarBlurBand> bands =
      List<MiTopBarBlurBand>.unmodifiable(<MiTopBarBlurBand>[
    for (var i = 0; i < _tops.length; i++)
      MiTopBarBlurBand(
        top: _tops[i],
        height: _heights[i],
        sigma: MiTransparencyTokens.blurSigmaHeaderRamp[i],
      ),
  ]);

  /// 各段顶部位置（dp）。
  static const List<double> _tops = <double>[
    0, // 平台段 0…35
    35,
    50,
    64,
    78,
    92,
    108,
    124,
    142, // 羽化尾段 142…158
  ];

  /// 各段高度（dp）；合计 = [nominalExtent]（158）。
  static const List<double> _heights = <double>[
    35,
    15,
    14,
    14,
    14,
    16,
    16,
    18,
    16,
  ];
}
