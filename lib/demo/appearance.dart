import 'package:flutter/material.dart';

import 'package:mi_like_ui/mi_like_ui.dart';

/// 示例应用的「外观模式」偏好（demo 层，不属于框架公共 API）。
///
/// 三档：浅色 / 深色 / 跟随系统。
///
/// **为什么不给 [MiThemeMode] 加第三个枚举值**：[MiThemeMode] 是**已解析**
/// 的明暗配方选择 —— token 层所有 `of(mode)` 都按它取色，语义上只有「暗
/// 配方 / 亮配方」两种，多一档会让每个 `switch` 都长出一条无意义的退化
/// 分支。「跟随系统」是**偏好**，必须在落进画面之前换算成确定的明暗，
/// 换算点就是 [resolve]。
enum DemoAppearance {
  light('浅色'),
  dark('深色'),
  system('跟随系统');

  const DemoAppearance(this.label);

  /// 设置行值文 / 菜单项文案。
  final String label;

  /// 换算成 Material 的 [ThemeMode]，交给 `MaterialApp.themeMode`
  /// （System 档让 Material 自家组件跟着系统翻面）。
  ThemeMode get materialThemeMode => switch (this) {
        DemoAppearance.light => ThemeMode.light,
        DemoAppearance.dark => ThemeMode.dark,
        DemoAppearance.system => ThemeMode.system,
      };

  /// 换算成组件层真正吃得下的 [MiThemeMode]。
  ///
  /// 只有 [system] 读 [platformBrightness]；浅色 / 深色是用户的显式选择，
  /// 系统翻面时不跟着变（否则「我明明选了深色，系统天黑就给我翻亮」）。
  MiThemeMode resolve(Brightness platformBrightness) => switch (this) {
        DemoAppearance.light => MiThemeMode.light,
        DemoAppearance.dark => MiThemeMode.dark,
        DemoAppearance.system =>
          platformBrightness == Brightness.light ? MiThemeMode.light : MiThemeMode.dark,
      };
}
