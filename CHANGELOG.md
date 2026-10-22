# Changelog

本项目所有重要变更均记录于此。

格式参考 [Keep a Changelog](https://keepachangelog.com/)，版本号遵循 [Semantic Versioning](https://semver.org/)。

## [Unreleased]

### Added

- **`MiCardPageRoute` 页面推入转场**：新页自右缘滑入（400ms `easeOutCubic`）、前缘
  61.2dp 圆角，下层页左移 0.25 × 页宽并随进度压暗至黑 @0.55；归位后不保留变换层
  与遮罩。压暗以纯色填充实现，避免 `Opacity` 的 saveLayer 破坏下层 backdrop
- **`MiDialog` 弹框**：遮罩 + 卡片一体的模态浮层。支持顶部 / 底部 / 居中三档位置
  （默认底部）、中性 / 主 / 破坏性三种按钮形态、按压动效（填充叠色 150ms 过渡），
  卡片高度随正文行数自适应
- **搜索态**：`MiTopBar` 新增 `searchActive` / `onSearchCancel` —— 搜索栏切换为输入态、
  右侧淡入取消钮（`MiSearchCancelButton`）、胶囊标签行淡出并退出排版；转场 480ms
- **`MiSearchBar` 输入态**：新增 `editable` / `controller` / `focusNode` / `autofocus` /
  `onChanged` / `onSubmitted` / `textInputAction`
- **`MiTopBar` 顶部导航栏**：大标题折叠（随滚动位移并淡出、紧凑标题衔接淡入）；
  头部区内嵌（`searchHint` / `tabs` 数据参数，或 `searchBar` / `tabBar` / `header`
  插槽自定义）；材质开关 `showBlur` / `showSurface`；`occupiedHeight()` 供滚动内容让位
- **`MiGradientBlur`**：内容顶部渐进模糊，可独立于顶栏使用
- **`MiButton`** 胶囊按钮（主 / 次级 / 禁用三态）、**`MiThemeCard`** 主题卡片
- **响应式工具**：`MiBreakpoints` / `MiViewport` / `MiScaledCanvas` / `MiResponsiveGrid`
  （断点判定、等比缩放画布、按容器宽切列）
- **颜色令牌**：`MiColors.accent`、`MiColors.pageBackground{Light,Dark}`

### Changed

- 透明 / 磨砂参数统一至 `MiTransparencyTokens` 单一来源，各组件令牌仅引用常量；
  渲染结果逐字节不变
- 顶部磨砂改为分段定 σ 实现（半透明遮罩会破坏 `BackdropFilter` 的 backdrop）
- 顶栏材质拆分为两个独立开关：`showBlur`（顶部磨砂）与 `showSurface`（顶部压色）
- 平板 / 桌面布局改为铺满窗口（edge-to-edge），浮层组件自行避让安全区；
  窗口断点与导航形态解耦
- 头部区（搜索栏 / 标签行）改由 `MiTopBar` 内部产出，页面只传数据
- 搜索入口支持两条路径：整页推入（`MiCardPageRoute`，搜索页落定后头部为
  返回圆钮 + 输入框 + 搜索钮）与原地输入态（`MiTopBar.searchActive`）；示例首页用前者、
  「分类」页保留后者

### Fixed

- 搜索态下浮动底栏正确收起；键盘弹出不再压缩画面
- 搜索态转场起始状态正确；示例 `Stack` 子级增删补充 `ValueKey`（防止兄弟节点状态重建）
- 底部浮层不再重复叠加安全区；示例不自绘 Home 指示条
- 压在内容上的零件（`overContent`）补玻璃膜预合成（`veiledFill`），静止与滚动态观感一致
- 头部区磨砂恢复为恒定 σ、栏底硬切的规格

### Performance

- 深色顶栏跳过被不透明压色完全覆盖的模糊段
- 胶囊行多枚 `BackdropFilter` 合并为单次裁切 + 单次模糊（相邻胶囊不串色）
- `ImageFilter` 按 σ 缓存复用，跳过亚像素模糊段
- 页面切换移除淡入淡出（saveLayer 会破坏下层 backdrop，且额外增加全宽高斯）
- 模糊层数与覆盖面积固化为性能预算（`test/perf_budget_test.dart`），防止回退

---

## [1.0.0] - 2026-10-16

首个正式版本：小米风格（HyperOS 设计语言）Flutter UI 组件框架，像素级设计规格、
明暗双模式、分层架构、可持续扩充。

### Added

- **`MiGlassNavBar`** 玻璃悬浮底部导航栏
  - 果冻胶囊切换动效（按压挤压、拖拽跟随、弹簧沉降）
  - 高亮胶囊与栏体外缘等距（端部圆头同心）
- **`MiGlassSideNavBar`** 侧边导航栏（宽屏 / 桌面形态，与底部栏同语义同配方）
- **`MiPillTabBar`** 胶囊分类标签行
- **`MiGlassNavFab`** 浮动圆钮（可挂载于底部 / 侧边导航栏）
- **`MiThemeMode`** 明暗双模式与 `MiGlassPalette` 玻璃配方
- **`MiTransparencyTokens`** 透明 / 磨砂参数统一配置
- **导航图标合集** `nav_icons.dart`
- **框架骨架**：分层架构（导出 / 组件 / 主题 / 图标 / 工具 / 示例）、barrel 唯一对外 API、
  命名与扩充约定
- **演示应用** 与视觉回归测试

### Changed

- 重构为可扩展组件库（此前为单文件演示）
- 拖拽果冻拉伸改为平滑衰减，消除慢拖停顿时的宽度跳动
- 亮色胶囊去除白描边，对齐设计规格

### Fixed

- 侧栏内外圈间距四周等距（栏体圆角 = 胶囊圆角 + 内边距，端头圆弧同心）
- 圆钮收起后不再拦截该区域点击（`IgnorePointer` 移至 `GestureDetector` 外层，
  底部栏同款问题一并修复）
- 导航图标在各 tab 内居中对齐
- 数量 / FAB 适配校验移至 `initState`（const 断言不支持 `.length` 求值）
