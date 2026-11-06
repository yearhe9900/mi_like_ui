# Changelog

本项目所有重要变更均记录于此。

格式参考 [Keep a Changelog](https://keepachangelog.com/)，版本号遵循 [Semantic Versioning](https://semver.org/)。

## [Unreleased]

### Changed（demo）

- **「按钮展示」组去掉占位展示位网格**：该组只留按钮本体（形态 / 尺寸陈列 +
  `MiFloatingActionButton` 三态），不再铺一屏渐变占位网格 —— 占位格只为补可滚
  长度，与按钮本体无关，还会把陈列淹没。可滚长度只由「Logo 展示」组的网格
  提供（吸顶磨砂演示仍在该组），按钮组内容本身够滚。

### Added（组件：按钮 / 滑条）

- **`MiButton` 补齐形态与内容插槽**：新增 `text` 形态（无填充 + 强调色标签）、
  `large` 尺寸档（高 40 / 内边距 20 / 标签 15dp，对齐 flutter_miuix
  `MiuixButtonDefaults` 的参考实现值）、`icon` 前置图标（16dp 定尺、间距 6dp）、
  `child` 任意内容与 `minWidth` 最小宽；`enabled` 与 `onPressed` 解耦，临时禁用
  不必丢回调。常规档几何、配色与结构未动。
- **`MiSlider` 从「能拖」补成完整交互**：点按跳到落点并由 `settle` 弹簧收敛
  （宿主不接受则在帧末弹回）、拇指在按下 / 拖拽 / 悬停于拇指上时放大 1.127、
  `keyPoints` / `showKeyPoints` 关键点（越过的点换选中色）、`magnetThreshold`
  磁吸、`reverseDirection` 反向（RTL 下自动再镜像）、`onChangeEnd` 交互结束
  回调、无障碍 `slider` 语义（含整步增 / 减）。拇指改为贴边行程 —— 取值 0 / 1
  时圆心内切轨道两端，不再探出控件。新增 `theme/slider_tokens.dart`
  （`MiSliderPalette`）承接钮体与关键点配色，主色仍取自既有 token。
- **示例层**：「组件展示」新增「滑条」一节（连续 + 关键点 / 分档刻度 / 反向 /
  禁用），「按钮展示」补大号、前置图标、文本形态与最小宽四行。

### Added（组件：浮动操作按钮）

- **`MiFloatingActionButton` —— 通用浮动操作按钮**：60dp 正圆 + 可选投影，
  几何与投影标注为参考实现值（上游 `shadowElevation = 4` → blur 4 / 下偏 2）；
  填充默认取素材度量的预留空位绿，投影色复用 `panelShadow`（不为新件另开
  alpha）。按压换填充（预合成压色，不引 saveLayer），三态反馈走 `MiPressable`，
  投影走 `MiSquircleShadowPainter`（形状投影，不进 `BackdropFilter` 页面的
  预算）。**底栏 / 侧栏的槽位圆钮改由本组件渲染**（`MiGlassNavFab` 退成
  「哪个 tab 显示 / 回调 / 配色」的声明），栏位内显式 `showShadow: false` ——
  黄金图与预览图基线未变，圆钮像素零差异。

### Changed（组件：菜单）

- **菜单行上下内边距全行统一 20dp**：原先首 / 末行 20dp、中间行 12dp 两档
  （照搬参考实现 `firstLastVerticalPadding` / `middleVerticalPadding`），真机上
  整列读作「上疏、中紧、下疏」。统一到更松的一档后行高恒为 55.9dp、相邻行
  中心距处处相等。`MiMenuItemRow` 的 `isFirst` / `isLast` 与
  `MiMenuMetrics.rowEdgePadY` 一并移除（两者只为这两档服务）。

### Added（组件：菜单行）

- **`MiMenuItemRow` —— 菜单行的公开形态**：`MiMenu` 面板里那一行（前导 +
  主 / 副文案 + 行尾装饰）提成独立组件，可直接铺进选项列表 / 对话框行，
  不必搬整套锚定与遮罩；`MiMenu` 内部改由它渲染，行几何与按压语言只剩一处
  定义。行尾装饰按状态推导（勾号 > 回退左箭头 > 级联右箭头），上下内边距全行
  统一（见下条 Changed），装饰不参与行高（issue #6 的口径原样保留）；
  `MiDropdownImpl` 作为与参考实现 `MiuixDropdownImpl` 同位名的别名一并导出。

### Fixed（组件：菜单）

- **`MiMenu` 行距不再被选中勾号撑开**：勾号墨盒 20dp 比正文行盒（`dialogAction`
  15.9dp，`height: 1.0`）高 4.1dp，此前它参与行高计算，选中行比普通行高 4.1dp
  —— 上下两个相邻中心距各 +2dp（真机实测 42 vs 40dp），整列读作「选中项上下
  更松」。行尾装饰槽改为只吃宽度、装饰按行中线居中溢出绘制，行高回到只由文案
  块决定；级联箭头同一处一并收口。

- **`MiMenu` 级联切换对齐参考实现**：返回行照抄父项整行（含副文），两层才能
  按行对齐 —— 原先漏掉副文让整列上移，切换时像「两页文字糊在一起」；滚动体移
  进切换子树，每层各一条滚动轴（原先共用，旧层偏移会带到新层）；两层行数不同
  时面板宽 / 高按同一 200ms 跟随内容过渡（`AnimatedSize`，对应 Compose 原版
  `AnimatedContent` 的 `SizeTransform`；Flutter 移植版直接用 `AnimatedSwitcher`
  所以是瞬跳）。淡换本身不变：200ms、`easeOut` / `easeIn`、0.95→1、顶对齐就地
  换内容。返回行箭头仍为左向 `‹`（「回上一级」语义，未跟随参考复用右向）。

### Added（组件：菜单）

- **`MiMenu` —— 锚定菜单**：贴触发件弹出（右缘对齐、下方优先，放不下翻上方
  并夹紧在宿主内），支持单选勾号 / 级联二级（第二级首行是同名返回行）/ 多分组
  与整组禁用；触发件不被接管 —— `MiMenu` 只量 `child` 的盒子做锚点，点按仍由
  行自己处理（`controller.toggle`），因此设置行可直接兼作入口。面板经
  `MiPopup` 注册到宿主（z 序 = 注册序），点遮罩 / 系统返回收起，收口后才回调
  `onDismissed`。补的是「就地选择」这块缺件：此前同类交互只能走弹框，选一项
  要盖整屏。几何与动效为 `flutter_miuix` 的参考实现值（本库无菜单素材），
  配色不新造色值（见 `MiMenuPalette`）。分类页「组件展示」新增「菜单」一节，
  并附三张预览图（`doc/preview/menu_light|menu_dark|menu_cascade_dark.png`）。

### Changed（动效）

- **搜索转场提速**：原地搜索态进入 220→180ms、退出 150ms 走独立曲线（线性淡出收进前 70%）；整页推入 300→220ms、返回 180ms，宽屏视觉铺满全时程；搜索页返回前先收焦点，让键盘与转场并行收起。原因是进入方向的 `easeOut` 曲线被原样反向播，返回时前半程画面几乎不动，读作「点了没反应、然后突然弹回」。

### Changed（demo）

- **外观模式改三档**：「我的」页的深色开关改为「浅色 / 深色 / **跟随系统**」
  单选菜单（`MiMenu` 偏好行形态）。两档开关表达不了系统级设置里最常用的
  「跟随系统」，而三档塞不进一个尾部开关。偏好与解析后的明暗分离
  （`DemoAppearance.resolve`）：只有「跟随系统」读平台亮度，显式档不受系统
  翻面影响；系统亮暗变化时按档决定是否重建。默认仍是深色（参考素材观感）。

### Changed（结构与文档）

- **分层重整（行为零变化）**：浮层统一到 `src/overlays/`（原 `components/
  feedback` + `components/overlays` + `src/overlay` 三处合并，宿主改名
  `popup_host.dart`）；`src/utils/` 拆为 `src/foundations/`（squircle、三态
  反馈、滤镜缓存、格位数学）与 `src/layout/`（响应式、滚动作用域）；
  `preference_tile` 从 `inputs/` 归位到 `lists/`。
- **消除一处逆向依赖**：`MiPreferenceTileMetrics` 原直接引浮层的
  `MiDialogListMetrics.rowHeight`，行几何上提为 `theme/row_tokens.dart` 的
  `MiRowMetrics`，dialog 侧改为同源转发（API 与数值均不变）。
- **命名统一**：`glass_side_nav_bar/` 三个文件补 `glass_` 前缀；
  `search_cancel_metrics.dart` → `search_cancel_button_metrics.dart`；
  slider / switch / snackbar / preference_tile 的主题解析统一走
  `MiTheme.modeOf`（原先各自手写同一段回落逻辑）。
- **demo 拆分**：`mock_pages.dart` 2919 行按页面拆为 4 个 `part`（profile /
  home / showcase / search），对外符号不变。
- **新增 `test/architecture_test.dart`（8 例）**：分层依赖方向 + barrel 死链
  与覆盖守门；动效 / 透明度字面量扫描范围补上 `lib/src/overlays`（浮层移出
  `components/` 后不再被扫，规则会静默退化）。
- **文档**：新增 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)（分层 / 目录 /
  token 三层 / 命名 / 扩展流程 / 质量门）、[docs/MODULES.md](docs/MODULES.md)
  （六个分层下各模块用途与关键接口）、[docs/USAGE.md](docs/USAGE.md)
  （引入 / 骨架 / 主题浮层响应式配置 / 测试 / 常见坑）；README 增文档索引并
  对齐新结构。

