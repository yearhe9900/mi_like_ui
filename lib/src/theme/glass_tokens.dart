import 'package:flutter/painting.dart';

/// 磨砂玻璃材质配方 token（视频实测，所有玻璃类组件共用）。
///
/// 实测透射模型：遮罩 `scrim` 在干净列上满足 out = 0.37·in + 12.6；
/// 高亮胶囊是"透镜"（在遮罩上开洞 + 暗化 + 白茶色），不是纯色块。
class MiGlassTokens {
  MiGlassTokens._();

  /// 背景高斯模糊 sigma。
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
