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
