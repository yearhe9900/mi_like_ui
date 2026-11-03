import 'package:flutter/material.dart';

import 'checkbox_metrics.dart';

/// 复选框圆底 + 勾号画笔（三态连续变形，绘制细节见 [MiCheckboxMetrics]）。
///
/// 一次 `drawCircle` + 一次 `drawPath` —— 不做分层 / 离屏，压在含磨砂的
/// 页面里也只是两次普通绘制。
class MiCheckboxPainter extends CustomPainter {
  const MiCheckboxPainter({
    required this.fill,
    required this.checkColor,
    required this.alpha,
    required this.trim,
    required this.indeterminate,
  });

  /// 圆底填充（按压叠色已在组件层预合成，画笔只负责画）。
  final Color fill;

  /// 勾号墨色。
  final Color checkColor;

  /// 勾号整体不透明度 0…1（勾号先显形、再被 trim 划完）。
  final double alpha;

  /// trim 进度 0…1（0 = 收起态区间，1 = 展开态区间）。
  final double trim;

  /// 半选进度 0…1（1 = 三个控制点收拢成水平横杠）。
  final double indeterminate;

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      size.width / 2,
      Paint()..color = fill,
    );
    if (alpha <= 0) return;

    // 视口坐标 → 画布坐标（等比映射，改直径不用重排路径点）。
    const viewport = MiCheckboxMetrics.checkViewport;
    Offset map(Offset p) => Offset(
          center.dx + (p.dx - viewport / 2) / viewport * size.width,
          center.dy + (p.dy - viewport / 2) / viewport * size.height,
        );

    // 半选：三点向中心 y 收拢 → 横杠；折点的 x 也收向中心，
    // 否则横杠会带着折角的斜向量。
    final start = Offset(
      map(MiCheckboxMetrics.checkStart).dx,
      _lerp(map(MiCheckboxMetrics.checkStart).dy, center.dy, indeterminate),
    );
    final middle = Offset(
      _lerp(map(MiCheckboxMetrics.checkMiddle).dx, center.dx, indeterminate),
      _lerp(map(MiCheckboxMetrics.checkMiddle).dy, center.dy, indeterminate),
    );
    final end = Offset(
      map(MiCheckboxMetrics.checkEnd).dx,
      _lerp(map(MiCheckboxMetrics.checkEnd).dy, center.dy, indeterminate),
    );

    final paint = Paint()
      ..color = checkColor.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * MiCheckboxMetrics.checkStrokeRatio
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // trim 区间 → 沿「起点 → 折点 → 终点」两段折线的可见长度区间。
    final trimStart = _lerp(
      MiCheckboxMetrics.trimCollapsed,
      MiCheckboxMetrics.trimStart,
      trim,
    );
    final trimEnd = _lerp(
      MiCheckboxMetrics.trimCollapsed,
      MiCheckboxMetrics.trimEnd,
      trim,
    );
    final firstLength = (middle - start).distance;
    final secondLength = (end - middle).distance;
    final total = firstLength + secondLength;
    final from = total * trimStart;
    final to = total * trimEnd;

    final path = Path();
    if (to > 0 && from < firstLength) {
      final a = (from / firstLength).clamp(0.0, 1.0);
      final b = (to / firstLength).clamp(0.0, 1.0);
      path
        ..moveTo(
          start.dx + (middle.dx - start.dx) * a,
          start.dy + (middle.dy - start.dy) * a,
        )
        ..lineTo(
          start.dx + (middle.dx - start.dx) * b,
          start.dy + (middle.dy - start.dy) * b,
        );
    }
    if (to > firstLength) {
      final a = ((from - firstLength) / secondLength).clamp(0.0, 1.0);
      final b = ((to - firstLength) / secondLength).clamp(0.0, 1.0);
      final p1 = Offset(
        middle.dx + (end.dx - middle.dx) * a,
        middle.dy + (end.dy - middle.dy) * a,
      );
      final p2 = Offset(
        middle.dx + (end.dx - middle.dx) * b,
        middle.dy + (end.dy - middle.dy) * b,
      );
      if (from < firstLength) {
        path.lineTo(p2.dx, p2.dy);
      } else {
        path
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(MiCheckboxPainter oldDelegate) =>
      fill != oldDelegate.fill ||
      checkColor != oldDelegate.checkColor ||
      alpha != oldDelegate.alpha ||
      trim != oldDelegate.trim ||
      indeterminate != oldDelegate.indeterminate;
}
