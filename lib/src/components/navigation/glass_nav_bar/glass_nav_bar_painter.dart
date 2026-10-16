import 'package:flutter/material.dart';

import '../../../theme/glass_tokens.dart';

/// Paints the scrim (with a stadium-shaped hole where the pill is),
/// the pill glass lens and the subtle rim highlights.
///
/// Colors come from a [MiGlassPalette] so the same geometry renders in
/// dark and light mode; the default is the measured dark recipe.
///
/// 框架内部实现 —— 刻意不从 `mi_like_ui.dart` 导出，不承诺 API 稳定。
class GlassBarPainter extends CustomPainter {
  GlassBarPainter({
    required this.pillCenterX,
    required this.pillWidth,
    required this.pillHeight,
    this.palette = MiGlassPalette.dark,
  });

  final double pillCenterX;
  final double pillWidth;
  final double pillHeight;
  final MiGlassPalette palette;

  /// 玻璃层画笔：渐变配方（亮色）按栏体整体高度着色，纯色配方（深色）直取。
  static Paint _layerPaint(Gradient? gradient, Color color, Size size) =>
      gradient == null
          ? (Paint()..color = color)
          : (Paint()..shader = gradient.createShader(Offset.zero & size));

  @override
  void paint(Canvas canvas, Size size) {
    final barR = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    final pillRect = Rect.fromCenter(
      center: Offset(pillCenterX, size.height / 2),
      width: pillWidth,
      height: pillHeight,
    );
    final pillR = RRect.fromRectAndRadius(
      pillRect,
      Radius.circular(pillHeight / 2),
    );

    // 1) scrim with a hole where the pill sits (the pill is a lens
    //    through the scrim, which is why it brightens with the content)
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRRect(barR),
      Path()..addRRect(pillR),
    );
    canvas.drawPath(scrim, _layerPaint(palette.scrimGradient, palette.scrim, size));

    // 2) pill lens: shade + tint over the hole (dark: ~60% content
    //    transmission, light: gradient warm-gray glass body with no shade)
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

    // 3) bar rim highlight
    canvas.drawRRect(
      barR,
      Paint()
        ..color = palette.rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant GlassBarPainter old) =>
      old.pillCenterX != pillCenterX ||
      old.pillWidth != pillWidth ||
      old.pillHeight != pillHeight ||
      old.palette != palette;
}
