import 'package:flutter/material.dart';

import '../../../theme/dimens.dart';
import '../../../theme/pill_tab_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../theme/typography.dart';
import '../../../utils/filter_cache.dart';
import '../../../utils/glass_rim.dart';
import '../../../utils/pressable.dart';
import '../../../utils/squircle.dart';
import 'pill_tab_bar_metrics.dart';

/// 胶囊分类标签行（明暗双模式）。
///
/// [labels] 以胶囊排成一行，支持横向滚动（超出视口自动裁切滚动）。
/// 宽度两档（[itemWidthMode]）：默认**定宽**（度量 87.6，逐像素不变）；
/// [MiPillItemWidth.adaptive] 按标签文字自然宽 clamp（见
/// [MiPillTabMetrics] 自适应档注释）。选中项为高不透明胶囊 + 高对比标签，
/// 未选中为低对比胶囊 + 反色标签；明暗配方见 `theme/pill_tab_tokens.dart`，
/// 几何见 [MiPillTabMetrics]。
///
/// 透明效果与玻璃导航栏同源（`theme/transparency_tokens.dart`）：胶囊填充
/// 为半透明表面，下叠同款 backdrop 磨砂（σ = [MiTransparencyTokens.blurSigma]），
/// 内容从胶囊后方经过时透出磨砂质感。渲染分两遍：先以单次 `ClipPath`
/// 裁出全部胶囊形状做一次整行磨砂（此时画布上尚无填充，相邻胶囊互不
/// 串色），再绘制填充与文案。
///
/// 点按切换选中态，填充 / 标签色以 200ms 过渡。
///
/// 未选中胶囊是低调表面（onSurface @6%）。压在滚动内容上时（[overContent]）
/// 额外垫一层**行区限定的玻璃膜带**（issue #4①）：膜只覆盖胶囊行那一段、
/// 行外与胶囊间隙不垫 —— 膜是独立一层（不再逐胶囊预合成 `veiledFill`），
/// 胶囊填充两态同值，膜管「形状可读」、内缘亮边管「受光边」。
/// 上下缘羽化（`MiPillTabMetrics.veilFeatherHeight`）现为 **0（均匀铺满）**：
/// 8dp 羽化曾把 40dp 胶囊上下各 1/3 的膜吃掉，彩色内容直接透出（实机截图
/// 否定，2026-10-28）；参考的胶囊膜是均匀的。
class MiPillTabBar extends StatelessWidget {
  const MiPillTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onTap,
    this.itemWidth = MiPillTabMetrics.itemWidth,
    this.itemWidthMode = MiPillItemWidth.fixed,
    this.minItemWidth = MiPillTabMetrics.itemWidth,
    this.maxItemWidth = MiPillTabMetrics.adaptiveMaxWidth,
    this.textInset = MiPillTabMetrics.adaptiveTextInset,
    this.themeMode = MiThemeMode.dark,
    this.frosted = true,
    this.overContent = false,
    this.rimProgress = 1.0,
    this.fade = 1.0,
  })  : assert(itemWidth > 0),
        assert(minItemWidth > 0),
        assert(maxItemWidth >= minItemWidth),
        assert(textInset >= 0),
        assert(fade >= 0 && fade <= 1);
  // labels 非空与 selectedIndex 范围校验见 build()：const 构造断言不支持
  // .length 求值（放构造器会封死 const 构造）

  /// 各分类标签文案。
  final List<String> labels;

  /// 选中项下标。
  final int selectedIndex;

  /// 点按回调，参数为被点标签下标。
  final ValueChanged<int> onTap;

  /// 定宽档（[MiPillItemWidth.fixed]）的胶囊宽度，默认取度量
  /// [MiPillTabMetrics.itemWidth]。
  final double itemWidth;

  /// 宽度模式（默认 [MiPillItemWidth.fixed]，现有行为逐像素不变）。
  final MiPillItemWidth itemWidthMode;

  /// 自适应档胶囊宽度下限（默认度量 87.6）。
  final double minItemWidth;

  /// 自适应档胶囊宽度上限（默认 2×度量 = 175.2；超出以省略号截断）。
  final double maxItemWidth;

  /// 自适应档标签两侧内缩（默认 16）。
  final double textInset;

  /// 明暗模式，驱动配色配方。
  final MiThemeMode themeMode;

  /// 是否自绘 backdrop 磨砂（默认 true）。
  ///
  /// 放进**自带材质的顶栏**（`MiTopBar(showSurface: true)` 的头部区）时传
  /// `false`：磨砂由顶栏那条渐进曲线统一提供，否则胶囊比周围更糊、且多一份
  /// 每帧全 QUAD 高斯。只保留半透明填充。
  final bool frosted;

  /// 未选胶囊是否垫**行区玻璃膜带**（默认 false）。
  ///
  /// 平底页（分类页）的未选胶囊是 onSurface@6% 的低调填充（合成 #E5E5E5）；
  /// 压在照片/视频上时（悬浮头部区）再垫一层膜 —— 否则胶囊在杂乱背景上几乎
  /// 读不出形状。膜是**行区限定的一条渐变带**（issue #4①）：只覆盖胶囊行
  /// 那一段、上下缘羽化（8dp，推导），行外与胶囊间隙不垫；不再逐胶囊预合成
  /// （`veiledFill`），胶囊填充两态同值 —— 垫在同色页底上等于没垫，**平底页
  /// 观感不变**，只有背景有内容时才显出玻璃片。选中胶囊近不透明，盖住膜。
  final bool overContent;

  /// 内缘亮边激活进度（0…1，默认 1 = 常亮）：**内容靠近顶栏一定程度才亮**
  /// （参考实测：内容距栏底 ≲20dp 时进入激活态；静止且内容较远时亮边 = 0，
  /// 不是常驻描边）。顶栏按滚动位置下发（见 `MiTopBarMetrics.rimFadeDistance`）。
  final double rimProgress;

  /// 整行淡出系数（0…1，默认 1 = 完全显示）。
  ///
  /// 供**退场转场**用：值乘进各处颜色的 alpha（选中 / 未选填充、标签墨色、
  /// 膜带、内缘亮边），行结构不变。
  ///
  /// **不要用父级 `Opacity` 代替**：本行自带 backdrop 磨砂（[frosted]），
  /// 套 `Opacity` 会引入 saveLayer —— backdrop 的输入被清空、磨砂在整段
  /// 转场里消失，且每帧多一次整行离屏合成（转场掉帧的主因）。
  final double fade;

  /// 自适应档：量取标签文字自然宽（单行，不截断）。
  double _labelWidth(BuildContext context, String label) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: MiTypography.pillLabel),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// 本行胶囊宽度序列 —— **三遍绘制（填充 / 磨砂裁形 / 内缘亮边）共用
  /// 同一份**，保证逐像素对齐（issue #3）。
  List<double> _widths(BuildContext context) {
    if (itemWidthMode == MiPillItemWidth.fixed) {
      return List<double>.filled(labels.length, itemWidth);
    }
    return [
      for (final label in labels)
        (_labelWidth(context, label) + 2 * textInset)
            .clamp(minItemWidth, maxItemWidth),
    ];
  }

  @override
  Widget build(BuildContext context) {
    assert(labels.isNotEmpty, 'labels 不能为空');
    assert(
      selectedIndex >= 0 && selectedIndex < labels.length,
      'selectedIndex 必须落在 labels 范围内',
    );
    final palette = MiPillTabPalette.of(themeMode);
    // 淡出（[fade] < 1）：把系数乘进各处颜色的 alpha，行结构与绘制层次不变。
    final f = fade;
    Color faded(Color c) => f >= 1 ? c : c.withValues(alpha: c.a * f);
    // 淡出途中**不做填充色过渡**：`AnimatedContainer` 默认会在 200ms 里插值，
    // 每帧一个新目标色 → 淡出被拖成一条长尾（也在退场时白跑一堆动画）。
    final Duration fillDuration = f < 1
        ? Duration.zero
        : const Duration(milliseconds: MiPillTabMetrics.fillFadeMs);
    // 未选填充：两态同值（issue #4①）—— 压内容时的膜是独立的行区渐变带，
    // 不再在这里逐胶囊预合成 veiledFill。
    final unselectedFill = faded(palette.unselectedFill);
    final widths = _widths(context);
    // 填充/文案/手势层（与磨砂分离成两层，保证模糊源里没有填充色）。
    final fills = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      if (i > 0) fills.add(const SizedBox(width: MiPillTabMetrics.gap));
      final selected = i == selectedIndex;
      // 半透明填充 + 文案 + 手势。填充沿用 Decoration 自身圆角 AA（与截图
      // 度量的单层边缘 AA 一致，勿再外包 ClipRRect，两层 AA 叠乘会把边缘
      // 覆盖率压成 c²）。
      fills.add(
        // 三态反馈统一入口：点按 / Enter / Space 选中；悬停只给**未选中**
        // 胶囊（选中项已是近不透明实心，再叠一层读不出变化，反而糊住
        // 选中态）；焦点环全项统一（Tab 每项一停，推导桌面语义）。
        MiPressable(
          onPressed: () => onTap(i),
          mode: themeMode,
          hover: !selected,
          borderRadius: BorderRadius.circular(MiDimens.radiusPill),
          child: AnimatedContainer(
              duration: fillDuration,
              curve: Curves.easeOut,
              width: widths[i],
              height: MiPillTabMetrics.pillHeight,
              decoration: ShapeDecoration(
                color: selected ? faded(palette.selectedFill) : unselectedFill,
                shape: const MiSquircleBorder(MiDimens.radiusPill),
              ),
              alignment: Alignment.center,
              child: Text(
                labels[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MiTypography.pillLabel.copyWith(
                  color: faded(
                    selected ? palette.selectedLabel : palette.unselectedLabel,
                  ),
                ),
              ),
            ),
        ),
      );
    }
    final rowWidth = widths.fold<double>(
          0,
          (sum, w) => sum + w,
        ) +
        (labels.length - 1) * MiPillTabMetrics.gap;
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
            // [frosted] 为 false时整层跳过（材质由顶栏给）；淡到 0 时也跳过
            //（不可见的磨砂不必每帧再跑一次高斯）。
            if (frosted && f > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _CapsuleStripClipper(
                      widths: widths,
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
            // 行区玻璃膜带（issue #4①）：与磨砂同一套胶囊栅格裁形，膜色沿 y
            // 上下缘羽化收尾（veil @0 端点）—— 独立一层，垫在填充之下；间隙
            // 与行外不垫（形状仍绑胶囊栅格），行区上下缘不再是硬边。
            if (overContent)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _CapsuleStripClipper(
                      widths: widths,
                      gap: MiPillTabMetrics.gap,
                      height: MiPillTabMetrics.pillHeight,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            faded(MiTransparencyTokens.veilFeatherFor(themeMode)),
                            faded(MiTransparencyTokens.veilFor(themeMode)),
                            faded(MiTransparencyTokens.veilFor(themeMode)),
                            faded(MiTransparencyTokens.veilFeatherFor(themeMode)),
                          ],
                          stops: const [
                            0.0,
                            MiPillTabMetrics.veilFeatherHeight /
                                MiPillTabMetrics.pillHeight,
                            1 - MiPillTabMetrics.veilFeatherHeight /
                                MiPillTabMetrics.pillHeight,
                            1.0,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(child: Row(children: fills)),
            // 内缘亮边（「边缘逐渐变亮」的受光边）：只画**未选中**胶囊 ——
            // 选中项是近实心填充，实测亮边弱到不可辨（见
            // `MiTransparencyTokens.surfaceRimFor`）。一次画完整条，
            // 不给每个胶囊各挂一个 painter。
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CapsuleRimPainter(
                    widths: widths,
                    gap: MiPillTabMetrics.gap,
                    height: MiPillTabMetrics.pillHeight,
                    color: faded(MiTransparencyTokens.surfaceRimFor(themeMode,
                        progress: rimProgress)),
                    skipIndex: selectedIndex,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 第 i 个胶囊的左缘（宽度序列 [widths] + 定距 [gap] 的栅格；三遍绘制共用）。
double _cellLeft(List<double> widths, int gapIndex, double gap) {
  var left = 0.0;
  for (var i = 0; i < gapIndex; i++) {
    left += widths[i] + gap;
  }
  return left;
}

/// 把整行裁成「N 个 stadium 胶囊」的并集（供单次 backdrop 模糊与膜带
/// 覆盖全部胶囊）。
///
/// 胶囊按 [widths] 序列等距排布（定宽档即全等），第 i 个的左缘 =
/// 前 i 项宽 + i×gap，圆角半径取高的一半（与
/// `BorderRadius.circular(radiusPill)` 半径钳位后的 stadium 一致）。
class _CapsuleStripClipper extends CustomClipper<Path> {
  const _CapsuleStripClipper({
    required this.widths,
    required this.gap,
    required this.height,
  });

  final List<double> widths;
  final double gap;
  final double height;

  @override
  Path getClip(Size size) {
    final path = Path();
    for (var i = 0; i < widths.length; i++) {
      final left = _cellLeft(widths, i, gap);
      // 胶囊（半径 = 高/2）：端头为真半圆（MiSquircle 胶囊例外），
      // 与裁形外的填充 / 亮边同一栅格、逐像素对齐。
      MiSquircle.addRect(
        path,
        Rect.fromLTWH(left, 0, widths[i], height),
        height / 2,
      );
    }
    return path;
  }

  @override
  bool shouldReclip(_CapsuleStripClipper oldClipper) =>
      oldClipper.widths.length != widths.length ||
      !_listEquals(oldClipper.widths, widths) ||
      oldClipper.gap != gap ||
      oldClipper.height != height;
}

/// 整行未选中胶囊的内缘亮边（几何与 [_CapsuleStripClipper] 同一套栅格）。
class _CapsuleRimPainter extends CustomPainter {
  const _CapsuleRimPainter({
    required this.widths,
    required this.gap,
    required this.height,
    required this.color,
    required this.skipIndex,
  });

  final List<double> widths;
  final double gap;
  final double height;
  final Color color;

  /// 选中项下标（近实心，不画亮边）。
  final int skipIndex;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < widths.length; i++) {
      if (i == skipIndex) continue;
      final left = _cellLeft(widths, i, gap);
      MiGlassRimPainter.drawRim(
        canvas,
        Rect.fromLTWH(left, 0, widths[i], height),
        height / 2,
        color,
      );
    }
  }

  @override
  bool shouldRepaint(_CapsuleRimPainter oldDelegate) =>
      oldDelegate.widths.length != widths.length ||
      !_listEquals(oldDelegate.widths, widths) ||
      oldDelegate.gap != gap ||
      oldDelegate.height != height ||
      oldDelegate.color != color ||
      oldDelegate.skipIndex != skipIndex;
}

/// 宽度序列等值比较（Flutter 无 const 可用的 listEquals 常量形）。
bool _listEquals(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
