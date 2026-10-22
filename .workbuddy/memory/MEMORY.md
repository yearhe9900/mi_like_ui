# mi_like_ui_demo 项目笔记

> 细节过程见 `.workbuddy/memory/YYYY-MM-DD.md`；本文件只留**长期有效的约定、度量、坑**。

## 约定
- 对外只经 barrel `lib/mi_like_ui.dart`；组件 `src/components/<类别>/<组件名>/`，类 `Mi` 前缀、文件 snake_case；颜色/文字/间距走 `src/theme/` token，组件内不写字面量。
- **透明参数只有一个来源**：`src/theme/transparency_tokens.dart`。其它文件只引用常量，**alpha 保持原生表达**（0.63 别写成 161/255，否则黄金图漂）。守门测试 `transparency_config_test.dart` 扫源码（含「配置自身必须带字面量」防空转）；色值/σ 表在统一配置，几何（stops、段高）留各 palette。
- **实测优先**：视觉参数 1:1 从参考素材量；素材没有的样式只能推导，标「推导（非实测）」+ 写明来源。
- 每个任务完成即 commit（精确路径 add，绝不 `git add .`）；改样式后 `flutter test --update-goldens test/preview_capture_test.dart`；工作区不留未提交改动。`analyze`/`test` 由 agent 代跑，build/adb 只给命令文本。
- **CHANGELOG 只写发布级变更**：一条 1~2 行（改了什么 + 为什么），不写实测出处、像素/拟合数据、测试例数、预览图清单、实现细节；细节留 README / 注释 / memory。
- **对外口径**：README / CHANGELOG / pubspec / 公共 dartdoc 用「设计度量 / 推导值 / 参考素材」术语与专业 API 文档口吻；**不写过程叙事**（日期、用户反馈、踩坑、黄金图、判据、内部项目名）。

## 响应式（`src/utils/responsive.dart`）
- **三处断点各管一件事**：① 窗口宽 `MiViewport/ofWidth`（compact<600 / medium 600…1023 / expanded≥1024）→ 外壳是否加宽；② **画面容器宽** `usesSideNav(w)=w>600` → 底栏 vs 侧栏；③ **内容容器宽** `MiResponsiveGrid.compactMax/mediumMax`（示例 520/800）→ 列数。混用会错：限宽画布够不到窗口断点。
- `MiScaledCanvas.scaleFor = clamp(min(1, 可用宽/设计宽, 可用高/设计高))`：只缩不放、等比；`scale==1` 走原样路径（零变换层）。
- `DemoStage`（demo_app，`sizeFor(Size)→{logical,rendered}` 可单测）：**只有 compact 是物理手机**（等比 393×856），medium/expanded 铺满窗口（无留白/圆角/投影/宽度上限）。内容断点：主题卡 3/4/6、展示位 4/6/8；页边距 非 compact 24、compact 11.9/20。

## 宽屏侧栏 `MiGlassSideNavBar`
- 判定：`LayoutBuilder` 读**外壳自己** `constraints.maxWidth > 600` → 平板也用侧栏；`MiBreakpoints.desktop`(1024) 只给桌面专属样式。与底栏共用 items/selectedIndex/onTap + 全部动效 token（只换轴）。
- **几何全「推导（非实测）」**：栏宽 95.4 = 格宽 82.2 + 2×6.6、条目高 49.3、间距 8、留白 25.5；`railHeightFor(n)=2×6.6+n×49.3+(n−1)×8`（3 项 177.1）；胶囊中心 = `railInnerPad + itemHeight/2 + pitch×pos`（**不是** `pitch×(pos+0.5)`，否则整体下移 gap/2）；`railRadius = pillRadius + railInnerPad = 31.25`（内外圈四周恒 6.6，**不用 railWidth/2**）；fab 挂栏尾、栏体不让位。
- 示例：页面恒为 `Stack` 第一个 `Positioned(left: sideNav?gutter:0)` → 跨断点不重建、滚动保留；侧栏档外壳底色 = 页底色（否则深色竖缝）；**不自绘 Home 指示条**（edge-to-edge 系统自己画，自绘=两条）。
- **edge-to-edge**：`main.dart` `SystemUIMode.edgeToEdge` + `AnnotatedRegion<SystemUiOverlayStyle>`（透明状态栏/手势条、图标亮度随明暗）。不做的代价是系统画一条灰带（实测 250→183）。浮层让安全区：侧栏顶 `padding.top+25.5`、底栏底 **`max(24.2, padding.bottom)`**（24.2 量的是屏幕底缘、手势条已含在内 → 不叠加，叠加会到 45dp）。

