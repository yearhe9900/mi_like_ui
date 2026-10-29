import 'package:flutter/material.dart';

import '../../../theme/gradient_blur_tokens.dart';
import '../../../utils/filter_cache.dart';

/// 顶部渐进模糊：自顶部最模糊向下逐段变清晰、区底归零的磨砂层。
///
/// 「内容顶部被磨开、越往下越清晰」的视觉效果属**滚动内容自身的顶部模糊**，
/// 与顶栏相互独立：任何滚动内容都可自行挂载，不受页面形态（有无顶栏 /
/// 搜索栏）影响；`MiTopBar(showBlur: true)` 内部复用本组件。
///
/// ## 用法
///
/// 叠在滚动内容之上、其它内容之下（`Stack` 中排在列表之后；不参与手势）：
///
/// ```dart
/// Stack(children: [
///   ListView(children: [...]),
///   Positioned(top: 0, left: 0, right: 0, height: 120,
///     child: MiGradientBlur(height: 120)),
/// ])
/// ```
///
/// 需要压色（保证标题 / 零件可读）时，将渐变压色层另置于本组件之上
/// （属承载组件的职责，与本组件无关）。
///
/// ## 实现
///
/// 分段定 σ 并列（[MiGradientBlurProfile.bands]）：每段
/// `ClipRect → BackdropFilter(σ_i)`，σ_i 取曲线在段中点的值。曲线形状
/// 固定、作用范围随 [height] 等比伸缩并在区底归零，无硬边。
///
/// Flutter 不提供位置相关模糊；对模糊层施加半透明遮罩会破坏其 backdrop，
/// 分段并列是等效近似（段高 ≤ 17dp、相邻 σ 比 ≤ 1.5，视觉无台阶）。
///
/// **边缘完整性（3σ 邻域审计）**：本库磨砂全部走 `BackdropFilter`（吃实时
/// backdrop），Skia / Impeller 在裁剪区之外仍按高斯半径取样真实邻域内容
/// —— 不存在「快照纹理」路线（先把背景拍成 Image 再糊）的「取样区外
/// 为透明 → 边缘变暗」坑。那条路线的 3σ margin + 绘制区裁剪技巧
/// （思路源自 flutter_miuix `texture_blur.dart`）留待未来纹理玻璃专题
/// 引入，本实现无需也不应添加。
class MiGradientBlur extends StatelessWidget {
  const MiGradientBlur({
    super.key,
    this.height = MiGradientBlurProfile.nominalExtent,
    this.opaqueScrimBottom = 0,
    this.underSurface = true,
    this.sigmaScale = 1.0,
  }) : assert(height > 0, 'height 必须为正'),
       assert(opaqueScrimBottom >= 0, 'opaqueScrimBottom 不能为负'),
       assert(sigmaScale > 0, 'sigmaScale 必须为正');

  /// 作用区高度（dp）—— 曲线拉伸到这个高度并在底部归零。
  ///
  /// 默认 [MiGradientBlurProfile.nominalExtent]（119dp，度量曲线自身的跨度）；
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

  /// σ 缩放系数（**推导值**，默认 1.0 = 不缩放）。
  ///
  /// 滚动中 backdrop 每帧重算，是本库最贵的一块 —— 传 < 1 的值（如 0.6）
  /// 可在**运动中**把每段 σ 等比压低，GPU 成本随 σ 线性下降；停下来后传回
  /// 1.0 即恢复度量材质。曲线**形状**不变（各段同比例缩放，仍是单调递减、
  /// 无缝铺满），只改强度。
  ///
  /// 与 [minVisibleSigma] 的关系：缩放后 σ 低于阈值的段会被照常剔除
  /// （亚像素模糊与「不模糊」不可分辨），所以低速滚动时段数可能变少 ——
  /// 这是预期的省帧行为。
  final double sigmaScale;

  /// 实际要绘制的模糊段（剔除视觉上不存在的段），按 y 升序、首尾相接。
  ///
  /// 剔除两类：
  ///  * σ < [MiGradientBlurProfile.minVisibleSigma] —— 高斯半径 < 1dp，亚像素；
  ///  * [underSurface] 为 true 时，完全落在 [opaqueScrimBottom] 之内的段。
  ///
  /// 后者是零视觉差异的省帧手段：平板 768×1280 深色首页度量，模糊段从
  /// 8 段 / 119dp 降到 5 段 / 45.4dp，模糊面积 85,680 → 32,688 dp²（−62%）；
  /// 每段在滚动时都要重算一次全宽高斯，这是丢帧的主因。
  ///  * σ 缩放量化到 0.05 档 —— [MiFilterCache] 以 σ 为键，连续 σScale 会
  ///    让每帧每段都新建 native filter；0.05 档在运动中仍是渐变观感；
  ///  * σScale < 1 时，σ 缩放后低于 [MiGradientBlurProfile.minVisibleSigma]
  ///    的段照常剔除（亚像素模糊与「不模糊」不可分辨）。
  static List<MiTopBarBlurBand> bandsFor({
    double extent = MiGradientBlurProfile.nominalExtent,
    double opaqueScrimBottom = 0,
    bool underSurface = true,
    double sigmaScale = 1.0,
  }) {
    if (extent <= 0) return const <MiTopBarBlurBand>[];
    final scale = (sigmaScale * 20).roundToDouble() / 20;
    final nominal = MiGradientBlurProfile.bands.last.bottom;
    final k = extent / nominal;
    // 压色的渐变 stop 是比例值，会跟着同一块盒子一起拉长，实心段下沿同样被拉长
    final opaque = underSurface ? opaqueScrimBottom : 0.0;
    final bands = <MiTopBarBlurBand>[];
    for (final band in MiGradientBlurProfile.bands) {
      final sigma = band.sigma * scale;
      if (sigma < MiGradientBlurProfile.minVisibleSigma) continue;
      final top = band.top * k;
      final bottom = band.bottom * k;
      final clipped = top > opaque ? top : opaque;
      if (bottom <= clipped) continue;
      bands.add(MiTopBarBlurBand(
        top: clipped,
        height: bottom - clipped,
        sigma: sigma,
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
      sigmaScale: sigmaScale,
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