### Changed（组件：开关）

- **`MiSwitch` 补齐上游 flutter_miuix 的交互面**：
  - **水平拖拽切换** —— 钮体跟手（轨道色随行程插值），松手越过行程中点
    即吸附到另一端、未越过则弹回；拖拽被父级手势抢占同样弹回；归位推迟到
    帧末按最新 `widget.value` 决定（宿主同帧接受 → 弹到新端；受控值不变
    → 弹回原端），无需猜；
  - **按压 / 拖拽态钮体放大 1.127**（参考实现值，上游 Kotlin 同档），
    过渡沿用全库按压档 `pressMs` + `pressCurve`，松开回原尺寸 —— 触屏
    点按没有悬停叠色，这一层就是它的按压视觉；
  - **RTL 镜像**：钮体从右端起算、拖拽方向取反；
  - 触感（`HapticFeedback`）仍不代发，与 `MiPullUpPanel` / `MiCheckbox`
    同口径 —— 需要时由调用方在 `onChanged` 里触发。
- **demo**：「我的」页外观模式行、分类页设置行（蓝牙）的尾部开关由
  Material `Switch` 换成本库 `MiSwitch`；组件展示新增「开关」一节
  （开 / 关 / 禁用三态，可点按可拖拽）；禁用行标签区分
  `禁用态（开关）` / `禁用态（复选框）`，热点行值文改为「已连接 /
  未连接」。同步更新 `test/goldens/demo_light_mine.png` 与三张 README
  预览图 —— 像素级比对确认差异仅限该开关矩形内，页面其余部分零漂移。

### Added（组件：复选框）

- **`MiCheckbox` —— 复选框**（三态 / 勾号 trim 动效）：26dp 圆形控件，
  未选走全库「关闭档」墨量（`controlOffFillFor`，与开关轨道同源）、选中
  走强调色，勾号以 `PathMetric` trim 逐段描出（√ 形状三点收拢，半选时
  收成横杠，`alphaMs` / `trimMs` / `indetMs` 三段并行）；三态（按压 /
  悬停 / 焦点）与 Enter / Space 激活收编自 `MiPressable`，按压叠色复用
  `dialogPressedFill`，不缩放；`Semantics` 下发 checked / mixed / enabled，
  禁用降透明至 `MiDimens.disabledOpacity`；9 例几何 / 交互 / 语义 / 键盘
  测试锁定。几何与动效标注为**参考实现值**（本库无素材）。

### Added（浮层：底部弹窗 / 悬浮工具栏）

