# mi_like_ui_demo 项目笔记

## 约定
- 对外只经 barrel `lib/mi_like_ui.dart`（新增组件/token 补 export）；组件 `src/components/<类别>/<组件名>/`，类 `Mi` 前缀、文件 snake_case；颜色/文字/间距一律走 `src/theme/` token，组件内不写字面量。
- **透明参数只有一个来源**：`src/theme/transparency_tokens.dart`（σ / 各级 alpha / 玻璃膜色 / 压色曲线采样色 / 导航栏五层 alpha / 禁用态）。其它 theme 文件与组件只引用常量，**alpha 保持原生表达形式**（0.63 别换算成 161/255，否则黄金图漂）。守门测试 `test/transparency_config_test.dart` 扫源码（含「配置文件自身必须带字面量」防空转）。曲线类：色值表/σ 表在统一配置，几何（stops、段位段高）留在各 palette。
- **实测优先**：视觉参数 1:1 从参考截图像素量；参考图没有的样式只能推导，doc 标「推导（非实测）」+ 写明来源。
- 每个任务完成即 git commit（精确路径 add，绝不 `git add .`）；改样式后 `flutter test --update-goldens test/preview_capture_test.dart`；工作区不留未提交改动。`analyze`/`test` 由 agent 代跑（2026-10-17 用户明确），build/adb 给命令文本。
- **CHANGELOG 只写发布级变更**（2026-10-20 用户两次要求精简）：一条 1~2 行，写「改了什么 + 为什么」；**不写**实测出处（谁提供的录屏/截图）、像素与拟合数据、测试例数、预览图与文件清单、实现细节。细节留在 README（设计叙事）、代码注释与 `.workbuddy/memory/`。同一版本内不重复 `### Added` / `### Changed` 小标题。

## 响应式（`src/utils/responsive.dart`）
- **三处断点各管一件事**，混用必错：① 窗口宽 `MiViewport`/`ofWidth`（compact<600 / medium 600…1023 / expanded≥1024）→ 外壳是否加宽；② **画面容器宽** `MiBreakpoints.usesSideNav(w)= w>600` → 底栏 vs 侧栏；③ **内容容器宽** `MiResponsiveGrid.compactMax/mediumMax` → 网格列数。
- `MiScaledCanvas.scaleFor = clamp(min(1, 可用宽/设计宽, 可用高/设计高), minScale, maxScale)`：只缩不放、等比；`scale==1` 走原样路径（零变换层，黄金图稳定）。
- 示例外壳 `DemoStage`（demo_app.dart，`sizeFor(Size)→{logical,rendered}` 可单测）：**只有 compact 是物理手机**（等比 393×856）；medium/expanded = 铺满窗口（2026-10-18 平板实拍反馈去掉 24 留白/圆角/投影/宽度上限）。
- 内容断点：主题卡 3/4/6 列、展示位 4/6/8 列；非 compact 页边距 24，compact 用实测 11.9/20。

