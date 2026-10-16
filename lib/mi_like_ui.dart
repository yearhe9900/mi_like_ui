/// mi_like_ui —— 小米风格可扩展 UI 组件框架。
///
/// **对外只从这里导入**：`import 'package:mi_like_ui/mi_like_ui.dart';`
///
/// 分层约定：
///  * `src/theme/`       —— 样式/主题 token（颜色、文字、间距、材质配方）
///  * `src/components/`  —— 组件层，按 `类别/组件名/` 组织
///  * `src/icons/`       —— 图标 painter 集
///  * `src/utils/`       —— 纯函数工具层
///
/// `src/` 下**未被本文件导出**的实现（如组件内部 painter）属框架内部，
/// 不承诺 API 稳定。新增组件后记得在此补一行 export。
library mi_like_ui;

// ── 样式/主题层 ────────────────────────────────────────────────────────────
export 'src/theme/colors.dart';
export 'src/theme/theme_mode.dart';
export 'src/theme/typography.dart';
export 'src/theme/dimens.dart';
export 'src/theme/transparency_tokens.dart';
export 'src/theme/glass_tokens.dart';
export 'src/theme/pill_tab_tokens.dart';

// ── 组件层 ────────────────────────────────────────────────────────────────
export 'src/components/navigation/glass_nav_bar/glass_nav_bar.dart';
export 'src/components/navigation/glass_nav_bar/glass_nav_bar_metrics.dart';
export 'src/components/navigation/pill_tab_bar/pill_tab_bar.dart';
export 'src/components/navigation/pill_tab_bar/pill_tab_bar_metrics.dart';

// ── 图标 ──────────────────────────────────────────────────────────────────
export 'src/icons/nav_icons.dart';

// ── 工具函数层 ────────────────────────────────────────────────────────────
export 'src/utils/cell_grid.dart';
