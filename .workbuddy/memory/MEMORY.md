# mi_like_ui_demo 项目笔记

> 细节过程见 `.workbuddy/memory/YYYY-MM-DD.md`；本文件只留**长期有效的约定、度量、坑**。

## 约定
- 对外只经 barrel `lib/mi_like_ui.dart`；组件 `src/components/<类别>/<组件名>/`，类 `Mi` 前缀、文件 snake_case；颜色/文字/间距走 `src/theme/` token。
- **透明参数只有一个来源** `src/theme/transparency_tokens.dart`：其它文件只引用常量、**alpha 保留原生表达**（0.63 别写 161/255）。`transparency_config_test` 扫源码守门（含「配置自身必须带字面量」防空转）。
- **实测优先**：视觉参数 1:1 从素材量；素材没有的标「推导（非实测）」+ 写依据。
- 每任务完成即 commit（精确路径 add，绝不 `git add .`）；改样式后 `flutter test --update-goldens test/preview_capture_test.dart`；工作区不留未提交改动。analyze/test 由 agent 跑，build/adb 只给命令。
- **CHANGELOG 只写发布级变更**（1~2 行：改了什么 + 为什么）；细节留 README/注释/memory。
- **对外口径**：README/CHANGELOG/dartdoc 用「设计度量/推导值/参考素材」+ 专业 API 口吻，不写过程叙事（日期、反馈、踩坑、黄金图、内部项目名）。

## 响应式（`src/utils/responsive.dart`）
- **三处断点各管一件事**：① 窗口宽 `MiViewport/ofWidth`（compact<600 / medium 600…1023 / expanded≥1024）；② **画面容器宽** `usesSideNav(w)=w>600` → 底栏 vs 侧栏；③ **内容容器宽** `MiResponsiveGrid.compactMax/mediumMax`（示例 520/800）→ 列数。混用会错：限宽画布够不到窗口断点。
- `MiScaledCanvas.scaleFor = clamp(min(1, 可用宽/设计宽, 可用高/设计高))`：只缩不放；`scale==1` 走原样路径（零变换层）。
- `DemoStage.sizeFor(Size)→{logical,rendered}`（可单测）：**只有 compact 是物理手机**（等比 393×856），medium/expanded = 窗口（无留白/圆角/投影）。
- **宽屏配方（全部推导，素材只有 393 手机）**：内容列 ≤ **1120**（`MiBreakpoints.contentMaxWidth` + `MiContentColumn`，纵向撑满、只限内容不限底色）；页边距非 compact **32**（`MiDimens.spaceXxxl`）；主题卡桌面换**横版 16:10**（`MiThemeCard.previewAspectRatio`），平板竖屏停 3 列（6 张 3+3）；`MiResponsiveGrid.maxCellWidth`（主题卡 240）按 `ceil((w+gap)/(maxCell+gap))` **加列不加速度**；「我的」页内容列 720。列数取「断点台阶」与「单元宽上限列数」的较大者。
- **内容列恒定套着**（`Positioned` 里直接 `MiContentColumn`）：不按断点增删那层，否则页面 Element 重建、跨断点滚动位置归零；手机/平板画面本来 ≤1120，套上等于未启用。

## 指针悬停（`src/utils/hover_feedback.dart`）
- `MiHoverFeedback`：`MouseRegion(click)` + 叠色 = 按压高光的 60%（白/黑 **@5.6%**，`MiTransparencyTokens.hoverOverlayFor`），150ms easeOut。已接：主题卡 / 胶囊（仅未选）/ 按钮（仅可点）/ 搜索栏（仅 `onTap` 形态）/ 底栏与侧栏条目（圆角 16）。
- **叠色必须是实色 `AnimatedContainer`**（禁 `Opacity`/`FadeTransition`，见性能坑）；未悬停时 `Colors.transparent` → 结构恒定、黄金图零差异。`overlayKey` 供测试读叠色。
- 宽屏可见滚动条 `Scrollbar(thumbVisibility: !isCompact)`，页面需自己的 `ScrollController`。

