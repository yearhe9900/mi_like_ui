import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 底部导航栏 logo 合集（全部 像素级度量自参考视频/截图）。
///
/// Contents: the 4 tab icons + the FAB dot-grid glyph (theme-store videos),
/// the white plus glyph of the green action button ([PlusIconPainter],
/// phone-app screenshot 1220x378), the top-bar back chevron
/// ([BackChevronIconPainter]) with its row-tail mirror
/// ([ForwardChevronIconPainter], 推导) and the vertical three-dot "more" glyph
/// ([MoreVerticalIconPainter], 推导值).
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

/// 浮动圆钮图标 —— 3×3 点阵（九宫格）。
///
/// 规格（设计度量）：墨迹 56×56px、点径 12px、点距 22.3px（绿圆 ⌀171px
/// 素材），归一到 100 单位高即点径 21、点距 39.1，墨迹铺满 100 单位方。
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

/// 顶栏返回箭头「‹」。
///
/// 规格（设计度量，3.104 px/dp）：
///  * 墨迹包围盒 36×66px = 11.6×21.3dp；两臂 45°；
///  * 笔画横切 9px → 垂直笔宽 9·sin45° = 6.36px = 2.05dp；
///  * 端头与顶点均为圆角（圆角顶点墨左 = 顶点 x − 笔宽/2）；
///  * 中心线反解：墨高 = 2L + w、墨宽 = L + w（L = 臂垂直半跨）⇒
///    L = 9.63dp，墨盒 11.68×21.31dp。
///
/// 归一到 100 单位高：笔宽 9.624、顶点 (4.812, 50)、臂端
/// (50, 4.812)/(50, 95.188)。建议配 [MiTopBarMetrics.chevronWidth] /
/// [MiTopBarMetrics.chevronHeight]（即该墨盒）使用。
/// 行尾前进箭头「›」见 [ForwardChevronIconPainter]（本图的水平镜像）。
class BackChevronIconPainter extends CustomPainter {
  BackChevronIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // ink bbox x: 0..54.812 -> center 27.406
    _fit(canvas, size, 27.406);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.624
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(50, 4.812)
        ..lineTo(4.812, 50)
        ..lineTo(50, 95.188),
      p,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BackChevronIconPainter old) => old.color != color;
}

/// 行尾前进箭头「›」—— [BackChevronIconPainter] 的水平镜像（**推导值**：
/// 同一套度量只是朝向相反）。
///
/// 墨盒同为 11.68×21.31dp（归一 100 单位高、笔宽 9.624、两臂 45°）：
/// 顶点 (50, 50)、臂端 (4.812, 4.812)/(4.812, 95.188)，墨中心 x = 27.406。
/// 用于列表行的「可进入」尾饰（如设置页风格行）。
class ForwardChevronIconPainter extends CustomPainter {
  ForwardChevronIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // ink bbox x: 0..54.812 -> center 27.406（与返回箭头同盒，仅朝向相反）
    _fit(canvas, size, 27.406);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.624
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(4.812, 4.812)
        ..lineTo(50, 50)
        ..lineTo(4.812, 95.188),
      p,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ForwardChevronIconPainter old) =>
      old.color != color;
}

/// 加号 logo —— 绿色圆钮内的白色圆角加号。
///
/// 规格（设计度量，绿圆 ⌀171px）：加号墨迹 62×62px、笔宽 8.7px、端头
/// 圆角约 2px、纯白，与圆心同心。归一到 100 单位见方即笔宽 14、圆角 3.2；
/// 配 [MiGlassNavFab] 使用时建议 child 尺寸约 20dp。
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

/// 更多 logo —— 竖向三点（⋮，「更多操作」语义）。
///
/// 规格（**推导值**，无参考素材；沿用 [GridDotsIconPainter] 的点阵语言）：
/// 点径 21（同九宫格点径）、三点等距竖排，首末点外缘正好铺满 100 单位高
/// （点距 = (100 − 21) / 2 = 39.5）、x 居中于 50 —— 墨宽即点径，呈窄竖条。
/// 与 [GridDotsIconPainter] 同尺寸使用（如 18.2dp）即同档视觉大小。
class MoreVerticalIconPainter extends CustomPainter {
  MoreVerticalIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // ink bbox: width = 点径、高铺满 100 单位，x 中心 50
    _fit(canvas, size, 50);
    final p = Paint()..color = color;
    const r = 10.5;
    const step = 39.5;
    for (final dy in const [-step, 0.0, step]) {
      canvas.drawCircle(Offset(50, 50 + dy), r, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MoreVerticalIconPainter old) => old.color != color;
}
