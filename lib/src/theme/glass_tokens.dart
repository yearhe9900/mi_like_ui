import 'package:flutter/painting.dart';

import 'theme_mode.dart';

/// 磨砂玻璃材质配方 token（视频/截图实测，所有玻璃类组件共用）。
///
/// 实测透射模型（深色）：遮罩 `scrim` 在干净列上满足 out = 0.37·in + 12.6；
/// 高亮胶囊是"透镜"（在遮罩上开洞 + 暗化 + 白茶色），不是纯色块。
///
/// 浅色实测（881×1920 亮色截图，2.24px/dp）：遮罩满足
/// out = 0.18·in + 187.4（= rgba(228,228,228,0.82)，透射更低），
/// 透镜同样"开洞 + 轻微暗化 + 暖白茶色"但仅比遮罩暗 2~5 级；
/// 外缘是近实白 1px 高光（深色下仅 10% 白）；栏体带下投影
/// （下缘 2px 处 ≈9% 黑，25px 内衰减完，上缘仅 ≈4%）。
class MiGlassTokens {
  MiGlassTokens._();

  /// 背景高斯模糊 sigma（明暗通用）。
  static const double blurSigma = 28;

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
    this.elevationShadow = const [],
  });

  /// 玻璃体遮罩（在透镜处开洞）。
  final Color scrim;

  /// 透镜暗化层（贴在开洞处的最底层）。
  final Color lensShade;

  /// 透镜色调（叠在暗化层上，构成透镜玻璃体）。
  final Color lensTint;

  /// 透镜内描边。
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

  /// 浅色配方（亮色截图实测）。
  ///
  /// 透镜：开洞后 lensShade 黑 5% + 暖白茶 lensTint 78% ⇒
  /// out = 0.209·in + (181,179,176)，实测点 in=100→202 / 158→214 / 243→230。
  static const MiGlassPalette light = MiGlassPalette(
    scrim: Color.fromRGBO(228, 228, 228, 0.82),
    lensShade: Color.fromRGBO(0, 0, 0, 0.05),
    lensTint: Color.fromRGBO(232, 230, 226, 0.78),
    lensStroke: Color.fromRGBO(255, 255, 255, 0.55),
    rim: Color.fromRGBO(255, 255, 255, 0.90),
    elevationShadow: [
      BoxShadow(color: Color(0x2E000000), blurRadius: 18, offset: Offset(0, 6)),
    ],
  );

  /// 按明暗模式取配方。
  static MiGlassPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;
}