## 宽屏侧栏 `MiGlassSideNavBar`
- 判定：`LayoutBuilder` 读**外壳自己** `maxWidth > 600` → 平板也用侧栏；`MiBreakpoints.desktop`(1024) 只给桌面专属样式。与底栏共用 items/selectedIndex/onTap + 全部动效 token（只换轴）。
- **几何全推导**：栏宽 95.4 = 格宽 82.2 + 2×6.6、条目高 49.3、间距 8、留白 25.5；`railHeightFor(n)=2×6.6+n×49.3+(n−1)×8`（3 项 177.1）；胶囊中心 = `railInnerPad + itemHeight/2 + pitch×pos`（**不是** `pitch×(pos+0.5)`）；`railRadius = pillRadius + railInnerPad = 31.25`（内外圈四周恒 6.6，**不用 railWidth/2**）；fab 挂栏尾。
- 示例：页面恒为 `Stack` 第一个 `Positioned(left: sideNav?gutter:0)`；侧栏档外壳底色 = 页底色（否则深色竖缝）；**不自绘 Home 指示条**（edge-to-edge 系统自己画）。
- **edge-to-edge**：`main.dart` `SystemUIMode.edgeToEdge` + `AnnotatedRegion<SystemUiOverlayStyle>`（透明状态栏/手势条、图标亮度随明暗）。不做则有系统灰带（实测 250→183）。浮层让安全区：侧栏顶 `padding.top+25.5`、底栏底 **`max(24.2, padding.bottom)`**（24.2 量的是**屏幕**底缘、手势条已含在内 → 不叠加，叠加到 45dp）。

## 搜索态①原地（`MiTopBar.searchActive`）
- 与②推入并存：原地在「分类」页、推入在首页。换算用**同帧搜索栏高** 66px→44.1dp 标定。实测：栏 y 252…317 → 78…143；左缘 21 不动、右缘 591→511；取消钮 ⌀66 = 栏高、距栏 15px、右缘贴屏 0（21+491+15+66≈592 闭合）。
- 取消钮：叉号墨盒 17.0 / 笔画 1.9；**墨色 = 前景墨色**（叉号 0 / 放大镜 167 / hint 161 三档，不能共用 icon 灰）；填充 = 搜索栏填充。
- 光标：`MiColors.accent`、高 21.3 钉死、闪烁 500/500ms（= 框架默认）。
- 转场 **480ms = 前 10% 静止 + easeOutQuint**；取消钮淡入落在线性 0.35…0.62。
- `MiTopBar` 是 Stateful，但构建体在 `_buildBar(context, progress)` → 非搜索页零像素变化。
- **坑**：`late final _c = AnimationController(value: widget.x)` 初始化器首次访问才跑（常在 didUpdateWidget）→ 出生即终态，**必须 initState 建**；Stack 条件插入子级会按下标配对 → **增删子级一律给 ValueKey**。

## 推入转场 `MiCardPageRoute`
- 素材 1220×2656 @24.31fps，s=3.104。新页左缘逐帧 `1220…0` → **easeOutCubic + 400ms**（mean|Δ| 1.6dp）；**前缘圆角 R=190px=61.2dp 全程恒定**；下层页左移 **0.25×屏宽×进度**（横幅上缘 y 恒 536 → 不缩放）；**压暗 = 黑 scrim**（沿 x 平坦 0.63~0.66，不是投影），进度 0.35/0.55/0.70 → α 0.20/0.32/0.38 → 终值 **0.55**；**无投影**。
- 搜索页头部：行顶 52.2、圆钮 ⌀44.1+左 11.9、钮↔框 11.0、框高 44.1、框↔搜索钮 11.0、搜索钮 53.5×40.9（右缘 12.6）；输入框**无放大镜**、占位缩进 12.6、hint 165 / 搜索钮墨 0。
- **一个路由两种角色**：`secondary != dismissed` → 只做被压住的左移视差；否则 → 全屏压暗 + 滑入 + ClipRRect 圆角；`visual>=1` 直接返回 child（零图层）。**压暗由上层画**、**视差只能由下层画**（`secondaryAnimation` 钩子；平台路由没有，所以示例根路由也换成本类，否则 Android Zoom 自己缩放退出页）。根路由换 `onGenerateRoute` 后主题切换仍生效（读 `_mode` 字段，非捕获值）。
- 参考实现圆角全程恒定（0.998 仍 190px）；本库「归位即归零」——此时新页铺满、缺口不露。