## 宽屏侧栏 `MiGlassSideNavBar`（2026-10-18）
- 判定照 MReader `lib/ui/home_shell.dart`：`LayoutBuilder` 读**外壳自己 constraints.maxWidth**，`> MiBreakpoints.navRail`（600）切侧栏 → 平板也用侧栏，只有手机/窄窗留底栏；`MiBreakpoints.desktop`(1024) 只给桌面专属样式（舞台加宽/6-8 列）。
- 与底栏共用 `MiGlassNavItem`/`selectedIndex`/`onTap` + 全部动效 token（只换轴）。
- **几何全「推导（非实测）」**：栏宽 95.4 = 格宽 82.2 + 2×6.6、条目高 49.3、间距 8、左/顶留白 25.5；`railHeightFor(n)= 2×6.6 + n×49.3 +(n−1)×8`（3 项=177.1）。胶囊中心 = `railInnerPad + itemHeight/2 + pitch×pos`（不是 `pitch×(pos+0.5)`，否则整体下移 gap/2）。fab 挂栏尾下方、栏体不让位（槽位恒定预留）。
- **内外圈等距（用户反馈「以内圈为准」）**：`railRadius = pillRadius + railInnerPad` = 31.25（不是 railWidth/2）——端头圆弧与胶囊顶角同心、四周恒 6.6。
- 示例：`DemoStage` 内套 `LayoutBuilder`，页面恒为 `Stack` 第一个 `Positioned(left: sideNav ? gutterWidth : 0)` → 跨断点不重建、滚动保留；侧栏档外壳底色 = 页底色（否则深色有竖缝）；**不自绘 Home 指示条**（edge-to-edge 下系统自己画，自绘=两条）。
- **edge-to-edge**：`main.dart` 调 `SystemChrome.setEnabledSystemUIMode(edgeToEdge)`，`DemoHome` 用 `AnnotatedRegion<SystemUiOverlayStyle>`（透明状态栏/手势条，图标亮度随明暗）。不做则窗口从状态栏下方开始，那条灰带（实测 250→183）就是系统画的。代价：侧栏顶 = `padding.top+25.5`、底栏底 = **`max(24.2, padding.bottom)`**（24.2 量的是**屏幕**底缘、手势条就在这 24.2 里 → 不叠加；叠加会到 45dp，真机实测过）。

## 搜索态（`MiTopBar.searchActive`，2026-10-20）
- 参考录屏「短信」搜索 592×1280 **@24fps**；换算 s 用**同帧搜索栏高** 66px→44.1dp 标定（别用屏宽标，会和既有 44.1 打架）。
- 实测：栏 y 252…317 → **78…143**（168.4→52.1dp），高不变 66px；左缘 21 不动、右缘 591→511；取消钮 ⌀66 **= 栏高**、距栏 15px、**右缘贴屏（0）**——四数闭合 21+491+15+66=593≈屏宽，圆纵向也 66 故非裁切。
- 取消钮：叉号墨盒 17.0 / 笔画 1.9；**墨色 = 前景墨色**（实测叉号 0、放大镜 167、hint 161，三档不同，叉号不能共用 icon 灰）。填充 = 搜索栏填充（同帧同色）。
- 光标：强调蓝（实测 rgb(60,130,246) → `MiColors.accent`）、高 **21.3** 钉死、闪烁 500/500ms（= Flutter 默认，不用设）。
- 转场 **480ms = 前 10% 静止 + easeOutQuint**（拟合 mean|Δ|=0.008；无延迟 quint 0.035、easeInOut 更差）。**几何与透明度是两条曲线**：取消钮淡入落在线性 0.35…0.62（实测 208/250/292ms → 0.32/0.63/0.96）。
- `MiTopBar` 已改 Stateful，但构建体留在 widget 的 `_buildBar(context, progress)`：常规态插值退化为原值 → 非搜索页零像素变化。
- **坑1**：`late final _c = AnimationController(value: widget.x)` 的初始化器在**首次访问**才跑（多半已在 didUpdateWidget，widget 是新值）→ 出生即终态。**必须在 initState 建**。
- **坑2**：宿主 `Stack` 条件插入子级 → 兄弟按**下标**配对，后面的子树整体重建（State 重来）。**Stack 子级增删一律给 ValueKey**。