## 搜索态①原地（`MiTopBar.searchActive`）
- 与②推入并存：原地态示例在「分类」页，推入在首页；`search_state_test` 外壳用例先点「分类」再点搜索栏。
- 换算 s 用**同帧搜索栏高** 66px→44.1dp 标定（别用屏宽标）。实测：栏 y 252…317 → 78…143（168.4→52.1dp），高不变 66px；左缘 21 不动、右缘 591→511；取消钮 ⌀66 = 栏高、距栏 15px、**右缘贴屏 0**（四数闭合 21+491+15+66=593≈592，圆纵向也 66 → 非裁切）。
- 取消钮：叉号墨盒 17.0 / 笔画 1.9；**墨色 = 前景墨色**（实测叉号 0、放大镜 167、hint 161 三档，不能共用 icon 灰）；填充 = 搜索栏填充。
- 光标：`MiColors.accent`、高 21.3 钉死、闪烁 500/500ms（= Flutter 默认，不用设）。
- 转场 **480ms = 前 10% 静止 + easeOutQuint**（mean|Δ| 0.008）；**几何与透明度两条曲线**：取消钮淡入落在线性 0.35…0.62。
- `MiTopBar` 改 Stateful，但构建体留在 widget 的 `_buildBar(context, progress)` → 常规态插值退化为原值，非搜索页零像素变化。
- **坑1**：`late final _c = AnimationController(value: widget.x)` 初始化器在**首次访问**才跑（常在 didUpdateWidget，widget 已新）→ 出生即终态，**必须 initState 建**。**坑2**：Stack 条件插入子级 → 兄弟按**下标**配对、后面子树整体重建 → **增删子级一律给 ValueKey**。

## 搜索态②推入转场 `MiCardPageRoute`（2026-10-22）
- 素材 1220×2656 @24.31fps，s = 1220/393 = 3.104。实测：新页左缘逐帧 `1220 1101 807 536 362 214 120 65 23 9 7 3 2 0` → **easeOutCubic + 400ms**（mean|Δ| 1.6dp）；**前缘圆角 R=190px=61.2dp**（`dx(y)=R−√(R²−(R−y)²)` 拟合，误差≤2px，全程恒定）；**下层页左移 0.25×屏宽×进度**（模板匹配 −30/−102px @ 0.09/0.35；横幅上缘 y 恒 536 → 不缩放）；**压暗 = 黑 scrim**（沿 x 平坦 0.63~0.66，不是投影），进度 0.35/0.55/0.70 → α 0.20/0.32/0.38，线性外推终值 **0.55**；**无投影**。
- 搜索页头部：行顶缘 52.2、圆钮 ⌀44.1 + 左 11.9、圆钮↔框 11.0、框高 44.1、框↔搜索钮 11.0、搜索钮 **53.5×40.9**（右缘 12.6）；**输入框无放大镜**、占位缩进 12.6、hint 165 / 搜索钮墨 0；箭头墨迹 = `MiTopBarMetrics.chevron*`。
- **一个路由两种角色**（`buildTransitions`）：`secondary != dismissed` → 「被压住」只做左移视差；否则 → 「进入」全屏压暗 + 横向滑入 + ClipRRect 圆角。`visual >= 1` 直接返回 child（**零图层**）。
- **压暗由上层画**（`Stack[全屏半透明 ColoredBox, 滑入页]`，不挑下层路由类型）；**视差只能由下层画**（`secondaryAnimation` 钩子，平台路由没有）→ 示例根路由也换成本类（`MaterialApp.onGenerateRoute` + `initialRoute`），否则 Android Zoom 会自己缩放退出页。`home:` 换 `onGenerateRoute` 后主题切换仍生效（builder 读 `_mode` 字段，非捕获值）。
- 圆角参考实现全程恒定（进度 0.998 仍 190px，归位那帧消失）；本库「归位即归零」——此时新页铺满、下层不再画，缺口不露。

