import 'package:flutter/material.dart';

import '../../../theme/button_tokens.dart';
import '../../../theme/dimens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/typography.dart';
import '../../../utils/pressable.dart';
import '../../../utils/squircle.dart';
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
      // 三态反馈（悬停叠色 + 手型光标、Tab 焦点环 + Enter / Space 激活、
      // 按压状态机）收编自 MiPressable（描边与叠色实色、不引 saveLayer，
      // 见各基础件文档）。按钮素材无按压帧 —— 不发明按压视觉
      //（pressBuilder 缺省）；悬停 / 焦点只给可点态（禁用态不该有
      //「可点」暗示），由 MiPressable 按 enabled 门控。
      child: MiPressable(
        onPressed: onPressed,
        mode: themeMode,
        borderRadius: BorderRadius.circular(MiDimens.radiusPill),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: MiButtonMetrics.pressDurationMs,
          ),
          curve: Curves.easeOut,
          height: MiButtonMetrics.height,
          padding: const EdgeInsets.symmetric(
            horizontal: MiButtonMetrics.horizontalPadding,
          ),
          decoration: ShapeDecoration(
            color: fill,
            shape: const MiSquircleBorder(MiDimens.radiusPill),
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
    );
  }
}
