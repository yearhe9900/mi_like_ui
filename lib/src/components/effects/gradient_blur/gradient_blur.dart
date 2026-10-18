import 'package:flutter/material.dart';

import '../../../theme/gradient_blur_tokens.dart';
import '../../../utils/filter_cache.dart';

/// 顶部**渐进模糊**：一片从顶部最糊、向下逐段变锐、到区底归零的磨砂。
///
/// ## 它不属于顶栏
///
/// 参考 App 里有一页**完全没有顶栏**（主题商店「每日精选」），内容顶部照样
/// 是糊的 —— 逐行水平梯度 44dp `0.05` → 75dp `0.97` → 116dp `4.32` →
/// **120dp 后不再上升**（已完全清晰、没有硬边）。所以这层模糊是**内容滚动区
/// 自己的顶部渐进模糊**：滚动内容从下面经过时被它糊住，`MiTopBar` 只是位置
/// 正好压在上面、顺带复用（`showBlur`）。
///
/// 因此本组件**不依赖顶栏**：任何滚动内容都能自己挂一层，换页面形态（无顶栏、
/// 只有状态栏、只有搜索栏）时不用跟着顶栏走。
///
/// ## 用法
///
/// 叠在滚动内容之上、其它内容之下（`Stack` 里排在列表后面即可；它不吃手势）：
///
/// ```dart
/// Stack(children: [
///   ListView(children: [...]),
///   Positioned(top: 0, left: 0, right: 0, height: 120,
///     child: MiGradientBlur(height: 120)),
/// ])
/// ```
///
/// 需要压色（保证标题/零件可读）时，把那层渐变另画在一个 `Stack` 里盖在本组件
/// 之上 —— 那是**顶栏自己的**东西，与本组件无关。
///
/// ## 实现
///
/// **8 段定 σ 并列**（[MiGradientBlurProfile.bands]）：每段
/// `ClipRect → BackdropFilter(σ_i)`，σ 取实测 σ(y) 曲线在该段中点处的值。
/// 曲线**形状固定、范围跟着 [height] 走**：`119dp` 的实测曲线等比拉伸到
/// [height] 并在区底归零，所以底下不会留一条硬边。
///
/// Flutter 没有「位置相关模糊」，而唯一能按位置衰减的手段（渐变 `ShaderMask` /
/// `Opacity`）会引入新的 saveLayer 并把 backdrop 变空 —— 实测遮罩 alpha 恒 1
/// 时模糊正常，一旦出现 <1 的 alpha 模糊**整段消失**。故只能分段近似：
/// 段高 ≤ 17dp、相邻 σ 比 ≤ 1.5，台阶肉眼不可见。
class MiGradientBlur extends StatelessWidget {
  const MiGradientBlur({
    super.key,
    this.height = MiGradientBlurProfile.nominalExtent,
    this.opaqueScrimBottom = 0,
    this.underSurface = true,
  }) : assert(height > 0, 'height 必须为正'),
       assert(opaqueScrimBottom >= 0, 'opaqueScrimBottom 不能为负');

  /// 作用区高度（dp）—— 曲线拉伸到这个高度并在底部归零。
  ///
  /// 默认 [MiGradientBlurProfile.nominalExtent]（119dp，实测曲线自身的跨度）；
  /// 顶栏形态传它的材质盒高（无头部区 128.9 / 有头部区整条栏）。
  final double height;

  /// 盖在上面的压色**完全不透明**段的下沿（dp，距顶端）；0 = 没有这种不透明段。
  ///
  /// 传**最终 dp**（压色盒比曲线高时，其比例 stop 会跟着拉长，由调用方换算）。
  /// 给了它、且 [underSurface] 为 true 时，完全落在里面的模糊段会被跳过 ——
  /// 底下的结果 100% 被遮住，省掉的是纯浪费的每帧全宽高斯。
  final double opaqueScrimBottom;

  /// 上层是否**真的**有那层不透明压色。
  ///
  /// 关掉压色时必须传 `false`：那时上半段是透明的，模糊真会被看到，跳过它
  /// 等于顶部一片清晰（实机踩过）。
  final bool underSurface;

  /// 实际要绘制的模糊段（剔除视觉上不存在的段），按 y 升序、首尾相接。
  ///
  /// 剔除两类：
  ///  * σ < [MiGradientBlurProfile.minVisibleSigma] —— 高斯半径 < 1dp，亚像素；
  ///  * [underSurface] 为 true 时，完全落在 [opaqueScrimBottom] 之内的段。
  ///
  /// 后者是零视觉差异的省帧手段：平板 768×1280 深色首页实测，模糊段从
  /// 8 段 / 119dp 降到 5 段 / 45.4dp，模糊面积 85,680 → 32,688 dp²（−62%）；
  /// 每段在滚动时都要重算一次全宽高斯，这是丢帧的主因。
  static List<MiTopBarBlurBand> bandsFor({
    double extent = MiGradientBlurProfile.nominalExtent,
    double opaqueScrimBottom = 0,
    bool underSurface = true,
  }) {
    if (extent <= 0) return const <MiTopBarBlurBand>[];
    final nominal = MiGradientBlurProfile.bands.last.bottom;
    final k = extent / nominal;
    // 压色的渐变 stop 是比例值，会跟着同一块盒子一起拉长，实心段下沿同样被拉长
    final opaque = underSurface ? opaqueScrimBottom : 0.0;
    final bands = <MiTopBarBlurBand>[];
    for (final band in MiGradientBlurProfile.bands) {
      if (band.sigma < MiGradientBlurProfile.minVisibleSigma) continue;
      final top = band.top * k;
      final bottom = band.bottom * k;
      final clipped = top > opaque ? top : opaque;
      if (bottom <= clipped) continue;
      bands.add(MiTopBarBlurBand(
        top: clipped,
        height: bottom - clipped,
        sigma: band.sigma,
      ));
    }
    return bands;
  }

  @override
  Widget build(BuildContext context) {
    final bands = bandsFor(
      extent: height,
      opaqueScrimBottom: opaqueScrimBottom,
      underSurface: underSurface,
    );
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            for (final band in bands)
              Positioned(
                left: 0,
                right: 0,
                top: band.top,
                height: band.height,
                child: ClipRect(
                  child: BackdropFilter(
                    // σ 来自固定 token → 复用缓存的 native filter，避免每帧
                    // 重建（滚动时每帧都会走这里）。
                    filter: MiFilterCache.blur(band.sigma),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
