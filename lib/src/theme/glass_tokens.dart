import 'package:flutter/painting.dart';

import 'theme_mode.dart';
import 'transparency_tokens.dart';

/// 磨砂玻璃材质配方 token（视频/截图实测，所有玻璃类组件共用）。
///
/// 实测透射模型（深色）：遮罩 `scrim` 在干净列上满足 out = 0.37·in + 12.6；
/// 高亮胶囊是"透镜"（在遮罩上开洞 + 暗化 + 白茶色），不是纯色块。
///
/// 浅色同样是半透明真实玻璃（亮色录屏 1220×2656 实测）：遮罩带垂直
/// 渐变（上更透、下更实），背后内容色彩透上来；选中胶囊是独立的暖灰
/// 玻璃体。旧"白玻璃"参考图（近白底 #F7F7F7）实为同一配方在白底上的
/// 表现（代入透射模型体部≈#FBFBFB、胶囊≈#EAEAEA，与旧采样吻合）。
/// 明暗两套配方见 [MiGlassPalette]。
class MiGlassTokens {
  MiGlassTokens._();

  /// 背景高斯模糊 sigma（明暗通用）。
  ///
  /// 同源转发自 [MiTransparencyTokens.blurSigma]（统一透明配置），
  /// 保持旧引用兼容；新代码请直接取 [MiTransparencyTokens.blurSigma]。
  static const double blurSigma = MiTransparencyTokens.blurSigma;

  /// 玻璃体深色遮罩（rgba(20,20,20,0.63)）。
  static const Color scrim = Color.fromRGBO(20, 20, 20, 0.63);

  /// 透镜暗化层（~60% 内容透射）。
  static const Color lensShade = Color.fromRGBO(0, 0, 0, 0.40);

  /// 透镜白茶色调。
  static const Color lensTint = Color.fromRGBO(255, 255, 255, 0.118);

  /// 透镜内描边。
  static const Color lensStroke = Color.fromRGBO(255, 255, 255, 0.08);

  /// 玻璃体外缘高光。
  static const Color rim = Color.fromRGBO(255, 255, 255, 0.10);
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
    this.elevationShadow = const [],
  });

  /// 玻璃体遮罩（在透镜处开洞）；[scrimGradient] 非空时改按渐变绘制。
  final Color scrim;

  /// 玻璃体遮罩垂直渐变（可空 = 纯色 [scrim]；亮色实测上透下实）。
  final Gradient? scrimGradient;

  /// 透镜暗化层（贴在开洞处的最底层）。
  final Color lensShade;

  /// 透镜色调（叠在暗化层上，构成透镜玻璃体）；
  /// [lensTintGradient] 非空时改按渐变绘制。
  final Color lensTint;

  /// 透镜色调垂直渐变（可空 = 纯色 [lensTint]）。
  final Gradient? lensTintGradient;

  /// 透镜内描边（深色 0.08 实测；浅色真值为无描边=透明，见 [MiGlassPalette.light]）。
  final Color lensStroke;

  /// 玻璃体外缘高光。
  final Color rim;

  /// 玻璃体投影（浅色下可见；深色下为空，不产生任何绘制）。
  final List<BoxShadow> elevationShadow;

  /// 深色配方（视频实测，见 [MiGlassTokens]）。
  static const MiGlassPalette dark = MiGlassPalette(
    scrim: MiGlassTokens.scrim,
    lensShade: MiGlassTokens.lensShade,
    lensTint: MiGlassTokens.lensTint,
    lensStroke: MiGlassTokens.lensStroke,
    rim: MiGlassTokens.rim,
  );

  /// 浅色配方（亮色录屏真实玻璃实测 1220×2656，采样密度≈3.07）。
  ///
  /// 真实玻璃形态（区别于旧"白玻璃"近实白读数——那是白底上的表现）：
  ///  * 栏体半透明磨砂玻璃：垂直渐变遮罩 alpha 0.61→0.76→0.80（上→中→下），
  ///    色 #FBFBFB，透射模型 out = a·C + (1-a)·blurB（背后内容色彩透上来）；
  ///  * 选中胶囊是独立暖灰玻璃体（色 ≈#E6E6E7，alpha 0.66→0.78→0.82），
  ///    比栏体暗 ~13 级；lensShade 置全透明（无额外暗化）；
  ///  * 胶囊边缘**无描边**（录屏真值：218→205 干净亮度阶跃、无亮环）；
  ///    旧 lensStroke 白 0.30 系早期拟合虚构（帽形拟合本就不含边缘），
  ///    会在胶囊外沿形成白亮环、与间隙带连成一片，吃掉胶囊↔栏体间距的
  ///    可读性（明暗模式“内圈外圈相距”感知不一致的根因），2026-10-16 移除；
  ///  * 外缘纯白 #FFFFFF 高光（实测峰值 255）；
  ///  * 投影：下缘近处约 -8 级、~50px 内衰减完。
  static const MiGlassPalette light = MiGlassPalette(
    scrim: Color.fromRGBO(251, 251, 251, 0.76),
    scrimGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0, 0.5, 1],
      colors: [
        Color.fromRGBO(251, 251, 251, 0.61),
        Color.fromRGBO(251, 251, 251, 0.76),
        Color.fromRGBO(251, 251, 251, 0.80),
      ],
    ),
    lensShade: Color.fromRGBO(0, 0, 0, 0),
    lensTint: Color.fromRGBO(230, 230, 231, 0.78),
    lensTintGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [0, 0.5, 1],
      colors: [
        Color.fromRGBO(230, 230, 231, 0.66),
        Color.fromRGBO(230, 230, 231, 0.78),
        Color.fromRGBO(230, 230, 231, 0.82),
      ],
    ),
    lensStroke: Color.fromRGBO(255, 255, 255, 0),
    rim: Color.fromRGBO(255, 255, 255, 1.0),
    elevationShadow: [
      BoxShadow(color: Color(0x0F000000), blurRadius: 32, offset: Offset(0, 4)),
    ],
  );

  /// 按明暗模式取配方。
  static MiGlassPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;
}
