/// 明暗模式维度（框架级，跨组件共用）。
///
/// 组件通过 `themeMode` 参数接收；token 层按模式取用对应配方
/// （如 `MiGlassPalette.of(mode)`、`MiColors.foregroundFor(mode)`）。
enum MiThemeMode {
  /// 深色模式（默认，参考视频度量）。
  dark,

  /// 浅色模式（参考亮色素材度量）。
  light,
}
