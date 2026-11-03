import 'package:flutter/painting.dart';

/// `MiFloatingToolbar` 的几何规格。
///
/// **来源说明**：本库**没有悬浮工具栏的实机素材**（参考素材是主题商店 /
/// 设置页截图）。下列数值取自 `flutter_miuix` 的
/// `MiuixFloatingToolbarDefaults`（其源自 HyperOS `FloatingToolbar` 规格），
/// 属「参考实现值」；素材到位后应复核。
///
/// 取值口径：
///  * 外留白 12（横）/ 8（纵）：工具栏要和屏幕边缘拉开一档，否则「悬浮」
///    读成「贴边」；
///  * 圆角 50 —— 配常见 40…48 高的内容即**胶囊轮廓**（半径大于半高时按
///    胶囊口径画真半圆端头，见 `MiSquircle.addRect` 的胶囊例外）；
///  * 投影几何**固定**：blur 10、零偏移、零扩散；`showShadow` 只是开关，
///    不参与缩放（与源实现一致：它不是 elevation，改高度不会改投影）；
///  * 描边 0.75：细到不抢内容，又能把「表面」从同色的卡片里划出来。
class MiFloatingToolbarMetrics {
  MiFloatingToolbarMetrics._();

  /// 默认圆角（配合矮内容得到胶囊轮廓）。
  static const double cornerRadius = 50;

  /// 外留白。
  static const EdgeInsets outsidePadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  /// 描边宽。
  static const double dividerWidth = 0.75;

  /// 投影模糊半径（几何固定）。
  static const double shadowBlurRadius = 10;

  /// 投影偏移（零：工具栏四周同样厚）。
  static const Offset shadowOffset = Offset.zero;
}