- **`MiBottomSheet` —— 底部弹窗**：`show` 驱动的声明式贴底抽屉，经
  `MiPopup` 渲染、遮罩按滑入进度淡入（`dialogScrimProgressFor`）；弹簧
  展开（`miSpring(damping: 0.9, response: 0.38)`，约 273ms）按自身高度
  做 `FractionalTranslation` 滑入，不跑布局也不需预先量高；手柄下拉抽屉
  跟手（`dragResistance` 阻尼回弹），超过 `dismissDistance` 或甩速过
  `flingVelocity` 才请求关闭，宿主不接则自动弹回；只圆上两角
  （`MiSquircleBorder(topOnly: true)`，G2 连续曲率）；宽屏 `maxWidth` 640
  居中、底部让开安全区与键盘内缩。
- **`MiFloatingToolbar` —— 悬浮工具栏**：托盘式胶囊容器（`cornerRadius`
  50），内容自定、几何固定（外留白 12/8、投影 `blurRadius` 10 无偏移、
  可选 0.75dp 描边），投影用 `MiSquircleShadowPainter` 按形状绘制（非
  `BoxShadow` 矩形，故圆角处不漏影）；表面吃点击不穿透。
- **`MiPopupRegistry` 通知改推到帧末**：注册 / 注销 / 刷新在 build 期不再
  同步 `notifyListeners`（否则「首帧即挂浮层」会在宿主上触发
  `setState() called during build`），合帧后统一通知。

### Changed（基建）

- `MiSquircle.pathOf` / `addRect` / `MiSquircleClipper` 增加 `topOnly`
  （只圆上两角，弹窗贴底形态用）；`MiSquircleBorder` 增加 `topOnly` 与
  `side`（可选描边，`BorderSide.none` 时不绘制），相等性与
  `shouldReclip` 一并纳入。
- `MiDimens.disabledOpacity`（0.38）上提为全库禁用档，开关 metric 改为
  同源转发，调用点零改动；`MiTransparencyTokens` 新增
  `controlOffFillAlpha` / `controlOffFillFor`（开关轨道与复选框共用的
  「关闭档」墨量）、`dialogScrimProgressFor`（遮罩带进度）、
  `sheetHandleFor`（弹窗手柄，含按压加深档）。

### Changed（demo）

- **「分类」页占位组落地为真实组件陈列**：后两个胶囊分组原为「示例三 /
  示例四」占位（渐变方块 + 「示例组件N」），现四组全部陈列真实组件：
  - **组件展示** —— 搜索栏静态 / 输入两态 + 取消钮 `fade` 淡入（常驻
    排版、alpha 乘进填充与叉号，不套 Opacity）、设置行三种尾部
    （值文 + chevron / 开关 / 副标题）、桌面三态反馈三格
    （`MiPressable` / `MiHoverFeedback` / `MiFocusRing`）、
    `MiResponsiveGrid` 列数断点；
  - **弹层与效果** —— 弹框三位置 + 操作列表（声明式，经外壳在机身壳内
    挂浮层，与「我的」页同一入口）、命令式 `showMiDialog`（`await` 拿
    被点下标 / 点遮罩回 null，挂根导航器）、弹出面板从触发行弹起
    （自定义高 240，点面板外收回）、`MiGradientBlur` 独立用法（高频
    内容 + σ 缩放滑杆演示运动省帧档）；
  - 前两组保留占位展示位（补可滚长度，吸顶磨砂要有内容从后方经过）；
  - 分类页列表底部让开浮动底栏（compact 100 / 宽屏 20）—— 末节内容
    （面板触发行）此前会被玻璃底栏压住；
- **新增 `test/showcase_gallery_test.dart`（9 例）**：两组新内容的可交互
  契约（取消钮 fade 时序、开关、按压计数、弹框入口透传、`showMiDialog`
  下标与遮罩关闭、面板唤起 / 收回、σ 缩放）；胶囊标签改动同步
  `showcase_sticky_test` 与胶囊特写预览图。

### Added（组件：动作条目）

- **`MiActionEntry` / `MiActionEntryRow` —— 纵向动作条目**（issue #5）：
  图标在上、文字在下的底部菜单格（目录 / 夜间 / 设置 / 更多这类等分
  横排），收编 MReader `control_bar.dart` 自拼的 `_MenuEntry`：
  - 几何按度量：22dp 图标 + 3dp 间隙 + `MiTypography.navLabel` 文字
    （10.5dp Medium），行高默认 56（`MiActionEntryMetrics` 注明口径）；
  - 按压 = 整格淡出 0.55（MReader 口径，瞬时）；禁用降透明至全库禁用
    档 ≈38%（引用 `MiTransparencyTokens.disabledLabelAlpha`）不消失；
    高亮态（如「夜间」已开）图标与文字走强调色；
  - 三态（按压 / 悬停 / 焦点）与 Enter / Space 激活收编自 `MiPressable`，
    组件内不手写 `_pressed`；淡出经 IconTheme / DefaultTextStyle 下发，
    不引 saveLayer；
  - `MiActionEntryRow` = 等分横排容器（`Expanded` 每格同宽），宿主也可
    自行 `Row + Expanded` 组合；8 例几何 / 交互 / 主题测试锁定。

### Added（弹层）

- **`showMiDialog` —— 命令式弹框**：`await` 返回被点按钮 / 列表项下标
  （点遮罩 / 系统返回 = null），免去页面手写 Stack 挂浮层 + 显隐状态的
  样板；原 `onPressed` 回调仍执行（先回调后关闭），同一份 `MiDialog`
  配置声明式 / 命令式两用；挂根导航器（`showDialog` 同口径）、零转场
  时长（与声明式出现方式逐帧一致）；5 例测试锁定。

### Added（滚动接线）

- **`MiScrollBinder` —— 滚动位移作用域**：包住滚动体与消费者，顶栏
  折叠位移免逐页手写 `NotificationListener` / `ScrollController` +
  `setState` 样板：
  - `MiTopBar.scrollOffset` 变可空，null（默认）= 从祖先作用域自动
    读取，显式传值压过作用域（滚动降 σ 需集中两个滚动量的页面仍手写）；
  - 只认 depth == 0 且同方向的滚动通知（嵌套滚动体 depth ≥ 1 与横向
    滚动体不驱动竖向折叠），位移经 `ValueNotifier` 等值去重广播；
  - 无作用域且未传参 = 旧默认（未滚动，逐像素不变）；demo 设置页壳
    已迁移（删掉 ValueNotifier + listener 样板），5 例测试锁定。

### Added（无障碍）