## 实测速查（dp @ 393 设计宽）
- 页底：亮 `#F3F3F3` / 暗 `#000000`；搜索栏灰：亮 `#E7E7E7` / 暗 `#242424`。
- MiPillTabBar：pill 87.6×39.9、gap/edge 11.9、标签 13.85 w500。
- MiButton：`#4980F7`（明暗同色）、高 28.3、左右 17、13dp w500、stadium；列表行距 56.1。
- MiSearchBar：高 44.1、inset 15.4、icon 17.8（笔画 1.8/镜片 6.9/r6.0）、gap 12、字 16.5 w400；填充 alpha 亮 13 / 暗 36、backdrop σ28；hint 亮 `#848484`/暗 `#6D6D6D`，icon `#9A9A9A`。
- MiGlassNavBar：栏 342×55.4、边距 25.5、格宽 82.2、内边距 6.6、pill 竖 inset 3.05 → pill 宽 89.3、icon 高 23.2、icon→label 5.5、label 10.5 w500；fab ⌀55.4、gap 11.9；飞行 easeOutSine 260+20/cell ms + settle 350（overshoot .037 cell、squash .022）、按压 90ms。
- MiDialog：卡宽 369.2（边距 11.9）/ 圆角 49.3（正圆）/ 底距屏 32.9 / 无投影；标题 18.0（墨心 36.4）、正文 15.9（行距 23.2、墨心行1 75.55、内缩 28）、按钮盒 133..183（高 49.9）圆角 15.0、行内缩 24.2、gap 12.6、底留白 24.1、标签墨心=盒心；卡高 = 133+(行数−2)×23.2+49.9+24.1。色：卡 #242424/#FFF、中性钮 #434343/#F0F0F0、主钮 #478AFF/#3383FF、破坏红 #DA5244、次级字 纯白/黑@0.80、遮罩黑 @0.20(亮)/@0.60(暗)；按压 = 填充叠色 黑/白@0.12（150ms easeOutQuad，标签不变、不缩放）。
- MiThemeCard：预览图 259:472≈0.549（有界父级内 AspectRatio 必铺满）、圆角 20（拟合 19.6）、标题 13.85 w500 左对齐内缩 8.8、图→题 8 / 行距 15 / 列距 11.9；页面双轨页边距 = 壳层 11.9 + 文本列 20.5（区块标题 inset 8.6）。
- **玻璃膜（`overContent`，压在内容上的搜索栏/未选胶囊）**：亮 = 页底 @117/255(0.46)、暗 = 纯黑 @150/255(0.59)。依据：胶囊内侧 vs 同 y 间隙 亮 200/167（+33）、暗 70/170（−100）；模糊不改局部均值，落差只能来自膜。平底页那档 onSurface@6% 是**另一状态**，不可互推。

