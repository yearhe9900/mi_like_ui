import 'package:flutter/material.dart';

import '../../../theme/floating_toolbar_tokens.dart';
import '../../../theme/mi_theme.dart';
import '../../../theme/theme_mode.dart';
import '../../../utils/squircle.dart';
import 'floating_toolbar_metrics.dart';

/// 悬浮工具栏（`MiFloatingToolbar`）：一块浮在内容之上的胶囊容器。
///
/// 只做**容器**，不安排方向：[child] 里用 `Row` 还是 `Column` 由调用方定
/// （横排 = 一排图标钮，纵排 = 缩放类迷你工具条）。结构（自外向内）：
/// 外留白 [padding] → squircle 投影 → 表面（squircle）→ 可选描边 → 内容。
/// 几何口径见 [MiFloatingToolbarMetrics]，配色见
/// `theme/floating_toolbar_tokens.dart`。
///
/// ```dart
/// MiFloatingToolbar(
///   showDivider: true,
///   child: Row(mainAxisSize: MainAxisSize.min, children: [ …按钮… ]),
/// )
/// ```
///
/// ## 行为
///
///  * **吃掉点击**：容器带 opaque 命中行为，点空白处不会穿透到背后的内容；
///    内部按钮仍在手势竞技场里正常胜出（命中测试自下而上，子级先拿）；
///  * **投影是固定几何**：[showShadow] 只决定画不画，不随尺寸 / 内容变化
///    （它不是 elevation —— 工具栏换内容不该换阴影）；
///  * **不引离屏**：投影走 [MiSquircleShadowPainter]（`MaskFilter.blur` 的
///    路径投影），不套 `BoxShadow` 的 elevation 语义、也不加 saveLayer ——
///    放在含磨砂的页面里不影响下层 `BackdropFilter`。
class MiFloatingToolbar extends StatelessWidget {
  const MiFloatingToolbar({
    super.key,
    required this.child,
    this.color,
    this.cornerRadius = MiFloatingToolbarMetrics.cornerRadius,
    this.padding = MiFloatingToolbarMetrics.outsidePadding,
    this.showShadow = true,
    this.showDivider = false,
    this.themeMode,
  });

  /// 内容（横排 / 纵排由调用方决定）。
  final Widget child;

  /// 表面色；null = 取 [MiFloatingToolbarPalette.surface]。
  final Color? color;

  /// 圆角（大于半高时按胶囊画真半圆端头）。
  final double cornerRadius;

  /// 外留白（工具栏与屏幕边缘 / 周围内容的间距）。
  final EdgeInsetsGeometry padding;

  /// 是否画投影（几何固定，见类注释）。
  final bool showShadow;

  /// 是否画 0.75dp 描边。
  final bool showDivider;

  /// 明暗模式；为空时跟随 [MiTheme]，未声明时跟环境 `Theme` 亮度。
  final MiThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    final mode = MiTheme.modeOf(context, explicit: themeMode);
    final palette = MiFloatingToolbarPalette.of(mode);
    final surface = DecoratedBox(
      decoration: ShapeDecoration(
        color: color ?? palette.surface,
        shape: MiSquircleBorder(
          cornerRadius,
          side: showDivider
              ? BorderSide(
                  color: palette.divider,
                  width: MiFloatingToolbarMetrics.dividerWidth,
                )
              : BorderSide.none,
        ),
      ),
      child: child,
    );

    return Padding(
      padding: padding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: showShadow
            ? CustomPaint(
                painter: MiSquircleShadowPainter(
                  radius: cornerRadius,
                  shadows: <BoxShadow>[
                    BoxShadow(
                      color: palette.shadow,
                      blurRadius: MiFloatingToolbarMetrics.shadowBlurRadius,
                      offset: MiFloatingToolbarMetrics.shadowOffset,
                    ),
                  ],
                ),
                child: surface,
              )
            : surface,
      ),
    );
  }
}
