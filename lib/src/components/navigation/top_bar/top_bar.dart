import 'package:flutter/material.dart';

import '../../../icons/nav_icons.dart';
import '../../../theme/top_bar_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/typography.dart';
import '../../../utils/filter_cache.dart';
import 'top_bar_metrics.dart';

/// 小米「大标题折叠」顶部导航栏（深/浅色双模式）。
///
/// **材质**（磨砂 + 叠色）实测自亮色「我的」页录屏，**折叠几何**（大标题 /
/// 紧凑标题 / 返回圆钮）实测自 HyperOS 设置「显示与亮度」页录屏 ——
/// 几何见 [MiTopBarMetrics]，材质 / 配色见 `theme/top_bar_tokens.dart`。
///
/// ## 材质：渐进磨砂（不是纯色遮罩）
///
/// 顶栏 = **backdrop 高斯模糊**（σ 沿 y 递减：[MiTopBarPalette.blurSigma]
/// 5.37dp 起，到 119dp 归零）+ **叠色** [MiTopBarPalette.scrimGradient]。
/// 栏顶全强度模糊、越往下越锐利，119dp 以下完全清晰。
///
/// 实现是 **8 段定 σ 阶梯**（[MiTopBarPalette.blurBands]）：每段
/// `ClipRect → BackdropFilter(σ_i)`，σ_i 取实测 σ(y) 曲线在该段中点的值。
/// Flutter 没有"位置相关模糊"，而唯一的替代（渐变 `ShaderMask` / `Opacity`
/// 削弱模糊层）会引入新的 saveLayer 并把 backdrop 变空 —— 实测遮罩 alpha
/// 恒 1 时模糊正常，一旦出现 <1 的 alpha 模糊**整段消失**。因此只能分段
/// 近似：段高 ≤ 17dp、相邻 σ 比 ≤ 1.5，台阶肉眼不可见。
///
/// ⚠️ 上一版曾判定"顶栏是纯色遮罩、无 backdrop 模糊"，该结论**已废弃**：
/// 当时的证据（沿蓝卡做纵向取样得亮度斜坡、卡片下缘 3px 硬跳变）都取自
/// 模糊带**之下**的平坦色块 —— 平坦区在模糊下亮度不变、且本来就在带外，
/// 无法区分"有模糊"与"无模糊"。本轮改用**高频内容**（头像照片 / 圆角方块
/// 的竖直边缘）才测出模糊。
///
/// ## 折叠行为（实测，非套用 iOS/Material 惯例）
///
///  * **大标题属于滚动内容**：其质心位移与列表滚动位移逐帧相等，即随内容
///    1:1 上移（不是钉在栏上缩小）；
///  * 大标题在此之上还有一条**独立淡出曲线**（位移 ≈20dp 内归零），
///    紧凑标题在大标题归零后才开始淡入（≈20→27.4dp），两段不重叠；
///  * 返回圆钮按压反馈 = ⌀44.1 圆盘、白 @9.4%，0.42s easeOut 淡入 /
///    0.3s 淡出。
///
/// ## 形态与插槽
///
/// 顶栏由「**标题区**」（材质 + 大/紧凑标题 + 返回圆钮，定高）与
/// 「**头部区**」（插槽，按需）上下拼成，两区可自由组合：
///
/// | 形态 | `title` | `showSurface` | 插槽 | 典型用法 |
/// |------|---------|---------------|------|----------|
/// | 大标题折叠 | 有 | `true` | — | 首页 / 「我的」/ 设置页 |
/// | 纯材质 | `null` | `true` | — | 参考录屏「我的」页（顶栏不内嵌组件） |
/// | 吸顶头部 | `null` | `false` | `searchBar` + `tabBar` | 分类页（搜索栏 + 胶囊行吸顶） |
/// | 材质 + 头部 | `null` | `true` | 任意 | 需要磨砂底的自定义头部 |
///
/// 头部插槽自上而下排列，**三者互斥**（构造期断言保证）：
///
/// | 插槽 | 类型 | 高度来源 | 布局 |
/// |------|------|----------|------|
/// | [searchBar] | `Widget` | [searchBarHeight]（默认 44.1） | 左右 [headerInset]、顶部状态栏让位 |
/// | [tabBar] | `Widget` | [tabBarHeight]（默认 39.9） | **满宽**（自带 11.9 边距，需横向出血滚动），与搜索栏隔 16 |
/// | [header] | `PreferredSizeWidget` | `preferredSize.height` | 左右 [headerInset]，整块自定义头部的逃生口 |
///
/// 插槽高度是**声明值**：组件按它分配高度，宿主也按它（经 [occupiedHeight]）
/// 给滚动内容让位 —— 两侧同源，不会出现「头部下移而列表没让位」的错位。
/// 换成自定义高度的组件时记得同步传高度。
///
/// ## 用法 —— 吸顶头部（分类页形态）
///
/// ```dart
/// final bar = MiTopBar(
///   themeMode: mode,
///   showSurface: false,             // 头部自带磨砂，不再叠一层材质
///   searchBar: MiSearchBar(hint: '搜索主题 / 壁纸 / 图标'),
///   tabBar: MiPillTabBar(labels: tabs, selectedIndex: i, onTap: ...),
/// );
///
/// Stack(children: [
///   ListView(padding: EdgeInsets.only(
///     top: bar.occupiedHeight(context) + MiTopBarMetrics.headerContentGap,
///   ), children: [...]),
///   Positioned(top: 0, left: 0, right: 0, child: bar),
/// ])
/// ```
///
/// ## 用法 —— 大标题折叠
///
/// 本组件**不自带滚动**，由宿主提供当前滚动位移（受控组件，与
/// [MiPillTabBar] 的 `selectedIndex` 同风格），叠在滚动内容之上：
///
/// ```dart
/// Stack(children: [
///   ListView(controller: _c, padding: const EdgeInsets.only(
///     top: MiTopBarMetrics.contentTopInset), children: [...]),
///   Positioned(top: 0, left: 0, right: 0,
///     child: MiTopBar(title: '显示与亮度', scrollOffset: _offset, onBack: ...)),
/// ])
/// ```
///
/// **纯材质形态**：参考录屏（亮色「我的」页）的顶栏**不内嵌任何组件** ——
/// 传 `title: null` 即只有磨砂 + 叠色，不绘制标题，组件高度收到
/// [MiTopBarMetrics.scrimHeight]：
///
/// ```dart
/// Positioned(top: 0, left: 0, right: 0, child: MiTopBar())
/// ```
///
/// ⚠️ **必须用 `Positioned` 钉在顶部**（或保证外层给出的是紧约束）。若把它
/// 留作外层 `Stack` 的**非定位子级**，该 `Stack` 就会按它收缩成 393×152.8
/// 而不是撑满，一旦再处于 loose 约束的上级里（如 `Center`、
/// `AnimatedSwitcher` 内部那个 `alignment: center` 的 `Stack`），整页会被
/// 居中到屏幕正中：顶栏跑到屏幕中间、页底与滚动内容只剩 152.8dp 高。
/// 2026-10-16 实机截图实测该偏移 = (856 − 152.8) / 2 = 351.6dp。
///
/// 材质层只覆盖顶部 [MiTopBarMetrics.scrimHeight]，其下内容照常透出。
/// 除返回圆钮与插槽本身外整体不参与手势，滚动内容可从顶栏下方正常拖动。
///
/// **坐标原点 = 屏幕顶端**：实测几何已包含 [MiTopBarMetrics.statusBarHeight]
/// 的状态栏让位，宿主把它铺在屏幕顶部即可，顶部不要再叠加 `SafeArea` 内边距
/// （否则整体会下移、大标题与圆钮的实测垂心失效）。头部插槽区自带状态栏
/// 让位（[MiTopBarMetrics.headerTopInsetFor]，安全区更高时取安全区）。
///
/// [themeMode] 为空时跟随环境 `Theme.of(context).brightness`。
///
/// **返回圆钮默认不显示**（顶层页无返回，如参考截图「设置」首页）：需要时
/// 传 `showBack: true`，其可点性再由 [onBack] 决定（null = 只显示、不可点）。
///
/// 两条标题都用 `Baseline`（alphabetic）把**基线钉到实测反推的目标值**
/// （见 [MiTopBarMetrics.titleBaselineY]），使墨心落点不随字体族的
/// ascent/descent 漂移（详见 metrics 类文档）。
class MiTopBar extends StatelessWidget {
  const MiTopBar({
    super.key,
    this.title,
    this.showBack = false,
    this.onBack,
    this.themeMode,
    this.scrollOffset = 0,
    this.searchBar,
    this.searchBarHeight = MiTopBarMetrics.searchBarSlotHeight,
    this.tabBar,
    this.tabBarHeight = MiTopBarMetrics.tabBarSlotHeight,
    this.header,
    this.headerInset = MiTopBarMetrics.headerInset,
    this.showSurface = true,
  })  : assert(scrollOffset >= 0, 'scrollOffset 不能为负（未滚动时传 0）'),
        assert(header == null || (searchBar == null && tabBar == null),
            'header 与 searchBar / tabBar 互斥：给了整块头部就不要再给零件'),
        assert(searchBarHeight > 0, 'searchBarHeight 必须为正'),
        assert(tabBarHeight > 0, 'tabBarHeight 必须为正'),
        assert(headerInset >= 0, 'headerInset 不能为负'),
        assert(
          title != null ||
              showSurface ||
              searchBar != null ||
              tabBar != null ||
              header != null,
          '空顶栏没有意义：title / showSurface / 插槽至少要给一个',
        );

