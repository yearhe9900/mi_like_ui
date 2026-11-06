import 'package:flutter/material.dart';

import '../../foundations/pressable.dart';
import '../../theme/menu_tokens.dart';
import '../../theme/mi_theme.dart';
import '../../theme/theme_mode.dart';
import '../../theme/transparency_tokens.dart';
import '../../theme/typography.dart';
import 'menu_metrics.dart';
import 'menu_painter.dart';

/// 菜单行（`MiMenuItemRow`）：一行「前导 + 主文案（+ 副文案）+ 行尾装饰」。
///
/// 这是 [MiMenu] 面板里那一行的**公开形态** —— 结构与几何对应参考实现
/// flutter_miuix（Apache-2.0）`MiuixDropdownImpl`（上游 compose-miuix 的
/// 下拉菜单项），数值逐项取自 [MiMenuMetrics] 的「本类 ↔ 参考字段」表；
/// 配色走 [MiMenuPalette]（全部落在既有 token 上，不新造色值）。
///
/// 单独拿出来是因为「一行选项」不止菜单在用：对话框选项列表、自定义弹层、
/// 级联导航的返回行都能直接复用，不必把 [MiMenu] 的整套锚定 / 遮罩搬过来。
/// [MiMenu] 内部同样由本件渲染，几何只有一处定义。
///
/// ## 行为
///
///  * **点按**：经 [MiPressable] 拿到三态（按压高亮 150ms + 悬停叠色 + Tab
///    焦点环与 Enter / Space 激活）；[onTap] 为 null 或 [enabled] 为 false
///    时整行禁用（墨色降档、不响应）；
///  * **行尾装饰**由状态推导，优先级 [selected]（勾号）> [showBackArrow]
///    （左向箭头，级联回退）> [hasChildren]（右向箭头，级联触发器）；
///  * **行上下内边距**恒取 [MiMenuMetrics.rowPadY]（20dp，所有行统一 ——
///    参考实现的首末 / 中间两档会让整列间距上疏下紧，本库不跟）；
///  * 行尾装饰**不参与行高**：槽钉 0 高、墨盒按行中线居中溢出绘制，否则
///    20dp 的勾号会把 15.9dp 文案的行撑高 4.1dp（见 [MiMenuMetrics.checkSide]）。
///
/// 几何 / 动效均为**参考实现值**（本库无菜单素材），素材到位后按实机复核。
class MiMenuItemRow extends StatelessWidget {
  const MiMenuItemRow({
    super.key,
    required this.label,
    this.subtitle,
    this.leading,
    this.selected = false,
    this.enabled = true,
    this.hasChildren = false,
    this.showBackArrow = false,
    this.onTap,
    this.themeMode,
  });

  /// 三种行尾装饰的 key（测试定位用，不是公开 API 语义）。
  static const Key checkKey = Key('mi-menu-item-row-check');
  static const Key chevronKey = Key('mi-menu-item-row-chevron');
  static const Key backChevronKey = Key('mi-menu-item-row-back-chevron');

  /// 主文案（单行，超宽省略）。
  final String label;

  /// 副标题（主文案下方一行，次级墨色）。
  final String? subtitle;

  /// 前导内容（图标 / 色块等，落在 26dp 的单元格里）。
  final Widget? leading;

  /// 是否处于选中态（主文案转强调色 + 尾部勾号）。
  final bool selected;

  /// 是否可点（false = 整行禁用墨色、不响应）。
  final bool enabled;

  /// 是否是级联触发器（尾部画右向箭头）。
  final bool hasChildren;

  /// 是否是级联回退行（尾部画左向箭头，语义「回到上一级」）。
  final bool showBackArrow;

  /// 点按回调；null = 该行不可点。
  final VoidCallback? onTap;

