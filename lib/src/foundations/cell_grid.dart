/// 等分格位网格的索引 / 吸附数学。
///
/// 适用于一切"横排等宽格子"型组件（tab 栏、分段控制器、轮播页指示等）。
library;

/// 横向偏移 [dx] 落入的格子下标（钳位到 0..count-1）。
///
/// [leadingInset] 是首格左缘到容器左缘的距离，[cellWidth] 是单格宽。
int cellIndexAt({
  required double dx,
  required double leadingInset,
  required double cellWidth,
  required int count,
}) {
  return ((dx - leadingInset) / cellWidth).floor().clamp(0, count - 1);
}

/// 连续格位 [position]（可越界）最近的格子下标（钳位到 0..count-1）。
int nearestCell(double position, int count) {
  return position.round().clamp(0, count - 1);
}
