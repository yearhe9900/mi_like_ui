# Changelog

本项目所有重要变更均记录于此。

格式参考 [Keep a Changelog](https://keepachangelog.com/)，版本号遵循 [Semantic Versioning](https://semver.org/)。

## [Unreleased]

### Added

- **弹出面板 `MiPullUpPanel`**（首页右下「更多」圆钮的唤起形态，2026-10-26，
  参考 HyperOS 拨号键盘唤起录屏逐帧度量；不实现拨号键盘，面板高度与内容
  完全自定义）
  - **几何（度量）**：宽 = 屏宽 − 2×24dp（左右 24.2/23.8 取均）、圆角 33.0
    （五点圆拟合残差 <0.3dp）、底距屏底 90.0（底缘实测 y=766dp）、表面
    #2C2C2C 不透明（亮 #FFFFFF 推导）；**无压暗遮罩**（面板外页底像素不变，
    仍留一层透明命中层交宿主收起）、无投影
  - **唤起动效（逐帧拟合，残差 ≤11dp）**：从触发按钮**等比放大**到终态；
    弹簧 stiffness 260 / damping 26 / mass 1（ζ=0.807，由素材拟合：~0.53s
    收口、~0.33s 峰值、1.3% 过冲）；缩放原点为**移动原点** —— 横向 t∈[0,0.2]
    从按钮圆心靠到「终态右缘 − 20.9」（素材全帧恒定 ±1dp），纵向随进度
    lerp 到「屏底 − 2×90」（首版「绕按钮中心等比放大」中段低 ~34dp，
    不是素材里「向上长」的观感）；`AnimationController` 上界 1.2 防过冲钳平
  - **收回动效（拟合）**：同一原点路径的**反向弹簧**（临界阻尼 530/46，
    ~0.19s 缩回按钮、无回摆）+ **随进度线性淡出**（素材实测：进度 0.72 时
    面板亮度 43/44）；收口后回调 `onDismissed` 由宿主移除；新增
    `MiPullUpPanelController` 供编程收起（圆钮二次点按 = 收回）
  - **震动反馈**：demo 圆钮点按接 `HapticFeedback.lightImpact()`（素材按键
    有触感；档位为推导）；面板不代发触感（触发按钮属调用方）
  - **自定义长高与内容**：`height` 定值（超高钳到屏内可用高）或 null 内容
    自适应；内容在**终态尺寸**下排版、随面板一起缩放（唤起过程不重排版）；
    锚点传触发按钮圆心（全局坐标），默认取素材按钮位（推导）；宽屏档限宽
    440（推导，沿用弹框宽屏口径）
  - demo 首页右下九宫格圆钮接入：点按唤起「快捷操作」面板（240dp 自定义高）、
    面板展开时圆钮同步变深（度量 #131313）、切走 tab 自动收起；新增
    `pull_up_panel_test` 8 项；README 补节与预览图 `panel_dark/light.png`

- **弹框纵向操作列表形态**（`MiDialogLayout.list` + `MiDialogItem`，2026-10-23，
  issue #1「MiDialog 缺纵向操作列表形态」）
  - 下游 MReader「长按图书 → 操作面板」换用 `MiDialog` 后只能压成 3 枚横排
    等宽按钮，图标与副标题全部丢失。现新增第二种形态
    `layout: MiDialogLayout.list`：
    - 每项 = 可选前导图标（22dp，颜色走 `IconTheme` 随行墨色 / 危险色）+
      主文案 + 可选副标题；项间 1dp 分隔线（左右内缩 20）、危险项**整行**
      红字（复用度量红 `destructiveActionLabel`）；标题左对齐最多两行（首行
      墨心仍是度量 36.4，行距 23.0 推导）；可与 `actions` 同用（按钮行恒钉
      卡底），`onPressed` null 不可点且无按压反馈（同按钮契约）
    - 几何**全部为推导值**（`MiDialogListMetrics`，类注释有取值口径）：行高
      47.2（无副标题）/ 68.2（有副标题）= 2×12 + 主行距 23.2（+ 间隙 3 +
      副行距 18）；墨心/基线换算沿用弹框口径（0.355em）；列表顶 = 上一块
      末行墨心 + 18（合成墨心间距 41.6，与「标题 36.4 → 正文 75.55」的 39.2
      同节奏）；分隔线 onSurface @0.08（`dialogDividerAlpha`）
  - **卡片高度上限**（两种形态通用）：卡高**先算后摆**，超出屏内可用高
    （屏高 − 上下让位，下限 `MiDialogMetrics.minCardHeight` 120 推导值）时
    clamp 到可用高 —— 此前 `cardHeightFor(lines)` 随行数线性增长、位置不
    clamp，超长正文会顶出屏幕；现在正文区 / 列表区转内部滚动，标题与按钮
    行保持可见。**静止态既有度量（369.2 / 49.3 / 49.9 / 133.0 …）逐像素
    不变**：`dialog_test` 15 项原样通过，新增 `dialog_list_test` 10 项
  - demo「我的」页新增「操作列表弹框（纵向）」入口（两行标题 + 三项 + 取消）；
    README 弹框节补用法与预览图 `dialog_list_dark/light.png`

- **宽屏第二批：展开侧栏 / 顶栏收敛 / 键盘 / 桌面弹窗与转场 / 悬停操作条**
  （2026-10-23，反馈「全做」——补齐桌面档的形态、交互与动效）
  - **展开态侧边导航栏**（`MiGlassSideNavBar.expanded` + `MiGlassSideNavMetrics`
    展开档）：桌面档（容器宽 ≥ 1024，`MiBreakpoints.usesExpandedRail`）换 176dp
    **带文字标签**的常驻侧栏 —— 图标在左、标签在右、整条目一个胶囊。176 是
    **推导值**，按标签实际字号 10.5dp 反推（2×内缩 18 + 图标 24 + 间距 12 +
    标签 + 2×内边距 6.6；2 字 106 / 6 字 148 / 8 字 169，取 176 留一档余量）；
    纵向节奏（条目高 / 间隙 / 飞行-沉降-按压动效）与窄栏逐帧同源。平板竖屏仍
    走窄栏（展开栏 + 留白占 768 宽的 26%）。
    > 首版 240 是错的：推导时把标签当成 13.85dp（那是胶囊标签 `pillLabel`）
    > 又翻倍留量，实际用 10.5dp —— 「首页」这类 2 字标签的选中胶囊 70% 是空白
    > （用户反馈「太宽了」后按真实字号重推）
  - **顶栏收敛**（`MiTopBar` 三个宽屏参数，手机档传默认值逐像素不变）：
    `headerTopInset`（桌面 24 —— 推导值，窗口没有状态栏，留 56 会悬出空带）、
    `searchBarMaxWidth`（桌面 520 —— 1120 列上一条满宽搜索框难用且不像桌面应用）、
    `actions`（右侧动作区，随搜索转场淡出并退出排版，同胶囊行契约）
  - **键盘支持**：
    - `MiSearchShortcuts`（示例层）—— ⌘/Ctrl + K 聚焦搜索、Esc 退出；包装层
      **结构恒定**、只有 `autofocus` 随断点切（跨断点增删这层会让页面 Element
      重建、滚动位置归零）
    - `MiFocusRing` —— Tab 聚焦可点元素时在边界外画 2dp 强调描边、Enter/Space
      激活。描边是**实色 `AnimatedContainer`**（未聚焦全透明 → 结构恒定、黄金图
      零变化），不引 saveLayer；已接入 `MiButton`
    - 示例在宽屏动作区放 `⌘K` / `Ctrl K` 提示徽标
  - **桌面弹窗**（`MiDialogMetrics` 宽屏档）：容器宽 ≥ 1024 时卡片**居中限宽
    440**、圆角 16、`position` 只在手机档生效。440 / 16 是**推导值**（正文行长
    ~40 字上限 + 居中卡通行圆角）；正文行数按实际卡宽排版，窄容器不溢出
  - **桌面页面转场**（`MiCardPageRouteMetrics` 宽屏档）：窗口 ≥ 1024 换
    「4dp 抬起 + 同色幕布淡入」220ms、前缘圆角 ≤16。**幕布不用 `Opacity`** ——
    新页含磨砂顶栏，套 saveLayer 会让 backdrop 变空；改在新页之上盖一层页底色
    实色（`ColoredBox`，普通绘制）做 alpha 1→0。下层页不做视差、不压暗
  - **卡片悬停快捷操作**（`MiThemeCard.quickActions` + `MiHoverFeedback.
    onHoverChanged`）：悬停时预览图底部滑出操作条（黑 @45% 底，`cardQuickActionsScrim`
    推导值）。滑入用 `AnimatedSlide`（Transform，**不引 saveLayer**）；静止态
    结构恒定、零像素变化；手机档不传（触屏无悬停语义）
  - **滚动降 σ**（`MiGradientBlur.sigmaScale` / `MiTopBar.sigmaScale`）：滚动中
    磨砂 σ 等比压到 0.6、停下 120ms 恢复度量材质。σ 与高斯成本近似线性、运动
    掩蔽下视觉几乎无差；曲线形状（段位/段高）不变，只改强度，低于阈值的尾段
    照常剔除。两档 σ 各自走 `MiFilterCache` 缓存，来回切不新建 native filter
  - **模糊预算重标**：1366 实测 191,615 → **170,050dp²**（层数仍 2）——
    收窄栏宽（176）与桌面顶栏顶部让位 24（顶栏高 156 → 124）两处一起省了
    ~21k；阈值按实测 +3% 收紧为 175,000。首版注释里的 214,182 是按 156 高
    **估算**的错值（实测分层：1120×124 + 176×177.1），本次一并更正

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
