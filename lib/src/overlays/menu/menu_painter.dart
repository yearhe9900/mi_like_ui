import 'package:flutter/rendering.dart';

import '../../foundations/squircle.dart';
import 'menu_metrics.dart';

/// 菜单内部矢量字形：勾号、右向箭头（级联 / 返回上级）、上下双向箭头
/// （触发行的「可展开」尾饰）。
///
/// 三条路径的坐标数据取自 `flutter_miuix`（Apache-2.0）的
/// `miuix_dropdown.dart`，其上游为 compose-miuix 的 `icon/basic/*.kt`
/// `ImageVector`（evenOdd 填充、单色 tint）。本库只保留「路径 + 视口 +
/// 按目标色填充」的最小能力 —— 没有透明度、没有描边，颜色由调用方从
/// 菜单配色令牌取。
class MiMenuCheckPainter extends CustomPainter {
  const MiMenuCheckPainter(this.color);

  /// 勾号墨色（未选中时传零 Alpha 色即「不画」）。
  final Color color;

  static const Size viewport = Size(56, 56);

  @override
  void paint(Canvas canvas, Size size) {
    _paintPath(canvas, size, _checkPath, viewport, color);
  }

  @override
  bool shouldRepaint(MiMenuCheckPainter oldDelegate) => oldDelegate.color != color;
}

/// 右向箭头「›」：级联项尾饰 / 子菜单首行（返回上级）。
///
/// [back] 为 true 时按**返回**语义取水平镜像（左向「‹」，几何是同一路径的
/// 镜像，与 `BackChevronIconPainter` / `ForwardChevronIconPainter` 同一做派）。
/// 参考实现给子菜单首行复用了右向箭头，这里按语义改左向 —— **推导值**，
/// 只改朝向不改墨盒。
class MiMenuChevronPainter extends CustomPainter {
  const MiMenuChevronPainter(this.color, {this.back = false});

  final Color color;

  /// 是否画左向（返回）箭头。
  final bool back;

  @override
  void paint(Canvas canvas, Size size) {
    _paintPath(
      canvas,
      size,
      _chevronPath,
      MiMenuMetrics.arrowSize,
      color,
      mirror: back,
    );
  }

  @override
  bool shouldRepaint(MiMenuChevronPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.back != back;
}

/// 上下双向箭头「⌃⌄」：偏好行尾饰，表示「点开是一个列表」。
class MiMenuArrowPainter extends CustomPainter {
  const MiMenuArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    _paintPath(canvas, size, _arrowUpDownPath, MiMenuMetrics.arrowSize, color);
  }