  /// 明暗模式；null = 跟随 [MiTheme] / 环境亮度。
  final MiThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    final mode = MiTheme.modeOf(context, explicit: themeMode);
    final palette = MiMenuPalette.of(mode);
    final labelColor = !enabled
        ? palette.disabled
        : (selected ? palette.selectedLabel : palette.label);
    final subtitleColor = enabled ? palette.secondary : palette.disabled;
    final trailing = _trailingFor(palette);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: MiPressable(
        onPressed: enabled ? onTap : null,
        mode: mode,
        pressBuilder: (context, pressed, child) => AnimatedContainer(
          duration: const Duration(milliseconds: MiMenuMetrics.pressMs),
          curve: MiMenuMetrics.pressCurve,
          color: pressed ? palette.pressed : MiTransparencyTokens.clear,
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MiMenuMetrics.rowInsetX,
            vertical: MiMenuMetrics.rowPadY,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: MiMenuMetrics.iconCell,
                    minHeight: MiMenuMetrics.iconCell,
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: MiMenuMetrics.iconGap,
                    ),
                    child: leading,
                  ),
                ),
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
                      style: MiTypography.dialogAction.copyWith(
                        color: labelColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: MiMenuMetrics.subtitleGap),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MiTypography.dialogItemSubtitle.copyWith(
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: MiMenuMetrics.trailingGap,
                  ),
                  child: trailing,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 行尾装饰：选中勾号优先，其次级联回退的左箭头，再是级联触发器的右箭头。
  Widget? _trailingFor(MiMenuPalette palette) {
    if (selected) {
      return _slot(
        key: checkKey,
        width: MiMenuMetrics.checkSide,
        height: MiMenuMetrics.checkSide,
        painter: MiMenuCheckPainter(palette.selectedLabel),
      );
    }
    if (showBackArrow) {
      return _slot(
        key: backChevronKey,
        width: MiMenuMetrics.arrowSize.width,
        height: MiMenuMetrics.arrowSize.height,
        // 左向箭头 = 「回到上一级」的语义（参考实现复用右向箭头，见
        // `MiMenuChevronPainter.back` 的说明）。
        painter: MiMenuChevronPainter(palette.secondary, back: true),
      );
    }
    if (!hasChildren) return null;
    return _slot(
      key: chevronKey,
      width: MiMenuMetrics.arrowSize.width,
      height: MiMenuMetrics.arrowSize.height,
      painter: MiMenuChevronPainter(palette.secondary),
    );
  }

  /// 行尾装饰槽：**只吃宽度、不吃高度**，装饰按行垂直中线居中溢出绘制。
  ///
  /// 勾号墨盒 20dp 高于正文行盒（`MiTypography.dialogAction` 15.9dp，
  /// `height: 1.0`），若让槽参与行高计算，选中行就比普通行高 4.1dp —— 上下
  /// 两个相邻中心距各 +2dp，读起来是「选中项上下更松」。这里把槽钉成 0 高、
  /// 用 [OverflowBox] 让墨盒以行的中线为心画到槽外（溢出 2.05dp 落在 20dp
  /// 行内边距里，不碰相邻行），行高于是只由文案块决定。参考实现同样让勾号
  /// 参与行高，差别在它的正文行盒 ≈18.7dp（差值仅 1.3dp，看不出来）。
  Widget _slot({
    required Key key,
    required double width,
    required double height,
    required CustomPainter painter,
  }) {
    return SizedBox(
      key: key,
      width: width,
      height: 0,
      child: OverflowBox(
        maxWidth: width,
        maxHeight: height,
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(painter: painter),
        ),
      ),
    );
  }
}

/// 参考实现 `MiuixDropdownImpl` 的同位名。
///
/// 本库命名习惯下这一行叫 [MiMenuItemRow]（`Impl` 是上游的内部命名，
/// 不是给使用方的词汇）；别名只为了让与 flutter_miuix 的对照 / 移植检索
/// 不断链，新代码请用 [MiMenuItemRow]。
typedef MiDropdownImpl = MiMenuItemRow;