## 实测速查（dp @ 393 设计宽）
- 页底：亮 `#F3F3F3` / 暗 `#000000`；搜索栏灰：亮 `#E7E7E7` / 暗 `#242424`。
- MiPillTabBar：pill 87.6×39.9、gap/edge 11.9、标签 13.85 w500。
- MiButton：`#4980F7`（明暗同色）、高 28.3、左右 17、13 w500、stadium；列表行距 56.1。
- MiSearchBar：高 44.1、inset 15.4、icon 17.8（笔 1.8/镜片 6.9/r6.0）、gap 12、字 16.5 w400；填充 α 亮 13 / 暗 36、σ28；hint 亮 `#848484`/暗 `#6D6D6D`，icon `#9A9A9A`。
- MiGlassNavBar：栏 342×55.4、边距 25.5、格宽 82.2、内边距 6.6、pill 竖 inset 3.05 → pill 89.3、icon 高 23.2、icon→label 5.5、label 10.5 w500；fab ⌀55.4、gap 11.9；飞行 easeOutSine 260+20/cell + settle 350（overshoot .037、squash .022）、按压 90ms。
- MiDialog：卡宽 369.2/圆角 49.3/底距屏 32.9/无投影；标题 18.0（墨心 36.4）、正文 15.9（行距 23.2、墨心 75.55、内缩 28）、按钮盒 133..183（高 49.9）圆角 15、行内缩 24.2、gap 12.6、底留白 24.1；卡高 = 133+(行数−2)×23.2+49.9+24.1。色：卡 #242424/#FFF、中性钮 #434343/#F0F0F0、主钮 #478AFF/#3383FF、破坏红 #DA5244、遮罩黑 @0.20(亮)/@0.60(暗)；按压 = 叠色 12%（150ms，标签不变、不缩放）。
- MiThemeCard：预览 259:472≈0.549、圆角 20（拟合 19.6）、标题 13.85 w500 内缩 8.8、图→题 8 / 行距 15 / 列距 11.9；页边距双轨 = 壳 11.9 + 文本列 20.5（区块标题 inset 8.6）。**横版 16:10 是推导值**（桌面档）。
- **玻璃膜（`overContent`）**：亮 = 页底 @117/255(0.46)、暗 = 纯黑 @150/255(0.59)。依据：胶囊内侧 vs 同 y 间隙 亮 200/167、暗 70/170；模糊不改局部均值。平底页 onSurface@6% 是**另一状态**，不可互推。

## MiTopBar
- 返回圆钮 ⌀44.1/左 11.9/垂心 76.0，箭头墨盒 11.68×21.31（笔 2.05、墨心左偏 1.3）；大标题 31.83（墨左 29.6/墨心 132.9）、紧凑标题 18.0（屏心/墨心 75.9）；按压圆盘 白@9.4%、420ms 入/300ms 出。
- 内容首行顶缘两档（都实测，不归一）：卡片类 `contentTopInset` 183.0、搜索栏类 `searchBarTopInset` 168.5。
- 标题墨心靠 `Baseline(baseline: 墨心+0.355em)` 钉死；本 SDK `StrutStyle` 无 ascent/descent、`TextStyle.height` 只等比缩放 → 别退回 em 换算。
- 折叠：大标题随滚动 1:1 上移 + 独立淡出（0→19.97 归零）；紧凑标题 19.97→29.31 淡入。
- **材质两套规律**：① 纯标题/无头部 = 渐进曲线 σ 5.37(0…35)→4.96(50)→4.34(67.5)→1.85(90)→0.76(103)→0(119)，`visibleBlurBands` 等比拉伸到栏底归零；② **头部区 = 恒定 σ5.37 铺满 0…`occupiedHeight`(156)、栏底硬切**（`uniformBlurBands`）。
- **两个独立开关**：`showBlur`（内容区顶部渐进磨砂）、`showSurface`（顶栏压色：浅 #F3F3F3 @0.650→0@122.4；深色不动）。分类页 = 糊但无压色；「上半段纯黑」是叠色 α=1。
- **头部区由顶栏自产**：`searchHint/onSearchTap` → 内部 `MiSearchBar`；`tabs/selectedTab/onTabChanged` → 内部 `MiPillTabBar`（须显式下发 themeMode，其默认 deep）；换皮才用插槽，互斥靠构造断言（`hasSearchBar/hasTabBar/hasHeaderSlot`）。
- `MiTopBarMetrics`：`headerTopInset` 56（`headerTopInsetFor(safeTop)` 取大者）、`searchBarGap` 16、`headerContentGap` 12、`headerInset` 11.9、slot 高 44.1/39.9。材质层是**盖在整栏上的底**、不占布局高；`titleExtent` 在「有头部区无标题」时为 0；内置零件传 `frosted:false`；**胶囊行必须满宽**（自带 edgeInset 出血）。
- **标题只在不透明区内**：搜索态下顶栏按空白区 `hitTestBehavior` 处理，勿让材质层吃命中。

