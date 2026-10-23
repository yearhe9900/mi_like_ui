import 'package:flutter/material.dart';

import '../../../icons/nav_icons.dart';
import '../../../theme/top_bar_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/typography.dart';
import '../../../utils/filter_cache.dart';
import '../../effects/gradient_blur/gradient_blur.dart';
import '../../inputs/search_bar/search_bar.dart';
import '../../inputs/search_bar/search_cancel_button.dart';
import '../../inputs/search_bar/search_cancel_metrics.dart';
import '../pill_tab_bar/pill_tab_bar.dart';
import 'top_bar_metrics.dart';

/// 大标题折叠顶部导航栏（明暗双模式）。
///
/// 顶栏由「标题区」（材质 + 大 / 紧凑标题 + 返回圆钮）与可选「头部区」
/// （搜索栏 / 胶囊标签行）组成，支持滚动联动折叠、可内嵌头部组件与搜索态。
/// 几何规格见 [MiTopBarMetrics]，材质与配色见 `theme/top_bar_tokens.dart`。
///
/// ## 材质
///
/// 材质为「磨砂 + 压色」两层，由 [showBlur] 与 [showSurface] 独立控制，
/// 绘制为顶栏区域的背景（不占布局高度，高度见 [materialExtent]）：
///
///  * **磨砂**（[showBlur]）：backdrop 高斯模糊，按是否有头部区取两种曲线 ——
///    * 无头部区（纯标题 / 纯材质）：**渐进磨砂**，σ 自
///      [MiTopBarPalette.blurSigma]（5.37dp）沿 y 衰减至材质盒底归零
///      （[MiGradientBlurProfile.bands]；盒高变化时曲线形状固定、范围等比
///      伸缩）；
///    * 有头部区（搜索栏 / 标签行）：**恒定磨砂**，σ 5.37dp 铺满整条头部区
///      （0…[occupiedHeight]），栏底硬切（[uniformBlurBands]）。
///  * **压色**（[showSurface]）：顶部最深、向下渐隐的压色层
///    （[MiTopBarPalette.scrimGradient]），保证标题可读。大标题形态默认开启；
///    头部区形态（页面内容本身不压色）建议传 `false`。
///
/// 渐进曲线以分段定 σ 阶梯实现（每段 `ClipRect` + `BackdropFilter`，
/// σ 取曲线段中点值；段高 ≤ 17dp、相邻 σ 比 ≤ 1.5，视觉无台阶）：Flutter
/// 不提供位置相关模糊，且对模糊层施加半透明遮罩会破坏其 backdrop，
/// 分段并列是等效近似。
///
/// ## 折叠行为
///
///  * **大标题随内容滚动**：位移与列表滚动 1:1 联动（非缩小锚定）；
///  * 大标题叠加独立淡出曲线（位移 ≈20dp 内归零），紧凑标题在约 20dp 处
///    开始淡入衔接，两段不重叠；
///  * 两段标题的基线均以 `Baseline` 锚定（[MiTopBarMetrics.titleBaselineY]），
///    垂直落点不随字体族的 ascent/descent 漂移；
///  * 返回圆钮按压反馈：⌀44.1 圆盘高光（@9.4%），420ms 淡入 / 300ms 淡出。
///
/// ## 形态
///
/// | 形态 | `title` | `showBlur` | `showSurface` | 头部区 | 典型用法 |
/// |------|---------|-----------|---------------|--------|----------|
/// | 大标题折叠 | 有 | `true` | `true` | — | 首页 / 「我的」/ 设置页 |
/// | 纯材质 | `null` | `true` | `true` | — | 顶栏不内嵌组件的页面 |
/// | 吸顶头部 | `null` | `true` | `false` | `searchHint` + `tabs` | 搜索栏 + 标签行吸顶（恒定磨砂、不压色） |
/// | 材质 + 头部 | `null` | `true` | `true` | 任意 | 需要压色底的自定义头部 |
/// | 零件自带玻璃 | `null` | `false` | `false` | 任意 | 材质交给插槽组件自行绘制 |
///
/// ## 头部区
///
/// 头部内容默认由顶栏内部产出，调用方只提供数据：
///
/// | 头部内容 | 声明式入参 | 内部产出 | 高度 |
/// |----------|------------|----------|------|
/// | 搜索栏 | [searchHint] / [onSearchTap] | `MiSearchBar` | [searchBarHeight]（44.1） |
/// | 胶囊标签行 | [tabs] / [selectedTab] / [onTabChanged] | `MiPillTabBar` | [tabBarHeight]（39.9） |
///
/// 需要自定义组件时改用同名插槽（与声明式入参互斥，构造期校验）：
///
/// | 插槽 | 类型 | 高度来源 | 布局 |
/// |------|------|----------|------|
/// | [searchBar] | `Widget` | [searchBarHeight] | 左右 [headerInset]，顶部让开状态栏 |
/// | [tabBar] | `Widget` | [tabBarHeight] | 满宽（自带 11.9 边距，支持横向出血滚动），与搜索栏间隔 16 |
/// | [header] | `PreferredSizeWidget` | `preferredSize.height` | 左右 [headerInset]，整块自定义头部 |
///
/// [header] 与搜索栏 / 标签行互斥。插槽高度为声明值：顶栏据此排版，宿主据
/// [occupiedHeight] 给滚动内容让位，两侧同源不错位；自定义组件请同步传高度。
///
/// ## 用法 —— 吸顶头部
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
/// ## 用法 —— 大标题折叠
///
/// 本组件不自带滚动，由宿主提供滚动位移（受控组件），叠在滚动内容之上：
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
/// 纯材质形态（不绘制标题，高度收到 [MiTopBarMetrics.scrimHeight]）：
///
/// ```dart
/// Positioned(top: 0, left: 0, right: 0, child: MiTopBar())
/// ```
///
/// ## 布局契约
///
///  * **必须以 `Positioned` 钉在顶部**（或由外层提供紧约束）：作为 `Stack`
///    的非定位子级会使其收缩到顶栏自身尺寸，进而在 loose 约束的上级中被
///    居中，导致整页错位；
///  * **坐标原点为屏幕顶端**：规格已含状态栏让位
///    （[MiTopBarMetrics.statusBarHeight]），顶部不要再叠加 `SafeArea`；
///    头部插槽区自带让位（[MiTopBarMetrics.headerTopInsetFor]，安全区更高时
///    取安全区）；
///  * 材质层只覆盖顶部区域，其下内容照常透出；除返回圆钮与插槽本身外
///    整体不参与手势。
///
/// [themeMode] 为空时跟随环境 `Theme.of(context).brightness`。
/// 返回圆钮默认不显示（顶层页无返回）：传 `showBack: true` 显示，
/// 可点性由 [onBack] 决定（`null` = 不可点）。
///
/// ## 搜索态（[searchActive]）
///
/// 宿主置 [searchActive] 为 `true` 进入搜索态：
///
///  * 内置搜索栏切换为输入态（`MiSearchBar(editable: true)`，聚焦弹键盘）；
///  * 右侧让出取消钮（`MiSearchCancelButton`，⌀44.1，转场中段淡入），
///    点按经 [onSearchCancel] 通知宿主退出；
///  * 胶囊标签行淡出并退出排版（不计入 [occupiedHeight]）；
///  * 材质盒高度收到「仅搜索栏」档。
///
/// 转场 480ms（起手静止 48ms + 位移 `easeOutQuint` 430ms），参数见
/// [MiTopBarMetrics.searchTransitionMs] / [MiTopBarMetrics.searchMotion]。
class MiTopBar extends StatefulWidget {
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
    this.overContent = false,
    this.searchActive = false,
    this.onSearchCancel,
    this.searchController,
    this.searchFocusNode,
    this.searchAutofocus = true,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.searchCancelInset = MiSearchCancelMetrics.trailingInset,
    this.headerTopInset = MiTopBarMetrics.headerTopInset,
    this.searchBarMaxWidth,
    this.actions,
    this.sigmaScale = 1.0,
  })  : assert(scrollOffset >= 0, 'scrollOffset 不能为负（未滚动时传 0）'),
        assert(
            header == null ||
                (searchBar == null &&
                    searchHint == null &&
                    tabBar == null &&
                    tabs == null),
            'header 与搜索栏 / 胶囊行互斥：给了整块头部就不要再给零件'),
        assert(searchBar == null || searchHint == null,
            '搜索栏二选一：searchBar（自定义组件）与 searchHint（内置 MiSearchBar）不能同时给'),
        assert(tabBar == null || tabs == null,
            '胶囊行二选一：tabBar（自定义组件）与 tabs（内置 MiPillTabBar）不能同时给'),
        assert(searchBarHeight > 0, 'searchBarHeight 必须为正'),
        assert(tabBarHeight > 0, 'tabBarHeight 必须为正'),
        assert(headerInset >= 0, 'headerInset 不能为负'),
        assert(searchCancelInset >= 0, 'searchCancelInset 不能为负'),
        assert(headerTopInset >= 0, 'headerTopInset 不能为负'),
        assert(
            searchBarMaxWidth == null || searchBarMaxWidth > 0,
            'searchBarMaxWidth 必须为正（或不传 = 不限宽）'),
        assert(sigmaScale > 0, 'sigmaScale 必须为正'),
        assert(selectedTab >= 0, 'selectedTab 不能为负'),
        assert(!searchActive || (searchBar != null || searchHint != null),
            'searchActive 只在有搜索栏时有意义：先给 searchHint（或 searchBar 插槽）'),
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
  /// 大标题形态靠它压住下方内容、保证标题可读；头部件形态（分类页）度量
  /// 参考页没有这层压色 —— 那页整条栏都能看见被模糊的背景，所以传 `false`。
  ///
  /// 磨砂见 [showBlur]。
  final bool showSurface;

  /// 是否绘制**顶部磨砂**（默认 true）。
  ///
  /// 磨砂本体是内容区自己的（度量：有一页完全没有顶栏 —— 主题商店
  /// 「每日精选」—— 内容顶部照样糊），顶栏只是位置正好重合、按自己的材质盒
  /// 高复用。**两种形态两套规律**：
  ///  * 无头部区：渐进曲线（独立组件 [MiGradientBlur]），σ 沿 y 递减到材质盒
  ///    底归零 —— 栏底既不糊也不留硬边；
  ///  * 有头部区：**一整段恒定 σ**（[uniformBlurBands]）铺满整条栏，到栏底
  ///    硬切 —— 首页素材度量搜索栏与胶囊行后方糊得一样重（详见类文档）。
  ///
  /// 内置的搜索栏 / 胶囊行会自动关掉自绘的 backdrop（`frosted: false`），
  /// 整条栏只糊一次。
  final bool showBlur;

  /// 头部区是否**压在内容上**（照片/视频从下方经过，默认 false）。
  ///
  /// 只影响内置零件的填充（[searchHint] / [tabs] 产出的组件）：
  /// 开启后在低调填充之下再垫一层玻璃膜（[MiTransparencyTokens.veiledFill]）。
  /// 首页素材度量：压在横幅上的胶囊内侧比同 y 间隙亮 33 级（亮）/暗 100 级
  /// （暗），那层落差只能来自膜 —— 模糊只改局部对比、不改局部均值。
  ///
  /// **膜取页底色，垫在同色页底上等于没垫**：静止态（背后是页底）观感与不开
  /// 时一致，只有内容滚到头部后面才显出玻璃片。所以分类页这种「静止态平底、
  /// 滚动态有内容」的页面也该开着，不需要随滚动状态切换。
  ///
  /// 与 [showBlur] 是两件事：磨砂管**糊**，膜管**形**。
  final bool overContent;

  // ── 搜索态 ──────────────────────────────────────────────────────────────
  /// 是否处于**搜索态**（默认 false）—— 点按搜索栏后由宿主置 true。
  ///
  /// 进入后：内置搜索栏变真输入框（光标 + 键盘）、右侧淡入取消钮、胶囊行
  /// 淡出并退出排版。转场见 [MiTopBarMetrics.searchTransitionMs]。
  ///
  /// 只有 `searchHint` 产出的**内置**搜索栏会自动变成输入框；传 [searchBar]
  /// 插槽时布局照样给取消钮让位，但「会不会输入」由插槽组件自己决定。
  final bool searchActive;

  /// 取消钮点按回调（搜索态右侧那个 ⌀44.1 圆钮）；null = 只展示不可点。
  ///
  /// 宿主一般在这里把 [searchActive] 置回 false。
  final VoidCallback? onSearchCancel;

  /// 内置搜索栏的输入控制器（仅 [searchActive] 且用 [searchHint] 时生效）。
  final TextEditingController? searchController;

  /// 内置搜索栏的焦点节点（同上）。
  final FocusNode? searchFocusNode;

  /// 进入搜索态是否自动聚焦（默认 true —— 参考素材点按即弹键盘）。
  final bool searchAutofocus;

  /// 输入变化回调（同上）。
  final ValueChanged<String>? onSearchChanged;

  /// 键盘提交回调（同上）。
  final ValueChanged<String>? onSearchSubmitted;

  /// 取消钮右缘距屏幕右缘（默认 [MiSearchCancelMetrics.trailingInset] = 0）。
  ///
  /// 默认 0 是**度量**：参考素材里横向四项闭合（左 21 + 栏 491 + 间隙 15 +
  /// 直径 66 = 593 ≈ 屏宽 592），且圆在纵向同样 66px 高，说明没有被帧边界
  /// 裁掉 —— 参考实现就是贴着屏幕右缘。想改成留白就覆盖这个值。
  final double searchCancelInset;

  // ── 宽屏收敛（桌面档专属，推导值） ────────────────────────────────────────
  //
  // 参考素材只有手机档，以下三项都是**推导值**：手机传默认值时逐像素不变。

  /// 头部区顶部让位（默认 [MiTopBarMetrics.headerTopInset] 56 —— 手机档
  /// **度量**：搜索栏顶缘 y = 56）。
  ///
  /// 桌面窗口没有状态栏，传 [MiTopBarMetrics.desktopHeaderTopInset]（24）：
  /// 继续留 56 会在窗口顶部悬出一条空带。
  final double headerTopInset;

  /// 内置搜索栏的最大宽度（dp）；null = 不限宽（铺满 headerInset 之间的区域）。
  ///
  /// 手机档不需要它（393dp 宽本来就窄）；桌面 1120dp 的内容列上一条 1000dp+
  /// 的搜索框既难用也不像桌面应用 —— 传 480…560 一档（示例取 520），搜索栏
  /// 靠左停在 [headerInset] 处，右侧留给 [actions] 与空白。
  ///
  /// 只作用于**内置/插槽搜索栏的排版宽度**：搜索态转场的「右缘让位」几何
  /// 照旧（限宽后让位量不变，取消钮仍落在同一相对位置）。
  final double? searchBarMaxWidth;

  /// 头部区搜索栏**右侧**的动作区（桌面档）：一排按钮 / 图标，右对齐到
  /// [headerInset]。
  ///
  /// 与搜索栏同一行（搜索栏限宽后右侧的空白就归它）；搜索态转场时随整行
  /// 一起淡出（与胶囊行同一段转场，`Opacity` 只包**无磨砂**的动作件，
  /// 磨砂子树不许进这一层 —— 见类文档的 saveLayer 约束）。
  ///
  /// null = 不渲染（手机档默认）。纵向占位 = [searchBarHeight]。
  final List<Widget>? actions;

  /// 磨砂 σ 缩放系数（默认 1.0 = 度量材质，逐像素不变）。
  ///
  /// **滚动降 σ**：滚动中 backdrop 每帧重算，是本库最贵的一块。宿主在滚动
  /// 期间把它压到 < 1（如 0.6），停下后传回 1.0 —— σ 与高斯成本近似线性，
  /// 视觉上运动中的模糊弱一点几乎不可察觉（运动掩蔽），GPU 却省下近半。
  ///
  /// 作用于**两套磨砂规律**：无头部区的渐进曲线（[MiGradientBlur]）与有
  /// 头部区的恒定段（[uniformBlurBands]）。σ 是 [MiFilterCache] 的缓存键，
  /// 两档各自缓存、跨帧复用，来回切不会每帧新建 native filter。
  final double sigmaScale;

  /// 头部区是否有搜索栏（声明式入参或插槽任一生效）。
  bool get hasSearchBar => searchBar != null || searchHint != null;

  /// 头部区是否有胶囊标签行（声明式入参或插槽任一生效）。
  bool get hasTabBar => tabBar != null || tabs != null;

  /// 头部区是否有内容。
  bool get hasHeaderSlot => hasSearchBar || hasTabBar || header != null;

  /// 是否画任何材质（磨砂或叠色）。
  bool get hasMaterial => showBlur || showSurface;

  /// 是否真正处于搜索态（给了 [searchActive] 但没有搜索栏时为 false）。
  bool get isSearchMode => searchActive && hasSearchBar;

  /// 标题区高度：有标题 = 大标题墨心 + 一整行；无标题 = 只剩材质盒
  /// （不画任何材质则为 0）。
  ///
  /// **有头部区且无标题时为 0**：头部区自带状态栏让位，材质层是盖在整条
  /// 顶栏上的叠加层（见 [materialExtent]），不再需要一个 128.9dp 高的空块把
  /// 搜索栏往下推。搜索态收缩到 0（标题淡出，让位给整条搜索栏）。
  double titleExtent(double largeTitleFontSize) =>
      title != null && !isSearchMode
          ? MiTopBarMetrics.componentHeight(largeTitleFontSize)
          : (hasMaterial && !hasHeaderSlot ? MiTopBarMetrics.scrimHeight : 0);

  /// 头部区高度（含状态栏让位；无头部内容为 0）。
  ///
  /// 与 [occupiedHeight]、`_buildBar` 三处共用同一套声明值，改一处同步生效。
  /// **搜索态不含胶囊行**（那一行淡出并退出排版）。
  double headerExtent(BuildContext context) {
    if (!hasHeaderSlot) return 0;
    var extent = MiTopBarMetrics.headerTopInsetFor(
      MediaQuery.paddingOf(context).top,
      topInset: headerTopInset,
    );
    if (header != null) return extent + header!.preferredSize.height;
    if (hasSearchBar) extent += searchBarHeight;
    final showTabs = hasTabBar && !isSearchMode;
    if (hasSearchBar && showTabs) {
      extent += MiTopBarMetrics.searchBarGap;
    }
    if (showTabs) extent += tabBarHeight;
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
  /// 就是「顶栏盖住的这块区域」：无头部区 → 度量材质盒
  /// [MiTopBarMetrics.scrimHeight]（128.9dp）；有头部区 → 整条顶栏
  /// （[occupiedHeight]）。磨砂在这里收尾：无头部区的渐进曲线拉伸到盒底
  /// 归零（无硬边），有头部区的恒定 σ 段则到盒底**硬切**（见
  /// [uniformBlurBands]）。
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
  /// **只服务「无头部区」形态**（纯标题 / 纯材质）—— 那一档是渐进曲线：
  /// 几何按 [extent]（材质盒高）等比拉伸、σ 不变（[MiGradientBlurProfile.bands]
  /// 末段落在 119dp，材质盒 128.9dp 就整体拉到 128.9 才归零）。有头部区的
  /// 形态走恒定 σ 的另一套规律，见 [uniformBlurBands]。
  @visibleForTesting
  static List<MiTopBarBlurBand> visibleBlurBands(
    MiTopBarPalette palette, {
    double extent = MiTopBarMetrics.scrimHeight,
    bool underSurface = true,
  }) =>
      MiGradientBlur.bandsFor(
        extent: extent,
        opaqueScrimBottom:
            palette.scrimOpaqueBottom * (extent / MiTopBarMetrics.scrimHeight),
        underSurface: underSurface,
      );

  /// **有头部区**形态的磨砂：一整段恒定 σ 铺满 0…[extent]，到栏底硬切。
  ///
  /// 与 [visibleBlurBands] 是两套度量规律：头部区那张截图（首页亮/暗，
  /// 881×1920）里 σ 沿 y **不衰减** —— 搜索栏行、栏与胶囊之间的间隙、
  /// 胶囊行后方树影糊得一样重，胶囊底缘（度量 152dp = 状态栏让位 51.8 +
  /// 搜索栏 43.7 + 间隙 16.5 + 胶囊 39.9）以下内容立刻锐利。
  ///
  /// 恒定 σ 只要一段：既是真机形态，也比「曲线拉到 156dp」少 7 段全宽高斯。
  /// 深色开叠色时，α = 1 的实心段之下那段模糊 100% 不可见，照旧跳过
  ///（[underSurface] 为 `false` 时不得跳，否则栏顶一片清晰）。
  @visibleForTesting
  static List<MiTopBarBlurBand> uniformBlurBands(
    MiTopBarPalette palette, {
    required double extent,
    bool underSurface = true,
    double sigmaScale = 1.0,
  }) {
    if (extent <= 0) return const <MiTopBarBlurBand>[];
    final sigma = MiTopBarPalette.blurSigma * sigmaScale;
    if (sigma < MiGradientBlurProfile.minVisibleSigma) {
      return const <MiTopBarBlurBand>[];
    }
    // 压色实心段下沿：叠色 gradient 的 stop 是比例值，随盒子等比拉长
    final opaque = underSurface
        ? palette.scrimOpaqueBottom * (extent / MiTopBarMetrics.scrimHeight)
        : 0.0;
    final top = opaque.isFinite && opaque > 0 && opaque < extent ? opaque : 0.0;
    if (extent <= top) return const <MiTopBarBlurBand>[];
    return [MiTopBarBlurBand(top: top, height: extent - top, sigma: sigma)];
  }

  /// 把恒定 σ 的模糊段铺成「满宽 `ClipRect` + 单个 `BackdropFilter`」。
  ///
  /// 与 [MiGradientBlur] 的多段阶梯不同，头部区只有一段；[MiFilterCache]
  /// 让同 σ 的 native filter 跨帧复用（滚动时每帧都要走这里）。
  Iterable<Widget> _uniformBands(List<MiTopBarBlurBand> bands) sync* {
    for (final band in bands) {
      yield Positioned(
        left: 0,
        right: 0,
        top: band.top,
        height: band.height,
        child: ClipRect(
          child: BackdropFilter(
            filter: MiFilterCache.blur(band.sigma),
            child: const SizedBox.expand(),
          ),
        ),
      );
    }
  }

  @override
  State<MiTopBar> createState() => _MiTopBarState();

  /// 顶栏的完整构建，[progress] = 搜索态转场的**线性**进度（0 = 常规态，1 = 搜索态）。
  ///
  /// 常规态 `progress = 0`，此时函数体里的每一处插值都退化成原值 —— 搜索态
  /// 是**叠加**上来的一层状态，不是另一套布局，非搜索页逐像素不变。
  ///
  /// 两个进度分开用：几何走 [MiTopBarMetrics.searchMotion]（前 10% 静止 +
  /// easeOutQuint），透明度类走线性 [progress] —— 度量里它们本来就不是一条
  /// 曲线（取消钮的淡入落在中段，与位移进度并不同步）。
  Widget _buildBar(BuildContext context, double progress) {
    final t = MiTopBarMetrics.searchMotion.transform(progress).clamp(0.0, 1.0);
    final mode = themeMode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    final palette = MiTopBarPalette.of(mode);
    final title = this.title;
    // 搜索态下标题整体淡出（参考素材那页的大标题在转场中消失）。
    final titleFade = 1 - progress;
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
    // 与字体 ascent/descent 无关 —— 这是本组件对齐素材的关键（用 `height`
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
    final searching = isSearchMode;
    final resolvedSearchBar = searchBar ??
        (searchHint == null
            ? null
            : MiSearchBar(
                hint: searchHint!,
                onTap: onSearchTap,
                themeMode: mode,
                frosted: !showBlur,
                overContent: overContent,
                // 搜索态：同一个组件换成真输入框（几何 / 配色不变）。
                // 进入时靠 autofocus 弹键盘，退出时 TextField 被换掉即失焦。
                editable: searching,
                controller: searchController,
                focusNode: searchFocusNode,
                autofocus: searching && searchAutofocus,
                onChanged: onSearchChanged,
                onSubmitted: onSearchSubmitted,
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
                overContent: overContent,
              ));
    // 材质层：磨砂（可关，独立组件）+ 压色（可关），两者共用「顶栏盖住的
    // 那块区域」，磨砂曲线拉伸到同一高度并在那里归零。
    //
    // 搜索态下材质盒矮了一整行「间隙 + 胶囊行」。`materialExtent` 给的是
    // **目标态**的值（它就是按 [isSearchMode] 算的），所以这里把常规态的值
    // 反推回来再插值 —— 转场中磨砂边界跟着收，不会在最后一帧突然跳。
    final targetMaterialHeight = materialExtent(context);
    final collapsedRow = hasSearchBar && hasTabBar
        ? MiTopBarMetrics.searchBarGap + tabBarHeight
        : 0.0;
    final materialHeight = searching && collapsedRow > 0
        ? targetMaterialHeight + collapsedRow * (1 - t)
        : targetMaterialHeight;

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
                    // 1) 磨砂：**两种形态两套规律**（各自度量，见类文档）
                    //    · 无头部区 → 内容区自己那层顶部**渐进**模糊，本体是独立
                    //      组件 [MiGradientBlur]（与顶栏无关，只是位置正好重合）。
                    //      压色盒比曲线高时其比例 stop 会一起拉长，实心段下沿
                    //      按同一比例换算后再交给组件跳过。
                    //    · 有头部区 → **一整段恒定 σ** 铺满整条栏、到栏底硬切
                    //      （首页素材度量：胶囊行附近照样是满强度模糊）。
                    //      顺带把这一档从 8 段全宽高斯压到 1 段。
                    if (showBlur)
                      if (hasHeaderSlot)
                        ..._uniformBands(
                          uniformBlurBands(
                            palette,
                            extent: materialHeight,
                            underSurface: showSurface,
                            sigmaScale: sigmaScale,
                          ),
                        )
                      else
                        MiGradientBlur(
                          height: materialHeight,
                          opaqueScrimBottom: palette.scrimOpaqueBottom *
                              (materialHeight / MiTopBarMetrics.scrimHeight),
                          underSurface: showSurface,
                          sigmaScale: sigmaScale,
                        ),
                    // 2) 叠色：顶部最深 → 渐隐（亮色 = 页底色 @0.65→0，深色 = 黑
                    //    @1→0，两页各自度量，见 MiTopBarPalette 文档）。
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
                // 由上面的材质层决定，这里为 0。搜索态收到 0（标题同时淡出）。
                height: title != null && searching
                    ? MiTopBarMetrics.componentHeight(largeSize) * (1 - t)
                    : titleExtent(largeSize),
                child: Stack(
                  children: [
                    // 3) 大标题：随滚动 1:1 上移 + 按度量表淡出（钉基线 → top 恒为 0）
                    if (title != null)
                      Positioned(
                        left: MiTopBarMetrics.largeTitleLeadingInset,
                        top: 0,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: MiTopBarMetrics.largeTitleOpacity(offset) *
                                titleFade,
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
                    // 4) 紧凑标题：与返回圆钮同一行、屏内水平居中（度量 609.5px ≈ 屏心）
                    if (title != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity:
                                MiTopBarMetrics.compactTitleOpacity(offset) *
                                    titleFade,
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
                                    style: MiTypography.topBarCompactTitleFor(
                                        mode),
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
                      topInset: headerTopInset,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (header != null)
                        Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: headerInset),
                          child: SizedBox(
                            height: header!.preferredSize.height,
                            child: header,
                          ),
                        ),
                      if (resolvedSearchBar != null)
                        _searchRow(
                          bar: resolvedSearchBar,
                          mode: mode,
                          t: t,
                          progress: progress,
                        ),
                      // 搜索栏 ↔ 胶囊行间距 16dp（度量）；搜索态两行都不在，随 t
                      // 一起让位。
                      if (resolvedSearchBar != null &&
                          resolvedTabBar != null &&
                          t < 1)
                        SizedBox(
                            height: MiTopBarMetrics.searchBarGap * (1 - t)),
                      // 胶囊行：搜索态淡出（参考素材那页没有标签行，这一段的
                      // 呈现属推导 —— 与取消钮同一段转场里退场，不硬切）。
                      // ⚠️ 不要给自带 backdrop 的自定义 `tabBar` 走这条路：Opacity
                      // 会引入 saveLayer 并把底下的 backdrop 变空（见类文档）。
                      if (resolvedTabBar != null && t < 1)
                        SizedBox(
                          height: tabBarHeight,
                          child: Opacity(
                            opacity: 1 - progress,
                            child: resolvedTabBar,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 搜索栏那一行：左侧搜索栏 + 右侧取消钮。
  ///
  /// 常规态（`t = 0`）退化成「左右各留 [headerInset] 的整宽搜索栏」，与加
  /// 这个状态之前逐像素一致；转场中搜索栏右缘左移让出取消钮的位置
  /// （度量：让位目标 = 间隙 10.0 + 直径 44.1，右缘贴屏 `searchCancelInset` = 0）。
  ///
  /// [t] 是**缓动之后**的位移进度（0…1），[progress] 是线性时间进度；
  /// 取消钮的淡入区间落在后者上（度量它与位移不同步）。
  ///
  /// ## 宽屏路径（给了 [searchBarMaxWidth] 或 [actions] 时）
  ///
  /// 换成 `Row`：搜索栏限宽后**靠左**停在 [headerInset]，右侧依次是
  /// [actions]（随转场淡出、`t = 1` 退出排版 —— 与胶囊行同一契约）与取消钮。
  /// 手机路径（两者都没给）保持原 Stack 几何，逐像素不变。
  Widget _searchRow({
    required Widget bar,
    required MiThemeMode mode,
    required double t,
    required double progress,
  }) {
    const double gap = MiSearchCancelMetrics.barGap;
    const double diameter = MiSearchCancelMetrics.diameter;
    final hasActions = actions != null && actions!.isNotEmpty;
    final wide = hasActions || searchBarMaxWidth != null;

    final cancelFade = const Interval(
      MiTopBarMetrics.searchCancelFadeBegin,
      MiTopBarMetrics.searchCancelFadeEnd,
    ).transform(progress).clamp(0.0, 1.0);

    // 搜索态取消钮（两种路径共用）：点按经 onSearchCancel 通知宿主退出。
    // IgnorePointer 必须包在**外层**：淡出到 0 时若还留在命中测试里，
    // 这块不可见区域会吞掉下方内容的点击。
    Widget cancelButton = IgnorePointer(
      ignoring: cancelFade <= 0,
      child: Opacity(
        opacity: cancelFade,
        child: MiSearchCancelButton(
          onTap: onSearchCancel,
          themeMode: mode,
          frosted: !showBlur,
          overContent: overContent,
        ),
      ),
    );

    if (!wide) {
      // ── 手机路径（逐像素保持度量几何） ──────────────────────────────────
      // 让位量：0 → (间隙 + 直径)，再叠加右缘留白从 headerInset 收到目标值。
      final barRight =
          headerInset + (searchCancelInset + gap + diameter - headerInset) * t;
      final cancelRight =
          searchCancelInset + (headerInset - searchCancelInset) * (1 - t);
      return SizedBox(
        height: searchBarHeight,
        child: Stack(
          children: [
            Positioned(
              left: headerInset,
              right: barRight,
              top: 0,
              bottom: 0,
              child: bar,
            ),
            // t = 0 时干脆不建：闲置态不白挂一份 backdrop / 手势层。
            if (t > 0)
              Positioned(
                right: cancelRight,
                top: (searchBarHeight - diameter) / 2,
                child: cancelButton,
              ),
          ],
        ),
      );
    }

    // ── 宽屏路径 ──────────────────────────────────────────────────────────
    // 限宽搜索栏靠左 + 动作区 / 取消钮靠右。取消钮右缘停在 [headerInset]
    // （手机档的 `searchCancelInset = 0` 是「贴屏幕右缘」的**度量**，宽屏
    // 的内容列有页边距，照搬会顶到窗口边上）。
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: headerInset),
      child: SizedBox(
        height: searchBarHeight,
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: searchBarMaxWidth == null
                    ? bar
                    : ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: searchBarMaxWidth!),
                        child: bar,
                      ),
              ),
            ),
            // 动作区：随搜索转场淡出，t = 1 退出排版（同胶囊行契约）。
            // ⚠️ Opacity 只包**无磨砂**的动作件 —— 磨砂子树进这层会 saveLayer
            // 把 backdrop 清空（见类文档）。
            if (hasActions && t < 1)
              IgnorePointer(
                ignoring: progress > 0,
                child: Opacity(
                  opacity: 1 - progress,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                ),
              ),
            if (t > 0)
              Padding(
                padding: EdgeInsets.only(left: gap),
                child: cancelButton,
              ),
          ],
        ),
      ),
    );
  }
}