## MiTopBar（头部区 / 大标题折叠）
- 返回圆钮 ⌀44.1 / 左 11.9 / 垂心 76.0，箭头墨盒 11.68×21.31（笔宽 2.05、墨心左偏 1.3）；大标题 31.83（墨左 29.6 / 墨心 y 132.9）、紧凑标题 18.0（屏心 / 墨心 75.9）；按压圆盘 白@9.4%、420ms 入 / 300ms 出。
- 内容首行顶缘两档（都实测，不归一）：卡片类 `contentTopInset` 183.0、搜索栏类 `searchBarTopInset` 168.5。
- `showBack` 默认 false；它同时决定紧凑标题对称内缩。标题墨心靠 `Baseline(baseline: 墨心+0.355em)` 钉死，组件高 = 墨心 + 一行定值；本 SDK 的 `StrutStyle` 无 ascent/descent、`TextStyle.height` 只等比缩放 → 别退回 em 换算。
- 折叠：大标题属滚动内容（1:1 上移）+ 独立淡出（0→19.97 归零）；紧凑标题 19.97→29.31 才淡入。
- **材质两套规律**：① 纯标题/无头部 = 渐进曲线 σ 5.37(0…35)→4.96(50)→4.34(67.5)→1.85(90)→0.76(103)→0(119)，`visibleBlurBands` 等比拉伸、栏底归零；② **头部区 = 恒定 σ5.37 铺满 0…`occupiedHeight`(156)、栏底硬切**（`uniformBlurBands`）——分类页拉伸渐进曲线时胶囊处只剩 σ≈2.5。
- **两个独立开关**：`showBlur`（内容区顶部渐进磨砂，无顶栏页照样糊）、`showSurface`（顶栏压色：浅 #F3F3F3 @0.650→0@122.4；深色不动）。分类页 = 糊但无压色；「上半段纯黑」是叠色 α=1。
- **头部区由顶栏自产**：`searchHint`/`onSearchTap` → 内部 `MiSearchBar`；`tabs`/`selectedTab`/`onTabChanged` → 内部 `MiPillTabBar`（须显式下发 themeMode，其默认 deep）。换皮才用插槽 `searchBar`/`tabBar`/`header`；互斥靠构造期断言，口径 `hasSearchBar`/`hasTabBar`/`hasHeaderSlot`。**不是页面 new 好传进来**。
- `MiTopBarMetrics`：`headerTopInset` 56（`headerTopInsetFor(safeTop)` 取大者）、`searchBarGap` 16、`headerContentGap` 12、`headerInset` 11.9、slot 高 44.1/39.9（= 零件 metrics，测试钉住）。材质层是**盖在整栏上的底**（`Stack`+`Positioned`），不占布局高；`titleExtent` 在「有头部区无标题」时为 0；内置零件传 `frosted:false`；**胶囊行必须满宽**（自带 edgeInset 出血），只有搜索栏吃 `headerInset`。

## 性能：每帧模糊预算
- **`BackdropFilter` = 每帧全 QUAD 高斯**，口径 = 一次 build 的**层数 + 覆盖面积 dp²**，钉在 `test/perf_budget_test.dart`。平板 768×1280 深色：首页/我的 10 层/100,073 → 6~7 层；分类 6→3；头部区恒定 σ 后 3 层（σ 段 8→1）。
- 优化：① 深色顶栏跳过 0…63.6（scrim α=1）② 胶囊行 4 filter→1（`_CapsuleStripClipper`）③ `ImageFilter` 按 σ 缓存（`utils/filter_cache.dart`）+ 跳过 σ<0.5。**恒定 σ 的代价**：层数降、面积升 —— 一次大 filter 比多次小 filter 便宜。
- **任何含磨砂的子树都不要套 `Opacity`/`FadeTransition`/`ShaderMask`**：引 saveLayer → backdrop 变空、磨砂消失 + 双份全宽高斯。切 tab / 底栏显隐 / 转场压暗一律**换结构或纯色填充**。
- 「感觉丢帧」先排除 debug 模式：`flutter run --profile` + `dumpsys gfxinfo`。

## 已知坑：测量与判据
- **平坦色块判不了有没有模糊**（模糊不改平坦区亮度）→ 用高频内容（照片边缘/文字笔画）量边缘宽度；`matchesGoldenFile(finder)` 只截该子树，模糊源必须在内。
- **σ 与叠色 α 在窄窗口耦合退化**（<3σ 解出假 α≈0.6）→ 频谱比 `log(Ŝ₁/Ŝ₀)=−2π²σ²f²+2log(1−α)`（斜率只含 σ）／带外平坦区反解 α／m<1 剖面 10-90 宽 = 2.08σ。
- 纵向滚动录屏里竖直边缘（水平剖面）不受运动模糊影响 → 优先取图标/头像左右缘。
- **判据别被描边骗**：色差阈值会先撞描边（曾误报 177.17，真值 183.0）→ 沿列剖面找单行硬跳变。
- 转场里「是不是缩放」用**另一轴的固定特征**判（横幅上缘 y 恒 536 即不缩放）；「是不是阴影」看压暗**沿 x 是否平坦**（平坦 = scrim，衰减 = 投影）。