  /// 标题文案（大标题与紧凑标题同源）。
  ///
  /// **null = 无标题**：不画两条标题，此时高度只剩材质层（纯材质形态）与
  /// 头部插槽区。
  final String? title;

  /// 是否显示返回圆钮（默认 false —— 顶层页无返回）。
  final bool showBack;

  /// 返回回调；仅在 [showBack] 为 true 时生效。
  /// null = 圆钮只显示、不可点（不参与手势、无按压反馈）。
  final VoidCallback? onBack;

  /// 明暗模式；null = 跟随环境 Theme 亮度。
  final MiThemeMode? themeMode;

  /// 当前滚动位移（dp，非负）；驱动大标题上移 + 淡出、紧凑标题淡入。
  final double scrollOffset;

  // ── 头部插槽（searchBar / tabBar / header 三者互斥） ────────────────────
  /// 搜索栏插槽：头部区首行，左右留 [headerInset]、顶部留状态栏让位。
  ///
  /// 分类页传 `MiSearchBar`；只给它不给 [tabBar] 时头部区只有一行。
  final Widget? searchBar;

  /// 搜索栏插槽的高度（**布局用**，须与传入组件的实际高度一致）。
  final double searchBarHeight;

  /// 胶囊标签行插槽：渲染在搜索栏下方，隔
  /// [MiTopBarMetrics.searchBarGap]（16dp）。
  ///
  /// **满宽铺开、左右不内缩** —— 标签行自带 11.9 的 `edgeInset`，且要能
  /// 横向出血滚动到屏幕边缘；再套一层外边距会把末尾胶囊多裁一截。
  final Widget? tabBar;