## 实测速查（dp @ 393 设计宽）
- 页底：亮 `#F3F3F3` / 暗 `#000000`；搜索栏灰：亮 `#E7E7E7` / 暗 `#242424`。
- MiPillTabBar：pill 87.6×39.9、gap/edge 11.9、标签 13.85 w500。
- MiButton：`#4980F7`（明暗同色）、高 28.3、左右 17、13dp w500、stadium；列表行距 56.1。
- MiSearchBar：高 44.1、inset 15.4、icon 17.8（笔画 1.8/镜片 6.9/r6.0）、gap 12、字 16.5 w400；填充 alpha 亮 13 / 暗 36，backdrop sigma 28；hint 亮 `#848484`/暗 `#6D6D6D`，icon `#9A9A9A`。
- MiGlassNavBar：栏 342×55.4、边距 25.5、格宽 82.2、内边距 6.6、pill 竖 inset 3.05 → pill 宽 89.3、icon 高 23.2、icon→label 5.5、label 10.5 w500；fab ⌀55.4、gap 11.9；飞行 easeOutSine 260+20/cell ms + settle 350（overshoot .037 cell、squash .022）、按压 90ms。
- MiThemeCard：预览图 259:472≈0.549（有界父级内 AspectRatio 必铺满）、圆角 20（拟合 19.6）、标题 13.85 w500 左对齐内缩 8.8、图→题 8 / 行距 15 / 列距 11.9；页面双轨页边距 = 壳层 11.9 + 文本列 20.5（区块标题 inset 8.6）。
- **玻璃膜（压在内容上的搜索栏 / 未选胶囊，`overContent`）**：亮 = 页底 #F3F3F3 @117/255(0.46)、暗 = 纯黑 @150/255(0.59)。实测依据：胶囊内侧 vs 同 y 间隙 亮 200/167（+33）、暗 70/170（−100）；模糊不改局部均值，落差只能来自膜。平底页那档 onSurface@6% 是**另一状态**，两态不可互推。复核我们预览：亮 +36、暗 −72。

## MiTopBar（带头部区 / 大标题折叠双形态）
- 返回圆钮 ⌀44.1 / 左 11.9 / 垂心 76.0，箭头墨盒 11.68×21.31（笔宽 2.05、墨心左偏 1.3）；大标题 31.83（墨左 29.6 / 墨心 y 132.9）、紧凑标题 18.0（屏心 / 墨心 y 75.9）；按压圆盘 白@9.4% 420ms 淡入 / 300ms 淡出。
- 内容首行顶缘两档（都实测，不归一）：卡片类 `contentTopInset` 183.0、搜索栏类 `searchBarTopInset` 168.5（demo 首页用后者）。
- `showBack` 默认 false；它同时决定紧凑标题对称内缩（`backInset+backDiameter`）。
- 标题墨心靠 `Baseline(baselineType: alphabetic, baseline: 墨心+0.355em)` 钉死；组件高 = 大标题墨心 + 一行定值。本 SDK(@3.47.5) `StrutStyle` 无 ascent/descent、`TextStyle.height` 只等比缩放 → 别再退回 em 换算。
- 折叠：大标题属滚动内容（1:1 上移）+ 独立淡出（0→19.97 归零）；紧凑标题 19.97→29.31 才淡入。
- **材质两套规律（都实测）**：① 纯标题/无头部 = 渐进曲线 σ 5.37(0…35)→4.96(50)→4.34(67.5)→1.85(90)→0.76(103)→0(119dp)，`visibleBlurBands(extent:,underSurface:)` 等比拉伸、栏底归零；② **头部区（搜索栏+胶囊行）= 恒定 σ 5.37 铺满 0…`occupiedHeight`(156dp)、栏底硬切**（`uniformBlurBands`）。依据：搜索栏行/间隙/胶囊行后方糊得一样重，胶囊底缘 150…152dp 以下立刻锐利；照渐进曲线拉到 156dp 时胶囊处只剩 σ≈2.5。
- **两个独立开关**：`showBlur` 控磨砂（内容区自己的顶部渐进模糊，无顶栏页照样糊），`showSurface` 只控叠色（浅色 #F3F3F3 @0.650 顶→0@122.4dp；深色不动）。分类页 = 糊但无压色；真机「上半段纯黑」是叠色 α=1。
- **`overContent`**（默认 false）= 头部区压在照片/视频上：内置搜索栏与未选胶囊改用玻璃膜（见实测速查），与 `showBlur` 是两件事（分类页同样开磨砂但底色是平的）。demo 首页传 true。
- **头部区由顶栏自产**：`searchHint`/`onSearchTap` → 内部 `MiSearchBar`；`tabs`/`selectedTab`/`onTabChanged` → 内部 `MiPillTabBar`（须显式下发 themeMode，其默认 deep）。换皮才用插槽 `searchBar`/`tabBar`/`header`；互斥靠构造期断言，口径 `hasSearchBar`/`hasTabBar`/`hasHeaderSlot`。**不是页面 new 好传进来**（用户 2026-10-17 反馈命中）。
- `MiTopBarMetrics`：`headerTopInset` 56（`headerTopInsetFor(safeAreaTop)` 取大者）、`searchBarGap` 16、`headerContentGap` 12、`headerInset` 11.9、`searchBarSlotHeight` 44.1、`tabBarSlotHeight` 39.9（= 零件 metrics，测试钉住）；插槽高是声明值，宿主用 `occupiedHeight(context)` 让位。
- 材质层是**盖在整栏上的底**（`Stack`+`Positioned(height: materialExtent)`），不占布局高。`titleExtent` 在「有头部区且无标题」时为 0，否则材质盒把搜索栏下推 128.9。内置零件传 `frosted: false`，全栏只糊一次。**胶囊行必须满宽**（自带 edgeInset + 出血滚动），只有搜索栏吃 `headerInset`。