## 已知坑：布局
- **无 child 的 `DecoratedBox`/`Container` 在松约束下取 `constraints.smallest`**（交叉轴松 → 宽 0、整块隐形且不报错）→ 加 `child: SizedBox.expand()` 或给紧约束。
- **网格断点按「容器宽」标定**：舞台 1000 − 48 = 952 < 1024，沿用窗口断点会永远 medium。
- **`MiPillTabBar` 在宽父级里会居中**（横向 ScrollView shrink-wrap + Column center）→ 宽屏包 `Align(centerStart)`。
- **全屏页壳的 Stack 子级一律 `Positioned`**：有非定位子级时 Stack 收缩到该子级尺寸，遇 loose 上级整页居中（实测偏移 351.6dp）。
- `Container`/`Align` 带 `alignment` 在有界父级会拉满宽；内容自适应用 `Center(widthFactor: 1.0)`。
- 叠在内容上的透明层要包 `IgnorePointer`，且包在 `GestureDetector` **外层**（后者 behavior.opaque 自身吃命中）。
- **布局类断言别用 `Column` 撑溢出**：比容器高的 mock 用 `Stack`+`Positioned` 逐行摆，行距并进 `top`。
- **`clipBehavior` 不要在状态间切**（`antiAlias ↔ none` 增删裁剪层 → 子级 Element 重建，表现为跨断点滚动位置归零）：固定 `antiAlias`，用 `BorderRadius.zero` + 空 `boxShadow` 表达「无卡片」。
- **给已截图界面加外壳层要零新增 render object**：套 `Padding`/垫 `ColoredBox` 会让黄金图出现噪声差 → 改 `Positioned` 几何 + 容器自身颜色。

## 已知坑：字体与基线
- 墨心在基线上方 `k ≈ 0.355em` 跨字体稳；基线在行盒内位置只能由字体度量决定 → 用 `Baseline` 让框架布局期求解。`Baseline` 语义：`size.height = (N − 子级基线距) + 子级高`（无 clamp）。
- **测试字体 CJK advance ≠ 1em**（「关注」13dp 实测 26.5）→ 锁「收缩到内容」写 `btn.width == text.width + 2*padding`。
- **行盒高被引擎向上取整**：31.83 → 32.0，容差别写 0.01。

## 已知坑：测试与流程
- **`Unable to connect to flutter_tester ... Invalid WebSocket upgrade request` ≠ 代码问题**：`HTTP_PROXY` 劫持本地 WebSocket，跑测试一律加 `NO_PROXY=localhost,127.0.0.1`。
- **改了几何 token 而预览图逐字节不变 = 有代码自算几何绕过 token**（如 painter 里 `Radius.circular(size.width/2)`）→ 先 grep 自算点，再用 `ImageChops.difference().getbbox()` 定位差异区。
- 动过 `test/` 至少跑一次 `dart analyze`（0 error 才算过）。断言速记：构造期断言用 `expect(() => harness(...), throwsA(isA<AssertionError>()))`；`getDistanceToBaseline` 不能在测试体里调 → 断 `Baseline.baseline`；`MaterialApp.theme` 是 200ms `AnimatedTheme` → `pump(300ms)`；`const` 断言不能求值 `.length`；位移用 `position.jumpTo`（drag 带惯性不可复现）。
- **路由转场**：`push` 后要 **pump 两帧**页面才挂上；`getTopLeft/getRect` **会应用祖先变换**（可直接量 `FractionalTranslation`/`Transform` 后的位置）；上层是不透明路由时下层页 **offstage** → `find.byType(..., skipOffstage: false)`；量容器左缘别用内部 `TextField`（会多算内缩）。
- 截含光标的页面**不能 pumpAndSettle**（光标闪烁是永不停歇的定时器）→ 固定 pump 到确定时长。

## 工具
- 像素测量脚本 `.workbuddy/measure_*.py` / `extract_*.py` / `fit_*.py`（PIL，非交付物，不入库）；本机 venv `C:\Users\zmt\.workbuddy\binaries\python\envs\default\Scripts\python.exe`（`imageio.v3` + `imageio_ffmpeg` 可抽帧，无 ffmpeg 在 PATH）。
