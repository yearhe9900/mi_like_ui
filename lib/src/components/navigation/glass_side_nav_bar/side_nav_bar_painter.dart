import 'package:flutter/material.dart';

import '../../../theme/glass_tokens.dart';
import 'side_nav_bar_metrics.dart';

/// 纵向玻璃侧栏的绘制：栏体遮罩（在选中胶囊处开洞）+ 胶囊透镜 + 外缘高光。
///
/// 这是 `GlassBarPainter`（底部栏）的**同配方转轴版**：配方（[MiGlassPalette]
/// 的遮罩 / 渐变 / 透镜暗化 / 色调 / 描边 / 高光）与层序完全一致，只是胶囊
/// 沿**纵轴**移动、栏体圆角取 [MiGlassSideNavMetrics.railRadius]
/// （= 内圈胶囊圆角 + 内边距，内外圈四周等距）。
///
/// 框架内部实现 —— 刻意不从 `mi_like_ui.dart` 导出，不承诺 API 稳定。
class SideNavPainter extends CustomPainter {
  SideNavPainter({
    required this.pillCenterY,
    required this.pillWidth,
    required this.pillHeight,
    this.palette = MiGlassPalette.dark,
  });

  /// 选中胶囊的纵向中心（相对栏体顶端）。
  final double pillCenterY;

  final double pillWidth;
  final double pillHeight;
  final MiGlassPalette palette;

  /// 与 `GlassBarPainter._layerPaint` 同语义：渐变配方（亮色）按栏体整体
  /// 着色，纯色配方（深色）直取。
  static Paint _layerPaint(Gradient? gradient, Color color, Size size) =>
      gradient == null
          ? (Paint()..color = color)
          : (Paint()..shader = gradient.createShader(Offset.zero & size));

  @override
  void paint(Canvas canvas, Size size) {
    // 栏体（外圈）：圆角 = 内圈胶囊圆角 + 内边距（**以内圈为准等距外扩**，
    // 见 MiGlassSideNavMetrics.railRadius）——端头圆弧与胶囊顶角圆弧同心，
    // 内外圈间距四周恒 6.6。曾自算 `size.width / 2`（stadium）：与内圈
    // 不同心，肩部间距会收缩到 0（两圆弧相交、胶囊被裁）。
    final railR = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(MiGlassSideNavMetrics.railRadius),
    );
    final pillRect = Rect.fromCenter(
      center: Offset(size.width / 2, pillCenterY),
      width: pillWidth,
      height: pillHeight,
    );
    // 胶囊同样按短轴（高度）取全圆角 —— 带宽 > 高的扁胶囊，与底部栏一致。
    final pillR = RRect.fromRectAndRadius(
      pillRect,
      Radius.circular(pillHeight.clamp(0, pillWidth) / 2),
    );

    // 1) 遮罩在胶囊处开洞（胶囊是透镜，会随背后内容变亮）
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRRect(railR),
      Path()..addRRect(pillR),
    );
    canvas.drawPath(scrim, _layerPaint(palette.scrimGradient, palette.scrim, size));

    // 2) 胶囊透镜：暗化 + 色调（深色 ≈60% 透射；浅色为渐变暖灰玻璃体）
    canvas.drawRRect(pillR, Paint()..color = palette.lensShade);
    canvas.drawRRect(
      pillR,
      _layerPaint(palette.lensTintGradient, palette.lensTint, size),
    );
    canvas.drawRRect(
      pillR,
      Paint()
        ..color = palette.lensStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 3) 栏体外缘高光
    canvas.drawRRect(
      railR,
      Paint()
        ..color = palette.rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant SideNavPainter old) =>
      old.pillCenterY != pillCenterY ||
      old.pillWidth != pillWidth ||
      old.pillHeight != pillHeight ||
      old.palette != palette;
}
