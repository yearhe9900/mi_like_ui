import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/dimens.dart';

/// 窗口尺寸等级（按**可用逻辑宽**分档）。
///
/// 断点取值（见 [MiBreakpoints]）：
///  * `compact`  < 600dp  —— 手机竖屏、桌面小窗、分屏小半；
///  * `medium`   600…1023dp —— 平板竖屏、手机横屏、桌面窄窗；
///  * `expanded` ≥ 1024dp —— 平板横屏、桌面。
///
/// 与 Material 3 的 window size class 同语义，但只留三档：本框架的组件
/// 几何都是 1:1 实测的「手机设计宽 393dp」值，再细分档位也无额外决策。
enum MiWindowSize {
  compact,
  medium,
  expanded;

  bool get isCompact => this == MiWindowSize.compact;
  bool get isMedium => this == MiWindowSize.medium;
  bool get isExpanded => this == MiWindowSize.expanded;

  /// 是否给出了「单列手机」以外的布局空间。
  bool get isWide => this == MiWindowSize.expanded;

  /// 导航形态是否用**侧边导航栏**（枚举口径：medium / expanded 都用侧栏）。
  ///
  /// 与 [MiBreakpoints.usesSideNav] 同一结论，`600` 这个边界点除外 ——
  /// `ofWidth` 把「正好 600」算进 medium（compact 是 `< 600`），而权威口径
  /// 是 **严格大于**（MReader 的 `maxWidth > kShellRailBreakpoint`）。
  /// 需要逐像素一致时用宽度版。
  bool get usesSideNav => this != MiWindowSize.compact;

  /// 是否达到**桌面断点**（视口宽 ≥ [MiBreakpoints.desktop]）。
  ///
  /// 只用来判断「桌面档专属」的样式（如示例舞台加宽成 1000dp）；
  /// **导航形态不要按它判** —— 平板（medium）也用侧边导航栏，见
  /// [usesSideNav]。
  bool get isDesktop => this == MiWindowSize.expanded;
}

/// 断点常量与判定函数（**纯函数**，无 context 依赖，可直接单测）。
///
/// 三套入口语义不同，别混用：
///  * [ofWidth] / [MiViewport.windowSize] —— **窗口**宽，用于决定页面级布局
///    形态（如示例舞台是否加宽）；
///  * [usesSideNav] —— **外壳容器**宽，决定导航形态（底栏 ⇄ 侧栏）；
///  * [columnsFor] —— **组件自身容器**的可用宽，用于网格列数等局部布局。
///    组件被嵌在限宽画布（如 393dp 手机框）里时，窗口再宽也不该改变它的
///    列数，所以局部布局必须读容器宽而不是窗口宽。
class MiBreakpoints {
  MiBreakpoints._();

  /// compact 上界（不含）：`width < 600` 即 compact。
  static const double compact = 600;

  /// **导航形态断点**：外壳容器宽 **> 该值** 时用侧边导航栏，否则底部导航栏。
  ///
  /// 取值与 MReader 主壳层 `kShellRailBreakpoint = 600`
  /// （`lib/ui/home_shell.dart`，其上游 anx-reader 同值）一致 ——
  /// 平板（600…1023）**也**用侧栏，只有手机竖屏 / 窄窗留底栏。
  /// 判定用**严格大于**：正好 600 仍走底栏，与 MReader 的
  /// `constraints.maxWidth > kShellRailBreakpoint` 逐像素同口径。
  static const double navRail = 600;

  /// **桌面断点**：视口宽 ≥ 该值即进入桌面档（示例舞台加宽、网格 6/8 列）。
  ///
  /// 它只是「expanded 档下界」，**不是**导航形态的判定口（那看 [navRail]）。
  static const double desktop = 1024;

  /// medium 上界（不含）：`600 ≤ width < 1024` 即 medium。
  static const double medium = desktop;

  /// 按宽度判档。
  static MiWindowSize ofWidth(double width) {
    if (width < compact) return MiWindowSize.compact;
    if (width < medium) return MiWindowSize.medium;
    return MiWindowSize.expanded;
  }

  /// 导航形态：容器宽 **> [navRail]** 时用侧边导航栏。
  ///
  /// 传**外壳自己的容器宽**（`LayoutBuilder` 的 `constraints.maxWidth`），
  /// 与 MReader 的 `LayoutBuilder` + `constraints.maxWidth` 同一做法：
  /// 分屏、画中画、嵌在限宽画布（示例的 393 手机框 / 1000 舞台）里时，
  /// 结论跟着容器走而不是跟着窗口走 —— 手机框里就算窗口再宽也不摆侧栏。
  static bool usesSideNav(double width) => width > navRail;

