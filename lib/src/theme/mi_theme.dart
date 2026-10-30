import 'package:flutter/material.dart';

import 'colors.dart';
import 'theme_mode.dart';

/// App 级主题数据（一处声明，全库生效）。
///
/// **优先级**：组件显式参数 > [MiTheme] 声明 > 兜底（组件各自原有默认）。
/// 不包 [MiTheme] 的使用方行为逐像素不变 —— 本类只是给「App 根部声明一次、
/// 全库组件跟随」留出的注入点，消灭逐组件传 `themeMode` 的样板。
///
/// 字段全部可空：null = 不覆盖该维度，回落到库默认（`MiColors` 的度量值）。
/// 品牌色 / 页底色注入是**整库替换**（按钮填充、搜索光标、焦点环、推入转场
/// 幕布同源换色），不是主题皮肤系统 —— 更细的维度（阅读器日间 / 羊皮纸等
/// 独立于 App 明暗的第三维度）由使用方在自己的组件层处理。
class MiThemeData {
  const MiThemeData({
    this.mode,
    this.accent,
    this.pageBackgroundLight,
    this.pageBackgroundDark,
  });

  /// 明暗模式；null = 跟随环境 `Theme.of(context).brightness`。
  final MiThemeMode? mode;

  /// 品牌强调色；null = [MiColors.accent]（度量 #4980F7）。
  ///
  /// 注入点：主按钮填充、搜索输入光标、浅色模式键盘焦点环。
  final Color? accent;

  /// 页底色（浅色）；null = [MiColors.pageBackgroundLight]（度量 #F3F3F3）。
  final Color? pageBackgroundLight;

  /// 页底色（深色）；null = [MiColors.pageBackgroundDark]（度量纯黑）。
  final Color? pageBackgroundDark;

  /// 生效的强调色（注入值或库默认度量值）。
  Color get accentOr => accent ?? MiColors.accent;

  /// 按明暗模式取生效页底色。
  Color pageBackgroundFor(MiThemeMode mode) => switch (mode) {
        MiThemeMode.dark => pageBackgroundDark ?? MiColors.pageBackgroundDark,
        MiThemeMode.light => pageBackgroundLight ?? MiColors.pageBackgroundLight,
      };

  @override
  bool operator ==(Object other) =>
      other is MiThemeData &&
      other.mode == mode &&
      other.accent == accent &&
      other.pageBackgroundLight == pageBackgroundLight &&
      other.pageBackgroundDark == pageBackgroundDark;

  @override
  int get hashCode => Object.hash(
        mode,
        accent,
        pageBackgroundLight,
        pageBackgroundDark,
      );

  MiThemeData merge(MiThemeData? other) => other == null
      ? this
      : MiThemeData(
          mode: other.mode ?? mode,
          accent: other.accent ?? accent,
          pageBackgroundLight: other.pageBackgroundLight ?? pageBackgroundLight,
          pageBackgroundDark: other.pageBackgroundDark ?? pageBackgroundDark,
        );
}

/// App 级主题注入点：根部包一层，子树内所有组件按本主题取模式 / 品牌色。
///
/// ```dart
/// MaterialApp(
///   home: MiTheme(
///     data: const MiThemeData(mode: MiThemeMode.dark, accent: Color(0xFFE94F37)),
///     child: const ReadingApp(),
///   ),
/// );
/// ```
///
/// 组件级 `themeMode` 参数仍可用且优先级更高（局部覆盖场景，如一页内
/// 同时展示明暗两套样张）。不包本件时全库行为与旧版逐像素一致。
class MiTheme extends InheritedWidget {
  const MiTheme({super.key, required this.data, required super.child});

  /// 根部声明的主题数据。
  final MiThemeData data;

  /// 最近的 [MiTheme] 数据；未声明返回 null。
  static MiThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MiTheme>()?.data;

  /// 最近的 [MiTheme] 数据；未声明返回全默认的空数据（各维度取库默认）。
  static MiThemeData of(BuildContext context) =>
      maybeOf(context) ?? const MiThemeData();

  /// 明暗模式解析（环境跟随型组件的口径）：
  /// 显式参数 > [MiTheme] 声明 > 环境 `Theme.of(context).brightness`。
  static MiThemeMode modeOf(BuildContext context, {MiThemeMode? explicit}) =>
      explicit ??
      maybeOf(context)?.mode ??
      (Theme.of(context).brightness == Brightness.light
          ? MiThemeMode.light
          : MiThemeMode.dark);

  /// 明暗模式解析（库默认深色型组件的口径，如玻璃导航栏 / 胶囊行 / 按钮）：
  /// 显式参数 > [MiTheme] 声明 > [fallback]（原有默认值，行为不变）。
  static MiThemeMode modeOfOr(
    BuildContext context, {
    MiThemeMode? explicit,
    required MiThemeMode fallback,
  }) =>
      explicit ?? maybeOf(context)?.mode ?? fallback;

  /// 生效的品牌强调色（[MiThemeData.accent] 注入值或 [MiColors.accent]）。
  static Color accentOf(BuildContext context) => of(context).accentOr;

  /// 按明暗模式取生效页底色（注入值或库默认度量值）。
  static Color pageBackgroundFor(BuildContext context, MiThemeMode mode) =>
      of(context).pageBackgroundFor(mode);

  @override
  bool updateShouldNotify(MiTheme oldWidget) => oldWidget.data != data;
}
