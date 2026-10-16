import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'search_bar_metrics.dart';

/// 搜索栏放大镜图标（组件内部 painter，不入 barrel）。
///
/// 几何 1:1 实测自亮/暗完整截图（两图一致）：包围盒 17.8dp 见方 =
/// 镜片圆（圆心 6.9、半径 6.0、笔画 1.8）+ 45° 手柄（round cap 触盒缘）。
/// 墨色由调用方从 `MiSearchBarPalette` 传入（截图实测明暗同值 #9A9A9A）。
///
/// 归一到 [MiSearchBarMetrics.iconSize] 设计单位，随传入 [Size] 等比
/// 缩放（paint 中以 k = size / 设计尺寸 换算）。
class SearchIconPainter extends CustomPainter {
  const SearchIconPainter({required this.color});

  /// 图标墨色（palette 供给，明暗同值）。
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / MiSearchBarMetrics.iconSize;
    final strokeWidth = MiSearchBarMetrics.iconStroke * k;
    final half = strokeWidth / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // 镜片圆（笔画中心线）。
    final center = Offset(MiSearchBarMetrics.lensCenter, MiSearchBarMetrics.lensCenter) * k;
    final radius = MiSearchBarMetrics.lensRadius * k;
    canvas.drawCircle(center, radius, paint);

    // 手柄沿 45°：起点落在镜片中心线圆上（圆内段被同色笔画覆盖），
    // 终点内缩 round cap 投影 (half/√2 每轴)，cap 外缘恰好触包围盒角。
    final step = radius * math.sqrt(0.5);
    final start = center + Offset(step, step);
    final tip = Offset(size.width, size.height) - Offset(half, half) * math.sqrt(0.5);
    canvas.drawLine(start, tip, paint);
  }

  @override
  bool shouldRepaint(SearchIconPainter oldDelegate) => oldDelegate.color != color;
}