  /// 胶囊标签行插槽的高度（**布局用**，须与传入组件的实际高度一致）。
  final double tabBarHeight;

  /// 整块自定义头部的逃生口（与 [searchBar] / [tabBar] 互斥）。
  ///
  /// 高度取 `preferredSize.height`，左右仍走 [headerInset]。
  final PreferredSizeWidget? header;

  /// 头部插槽的左右页边距（默认 [MiTopBarMetrics.headerInset] 11.9）。
  ///
  /// 宽屏舞台下页面边距会放大（示例层用 24），由宿主传同值以保持与滚动
  /// 内容左缘对齐。
  final double headerInset;

  /// 是否绘制磨砂 + 叠色材质层（默认 true）。
  ///
  /// 头部插槽自带磨砂（`MiSearchBar` / `MiPillTabBar` 都有自己的 backdrop）
  /// 时传 `false`：否则材质会在它们后方再叠一层，多出若干层 backdrop 模糊，
  /// 且搜索栏 / 胶囊之间的间隙被染上叠色，与参考页不符。
  final bool showSurface;

  /// 头部区是否有插槽。
  bool get hasHeaderSlot =>
      searchBar != null || tabBar != null || header != null;

  /// 标题区高度：有标题 = 大标题墨心 + 一整行；无标题 = 只剩材质盒
  /// （不画材质则为 0）。
  double titleExtent(double largeTitleFontSize) => title != null
      ? MiTopBarMetrics.componentHeight(largeTitleFontSize)
      : (showSurface ? MiTopBarMetrics.scrimHeight : 0);

