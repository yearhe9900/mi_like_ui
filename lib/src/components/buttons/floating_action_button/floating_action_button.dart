import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/mi_theme.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../foundations/pressable.dart';
import '../../../foundations/squircle.dart';
import 'floating_action_button_metrics.dart';

/// 浮动操作按钮（`MiFloatingActionButton`）：正圆主行动按钮，可选投影。
///
/// 用于**悬浮在内容之上**的主要操作（新建 / 发起 / 快捷动作）。几何与投影
/// 口径见 [MiFloatingActionButtonMetrics]（本库无独立 FAB 素材，标注为
/// 参考实现值）；配色只引用既有 token —— 默认填充 = [MiColors.fabGreenFor]
/// （素材度量的「预留空位圆形按钮底色」暗 #25BF43 / 浅 #66CB61）。
///
/// ```dart
/// MiFloatingActionButton(
///   onPressed: _compose,
///   child: const Icon(Icons.add),
/// )
/// ```
///
/// ## 结构
///
///  * **填充即按压视觉**：`pressBuilder` 直接把圆底换成按压色（
///    `MiTransparencyTokens.dialogPressedFill` 预合成单色，与弹框按钮同一
///    手法 —— 叠色只压填充、不碰内容，也不引 saveLayer）；未按压时就是
///    一枚正圆填充；
///  * **三态反馈走 `MiPressable`**：按压状态机 + 悬停叠色（白 / 黑 @5.6%）
///    + Tab 焦点环与 Enter / Space 激活；[onPressed] 为 `null` **或**
///    [enabled] 为 false 即禁用（不进按压态、不响应）；
///  * **投影画在形状之外**：`MiSquircleShadowPainter` 路径投影，不套
///    `BoxShadow` 的 elevation 语义、不引 saveLayer —— 放在含磨砂的页面里
///    不影响下层 `BackdropFilter`（[showShadow] 可关）；
///  * **内容色**向下传给 `DefaultTextStyle` / `IconTheme`（默认前景墨色
///    [MiColors.foregroundFor] 口径），调用方给的显式颜色优先级更高；
///    边长由父级约束决定：给了更紧的约束就按约束走，否则至少 [size]。
///
/// ## 与导航栏圆钮的关系
///
/// `MiGlassNavBar` / `MiGlassSideNavBar` 的槽位圆钮（`MiGlassNavFab`）就是
/// 本组件 —— 导航栏侧显式 `showShadow: false`（素材实测：圆钮是栏体的一
/// 分部，无投影），其余几何与交互同源。**不要**把本组件与那颗 ⌀55.4 的
/// 槽位尺寸混为一谈：那是导航栏度量，本组件默认 60dp。
class MiFloatingActionButton extends StatelessWidget {
  const MiFloatingActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
    this.color,
    this.size = MiFloatingActionButtonMetrics.size,
    this.showShadow = true,
    this.themeMode,
    this.focusNode,
  }) : assert(size > 0, 'size 必须为正');

  /// 填充层的 key（测试读填充色与圆心；不是公开 API 语义）。
  static const Key fillKey = Key('mi-floating-action-button-fill');

  /// 按钮内容（图标 / 任意内容，居中陈列）。
  final Widget child;

  /// 点按回调；为 null 时按钮进入禁用态。
  final VoidCallback? onPressed;

  /// 是否可用（false = 禁用，回调保留但不触发）。
  final bool enabled;

  /// 填充色；null = [MiColors.fabGreenFor]（明暗各自的素材度量绿）。
  final Color? color;

  /// 最小边长（正圆直径）；父级约束更紧时以父级为准。
  final double size;

  /// 是否画投影（见类注释；导航栏槽位圆钮传 false）。
  final bool showShadow;

  /// 明暗模式，驱动填充与内容墨色；null = 跟随 [MiTheme]。
  final MiThemeMode? themeMode;

  /// 外部键盘焦点节点；null = 自建（由 `MiPressable` 挂 Tab 停靠）。
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final mode = MiTheme.modeOf(context, explicit: themeMode);
    final active = enabled && onPressed != null;
    final fill = color ?? MiColors.fabGreenFor(mode);
    final ink = MiColors.foregroundFor(mode);

    Widget body = ConstrainedBox(
      // 边长下限：父级（导航栏槽位）给了更紧的约束时，`enforce` 会按父级
      // 走 —— 这就是同一枚组件既能 60dp 独立放、又能贴进 ⌀55.4 槽位的原因。
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      child: Semantics(
        button: true,
        enabled: active,
        child: MiPressable(
          onPressed: active ? onPressed : null,
          mode: mode,
          // 悬停叠色与焦点环的圆角跟随正圆；父级给更紧的盒子时，
          // 这里超出边长一半的半径会被 BoxDecoration 夹回正圆。
          borderRadius: BorderRadius.circular(size / 2),
          focusNode: focusNode,
          // 结构恒定（按压 / 未按压都是同一个 DecoratedBox）：静止态
          // 像素不变，黄金图不受影响。
          pressBuilder: (context, pressed, child) => DecoratedBox(
            key: MiFloatingActionButton.fillKey,
            decoration: ShapeDecoration(
              color: pressed
                  ? MiTransparencyTokens.dialogPressedFill(fill, mode)
                  : fill,
              shape: const CircleBorder(),
            ),
            child: child,
          ),
          child: Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: DefaultTextStyle.merge(
              style: TextStyle(color: ink),
              child: IconTheme.merge(
                data: IconThemeData(color: ink),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

    if (showShadow) {
      body = CustomPaint(
        painter: MiSquircleShadowPainter(
          radius: size / 2,
          shadows: const [
            BoxShadow(
              color: MiTransparencyTokens.panelShadow,
              blurRadius: MiFloatingActionButtonMetrics.shadowBlurRadius,
              offset: MiFloatingActionButtonMetrics.shadowOffset,
            ),
          ],
        ),
        child: body,
      );
    }
    return body;
  }
}