## 性能：每帧模糊预算
- `BackdropFilter` = 每帧全 QUAD 高斯；口径 = 一次 build 的**层数 + 面积 dp²**，钉在 `test/perf_budget_test.dart`。现状（深色）：手机 393 首页/分类 **2 层/75,701**、我的 6/35,799；平板 768 2/117,843、我的 6/52,142；桌面 1366 2/**191,615**、我的 6/77,900。
- 优化：① 深色顶栏跳过 0…63.6（scrim α=1）② 胶囊行 4 filter→1（`_CapsuleStripClipper`）③ `ImageFilter` 按 σ 缓存 + 跳过 σ<0.5。**恒定 σ：层数降、面积升** —— 一次大 filter 比多次小 filter 便宜。**内容列 1120 上限把桌面面积封顶**（否则随窗口线性涨）。
- **任何含磨砂的子树都不要套 `Opacity`/`FadeTransition`/`ShaderMask`**：引 saveLayer → backdrop 变空、磨砂消失 + 双份全宽高斯。切 tab / 底栏显隐 / 转场压暗 / 悬停一律**换结构或实色填充**。
- 「感觉丢帧」先排除 debug：`flutter run --profile` + `dumpsys gfxinfo`。

## 已知坑：测量与判据
- **平坦色块判不了有没有模糊**（模糊不改平坦区亮度）→ 用高频内容量边缘宽度；`matchesGoldenFile(finder)` 只截该子树，模糊源必须在内。
- **σ 与 α 在窄窗口耦合退化**（<3σ 解出假 α≈0.6）→ 频谱比 `log(Ŝ₁/Ŝ₀)=−2π²σ²f²+2log(1−α)`（斜率只含 σ）／带外平坦区反解 α／m<1 剖面 10-90 宽 = 2.08σ。
- 纵向滚动录屏里竖直边缘（水平剖面）不受运动模糊影响 → 优先取图标/头像左右缘。
- **判据别被描边骗**（曾误报 177.17，真值 183.0）→ 沿列剖面找单行硬跳变。
- 「是不是缩放」用**另一轴固定特征**判；「是不是阴影」看压暗**沿 x 是否平坦**（平坦 = scrim）。

## 已知坑：布局
- **无 child 的 `DecoratedBox`/`Container` 在松约束下取 `constraints.smallest`**（宽 0、隐形不报错）→ 加 `SizedBox.expand()`。
- **网格断点按「容器宽」标定**：舞台 1000−48=952 < 1024，沿用窗口断点永远 medium。
- **`MiPillTabBar` 在宽父级里会居中**（横向 ScrollView shrink-wrap）→ 宽屏包 `Align(centerStart)`。
- **全屏页壳 Stack 子级一律 `Positioned`**：否则 Stack 收缩到子级尺寸、遇 loose 上级整页居中（实测偏移 351.6dp）。
- 内容自适应用 `Center(widthFactor: 1.0)`（`Container`/`Align` 带 alignment 会有界拉满）。
- 叠在内容上的透明层要包 `IgnorePointer`，且包在 `GestureDetector` **外层**。
- 布局断言别用 `Column` 撑溢出：比容器高的 mock 用 `Stack`+`Positioned` 逐行摆。
- **`clipBehavior` 不要在状态间切**（增删裁剪层 → 子级重建 → 跨断点滚动位置归零）：固定 `antiAlias` + `BorderRadius.zero` + 空 `boxShadow` 表达「无卡片」。
- **给已截图界面加外壳层要零新增 render object**：套 `Padding`/`ColoredBox` 会让黄金图出现噪声差 → 改 `Positioned` 几何 + 容器颜色。
- **`ListView` 里塞 `Column` 必须 `mainAxisSize.min`**（无界高），带 `stretch` 时宽度取紧约束。

## 已知坑：字体与基线
- 墨心在基线上方 `k ≈ 0.355em` 跨字体稳；行盒内基线位置只能由字体度量定 → 用 `Baseline`。语义：`size.height = (N − 子级基线距) + 子级高`（无 clamp）。
- **测试字体 CJK advance ≠ 1em**（「关注」13dp 实测 26.5）→ 锁「收缩到内容」写 `btn.width == text.width + 2*padding`。
- **行盒高被引擎向上取整**：31.83 → 32.0，容差别写 0.01。

## 已知坑：测试与流程
- **`Unable to connect to flutter_tester ... Invalid WebSocket upgrade request` ≠ 代码问题**：`HTTP_PROXY` 劫持本地 WebSocket → 一律 `NO_PROXY=localhost,127.0.0.1 flutter test`。
- **改了几何 token 而预览图逐字节不变 = 有代码自算几何绕过 token** → grep 自算点 + `ImageChops.difference().getbbox()` 定位。
- 动过 `test/` 至少跑一次 `dart analyze`（0 error）。断言速记：构造断言 `expect(() => harness(...), throwsA(isA<AssertionError>()))`；`getDistanceToBaseline` 不能在测试体调 → 断 `Baseline.baseline`；`MaterialApp.theme` 是 200ms `AnimatedTheme` → `pump(300ms)`；`const` 断言不能求值 `.length`；位移用 `position.jumpTo`。
- **路由**：`push` 后 pump 两帧才挂上；`getTopLeft/getRect` **会应用祖先变换**；上层不透明路由时下层 offstage → `skipOffstage: false`；量容器左缘别用内部 `TextField`。
- **鼠标悬停测试**：`tester.createGesture(kind: PointerDeviceKind.mouse)` + `addPointer` + `moveTo`，再 pump 两帧走完 150ms 过渡；`find.byType(MouseRegion)` 会被 MaterialApp 自身干扰 → 按 `cursor == SystemMouseCursors.click` 过滤。
- **键盘测试**：本 SDK `sendKeyEvent` **没有修饰键参数** → 组合键用 `sendKeyDownEvent(modifier)` + `sendKeyEvent(key)` + `sendKeyUpEvent(modifier)`；`find.byType(Focus).first` 会先命中 MaterialApp 自己的 Focus → 必须 `descendant(of: 目标组件)` 限定。
- **断点切包装层 = 换 Element = 滚动位置归零**：任何「按断点增删的外壳层」（键盘作用域 / Focus / 内容列）必须**三档恒挂、只切参数**，不能写「compact 原样返回 child」（2026-10-23 踩过：`_keyboardScope` 导致跨断点测试红）。抢焦点的 `Focus(autofocus)` 手机档要关掉 —— 会把搜索光标闪烁相位推偏（黄金图 0.01% 差）。
- 截含光标的页面**不能 pumpAndSettle** → 固定 pump 到确定时长。

## 宽屏第二批配方（2026-10-23，全部推导 —— 素材只有手机档）
- **展开侧栏** `MiGlassSideNavBar.expanded`：容器 ≥1024（`usesExpandedRail`）换 **176dp**（`expandedItemWidth` 162.8、内缩 18、图文距 12），条目横排 icon+label；平板仍窄栏 95.4（展开栏+留白 201.5 = 768 的 26%）。
  - ⚠️ **首版 240 是错的**（用户反馈「太宽了」）：推导时把标签当成 13.85dp（那是 `pillLabel` 胶囊标签的字号），展开态实际用 `navLabel` = **10.5dp** → 2 字标签的胶囊 70% 是空白。正确反推：`2×内缩18 + 图标24 + 间距12 + 标签 + 2×6.6` = 2 字 106 / 6 字 148 / 8 字 169 → 取 176。**宽度跟着内容走，先确认字号再算**。
  - ⚠️ 横排 Row **必须钉 `expandedItemWidth` 定宽**（外层 Column 是居中对齐，不定宽会按自然宽居中、内缩不从胶囊左缘量起）。
- **顶栏三参数**（手机传默认值逐像素不变）：`headerTopInset` 桌面 **24**、`searchBarMaxWidth` 桌面 **520**、`actions` 右侧动作区（搜索转场淡出退排版）。`_searchRow` 分手机 Stack / 宽屏 Row 两条路径，**手机路径一字不动**。
- **桌面弹窗** `MiDialogMetrics.isWide(容器 ≥1024)`：居中限宽 **440**、圆角 **16**、`position` 失效；手机档用 `left/right=sideMargin` **自适应**（写死 width 369.2 会让窄容器溢出、平板原行为是撑满边距之间）。正文行数按**实际卡宽**排版。
- **桌面路由** `MiCardPageRouteMetrics.isWide(窗口 ≥1024)`：**4dp 抬起 + 同色幕布**（`ColoredBox` 页底色 alpha 1→0）**220ms**（`Interval(0,0.55)` 落在原 400ms 里 —— `transitionDuration` 构造期定死、拿不到窗口宽）、圆角 ≤16；下层无视差不压暗。⚠️ **淡入禁用 `Opacity`/`FadeTransition`**（新页含磨砂顶栏，saveLayer 清空自己的 backdrop）→ 用同色幕布。测试读 alpha 用 `MiCardPageRoute.wideVeilKey`。
- **悬停快捷操作** `MiThemeCard.quickActions`：黑@45%（token `cardQuickActionsScrim`）+ `AnimatedSlide` 滑入（Transform 无 saveLayer）、`IgnorePointer.ignoring` 联动；`quickActions==null` 不挂（手机档）。悬停态由 `MiHoverFeedback.onHoverChanged` 单点维护。
- **滚动降 σ** `MiGradientBlur.sigmaScale` / `MiTopBar.sigmaScale`（默认 1.0）：demo 滚动中 0.6、停 120ms 恢复。形状（段位/段高）不变只改强度，低于 `minVisibleSigma` 的尾段照常剔除；两档 σ 各自进 `MiFilterCache`。
- **桌面模糊预算**：1366 实测 **170,050 dp²**（2 层 = 顶栏 1120×**124** + 展开栏 176×177.1），比窄栏时代的 191,615 低 ~21k；阈值 **175,000**（按实测 +3%，与手机 78k / 平板 122k 同幅度）。README 表的手机 75,701 / 35,799、平板 117,843 / 52,142 是对的。
  - ⚠️ **性能/几何数字必须实测，别按推算写进注释**：上一批把桌面顶栏高度按手机的 **156** 算（实际 `headerTopInset` 桌面 24 → 高 **124**），得出 214,182 并写进了 README/CHANGELOG/阈值 —— 实测是 178,966，错 35k。查法：scratch 测试遍历 `BackdropFilter` 打 `size + localToGlobal`（`.workbuddy/scratch_*_test.dart`，跑完删）。
  - 桌面「我的」页 = 5 段渐进曲线（1120 宽，压色实心段下先剔 3 段）+ 展开栏 = 6 层 / 92,174（旧 README 的 77,900 是窄栏 95.4 时代的实测，也过期了）。

## 工具
- 像素脚本 `.workbuddy/measure_*.py / extract_*.py / fit_*.py`（PIL，非交付物，不入库）；venv `C:\Users\zmt\.workbuddy\binaries\python\envs\default\Scripts\python.exe`（`imageio` 可抽帧，ffmpeg 不在 PATH）。
- 快速出图：临时测试放 `.workbuddy/scratch_*_test.dart` + `--update-goldens`（跑完删除，勿入库）。
