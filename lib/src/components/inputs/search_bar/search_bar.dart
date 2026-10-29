import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/dimens.dart';
import '../../../theme/search_bar_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../theme/typography.dart';
import '../../../utils/filter_cache.dart';
import '../../../utils/glass_rim.dart';
import '../../../utils/pressable.dart';
import '../../../utils/squircle.dart';
import 'search_bar_metrics.dart';
import 'search_bar_painter.dart';

/// 搜索栏（明暗双模式，静态展示 / 可输入两态）。
///
/// 几何与配色规格见 [MiSearchBarMetrics] / `theme/search_bar_tokens.dart`：
/// stadium 高 44.1dp，图标 17.8dp、图文间距 12dp、左缘内缩 15.4dp，
/// 占位文字 16.5dp，全部垂直居中。
///
/// **透明参数与导航栏同源**（`theme/transparency_tokens.dart`）：栏体带
/// backdrop 磨砂（σ = [MiTransparencyTokens.blurSigma]），填充为半透明
/// 表面色（平底合成实色亮 #E7E7E7 / 暗 #242424）——滚动内容从搜索栏后方
/// 经过时透出磨砂质感，与胶囊标签行、玻璃导航栏同属一套透明语言。
///
/// [themeMode] 为空时跟随环境 `Theme.of(context).brightness`；点按经
/// [onTap] 回调（为空则不参与手势）。
///
/// ## 输入态（`editable: true`）
///
/// 同一几何，占位文字位置替换为真实输入框（`TextField` +
/// `InputDecoration.collapsed`）：放大镜与占位文字保持原位，左侧显示
/// 闪烁光标（与占位文字同现）。
///
///  * 光标色 = 强调蓝（[MiSearchBarPalette.caret]）；
///  * 光标高 21.3dp（[MiSearchBarMetrics.caretHeight]）为绝对值，
///    不随字体行盒漂移；
///  * 光标闪烁 500ms 亮 / 500ms 灭，与 Flutter `EditableText` 默认半周期
///    一致，不另行配置。
class MiSearchBar extends StatelessWidget {
  const MiSearchBar({
    super.key,
    required this.hint,
    this.onTap,
    this.themeMode,
    this.frosted = true,
    this.overContent = false,
    this.rimProgress = 1.0,
    this.editable = false,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  /// 占位文字（`editable` 时同时是输入框的 hint）。
  final String hint;

  /// 点按回调；null = 不参与手势。
  ///
  /// `editable` 时它仍会触发（在聚焦之外），方便宿主做页面级副作用。
  final VoidCallback? onTap;

  /// 明暗模式；null = 跟随环境 Theme 亮度。
  final MiThemeMode? themeMode;

  /// 是否自绘 backdrop 磨砂（默认 true）。
  ///
  /// 放进**自带材质的顶栏**（`MiTopBar(showSurface: true)` 的头部区）时传
  /// `false`：磨砂由顶栏那条渐进曲线统一提供，再叠一层等于两次高斯 ——
  /// 既让栏内比周围更糊（与「统一材质」相悖），也多一份每帧全 QUAD 开销。
  /// 只保留半透明填充：平底合成仍等于素材度量实色。
  final bool frosted;

  /// 是否铺**玻璃膜**（默认 false）—— 压在照片/视频等内容上时开启。
  ///
  /// 平底页填充是 onSurface@13/36 的低调半透明（合成 #E7E7E7 / #242424）；
  /// 压在内容上时再垫一层页面色 @0.46(亮)/纯黑 @0.59(暗) 的膜，否则整条栏
  /// 在杂乱背景上会糊成一片、边缘读不出来。两层预合成成一个等效色
  /// （[MiTransparencyTokens.veiledFill]）：平底页观感不变。
  final bool overContent;

  /// 内缘亮边激活进度（0…1，默认 1 = 常亮）。
  ///
  /// **内容靠近顶栏一定程度才亮**（参考实测：内容距栏底 ≲20dp 时玻璃
  /// 进入激活态；静止且内容较远时亮边 = 0，不是常驻描边）。顶栏按滚动
  /// 位置下发（见 `MiTopBarMetrics.rimFadeDistance`）；独立使用时按需传。
  final double rimProgress;

  /// 是否变成**可真输入**的搜索栏（默认 false = 只展示占位文字）。
  ///
  /// 打开后中间换成 `TextField`，聚焦即弹键盘、出光标；放大镜与占位文字
  /// 位置不变（度量行为）。
  final bool editable;

  /// 输入框控制器（仅 [editable] 生效；null = 组件自建）。
  final TextEditingController? controller;

  /// 输入焦点节点（仅 [editable] 生效；null = 组件自建）。
  ///
  /// 搜索态一般由顶栏统一下发，宿主点 × 时可以直接 `unfocus()`。
  final FocusNode? focusNode;

  /// 是否自动聚焦（仅 [editable] 生效，默认 false）。
  final bool autofocus;

  /// 输入变化回调（仅 [editable] 生效）。
  final ValueChanged<String>? onChanged;

  /// 键盘提交回调（仅 [editable] 生效）。
  final ValueChanged<String>? onSubmitted;

  /// 键盘回车键语义（仅 [editable] 生效；null = 用 `TextInputAction.search`）。
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final mode = themeMode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    final palette = MiSearchBarPalette.of(mode);
    // 未选填充两态：平底 = 低调半透明（palette.fill）；压内容 = 该档再垫一层
    // 玻璃膜（预合成为单色，平底观感不变）。
    final fill = overContent
        ? MiTransparencyTokens.veiledFill(palette.fill, mode)
        : palette.fill;
    // 磨砂取景框裁到 stadium 形状（与玻璃导航栏 / 胶囊同款：clip →
    // backdrop → 半透明填充 → 内容），只有栏内透射磨砂，栏外不糊。
    // [frosted] 为 false 时跳过 backdrop，只留半透明填充（宿主另有整条
    // 材质时用；顶栏内的内置搜索栏**仍自绘玻璃**——顶栏那层是随 y 衰减的
    // 背景磨砂，零件自己那层才是它的「透明模糊属性」）。
    Widget bar = ClipPath(
      clipper: const MiSquircleClipper(MiDimens.radiusPill),
      child: frosted
          ? BackdropFilter(
              // σ 固定 → 复用缓存的 native filter（每帧重建是纯开销）
              filter: MiFilterCache.blur(MiTransparencyTokens.blurSigma),
              child: _content(palette, fill),
            )
          : _content(palette, fill),
    );
    // 内缘亮边（「边缘逐渐变亮」的受光边）：贴边缘内侧 ~1dp、向内羽化收尾；
    // 颜色/宽度见 `MiGlassRimPainter` 与 `MiTransparencyTokens.surfaceRimFor`。
    bar = CustomPaint(
      foregroundPainter: MiGlassRimPainter(
        color: MiTransparencyTokens.surfaceRimFor(mode, progress: rimProgress),
        radius: MiDimens.radiusPill,
      ),
      child: bar,
    );
    if (onTap != null) {
      // 三态反馈统一入口：悬停叠色铺在**整条**之上（圆角与栏体同档，
      // 避免方角）+ 点按进搜索（推导桌面语义同惯例）。
      //
      // **焦点环刻意不挂**（`focus: false`）：点按可点形态时，点击会把
      // 焦点给到包装层（`Focus.hasFocus` 含后代聚合），随即切换的可编辑
      // 形态又要 autoFocus 输入框 —— 两代焦点链互相干扰（预览实测：
      // 暗色下点击后环被祖先聚合点亮、描边常驻）。搜索的键盘可达性走
      // ⌘K / 宿主路径（示例层 MiSearchShortcuts），不占 Tab 停靠。
      bar = MiPressable(
        onPressed: onTap,
        mode: mode,
        focus: false,
        borderRadius: BorderRadius.circular(MiDimens.radiusPill),
        child: bar,
      );
    }
    return bar;
  }

  /// 填充 + 内容（图标 / 占位文字或输入框），与是否自绘磨砂无关。
  Widget _content(MiSearchBarPalette palette, Color fill) {
    return ColoredBox(
      color: fill,
      child: SizedBox(
        height: MiSearchBarMetrics.barHeight,
        child: Row(
          children: [
            const SizedBox(width: MiSearchBarMetrics.contentInset),
            CustomPaint(
              painter: SearchIconPainter(color: palette.icon),
              size: const Size.square(MiSearchBarMetrics.iconSize),
            ),
            const SizedBox(width: MiSearchBarMetrics.iconGap),
            Flexible(
              child: editable
                  ? _field(palette)
                  : Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MiTypography.searchHint.copyWith(
                        color: palette.hint,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 可输入态：`TextField` 走同一条 hint 样式与同一段横向位置。
  ///
  /// 用 `InputDecoration.collapsed` 而不是默认装饰 —— 后者自带 12dp 左右的
  /// 内边距与最小高，会把文字推离度量位置（hint 起点就不在 iconGap 之后了）。
  ///
  /// 已输入文字用**前景墨色**（[MiSearchBarPalette.cancelInk]）：参考素材
  /// 全程没输入过文字，这档属于推导 —— 依据是同页叉号度量就是前景墨色，
  /// 输入的文字没理由比它淡。
  Widget _field(MiSearchBarPalette palette) {
    final style = MiTypography.searchHint.copyWith(color: palette.cancelInk);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction ?? TextInputAction.search,
      style: style,
      cursorColor: palette.caret,
      cursorHeight: MiSearchBarMetrics.caretHeight,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration.collapsed(
        hintText: hint,
        hintStyle: MiTypography.searchHint.copyWith(color: palette.hint),
        border: InputBorder.none,
      ),
    );
  }
}
