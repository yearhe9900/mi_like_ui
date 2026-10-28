import 'package:flutter/painting.dart';

import 'theme_mode.dart';
import 'transparency_tokens.dart';

/// 磨砂玻璃材质配方令牌（所有玻璃类组件共用）。
///
/// 深色透射模型：遮罩 `scrim` 满足 out ≈ 15 + 0.24·in；选中胶囊为**高磨砂
/// 块**（暗化 + 白茶色调，**不开洞**，实测 (c,t)≈(84,0.05)）。
///
/// 浅色同为半透明真实玻璃：遮罩带垂直渐变（上透下实），背后内容色彩
/// 透出；选中胶囊为独立暖灰玻璃体（亮色实测为**开洞**玻璃体，见
/// [MiGlassPalette.lensCutsScrim]）。明暗两套配方见 [MiGlassPalette]。
///
/// **alpha / σ 均为引用**（[MiTransparencyTokens]），本层只决定
/// 「哪一层用哪档」与色相。
class MiGlassTokens {
  MiGlassTokens._();

  /// 背景高斯模糊 sigma（明暗通用）。
  ///
  /// 同源转发自 [MiTransparencyTokens.blurSigma]（统一透明配置），
  /// 保持旧引用兼容；新代码请直接取 [MiTransparencyTokens.blurSigma]。
  static const double blurSigma = MiTransparencyTokens.blurSigma;

  /// 玻璃体深色遮罩（20,20,20 @0.63）。
  static const Color scrim = Color.fromRGBO(
      20, 20, 20, MiTransparencyTokens.glassScrimAlpha);

  /// 选中块暗化层（压在未开洞的栏体玻璃上；暗色实测 t≈0.05 的高磨砂块）。
  static const Color lensShade = Color.fromRGBO(
      0, 0, 0, MiTransparencyTokens.glassLensShadeAlpha);

  /// 选中块白茶色调。
  static const Color lensTint = Color.fromRGBO(
      255, 255, 255, MiTransparencyTokens.glassLensTintAlpha);

  /// 透镜内描边。
  static const Color lensStroke = Color.fromRGBO(
      255, 255, 255, MiTransparencyTokens.glassLensStrokeAlpha);

  /// 玻璃体外缘高光。
  static const Color rim = Color.fromRGBO(
      255, 255, 255, MiTransparencyTokens.glassRimAlpha);
}

/// 玻璃材质配方包（按 [MiThemeMode] 取用的一整套颜色 + 投影）。
///
/// [MiGlassTokens] 的静态常量即 [MiGlassPalette.dark] 的取值（保持旧引用不变）。
class MiGlassPalette {
  const MiGlassPalette({
    required this.scrim,
    required this.lensShade,
    required this.lensTint,
    required this.lensStroke,
    required this.rim,
    this.scrimGradient,
    this.lensTintGradient,
    this.lensCutsScrim = false,
    this.elevationShadow = const [],
  });

  /// 选中块是否在栏体遮罩上**开洞**（「透镜」形态）。
  ///
  /// 亮色实测：选中胶囊是开洞的独立暖灰玻璃体（透射 t≈0.20，比栏体略实）
  /// → `true`；暗色实测：选中块是**高磨砂块**（(c,t)≈(84,0.05)，内容几乎
  /// 不透出）→ `false`（暗化 + 白茶色调压在未开洞的栏体玻璃之上）。
  final bool lensCutsScrim;

  /// 玻璃体遮罩（[lensCutsScrim] 为真时在选中块处开洞）；
  /// [scrimGradient] 非空时改按渐变绘制。
  final Color scrim;

  /// 玻璃体遮罩垂直渐变（可空 = 纯色 [scrim]；亮色度量上透下实）。
  final Gradient? scrimGradient;

  /// 选中块暗化层（[lensCutsScrim] 为假时贴在栏体玻璃上；为真时贴在开洞处）。
  final Color lensShade;

  /// 选中块色调（叠在暗化层上）；
  /// [lensTintGradient] 非空时改按渐变绘制。
  final Color lensTint;

