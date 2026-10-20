import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/dimens.dart';
import '../../../theme/search_bar_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../theme/typography.dart';
import '../../../utils/filter_cache.dart';
import 'search_bar_metrics.dart';
import 'search_bar_painter.dart';

/// 小米主题商店风格搜索栏（深/浅色双模式）。
///
/// 几何 / 配色 1:1 实测自亮/暗分类页完整截图（几何见 [MiSearchBarMetrics]、
/// 配方见 `theme/search_bar_tokens.dart`）：stadium 高 44.1，图标 17.8 +
/// 图文间距 12 起于左缘 15.4，占位文字 16.5dp CJK advance，全部垂心居中。
///
/// **透明参数与底部导航栏同源**（`theme/transparency_tokens.dart`）：
/// 栏体下叠与 [MiGlassNavBar] 同款 backdrop 磨砂（sigma =
/// [MiTransparencyTokens.blurSigma]），填充为半透明表面（平底合成 =
/// 截图实测实色 #E7E7E7 / #242424，档位推导见 palette 注释）——滚动
/// 内容从搜索栏后方经过时透上来并被磨出毛玻璃感，与胶囊标签行、玻璃
/// 导航栏构成同一套透明语言。
///
/// [themeMode] 为空时跟随环境 `Theme.of(context).brightness`（demo
/// 首页列表里的 const 用法即靠此推导）；点按经 [onTap] 回调（为空则
/// 不参与手势）。
///
/// ## 搜索态：`editable: true`
///
/// 同一个组件、同一套几何，只把中间的占位文字换成真的输入框
/// （`TextField` + `InputDecoration.collapsed`）：点按后**放大镜与占位文字
/// 都留在原位**，左侧多出闪烁的输入光标 —— 参考录屏实测就是这样
///（光标与 hint 同现，不是「聚焦后 hint 消失」），Flutter 的 `TextField`
/// 在空值 + 聚焦时恰好也是这个表现。
///
/// 三处实测/推导：
///  * 光标色 = 强调蓝（[MiSearchBarPalette.caret]）；
///  * 光标高 21.3dp（[MiSearchBarMetrics.caretHeight]）钉成绝对值，不随
///    字体行盒漂；
///  * 光标闪烁 500ms 亮 / 500ms 灭 —— 录屏逐帧实测亮 12 帧、灭 12 帧
///    （24fps），与 Flutter `EditableText` 默认半周期 500ms 一致，故不另设。
class MiSearchBar extends StatelessWidget {
  const MiSearchBar({
    super.key,
    required this.hint,
    this.onTap,
    this.themeMode,
    this.frosted = true,
    this.overContent = false,
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
  /// 只保留半透明填充：平底合成仍等于截图实测实色。
  final bool frosted;

  /// 是否铺**玻璃膜**（默认 false）—— 压在照片/视频等内容上时开启。
  ///
  /// 平底页填充是 onSurface@13/36 的低调半透明（合成 #E7E7E7 / #242424）；
  /// 压在内容上时再垫一层页面色 @0.46(亮)/纯黑 @0.59(暗) 的膜，否则整条栏
  /// 在杂乱背景上会糊成一片、边缘读不出来。两层预合成成一个等效色
  /// （[MiTransparencyTokens.veiledFill]）：平底页观感不变。
  final bool overContent;

  /// 是否变成**可真输入**的搜索栏（默认 false = 只展示占位文字）。
  ///
  /// 打开后中间换成 `TextField`，聚焦即弹键盘、出光标；放大镜与占位文字
  /// 位置不变（实测行为）。
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
    // [frosted] 为 false 时跳过 backdrop，只留半透明填充（材质由顶栏给）。
    Widget bar = ClipRRect(
      borderRadius: BorderRadius.circular(MiDimens.radiusPill),
      child: frosted
          ? BackdropFilter(
              // σ 固定 → 复用缓存的 native filter（每帧重建是纯开销）
              filter: MiFilterCache.blur(MiTransparencyTokens.blurSigma),
              child: _content(palette, fill),
            )
          : _content(palette, fill),
    );
    if (onTap != null) {
      bar = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
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
  /// 内边距与最小高，会把文字推离实测位置（hint 起点就不在 iconGap 之后了）。
  ///
  /// 已输入文字用**前景墨色**（[MiSearchBarPalette.cancelInk]）：参考录屏
  /// 全程没输入过文字，这档属于推导 —— 依据是同页叉号实测就是前景墨色，
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
