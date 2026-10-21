# Changelog

本项目所有重要变更均记录于此。

格式参考 [Keep a Changelog](https://keepachangelog.com/)，版本号遵循 [Semantic Versioning](https://semver.org/)。

## [Unreleased]

### Added

- **`MiDialog`**：明暗双模式弹框 —— 遮罩 + 卡片一体的全屏浮层，三档位置（顶部 / 底部 / 居中，
  默认底部），按钮中性 / 主 / 破坏性三形态，正文行数自适应卡片高度；按钮按压态填充叠色
  （亮压暗 / 暗提亮，150ms 过渡）；示例「我的」页加三档演示入口
- **搜索态**：`MiTopBar` 新增 `searchActive` / `onSearchCancel` 等入参 —— 置 `true` 后内置搜索栏换成真
  `TextField`、右侧淡入取消钮（`MiSearchCancelButton`，⌀44.1）、胶囊行淡出并退出排版。转场 480ms
  （前 10% 静止 + `easeOutQuint`），取消钮淡入与位移**不同步**、落在中段
- **输入态搜索栏**：`MiSearchBar` 新增 `editable` / `controller` / `focusNode` / `autofocus` /
  `onChanged` / `onSubmitted` / `textInputAction`，几何与配色完全复用
- **`MiTopBar`**：大标题折叠顶栏 —— 大标题**属于滚动内容**（1:1 上移）叠加独立淡出、紧凑标题随后淡入；
  标题墨心用 `Baseline` 在布局期钉死，跨字体不漂
- **`MiTopBar` 头部区**：`searchHint` / `tabs` 声明式入参，搜索栏与胶囊行由顶栏**自己产出**（页面只给数据）；
  保留同名插槽作换皮出口，互斥关系走构造期断言；`occupiedHeight()` 供内容让位
- **`MiGradientBlur`**：把「内容顶部渐进模糊」抽成独立组件，不再依赖顶栏 —— 没有任何顶栏的页面也能挂
- **`MiButton`** 胶囊按钮（filled / tonal / 禁用三态）、**`MiThemeCard`** 主题卡
- **响应式能力**：`src/utils/responsive.dart`（窗口断点、`MiScaledCanvas` 等比画布、`MiResponsiveGrid`
  按容器宽切列），示例外壳 `DemoStage` 分手机 / 平板 / 桌面三档
- **颜色 token**：新增 `MiColors.accent`、`MiColors.pageBackground{Light,Dark}`

### Fixed

- **搜索态收起浮动底栏；键盘不再压缩画面** —— 底栏走**换结构**而非 `Opacity` 淡出（淡出会让
  backdrop 变空），`Scaffold` 设 `resizeToAvoidBottomInset: false` 让键盘覆盖而非挤压画布
- **搜索态转场一上来就跳到终态**：控制器改在 `initState` 创建（`late final` 初始化器会晚到
  `didUpdateWidget`）；示例 `Stack` 增删子级补 `ValueKey`（否则兄弟按下标配对、状态被重建）
- **真机多出一条手势横条**：示例不再自绘 Home 指示条（交给系统），底栏浮起量改
  `max(24.2, safeBottom)`、不再叠加安全区
- **压在内容上的搜索栏 / 未选胶囊补玻璃膜**（`overContent`）：此前只留 6% 表面色，压在横幅上读不出形状
- **玻璃膜改为「垫在低调填充之下」的叠加**（`veiledFill`）：平底页观感不变，静止态与滚动态不再靠开关
  二选一，分类页也能开启
- **头部区磨砂改回「一整段恒定 σ、栏底硬切」**（`uniformBlurBands`）：上一版误把无顶栏页的渐进曲线
  套到头部区，胶囊行处模糊明显偏轻

### Performance

- 深色顶栏跳过被**不透明压色**盖住的模糊段（`visibleBlurBands`），亮色一段不省
- 胶囊行 4 个 `BackdropFilter` 合并成 1 个（`ClipPath` 一次裁完，相邻胶囊仍不串色）
- `ImageFilter` 按 σ 缓存复用（`utils/filter_cache.dart`），并跳过 σ < 0.5dp 的段
- 切 tab 去掉淡入淡出：`Opacity` 会给含 `BackdropFilter` 的子树加 saveLayer，换页期间磨砂反而消失
- 层数与覆盖面积钉成预算（`test/perf_budget_test.dart`），防止后续改动悄悄涨回去

### Changed

- **透明参数统一到 `MiTransparencyTokens`**：各 palette 只引用常量 + 自己的几何，语义不再抄两遍；
  逐字节不变、零黄金图更新
- **磨砂的「渐变遮罩」改为「分段定 σ 阶梯」**：`ShaderMask` / `Opacity` 的半透明遮罩会让 backdrop
  变空（模糊整段消失），Flutter 又没有位置相关模糊，只能分段并列近似曲线
- **平板 / 桌面铺满窗口**（去掉外围圆角卡片与宽度上限），并改 edge-to-edge 透明状态栏；浮层随之自己让
  安全区，窗口断点与导航形态解耦
- **顶栏材质拆成两个独立开关**：`showBlur`（内容区顶部磨砂）与 `showSurface`（顶栏压色），
  分类页即「糊但无压色」；浅色压色改为实测曲线
- **分类页头部区改由 `MiTopBar` 内部产出**，页面手写的吸顶 `Column` 与高度常量删除，渲染结果不变
- **推翻两条早期结论**：「顶栏是纯色遮罩、无模糊」（判据取自模糊带外的平坦色块）与「头部区恒定 σ
  一直糊到栏底」（真实成因是内容区自己的渐进曲线）；真机「上半段纯黑」的元凶是叠色不是模糊
- 示例页细节对齐：首页左右页边距 20 → 11.9dp、组件展示页胶囊改名（Logo 展示 / 按钮展示）

---

## [1.0.0] - 2026-10-16

小米风格可扩展 UI 组件框架（Flutter）首个正式版本。以像素级实测还原小米系视觉与动效，沉淀为分层清晰、可持续扩充的组件库。

### Added

- **MiGlassNavBar** 玻璃悬浮底部导航栏
  - 1:1 复刻参考视频的果冻胶囊切换动效（按压挤压 + 拖拽切换 + 弹簧收尾）
  - 高亮胶囊与栏体外缘等距（端部圆头同心）
- **MiPillTabBar** 胶囊分类标签行组件 + 分类组件展示页（标签行吸顶，滚动内容从半透明磨砂胶囊后方经过）
- **MiGlassNavFab** 预留空位圆形按钮
- **深/浅双模式** `MiThemeMode` + `MiGlassPalette`，demo「我的」页可切换
- **亮色模式** 对齐参考样式：白玻璃栏体 + 灰胶囊 + 近白底色 + 明暗双绿 FAB
- **导航栏 logo 合集** `nav_icons.dart`（含新增加号 logo）
- **MiTransparencyTokens** 统一透明 / 磨砂配置，胶囊半透明磨砂同源取值
- **框架骨架**：分层架构（导出层 / 组件层 / 主题层 / 图标 / 工具 / 示例）、barrel 唯一对外 API、命名与扩充约定
- **MiGlassSideNavBar** 桌面 / 平板侧边导航栏（容器宽 > 600 替代底部栏，
  与底部栏同语义 / 同配方，轴换纵向；含预留空位绿色圆钮）
- **演示 app** 与黄金图回归测试（`test/preview_capture_test.dart`）

### Changed

- 重构为可扩展 `mi_like_ui` 框架骨架（之前为单文件 demo）
- 拖拽果冻拉伸改为平滑衰减，消除慢拖停顿时的宽度跳动
- `README` 重写为完整框架指南（架构、约定、扩充流程、路线图）
- 亮色胶囊移除虚构白描边，对齐实测真值
- 脚手架：`flutter create` 平台工程 + Gradle wrapper 改用腾讯镜像

### Fixed

- 侧栏**内外圈间距四周等距**：栏体圆角改「内圈胶囊圆角 + 内边距」（31.25），
  端头圆弧与胶囊同心 —— 旧 stadium 圆角与内圈不同心，肩部间距从 6.6 收缩到 0
- 圆钮收起后**不再吞掉该区域点击**：`IgnorePointer` 移到 `GestureDetector`
  外层（`GestureDetector` 自身 opaque，包在里层时收起仍命中；底部栏同款
  隐患一并修复）
- 导航图标在每个 tab 居中对齐（修复 roller +3dp 偏移）
- `const` 构造断言不支持 `.length` 求值，数量 / FAB 适配校验移至 `initState`
- 预览图遗漏：`demo_light` 重新生成并补入 `.gitignore`（`test/failures`）

---

## 路线图

- [x] `MiGlassNavBar` — 玻璃悬浮底部导航栏
- [x] `MiPillTabBar` — 胶囊分类标签行
- [x] `MiButton` — 按钮
- [x] `MiSearchBar` — 搜索栏（与导航栏共用透明磨砂参数）
- [x] `MiTopBar` — 顶部导航栏（大标题折叠 / 头部区 / 材质）
- [ ] `MiDialog` — 弹窗
- [ ] `MiForm` — 表单
- [ ] `MiTheme` — 主题聚合