  /// 选中块色调垂直渐变（可空 = 纯色 [lensTint]）。
  final Gradient? lensTintGradient;

  /// 选中块内描边（深色 0.08 度量；浅色真值为无描边=透明，见 [MiGlassPalette.light]）。
  final Color lensStroke;

  /// 玻璃体外缘高光。
  final Color rim;

  /// 玻璃体投影（浅色下可见；深色下为空，不产生任何绘制）。
  final List<BoxShadow> elevationShadow;

  /// 深色配方（视频度量，见 [MiGlassTokens]）。
  static const MiGlassPalette dark = MiGlassPalette(
    scrim: MiGlassTokens.scrim,
    lensShade: MiGlassTokens.lensShade,
    lensTint: MiGlassTokens.lensTint,
    lensStroke: MiGlassTokens.lensStroke,
    rim: MiGlassTokens.rim,
  );

  /// 浅色配方（亮色素材真实玻璃度量 1220×2656，采样密度≈3.07）。
  ///
  /// 真实玻璃形态（区别于旧"白玻璃"近实白读数——那是白底上的表现）：
  ///  * 栏体半透明磨砂玻璃：垂直渐变遮罩 alpha 0.61→0.76→0.80（上→中→下），
  ///    色 #FBFBFB，透射模型 out = a·C + (1-a)·blurB（背后内容色彩透上来）；
  ///  * 选中胶囊是独立暖灰玻璃体（色 ≈#E6E6E7，alpha 0.66→0.78→0.82），
  ///    比栏体暗 ~13 级；lensShade 置全透明（无额外暗化）；
  ///  * 胶囊边缘**无描边**（素材真值：218→205 干净亮度阶跃、无亮环）；
  ///    描边取白 0.30 会在胶囊外沿形成白亮环、与间隙带连成一片，影响
  ///    胶囊与栏体的间距可读性，故描边为 0；
  ///  * 外缘纯白 #FFFFFF 高光（度量峰值 255）；
  ///  * 投影：下缘近处约 -8 级、~50px 内衰减完。
  static const MiGlassPalette light = MiGlassPalette(
    lensCutsScrim: true,
    scrim: Color.fromRGBO(
        251, 251, 251, MiTransparencyTokens.glassScrimLightAlphaMid),
    scrimGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0, 0.5, 1],
      colors: [
        Color.fromRGBO(
            251, 251, 251, MiTransparencyTokens.glassScrimLightAlphaTop),
        Color.fromRGBO(
            251, 251, 251, MiTransparencyTokens.glassScrimLightAlphaMid),
        Color.fromRGBO(
            251, 251, 251, MiTransparencyTokens.glassScrimLightAlphaBottom),
      ],
    ),
    lensShade: Color.fromRGBO(
        0, 0, 0, MiTransparencyTokens.glassLensShadeLightAlpha),
    lensTint: Color.fromRGBO(
        230, 230, 231, MiTransparencyTokens.glassLensTintLightAlphaMid),
    lensTintGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0, 0.5, 1],
      colors: [
        Color.fromRGBO(
            230, 230, 231, MiTransparencyTokens.glassLensTintLightAlphaTop),
        Color.fromRGBO(
            230, 230, 231, MiTransparencyTokens.glassLensTintLightAlphaMid),
        Color.fromRGBO(
            230, 230, 231, MiTransparencyTokens.glassLensTintLightAlphaBottom),
      ],
    ),
    lensStroke: Color.fromRGBO(
        255, 255, 255, MiTransparencyTokens.glassLensStrokeLightAlpha),
    rim: Color.fromRGBO(255, 255, 255, MiTransparencyTokens.glassRimLightAlpha),
    elevationShadow: [
      BoxShadow(
          color: MiTransparencyTokens.glassShadowLight,
          blurRadius: 32,
          offset: Offset(0, 4)),
    ],
  );

  /// 按明暗模式取配方。
  static MiGlassPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;
}