  /// 按**容器可用宽**取列数（网格等局部布局用）。
  ///
  /// [compactMax] / [mediumMax] 是该网格自己的内容宽断点：组件嵌在限宽画布
  /// 里时，容器宽永远小于窗口宽（舞台 1000 − 两侧页边距 ≈ 952 < 1024），
  /// 若沿用窗口断点就会一直停在 medium 档、宽屏永远换不到 expanded 列数。
  /// 所以网格断点要按「内容宽」标定（示例取 520 / 800 ≈ 设计宽 393 的
  /// 1.3 / 2 倍）。
  ///
  /// 三档各给一个列数，返回前 clamp 到 `[1, maxColumns]`：容器窄到放不下
  /// 也不会出现 0 列；容器极宽也不会无限扩列。
  static int columnsFor(
    double width, {
    required int compact,
    required int medium,
    required int expanded,
    int maxColumns = 12,
    double compactMax = MiBreakpoints.compact,
    double mediumMax = MiBreakpoints.medium,
  }) {
    final n = width < compactMax
        ? compact
        : width < mediumMax
        ? medium
        : expanded;
    return n.clamp(1, math.max(1, maxColumns));
  }
}

/// 当前窗口的尺寸快照（由 [MediaQuery] 推导，随窗口变化自动重建）。
///
/// 用法：
/// ```dart
/// final viewport = MiViewport.of(context);
/// if (viewport.isExpanded) { /* 宽屏布局 */ }
/// ```
///
/// **实时响应**：`MediaQuery.sizeOf` 注册的是 `MediaQuery` 的 size
/// aspect 依赖 —— 窗口/浏览器/分屏尺寸一变，本 context 立刻重建，
/// 不需要 `setState`，也不需要轮询。
@immutable
class MiViewport {
  const MiViewport(this.size);

  /// 从 context 取当前窗口逻辑尺寸。
  factory MiViewport.of(BuildContext context) =>
      MiViewport(MediaQuery.sizeOf(context));

  /// 窗口逻辑尺寸（dp）。
  final Size size;

  MiWindowSize get windowSize => MiBreakpoints.ofWidth(size.width);

  bool get isCompact => windowSize.isCompact;
  bool get isMedium => windowSize.isMedium;
  bool get isExpanded => windowSize.isExpanded;

  /// 是否进入桌面布局（视口宽 ≥ [MiBreakpoints.desktop]）。
  /// 示例里用它把底部导航栏换成侧边导航栏。
  bool get isDesktop => windowSize.isDesktop;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MiViewport && other.size == size);

  @override
  int get hashCode => size.hashCode;

  @override
  String toString() => 'MiViewport($size, ${windowSize.name})';
}

/// 固定设计尺寸的画布，按可用空间**等比**缩放到放得下（contain）。
///
/// 用于「1:1 实测」的像素级界面：设计尺寸内的几何一个不改，整体只做
/// 单一比例的仿射缩放，因此
///  * **不溢出**：缩放比取两个方向的较小者，画布永远完整落在可用空间内；
///  * **不变形**：宽高共用同一个比例（不是宽高各自拉伸）；
///  * **不模糊**：走 `FittedBox`（Skia 变换 + 矢量重绘），不是位图取样。
///
/// 缩放区间 `[minScale, maxScale]` 默认 `[0, 1]`：只缩小不放⼤（放大会
/// 破坏「1dp = 1 物理 dp」的实测语义）。刻意放开 `maxScale` 时请自行确认
/// 目标场景允许放大。
///
/// 子级按 `designSize` 拿到 **tight** 约束，可用 `LayoutBuilder` 感知的
/// 是设计尺寸而非缩放后的尺寸 —— 这正是「逻辑尺寸不变、只改渲染尺寸」
/// 的语义。
class MiScaledCanvas extends StatelessWidget {
  const MiScaledCanvas({
    super.key,
    required this.designSize,
    required this.child,
    this.maxScale = 1.0,
    this.minScale = 0.0,
    this.alignment = Alignment.center,
  });
  // 参数校验见 build()/scaleFor()：const 构造断言不能对参数成员求值
  //（`designSize.width` 属成员访问，会报 invalid_constant）。

  /// 设计尺寸（画布内布局用的逻辑尺寸）。
  final Size designSize;

  /// 画布内容，按 [designSize] 布局。
  final Widget child;

  /// 缩放上限（默认 1.0：不放大）。
  final double maxScale;

  /// 缩放下限（默认 0：缩到任意小，保证永不溢出）。
  final double minScale;

  /// 画布在可用空间内的对齐方式。
  final Alignment alignment;

