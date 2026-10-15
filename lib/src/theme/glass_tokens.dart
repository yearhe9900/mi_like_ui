import 'package:flutter/painting.dart';

import 'theme_mode.dart';

/// 磨砂玻璃材质配方 token（视频/截图实测，所有玻璃类组件共用）。
///
/// 实测透射模型（深色）：遮罩 `scrim` 在干净列上满足 out = 0.37·in + 12.6；
/// 高亮胶囊是"透镜"（在遮罩上开洞 + 暗化 + 白茶色），不是纯色块。
///
/// 浅色为"白玻璃"形态（亮色参考图 1220×308 实测）：栏体近实白
/// #FDFDFD 平坦（压过背后内容）、选中胶囊是比栏体暗 ~16 级的灰实色
/// 胶囊 #ECECEC~#EDEDED、外缘纯白 1~2px 高光、投影极浅（下缘仅比
/// 底色暗 2~5 级、~15px 内衰减完）。明暗两套配方见 [MiGlassPalette]。
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

  /// 浅色配方（亮色参考图实测 1220×308 采样）。
  ///
  /// 白玻璃形态（区别于旧暖透镜配方）：
  ///  * 栏体近实白 #FDFDFD 平坦（压过背后文字，scrim 0.98 近不透明）；
  ///  * 选中胶囊是灰实色胶囊 #ECECEC~#EDEDED（比栏体暗 ~16 级），
  ///    不是"开洞透镜"——lensTint 近不透明灰直接给出平坦灰胶囊；
  ///  * 外缘纯白 #FFFFFF 1~2px 高光；
  ///  * 投影极浅：下缘仅比底色暗 2~5 级、~15px 内衰减完。
  static const MiGlassPalette light = MiGlassPalette(
    scrim: Color.fromRGBO(253, 253, 253, 0.98),
    lensShade: Color.fromRGBO(0, 0, 0, 0.05),
    lensTint: Color.fromRGBO(236, 236, 236, 0.98),
    lensStroke: Color.fromRGBO(255, 255, 255, 0.30),
    rim: Color.fromRGBO(255, 255, 255, 1.0),
    elevationShadow: [
      BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );

  /// 按明暗模式取配方。
  static MiGlassPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;
}
