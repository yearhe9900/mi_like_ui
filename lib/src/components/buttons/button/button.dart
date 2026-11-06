import 'package:flutter/material.dart';

import '../../../theme/button_tokens.dart';
import '../../../theme/dimens.dart';
import '../../../theme/mi_theme.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../theme/typography.dart';
import '../../../foundations/pressable.dart';
import '../../../foundations/squircle.dart';
import 'button_metrics.dart';

/// 按钮形态。
enum MiButtonVariant {
  /// 主按钮：强调填充 + 白字。
  filled,

  /// 次级按钮：低对比表面填充（推导值）。
  tonal,

  /// 文本按钮：无填充、强调色标签（悬停 / 按压仍走三态反馈）。
  text,
}

/// 按钮尺寸档。
enum MiButtonSize {
  /// 常规档：高 28.3dp（**设计度量**，参考素材的「关注」按钮）。
  regular,

  /// 大号档：高 40dp、内边距 20dp、标签 15dp（**参考实现值**，对齐
  /// flutter_miuix `MiuixButtonDefaults.minHeight`）。
  large,
}

/// 胶囊按钮（明暗双模式；主 / 次级 / 文本三形态，常规 / 大号两档）。
///
/// 规格（几何见 [MiButtonMetrics]、配色见 `theme/button_tokens.dart`）：
/// 常规档高 28.3dp stadium、左右内边距 17dp、标签 13dp Medium，宽度随内容
/// 自适应；主按钮填充 [MiColors.accent]（明暗同色）。
///
/// ## 内容
///
///  * [label] 与 [child] 二选一（两者都空是构造期断言失败）：前者是纯文案
///    的快捷写法，后者给图标 / 富文本 / 任意内容，文字仍继承按钮标签样式
///    与标签色；
///  * [icon] 是从上游 flutter_miuix `MiuixButton(child:)` 收编的常用形态：
///    前置图标按 [MiButtonMetrics.iconSize] 定尺（16dp，与 13dp 标签同档），
///    与文案间隔 [MiButtonMetrics.iconGap]；
///  * [minWidth] 只在调用方显式给出时施加 —— 本库按钮是**内容自适应**
///    胶囊，不搬上游默认 58dp 的最小宽。
///
/// ## 状态
///
///  * [onPressed] 为 `null` **或** [enabled] 为 false 时进入禁用态（推导值：
///    填充 / 标签换禁用配方）；[enabled] 用来在不丢回调的前提下临时禁用
///    （上游 `MiuixButton(enabled:)` 同语义）；
///  * 文本形态禁用时填充保持透明、只降标签墨色。
///
/// 形态 / 尺寸 / 状态切换时填充与标签色以 200ms 过渡（`easeOut`）。
class MiButton extends StatelessWidget {
  const MiButton({
    super.key,
    this.label,
    this.child,
    this.icon,
    this.onPressed,
    this.enabled = true,
    this.variant = MiButtonVariant.filled,
    this.size = MiButtonSize.regular,
    this.minWidth,
    this.themeMode,
  })  : assert(label != null || child != null, 'label 与 child 至少给一个'),
        assert(minWidth == null || minWidth >= 0, 'minWidth 不能为负');

  /// 按钮文案（与 [child] 二选一）。
  final String? label;

  /// 自定义内容（与 [label] 二选一）；文字继承按钮标签样式与标签色。
  final Widget? child;

  /// 前置图标（按 16dp 定尺陈列，与文案间隔 6dp）。
  final Widget? icon;

  /// 点按回调；为 null 时按钮进入禁用态。
  final VoidCallback? onPressed;

  /// 是否可用（false = 禁用，回调保留但不触发）。
  final bool enabled;

  /// 按钮形态（主 / 次级 / 文本）。
  final MiButtonVariant variant;

  /// 尺寸档（常规 / 大号）。
  final MiButtonSize size;

  /// 最小宽度；null = 完全随内容收缩。
  final double? minWidth;

  /// 明暗模式，驱动配色配方；null = 跟随 [MiTheme]，未声明时默认深色
  /// （行为与旧版一致）。
  final MiThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    final mode = MiTheme.modeOfOr(
      context,
      explicit: themeMode,
      fallback: MiThemeMode.dark,
    );
    final palette = MiButtonPalette.of(
      mode,
      accent: MiTheme.maybeOf(context)?.accent,
    );
    final active = enabled && onPressed != null;
    final large = size == MiButtonSize.large;
    final (fill, labelColor) = !active
        ? (
            variant == MiButtonVariant.text
                ? MiTransparencyTokens.clear
                : palette.disabledFill,
            palette.disabledLabel,
          )
        : switch (variant) {
            MiButtonVariant.filled => (palette.filledFill, palette.filledLabel),
            MiButtonVariant.tonal => (palette.tonalFill, palette.tonalLabel),
            // 文本形态：无填充 + 强调色标签（品牌色注入时跟随 filledFill）。
            MiButtonVariant.text => (
                MiTransparencyTokens.clear,
                palette.filledFill,
              ),
          };
    final labelStyle = (large
            ? MiTypography.buttonLabelLarge
            : MiTypography.buttonLabel)
        .copyWith(color: labelColor);

    Widget content = label != null
        ? Text(
            label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          )
        // 自定义内容也拿到同一套标签样式（未显式设色的 Text 会继承）。
        : DefaultTextStyle.merge(style: labelStyle, child: child!);
    if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: MiButtonMetrics.iconSize,
            child: icon,
          ),
          const SizedBox(width: MiButtonMetrics.iconGap),
          Flexible(child: content),
        ],
      );
    }

    return Semantics(
      button: true,
      enabled: active,
      // 三态反馈（悬停叠色 + 手型光标、Tab 焦点环 + Enter / Space 激活、
      // 按压状态机）收编自 MiPressable（描边与叠色实色、不引 saveLayer，
      // 见各基础件文档）。按钮素材无按压帧 —— 不发明按压视觉
      //（pressBuilder 缺省）；悬停 / 焦点只给可点态（禁用态不该有
      //「可点」暗示），由 MiPressable 按 enabled 门控。
      child: MiPressable(
        onPressed: active ? onPressed : null,
        mode: mode,
        borderRadius: BorderRadius.circular(MiDimens.radiusPill),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: MiButtonMetrics.pressDurationMs,
          ),
          curve: Curves.easeOut,
          height: large ? MiButtonMetrics.largeHeight : MiButtonMetrics.height,
          // 只有调用方要最小宽时才多这一层约束，默认结构不变。
          constraints:
              minWidth == null ? null : BoxConstraints(minWidth: minWidth!),
          padding: EdgeInsets.symmetric(
            horizontal: large
                ? MiButtonMetrics.largeHorizontalPadding
                : MiButtonMetrics.horizontalPadding,
          ),
          decoration: ShapeDecoration(
            color: fill,
            shape: const MiSquircleBorder(MiDimens.radiusPill),
          ),
          // 宽度随内容收缩：Center 带 widthFactor 才不会在有界父级
          //（Center/Column）里被拉满宽 —— 度量按钮是内容自适应的胶囊。
          child: Center(widthFactor: 1.0, child: content),
        ),
      ),
    );
  }
}
