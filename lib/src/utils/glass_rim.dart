import 'dart:ui';

import 'package:flutter/rendering.dart';

/// 玻璃片**内缘亮边**（「边缘逐渐变亮」的受光边）：贴形状边缘内侧约 1dp
/// 的白色亮边、向内渐变收尾，外侧仅微溢 ~1px。
///
/// 素材边缘细扫（1220×2656 明暗双素材）：亮边峰值比玻璃体内部高 +25…38
/// 级、1…1.3dp 内回落，沿周长均匀；颜色与 alpha 见
/// `MiTransparencyTokens.surfaceRimFor`。
///
/// 实现：沿形状边界描一圈**柔边**笔画（[Paint.maskFilter] 轻微高斯），
/// 宽度 1.1dp —— 峰值落在边界上、两侧各羽化 ~0.5dp，与实测剖面
/// （外 1px 微溢 → 峰 2px → 内 1…2px 回落）一致。
class MiGlassRimPainter extends CustomPainter {
  MiGlassRimPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.1,
  });

  /// 亮边颜色（含 alpha，取自 `MiTransparencyTokens.surfaceRimFor`）。
  final Color color;

  /// stadium 圆角半径（dp；胶囊类取高度一半）。
  final double radius;

  /// 笔画宽（dp）。
  final double strokeWidth;

  /// 柔边羽化 σ（dp）；`MaskFilter.blur` 随画布变换走逻辑坐标，无需按 dpr 换算。
  static const double feather = 0.5;

  /// 在 [rrect] 边界上描一圈亮边（多胶囊条等复用同一套笔刷参数）。
  static void drawRim(
    Canvas canvas,
    RRect rrect,
    Color color, {
    double strokeWidth = 1.1,
  }) {
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color
        ..isAntiAlias = true
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, feather),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    drawRim(
      canvas,
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(strokeWidth / 2),
        Radius.circular(radius),
      ),
      color,
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool shouldRepaint(MiGlassRimPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}