- **导航条目 / 胶囊标签补语义选中态**：`MiPillTabBar` /
  `MiGlassNavBar` / `MiGlassSideNavBar` 条目包 `Semantics(button +
  selected + label)`，读屏可感知当前选中项（此前裸 GestureDetector
  在语义树上无选中信息）；
- **`test/a11y_test.dart` 回归锁**：语义选中态 4 例 + 系统大字体
  （TextScaler 1.5× / 2.0× 下胶囊行 / 设置行 / 按钮 / 玻璃栏不抛异常、
  标签可见）4 例 —— 本库 `height: 1.0` + 基线锚定排版此前无大字体验证。

### Added（CI）

- **analyze + 测试进 CI**：push / PR 跑 `flutter analyze` +
  `flutter test`（钉 Flutter 3.47.5，升级时先本机重拍 golden 再改版本）；
  Pages 部署前加测试关（全绿才构建发布物）。预览图生成用例打 `preview`
  tag（依赖 Windows 中文字体）以 `--exclude-tags preview` 排除，
  其余 golden 用默认 Ahem 字体渲染、跨平台确定。

### Added（主题）

- **`MiTheme` —— App 级主题注入点**（一处声明，全库生效）：
  - `MiThemeData` 四个注入维度：`mode`（明暗）/ `accent`（品牌强调色，
    注入点 = 主按钮填充、搜索输入光标、浅色焦点环）/ `pageBackgroundLight|
    Dark`（页底色，注入点含推入转场幕布）；全空 = 库默认度量值；
  - 明暗解析口径收编为两个静态入口：`MiTheme.modeOf`（环境跟随型：显式
    参数 > MiTheme > `Theme` 亮度）与 `MiTheme.modeOfOr`（库默认深色型：
    显式参数 > MiTheme > 原默认 dark）—— 此前 8 处逐站手写的 `_modeOf` /
    内联三元全部收敛；
  - 组件 `themeMode` 参数降级为可空覆盖（null = 跟随 MiTheme）；
    **不包 MiTheme 时全库行为与旧版逐像素一致**（golden 仅 demo 设置行
    迁移导致 3 张重拍）；
  - `MiButtonPalette.of(mode, accent:)` / `MiSearchBarPalette.of(mode,
    accent:)` 品牌色注入；默认强调色仍走 const 配方（identical，零分配）。

### Added（组件）

- **设置行组收编为库组件**（原 demo 私有实现）：`MiSettingsCard` /
  `MiSettingsRow` / `MiSettingsTile` —— 分组卡片（squircle 裁形）+ 行
  （前导图标块 + 主 / 副文案 + 值文 / 尾部 + chevron，整行满铺按压带
  120ms easeOut）；按压状态机 / 悬停 / 焦点三态走 `MiPressable`（行内
  不再手写 `_pressed`），明暗与配色走 `MiTheme` + `MiSettingsPalette`；
  度量与配方在 `MiSettingsMetrics` / `MiSettingsPalette`（当前为推导值，
  升级为度量后原位替换）。demo 设置页已迁移，7 例交互 / 几何测试锁定。
### Added（弹层基建）

- **`MiPopupHost` / `MiPopup` / `MiPopupScope` —— 弹层单点渲染层**：
  - 注册序即 z 序（后开在上，无 zIndex 状态机 —— 本库同时可见浮层 ≤ 2，
    是相对 flutter_miuix 千行四件套的刻意裁剪）；不扰动页面栈（Stack
    中插会让后续子树重建、滚动位置归零）；非模态条目自动包 `IgnorePointer`；
  - `MiDialog` 内部经 `MiPopup` 注册（无宿主就地渲染 —— 既有用法与黄金图
    零变化）；`MiPullUpPanel` 因绘制位契约（导航栏之下）刻意不入；
  - demo 根部挂宿主；示例消息条从 Material `ScaffoldMessenger` 换到本库
    `MiSnackbar`。

### Added（组件：Snackbar / Switch / Slider / PreferenceTile）

- **`MiSnackbar`** —— 贴屏底自动收起消息条（2.5s 常驻、滑入 300 / 滑出
  200ms、可带动作钮、`MiSnackbar.show` 同类替换投放）。几何时序全推导
  （`MiSnackbarMetrics` 注明口径）；配色零新造（表面 = 面板同值、墨色 =
  弹框标题、动作 = 强调色）；
- **`MiSwitch`** —— 52×32 轨道 + ⌀26 白钮，临界阻尼吸附弹簧
  （`miSpring(1.0, 0.35)`，无过冲）；禁用降 0.38 透明（全推导，
  `switch_metrics.dart` 注明口径）；
- **`MiSlider`** —— 受控滑条：拖拽 `globalToLocal` 坐标换算取值（不累加
  delta —— flutter_miuix 同款回归教训）、键盘 ← / → 一格、`divisions`
  分档吸附（全推导）；
- **`MiPreferenceTile`** —— 设置行：行高与弹框列表行同源、按压同 state
  layer、尾随插槽吃 `MiSwitch`（`MiForm` 的行单元）；
- 测试：`snackbar_test` / `switch_test` / `slider_test` /
  `preference_tile_test` + 弹层基建契约用例（非模态不吃下层命中等）。

### Added（可达性）

- 主题卡 / 胶囊行经 `MiPressable` 补 Tab 焦点环与 Enter / Space 激活
  （推导桌面语义，静止态零像素、黄金图零重拍）；`MiSearchBar` **刻意不做**
  Tab 停靠 —— 点击给包装层的焦点被祖先聚合点亮环，与可编辑态 autoFocus
  互相干扰（预览实测），搜索可达性走 ⌘K / 宿主路径。

### Changed（磨砂审计）

- `MiTransparencyTokens.blurSaturation` 预留 token（恒等 1.0）：
  `BackdropFilter` 路线在当前 SDK（3.47）无色控组合入口（无
  `ImageFilter.colorFilter` 工厂），记录接入条件，不硬造实现；
- `MiFilterCache` 文档补两条审计：3σ 采样 margin 对本库不适用
  （`BackdropFilter` 原生采样边界外邻域，快照纹理路线的坑）；缓存 key
  即值（σ 纯函数，无 OS4 材质引用相等式的失效窗口）+ `filter_cache_test`。

### Added（文档）