  @override
  bool shouldRepaint(MiMenuArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 面板展开时的**揭示裁剪**：按进度只露出面板的一段高度，锚点侧先出现、
/// 向反方向长开（下方展开从顶缘长出、上方展开从底缘长出）。
///
/// 与缩放叠加构成参考实现的展开观感（`0.15 → 1` 缩放 + 单向揭示）；裁剪
/// 边沿用连续圆角，进度小时退化成胶囊端头，不会出现直角切边。
class MiMenuRevealClipper extends CustomClipper<Path> {
  const MiMenuRevealClipper({
    required this.progress,
    required this.fromBottom,
    this.cornerRadius = MiMenuMetrics.cornerRadius,
  });

  /// 揭示进度 0…1（弹簧可能过冲，这里只取 0…1）。
  final double progress;

  /// true = 从底缘向上长出（面板开在锚点上方）。
  final bool fromBottom;

  /// 圆角半径（与被裁面板一致）。
  final double cornerRadius;

  @override
  Path getClip(Size size) {
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0 || size.isEmpty) return Path();
    final visible = size.height * t;
    final top = fromBottom ? size.height - visible : 0.0;
    return MiSquircle.pathOf(
      Rect.fromLTWH(0, top, size.width, visible),
      cornerRadius,
    );
  }

  @override
  bool shouldReclip(MiMenuRevealClipper oldClipper) =>
      oldClipper.progress != progress ||
      oldClipper.fromBottom != fromBottom ||
      oldClipper.cornerRadius != cornerRadius;
}

/// 把视口路径缩放到 [size] 并按 [color] 实心填充（[mirror] = 水平镜像）。
void _paintPath(
  Canvas canvas,
  Size size,
  Path path,
  Size viewport,
  Color color, {
  bool mirror = false,
}) {
  if (size.isEmpty || color.a == 0) return;
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;
  canvas
    ..save()
    ..translate(mirror ? size.width : 0, 0);
  if (mirror) canvas.scale(-1, 1);
  canvas
    ..scale(size.width / viewport.width, size.height / viewport.height)
    ..drawPath(path, paint)
    ..restore();
}

/// 勾号路径（视口 56×56，evenOdd）。
final Path _checkPath = Path()
  ..fillType = PathFillType.evenOdd
  ..moveTo(46.8171, 18.1514)
  ..cubicTo(48.0496, 16.6624, 47.8417, 14.4561, 46.3527, 13.2235)
  ..cubicTo(44.8636, 11.991, 42.6573, 12.1989, 41.4247, 13.6879)
  ..lineTo(22.9535, 36.0031)
  ..lineTo(13.4007, 26.4502)
  ..cubicTo(12.0338, 25.0833, 9.8177, 25.0833, 8.4509, 26.4502)
  ..cubicTo(7.0841, 27.817, 7.0841, 30.0331, 8.4509, 31.3999)
  ..lineTo(20.7077, 43.6567)
  ..cubicTo(21.7243, 44.6733, 23.2108, 44.9338, 24.4682, 44.4381)
  ..cubicTo(25.0159, 44.2302, 25.5189, 43.8818, 25.9192, 43.3982)
  ..lineTo(46.8171, 18.1514)
  ..close();

/// 右向箭头「›」（视口 10×16，evenOdd）。
final Path _chevronPath = Path()
  ..fillType = PathFillType.evenOdd
  ..moveTo(1.65, 1.469)
  ..cubicTo(1.929, 1.19, 2.381, 1.19, 2.66, 1.469)
  ..lineTo(8.721, 7.53)
  ..cubicTo(9.0, 7.809, 9.0, 8.261, 8.721, 8.54)
  ..lineTo(2.66, 14.601)
  ..cubicTo(2.381, 14.88, 1.929, 14.88, 1.65, 14.601)
  ..cubicTo(1.371, 14.322, 1.371, 13.87, 1.65, 13.591)
  ..lineTo(7.205, 8.035)
  ..lineTo(1.65, 2.479)
  ..cubicTo(1.371, 2.2, 1.371, 1.748, 1.65, 1.469)
  ..close();

/// 上下双向箭头（视口 10×16，evenOdd）。
final Path _arrowUpDownPath = Path()
  ..fillType = PathFillType.evenOdd
  ..moveTo(2.397, 4.7384)
  ..lineTo(4.5688, 2.5665)
  ..lineTo(5.0075, 2.1278)
  ..lineTo(5.4266, 2.5469)
  ..lineTo(7.5985, 4.7187)
  ..lineTo(8.531, 5.6512)
  ..cubicTo(8.8282, 5.9485, 9.3102, 5.9485, 9.6075, 5.6512)
  ..cubicTo(9.9047, 5.354, 9.9047, 4.872, 9.6075, 4.5747)
  ..lineTo(8.675, 3.6423)
  ..lineTo(6.5031, 1.4704)
  ..lineTo(5.5706, 0.5379)
  ..cubicTo(5.3595, 0.3267, 5.0551, 0.2656, 4.7899, 0.3544)
  ..cubicTo(4.6561, 0.3855, 4.5291, 0.4532, 4.4248, 0.5575)
  ..lineTo(3.4924, 1.49)
  ..lineTo(1.3205, 3.6619)
  ..lineTo(0.388, 4.5943)
  ..cubicTo(0.0907, 4.8916, 0.0907, 5.3736, 0.388, 5.6708)
  ..cubicTo(0.6853, 5.9681, 1.1672, 5.9681, 1.4645, 5.6708)
  ..lineTo(2.397, 4.7384)
  ..close()
  ..moveTo(2.397, 11.257)
  ..lineTo(4.5688, 13.4289)
  ..lineTo(5.0075, 13.8675)
  ..lineTo(5.4266, 13.4485)
  ..lineTo(7.5985, 11.2766)
  ..lineTo(8.531, 10.3441)
  ..cubicTo(8.8282, 10.0468, 9.3102, 10.0468, 9.6075, 10.3441)
  ..cubicTo(9.9047, 10.6414, 9.9047, 11.1233, 9.6075, 11.4206)
  ..lineTo(8.675, 12.3531)
  ..lineTo(6.5031, 14.525)
  ..lineTo(5.5706, 15.4574)
  ..cubicTo(5.3594, 15.6686, 5.0551, 15.7298, 4.7899, 15.6409)
  ..cubicTo(4.6561, 15.6098, 4.5291, 15.5421, 4.4248, 15.4378)
  ..lineTo(3.4924, 14.5053)
  ..lineTo(1.3205, 12.3335)
  ..lineTo(0.388, 11.401)
  ..cubicTo(0.0907, 11.1037, 0.0907, 10.6217, 0.388, 10.3245)
  ..cubicTo(0.6853, 10.0272, 1.1672, 10.0272, 1.4645, 10.3245)
  ..lineTo(2.397, 11.257)
  ..close();
