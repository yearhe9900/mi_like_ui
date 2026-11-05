/// mi_like_ui —— 小米风格可扩展 UI 组件框架。
///
/// **对外只从这里导入**：`import 'package:mi_like_ui/mi_like_ui.dart';`
///
/// 分层（依赖只允许自上而下）：
///  * `src/theme/`       —— 设计 token（颜色 / 文字 / 间距 / 材质配方 / 动效 /
///    各组件配色）；**单一来源**，其它层不得裸写字面量
///  * `src/foundations/` —— 与业务无关的视觉与交互基元（squircle 连续圆角、
///    按压 / 悬停 / 焦点三态、滤镜缓存、格位数学、玻璃描边）
///  * `src/layout/`      —— 响应式与滚动基建（断点 / 视口 / 缩放画布 /
///    内容列 / 自适应网格 / 滚动位移作用域）
///  * `src/components/`  —— 组件层，按类别组织：`navigation` / `buttons` /
///    `inputs` / `cards` / `lists` / `effects`
///  * `src/overlays/`    —— 浮层（宿主与注册表 + 弹框 / 抽屉 / 面板 / 轻提示 /
///    悬浮容器）
///  * `src/icons/`       —— 图标 painter 集
///
/// `src/` 下**未被本文件导出**的实现（各目录内 `*_painter.dart`）属框架内部，
/// 不承诺 API 稳定。新增组件后记得在此补一行 export。
library mi_like_ui;

// ── 设计 token（单一来源） ─────────────────────────────────────────────────
export 'src/theme/colors.dart';
export 'src/theme/dimens.dart';
export 'src/theme/typography.dart';
export 'src/theme/theme_mode.dart';
export 'src/theme/mi_theme.dart';
export 'src/theme/motion_tokens.dart';
export 'src/theme/transparency_tokens.dart';
export 'src/theme/glass_tokens.dart';
export 'src/theme/gradient_blur_tokens.dart';
export 'src/theme/pill_tab_tokens.dart';
export 'src/theme/button_tokens.dart';
export 'src/theme/search_bar_tokens.dart';
export 'src/theme/top_bar_tokens.dart';
export 'src/theme/row_tokens.dart';
export 'src/theme/dialog_tokens.dart';
export 'src/theme/pull_up_panel_tokens.dart';
export 'src/theme/snackbar_tokens.dart';
export 'src/theme/bottom_sheet_tokens.dart';
export 'src/theme/floating_toolbar_tokens.dart';
export 'src/theme/settings_tokens.dart';
export 'src/theme/switch_tokens.dart';
export 'src/theme/checkbox_tokens.dart';
export 'src/theme/menu_tokens.dart';

// ── 视觉与交互基元 ────────────────────────────────────────────────────────
export 'src/foundations/squircle.dart';
export 'src/foundations/glass_rim.dart';
export 'src/foundations/pressable.dart';
export 'src/foundations/hover_feedback.dart';
export 'src/foundations/focus_ring.dart';
export 'src/foundations/filter_cache.dart';
export 'src/foundations/cell_grid.dart';

// ── 响应式与滚动基建 ──────────────────────────────────────────────────────
export 'src/layout/responsive.dart';
export 'src/layout/scroll_binder.dart';

// ── 组件：导航 ────────────────────────────────────────────────────────────
export 'src/components/navigation/top_bar/top_bar.dart';
export 'src/components/navigation/top_bar/top_bar_metrics.dart';
export 'src/components/navigation/glass_nav_bar/glass_nav_bar.dart';
export 'src/components/navigation/glass_nav_bar/glass_nav_bar_metrics.dart';
export 'src/components/navigation/glass_side_nav_bar/glass_side_nav_bar.dart';
export 'src/components/navigation/glass_side_nav_bar/glass_side_nav_bar_metrics.dart';
export 'src/components/navigation/pill_tab_bar/pill_tab_bar.dart';
export 'src/components/navigation/pill_tab_bar/pill_tab_bar_metrics.dart';
export 'src/components/navigation/card_page_route/card_page_route.dart';
export 'src/components/navigation/card_page_route/card_page_route_metrics.dart';

// ── 组件：按钮 ────────────────────────────────────────────────────────────
export 'src/components/buttons/button/button.dart';
export 'src/components/buttons/button/button_metrics.dart';
export 'src/components/buttons/action_entry/action_entry.dart';
export 'src/components/buttons/action_entry/action_entry_metrics.dart';

// ── 组件：输入 ────────────────────────────────────────────────────────────
export 'src/components/inputs/search_bar/search_bar.dart';
export 'src/components/inputs/search_bar/search_bar_metrics.dart';
export 'src/components/inputs/search_bar/search_cancel_button.dart';
export 'src/components/inputs/search_bar/search_cancel_button_metrics.dart';
export 'src/components/inputs/switch_control/switch.dart';
export 'src/components/inputs/switch_control/switch_metrics.dart';
export 'src/components/inputs/checkbox/checkbox.dart';
export 'src/components/inputs/checkbox/checkbox_metrics.dart';
export 'src/components/inputs/slider/slider.dart';
export 'src/components/inputs/slider/slider_metrics.dart';

// ── 组件：列表与行 ────────────────────────────────────────────────────────
export 'src/components/lists/settings_row/settings_row.dart';
export 'src/components/lists/settings_row/settings_row_metrics.dart';
export 'src/components/lists/preference_tile/preference_tile.dart';
export 'src/components/lists/preference_tile/preference_tile_metrics.dart';

// ── 组件：卡片与效果 ──────────────────────────────────────────────────────
export 'src/components/cards/theme_card/theme_card.dart';
export 'src/components/cards/theme_card/theme_card_metrics.dart';
export 'src/components/effects/gradient_blur/gradient_blur.dart';

// ── 浮层（宿主与全部覆盖层） ──────────────────────────────────────────────
export 'src/overlays/popup_host.dart';
export 'src/overlays/dialog/dialog.dart';
export 'src/overlays/dialog/dialog_metrics.dart';
export 'src/overlays/dialog/dialog_list_metrics.dart';
export 'src/overlays/dialog/show_mi_dialog.dart';
export 'src/overlays/bottom_sheet/bottom_sheet.dart';
export 'src/overlays/bottom_sheet/bottom_sheet_metrics.dart';
export 'src/overlays/pull_up_panel/pull_up_panel.dart';
export 'src/overlays/pull_up_panel/pull_up_panel_metrics.dart';
export 'src/overlays/snackbar/snackbar.dart';
export 'src/overlays/snackbar/snackbar_metrics.dart';
export 'src/overlays/floating_toolbar/floating_toolbar.dart';
export 'src/overlays/floating_toolbar/floating_toolbar_metrics.dart';
export 'src/overlays/menu/menu.dart';
export 'src/overlays/menu/menu_metrics.dart';

// ── 图标 ──────────────────────────────────────────────────────────────────
export 'src/icons/nav_icons.dart';
