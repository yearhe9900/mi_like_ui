import 'package:flutter/material.dart';

import '../../../icons/nav_icons.dart';
import '../../../theme/mi_theme.dart';
import '../../../theme/settings_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../foundations/pressable.dart';
import '../../../foundations/squircle.dart';
import 'settings_row_metrics.dart';

/// 设置分组卡片：圆角容器裁剪行间按压高亮带（方角带在圆角处随卡片裁切）。
///
/// 子级铺满行宽（[Column.stretch]）；行间分隔与间距由行自身布局决定。
/// 明暗配方见 [MiSettingsPalette]，模式解析走 [MiTheme]（可被根部声明
/// 统一驱动）。
class MiSettingsCard extends StatelessWidget {
  const MiSettingsCard({super.key, required this.children, this.themeMode});

  /// 卡片内子级（一般为 [MiSettingsRow] 列表）。
  final List<Widget> children;

  /// 明暗模式；null = 跟随 [MiTheme]，未声明时跟环境 `Theme` 亮度。
  final MiThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    final mode = MiTheme.modeOf(context, explicit: themeMode);
    // 表面层 + 裁形与弹框卡片同画法（squircle 连续圆角，全库同一语言）：
    // 填充走 ShapeDecoration + MiSquircleBorder，子级（行 / 按压带）由
    // ClipPath 裁在圆角内。
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: MiSettingsPalette.cardFor(mode),
        shape: const MiSquircleBorder(MiSettingsMetrics.cardRadius),
      ),
      child: ClipPath(
        clipper: const MiSquircleClipper(MiSettingsMetrics.cardRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// 设置行：前导块 + 主文案（+ 副标题）+ 可选值文 / 尾部 + chevron。
///
/// 按压反馈为**整行满铺高亮带**（120ms easeOut 淡入出，推导值）；按压
/// 状态机、悬停叠色与键盘焦点环由 [MiPressable] 统一提供（行不自带
/// 这三态 —— 与弹框按钮 / 返回钮同一套基础件）。无 [trailing] 且可点时
/// 显示 chevron；`onTap == null` 为纯展示行（无按压 / 悬停 / 焦点）。
class MiSettingsRow extends StatelessWidget {
  const MiSettingsRow({
    super.key,
    required this.label,
    this.subtitle,
    this.value,
    this.leading,
    this.trailing,
    this.chevron = true,
    this.onTap,
    this.themeMode,
  });

  /// 主文案。
  final String label;

  /// 副标题（多一行，行内文字缩小一档）。
  final String? subtitle;

  /// 右侧状态文案（如「已连接」「自动」）。
  final String? value;

  /// 前导块（图标块 [MiSettingsTile] / 头像等）。
  final Widget? leading;

  /// 尾部自定义内容（如开关）；给出时 chevron 让位。
  final Widget? trailing;

  /// 无 [trailing] 时是否显示 chevron（仍需 [onTap] 非空才显示）。
  final bool chevron;

  /// 点按回调；null = 纯展示行。
  final VoidCallback? onTap;

  /// 明暗模式；null = 跟随 [MiTheme]，未声明时跟环境 `Theme` 亮度。
  final MiThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    final mode = MiTheme.modeOf(context, explicit: themeMode);
    final fg = MiSettingsPalette.labelFor(mode);
    final sub = MiSettingsPalette.secondaryFor(mode);
    final showChevron = chevron && onTap != null && trailing == null;
    return Semantics(
      button: onTap != null,
      child: MiPressable(
        onPressed: onTap,
        mode: mode,
        // 按压视觉 = 整行满铺高亮带（方角，随卡片圆角裁切）。
        pressBuilder: (context, pressed, child) => AnimatedContainer(
          duration: const Duration(
            milliseconds: MiSettingsMetrics.pressDurationMs,
          ),
          curve: Curves.easeOut,
          color: pressed
              ? MiSettingsPalette.pressFor(mode)
              : Colors.transparent,
          child: child,
        ),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: MiSettingsMetrics.rowHeight,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: MiSettingsMetrics.rowInsetX,
            vertical: subtitle == null ? 0 : MiSettingsMetrics.rowBlockPaddingY,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: MiSettingsMetrics.leadingGap),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: MiSettingsMetrics.labelSize,
                        fontWeight: FontWeight.w400,
                        color: fg,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: MiSettingsMetrics.subtitleGap),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: MiSettingsMetrics.subtitleSize,
                          color: sub,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: MiSettingsMetrics.trailingGap),
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: MiSettingsMetrics.valueSize,
                    color: sub,
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: MiSettingsMetrics.trailingGap),
                trailing!,
              ] else if (showChevron) ...[
                const SizedBox(width: MiSettingsMetrics.chevronGap),
                // chevron 墨盒 11.7×21.3（前进箭头 = 返回箭头的水平镜像）
                SizedBox(
                  width: MiSettingsMetrics.chevronWidth,
                  height: MiSettingsMetrics.chevronHeight,
                  child: CustomPaint(
                    painter: ForwardChevronIconPainter(
                      MiSettingsPalette.chevronFor(mode),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 设置行前导图标块：彩色圆角方块 + 白色字形（推导值，见 metrics 注释）。
class MiSettingsTile extends StatelessWidget {
  const MiSettingsTile(this.icon, this.color, {super.key});

  /// 字形。
  final IconData icon;

  /// 块底色（品牌彩色）。
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MiSettingsMetrics.tileSide,
      height: MiSettingsMetrics.tileSide,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(MiSettingsMetrics.tileRadius),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
