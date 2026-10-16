import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/dimens.dart';
import '../../../theme/pill_tab_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../theme/typography.dart';
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
/// 先画全部胶囊的磨砂取景框（此时画布上还没有任何填充，backdrop
/// 只含背景/身后内容，相邻胶囊互不串色），再画全部填充/文案/手势。
///
/// 点按切换选中态，填充/标签色以 200ms 过渡（截图是静态参考、无动效
/// 实测，取标准过渡值；不引入按压缩放等未实测动效）。
class MiPillTabBar extends StatelessWidget {
  const MiPillTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onTap,
    this.itemWidth = MiPillTabMetrics.itemWidth,
    this.themeMode = MiThemeMode.dark,
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

  @override
  Widget build(BuildContext context) {
    assert(labels.isNotEmpty, 'labels 不能为空');
    assert(
      selectedIndex >= 0 && selectedIndex < labels.length,
      'selectedIndex 必须落在 labels 范围内',
    );
    final palette = MiPillTabPalette.of(themeMode);
    final blur = ImageFilter.blur(
      sigmaX: MiTransparencyTokens.blurSigma,
      sigmaY: MiTransparencyTokens.blurSigma,
    );
    // 两遍绘制：plates（磨砂）在下、fills（填充/文案/手势）在上。
    // 所有磨砂先于任何填充绘制，backdrop 只含背景/身后内容，
    // 相邻胶囊的填充不进入彼此的模糊源（无串色）。
    final plates = <Widget>[];
    final fills = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      if (i > 0) {
        plates.add(const SizedBox(width: MiPillTabMetrics.gap));
        fills.add(const SizedBox(width: MiPillTabMetrics.gap));
      }
      final selected = i == selectedIndex;
      // pass 1：磨砂取景框 —— clip 到胶囊形状后做 backdrop 模糊，
      // 只有胶囊内部透射磨砂，间隙/行外不糊。
      plates.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(MiDimens.radiusPill),
          child: BackdropFilter(
            filter: blur,
            child: SizedBox(
              width: itemWidth,
              height: MiPillTabMetrics.pillHeight,
            ),
          ),
        ),
      );
      // pass 2：半透明填充 + 文案 + 手势。填充沿用 Decoration 自身
      // 圆角 AA（与截图实测的单层边缘 AA 一致，勿再外包 ClipRRect，
      // 两层 AA 叠乘会把边缘覆盖率压成 c²）。
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
              color: selected ? palette.selectedFill : palette.unselectedFill,
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
            Positioned.fill(child: Row(children: plates)),
            Positioned.fill(child: Row(children: fills)),
          ],
        ),
      ),
    );
  }
}
