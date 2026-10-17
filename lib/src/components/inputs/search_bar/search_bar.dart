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
class MiSearchBar extends StatelessWidget {
  const MiSearchBar({
    super.key,
    required this.hint,
    this.onTap,
    this.themeMode,
    this.frosted = true,
  });

  /// 占位文字。
  final String hint;

  /// 点按回调；null = 不参与手势。
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

  @override
  Widget build(BuildContext context) {
    final mode = themeMode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    final palette = MiSearchBarPalette.of(mode);
    // 磨砂取景框裁到 stadium 形状（与玻璃导航栏 / 胶囊同款：clip →
    // backdrop → 半透明填充 → 内容），只有栏内透射磨砂，栏外不糊。
    // [frosted] 为 false 时跳过 backdrop，只留半透明填充（材质由顶栏给）。
    Widget bar = ClipRRect(
      borderRadius: BorderRadius.circular(MiDimens.radiusPill),
      child: frosted
          ? BackdropFilter(
              // σ 固定 → 复用缓存的 native filter（每帧重建是纯开销）
              filter: MiFilterCache.blur(MiTransparencyTokens.blurSigma),
              child: _content(palette),
            )
          : _content(palette),
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

  /// 填充 + 内容（图标 / 占位文字），与是否自绘磨砂无关。
  Widget _content(MiSearchBarPalette palette) {
    return ColoredBox(
      color: palette.fill,
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
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MiTypography.searchHint.copyWith(color: palette.hint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
