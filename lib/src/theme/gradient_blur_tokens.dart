import 'package:flutter/foundation.dart';

import 'transparency_tokens.dart';

/// 顶部**渐进模糊**（内容区自己那层磨砂）的实测曲线 token。
///
/// 这层模糊**不属于顶栏**：参考 App 里有一页完全没有顶栏（主题商店「每日
/// 精选」），内容顶部照样是糊的，而且越往下越清晰、到 ~120dp 自然收尾
/// （逐行水平梯度 `|g|`：44dp `0.05` → 75dp `0.97` → 116dp `4.32` →
/// **120dp 后不再上升**，即已完全清晰、没有硬边）。顶栏只是位置正好压在
/// 上面、顺带把这层画在同一处（见 `MiGradientBlur`）。
///
/// σ(y) 曲线本身实测自亮色「我的」页录屏（1220×2656，s = 393/1220）：
/// 栏顶平台段 5.37dp，50dp 处 4.96、67.5dp 处 4.34、90dp 处 1.85、
/// 103dp 处 0.76、119dp 归零。
///
/// 渐进效果只能**分段定 σ 并列**实现（Flutter 没有位置相关模糊；用渐变
/// `ShaderMask` / `Opacity` 削弱模糊层会引入新 saveLayer、把 backdrop 变空，
/// 实测整段模糊消失）。段高 ≤ 17dp、相邻 σ 比 ≤ 1.5 时台阶肉眼不可见。
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
  /// 逐档取自 [MiTransparencyTokens.blurSigmaRamp]（实测控制点分段线性插值）。
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
