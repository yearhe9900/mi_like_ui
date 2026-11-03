import 'package:flutter/material.dart';

import '../../../theme/dialog_tokens.dart';
import '../../../theme/motion_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../theme/typography.dart';
import '../../../utils/pressable.dart';
import '../../feedback/dialog/dialog_metrics.dart';
import 'preference_tile_metrics.dart';

/// 设置行（`MiPreferenceTile`）：前导图标（可选）+ 标题 + 副标题（可选）
/// + 尾随控件（可选，如 `MiSwitch` / 箭头）的一行式设置项。
///
/// 行模式与弹框操作列表同族：行高复用 [MiDialogListMetrics.rowHeight]
/// （47.2 / 68.2），文字样式复用 `MiTypography.dialogAction` /
/// `dialogItemSubtitle`，按压叠色 = 弹框同配方（[MiDialogMetrics]
/// .pressDurationMs + `MiTransparencyTokens.dialogPressFor`）—— 无新造值。
///
/// 交互经 [MiPressable]：[onTap] 非空时整行可点（点按 / Enter / Space
/// 触发）+ 悬停叠色 + Tab 焦点环（桌面语义，推导同惯例）；为 null 时
/// 只展示（尾随控件仍可独立交互，如开关自带手势）。
///
/// 分隔线（[showDivider]）画在行下、与行内边距对齐（推导：设置页通行
/// 排法），不参与按压区。
class MiPreferenceTile extends StatelessWidget {
  const MiPreferenceTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = false,
    this.themeMode,
  });

  /// 前导部件（图标，尺寸建议 [MiPreferenceTileMetrics.iconSize]）。
  final Widget? leading;

  /// 标题。
  final String title;

  /// 副标题（可选；给出后行高切到有副标题档）。
  final String? subtitle;

  /// 尾随控件（可选，如 `MiSwitch` / `Icon(Icons.chevron_right)`）。
  final Widget? trailing;

  /// 点按回调；null = 只展示（不参与手势与焦点）。
  final VoidCallback? onTap;

  /// 是否画行下分隔线（弹框列表同配方：onSurface @0.08）。
  final bool showDivider;

  /// 明暗模式；null = 跟随环境 `Theme` 亮度。
  final MiThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    final mode = themeMode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    final hasSubtitle = subtitle != null;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MiPreferenceTileMetrics.paddingH,
      ),
      child: SizedBox(
        height: MiPreferenceTileMetrics.heightFor(hasSubtitle: hasSubtitle),
        child: Row(
          children: [
            if (leading != null) ...[
              SizedBox(
                width: MiPreferenceTileMetrics.iconSize,
                height: MiPreferenceTileMetrics.iconSize,
                child: leading,
              ),
              const SizedBox(width: MiPreferenceTileMetrics.iconGap),
            ],
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MiTypography.dialogAction.copyWith(color: MiDialogPalette.of(mode).title),
                  ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: MiPreferenceTileMetrics.titleSubtitleGap),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MiTypography.dialogItemSubtitle
                          .copyWith(color: MiDialogPalette.of(mode).secondaryText),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: MiPreferenceTileMetrics.trailingGap),
              trailing!,
            ],
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: onTap != null,
          child: MiPressable(
            onPressed: onTap,
            mode: mode,
            // 按压整行叠弹框同款 state layer（压在页面底色上，不换填充）。
            pressBuilder: (context, pressed, child) => AnimatedContainer(
              duration: const Duration(
                milliseconds: MiDialogMetrics.pressDurationMs,
              ),
              curve: Curves.easeOutQuad,
              color: pressed
                  ? MiTransparencyTokens.dialogPressFor(mode)
                  : MiTransparencyTokens.clear,
              child: child,
            ),
            child: row,
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MiPreferenceTileMetrics.dividerInset,
            ),
            child: ColoredBox(
              color: MiTransparencyTokens.dialogDividerFor(mode),
              child: const SizedBox(height: 1),
            ),
          ),
      ],
    );
  }
}
