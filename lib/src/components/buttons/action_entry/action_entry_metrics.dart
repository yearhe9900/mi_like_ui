import '../../../theme/transparency_tokens.dart';

/// 纵向动作条目（图标在上、文字在下）的几何与反馈规格。
///
/// **度量口径**：第三方阅读器底部菜单第二行（目录 / 夜间 / 设置 / 更多）
/// 的 1220×2656 素材 —— 22dp 图标 + 3dp 间隙 + 10.5dp 文字（标签排版
/// 取 `MiTypography.navLabel`，同档同值）。素材无按压 / 悬停样张，相关
/// 取值的推导依据见各常量注释。
class MiActionEntryMetrics {
  MiActionEntryMetrics._();

  /// 图标墨盒边长（度量 22dp）。
  static const double iconSize = 22;

  /// 图标与文字间隙（度量 3dp）。
  static const double iconLabelGap = 3;

  /// 整格可点区域的悬停叠色 / 焦点环圆角（**推导值**：素材无悬停样张，
  /// 取菜单格惯用的 12dp —— 与 MReader 自拼件的按压形状一致）。
  static const double cellRadius = 12;

  /// 行高默认值（**推导值**：内容 22 + 3 + 10.5 ≈ 35.5dp，上下留白至
  /// 56dp —— 与 MReader 阅读器菜单现行行高同值）。只作用于
  /// [MiActionEntryRow] 的默认高度，最终由宿主布局决定。
  static const double rowHeight = 56;

  /// 按压淡出系数（**推导值**：MReader 自拼件 `_MenuEntry` 的按压口径
  /// 0.55；按压状态机由 MiPressable 提供，淡出是瞬时的，无过渡帧）。
  static const double pressFade = 0.55;

  /// 禁用态淡出系数：**引用全库禁用文字档**
  /// （[MiTransparencyTokens.disabledLabelAlpha] ≈ 38%，Material 常规），
  /// 图标与文字一起降透明、不消失。
  static const double disabledFade =
      MiTransparencyTokens.disabledLabelAlpha / 255;
}
