import 'package:flutter/material.dart';

import '../../../theme/glass_tokens.dart';

/// Paints the dark scrim (with a stadium-shaped hole where the pill is),
/// the pill glass lens and the subtle rim highlights.
///
/// 框架内部实现 —— 刻意不从 `mi_like_ui.dart` 导出，不承诺 API 稳定。
class GlassBarPainter extends CustomPainter {
  GlassBarPainter({
    required this.pillCenterX,
    required this.pillWidth,
    required this.pillHeight,
  });

  final double pillCenterX;
  final double pillWidth;
  final double pillHeight;

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

    // 1) dark scrim with a hole where the pill sits (the pill is a lens
    //    through the scrim, which is why it brightens with the content)
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRRect(barR),
      Path()..addRRect(pillR),
    );
    canvas.drawPath(scrim, Paint()..color = MiGlassTokens.scrim);

    // 2) pill lens: ~60% content transmission + small white tint
    canvas.drawRRect(pillR, Paint()..color = MiGlassTokens.lensShade);
    canvas.drawRRect(pillR, Paint()..color = MiGlassTokens.lensTint);
    canvas.drawRRect(
      pillR,
      Paint()
        ..color = MiGlassTokens.lensStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 3) bar rim highlight
    canvas.drawRRect(
      barR,
      Paint()
        ..color = MiGlassTokens.rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant GlassBarPainter old) =>
      old.pillCenterX != pillCenterX ||
      old.pillWidth != pillWidth ||
      old.pillHeight != pillHeight;
}
