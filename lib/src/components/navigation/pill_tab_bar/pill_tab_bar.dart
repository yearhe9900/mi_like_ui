import 'package:flutter/material.dart';

import '../../../theme/dimens.dart';
import '../../../theme/pill_tab_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/typography.dart';
import 'pill_tab_bar_metrics.dart';

/// 小米主题商店风格的胶囊分类标签行（深/浅色双模式）。
///
/// [labels] 以定宽胶囊排成一行，可横向滚动（超出视口自动裁切滚动，
/// 与截图中第 4 个胶囊被屏幕右缘裁切的行为一致）。选中项实色胶囊 +
/// 高对比标签，未选中低对比胶囊 + 反色标签；明暗配方均为完整截图
/// 实测（亮色 = 深胶囊白字，暗色 = 白胶囊黑字 + 低调深灰未选胶囊），
/// 取值见 `theme/pill_tab_tokens.dart`，几何见 [MiPillTabMetrics]。
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
    final children = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      if (i > 0) children.add(const SizedBox(width: MiPillTabMetrics.gap));
      final selected = i == selectedIndex;
      children.add(
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
          const EdgeInsets.symmetric(horizontal: MiPillTabMetrics.edgeInset),
      child: Row(children: children),
    );
  }
}
