import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/mi_theme.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/typography.dart';
import '../../../foundations/pressable.dart';
import 'action_entry_metrics.dart';

/// 「图标在上、文字在下」的纵向动作条目（底部菜单格：目录 / 夜间 / 设置 /
/// 更多这类等分横排的动作格）。
///
/// 与 `MiGlassNavBar` 的 tab 条目分工不同：那是**导航选中态**语义（胶囊
/// 飞行、拖拽切换、selectedIndex），本件是「点了就执行动作」的菜单格 ——
/// [onPressed] 即语义，无选中态概念；需要高亮（如「夜间」已开）时传
/// [active]，图标与文字走强调色。
///
/// **三态反馈收编自 [MiPressable]**（组件内不手写 `_pressed`）：
///  * 按压 = 内容整体淡出至 [MiActionEntryMetrics.pressFade]（0.55，
///    MReader 自拼件口径，瞬时无过渡帧）；
///  * 悬停叠色 / 手型光标、键盘焦点环 + Enter / Space 激活同套开关
///    （[hover] / [focus]，默认开）；
///  * 禁用（[onPressed] 为 null）= 降透明至 [MiActionEntryMetrics.
///    disabledFade]（≈38%，全库禁用文字档），不消失、不响应。
///
/// 等分排布由宿主用 `Expanded` 组合（或直接用 [MiActionEntryRow]）；
/// 几何口径见 [MiActionEntryMetrics]（22dp 图标 + 3dp 间隙 +
/// `MiTypography.navLabel` 文字）。
class MiActionEntry extends StatelessWidget {
  const MiActionEntry({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.themeMode,
    this.hover = true,
    this.focus = true,
  });

  /// 图标字形。
  final IconData icon;

  /// 标签文案（`MiTypography.navLabel` 同档：10.5dp Medium）。
  final String label;

  /// 点按回调；null = 禁用态（降透明、不响应）。
  final VoidCallback? onPressed;

  /// 高亮态（如「夜间」已开）：图标与文字走强调色。
  final bool active;

  /// 明暗模式；null = 跟随 [MiTheme]，未声明时跟环境 `Theme` 亮度。
  final MiThemeMode? themeMode;

  /// 是否启用悬停反馈（叠色 + 手型光标；禁用时自动失效）。
  final bool hover;

  /// 是否启用键盘焦点（焦点环 + Enter / Space 激活；禁用时自动失效）。
  final bool focus;

  @override
  Widget build(BuildContext context) {
    final mode = MiTheme.modeOf(context, explicit: themeMode);
    final enabled = onPressed != null;
    // 高亮走强调色（注入点优先），其余走明暗前景色。
    final ink = active
        ? MiTheme.accentOf(context)
        : MiColors.foregroundFor(mode);
    return Semantics(
      button: true,
      enabled: enabled,
      child: MiPressable(
        onPressed: onPressed,
        mode: mode,
        hover: hover,
        focus: focus,
        borderRadius: BorderRadius.circular(MiActionEntryMetrics.cellRadius),
        // 按压 / 禁用都以「淡出」表达：系数乘进图标与标签的 alpha ——
        // 结构恒定（与 MiPressable 的 pressBuilder 契约一致），且不引
        // saveLayer（磨砂子树约束见 MiHoverFeedback 文档）。
        pressBuilder: (BuildContext context, bool pressed, Widget child) {
          final fade = !enabled
              ? MiActionEntryMetrics.disabledFade
              : pressed
                  ? MiActionEntryMetrics.pressFade
                  : 1.0;
          final fadedInk =
              fade >= 1 ? ink : ink.withValues(alpha: ink.a * fade);
          return IconTheme(
            data: IconThemeData(color: fadedInk),
            child: DefaultTextStyle(
              style: MiTypography.navLabelFor(mode).copyWith(color: fadedInk),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: MiActionEntryMetrics.iconSize),
            const SizedBox(height: MiActionEntryMetrics.iconLabelGap),
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// [MiActionEntry] 的等分横排容器：每格 `Expanded` 等宽、整行高
/// [MiActionEntryMetrics.rowHeight]（56dp，推导值）。
///
/// 供底部菜单这类「一行四格」直接使用；自定义行高 / 间距时宿主自行
/// `Row(children: [Expanded(child: …), …])` 组合即可。
class MiActionEntryRow extends StatelessWidget {
  const MiActionEntryRow({
    super.key,
    required this.entries,
    this.height = MiActionEntryMetrics.rowHeight,
  });

  /// 行内条目（等分横排）。
  final List<MiActionEntry> entries;

  /// 行高（默认 [MiActionEntryMetrics.rowHeight]）。
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: <Widget>[
          for (final entry in entries) Expanded(child: entry),
        ],
      ),
    );
  }
}
