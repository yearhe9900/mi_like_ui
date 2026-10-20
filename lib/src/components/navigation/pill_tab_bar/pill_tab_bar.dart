import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/dimens.dart';
import '../../../theme/pill_tab_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../theme/typography.dart';
import '../../../utils/filter_cache.dart';
import 'pill_tab_bar_metrics.dart';

/// 小米主题商店风格的胶囊分类标签行（深/浅色双模式）。
///
/// [labels] 以定宽胶囊排成一行，可横向滚动（超出视口自动裁切滚动，
/// 与截图中第 4 个胶囊被屏幕右缘裁切的行为一致）。选中项高不透明胶囊 +
/// 高对比标签，未选中低对比胶囊 + 反色标签；明暗配方均为完整截图
/// 实测（亮色 = 深胶囊白字，暗色 = 白胶囊黑字 + 低调深灰未选胶囊），
/// 取值见 `theme/pill_tab_tokens.dart`，几何见 [MiPillTabMetrics]。
///
/// 透明效果与玻璃导航栏同源（`theme/transparency_tokens.dart`）：
/// 胶囊填充为半透明表面（平底合成 = 实测实色），胶囊下叠与
/// [MiGlassNavBar] 同款 backdrop 磨砂（sigma = [MiTransparencyTokens.blurSigma]），
/// 内容从胶囊后方经过时透上来并被磨出毛玻璃感。渲染分两遍：
/// 先画**整行一次**的磨砂（`ClipPath` 裁出全部胶囊形状 + 单个
/// `BackdropFilter`，此时画布上还没有任何填充，backdrop 只含背景/身后内容，
/// 相邻胶囊互不串色），再画全部填充/文案/手势。
///
/// 旧实现是「每个胶囊一个 `ClipRRect` + `BackdropFilter`」，4 个胶囊 = 4 次
/// 全 QUAD 高斯 + 4 个 saveLayer，滚动时每帧重算 —— 分类页的主要掉帧源。
/// 合并成 1 次后逐像素对比：最大灰度差 1~2 级、无任何像素差 > 2（纯 AA 舍入）。
///
/// 点按切换选中态，填充/标签色以 200ms 过渡（截图是静态参考、无动效
/// 实测，取标准过渡值；不引入按压缩放等未实测动效）。
///
/// 未选胶囊有**两种状态**（都实测）：平底页的 onSurface@6% 低调填充，
/// 与压在照片上的玻璃膜（[overContent]），不可互相推导。
class MiPillTabBar extends StatelessWidget {
  const MiPillTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onTap,
    this.itemWidth = MiPillTabMetrics.itemWidth,
    this.themeMode = MiThemeMode.dark,
    this.frosted = true,
    this.overContent = false,
  }) : assert(itemWidth > 0);
  // labels 非空与 selectedIndex 范围校验见 build()：const 构造断言不支持
  // .length 求值（放构造器会封死 const 构造）

  /// 各分类标签文案。
  final List<String> labels;

  /// 选中项下标。
  final int selectedIndex;

  /// 点按回调，参数为被点标签下标。
  final ValueChanged<int> onTap;

  /// 单个胶囊宽度；null 语义不支持，默认取实测值 [MiPillTabMetrics.itemWidth]。
  final double itemWidth;

  /// 明暗模式，驱动配色配方。
  final MiThemeMode themeMode;

  /// 是否自绘 backdrop 磨砂（默认 true）。
  ///
  /// 放进**自带材质的顶栏**（`MiTopBar(showSurface: true)` 的头部区）时传
  /// `false`：磨砂由顶栏那条渐进曲线统一提供，否则胶囊比周围更糊、且多一份
  /// 每帧全 QUAD 高斯。只保留半透明填充。
  final bool frosted;

  /// 未选胶囊是否铺**玻璃膜**（默认 false）。
  ///
  /// 平底页（分类页）的未选胶囊是 onSurface@6% 的低调填充（合成 #E5E5E5）；
  /// 压在照片/视频上时（悬浮头部区）再垫一层页面色 @0.46(亮)/纯黑
  /// @0.59(暗) 的膜 —— 否则胶囊在杂乱背景上几乎读不出形状。
  /// 两层预合成成一个等效色（[MiTransparencyTokens.veiledFill]）：垫在同色
  /// 页底上等于没垫，**平底页观感不变**，只有背景有内容时才显出玻璃片。
  /// 选中胶囊两态同款（近不透明），不参与这层膜。
  final bool overContent;

  @override
  Widget build(BuildContext context) {
    assert(labels.isNotEmpty, 'labels 不能为空');
    assert(
      selectedIndex >= 0 && selectedIndex < labels.length,
      'selectedIndex 必须落在 labels 范围内',
    );
    final palette = MiPillTabPalette.of(themeMode);
    // 未选填充两态：平底 = 低调 6% onSurface；压内容 = 该档再垫一层玻璃膜
    // （预合成为单色，平底观感不变）。
    final unselectedFill = overContent
        ? MiTransparencyTokens.veiledFill(palette.unselectedFill, themeMode)
        : palette.unselectedFill;
    // 填充/文案/手势层（与磨砂分离成两层，保证模糊源里没有填充色）。
    final fills = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      if (i > 0) fills.add(const SizedBox(width: MiPillTabMetrics.gap));
      final selected = i == selectedIndex;
      // 半透明填充 + 文案 + 手势。填充沿用 Decoration 自身圆角 AA（与截图
      // 实测的单层边缘 AA 一致，勿再外包 ClipRRect，两层 AA 叠乘会把边缘
      // 覆盖率压成 c²）。
      fills.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: itemWidth,
            height: MiPillTabMetrics.pillHeight,
            decoration: BoxDecoration(
              color: selected ? palette.selectedFill : unselectedFill,
              borderRadius: BorderRadius.circular(MiDimens.radiusPill),
            ),
            alignment: Alignment.center,
            child: Text(
              labels[i],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MiTypography.pillLabel.copyWith(
                color:
                    selected ? palette.selectedLabel : palette.unselectedLabel,
              ),
            ),
          ),
        ),
      );
    }
    final rowWidth =
        labels.length * itemWidth + (labels.length - 1) * MiPillTabMetrics.gap;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
          const EdgeInsets.symmetric(horizontal: MiPillTabMetrics.edgeInset),
      child: SizedBox(
        width: rowWidth,
        height: MiPillTabMetrics.pillHeight,
        child: Stack(
          children: [
            // 磨砂层：**一次** ClipPath 裁出全部胶囊形状 + 一个 BackdropFilter。
            // 旧实现是「每个胶囊一个 ClipRRect + BackdropFilter」= N 次全 QUAD
            // 高斯 + N 个 saveLayer（4 个胶囊即 4 次，滚动时每帧重算，是分类页
            // 的主要掉帧源）。合并后只有 1 次 —— 相邻胶囊仍不会串色：模糊层
            // 先于所有填充绘制，backdrop 里只有背景内容，没有别的胶囊填充。
            // [frosted] 为 false 时整层跳过（材质由顶栏给）。
            if (frosted)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _CapsuleStripClipper(
                      count: labels.length,
                      itemWidth: itemWidth,
                      gap: MiPillTabMetrics.gap,
                      height: MiPillTabMetrics.pillHeight,
                    ),
                    child: BackdropFilter(
                      filter:
                          MiFilterCache.blur(MiTransparencyTokens.blurSigma),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            Positioned.fill(child: Row(children: fills)),
          ],
        ),
      ),
    );
  }
}

/// 把整行裁成「N 个 stadium 胶囊」的并集（供单次 backdrop 模糊覆盖全部胶囊）。
///
/// 胶囊等宽定距，第 i 个的左缘 = `i × (itemWidth + gap)`，圆角半径取高的一半
/// （与 `BorderRadius.circular(radiusPill)` 半径钳位后的 stadium 一致）。
class _CapsuleStripClipper extends CustomClipper<Path> {
  const _CapsuleStripClipper({
    required this.count,
    required this.itemWidth,
    required this.gap,
    required this.height,
  });

  final int count;
  final double itemWidth;
  final double gap;
  final double height;

  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = Radius.circular(height / 2);
    for (var i = 0; i < count; i++) {
      final left = i * (itemWidth + gap);
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, 0, itemWidth, height),
          radius,
        ),
      );
    }
    return path;
  }

  @override
  bool shouldReclip(_CapsuleStripClipper oldClipper) =>
      oldClipper.count != count ||
      oldClipper.itemWidth != itemWidth ||
      oldClipper.gap != gap ||
      oldClipper.height != height;
}