  /// 头部区高度（含状态栏让位；无插槽为 0）。
  ///
  /// 与 [occupiedHeight]、`build` 三处共用同一套声明值，改一处同步生效。
  double headerExtent(BuildContext context) {
    if (!hasHeaderSlot) return 0;
    var extent = MiTopBarMetrics.headerTopInsetFor(
      MediaQuery.paddingOf(context).top,
    );
    if (header != null) return extent + header!.preferredSize.height;
    if (searchBar != null) extent += searchBarHeight;
    if (searchBar != null && tabBar != null) {
      extent += MiTopBarMetrics.searchBarGap;
    }
    if (tabBar != null) extent += tabBarHeight;
    return extent;
  }

  /// 顶栏**自身**占用的总高（标题区 + 头部区，不含与滚动内容的间距）。
  ///
  /// 宿主给滚动内容让位就用它：
  /// `padding.top = occupiedHeight(context) + MiTopBarMetrics.headerContentGap`。
  /// 与组件内部署用的是同一套声明值，故不会出现「头部下移、列表没让位」。
  double occupiedHeight(BuildContext context) =>
      titleExtent(MiTypography.topBarLargeTitle.fontSize!) +
      headerExtent(context);

  /// 渲染时真正要绘制的模糊段：剔除两类**视觉上不存在**的段。
  ///
  ///  * 完全落在叠色不透明段之内（[MiTopBarPalette.scrimOpaqueBottom]）——
  ///    深色配方 0…63.6dp 是 α = 1.000 的纯黑，底下的模糊结果 100% 被遮住；
  ///  * σ < [MiTopBarMetrics.minVisibleBlurSigma] —— 高斯半径 < 1dp，亚像素。
  ///
  /// 两条都是零视觉差异的省帧手段：平板 768×1280 深色首页实测，顶栏模糊
  /// 段从 8 段 / 119dp 降到 5 段 / 45.4dp，模糊面积 85,680 → 32,688 dp²
  ///（−62%）；每段在滚动时都要重算一次全宽高斯，这是丢帧的主因。
  /// 裁剪后段的 σ 仍取原段值（段变窄，σ 沿 y 的变化在 3~7dp 内可忽略）。
  @visibleForTesting
  static List<MiTopBarBlurBand> visibleBlurBands(MiTopBarPalette palette) {
    final opaque = palette.scrimOpaqueBottom;
    final bands = <MiTopBarBlurBand>[];
    for (final band in MiTopBarPalette.blurBands) {
      if (band.sigma < MiTopBarMetrics.minVisibleBlurSigma) continue;
      final top = band.top > opaque ? band.top : opaque;
      if (band.bottom <= top) continue;
      bands.add(
        top == band.top
            ? band
            : MiTopBarBlurBand(
                top: top,
                height: band.bottom - top,
                sigma: band.sigma,
              ),
      );
    }
    return bands;
  }