/// 顶栏状态：只为一件事存在 —— 搜索态转场的 [AnimationController]。
///
/// 转场**不进 `build` 的其余部分**：`_buildBar` 的每一处插值在 `t = 0` 时都
/// 退化成原值，所以非搜索页的视觉回归逐像素不变，也不会多出任何 render object。
class _MiTopBarState extends State<MiTopBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // ⚠️ 必须在 initState 里建：写成 `late final ... = AnimationController(value: widget.isSearchMode)` 时，这个初始化器会在**第一次
    // 访问**处（也就是 didUpdateWidget 里）才跑，那时 `widget` 已经是新值，
    // 于是控制器一出生就是 1.0 —— 转场被整段跳过（曾踩过）。
    _controller = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: MiTopBarMetrics.searchTransitionMs),
      value: widget.isSearchMode ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant MiTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSearchMode != oldWidget.isSearchMode) {
      // 时长对正反两向相同（度量只覆盖了进入方向；退出方向按同一时长反向
      // 播放，参考实现未单独录到）。
      if (widget.isSearchMode) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          widget._buildBar(context, _controller.value.clamp(0.0, 1.0)),
    );
  }
}

/// 内置胶囊行未给 [MiTopBar.onTabChanged] 时的空回调 —— 顶栏仍可展示标签，
/// 但点按不改变选中态（`MiPillTabBar` 的 `onTap` 是必填）。
void _ignoreTabTap(int _) {}

/// 返回圆钮：⌀44.1 命中区 + 箭头，按下时浮现白 @9.4% 圆盘（度量）。
///
/// 箭头墨心相对圆钮中心左偏 [MiTopBarMetrics.chevronCenterDx]（度量光学
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
          // 按压反馈圆盘（度量平坦填充、无描边）
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
          // 箭头：墨盒铺满，中心再按度量偏置平移
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