- `.claude/skills/mi-like-ui/SKILL.md` —— AI 编码助手技能卡：API 速览、
  度量驱动纪律、坑清单（真源仍是 README 与各 `*_metrics.dart` /
  `theme/*_tokens.dart`）。

### Changed（demo）

- **演示外壳按设备语境划分（web 按 user-agent）**：PC 端窄窗（< 600dp）
  套**手机壳**（393×856 设计画布、圆角机身 44 + 外圈底色 + 投影）、宽窗
  （≥ 600dp）套**平板壳**（820×1180 画布横 / 竖择优、圆角机身 32）；
  移动端（移动 UA / 手机平板实机）**铺满全屏**、无圆角无投影 —— 此前
  不分设备一律套壳，手机浏览器里出现「手机套手机」。形态解算下沉为纯
  函数 `DemoStage.modeFor` / `sizeFor(…, mode)`（可单测），
  `DemoApp(device:)` 可显式指定语境。

### Changed（动效 / 性能）

- **搜索转场提速去丢帧**：`MiTopBar.searchTransitionMs` 480 → 220ms、
  `MiCardPageRouteMetrics.durationMs` 400 → 300ms（曲线与起手静止段比例
  不变），两级搜索进入 / 退出的落位都提前约一半。
- **转场期不再逐帧重排 / 离屏合成**：胶囊行与取消钮的淡出改走组件自带的
  `fade`（alpha 乘进颜色，新增公开参数 `MiPillTabBar.fade` /
  `MiSearchCancelButton.fade`），去掉两处 `Opacity` —— 它们给含 backdrop
  磨砂的子树引 saveLayer（磨砂整段消失 + 每帧一次离屏）；顶栏材质盒高在
  转场期钉住不插值（否则磨砂段 `ClipRect` 每帧重定位、整条头部区全宽高斯
  每帧重跑）；推入转场的下层视差从 `LayoutBuilder` 换成
  `FractionalTranslation`（绘制期平移，不再每帧跑布局）。

### Added

- **全库圆角升级为 Squircle 连续圆角**（G2 连续曲率，HyperOS / iOS 标志性
  角形）：
  - 新增 `MiSquircle`（每角三次贝塞尔：瓦片 = 半径×1.1、控制比 0.643；
    思路参考 flutter_miuix `miuix_squircle.dart`（Apache-2.0），按本库
    度量驱动风格重写）+ `MiSquircleClipper` / `MiSquircleBorder` /
    `MiSquircleShadowPainter`（BoxShadow 的 squircle 版）
  - 26 处圆角画点全部迁移：玻璃底栏 / 侧栏（栏体 + 胶囊，painter 挖洞与
    内缘亮边同步换 path）、胶囊标签行（填充 / 磨砂裁形 / 亮边三遍绘制
    共用同一 squircle 栅格）、按钮、搜索栏、主题卡、弹框卡片与按钮、
    弹出面板（投影改 painter 垫底）、推入转场前缘
  - 半径语义不变（metrics 数值照旧，只换画法）；悬停 / 焦点包装层的
    borderRadius 参数保留（5.6% 叠色下角差不可辨，避免 API 破坏）
  - golden 16/17 重拍 + README 预览 47 张重生成，全量 281 测试通过；
    Widget 测试查找器同步迁移（BoxDecoration→ShapeDecoration、
    ClipRRect→ClipPath）

### Added（基础件）

- **`MiPressable` —— 统一反馈包装件**（按压状态机 + 悬停叠色 + 键盘焦点环）：
  - 收编此前散在四处、逐站手写的按压状态机（弹框按钮、弹框列表行、
    顶栏返回钮、搜索取消钮 —— 按下 / 抬起 / 取消 + 禁用门控，逻辑同构），
    两处弹框 widget 与返回钮 / 取消钮随之去 State 化；
  - 内部复用 `MiHoverFeedback`（悬停叠色 + 手型光标）与 `MiFocusRing`
    （2dp 焦点环 + Enter / Space 激活），嵌套顺序与 `MiButton` 迁移前的
    手写三层逐层等价；barrel 新导出；
  - 按压**视觉**留在组件层（`pressBuilder`）：时序与颜色是各组件度量
    （弹框 150ms 填充换压色、返回钮 / 取消钮 420/300ms 圆盘淡入出），
    包装件只提供 `pressed` 状态，取值继续引用 `MiMotionTokens` /
    `MiTransparencyTokens` 与各 `*_metrics.dart`；
  - 零行为变化迁移 + 桌面语义补齐：四处站点迁移时黄金图零重拍；随后按
    「触屏素材无样张 → 通行桌面惯例推导并标注」惯例，为弹框按钮 / 列表行、
    返回钮、取消钮补齐悬停叠色与 Tab 焦点环（静止态零像素，黄金图仍零
    重拍），四处各补一条接线测试；新增 `test/pressable_test.dart`
    （7 项契约测试）。

### Added（动效）

- **issue #2 / #3 / #4 三连：框架 API 补强**（2026-10-28）
  - **#2 宿主自拼头部的生产消费**：barrel 导出 `glass_rim.dart`
    （`MiGlassRimPainter`，下游自适应宽胶囊变体可直用同一支亮边画笔）；
    `MiTopBar.headerBlurBands` 去掉 `@visibleForTesting` **公开化**（有头部区
    形态的权威磨砂曲线，宿主自拼浮动头部与顶栏同源；与仅测试口径的
    `visibleBlurBands` 定位分开）
  - **#3 自适应胶囊宽度档**（`MiPillItemWidth.adaptive`，全推导值）：
    `胶囊宽 = clamp(标签文字自然宽 + 2×textInset(16), min(87.6), max(175.2))`，
    超上限 ellipsis 截断；填充 / 磨砂裁形 / 内缘亮边三遍对齐同一宽序列；
    默认 `fixed` 现有度量行为逐像素不变（golden 锁）；新增
    `pill_adaptive_dark` golden
  - **#4① 胶囊行区膜带**：`overContent` 的玻璃膜改为**行区限定的渐变膜带**
    （同胶囊栅格裁形、上下缘羽化 8dp，行外与间隙不垫，羽化端点
    `veilFeatherFor`）；不再逐胶囊预合成 `veiledFill`，胶囊填充两态同值 ——
    膜管「形状可读」、内缘亮边管「受光边」；首页头部预览随之重生成
  - **#4② 透明顶栏配方档**：`MiTopBarPalette.transparent` / `transparentFor`
    （零叠色渐变 + `scrimOpaqueBottom` 0）+ `MiTopBar.palette` 可选参数；
    配合 `showBlur: false` 与常亮亮边，阅读页顶栏一行切到透明形态

