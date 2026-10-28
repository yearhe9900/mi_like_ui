import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Squircle 连续圆角：曲率自直线**平滑过渡**到弯段（G2 连续）的圆角矩形，
/// HyperOS / iOS 标志性角形。普通 RRect 的曲率在接点从 0 瞬间跳到 1/r，
/// 边缘高光沿轮廓走时会打出一个「折」；squircle 让曲率缓升缓落，高光连续。
///
/// 实现：每角一段三次贝塞尔近似 —— 瓦片边长 = 名义半径 × [extension]，
/// 控制点比例 [control] 0.643（源端 SDF 预烘焙值）。算法与常数思路源自
/// flutter_miuix `foundation/miuix_squircle.dart`（Apache-2.0，其上游为
/// compose-miuix 的 SquirclePath.kt），按本库度量驱动风格重写。
///
/// **半径语义不变**：各组件 metrics 里的圆角值仍是名义圆角半径，本类只
/// 换「怎么画这个角」，几何尺寸（外接矩形、胶囊宽高）逐像素不变。
class MiSquircle {
  MiSquircle._();

  /// 瓦片倍率：1.0 = 普通圆弧，1.1 = 连续圆角（曲率提前 ~10% 开始过渡）。
  /// 可调范围 [minExtension]…[maxExtension]（夹位见 [addRect]）。
  static const double extension = 1.1;

  /// [extension] 下限（1.0 = 普通圆弧，不许更小 —— 那会把角画成凹陷）。
  static const double minExtension = 1.0;

  /// [extension] 上限（再大角会「方」到接近直角，失去圆角语义）。
  static const double maxExtension = 2.0;

  /// 贝塞尔控制点比例（源端 SDF 预烘焙值，勿调）。
  static const double control = 0.643;

  /// [rect] 的连续圆角轮廓；[radius] ≥ 短边一半时为**真半圆端头的胶囊**
  ///（圆弧，见 [addRect] 的胶囊例外）。
  static Path pathOf(
    Rect rect,
    double radius, {
    double extension = MiSquircle.extension,
  }) {
    final path = Path();
    addRect(path, rect, radius, extension: extension);
    return path;
  }

  /// 向 [path] 追加 [rect] 的连续圆角轮廓（多胶囊条等复用同一 path）。
  ///
  /// **胶囊例外**：[radius] ≥ 短边一半时形状语义是「胶囊」，端头退回
  /// **真半圆**（圆弧）—— squircle 是「圆角过渡段」的画法，拿角部贝塞尔
  /// 去画完整半圆会把端头改成外鼓 ~4.8% 的拟圆（45° 径向 = 1.048×r），
  /// 端头反而失真；真半圆与直边 G1 相切本就是胶囊的设计语义
  ///（实机素材的胶囊端头均为正半圆）。
  static void addRect(
    Path path,
    Rect rect,
    double radius, {
    double extension = MiSquircle.extension,
  }) {
    if (rect.width <= 0 || rect.height <= 0) return;
    final halfMin = math.min(rect.width, rect.height) * 0.5;
    if (radius >= halfMin) {
      path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(halfMin)));
      return;
    }
    final ext = extension.clamp(minExtension, maxExtension);
    final tile = (radius * ext).clamp(0.0, halfMin);
    if (tile <= 0) {
      path.addRect(rect);
      return;
    }
    final l = rect.left, t = rect.top;
    final r = rect.right, b = rect.bottom;
    final handle = tile * (1.0 - control);
    path
      ..moveTo(l + tile, t)
      ..lineTo(r - tile, t)
      ..cubicTo(r - handle, t, r, t + handle, r, t + tile)
      ..lineTo(r, b - tile)
      ..cubicTo(r, b - handle, r - handle, b, r - tile, b)
      ..lineTo(l + tile, b)
      ..cubicTo(l + handle, b, l, b - handle, l, b - tile)
      ..lineTo(l, t + tile)
      ..cubicTo(l, t + handle, l + handle, t, l + tile, t)
      ..close();
  }
}

/// [ClipPath] 用的连续圆角裁形器（`ClipRRect` 的 squircle 版）。
class MiSquircleClipper extends CustomClipper<Path> {
  const MiSquircleClipper(
    this.radius, {
    this.extension = MiSquircle.extension,
  });

  /// 名义圆角半径（夹位逻辑见 [MiSquircle.pathOf]）。
  final double radius;

  /// 瓦片倍率（见 [MiSquircle.extension]）。
  final double extension;

  @override
  Path getClip(Size size) => MiSquircle.pathOf(
        Offset.zero & size,
        radius,
        extension: extension,
      );

  @override
  bool shouldReclip(MiSquircleClipper oldClipper) =>
      oldClipper.radius != radius || oldClipper.extension != extension;
}

/// [ShapeDecoration] / [PhysicalShape] 用的连续圆角形状
///（`BoxDecoration.borderRadius` 的 squircle 版）。
class MiSquircleBorder extends ShapeBorder {
  const MiSquircleBorder(
    this.cornerRadius, {
    this.extension = MiSquircle.extension,
  });

  /// 名义圆角半径。
  final double cornerRadius;

  /// 瓦片倍率（见 [MiSquircle.extension]）。
  final double extension;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      MiSquircle.pathOf(rect, cornerRadius, extension: extension);

  /// 内轮廓未做等距内缩（与描边内缩场景无关 —— 本库只用它做填充与裁形）。
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  ShapeBorder scale(double t) =>
      MiSquircleBorder(cornerRadius * t, extension: extension);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MiSquircleBorder &&
          other.cornerRadius == cornerRadius &&
          other.extension == extension);

  @override
  int get hashCode => Object.hash(cornerRadius, extension);
}

/// 连续圆角投影画笔（`BoxShadow` 的 squircle 版）：`ShapeDecoration` 不带
/// boxShadow，需要投影的表面用它垫在底层（painter 画在 child 之下）。
///
/// 语义对齐 [BoxShadow]：`blurRadius / 2` 即高斯 σ、offset 原样平移。
class MiSquircleShadowPainter extends CustomPainter {
  const MiSquircleShadowPainter({
    required this.radius,
    required this.shadows,
  });

  /// 名义圆角半径（与被垫表面同档）。
  final double radius;

  /// 投影列表（沿用 [BoxShadow] 数据结构，配方零迁移）。
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    final path = MiSquircle.pathOf(Offset.zero & size, radius);
    for (final shadow in shadows) {
      canvas.drawPath(
        path.shift(shadow.offset),
        Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            math.max(shadow.blurRadius / 2, 0.0),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(MiSquircleShadowPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      !_shadowListEquals(oldDelegate.shadows, shadows);
}

bool _shadowListEquals(List<BoxShadow> a, List<BoxShadow> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