  /// 纯函数：给定可用空间，返回缩放比（可直接单测）。
  ///
  /// 可用方向为无界（∞）时该方向不参与约束。
  static double scaleFor(
    Size available,
    Size designSize, {
    double maxScale = 1.0,
    double minScale = 0.0,
  }) {
    assert(designSize.width > 0 && designSize.height > 0);
    assert(minScale >= 0 && maxScale >= minScale);
    final sx = available.width.isFinite && available.width > 0
        ? available.width / designSize.width
        : double.infinity;
    final sy = available.height.isFinite && available.height > 0
        ? available.height / designSize.height
        : double.infinity;
    var s = math.min(sx, sy);
    if (!s.isFinite) s = maxScale; // 两个方向都无界：按上限渲染，不无限放大
    return s.clamp(minScale, math.max(minScale, maxScale));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = scaleFor(
          Size(constraints.maxWidth, constraints.maxHeight),
          designSize,
          maxScale: maxScale,
          minScale: minScale,
        );
        final rendered = Size(
          designSize.width * scale,
          designSize.height * scale,
        );
        final canvas = SizedBox.fromSize(
          size: designSize,
          child: child,
        );
        // 1x 时走原样路径：不引入任何变换层（黄金图逐像素稳定）。
        final scaled = scale == 1.0
            ? canvas
            : FittedBox(fit: BoxFit.fill, child: canvas);
        return Align(
          alignment: alignment,
          child: SizedBox.fromSize(size: rendered, child: scaled),
        );
      },
    );
  }
}

/// 响应式网格：按**自身可用宽**切换列数，行内等分、行间留白。
///
/// 与 `Wrap` 的区别：本项目要求「行内等宽、最后一行不足的格子留空」，
/// `Wrap` 会让末项宽度不定；这里用 `Row + Expanded`，每列宽恒为
/// `(可用宽 - (n-1) × itemSpacing) / n`，浮点误差也不会导致意外换行。
///
/// 需要**有界宽**的父级（普通 Column / ListView / Padding 即可）；
/// 放在横向滚动容器里会抛「无界宽」约束错误。
///
/// ```dart
/// MiResponsiveGrid(
///   compactColumns: 3, mediumColumns: 4, expandedColumns: 6,
///   itemSpacing: 11.9, runSpacing: 15,
///   children: cards,
/// )
/// ```
class MiResponsiveGrid extends StatelessWidget {
  const MiResponsiveGrid({
    super.key,
    required this.children,
    this.compactColumns = 2,
    this.mediumColumns = 3,
    this.expandedColumns = 4,
    this.compactMax = MiBreakpoints.compact,
    this.mediumMax = MiBreakpoints.medium,
    this.itemSpacing = MiDimens.spaceMd,
    this.runSpacing = MiDimens.spaceMd,
    this.rowAlignment = CrossAxisAlignment.start,
  }) : assert(compactColumns >= 1),
       assert(mediumColumns >= 1),
       assert(expandedColumns >= 1),
       assert(itemSpacing >= 0),
       assert(runSpacing >= 0),
       assert(compactMax > 0 && mediumMax > compactMax);

  /// 网格项（按行优先顺序排列）。
  final List<Widget> children;

  /// compact 档列数。
  final int compactColumns;

  /// medium 档列数。
  final int mediumColumns;

  /// expanded 档列数。
  final int expandedColumns;

  /// compact 档的内容宽上界（默认 600 —— 窗口断点，适合铺满窗口的网格）。
  ///
  /// 嵌在限宽画布里的网格要按**内容宽**重新标定（示例 520），否则容器宽
  /// 永远够不到窗口断点，宽屏换不到更多列。
  final double compactMax;

  /// medium 档的内容宽上界（默认 1024）。
  final double mediumMax;

  /// 列间距。
  final double itemSpacing;

  /// 行间距。
  final double runSpacing;

  /// 行内纵向对齐（默认顶端对齐，卡片高度不同时不拉伸）。
  final CrossAxisAlignment rowAlignment;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MiBreakpoints.compact;
        final columns = MiBreakpoints.columnsFor(
          width,
          compact: compactColumns,
          medium: mediumColumns,
          expanded: expandedColumns,
          compactMax: compactMax,
          mediumMax: mediumMax,
        );
        final rows = <Widget>[];
        for (var start = 0; start < children.length; start += columns) {
          if (start > 0) rows.add(SizedBox(height: runSpacing));
          final cells = <Widget>[];
          for (var col = 0; col < columns; col++) {
            if (col > 0) cells.add(SizedBox(width: itemSpacing));
            final index = start + col;
            cells.add(
              Expanded(
                child: index < children.length
                    ? children[index]
                    : const SizedBox.shrink(),
              ),
            );
          }
          rows.add(Row(crossAxisAlignment: rowAlignment, children: cells));
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}
