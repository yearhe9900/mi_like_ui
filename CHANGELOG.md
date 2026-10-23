# Changelog

本项目所有重要变更均记录于此。

格式参考 [Keep a Changelog](https://keepachangelog.com/)，版本号遵循 [Semantic Versioning](https://semver.org/)。

## [Unreleased]

### Added

- **宽屏布局基础件**（2026-10-23，反馈「移动端尚可，桌面端和平板表现一般」）
  - **`MiContentColumn` + `MiBreakpoints.contentMaxWidth`（1120dp）**：把内容限制在
    列宽内并水平居中、纵向撑满。所有度量都取自 393dp 手机宽，宽屏直接沿用会让卡片与
    列表行等比拉伸（1366dp 时单张卡 500dp 宽、设置行 1200dp 长）。1120 是**推导值**：
    桌面阅读列常见上限 1000…1200、能放下 5 张 200dp 卡（与手机 3 列同密度）、小于
    常见 13" 笔记本逻辑宽
  - **`MiResponsiveGrid.maxCellWidth` / `maxColumns` + `MiBreakpoints.columnsForMaxCell`**：
    列数取「断点台阶」与「单元宽上限算出的列数」较大者 —— 宽屏只加列、不把卡片拉宽
    （`ceil((w+gap)/(maxCell+gap))`，单元宽恒 ≤ 上限）
  - **`MiThemeCard.previewAspectRatio`**：预览区比例可覆盖（默认仍是度量 259:472），
    宽屏换横版（示例 16:10）
  - **`MiHoverFeedback` + `MiTransparencyTokens.hoverOverlayFor`**：指针悬停叠色与手型
    光标。叠色 = 按压高光的 60%（白/黑 @5.6%，**推导值**，触屏素材里没有悬停样张）；
    已接入主题卡 / 胶囊标签 / 按钮 / 搜索栏（可点形态）/ 底部与侧边导航条目，禁用态
    不给悬停暗示。实现上用**实色 `AnimatedContainer`**：`Opacity` / `FadeTransition`
    会引入 saveLayer、让下层磨砂的 backdrop 变空；未悬停时全透明 → 结构恒定、零像素变化
  - **`MiDimens.spaceXxxl`（32dp）**：宽屏页边距（推导值）

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

- **示例的宽屏配方：页边距 32、区块响应式、横版主题卡、内容列上限、可见滚动条**（2026-10-23）
  - 页边距：非 compact 档 24 → **32**
  - 首页区块：`_homeSections` 从 const 两列 `Row` 改成按断点排布 —— 双卡宽幅（创意大赛 /
    更多）恒 2 列、卡面比例 1.15 → 1.9 → 2.45；四卡区（热门 IP / 经典表盘）换成 2/4/4 列
    网格；通栏卡 4.1:1 → 8:1。**手机档数值不变**（172×150、两列，与素材一致）
  - `_GradientCard` 从固定高改成 `aspect`（宽高比）：宽屏钉死 150 高时，516dp 宽的卡
    就是 3.4:1 的横条
  - 主题卡网格：单元宽上限 240（平板竖屏停在 3 列 = 3+3，不出现 4+2 缺角）、桌面 6 列
    横版 16:10 —— 1366×768 一屏从 1.4 行提到 2 行以上
  - 「我的」页内容列上限 720（表单行再宽就是「标签在左、开关贴屏边」）
  - 三页滚动条：非 compact 档 `Scrollbar(thumbVisibility: true)`
  - 外壳：页面恒套 `MiContentColumn`（不按断点增删，避免重建丢滚动位置）
  - 性能：内容列上限截断了「磨砂面积随窗口线性增长」，桌面 1366 每帧模糊面积
    211,132 → **191,615 dp²**（`perf_budget_test` 预算收紧到 196,000）

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
  - 高亮胶囊与栏体外缘等距（端部圆头同心）- **`MiGlassSideNavBar`** 侧边导航栏（宽屏 / 桌面形态，与底部栏同语义同配方）
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
