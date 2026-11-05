# 模块与关键接口

按分层列出每个模块的**用途**与**关键接口**。所有公开类型都从
`package:mi_like_ui/mi_like_ui.dart` 导入；未导出的 `*_painter.dart` 属
内部实现。

- 布局与依赖规则：见 [ARCHITECTURE.md](ARCHITECTURE.md)
- 用法示例与配置：见 [USAGE.md](USAGE.md)
- 逐组件的设计度量与截图：见 [README](../README.md)

## 1. 设计 token（`src/theme/`）

| 模块 | 关键接口 | 用途 |
|---|---|---|
| 色板 | `MiColors`（`accent` / `pageBackgroundLight` / `pageBackgroundDark` / 墨色阶梯） | 度量色值；全库强调色同源 |
| 间距与圆角 | `MiDimens`（`spaceXs…spaceXxxl` / `radiusSm…radiusPill` / `disabledOpacity`） | 4 的倍数阶梯；禁用档 0.38 |
| 排版 | `MiTypography`（`navLabel` / `dialogAction` / `dialogItemSubtitle` / …） | 字号字重行距；墨心靠基线锚定 |
| 模式 | `MiThemeMode`（`light` / `dark`） | 明暗双配方枚举 |
| 主题注入 | `MiThemeData`（`mode` / `accent` / `pageBackgroundLight` / `pageBackgroundDark`）、`MiTheme`、`MiTheme.modeOf` / `modeOfOr` / `accentOf` / `pageBackgroundFor` | App 根部声明一次，全库跟随；优先级高于环境亮度、低于组件显式参数 |
| 动效 | `MiMotionTokens`（`pressMs` / `pressCurve` / `pressFadeInMs` / `panelExpand` / `panelCollapse`）、`miSpring(damping:, response:)` | 跨组件动效单一来源；Folme 口径弹簧换算 |
| 透明 / 磨砂 | `MiTransparencyTokens`（`blurSigma` / `dialogScrimFor` / `surfaceFillFor` / `glassMembraneFor` / `controlOffFillFor` / `switchTrackOffFor` / `sheetHandleFor` / …） | alpha、σ、叠色、遮罩的**唯一**来源 |
| 列表行几何 | `MiRowMetrics`（`paddingY` / `iconSize` / `mainLinePitch` / `heightFor(hasSubtitle:)`） | 设置行 / 偏好行 / 弹框列表共用的行高 47.2 / 68.2 |
| 组件配色 | `MiGlassTokens` / `MiGlassPalette` / `MiPillTabPalette` / `MiButtonPalette` / `MiSearchBarPalette` / `MiTopBarPalette` / `MiDialogPalette` / `MiMenuPalette` / `MiBottomSheetPalette` / `MiPullUpPanelPalette` / `MiSnackbarPalette` / `MiFloatingToolbarPalette` / `MiSettingsPalette` / `MiSwitchPalette` / `MiCheckboxPalette` | 各组件明暗双配方，均给 `of(mode)` 入口 |
| 模糊曲线 | `MiTopBarBlurBand` / `MiGradientBlurProfile` / `MiHeaderBlurProfile` | 渐进模糊的 σ 分档与拉伸规则 |

## 2. 视觉与交互基元（`src/foundations/`）

| 模块 | 关键接口 | 用途 |
|---|---|---|
| 连续圆角 | `MiSquircle.pathOf(...)` / `MiSquircleClipper(radius, topOnly:)` / `MiSquircleBorder(radius, {topOnly, side})` / `MiSquircleShadowPainter` | G2 连续曲率（HyperOS 角形）；描边与「只圆上两角」；投影按形状绘制（`BoxShadow` 会在圆角处漏影） |
| 三态反馈 | `MiPressable({onPressed, pressBuilder, mode, borderRadius, hover, focus, focusNode, onHoverChanged})`、`MiPressBuilder` | 按压状态机 + 悬停叠色 + 键盘焦点环一次装好；**按压视觉**由组件层 `pressBuilder` 决定；禁用时手势仍在但不响应 |
| 悬停 | `MiHoverFeedback({mode, borderRadius, enabled, onHoverChanged})` | 指针悬停叠色（白/黑 @5.6%）+ 手型光标；必须用实色层，禁止 `Opacity` |
| 焦点 | `MiFocusRing({onActivate, borderRadius, mode, focusNode, enabled})` | 2dp 焦点环 + Enter / Space 激活；`MiFocusRing.ringKey` 供测试 |
| 玻璃高光 | `MiGlassRimPainter` | 玻璃边缘高光描边 |
| 滤镜缓存 | `MiFilterCache.blur(sigma)` | `ImageFilter.blur` 按 σ 复用实例（同 σ 必同实例），省每帧 native 分配 |
| 格位数学 | `cellIndexAt(dx:, leadingInset:, cellWidth:, count:)` / `nearestCell(position, count)` | 等分格位命中与吸附（底栏 / 侧栏共用） |

## 3. 响应式与滚动（`src/layout/`）