- **动效令牌 `MiMotionTokens`**（统一动效配置，token → 测试 → 文档同步链）：
  - 跨组件动效收归 `theme/motion_tokens.dart` 单一来源：按压反馈
    420/300ms `easeOut`（顶栏返回钮度量、搜索取消钮推导沿用）、按压叠色
    150ms `easeOutQuad`（弹框按压度量）、弹出面板展开 / 收回弹簧
    （素材拟合 260/26 与临界 530/46，拟合档案随迁）；原常量同源转发，
    调用点零改动
  - 换算工具 `miSpring(damping, response)`：Folme 口径
    `stiffness = (2π/response)²`（思路参考 flutter_miuix，Apache-2.0，
    按本库度量驱动风格重写）
  - 实现层裸值消灭：按钮 / 胶囊标签 200ms、主题卡操作条 180ms、底栏 /
    侧栏飞行兜底 300ms 收归各自 metrics（补推导注释）
  - 新增 `test/motion_config_test.dart`：源码扫描禁裸时长 / 弹簧 / 自创
    曲线字面量 + 跨组件同值断言；全量 276 测试通过、golden 零变化

### Fixed

- **胶囊行膜带羽化归零**（2026-10-28，实机反馈「顶部胶囊透明磨砂异常」）：
  issue #4① 的膜带上下缘 8dp 羽化吃掉 40dp 胶囊的上下各 1/3，彩色内容从
  胶囊上下区直接透出（截图实测：文字带 t≈0.42、羽化区更高，配方为 0.32）；
  参考的胶囊膜是**均匀铺满**的（原逐胶囊预合成无羽化，胶囊边缘是 4…6px
  干净压暗阶跃）→ `veilFeatherHeight` 8 → **0**（token 保留供后续开羽化）；
  golden 反验：修复后胶囊全高度均匀、透射回到配方档（b20fe16）

- **横屏/宽屏下侧栏与内容列无分隔**（2026-10-27，实机反馈七轮）：内容列
  的让位此前 = 侧栏列（栏体右缘与内容左缘相贴，间距 0，横幅通栏满铺时
  没有呼吸感）。新增 `MiGlassSideNavMetrics.contentSeparation = 24dp`
  （推导值，与栏体左留白 25.5 同档）与 `contentInsetFor(expanded:)`
  助手（侧栏列 + 分隔，外壳与几何测试同源）；responsive/desktop_nav
  几何断言与预览图同步

- **底栏选中高亮改回高磨砂块**（2026-10-27，实机反馈六轮）：
  - 参考实测（滚动对齐帧多点回归、胶囊全宽无字带 2503–2522）：暗色选中块
    (c,t) ≈ **(84, 0.05)** —— 内容几乎不透出的**磨砂块**；旧实现「遮罩开洞
    + 暗化0.4 + 白@0.118」得到 (30, 0.53) = 透镜窗口，把背后彩色内容直接
    透出来（实机截图正是该观感）
  - 暗色修正：**不再开洞**（`MiGlassPalette.lensCutsScrim = false`）+ 暗化
    0.4 + 白茶色调 0.118 → **0.28**，合成 (c,t) ≈ (78, 0.10) 落在实测邻域；
    golden 反验胶囊上下均匀（t≈0.1，非透镜的明显上下渐变）
  - 亮色实测 (182, 0.20) 与现实现 (179, 0.22) 吻合，**不动**（保留开洞）
  - golden 重生成，全量 267 测试通过（连跑两遍确定）

- **亮边在极快滑动时冻住**（2026-10-27，实机反馈五轮：「快滑不暗、轻碰才变」）：
  σScale 的 0.05 档量化本为抳 filter 缓存，但量化后**只在换档时通知** ——
  极快滑动时 σ 饱和在同一档不再换档，rimProgress（滚动位置派生量）停在旧值；
  轻碰一下又换档才刷新。修正为：σ 值继续量化（缓存命中不变），**通知改回
  逐滚动事件**（顶栏只重建自身子树，滚动内容不重建）；丢帧主因是每帧新建
  native filter，与重建次数无关，量化仍生效

### Changed

- **胶囊端头回归真半圆**（squircle 只修饰有过渡段的部分圆角）：底栏 /
  侧栏选中块 / 胶囊标签行 / 按钮 / 搜索栏等「半径吃满短边」的胶囊形，
  端头由角部贝塞尔拟合（45° 外鼓 ~4.8%）改回正半圆（圆弧）；卡片 /
  弹框 / 面板等部分圆角维持 squircle 不变

- **主题卡预览图圆角 20 → 12.9dp**（实机截图度量修订：3 列 / 2 列双测点
  交叠带 [12.1, 13.3] 取中；旧 20 系早期样张外推，见
  `MiThemeCardMetrics.previewRadius` 注记）

- **底栏遮罩取实测区间实端（0.70 → 0.76）**（2026-10-27，实机反馈四轮「过于透明」）
  - 参考的暗色栏体遮罩实测区间：合成匹配 LS（亮内容纯净条）a = 0.70…0.754、
    均值守恒法 a = 0.70…0.71；上一轮取了区间**下沿**（最透端）。按实机
    观感（参考是「糊而不透」）改取**实端 0.76**（透射 t≈0.24）；σ 维持
    28px 实测谷值不变
  - 渲染管线已验证无损（golden 同行玻璃内外反解出 a=0.70，与 token 一致；
    图标/文字是画在玻璃之上的 UI 像素，测透射时必须避开）

### Changed