## 性能：每帧模糊预算
- **`BackdropFilter` = 每帧全 QUAD 高斯**，滚动掉帧几乎全在这。口径 = 一次 build 的**层数 + 覆盖面积 dp²**，钉在 `test/perf_budget_test.dart`。
- 平板 768×1280 深色：首页/我的 10 层/100,073 → 6~7 层；分类 6→**3 层**；头部区形态恒定 σ 后 **3 层**（σ 段 8→1）。优化：① 深色顶栏跳过 0…63.6（scrim α=1）② 胶囊行 4 filter→1（`_CapsuleStripClipper`）③ `ImageFilter` 按 σ 缓存（`src/utils/filter_cache.dart`）+ 跳过 σ<0.5。
- **恒定 σ 的代价**：层数降但面积升（要算满整栏）——一次大 filter 比多次小 filter 便宜。
- **切 tab 不做 fade**：任何含磨砂子树都不要套 Opacity/FadeTransition（引入 saveLayer → backdrop 变空 + 双份全宽高斯）。
- 「感觉丢帧」先排除 debug 模式，用 `flutter run --profile` + `dumpsys gfxinfo`。

## 已知坑：模糊 / 材质
- **`BackdropFilter` 被任何半透明遮罩包住就失效**：`ShaderMask`（含 <1 alpha gradient）/ `Opacity` 都引入新 saveLayer → backdrop 变空、恢复锐利（alpha 恒 1 的 ShaderMask 仍能糊）。故渐进模糊只能**分段定 σ 并列**（段间 σ 比 ≤1.5、段高 ≤17dp 时台阶不可见）。回归测试断言「MiTopBar 下不得出现 ShaderMask」。
- **平坦色块判不了有没有模糊**：模糊不改平坦区亮度。要用高频内容（照片边缘/文字笔画）并量边缘宽度。`matchesGoldenFile(finder)` 只截该子树 → 模糊源必须在被截子树内。
- **σ 与叠色 α 在窄窗口耦合退化**（<3σ 解出假 α≈0.6）。替代：① 频谱比 `log(Ŝ₁/Ŝ₀) = −2π²σ²f² + 2log(1−α)`（斜率只含 σ）② 带外帧平坦区反解 α ③ m<1 混合剖面 10-90 宽度收敛到 2.08σ。
- 纵向滚动录屏里竖直边缘（水平剖面）不受运动模糊影响 → 测模糊优先取图标/头像左右缘。
- **判据别被描边骗**：量卡片填充顶缘用色差阈值会先撞描边（曾误报 177.17，真值 183.0）；沿列剖面找单行硬跳变。