| 模块 | 关键接口 | 用途 |
|---|---|---|
| 断点 | `MiWindowSize`（`compact` / `medium` / `expanded`）、`MiBreakpoints`（`compactMax` / `mediumMax` / `contentMaxWidth` / `usesSideNav` / `ofWidth`） | 三处断点各管一件事：窗口宽 / 画面容器宽 / 内容容器宽 |
| 视口 | `MiViewport`（`of(context)` / `ofWidth(width)`，`isCompact` / `isMedium` / `isExpanded`） | 读窗口档位 |
| 等比缩放 | `MiScaledCanvas({child, designSize, …})`、`scaleFor(...)` | 小窗等比缩到设计宽高，`scale == 1` 走零变换路径 |
| 内容列 | `MiContentColumn({child, …})` | 宽屏内容列恒定限宽（≤ 1120）并居中，图层不随断点增删 |
| 自适应网格 | `MiResponsiveGrid({children, maxCellWidth, …})` | 列数取「断点台阶」与「单元宽上限」较大者 —— 加列不加速度 |
| 滚动作用域 | `MiScrollBinder({child, …})`、`MiScrollScope` | 把滚动位移下发给 `MiTopBar` 等消费者，免逐页写 `NotificationListener` |

## 4. 组件（`src/components/`）

### 导航 `navigation/`

| 模块 | 关键接口 | 用途 |
|---|---|---|
| 折叠顶栏 | `MiTopBar({title, showBack, scrollOffset, searchHint, onSearchTap, searchActive, tabs, actions, showBlur, showSurface, sigmaScale, …})`、`MiTopBarMetrics`、`MiTopBar.…Key` | 大标题折叠、头部区（搜索栏 / 胶囊行）、渐进磨砂与顶栏压色两个独立开关 |
| 玻璃底栏 | `MiGlassNavBar({items, selectedIndex, onSelected, fab, …})`、`MiGlassNavItem`、`MiGlassNavFab`、`MiGlassNavMetrics` | 悬浮玻璃底栏；选中胶囊飞行 + 果冻形变 |
| 玻璃侧栏 | `MiGlassSideNavBar({items, selectedIndex, onSelected, expanded, fab, …})`、`MiGlassSideNavMetrics` | 宽屏侧栏：窄栏（95.4）/ 展开栏（176）两形态 |
| 胶囊标签行 | `MiPillTabBar({labels, selectedIndex, onSelected, …})`、`MiPillTabMetrics`、`MiPillItemWidth` | 分类标签；滚动时胶囊回弹 |
| 推入转场 | `MiCardPageRoute<T>({builder, …})`、`MiCardPageRouteMetrics` | 自右缘推入 + 前缘大圆角 + 下层视差与压暗 |

### 按钮 `buttons/`

| 模块 | 关键接口 | 用途 |
|---|---|---|
| 胶囊按钮 | `MiButton({label, onPressed, variant, …})`、`MiButtonVariant`、`MiButtonMetrics` | 主 / 次 / 危险形态；按压换填充 |
| 动作条目 | `MiActionEntry({icon, label, onTap, highlighted, …})`、`MiActionEntryRow`、`MiActionEntryMetrics` | 图标在上文字在下的底部菜单格；`Row` 版本等分横排 |

### 输入 `inputs/`

| 模块 | 关键接口 | 用途 |
|---|---|---|
| 搜索栏 | `MiSearchBar({hint, onTap, editable, controller, frosted, …})`、`MiSearchBarMetrics` | 静态展示态与输入态；磨砂可选 |
| 搜索取消钮 | `MiSearchCancelButton({fade, onTap, …})`、`MiSearchCancelMetrics` | `fade` 0→1 淡入（alpha 乘进填充与叉号，不套 `Opacity`） |
| 开关 | `MiSwitch({value, onChanged, themeMode})`、`MiSwitchMetrics`、`MiSwitch.knobKey` | 点按 / 拖拽切换；钮体按压放大 1.127；RTL 镜像 |
| 复选框 | `MiCheckbox({value, onChanged, themeMode})`、`MiCheckboxMetrics`、`MiCheckbox.painterKey` | 三态（`true` / `false` / `null` 半选）；勾号按路径 trim 划出 |
| 滑条 | `MiSlider({value, onChanged, divisions, …})`、`MiSliderMetrics` | 坐标换算取值（不用 delta 累加）；键盘 ←/→ 走一格 |

### 行与卡片 `lists/` `cards/`

| 模块 | 关键接口 | 用途 |
|---|---|---|
| 设置组 | `MiSettingsCard({children})`、`MiSettingsRow({label, subtitle, value, leading, trailing, chevron, onTap})`、`MiSettingsTile({icon, color})`、`MiSettingsMetrics` | 设置页分组卡片 + 整行满铺按压高亮带 |
| 偏好行 | `MiPreferenceTile({title, subtitle, leading, trailing, onTap, showDivider})`、`MiPreferenceTileMetrics` | 与弹框列表行同族的通用行（无 chevron、可选分隔线） |
| 主题卡片 | `MiThemeCard({preview, title, …})`、`MiThemeCardMetrics` | 259:472 竖版预览卡；桌面换横版 16:10 |

