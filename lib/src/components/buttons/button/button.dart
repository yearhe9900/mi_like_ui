import 'package:flutter/material.dart';

import '../../../theme/button_tokens.dart';
import '../../../theme/dimens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/typography.dart';
import '../../../utils/focus_ring.dart';
import '../../../utils/hover_feedback.dart';
import 'button_metrics.dart';

/// 按钮形态。
enum MiButtonVariant {
  /// 主按钮：强调填充 + 白字。
  filled,

  /// 次级按钮：低对比表面填充（推导值）。
  tonal,
}

/// 胶囊按钮（明暗双模式，主 / 次级 / 禁用三态）。
///
/// 规格（几何见 [MiButtonMetrics]、配色见 `theme/button_tokens.dart`）：
/// 高 28.3dp stadium、左右内边距 17dp、标签 13dp Medium，宽度随内容
/// 自适应；主按钮填充 [MiColors.accent]（明暗同色）。
///
/// [onPressed] 为 `null` 时进入禁用态（推导值）。形态 / 状态切换时填充与
/// 标签色以 200ms 过渡（`easeOut`）。
class MiButton extends StatelessWidget {
  const MiButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = MiButtonVariant.filled,
    this.themeMode = MiThemeMode.dark,
  });

  /// 按钮文案。
  final String label;

  /// 点按回调；为 null 时按钮进入禁用态。
  final VoidCallback? onPressed;

  /// 按钮形态（主 / 次级）。
  final MiButtonVariant variant;

  /// 明暗模式，驱动配色配方。
  final MiThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final palette = MiButtonPalette.of(themeMode);
    final enabled = onPressed != null;
    final (fill, labelColor) = !enabled
        ? (palette.disabledFill, palette.disabledLabel)
        : switch (variant) {
            MiButtonVariant.filled => (palette.filledFill, palette.filledLabel),
            MiButtonVariant.tonal => (palette.tonalFill, palette.tonalLabel),
          };
    return Semantics(
      button: true,
      enabled: enabled,
      // 键盘可达性：Tab 聚焦时在胶囊外侧画强调描边，Enter / Space 激活
      // （描边实色、不引 saveLayer，见 MiFocusRing 文档）。
      child: MiFocusRing(
        enabled: enabled,
        mode: themeMode,
        onActivate: onPressed,
        borderRadius: BorderRadius.circular(MiDimens.radiusPill),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          // 悬停只给可点态（禁用态不该有「可点」暗示）。
          child: MiHoverFeedback(
            mode: themeMode,
            enabled: enabled,
            borderRadius: BorderRadius.circular(MiDimens.radiusPill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: MiButtonMetrics.height,
              padding: const EdgeInsets.symmetric(
                horizontal: MiButtonMetrics.horizontalPadding,
              ),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(MiDimens.radiusPill),
              ),
              // 宽度随内容收缩：Center 带 widthFactor 才不会在有界父级
              //（Center/Column）里被拉满宽 —— 度量按钮是内容自适应的胶囊。
              child: Center(
                widthFactor: 1.0,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MiTypography.buttonLabel.copyWith(color: labelColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
