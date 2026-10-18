import 'package:flutter/material.dart';

import '../../../icons/nav_icons.dart';
import '../../../theme/top_bar_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/typography.dart';
import '../../effects/gradient_blur/gradient_blur.dart';
import '../../inputs/search_bar/search_bar.dart';
import '../pill_tab_bar/pill_tab_bar.dart';
import 'top_bar_metrics.dart';

/// 小米「大标题折叠」顶部导航栏（深/浅色双模式）。
///
/// **材质**（磨砂 + 叠色）实测自亮色「我的」页录屏，**折叠几何**（大标题 /
/// 紧凑标题 / 返回圆钮）实测自 HyperOS 设置「显示与亮度」页录屏 ——
/// 几何见 [MiTopBarMetrics]，材质 / 配色见 `theme/top_bar_tokens.dart`。
///
/// ## 材质：内容区的顶部渐进模糊 + 顶栏叠色
///
/// 顶栏那层"糊"**其实不属于顶栏**：参考 App 有一页**完全没有顶栏**
/// （主题商店「每日精选」），它的内容顶部照样是糊的，而且模糊程度随 y 递减
/// （逐行水平梯度 44dp 0.05 → 75dp 0.97 → 116dp 4.32 → **120dp 后不再上升**，
/// 即已经完全清晰、没有硬边）。所以磨砂是**内容滚动区自己的顶部渐进模糊**，
/// 已抽成独立组件 [MiGradientBlur]（不依赖顶栏，任何滚动内容都能自己挂）；
/// 顶栏只是因为位置正好重合，按自己的材质盒高**复用它**。
///
/// 于是材质拆成两个**独立开关**：
///
///  * **磨砂** [showBlur] —— backdrop 高斯模糊，σ 沿 y **递减**：
///    [MiTopBarPalette.blurSigma] 5.37dp 从栏顶平台段起、一路衰减到**栏底
///    归零**（[MiTopBarPalette.blurBands]）。曲线**形状固定、范围跟栏高走**：
///    无头部区拉到材质盒 128.9dp，有头部区拉到整条栏 156dp —— 对照分类页
///    截图，模糊一直糊到胶囊行下方、横幅底缘才变清晰；而没有顶栏的
///    「每日精选」页量到的是 ~120dp 收尾。
///  * **叠色** [showSurface] —— 顶部最深、向下渐隐的一层压色
///    （[MiTopBarPalette.scrimGradient]），用来压住下方内容保证标题可读。
///    这是**顶栏自己**的东西：大标题形态需要它，头部区形态（分类页）实测
///    参考页没有这层压色，传 `false`。
///
/// 材质是**盖在顶栏上的底**（不占布局高度）：高度 = 顶栏盖住的那块区域
/// （[materialExtent]）—— 无头部区是实测材质盒
/// [MiTopBarMetrics.scrimHeight]（128.9dp），头部区形态是整个 [occupiedHeight]。
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
/// 「**头部区**」（按需）上下拼成，两区可自由组合：
///
/// | 形态 | `title` | `showBlur` | `showSurface` | 头部区 | 典型用法 |
/// |------|---------|-----------|---------------|--------|----------|
/// | 大标题折叠 | 有 | `true` | `true` | — | 首页 / 「我的」/ 设置页 |
/// | 纯材质 | `null` | `true` | `true` | — | 参考录屏「我的」页（顶栏不内嵌组件） |
/// | 吸顶头部 | `null` | `true` | `false` | `searchHint` + `tabs` | 分类页（搜索栏 + 胶囊行吸顶，只用内容区的渐进模糊、不压色） |
/// | 材质 + 头部 | `null` | `true` | `true` | 任意 | 需要压色底的自定义头部 |
/// | 零件自带玻璃 | `null` | `false` | `false` | 任意 | 逃生形态：材质交给插槽里的组件自己画 |
///
/// 头部区**默认由顶栏自己产出**两个框架组件，调用方只给数据、不 new 组件：
///
/// | 头部内容 | 声明式入参 | 顶栏内部产出的组件 | 高度 |
/// |----------|------------|--------------------|------|
/// | 搜索栏 | [searchHint] / [onSearchTap] | `MiSearchBar` | [searchBarHeight]（44.1） |
/// | 胶囊标签行 | [tabs] / [selectedTab] / [onTabChanged] | `MiPillTabBar` | [tabBarHeight]（39.9） |
///
/// 需要换皮或塞别的组件时，用同名**插槽**覆盖（与声明式入参二选一）：
///
/// | 插槽 | 类型 | 高度来源 | 布局 |
/// |------|------|----------|------|
/// | [searchBar] | `Widget` | [searchBarHeight] | 左右 [headerInset]、顶部状态栏让位 |
/// | [tabBar] | `Widget` | [tabBarHeight] | **满宽**（自带 11.9 边距，需横向出血滚动），与搜索栏隔 16 |
/// | [header] | `PreferredSizeWidget` | `preferredSize.height` | 左右 [headerInset]，整块自定义头部的逃生口 |
///
/// [header] 与搜索栏 / 胶囊行**互斥**，`searchBar`↔`searchHint`、
/// `tabBar`↔`tabs` 各自互斥（构造期断言保证）。
///
/// 插槽高度是**声明值**：组件按它分配高度，宿主也按它（经 [occupiedHeight]）
/// 给滚动内容让位 —— 两侧同源，不会出现「头部下移而列表没让位」的错位。
/// 换成自定义高度的组件时记得同步传高度（用声明式入参则恒等于组件自身高度）。
///
/// ## 用法 —— 吸顶头部（分类页形态）
///
/// ```dart
/// final bar = MiTopBar(
///   themeMode: mode,
///   searchHint: '搜索主题 / 壁纸 / 图标',
///   tabs: const ['推荐', '背屏', '小部件', '主题'],
///   selectedTab: index,
///   onTabChanged: (i) => setState(() => index = i),
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
/// 需要自定义搜索栏 / 胶囊行时改传 [searchBar] / [tabBar] 插槽，排版与让位
/// 完全一致，只是组件本体由调用方提供。
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
    this.searchHint,
    this.onSearchTap,
    this.searchBarHeight = MiTopBarMetrics.searchBarSlotHeight,
    this.tabBar,
    this.tabs,
    this.selectedTab = 0,
    this.onTabChanged,
    this.tabBarHeight = MiTopBarMetrics.tabBarSlotHeight,
    this.header,
    this.headerInset = MiTopBarMetrics.headerInset,
    this.showSurface = true,
    this.showBlur = true,
  })  : assert(scrollOffset >= 0, 'scrollOffset 不能为负（未滚动时传 0）'),
        assert(header == null || (searchBar == null && searchHint == null &&
            tabBar == null && tabs == null),
            'header 与搜索栏 / 胶囊行互斥：给了整块头部就不要再给零件'),
        assert(searchBar == null || searchHint == null,
            '搜索栏二选一：searchBar（自定义组件）与 searchHint（内置 MiSearchBar）不能同时给'),
        assert(tabBar == null || tabs == null,
            '胶囊行二选一：tabBar（自定义组件）与 tabs（内置 MiPillTabBar）不能同时给'),
        assert(searchBarHeight > 0, 'searchBarHeight 必须为正'),
        assert(tabBarHeight > 0, 'tabBarHeight 必须为正'),
        assert(headerInset >= 0, 'headerInset 不能为负'),
        assert(selectedTab >= 0, 'selectedTab 不能为负'),
        assert(
          title != null ||
              showSurface ||
              showBlur ||
              searchBar != null ||
              searchHint != null ||
              tabBar != null ||
              tabs != null ||
              header != null,
          '空顶栏没有意义：title / showBlur / showSurface / 头部区至少要给一个',
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

  // ── 头部区：声明式入参（顶栏内部产出组件） ──────────────────────────────
  /// 搜索栏的占位文案 —— 给了它，顶栏**自己在内部产出** `MiSearchBar`，
  /// 调用方不用 import / new 搜索栏组件。
  ///
  /// 与 [searchBar] 二选一（同时给会在构造期断言）。
  final String? searchHint;

  /// 内置搜索栏的点按回调（仅 [searchHint] 生效时有效）。
  final VoidCallback? onSearchTap;

  /// 胶囊分类标签文案 —— 给了它，顶栏**自己在内部产出** `MiPillTabBar`。
  ///
  /// 与 [tabBar] 二选一（同时给会在构造期断言）；须非空、长度覆盖
  /// [selectedTab]（校验在 `MiPillTabBar.build`）。
  final List<String>? tabs;

  /// 内置胶囊行的选中下标（仅 [tabs] 生效时有效）。
  final int selectedTab;

  /// 内置胶囊行的点按回调；null = 只展示、不可切换。
  final ValueChanged<int>? onTabChanged;

  // ── 头部区：插槽（逃生口，与上面的声明式入参二选一） ──────────────────
  /// 搜索栏插槽：头部区首行，左右留 [headerInset]、顶部留状态栏让位。
  ///
  /// 需要换皮时用；只要内置 `MiSearchBar` 就传 [searchHint]。
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

  /// 整块自定义头部的逃生口（与搜索栏 / 胶囊行互斥）。
  ///
  /// 高度取 `preferredSize.height`，左右仍走 [headerInset]。
  final PreferredSizeWidget? header;

  /// 头部区的左右页边距（默认 [MiTopBarMetrics.headerInset] 11.9）。
  ///
  /// 宽屏舞台下页面边距会放大（示例层用 24），由宿主传同值以保持与滚动
  /// 内容左缘对齐。
  final double headerInset;

  /// 是否绘制**叠色**遮罩（默认 true）。
  ///
  /// 只控叠色（顶部最深、向下渐隐的那层压色），与磨砂是**两个开关**：
  /// 大标题形态靠它压住下方内容、保证标题可读；头部件形态（分类页）实测
  /// 参考页没有这层压色 —— 那页整条栏都能看见被模糊的背景，所以传 `false`。
  ///
  /// 磨砂见 [showBlur]。
  final bool showSurface;

  /// 是否绘制**顶部渐进磨砂**（默认 true）。
  ///
  /// 这是**内容区自己的顶部渐进模糊**（实测：有一页完全没有顶栏 —— 主题商店
  /// 「每日精选」—— 内容顶部照样糊），本体是独立组件 [MiGradientBlur]，
  /// 顶栏只是按材质盒高复用它。σ 沿 y 递减到**材质盒底归零**：形状固定、
  /// 范围随栏高（无头部区 128.9dp / 有头部区整条栏），栏底既不糊也不留硬边。
  ///
  /// 内置的搜索栏 / 胶囊行会自动关掉自绘的 backdrop（`frosted: false`），
  /// 整条栏只糊一次。
  final bool showBlur;

  /// 头部区是否有搜索栏（声明式入参或插槽任一生效）。
  bool get hasSearchBar => searchBar != null || searchHint != null;

  /// 头部区是否有胶囊标签行（声明式入参或插槽任一生效）。
  bool get hasTabBar => tabBar != null || tabs != null;

  /// 头部区是否有内容。
  bool get hasHeaderSlot => hasSearchBar || hasTabBar || header != null;

  /// 是否画任何材质（磨砂或叠色）。
  bool get hasMaterial => showBlur || showSurface;

  /// 标题区高度：有标题 = 大标题墨心 + 一整行；无标题 = 只剩材质盒
  /// （不画任何材质则为 0）。
  ///
  /// **有头部区且无标题时为 0**：头部区自带状态栏让位，材质层是盖在整条
  /// 顶栏上的叠加层（见 [materialExtent]），不再需要一个 128.9dp 高的空块把
  /// 搜索栏往下推。
  double titleExtent(double largeTitleFontSize) => title != null
      ? MiTopBarMetrics.componentHeight(largeTitleFontSize)
      : (hasMaterial && !hasHeaderSlot ? MiTopBarMetrics.scrimHeight : 0);

  /// 头部区高度（含状态栏让位；无头部内容为 0）。
  ///
  /// 与 [occupiedHeight]、`build` 三处共用同一套声明值，改一处同步生效。
  double headerExtent(BuildContext context) {
    if (!hasHeaderSlot) return 0;
    var extent = MiTopBarMetrics.headerTopInsetFor(
      MediaQuery.paddingOf(context).top,
    );
    if (header != null) return extent + header!.preferredSize.height;
    if (hasSearchBar) extent += searchBarHeight;
    if (hasSearchBar && hasTabBar) {
      extent += MiTopBarMetrics.searchBarGap;
    }
    if (hasTabBar) extent += tabBarHeight;
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

  /// 材质（磨砂 + 叠色）层的高度，两样都不画则 0。
  ///
  /// 就是「顶栏盖住的这块区域」：无头部区 → 实测材质盒
  /// [MiTopBarMetrics.scrimHeight]（128.9dp）；有头部区 → 整条顶栏
  /// （[occupiedHeight]）。磨砂的 σ(y) 曲线会**拉伸到同一高度**并在这里归零
  /// （见 [visibleBlurBands]），所以栏底既不糊也不留硬边。
  double materialExtent(BuildContext context) {
    if (!hasMaterial) return 0;
    return hasHeaderSlot
        ? occupiedHeight(context)
        : MiTopBarMetrics.scrimHeight;
  }

  /// 渲染时真正要绘制的模糊段 —— 转发到 [MiGradientBlur.bandsFor]。
  ///
  /// 磨砂本体已抽成独立组件 [MiGradientBlur]（它属于**内容区**，不属于顶栏）；
  /// 顶栏只是按自己的材质盒高复用它。这里保留转发仅为既有引用与测试。
  ///
  /// 几何按 [extent]（材质盒高）等比拉伸、σ 不变：实测曲线
  /// （[MiGradientBlurProfile.bands]）末段落在 119dp，头部区形态的材质高
  /// 156dp，曲线就整体拉到 156 才归零 —— 对照分类页截图：模糊一直糊到胶囊行
  /// 下方、横幅底缘才变清晰。叠色的比例 stop 同样随盒子拉长，实心段下沿要按
  /// 同一比例换算后再传给组件。
  @visibleForTesting
  static List<MiTopBarBlurBand> visibleBlurBands(
    MiTopBarPalette palette, {
    double extent = MiTopBarMetrics.scrimHeight,
    bool underSurface = true,
  }) =>
      MiGradientBlur.bandsFor(
        extent: extent,
        opaqueScrimBottom: palette.scrimOpaqueBottom *
            (extent / MiTopBarMetrics.scrimHeight),
        underSurface: underSurface,
      );

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

    // 头部区：**顶栏自己产出**框架组件本体 —— 调用方只给数据（hint / tabs），
    // 拿到的就是统一渲染的 MiSearchBar / MiPillTabBar；要换皮才用插槽覆盖。
    // 明暗配方由顶栏解析后的 mode 统一驱动，页面无需再各传一遍 themeMode。
    // 顶栏自己画磨砂时（showBlur），内置组件**不再自绘 backdrop**：整条栏只糊
    // 一次，否则栏内比周围更糊、且多一份每帧全 QUAD 高斯。
    final resolvedSearchBar = searchBar ??
        (searchHint == null
            ? null
            : MiSearchBar(
                hint: searchHint!,
                onTap: onSearchTap,
                themeMode: mode,
                frosted: !showBlur,
              ));
    final resolvedTabBar = tabBar ??
        (tabs == null
            ? null
            : MiPillTabBar(
                labels: tabs!,
                selectedIndex: selectedTab,
                onTap: onTabChanged ?? _ignoreTabTap,
                themeMode: mode,
                frosted: !showBlur,
              ));
    // 材质层：磨砂（可关，独立组件）+ 压色（可关），两者共用「顶栏盖住的
    // 那块区域」，磨砂曲线拉伸到同一高度并在那里归零。
    final materialHeight = materialExtent(context);

    return SizedBox(
      // 顶部叠加的根：材质层是**盖在**整条顶栏上的底，不占布局高度 ——
      // 这样「纯材质」形态高度仍是 128.9，「搜索栏 + 胶囊行」形态高度就是
      // 56 + 44.1 + 16 + 39.9，两者不会被材质盒互相污染。
      width: double.infinity,
      child: Stack(
        children: [
          // 0) 材质底（磨砂 + 压色），铺满 materialHeight
          if (materialHeight > 0)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: materialHeight,
              child: IgnorePointer(
                child: Stack(
                  children: [
                    // 1) 磨砂：**内容区自己那层顶部渐进模糊**，本体是独立组件
                    //    [MiGradientBlur]（与顶栏无关，只是位置正好重合）。
                    //    压色盒比曲线高时其比例 stop 会一起拉长，实心段下沿
                    //    按同一比例换算后再交给组件跳过。
                    if (showBlur)
                      MiGradientBlur(
                        height: materialHeight,
                        opaqueScrimBottom: palette.scrimOpaqueBottom *
                            (materialHeight / MiTopBarMetrics.scrimHeight),
                        underSurface: showSurface,
                      ),
                    // 2) 叠色：顶部最深 → 渐隐（亮色 = 页底色 @0.65→0，深色 = 黑
                    //    @1→0，两页各自实测，见 MiTopBarPalette 文档）。
                    //    梯度 stop 是比例值，盒子拉高即等比拉伸。
                    if (showSurface)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration:
                              BoxDecoration(gradient: palette.scrimGradient),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                // 有标题时到大标题墨心 + 一整行（够高不裁标题）；纯材质形态高度
                // 由上面的材质层决定，这里为 0。
                height: titleExtent(largeSize),
                child: Stack(
                  children: [
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
                  if (resolvedSearchBar != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: headerInset),
                      child: SizedBox(
                        height: searchBarHeight,
                        child: resolvedSearchBar,
                      ),
                    ),
                  if (resolvedSearchBar != null && resolvedTabBar != null)
                    const SizedBox(height: MiTopBarMetrics.searchBarGap),
                  // 胶囊行满宽：靠自身 11.9 的 edgeInset 与搜索栏左缘对齐，
                  // 同时保留横向出血滚动（再套内边距会把末尾胶囊多裁一截）。
                  if (resolvedTabBar != null)
                    SizedBox(height: tabBarHeight, child: resolvedTabBar),
                ],
              ),
            ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 内置胶囊行未给 [MiTopBar.onTabChanged] 时的空回调 —— 顶栏仍可展示标签，
/// 但点按不改变选中态（`MiPillTabBar` 的 `onTap` 是必填）。
void _ignoreTabTap(int _) {}

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
