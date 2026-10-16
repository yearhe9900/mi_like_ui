import 'package:flutter/material.dart';

import '../../../theme/button_tokens.dart';
import '../../../theme/dimens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/typography.dart';
import 'button_metrics.dart';

/// 按钮形态。
enum MiButtonVariant {
  /// 主按钮：实测关注按钮（蓝填充 + 白字），参考图唯一样式。
  filled,

  /// 次级按钮：低对比表面灰（「已关注」态，推导样式，非实测）。
  tonal,
}

/// 小米「我的关注」页风格的胶囊按钮（明暗双模式）。
///
/// 几何 / 配色 1:1 实测（几何见 [MiButtonMetrics]、配方见
/// `theme/button_tokens.dart`）：高 28.3dp stadium、填充 #4980F7 明暗
/// 同色、13dp Medium 白字、左右 17dp 内边距（宽度随内容自适应）。
///
/// [onPressed] 为 null 时进入禁用态（推导样式）。形态 / 状态切换时填充与
/// 标签色以 200ms 过渡 —— 与 `MiPillTabBar` 同款标准过渡（参考图为静态
/// 截图、无动效实测，故不引入按压缩放等未实测动效）。
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
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
          //（Center/Column）里被拉满宽 —— 实测按钮是内容自适应的胶囊。
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
