# Changelog

本项目所有重要变更均记录于此。

格式参考 [Keep a Changelog](https://keepachangelog.com/)，版本号遵循 [Semantic Versioning](https://semver.org/)。

## [Unreleased]

### Added

- **搜索态：点搜索栏 → 真输入（搜索栏让位 + 取消钮 + 光标 + 键盘）**（2026-10-20，用户提供「短信」搜索录屏 592×1280 @24fps）
  - 新增 `MiTopBar.searchActive` / `onSearchCancel` / `searchController` / `searchFocusNode` / `searchAutofocus` / `onSearchChanged` / `onSearchSubmitted` / `searchCancelInset`。置 `searchActive: true` 后：内置搜索栏换成真 `TextField`、右侧淡入取消钮、胶囊行淡出并退出排版
  - `MiSearchBar` 新增 `editable` / `controller` / `focusNode` / `autofocus` / `onChanged` / `onSubmitted` / `textInputAction`。几何与配色完全复用：放大镜与占位文字**都不动**，光标出现在文字起点（实测行为：聚焦后 hint 不消失）
  - 新增 `MiSearchCancelButton`（`search_cancel_button.dart` + `search_cancel_metrics.dart`）：⌀44.1 = **搜索栏高**、与栏隔 10.0、右缘贴屏（实测 0）、叉号墨盒 17.0 / 笔画 1.9、墨色是**前景墨色**（实测叉号 0 而放大镜 167，不能共用一档）
  - 实测几何：正常态搜索栏 y 252…317px（168.4dp）→ 搜索态 78…143px（52.1dp），**高度不变 66px = 44.1dp**；取消钮 ⌀66px；栏↔钮 15px；四数在 592px 屏宽上闭合（21 + 491 + 15 + 66 = 593）
  - 转场 **480ms**：前 10% 静止 + `easeOutQuint`（拟合逐帧位移 `252 244 194 143 112 95 86 82 80 79 79 78`，mean|Δ| = 0.008；纯 easeOutQuint 无延迟 0.035、easeInOut 族更差）。取消钮淡入**不与位移同步**，落在线性进度 0.35…0.62（实测 208/250/292ms 覆盖率 0.32/0.63/0.96）
  - 光标：强调蓝（实测 rgb(60,130,246) → `MiColors.accent`）、高 21.3dp 钉死（实测 32px）、闪烁 500ms/500ms（实测亮灭各 12 帧 @24fps，与 Flutter 默认一致，故不另设）
  - 颜色 token 收敛：`MiColors.accent`（主按钮填充同源）、`MiColors.pageBackground{Light,Dark}`（`veilBase*` 改为转发，值不变）
  - 测试：新增 `test/search_state_test.dart`（14 例：几何 / 让位 / 右缘留白可覆盖 / `occupiedHeight` / 480ms 转场与淡入区间 / 进出双向 / 回调 / 输入态与 autofocus / 取消钮组件与断言）；`preview_capture_test` 新增搜索态预览两图（后续外壳两例见 `### Fixed`，共 16 例）

### Fixed

- **搜索态下浮动底栏收起；键盘不再压缩画面**（2026-10-20，用户真机实拍反馈）
  - 反馈两条：「唤起搜索后应该不展示底部导航栏」「输入法出现后不应该整体缩放」。实拍截图里浮动玻璃底栏仍在，且整块画布被键盘顶上去缩了水
  - 底栏：示例外壳把搜索态上传（`MockPage.onSearchActiveChanged` → `DemoApp._searchActive`），`else if (!_searchActive)` 时**不插**底栏（**换结构**，不是 `Opacity` 淡出 —— 淡出会给含 `BackdropFilter` 的子树套 `saveLayer`，backdrop 变空、玻璃栏瞬间变锐利）
  - 键盘：`Scaffold(resizeToAvoidBottomInset: false)`。`DemoStage` 按可用高度取 `min(1, w/W, h/H)`，`viewInsets` 吃掉高度就会让 393×856 画布整体等比缩水；关掉后键盘覆盖下半屏、画布恒定
  - 测试：`search_state_test` 新增两例（进搜索态底栏消失 / 退出装回；`viewInsets` 800+300 下画面尺寸不变）
  - 预览：新增 `doc/preview/demo_search_dark.png`

- **搜索态转场一上来就跳到终态**（2026-10-20，自查发现）
  - 两个独立成因，都会让 480ms 的转场看起来「瞬间完成」：① `AnimationController` 写成 `late final ... = AnimationController(value: widget.isSearchMode ? 1 : 0)`，那个初始化器在**第一次访问**（`didUpdateWidget` 里）才跑，此时 `widget` 已是新值 → 控制器一出生就是 1.0；改为在 `initState` 里建。② demo 首页的 `Stack` 里**条件插入**了一层搜索态遮罩，兄弟节点按下标配对，顶栏从下标 1 挪到 2 → 它的 `Element` 被当成新子树重建 → `State` 重来；给三个子级都补上 `ValueKey`

- **真机多出一条手势操作横条：示例不再自绘 Home 指示条，底栏也不再叠加安全区**（2026-10-20 真机反馈，附 881×1920 截图）
  - 成因：上一版开了 edge-to-edge，应用窗口铺到手势条下面 → **系统开始自己画那条手势条**；而示例外壳仍照手机框的老样子自绘了一条 `138×5` 的灰条（`bottom: 9 + safeBottom`）。于是同一屏出现两条：自绘那条（实测宽 309px = 137.8dp、离屏底 31.1dp = 9 + 安全区 19.6 + 2.5）与系统那条（宽 281px = 125.4dp、离屏底 10.7dp），前者反而比后者高
  - 修法一：**删掉自绘指示条** —— 那是手机截图里的系统 chrome，不属于任何组件；真机由系统画，桌面/预览档也不该假装
  - 修法二：底栏浮起量 `24.2 + safeBottom` → `max(24.2, safeBottom)`。24.2 是**距屏幕物理底缘**的实测值（参考截图里手势条正落在这 24.2 之内），叠加安全区后真机由绿钮 bbox 反解出栏底离屏底 **45.05dp**，比参考高 20dp、手势条悬在栏下空档里；取大值后手势导航档回到 24.2，三键导航档（48dp）仍抬到按键之上
  - 预览/黄金图：`adaptive_phone.png` / `adaptive_small_window.png` / `demo_{dark,light}.png` / `goldens/demo_light_mine.png` 重新生成（少了那条 5dp 灰条）
  - 测试：`desktop_nav_test` 边到边用例改为「手势条 20dp 档 = `856 − 24.2`（不叠加）」「三键 48dp 档 = `856 − 48`」，并断言画面上不存在 `138×5` 的自绘指示条

- **玻璃膜改成「垫在低调填充之下」的叠加，并给分类页也开上**（2026-10-20，用户实机反馈「你只是改了首页，分类没改」）
  - 上一版把 `overContent` 做成二选一（有内容时**只**铺膜、平底时只留 onSurface@6%），结果分类页这种「静止态背后是页底、滚动态才有内容」的页面没法开：开了静止态胶囊会与页底同色而消失，不开滚动态又读不出形状
  - 现在膜**垫在原填充之下**，两层用 `Color.alphaBlend` 预合成成一个等效色（`MiTransparencyTokens.veiledFill`，不新增 render object、不给磨砂子树加 saveLayer）。关键性质：膜取的就是页底色，垫在同色页底上恒等于没垫 —— **平底/静止态观感不变**，两态由背景决定而不是靠一个状态开关
  - `veilAlpha` 按「两层叠完」重新反解：亮 `0.46 → 0.60`（153/255）、暗 `0.59 → 0.655`（167/255）。校验：亮 `0.9412×(167+76a)=200 → a=0.60`、暗 `0.9412×170×(1−a)+15=70 → a=0.655`；平底合成仍是 `#E5E5E5` / `#0F0F0F` / `#E7E7E7` / `#242424`（浮点只差 0.3 级）
  - demo 分类页（组件展示页）传 `overContent: true`：网格上滚后色块压在头部后方时，搜索栏与未选胶囊是明确的玻璃片，而不是色块直接透上来
  - `showcase_sticky_{light,dark}` 预览重新生成（现在能直接看出滚动态的膜）；`doc/preview/home_*.png` 同步刷新（胶囊比纯膜版更接近参考的 200/70）
  - 测试：`transparency_config_test` 新增「膜 + 低调填充 = 平底页观感不变」四条断言（亮/暗 × 胶囊/搜索栏，容差 0.5 级）

- **压在内容上的搜索栏 / 未选胶囊改铺「玻璃膜」（`overContent`）**（2026-10-20，同一批首页截图）
  - 只给磨砂不够：模糊改变局部对比、**不改局部均值**，而实测胶囊内侧比同 y 的间隙亮 **33 级**（亮：200 vs 167）、暗 **~100 级**（亮色胶囊内侧 200 / 暗色 70，同 y 间隙都 ≈170）——那层落差只能来自填充本身
  - 上一版内置零件在顶栏里只留 onSurface@6% 的低调填充（平底页实测档），压在杂乱横幅上几乎读不出胶囊形状，与截图明显不符
  - 新增 `MiTransparencyTokens.veilFor(mode)`：亮 = 页底色 #F3F3F3 @117/255（0.46）、暗 = 纯黑 @150/255（0.59），都是按「胶囊内侧 / 同 y 间隙」反解出来的
  - `MiPillTabBar` / `MiSearchBar` 新增 `overContent`（默认 false = 平底页低调填充，行为不变）；`MiTopBar.overContent` 负责下发给内置零件，demo 首页传 `true`
  - 选中胶囊两态同款（近不透明），不参与这层膜；分类页 / 侧栏等平底场景 golden 零变化
  - 测试：`pill_tab_bar_test` / `search_bar_test` 各 +1 例（两态填充互换、选中档不动），`top_bar_test` +1 例（`overContent` 正确下发）

- **头部区（搜索栏 + 胶囊行）的磨砂改回「一整段恒定 σ」，栏底硬切**（2026-10-20，依据用户提供的首页亮/暗完整截图 881×1920）
  - 上一轮把「有头部区」也套成渐进曲线（σ 沿 y 递减、到栏底归零）属于**过度推广**：那条曲线的判据来自**完全没有顶栏**的「每日精选」页。首页截图实测：搜索栏行、栏与胶囊之间的空隙、胶囊行后方的树影**糊得一样重**；胶囊底缘（150…152dp）往下草地图案与「Simply Gorgeous」小字**立刻锐利**，没有过渡。照渐进曲线拉伸到 156dp 时胶囊行处只剩 σ≈2.5，与截图明显不符
  - 新增 `MiTopBar.uniformBlurBands(palette, {extent, underSurface})`：有头部区时只画 **1 段**（σ = `MiTopBarPalette.blurSigma` 5.37dp，0…`occupiedHeight`）；深色开压色时仍按盒高比例跳过 α = 1 的实心段
  - `MiTopBar.visibleBlurBands` 回归**只服务无头部区形态**（纯标题 / 纯材质的渐进曲线，行为不变）
  - 性能：头部区形态 **8 段 → 1 段**（分类页 / 首页 8 → 2 层）；面积反而上升（恒定 σ 要算满整条栏 156dp，渐进曲线尾部几段本来被剔除），但少 6 个 saveLayer、少 6 趟全 QUAD 高斯。预算重标：平板 2 层 / 117,843dp²、手机 2 层 / 75,701dp²、桌面 2 层 / 211,131dp²（`test/perf_budget_test.dart`）

### Performance

- **每帧模糊开销减半**（"滚动感觉丢帧"的定位与修复）
  - **深色顶栏跳过被不透明叠色盖住的模糊段**：0…63.6dp 的 scrim 是 α = 1.000 纯黑，其下模糊 100% 不可见 → 新增 `MiTopBarPalette.scrimOpaqueBottom` + `MiTopBar.visibleBlurBands`，8 段/119dp → 5 段/45.4dp（模糊面积 85,680 → 39,888 dp²）。亮色顶部 α 0.650，**一段不省**
  - **胶囊行 4 个 BackdropFilter 合并成 1 个**：`ClipPath`（`_CapsuleStripClipper`）一次裁出全部胶囊 + 单个 backdrop 模糊；分类页 6 → 3 层，相邻胶囊仍不串色（模糊层先于填充绘制）
  - **`ImageFilter` 缓存复用**（`src/utils/filter_cache.dart`，内部不导出）：σ 固定却每帧 `ImageFilter.blur(...)` 新建 native 对象，滚动时每帧 N 次；另跳过 σ < 0.5dp（高斯半径 < 1dp，亚像素）的段
  - **切 tab 去掉 260ms 淡入淡出**：`FadeTransition` 的 `Opacity` 引入 saveLayer → 下层 `BackdropFilter` 的 backdrop 变空（本项目实测坑），切页期间旧页磨砂消失且多一份全宽高斯（层数 7 → 9、6 层 opacity）；底部 tab 惯例为瞬时切换
  - 逐像素对比：最大灰度差 1~2 级、零像素差 > 2；新增 `test/perf_budget_test.dart` 把层数/面积钉成预算（含"深色段不落在不透明区""亮色从栏顶开始""同 σ filter 跨帧复用"）
  - 平板 768×1280 深色首页实测：10 层 / 100,073 dp² → 6~7 层 / 47,081 dp²

### Changed

- **透明参数收进统一配置 `MiTransparencyTokens`**（`src/theme/transparency_tokens.dart`）
  - 之前只有 `blurSigma` / 表面填充 alpha 在那里，搜索栏的 13·36、顶栏压色曲线的 22 档采样色、按压高光 0.094、玻璃导航栏的遮罩·透镜·描边·外缘 alpha、按钮禁用态 12%·38%、亮色投影色，全散在各自 token 文件里 —— 同一个语义抄两遍的风险很高
  - 现在**数值只在统一配置定义**，`MiTopBarPalette` / `MiSearchBarPalette` / `MiPillTabPalette` / `MiGlassPalette` / `MiGradientBlurProfile` / `MiButtonPalette` 只引用常量 + 自己的几何（stops、段位段高）
  - 渐进曲线：`blurSigmaRamp`（8 档 σ）成为唯一来源，`MiGradientBlurProfile.bands` 由「段位/段高」两张几何表 + ramp 生成（`const` → `final`，`MiTopBarPalette.blurBands` 同步；引用处已改）
  - **逐字节不变**：alpha 一律保留原来的表达形式（0.63 之类实测小数仍走 `Color.fromRGBO`，没有换成 `161/255`），159 项测试全绿、**零黄金图更新**
  - 新增 `test/transparency_config_test.dart` 6 例守门：扫源码断言 theme 层（除配置文件）与组件层都不出现 `withOpacity` / `fromRGBO` 的 alpha 字面量 / 带 alpha 的十六进制色 / `fromARGB(数字`；再断言各组件的取值确实等于统一配置的常量（含「配置文件自身必须带字面量」防空转）

- **平板 / 桌面铺满窗口（去掉外围圆角卡片），并改成 edge-to-edge 透明状态栏**（2026-10-18 平板实拍反馈：「应该铺满屏幕，不需要外围卡片效果」「状态栏为什么呈现灰色」）
  - `DemoStage`：medium / expanded 的画面 = **窗口本身**（不再四周留 24 + 圆角 56 + 投影 + 宽度上限 1000），只有 compact 仍是「物理手机画布 393×856」（等比缩到放得下）。`DemoStage.wideMaxWidth` / `minStageHeight` / `gutter` 随之删除，`sizeFor` 对非 compact 直接返回可用尺寸（仍过 `min(1, …)` 兜底）
  - 灰带成因：应用窗口原本从状态栏下方开始，那一条是**系统自己画的底色 + 压色**（实测 250 → 183），与页面底色对不上。现在 `main.dart` 用 `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`，`DemoHome` 用 `AnnotatedRegion<SystemUiOverlayStyle>` 给透明状态栏 / 手势条 + 图标亮度随明暗翻转，状态栏背后就是页面底色与顶栏磨砂
  - 代价：浮层自己让安全区 —— 侧栏顶 = `padding.top + 25.5`、底栏底 = `24.2 + padding.bottom`（2026-10-20 改为 `max(24.2, padding.bottom)`，见上条 Fixed）、Home 指示条同款（该条已删除，改由系统绘制）；顶栏本来就读 `MediaQuery.padding.top`
  - 性能：铺满后顶栏磨砂**面积随宽度线性增长**（平板首页 73,831 → 78,562、桌面 101,430 → 137,506 dp²），层数不变（7 / 8）；预算表按新尺寸重测
  - 测试：新增「铺满（圆角 0 / 无投影）」「状态栏透明 + 图标亮度随主题翻转」「侧栏让开状态栏 / 底栏让开手势条」三例；断点用例改为 600 底栏 / 601 侧栏（画面 = 窗口后边界即窗口宽）
- **顶栏材质拆成「内容区的渐进磨砂」+「顶栏自己的压色」两个开关**（2026-10-17 用户提出关键判断 ——「会不会这个模糊效果和顶部导航栏无关，而是内容区自己加了顶部渐进的模糊效果」，并附了一张**完全没有顶栏**的「每日精选」截图；逐行水平梯度实测证实：无顶栏页 44dp `0.05` → 75dp `0.97` → 116dp `4.32` → **120dp 后不再上升**，即内容顶部自己糊、到 ~120dp 自然收尾）
  - **结论修正**：上一版「头部区形态整条栏一个恒定 σ、一直糊到栏底」的判据被推翻 —— 那页低梯度一直持续到 156dp，是**搜索栏 / 胶囊这些大块半透明填充**把梯度压平了，不是模糊更深；模糊的真实成因是内容区顶部的渐进曲线。同时真机「上半段一片纯黑」的元凶是**叠色**（深色配方 0…63.6dp α = 1.000），与模糊无关
  - **磨砂 `showBlur`**（默认 true）：σ 沿 y 从 5.37dp 递减到**栏底归零**。曲线**形状固定、范围跟栏高走** —— 参照页的 119dp 曲线等比拉伸到材质盒（无头部区 128.9 / 头部区 156），对照分类页截图：糊到胶囊行下方、横幅底缘才变清晰
  - **叠色 `showSurface`**（默认 true）：只控顶部那层压色。分类页实测参考页**没有**这层压色（整条栏都能看见被模糊的背景），改为 `showSurface: false`
  - `MiSearchBar` / `MiPillTabBar` 新增 `frosted`（默认 true）：`showBlur` 开着时顶栏给内置组件传 `false`，整条栏只糊一次
  - **只开磨砂时必须保留 0…63.6dp 的模糊**：`visibleBlurBands` 新增 `underSurface`，跳过「被 α = 1 压色盖住」的省帧规则只在有压色时成立（否则栏顶一片清晰，实机踩过）
  - 性能预算：深色平板分类页 **6 层 / 53,953dp² → 8 层 / 117,274dp²**（无压色可省，7 段从栏顶画满 + 导航 1）；首页 10 → 6~7 层 / 83,245dp²、我的 6 层 / 53,610dp²（曲线拉伸 119 → 128.9 带来的 ~8% 面积增量）
- **分类页的搜索栏 + 胶囊标签行改由 `MiTopBar` 内部产出**：页面里手写的「吸顶 `Column`（搜索栏 + 16dp + 胶囊行）」、`_headerHeight`（`状态栏 + 44.1 + 16 + 39.9`）以及两个组件的 `new` 全部删除，改为 `MiTopBar(showSurface: false, searchHint: …, tabs: …, selectedTab: …, onTabChanged: …)` —— 页面只给数据，`MiSearchBar` / `MiPillTabBar` 由顶栏自己构造，滚动内容让位取 `bar.occupiedHeight(context) + headerContentGap`。渲染结果与迁移前**逐像素一致**（`doc/preview/showcase_*.png` 未变），吸顶/透射/点按行为不变；`showcase_sticky_test` 追加「搜索栏与胶囊行必须是 `MiTopBar` 的子树」「内容让位 = 168dp」两条断言
- **平板档（medium）改铺内容舞台**（2026-10-17 实机反馈修正）：原先 medium 按 1x 画 393×856 小手机居中，平板竖屏（650×1138）上画面只占 64% 屏高、上下各留 170/240px 纯黑，内容列数也停在手机档。现与 expanded 同策略：画面宽 = 可用宽（上限 1000）、高 = 可用高，四周留 24 —— 平板 650×1138 即 602×1090 舞台，主题卡 3→4 列。仍然只缩不放（`min(1, …)`），不靠放大手机来填满，避免 1dp 实测值失去物理意义。`MockPage` 页边距在非 compact 档统一 24。

### Added

- **demo 首页改成参考页形态：悬浮搜索栏 + 胶囊行压在高频横幅上**
  - 新增 `_HeroBanner` / `_HeroPainter`（示例层，非框架组件）：程序化风景（天空 / 云 / 远山 / 树线剪影 / 460 根随机草叶），高 186dp、通栏、底缘 20dp 圆角、**从 y = 0 起铺**（含状态栏后面）。用高频纹理是有原因的：**平坦色块在模糊下亮度不变**，"有没有糊"判不出来（本项目已实测过的坑）
  - 首页不再是大标题折叠形态，改为 `MiTopBar(showSurface: false, searchHint: …, tabs: …)` 头部区形态；`ListView` 上内边距 **0**（不给头部让位）→ 横幅与区块一起从头部后方滚过。大标题折叠形态的演示保留在「我的」页
  - 新增 `test/home_header_test.dart` 3 例：横幅铺到屏顶 / 通栏 / 186dp + 列表不让位 + 搜索栏与胶囊行是顶栏子树且悬浮在 56 / 116.1dp；磨砂 = **1 段恒定 σ 覆盖 0…156dp** 且与胶囊行底同源；上滚时头部不动、横幅上移
  - 新增 README 预览 `doc/preview/home_{light,dark}.png`、`home_scrolled_{light,dark}.png`（上滚 20dp：草叶整片压到搜索栏与胶囊行后方）

- **`MiGradientBlur`：顶部渐进模糊抽成独立组件**（`src/components/effects/gradient_blur/`）
  - **动机**：这层模糊本来就不属于顶栏 —— 参考 App 有一页完全没有顶栏，内容顶部照样糊。之前只能通过 `MiTopBar(showBlur: true)` 拿到，等于「没有顶栏的页面永远没有这层模糊」，与参考页矛盾。现在它不依赖任何页面形态，任何滚动内容都能自己挂
  - 入参：`height`（作用区，曲线按其拉伸并在此归零）/ `opaqueScrimBottom` + `underSurface`（上层有不透明压色时跳过被 100% 遮住的段；**关掉压色必须传 `underSurface: false`**）；`bandsFor(...)` 是纯函数，可单测
  - **曲线 token 迁到 `theme/gradient_blur_tokens.dart`**（`MiGradientBlurProfile`：σ 5.37 / 名义跨度 119 / `minVisibleSigma` 0.5 / 8 段阶梯），`MiTopBarPalette.blurSigma`、`blurBands`、`MiTopBarMetrics.minVisibleBlurSigma` 保留为转发（旧引用不改、含 `MiTopBarBlurBand` 的 export）
  - `MiTopBar` 内部改为复用它（`visibleBlurBands` 转发到 `MiGradientBlur.bandsFor`）；**golden 零差异**（111 项既有测试原样通过，未更新任何一张图）
  - 新增 `test/gradient_blur_test.dart` 9 条：曲线段数 / σ 递减、按作用区等比拉伸、不透明压色跳段与 `underSurface: false` 的对照、每段几何与 `bandsFor` 一致、禁用 `ShaderMask`/`Opacity`、不吃手势、无 `MiTopBar` 也能单独用、`ImageFilter` 跨帧复用

- **宽屏（平板 / 桌面）：底部导航栏换成侧边导航栏**（`MiGlassSideNavBar`）
  - 新增组件 `src/components/navigation/glass_side_nav_bar/`（widget + metrics + painter），经 barrel 导出 `MiGlassSideNavBar` / `MiGlassSideNavMetrics`
  - **同语义纵向版**：条目类型沿用 `MiGlassNavItem`（标签 + 图标 painter），选中态同为「胶囊透镜」、`onTap(index)` 语义不变 —— 示例里底部栏与侧栏吃**同一份 items / selectedIndex / onTap**，图标、选中反馈与跳转行为零差异
  - **同配方**：玻璃材质（`MiGlassPalette` + `MiTransparencyTokens.blurSigma`，整条栏只挂 1 个 `BackdropFilter`）与动效（`MiGlassNavMetrics` 的飞行 easeOutSine、settle 波形、按压缩圈 3%/7.5%、拖拽果冻）全部复用底部栏 token，仅把轴换成纵向（飞 x→y、果冻「宽拉伸+高压缩」→「高拉伸+宽压缩」）
  - **几何全部「推导（非实测）」**（参考素材没有侧栏样张）：栏宽 95.4 = 实测格宽 82.2 + 2×内边距 6.6、条目高 49.3 = 实测胶囊高、条目间距 8、栏体到左缘留白 25.5 = 实测 `barMarginH`、图标墨盒 / 间距与底部栏完全一致；换算表写在 `side_nav_bar_metrics.dart` 类注释
  - **两处刻意差异**：不做预留空位圆钮（横向空位腾挪在纵向无等价语义）；栏体竖向收缩到内容高、位置由宿主给（示例贴顶 + 距左缘 25.5）
  - **判定逻辑照 MReader 主壳层**（`MReader/lib/ui/home_shell.dart`）：`LayoutBuilder` 读**外壳自己的** `constraints.maxWidth`，`maxWidth > kShellRailBreakpoint`（600）才切侧栏 —— 新增 `MiBreakpoints.navRail = 600` + 纯函数 `MiBreakpoints.usesSideNav(width)`（**严格大于**，正好 600 仍走底栏）+ `MiWindowSize.usesSideNav`。因此**平板也用侧栏**（600…1023），只有手机 / 窄窗留底栏；判据跟着容器走而非窗口，手机框嵌进宽窗口也不会摆侧栏
  - `MiBreakpoints.desktop`（1024）/ `MiWindowSize.isDesktop` / `MiViewport.isDesktop` 保留为「桌面档」判定（舞台加宽、网格 6/8 列），**不参与导航形态**
  - 示例 `DemoHome`：`DemoStage` 内套 `LayoutBuilder`，画面宽 > 600 时侧栏占左侧 120.9dp 列（贴顶、距左缘/顶缘各 25.5），页面左缘从 0 变成该列宽（页面恒为 `Stack` 第一个子级，跨断点切换时 `Element` 不重建、滚动位置保留）；手机 Home 指示条只有底栏形态才有
  - 切换不做淡入淡出（`Opacity`/`AnimatedSwitcher` 会给含 `BackdropFilter` 的子树引入 saveLayer → 磨砂整段消失，本项目已知坑）
  - 新增 `test/desktop_nav_test.dart`（`usesSideNav` 600/602 边界、侧栏几何 / 选中槽位 / 点按与拖拽回调 / 单层磨砂 / 形态唯一 / 画面让位与贴顶留白 / 跨断点来回切换保留滚动位置），`perf_budget_test` 追加桌面档预算（首页 7 层 / 101,430 dp²、分类 8 层 / 142,511 dp²）并按侧栏档重测平板（首页 73,831 / 我的 49,527 / 分类 102,501），预览图新增 `nav_side_dark|light.png` 与 `adaptive_desktop_light.png`、`adaptive_tablet.png` 重生成（平板也换侧栏）
- **MiTopBar 通用化：头部区（顶栏自己产出搜索栏 / 胶囊行）** —— 顶栏由「标题区 + 头部区」上下拼成，两区可自由组合
  - **声明式入参（默认路径，调用方不 new 组件）**：`searchHint` / `onSearchTap` → 顶栏内部构造 `MiSearchBar`；`tabs` / `selectedTab` / `onTabChanged` → 内部构造 `MiPillTabBar`。明暗配方由顶栏解析后的 `themeMode` 统一下发（页面不必再各传一遍 `themeMode`），`onTabChanged` 为空时胶囊只展示不可切换
  - **同名插槽（逃生口，与声明式入参二选一）**：`searchBar` / `tabBar` 传现成组件换皮，排版与让位完全相同；`searchBarHeight` / `tabBarHeight` 用于声明插槽高度（默认 44.1 / 39.9，声明式入参时恒等于组件自身高度）
  - `header`：`PreferredSizeWidget` 整块自定义头部，高度取 `preferredSize.height`；与搜索栏 / 胶囊行**互斥**，`searchBar`↔`searchHint`、`tabBar`↔`tabs` 也各自互斥（构造期断言）
  - `showSurface`：是否绘制顶部**压色**（默认 true）；`showBlur`：是否绘制**顶部渐进磨砂**（默认 true）。二者独立 —— 分类页形态是 `showBlur: true` + `showSurface: false`，都传 false 才回到「零件各自玻璃」的旧形态
  - `occupiedHeight(context)`：顶栏自身占用的总高（= 声明插槽高 + 标题区），宿主据此给滚动内容让位 —— 与组件内部排版同源，不会「头部下移而列表没让位」
  - 新增 `hasSearchBar` / `hasTabBar` / `hasHeaderSlot` 三个只读判断（声明式入参与插槽合并判断）
  - `MiTopBarMetrics` 新增头部件几何：`headerTopInset` 56 / `searchBarGap` 16 / `headerContentGap` 12 / `headerInset` 11.9 / `searchBarSlotHeight` 44.1 / `tabBarSlotHeight` 39.9，以及 `headerTopInsetFor(safeAreaTop)`
- **响应式 / 自适应能力**（桌面、平板、手机三档）
  - `src/utils/responsive.dart`：`MiBreakpoints`（窗口三档 compact <600 / medium 600…1023 / expanded ≥1024，纯函数）、`MiViewport`（`MediaQuery.sizeOf` 派生的窗口快照，随尺寸变化自动重建）、`MiScaledCanvas`（把固定设计画布按 contain 等比缩放：只缩不放、宽高同比例、`scale == 1` 时零变换层）、`MiResponsiveGrid`（按**容器宽**断点切列数，行内 `Expanded` 等分、末行留空不拉伸）
  - 示例外壳 `DemoStage`：compact 按 393×856 设计画布等比缩小（手机全屏正好 1:1）；medium 四周留 24dp、1x 居中；expanded 加宽成 1000×可用高 的内容舞台（重新布局而非拉伸）；三档统一过 `min(1, 可用宽/设计宽, 可用高/设计高)` 兜底，窗口再小也不溢出、不变形
  - 内容层断点：主题卡网格 3/4/6 列、展示位网格 4/6/8 列，断点按**内容宽** 520/800 标定（限宽画布里的容器够不到窗口断点）；分类页顶部状态栏让位改用 `max(56, 安全区)`，胶囊行显式左对齐
  - **修正**：demo 此前固定 393×856 手机框，在 260×470 这类小窗口下被裁掉一半（README 预览图即此状态）；现在整机完整可见
  - 回归见 `test/responsive_test.dart`（断点边界 / `scaleFor` / 三档尺寸 / 小窗与桌面实际渲染无溢出 / 窗口热切换 / 列数）
- **MiSearchBar** 搜索栏（亮/暗分类页完整截图 1:1 实测）
  - **透明参数与底部导航栏同源**：backdrop 磨砂取 `MiTransparencyTokens.blurSigma`（与 `MiGlassNavBar` / 胶囊同一磨砂强度），填充为半透明表面 —— 平底合成 = 截图实测实色（亮 #E7E7E7 / 暗 #242424，实测反推 黑@13 / 白@36；非胶囊 subtle(15) 档，代入会得 #E5/#0F 偏离截图）
  - 几何实测：高 44.1、stadium、图标 17.8dp 起于左缘 15.4、图文间距 12、占位 16.5dp CJK advance、放大镜墨色明暗同值 #9A9A9A、占位墨色 亮 #848484 / 暗 #6D6D6D
  - `MiSearchBarPalette` 配方入主题层（`theme/search_bar_tokens.dart`）、`MiSearchBarMetrics` 几何入组件目录、放大镜 `SearchIconPainter` 组件内自包含；`themeMode` 为空时跟随环境 Theme 亮度
- demo 首页与分类页吸顶头部的搜索位接入 `MiSearchBar`（替换私有不透明 `_SearchBar`），滚动内容从栏后透上来被磨砂
- **MiButton** 胶囊按钮（明暗双模式）
  - 1:1 实测自「我的关注」页关注按钮（亮/暗两张 1220×2656 完整截图）：高 28.3dp stadium、填充 `#4980F7` 明暗同色、标签 13dp Medium 白字、左右 17dp 内边距（宽度随内容自适应）
  - `MiButtonVariant` 形态：`filled`（实测）/ `tonal`（已关注，推导：复用搜索栏实测灰 + 胶囊标签实测墨色）；`onPressed = null` 为禁用态（推导：onSurface@12%/38%）
  - `MiButtonPalette` 配方入主题层（`theme/button_tokens.dart`）+ `MiButtonMetrics` 几何入组件目录
- **组件展示页「按钮展示」分组** 陈列 MiButton 三态（主按钮可点按切换 关注 ↔ 已关注），行距沿用实测 56.1dp
- **按钮 README 预览图** `doc/preview/button_light|dark.png`（明暗三态特写，由预览捕获测试生成）
- **MiTopBar** 大标题折叠顶部导航栏（明暗双模式，1:1 逐帧实测自 HyperOS 设置页录屏 1220×2656@24.32fps）
  - **折叠动效为逐帧实测**：大标题**属于滚动内容** —— 质心位移与列表滚动位移逐帧相等（−6/−18/−28/−31/−37/−45px 对同一组滚动量），即随内容 1:1 上移、**不是**钉在栏上缩放；在此之上另有一条独立淡出曲线（`largeTitleFade`：0→19.97dp 归零，中段下降最快），紧凑标题在大标题归零**之后**才淡入（`compactTitleFade`：19.97→29.31dp），两段不重叠
  - ~~**遮挡是纯色遮罩，不是磨砂玻璃**~~（**已废弃**，见 Changed）：实心段下沿 63.6dp + 1.5 次幂渐隐裙边至 128.9dp（拟合 `alpha(y)=1−clamp((y−63.6)/65.3,0,1)^1.5`，渐变为 8 等分采样）；实测依据 = 均匀色块在遮罩下出现亮度斜坡（排除 backdrop 模糊）+ 卡片硬边 3px 内完成跳变（无拖尾）。故刻意不复用 `MiGlassPalette`
  - 几何实测：返回圆钮 ⌀44.1 / 左 11.9 / 垂心 76.0，箭头墨盒 11.68×21.31 / 笔宽 2.05 / 墨心左偏 1.3dp（光学偏置）；大标题 31.83dp（墨左 29.6 / 墨心 y 132.9）、紧凑标题 18.0dp（屏内心 / 墨心 y 75.9）
  - **内容首行顶缘按实测分两档**：卡片类 `contentTopInset` 183dp（录屏「显示与亮度」卡片填充顶缘 568px 硬边）、搜索栏类 `searchBarTopInset` 168.5dp（参考截图「设置」首页搜索栏顶缘 523px）—— 两值都来自整机实测，故不强行归一
  - **标题墨心落点靠 `Baseline` 钉死**（`baselineType: alphabetic`，目标值 = 墨心 + 0.355em，见 `MiTopBarMetrics.titleBaselineY`）：墨心在**基线上方** `k ≈ 0.355em` 在各中文字体间很稳（simhei / msyh / simsun 实测 0.350~0.360），而基线在**行盒内**的位置只能由字体度量决定（`StrutStyle` 在本 SDK 上没有 ascent/descent 参数、`TextStyle.height` 只按比例缩放 ascent/descent 改不了二者之比），字体间可差 0.14em（参考录屏 MiSans ≈0.807、Android CJK 回退字体 ≈0.95）。不钉基线时实机大标题墨心比模型低 6.9dp（2026-10-16 实机实测）；`Baseline` 在布局期求解，故组件高度取「墨心 + 一整行」的定值即可（`componentHeight`，不随字体变化）
  - 按压反馈实测：⌀44.1 圆盘、白 @9.4%、420ms easeOut 淡入 / 300ms 淡出（逐帧 0→25%→83%→100%）
  - **返回圆钮默认不显示**（`showBack` 默认 `false` —— 顶层页无返回，如参考截图「设置」首页）：`showBack: true` 才绘制圆钮，其可点性由 `onBack` 决定（`null` = 只显示、不可点、无按压反馈）；`showBack` 同时决定紧凑标题的对称内缩（让开圆钮 / 用满整屏宽）
  - **受控组件**：`scrollOffset` 由宿主注入（与 `MiPillTabBar.selectedIndex` 同风格），组件不自带滚动；除返回圆钮外整体不参与手势。负位移 / NaN 构建期断言，+∞ 饱和为折叠完成态
  - `MiTopBarPalette` 配方入主题层（`theme/top_bar_tokens.dart`，**浅色配方为推导**：无亮色顶栏录屏，遮罩基色取实测页底 #F3F3F3）、`MiTopBarMetrics` 几何 + 折叠查找表入组件目录、返回箭头 `BackChevronIconPainter` 入 `icons/nav_icons.dart`
- demo 首页 / 「我的」页接入 `MiTopBar`（页面壳改 `StatefulWidget`，用 `ValueNotifier` 承接 `ScrollController` 位移，只重建顶栏一层）：首页 = **顶层页形态**（默认 `showBack: false`，首行搜索栏 → `searchBarTopInset` 168.5）、「我的」= **次级页形态**（`showBack: true`，首行卡片 → 183）
- **MiTopBar 渐进磨砂材质**（亮色「我的」页录屏实测，1220×2656@24.26fps）—— 顶栏原本只有纯色遮罩，**缺 backdrop 模糊**
  - 该页顶栏**不内嵌任何组件**，因此可纯粹观察材质：头像（⌀87dp 圆形照片）随滚动进入栏内后边缘被抹开、栏外时边缘仅 1.4px 宽
  - **σ = 5.37dp**：栏顶平台段边缘 10-90% 宽度 42.7px（w₁₀₋₉₀ ≈ 2.563σ）换算，并用同行「频谱比 log(S₁/S₀) = −2π²σ²f²」交叉验证（67.5dp 处 4.34dp、90dp 处 1.85dp，与衰减曲线一致）
  - **模糊随 y 渐隐**（非整片糊）：有效 σ 由 5.37（0…35dp）→ 4.96(50dp) → 4.34(67.5dp) → 1.85(90dp) → 0.76(103dp) → 0(≥119dp)；实现为 **8 段定 σ 阶梯**（`MiTopBarPalette.blurBands`，每段 `ClipRect + BackdropFilter`，σ 取实测曲线在段中点的分段线性插值）
  - **浅色叠色改为实测值**：叠色 = 页底色 #F3F3F3，α 0.650（栏顶）→ 0（122.4dp）。判据为两处平坦区交叉验证 —— 页底 243 在栏内全程不变（排除白色叠色）、白卡填充 255 在 80dp 处读 **249**（= 255 − 12×0.50）而同帧栏外读 255（排除无叠色），α(y) 曲线取自逐行反卷积 + 保序回归平滑
- **`MiTopBar.title` 改为可空**：不传 = **纯材质形态**（不内嵌任何组件，只画磨砂 + 叠色，组件高度收到 `scrimHeight`），与参考录屏同构；`showBack` 仍可单独使用
- **顶栏 README 预览图** `doc/preview/top_bar_light|dark.png`（四格：纯材质形态内容滑入栏内 / 顶层页默认形态无圆钮 / 次级页带圆钮 / 滚动 105dp 内容穿进磨砂）
- **MiThemeCard** 竖向预览卡片（主题商店「精选主题」卡，明暗双模式）
  - 1:1 实测自首页截图（881×1920 等比副本，s = 393/881 = 0.4461）：预览图 259:472 定比（3 列 115.5×210.6dp）、圆角外缘拟合 R=44px ≈ 19.6dp（取 `MiDimens.radiusLg`）、标题 13.85dp Medium（pitch 31px）、较图左缘内缩 19.5px ≈ 8.8dp（三卡一致、与区块标题 x46 同列 —— 左对齐 + 内缩而非居中）、图→标题行盒 8dp、行距 15dp、列距/页边距 11.9dp
  - `MiTypography.cardTitle` 文字 token + `MiThemeCardMetrics` 几何参数表（含 ink→行盒换算脚注）；`themeMode` 为空跟随环境 Theme 亮度（与 `MiSearchBar` 同约定），`onTap` 为空不参与手势（参考图为静态截图、无按压实测）
- demo 首页「精选主题」两行渐变占位替换为 3×2 `MiThemeCard` 网格（实测壁纸主色上→下渐变占位 + 示例标题）
- **主题卡片 README 预览图** `doc/preview/card_light|dark.png`（3 列特写，由预览捕获测试生成）

### Changed

- **磨砂的"渐变遮罩"实现改为"分段定 σ 阶梯"**：原实现用 `ShaderMask(blendMode: dstIn)` 把定 σ 的模糊按 m(y) 与原内容混合，但实测该写法**不生效** —— 半透明遮罩会给 `BackdropFilter` 换一层空的 saveLayer，backdrop 变空、模糊整段消失（探针：遮罩 alpha 恒 1 时条纹被抹平，一旦出现 <1 的 alpha 就完全恢复锐利；`Opacity` 同理）。Flutter 没有位置相关模糊，故改为 8 段并列（段高 ≤ 17dp、相邻 σ 比 ≤ 1.5）近似实测曲线。由此 `MiTopBarPalette.blurMask` 删除，新增 `blurBands` / `MiTopBarBlurBand`
- **推翻「顶栏是纯色遮罩、无 backdrop 模糊」的旧结论**（原文见 Added 里的 `MiTopBar` 条目，保留以便追溯）：当时的证据（沿蓝卡做纵向取样得亮度斜坡、卡片下缘 3px 硬跳变）都取自模糊带**之下**的**平坦色块** —— 平坦区在模糊下亮度不变、且本来就在带外，无法区分"有模糊"与"无模糊"。改用高频内容（头像照片、圆角方块的竖直边缘）后测出确定性模糊
- 浅色顶栏叠色由"#F3F3F3 @1.0→0（照抄深色的 1.5 次幂曲线，属推导）"改为**实测** α 0.650→0（122.4dp）；深色配方不动（其参考页顶部确实不透明）
- 顶栏预览从三格 393×744 改为四格 393×1100（新增纯材质形态；`_topBarBackdrop` 新增 `header` 页头，作为磨砂的判据内容）
- 组件展示页胶囊标签改名：`示例一` → **Logo 展示**、`示例二` → **按钮展示**（按分组内容命名，`示例三/四` 保持占位）
- 吸顶行为测试改为在滚动网格内定位分组标题（避免与同名胶囊标签冲突）
- demo 首页壳层左右页边距 20 → 11.9dp（实测搜索框 28 / 横幅 25 / 卡片 25~26 同量级），区块标题行经 `_SectionTitle.inset` 收进 ≈20.5dp 文本列（原 20 近似保留）；「我的」页与分类页不受影响

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
- 亮色胶囊移除虚构白描边，对齐录屏实测真值
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
- [x] `MiTopBar` — 大标题折叠顶部导航栏（纯色遮罩，非磨砂）
- [ ] `MiDialog` — 弹窗
- [ ] `MiForm` — 表单
- [ ] `MiTheme` — 主题聚合