- **底栏玻璃定标复归（σ 9.0dp / 深遮罩 0.70）；快速滑动丢帧修复**（2026-10-27，实机反馈三轮）
  - **零件玻璃 σ 5.5 → 9.0dp（≈28px）、深色遮罩 0.48 → 0.70（透射 t≈0.30）**：
    用「纯净条」（图标/文字/高亮之外的区域）重跑滚动对齐帧合成匹配，
    σ 谷值 26px 跨帧组复现（残差 <2.3）、亮暗两模式一致（26…30px）；
    含图标的窗口会把 UI 像素当内容，两轮修偏（10.3 / 5.5）都是过拟合 ——
    真值一直就是 ≈28px，与更早的 0.63 遮罩同档。合成对照面板（σ26/t0.285）
    与真实玻璃像素几乎不可分辨
  - **快速滑动丢帧**：σScale 从布尔/连续值改为 **0.05 档量化** ——
    `MiFilterCache` 以 σ 为键，连续 σScale 让每帧每段都新建 native filter
    （12 层 × 每帧新建 = 丢帧主因），量化后同档命中缓存、且只在换档时
    重建顶栏；叠加**运动合并**：快速运动（scale ≤ 0.8）把 9 段阶梯合并成
    3 段（段高加权 σ，运动掩蔽下不可辨），全宽高斯 9 趟 → 3 趟，停下自动
    恢复完整阶梯；运动中 σ<1dp 的段直接剔除
  - golden / README 预览图重生成，全量 267 测试通过（连跑两遍确定）

### Changed

- **亮边改「内容靠近才亮」；底栏玻璃透射/σ 对齐参考**（2026-10-27，实机
  反馈二轮 + 参考素材触发曲线细采样）
  - **内缘亮边不再是常驻描边**：参考实测是内容接近度触发 —— 同段录屏里
    内容距栏底 20.6dp 时亮边 = 0，靠近到 20.0dp 时已满（1 帧内翻转，玻璃
    同时进入激活态：填充变实）。改为 `rimProgress` 驱动：静止不亮、内容
    向栏靠近的过程中渐亮、进入栏区后保持；顶栏按滚动位移下发
    （`MiTopBarMetrics.rimFadeDistance = 20`，推导映射），零件可独立传
  - **底栏（及搜索栏/胶囊）玻璃 σ 10.3dp → 5.5dp、深色遮罩 0.63 → 0.48**：
    滚动对齐帧**合成模糊匹配**（同一内容先清晰掠过栏上方、再被栏玻璃
    覆盖，逐 σ/透射比重建比对，`.workbuddy/nav_glass_fit.py`）给出
    σ = 12…21px（中位 ≈17px ≈ 5.5dp）、透射比 t≈0.5；边缘宽度法复核
    （10…17px）同档。实机对比：旧参数把栏后内容糊得比参考重一倍、
    也更暗（旧 t≈0.35）；参考里栏后机身轮廓 / 文字仍可辨认
  - 首页 / 分类顶栏补传 `scrollOffset`（亮边进度的驱动源）；golden / README
    预览图重生成，全量 267 测试通过

### Changed

- **实机反馈批：玻璃零件补「自身透明模糊 + 内缘亮边」；滚动降 σ 改实时渐变**
  （2026-10-27，实机演示录屏 1220×2656 反馈 + 参考素材边缘细扫复核）
  - **搜索栏 / 未选胶囊补内缘亮边**（「边缘逐渐变亮」的受光边）：边缘细扫
    实测亮边峰值比玻璃体内部高 +25…38 级、1…1.3dp 内向内回落（外侧仅
    1px 微溢），沿周长均匀；反解白 @0.22（暗）/ @0.40（亮）。新增
    `MiGlassRimPainter`（`utils/glass_rim.dart`）+ `surfaceRimFor` token；
    选中胶囊近实心，实测亮边不可辨 → 不画。旧版边缘是无亮边的硬切，
    实机看像普通色块
  - **搜索栏 / 胶囊 / 取消钮始终自绘自己的玻璃**（backdrop 磨砂 + 亮边）：
    旧版在顶栏画磨砂时把内置零件的 `frosted` 关掉（「整条栏只糊一次」）
    —— 实机反馈：零件没有自己的「透明模糊属性」，像不透明色块。现两层
    叠加：顶栏那层是随 y 衰减的背景磨砂，零件自身那层才是它的玻璃属性
    （素材里胶囊内的内容比缝隙处更糊）
  - **滚动降 σ 改为实时渐变**：旧版是布尔开关（滚动中 0.6、停 120ms 后
    跳回 1.0），停顿瞬间「突然更糊」很扎眼；新版按**滚动速度**逐帧连续
    映射（demo `_ScrollSigma`：帧位移差分 + EMA → 0.6…1.0，惯性收尾平滑
    回升），只重建顶栏子树。速度源用帧时间戳（非墙钟）：golden 回归可复现
  - 性能预算重标：首页 / 分类每帧模糊层数 10 → 12（零件两层），面积阈值
    按实测 +3%；golden / README 预览图重生成，全量 267 测试通过

### Changed

- **头部区磨砂改为实测渐进曲线；玻璃零件 σ 修正为 10.3dp**（2026-10-27，
  两段 1220×2656 原生录屏 —— 亮色 16fbd9f4… / 暗色 5cf0c928…，同页
  明暗双模式交叉验证）
  - **头部区（搜索栏 + 胶囊行悬浮在内容上）磨砂不再是「恒定 σ 5.37 +
    栏底硬切」**：横幅侧边阶跃（理想竖直边缘，区外实测 10-90 宽仅
    1.3…1.6px）erf 最小二乘拟合逐深度给出 σ(y)：平台段 **8.5dp**
    （0…35dp）、线性衰减（100…113dp 处 3.2…4.4dp）、**158dp 归零** ——
    胶囊行底（152dp）之后还有约 6dp **羽化带**，不是硬切（胶囊正下方的
    横幅文字仍轻微发虚；暗色滚动帧里横幅上缘在 155dp 处实测 σ0.4dp、
    162dp 处已锐利）。旧口径出自 884×1920 低清素材（视频压缩软化下不可
    分辨渐变），本轮原生素材推翻
  - 新增 `MiHeaderBlurProfile`（`gradient_blur_tokens.dart`）：头部区 9 段
    定 σ 阶梯（`MiTransparencyTokens.blurSigmaHeaderRamp`），`MiTopBar`
    的 `uniformBlurBands` 重命名为 `headerBlurBands`、内部改用该曲线
    （仍按盒高拉伸、滚动 σScale 降 σ、不透明压色段内照旧剔除）
  - **玻璃零件（底栏 / 搜索栏 / 胶囊）磨砂 σ 28dp → 10.3dp = 32px**：
    浮动玻璃栏后方卡片边缘 erf 拟合 σ = 30…38px（亮 3 组 / 暗 3 组互证）。
    旧值 28 是 **px/dp 单位混淆**（28px ≈ 9dp 与实测同档，按 dp 用会糊
    2.7 倍；素材里导航栏后的棕榈叶 / 机身轮廓仍可辨）
  - 搜索栏 / 胶囊的玻璃膜 + 低调填充体系、底栏遮罩透射（深 0.63 / 亮
    0.61→0.80）与本轮实测一致，**不改**
  - 性能预算重标：头部区形态每帧模糊层数 2 → 10（9 段 + 导航，面积不变，
    阈值口径见 `perf_budget_test.dart`）；golden / README 预览图全部重生成