## 已知坑：布局
- **网格断点必须按「容器宽」标定**：舞台 1000 − 48 页边距 = 952 < 1024，沿用窗口断点会永远 medium（实拍 4 列）。
- **`MiPillTabBar` 在宽父级里会居中**（横向 ScrollView shrink-wrap + Column 默认 center）→ 宽屏包 `Align(centerStart)`。
- **全屏页壳的 Stack 子级一律 `Positioned`**：有非定位子级时 Stack 收缩到该子级尺寸，遇 loose 上级整页被居中 → 顶栏跑到屏幕正中（实测偏移 351.6dp）。
- `Container`/`Align` 带 `alignment` 在有界父级会拉满宽；内容自适应用 `Center(widthFactor: 1.0)`。
- 叠在内容上的透明层要包 `IgnorePointer`（否则吃下层点击），且必须包在 `GestureDetector` **外层**（后者 `behavior.opaque` 自身吃命中）。
- **布局类断言别用 `Column` 撑溢出**：比容器高的 mock 内容用 `Stack`+`Positioned` 逐行摆，行距并进 `top`。
- **`Container.clipBehavior` 不要在状态间切**：`Clip.antiAlias ↔ Clip.none` 增删裁剪层 → 子级 Element 重建（本项目表现为跨断点滚动位置归零）。固定 `Clip.antiAlias`，用 `BorderRadius.zero` + 空 `boxShadow` 表达「无卡片」（像素无差）。
- **给已截图界面加外壳层要零新增 render object**：套 `Padding`/垫 `ColoredBox` 会让黄金图出现噪声差。正确做法 = `Positioned(left: …)` 改几何、容器自身颜色改底色 —— 紧凑档逐像素不变。

## 已知坑：字体与基线
- 墨心在基线上方 `k ≈ 0.355em` 跨字体很稳；基线在行盒内位置只能由字体度量决定 → 用 `Baseline` 让框架布局期求解。
- **`Baseline` 语义**：基线距自己 box 顶端 N，`size.height = (N − 子级基线距) + 子级高`（无 clamp）；无界高时 dy=0。
- **测试字体 CJK advance ≠ 1em**：「关注」13dp 实测宽 26.5。锁「内边距+收缩到内容」断言 `btn.width == text.width + 2*padding`。
- **行盒高被引擎向上取整**：31.83 + height 1.0 → 32.0，容差别写 0.01。

## 已知坑：测试与流程
- **改了几何 token 预览图逐字节不变 = 有代码自算几何绕过 token**（如 painter 里 `Radius.circular(size.width/2)`）；ClipRRect 半径改小也裁不到像素。先 grep 自算点，再用 PIL `ImageChops.difference(...).getbbox()` 定位差异区。
- **`test/` 不参与 app 构建**：动过 `test/` 至少跑一次 `dart analyze`（`C:\src\flutter\bin\dart.bat`，0 error 才算过）。
- 构造期断言在 `harness()` 同步构造时就抛 → `expect(() => harness(...), throwsA(isA<AssertionError>()))`。
- **`getDistanceToBaseline` 不能在测试体里调** → 断言 `tester.widget<Baseline>(...).baseline`。
- **`MaterialApp.theme` 是 `AnimatedTheme`(200ms)**：换 theme 当帧 brightness 仍是旧值 → `pump(300ms)`。
- `const` 构造断言不能求值 `.length`（数量校验放 initState）。
- 预览图位移用 `ScrollableState.position.jumpTo`（drag 带惯性不可复现）。

## 工具
- 像素测量脚本 `.workbuddy/measure_*.py`（PIL，非交付物，不入库）；本机 venv `C:\Users\zmt\.workbuddy\binaries\python\envs\default\Scripts\python.exe`。