  @override
  Widget build(BuildContext context) {
    final mode = themeMode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    final palette = MiTopBarPalette.of(mode);
    final title = this.title;
    // 位移兜底：NaN / 负数按未滚动处理，+∞ 饱和为折叠完成态（避免布局出现
    // 无限坐标，同时语义上「滚过头」就是折叠态）。
    final offset = scrollOffset.isNaN || scrollOffset <= 0
        ? 0.0
        : (scrollOffset.isFinite
            ? scrollOffset
            : MiTopBarMetrics.collapsedOffset);
    final largeSize = MiTypography.topBarLargeTitle.fontSize!;
    final compactSize = MiTypography.topBarCompactTitle.fontSize!;
    // 基线落点：`Baseline` 会在布局期把标题基线放到「距组件顶端 N 处」，
    // 与字体 ascent/descent 无关 —— 这是本组件对齐录屏的关键（用 `height`
    // 或 strut 都做不到：前者按比例缩放、后者本 SDK 没有 ascent/descent）。
    final largeTitleBaseline = MiTopBarMetrics.titleBaselineY(
      MiTopBarMetrics.largeTitleInkCenterY,
      largeSize,
    );
    final compactTitleBaseline = MiTopBarMetrics.titleBaselineY(
      MiTopBarMetrics.compactTitleInkCenterY,
      compactSize,
    );

    final bands =
        showSurface ? visibleBlurBands(palette) : const <MiTopBarBlurBand>[];

    return SizedBox(
      // 上下拼装：标题区定高 + 头部区按插槽声明高度；无插槽时整体高度即
      // 标题区，与首版行为一致。
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            // 有标题时到大标题墨心 + 一整行（够高不裁标题）；纯材质形态只需
            // 盖住遮罩盒本身。遮罩之外的部分保持透明。
            height: titleExtent(largeSize),
            child: Stack(
              children: [
                // 1) 磨砂：按实测 σ(y) 曲线分段，每段一个定 σ 的 backdrop 模糊。
                //    （不能用一个渐变的 ShaderMask / Opacity 去调强度 —— 那会引入
                //    新的 saveLayer，BackdropFilter 的 backdrop 变空、模糊整段消失。
                //    见 MiTopBarPalette.blurBands 的说明。）
                for (final band in bands)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: band.top,
                    height: band.height,
                    child: IgnorePointer(
                      child: ClipRect(
                        child: BackdropFilter(
                          // σ 来自固定 token → 复用缓存的 native filter，
                          // 避免每帧重建（滚动时每帧都会走这里）。
                          filter: MiFilterCache.blur(band.sigma),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                // 2) 叠色：顶部最深 → 渐隐（亮色 = 页底色 @0.65→0，深色 = 黑
                //    @1→0，两页各自实测，见 MiTopBarPalette 文档）
                if (showSurface)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: MiTopBarMetrics.scrimHeight,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration:
                            BoxDecoration(gradient: palette.scrimGradient),
                      ),
                    ),
                  ),
                // 3) 大标题：随滚动 1:1 上移 + 按实测表淡出（钉基线 → top 恒为 0）
                if (title != null)
                  Positioned(
                    left: MiTopBarMetrics.largeTitleLeadingInset,
                    top: 0,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: MiTopBarMetrics.largeTitleOpacity(offset),
                        child: Baseline(
                          baseline: largeTitleBaseline - offset,
                          baselineType: TextBaseline.alphabetic,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MiTypography.topBarLargeTitleFor(mode),
                          ),
                        ),
                      ),
                    ),
                  ),
                // 4) 紧凑标题：与返回圆钮同一行、屏内水平居中（实测 609.5px ≈ 屏心）
                if (title != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: MiTopBarMetrics.compactTitleOpacity(offset),
                        child: Padding(
                          // 显示圆钮时对称内缩（圆钮右缘），长标题居中且不与圆钮相撞；
                          // 不显示圆钮时不留内缩，居中标题可用满整屏宽。
                          padding: EdgeInsets.symmetric(
                            horizontal: showBack
                                ? MiTopBarMetrics.backInset +
                                    MiTopBarMetrics.backDiameter
                                : 0,
                          ),
                          child: Center(
                            child: Baseline(
                              baseline: compactTitleBaseline,
                              baselineType: TextBaseline.alphabetic,
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MiTypography.topBarCompactTitleFor(mode),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // 5) 返回圆钮（可选，标题区内唯一的可交互元素）
                if (showBack)
                  Positioned(
                    left: MiTopBarMetrics.backInset,
                    top: MiTopBarMetrics.backCenterY -
                        MiTopBarMetrics.backDiameter / 2,
                    child: _MiTopBarBackButton(
                      palette: palette,
                      onTap: onBack,
                    ),
                  ),
              ],
            ),
          ),
          // 6) 头部区：搜索栏 / 胶囊标签行 / 自定义头部（自上而下）
          if (hasHeaderSlot)
            Padding(
              padding: EdgeInsets.only(
                top: MiTopBarMetrics.headerTopInsetFor(
                  MediaQuery.paddingOf(context).top,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (header != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: headerInset),
                      child: SizedBox(
                        height: header!.preferredSize.height,
                        child: header,
                      ),
                    ),
                  if (searchBar != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: headerInset),
                      child: SizedBox(height: searchBarHeight, child: searchBar),
                    ),
                  if (searchBar != null && tabBar != null)
                    const SizedBox(height: MiTopBarMetrics.searchBarGap),
                  // 胶囊行满宽：靠自身 11.9 的 edgeInset 与搜索栏左缘对齐，
                  // 同时保留横向出血滚动（再套内边距会把末尾胶囊多裁一截）。
                  if (tabBar != null)
                    SizedBox(height: tabBarHeight, child: tabBar),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 返回圆钮：⌀44.1 命中区 + 箭头，按下时浮现白 @9.4% 圆盘（实测）。
///
/// 箭头墨心相对圆钮中心左偏 [MiTopBarMetrics.chevronCenterDx]（实测光学
/// 偏置，非居中）。
class _MiTopBarBackButton extends StatefulWidget {
  const _MiTopBarBackButton({required this.palette, required this.onTap});

  final MiTopBarPalette palette;
  final VoidCallback? onTap;

  @override
  State<_MiTopBarBackButton> createState() => _MiTopBarBackButtonState();
}

class _MiTopBarBackButtonState extends State<_MiTopBarBackButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: MiTopBarMetrics.backDiameter,
      height: MiTopBarMetrics.backDiameter,
      child: Stack(
        children: [
          // 按压反馈圆盘（实测平坦填充、无描边）
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _pressed ? 1 : 0,
              duration: Duration(
                milliseconds: _pressed
                    ? MiTopBarMetrics.pressFadeInMs
                    : MiTopBarMetrics.pressFadeOutMs,
              ),
              curve: Curves.easeOut,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.palette.pressHighlight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // 箭头：墨盒铺满，中心再按实测偏置平移
          Center(
            child: Transform.translate(
              offset: const Offset(MiTopBarMetrics.chevronCenterDx, 0),
              child: CustomPaint(
                painter: BackChevronIconPainter(widget.palette.ink),
                size: const Size(
                  MiTopBarMetrics.chevronWidth,
                  MiTopBarMetrics.chevronHeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final onTap = widget.onTap;
    if (onTap == null) return IgnorePointer(child: content);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: onTap,
      child: content,
    );
  }
}
