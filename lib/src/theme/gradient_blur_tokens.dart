import 'package:flutter/foundation.dart';

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
class MiGradientBlurProfile {
  const MiGradientBlurProfile._();

  /// 顶部**平台段**的 blur σ（dp）。取 10-90% 边缘宽度 42.7px 换算：
  /// σ = 42.7 / 2.563 × 0.32213 = 5.37dp（频谱比法在 67.5dp 给出 4.34dp、
  /// 90dp 处 1.85dp，与衰减曲线一致）。
  static const double sigma = 5.37;

  /// 曲线从顶部到「完全清晰」的**名义**跨度（dp）。
  ///
  /// 这是 128.9dp 材质盒上量出来的值；作用区更高时曲线会**等比拉伸**到
  /// 区底归零（形状固定、范围跟着走），见 `MiGradientBlur.bandsFor`。
  static const double nominalExtent = 119;

  /// 低于该 σ 的模糊段**不绘制**：高斯半径 < 1dp 落在亚像素，渲染结果与
  /// 「不模糊」在任意 dpr 下都不可分辨（实测曲线尾部 0.76 / 0.27 即属此列）。
  static const double minVisibleSigma = 0.5;

  /// 8 段定 σ 阶梯：σ 取实测控制点 (0, 5.37) (35, 5.37) (50, 4.96)
  /// (67.5, 4.34) (90, 1.85) (103, 0.76) (119, 0) 的分段线性插值在段中点
  /// 处的值。
  static const List<MiTopBarBlurBand> bands = [
    MiTopBarBlurBand(top: 0, height: 35, sigma: 5.37), // 平台段 0…35
    MiTopBarBlurBand(top: 35, height: 15, sigma: 5.15),
    MiTopBarBlurBand(top: 50, height: 17, sigma: 4.68), // 50.1dp 测点 4.96
    MiTopBarBlurBand(top: 67, height: 11, sigma: 3.80), // 67.5dp 测点 4.34
    MiTopBarBlurBand(top: 78, height: 12, sigma: 2.50),
    MiTopBarBlurBand(top: 90, height: 10, sigma: 1.45), // 90.0dp 测点 1.85
    MiTopBarBlurBand(top: 100, height: 9, sigma: 0.70), // 103dp 测点 0.76
    MiTopBarBlurBand(top: 109, height: 10, sigma: 0.30),
  ];
}