### 效果 `effects/`

| 模块 | 关键接口 | 用途 |
|---|---|---|
| 渐进模糊 | `MiGradientBlur({child, profile, sigmaScale, frosted, …})` | 顶部渐进磨砂：σ 沿纵向衰减到 0，分档拼若干 `ClipRect` + 单次 filter |

## 5. 浮层（`src/overlays/`）

| 模块 | 关键接口 | 用途 |
|---|---|---|
| 单点渲染层 | `MiPopupHost({child})`、`MiPopup({show, builder, modal, tag})`、`MiPopupRegistry`（`entries` / `add` / `remove` / `removeByTag`）、`MiPopupScope`、`MiPopupHandle` | 页面里的浮层统一注册到宿主按序渲染；无宿主时就地渲染。注册表通知合并到帧末 |
| 弹框 | `MiDialog({title, message, actions, items, layout, position, messageAlign, onScrimTap})`、`MiDialogAction`（`style: MiDialogActionStyle`）、`MiDialogItem`、`MiDialogPosition`、`MiDialogLayout`、`MiDialogMetrics` / `MiDialogListMetrics` | 按钮形态 / 纵向操作列表形态；三档位置 |
| 命令式弹框 | `showMiDialog(context, dialog: …)` → `Future<int?>` | `await` 拿被点按钮 / 列表项下标（遮罩 / 返回 = null）；挂根导航器、零转场 |
| 锚定菜单 | `MiMenu({groups, child, controller, onSelected, onDismissed, themeMode, maxHeight, enableScrim, collapseOnSelect})`、`MiMenuItem({label, subtitle, leading, enabled, selected, children, value})`、`MiMenuGroup(items, {enabled})`、`MiMenuSelection`、`MiMenuController`、`MiMenuArrow`、`MiMenuMetrics` / `MiMenuPalette` | 贴触发件弹出：单选勾号 / 级联二级 / 多分组禁用；右缘对齐 + 空间不足翻转夹紧；经 `MiPopup` 入宿主 |
| 底部弹窗 | `MiBottomSheet({show, child, title, leading, trailing, onDismissRequest, onDismissed, enableDragDismiss, enableScrim, showHandle, cornerRadius, maxWidth})`、`MiBottomSheetMetrics` | 弹簧滑入、手柄下拉跟手、只圆上两角 |
| 弹出面板 | `MiPullUpPanel({child, height, maxHeight, anchorPoint, collapsedSize, controller, onDismissed})`、`MiPullUpPanelController`、`MiPullUpPanelMetrics` | 从触发行弹起的面板（展开欠阻尼 / 收回临界阻尼） |
| 轻提示 | `MiSnackbar.show(context, {message, actionLabel, onAction, duration, themeMode})`、`MiSnackbarController`、`MiSnackbarMetrics` | 底部轻提示，需要 `MiPopupHost` |
| 悬浮工具栏 | `MiFloatingToolbar({child, color, cornerRadius, padding, showShadow, showDivider})`、`MiFloatingToolbarMetrics` | 胶囊托盘容器；投影按形状绘制 |

> `MiPullUpPanel` 由 `controller` 驱动而非 `show`：它的绘制位契约要求贴着
> 触发按钮弹起，因此**不入**单点渲染层。

## 6. 图标（`src/icons/`）

`nav_icons.dart` 提供 9 个 `CustomPainter`（`RollerIconPainter` /
`GridSparkleIconPainter` / `CardsStarIconPainter` / `GridDotsIconPainter` /
`SmileyBeretIconPainter` / `BackChevronIconPainter` / `ForwardChevronIconPainter` /
`PlusIconPainter` / `MoreVerticalIconPainter`），按度量路径绘制（非字体图标），
保证任意 DPR 与字体环境下形状一致。

## 7. 示例层（`lib/demo/`）

不参与库导出，仅作演示与测试载体：

| 模块 | 关键接口 | 用途 |
|---|---|---|
| 演示外壳 | `DemoApp` / `DemoHome` / `DemoStage` / `DemoStageSize` / `DemoShellScope`（`demo/demo_app.dart`） | 明暗切换、设备语境（PC 套壳 / 移动铺满）、导航形态切换 |
| 页面入口 | `MockPage(index, {themeMode, onThemeModeChanged, onSearchActiveChanged, onShowDialog, onShowListDialog})` | 三个 tab 页的路由入口 |
| 搜索页 | `DemoSearchPage({…})`、`MiSearchShortcuts` | 推入式搜索页与首页头部快捷入口 |
| 页面零件 | `pages/profile_page.dart` / `home_page.dart` / `showcase_page.dart` / `search_page.dart` | 按页面拆分的 `part`，共享 `mock_pages.dart` 的 library 作用域 |
