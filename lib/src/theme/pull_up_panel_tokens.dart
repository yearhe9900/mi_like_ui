import 'package:flutter/painting.dart';

import 'theme_mode.dart';

/// 弹出面板配色令牌（明暗双配方）。
///
/// **暗色为度量**（唤起录屏，1220×2656，`dp = px × 393 / 1220`）：面板平坦区
/// 采样 RGB(44,44,44) = #2C2C2C，不透明（面板压在纯黑页底上读数一致、列表
/// 文字不透底）。注意与弹框卡片 #242424 不同 —— 这是另一套系统面板的表面，
/// 比弹框亮一档。
///
/// **浅色为度量**（0.25× 慢速浅色素材实测 #FFFFFF）：与
/// `MiDialogPalette.light.surface` 同值。
///
/// 面板**无压暗遮罩**（度量：面板外页底像素不变）；**带轻投影**（浅色素材
/// 下缘外压暗 14 级，黑 @0.12、blur 14、下偏 4，见
/// [MiTransparencyTokens.panelShadow]；暗色黑底上不可分辨，推导同值）。
class MiPullUpPanelPalette {
  const MiPullUpPanelPalette({required this.surface});

  /// 面板填充（度量暗 #2C2C2C / 度量亮 #FFFFFF）。
  final Color surface;

  /// 暗色配方。
  static const MiPullUpPanelPalette dark = MiPullUpPanelPalette(
    surface: Color(0xFF2C2C2C),
  );

  /// 浅色配方。
  static const MiPullUpPanelPalette light = MiPullUpPanelPalette(
    surface: Color(0xFFFFFFFF),
  );

  /// 按明暗模式取配方。
  static MiPullUpPanelPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;
}