### Changed

- **修正「我的」设置行的尾饰箭头方向**（2026-10-26）：误用了顶栏**返回**箭头
  `BackChevronIconPainter`（‹），新增水平镜像的 `ForwardChevronIconPainter`（›，
  同一套度量仅朝向相反，推导）用于行尾「可进入」指示；「Logo 展示」组同步
  补「前进箭头」（全量 9 个 logo）

- **demo「我的」页改版为系统设置页风格**（2026-10-26，参考设置页明暗截图，
  卡片/按压色与几何为目测推导值）
  - 顶层页形态（`showBack: false`），首行搜索栏（`MiSearchBar` 静态展示，
    `frosted: false` 平底页不加磨砂）、内容顶缘 168.5dp（度量
    `searchBarTopInset`）、卡片页边距 11.9dp
  - 分组圆角卡片（亮 #FFFFFF / 暗 #1E1E1E、圆角 20）+ 设置行（38dp 彩色
    圆角图标块 + 主文案 16 + 副标题/右侧状态文案 + chevron 复用
    `BackChevronIconPainter`）；原渐变卡演示行 / `_mineItems` 占位卡全部
    退场，弹框演示与外观模式开关改建为设置行
  - **点击效果**（参考素材按压态）：按压**整行满铺**高亮带（方角、与卡片
    同宽、压在图标文字之下、无缩放），亮 #E7E7E7 / 暗 #3A3A3A、120ms
    渐变渐隐（推导）；新增 desktop_nav 回归用例钉住按压态

### Added

- **新增竖点「更多」logo（`MoreVerticalIconPainter`）并补全「Logo 展示」**
  （2026-10-26）
  - `nav_icons.dart` 新增竖向三点（⋮，「更多操作」语义）logo：**推导值**，
    沿用九宫格点阵语言（点径 21、三点等距竖排，首末点外缘铺满 100 单位高、
    点距 39.5），与 `GridDotsIconPainter` 同尺寸即同档视觉大小
  - demo「分类 → Logo 展示」组补全为 `nav_icons.dart` **全量 8 个 logo**：
    此前缺顶栏「返回箭头」（前 6 位口径已过时），现连同新增「竖点更多」
    一起陈列；展示位数量随 logo 数自适应（占位展示位顺延）
- **弹出面板 `MiPullUpPanel`**（首页右下「更多」圆钮的唤起形态，2026-10-26，
  参考 HyperOS 拨号键盘唤起录屏逐帧度量，含 0.25× 慢速浅色段（884×1920）
  复核；不实现拨号键盘，面板高度与内容完全自定义）
  - **几何（度量）**：宽 = 屏宽 − 2×24dp（左右 24.2/23.8 取均）、圆角 33.0
    （五点圆拟合残差 <0.3dp）、底距屏底 90.0（两段素材分别实测、dp 换算后
    一致）、表面暗 #2C2C2C / 浅 #FFFFFF（浅色由推导升级为实测）、**轻投影**
    （慢速浅色段：下缘外压暗 14 级 / 上缘仅 3 级 → 黑 @0.12、blur 14、
    下偏 4；暗色黑底不可分辨，推导同值）；**无压暗遮罩**（面板外页底像素
    不变，仍留一层透明命中层交宿主收起）
  - **唤起动效（逐帧拟合，残差 ≤11dp）**：从触发按钮**等比放大**到终态；
    弹簧 stiffness 260 / damping 26 / mass 1（ζ=0.807，由素材拟合：~0.53s
    收口、~0.33s 峰值、1.3% 过冲）；缩放原点为**移动原点** —— 横向 t∈[0,0.2]
    从按钮圆心靠到「终态右缘 − 20.9」（素材全帧恒定 ±1dp），纵向随进度
    lerp 到「屏底 − 2×90」（首版「绕按钮中心等比放大」中段低 ~34dp，
    不是素材里「向上长」的观感）；`AnimationController` 上界 1.2 防过冲钳平；
    **慢速段复核：展开全程不淡入**（逐点透明度反解 q≡1），淡出只在收回
  - **收回动效（拟合，两段素材互证）**：同一原点路径的**反向弹簧**（临界
    阻尼 530/46，~0.19s 缩回按钮、无回摆）+ **淡出 = 回收进度**（慢速 42ms：
    几何 0.82 / 透明 0.84；暗色 41ms：0.72/0.72 —— 同弹簧）；收口后回调
    `onDismissed` 由宿主移除；新增 `MiPullUpPanelController` 供编程收起
    （圆钮二次点按 = 收回）
  - **震动反馈**：demo 圆钮点按接 `HapticFeedback.lightImpact()`（素材按键
    有触感；档位为推导）；面板不代发触感（触发按钮属调用方）
  - **自定义长高与内容**：`height` 定值（超高钳到屏内可用高）或 null 内容
    自适应；内容在**终态尺寸**下排版、随面板一起缩放（唤起过程不重排版）；
    锚点传触发按钮圆心（全局坐标），默认取素材按钮位（推导）；宽屏档限宽
    440（推导，沿用弹框宽屏口径）
  - demo 首页右下九宫格圆钮接入：点按唤起「快捷操作」面板（240dp 自定义高）、
    震动反馈、展开时圆钮**交叉淡变**（绿⇄暗 #131313 / 白 #FBFBFB、点阵
    白⇄黑 —— 度量，慢速 313 帧中间态实测）、切走 tab 自动收起；新增
    `pull_up_panel_test` 10 项；README 补节与预览图 `panel_dark/light.png`

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
