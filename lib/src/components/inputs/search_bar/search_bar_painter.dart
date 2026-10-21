import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'search_bar_metrics.dart';

/// 搜索栏放大镜图标（组件内部 painter，不入 barrel）。
///
/// 几何规格（两组参考素材一致）：包围盒 17.8dp 见方 = 镜片圆
/// （圆心 6.9、半径 6.0、笔画 1.8）+ 45° 手柄（round cap 触盒缘）。
/// 墨色由调用方自 `MiSearchBarPalette` 传入（明暗同值 #9A9A9A）。
///
/// 以 [MiSearchBarMetrics.iconSize] 为设计单位归一，随传入 [Size]
/// 等比缩放。
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
