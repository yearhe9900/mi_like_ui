import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 底部导航栏 logo 合集（全部 1:1 实测自参考视频/截图）。
///
/// Contents: the 4 tab icons + the FAB dot-grid glyph (theme-store videos),
/// and the white plus glyph of the green action button ([PlusIconPainter],
/// phone-app screenshot 1220x378).
///
/// Each painter draws inside a normalized coordinate system that is
/// 100 units tall; the natural width follows the measured pixel aspect
/// ratio so every icon keeps its exact silhouette:
///   roller 53x71 px, grid+sparkle 65x65 px, cards+star 68x72 px,
///   smiley+beret 68x76 px, plus 62x62 px.
///
/// [inkCenterX] passed to [_fit] is the horizontal center of the drawing's
/// ink bbox in the normalized frame, so every icon lands dead-centre in its
/// box — in the reference video each icon is exactly co-centered with its
/// label (measured icon/label ink centers match within 0.5 px).
void _fit(Canvas canvas, Size size, double inkCenterX) {
  final s = size.height / 100;
  canvas.save();
  canvas.translate(size.width / 2 - inkCenterX * s, 0);
  canvas.scale(s);
}

/// Concave 4-point "sparkle" star (✦) with points up/down/left/right.
Path _sparkle(Offset c, double r) {
  final k = r * 0.14;
  return Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
    ..close();
}

/// 首页 — paint roller (roller sleeve on top, stem, hanging paint drip).
class RollerIconPainter extends CustomPainter {
  RollerIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // ink bbox x: 12.7..87.3 (cap + sleeve span) -> center 50
    _fit(canvas, size, 50);
    final p = Paint()..color = color;

    // thin cap strip on top of the roller
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(12.7, 0, 74.6, 11), const Radius.circular(5.5)),
      p,
    );
    // roller sleeve
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(12.7, 15, 74.6, 25), const Radius.circular(9)),
      p,
    );
    // handle stem
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(44.5, 37, 11, 24), const Radius.circular(3)),
      p,
    );
    // paint drip (teardrop)
    final drop = Path()
      ..moveTo(50, 56)
      ..cubicTo(55, 69, 63, 75, 63, 86)
      ..arcToPoint(const Offset(37, 86),
          radius: const Radius.circular(13), rotation: 0, largeArc: true, clockwise: true)
      ..cubicTo(37, 75, 45, 69, 50, 56)
      ..close();
    canvas.drawPath(drop, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RollerIconPainter old) => old.color != color;
}

/// 分类 — 2x2 grid where the top-right cell is a sparkle.
class GridSparkleIconPainter extends CustomPainter {
  GridSparkleIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // ink bbox x: 0..102.25 (grid cells + sparkle overshoot) -> center 51.125
    _fit(canvas, size, 51.125);
    final p = Paint()..color = color;
    const side = 41.5;
    const radius = Radius.circular(12.3);
    for (final o in const [Offset(0, 0), Offset(0, 58.5), Offset(58.5, 58.5)]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, side, side), radius), p);
    }
    canvas.drawPath(_sparkle(const Offset(79.25, 20.75), 23), p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GridSparkleIconPainter old) => old.color != color;
}

/// 每日精选 — two overlapping tilted cards, front card has a star cutout.
class CardsStarIconPainter extends CustomPainter {
  CardsStarIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // ink bbox x: 10.31..93.51 (rotated rounded cards) -> center 51.91
    _fit(canvas, size, 51.91);
    final p = Paint()..color = color;

    // back card, tilted clockwise, peeks out on the right
    canvas.save();
    canvas.translate(62, 48);
    canvas.rotate(15 * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-27, -34, 54, 68), const Radius.circular(15)),
      p,
    );
    canvas.restore();

    // front card, tilted counter-clockwise, star hole via xor
    final card = Path()
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-28, -35, 56, 70), const Radius.circular(16)));
    final front = Path.combine(PathOperation.xor, card, _sparkle(Offset.zero, 17));
    canvas.save();
    canvas.translate(42, 52);
    canvas.rotate(-12 * math.pi / 180);
    canvas.drawPath(front, p);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CardsStarIconPainter old) => old.color != color;
}

/// 圆形按钮 — 3x3 dot matrix (九宫格)，1:1 复刻自圆形按钮视频。
///
/// 实测（1220px 屏，圆钮 ⌀171px）：墨迹 56x56px、点径 12px、点距 22.3px，
/// 归一到 100 单位高即点径 21、点距 39.1，墨迹正方形恰好铺满 100 单位。
class GridDotsIconPainter extends CustomPainter {
  GridDotsIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // ink bbox is exactly the 100x100 unit square -> center 50
    _fit(canvas, size, 50);
    final p = Paint()..color = color;
    const r = 10.5;
    const step = 39.1;
    for (final dy in const [-step, 0.0, step]) {
      for (final dx in const [-step, 0.0, step]) {
        canvas.drawCircle(Offset(50 + dx, 50 + dy), r, p);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GridDotsIconPainter old) => old.color != color;
}

/// 我的 — round smiley face wearing a tilted beret.
class SmileyBeretIconPainter extends CustomPainter {
  SmileyBeretIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // ink bbox x: 9..81 (face circle; beret/nub inside) -> center 45
    _fit(canvas, size, 45);
    final p = Paint()..color = color;

    // face: circle with eyes + open smile punched out
    final face = Path()..addOval(Rect.fromCircle(center: const Offset(45, 62), radius: 36));
    final eyes = Path()
      ..addOval(Rect.fromCircle(center: const Offset(32, 55), radius: 6.5))
      ..addOval(Rect.fromCircle(center: const Offset(58, 55), radius: 6.5));
    final mouth = Path()
      ..moveTo(28, 70)
      ..quadraticBezierTo(45, 92, 62, 70)
      ..close();
    var facePath = Path.combine(PathOperation.difference, face, eyes);
    facePath = Path.combine(PathOperation.difference, facePath, mouth);
    canvas.drawPath(facePath, p);

    // beret: tilted stadium across the top of the head
    canvas.save();
    canvas.translate(46, 22);
    canvas.rotate(-18 * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-31, -15, 62, 30), const Radius.circular(15)),
      p,
    );
    canvas.restore();
    // beret nub
    canvas.drawCircle(const Offset(72, 9), 5.5, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SmileyBeretIconPainter old) => old.color != color;
}

/// 加号 logo —— 绿色圆钮内的白色圆角加号（电话 App 截图 1220x378 实测）。
///
/// 实测（绿圆 ⌀171px，即亮色 FAB 绿 #66CB61）：加号墨迹 62x62px、
/// 笔宽 8.7px、端头圆角约 2px、纯白 #FFFFFF，与圆心同心（±0.5px）。
/// 归一到 100 单位见方即笔宽 14、圆角 3.2；配 [MiGlassNavFab] 使用时
/// 建议 child 尺寸约 20dp（= 62px ÷ 3.09px/dp）。
class PlusIconPainter extends CustomPainter {
  PlusIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // ink bbox is exactly the 100x100 unit square -> center 50
    _fit(canvas, size, 50);
    final p = Paint()..color = color;
    const stroke = 14.0;
    const radius = Radius.circular(3.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(50 - stroke / 2, 0, stroke, 100), radius),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 50 - stroke / 2, 100, stroke), radius),
      p,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PlusIconPainter old) => old.color != color;
}
