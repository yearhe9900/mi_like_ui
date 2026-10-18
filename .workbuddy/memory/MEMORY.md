# mi_like_ui_demo 项目笔记

## 架构与约定
- **顶部渐进模糊已独立成组件 `MiGradientBlur`**（`src/components/effects/gradient_blur/`，不再只归顶栏）：曲线 token 在 `theme/gradient_blur_tokens.dart`（`MiGradientBlurProfile`），`MiTopBar.showBlur` 内部复用；`bandsFor(extent:)` 把 119dp 曲线等比拉到作用区并在底归零，`underSurface: false` 时不得跳过被压色遮住的段。
- 对外只经 barrel `lib/mi_like_ui.dart`（新增组件/token 记得补 export）；组件放 `src/components/<类别>/<组件名>/`，类 `Mi` 前缀、文件 snake_case；颜色/文字/间距一律走 `src/theme/` token，组件内不写字面量。
- **实测优先**：视觉参数 1:1 从参考截图像素量；参考图没有的样式（禁用态、桌面侧栏等）只能推导，必须在 doc comment 标「推导（非实测）」+ 写明取值来源。
- 节奏：每个任务完成即 git commit；`flutter analyze` / `flutter test` 由 agent 执行（用户 2026-10-17 明确）；工作区不留未提交改动。改样式后必须 `flutter test --update-goldens test/preview_capture_test.dart`。

## 响应式（`src/utils/responsive.dart`）
- **三处断点各管一件事**：① 窗口宽 `MiViewport` / `ofWidth`（compact<600 / medium 600…1023 / expanded≥1024）→ 外壳是否把画面加宽；② **画面容器宽** `MiBreakpoints.usesSideNav(w) = w > 600` → 导航形态（底栏 vs 侧栏，见下）；③ **内容容器宽** `MiResponsiveGrid.compactMax/mediumMax` → 网格列数。混用会出错（限宽画布够不到窗口断点；手机框嵌宽窗口不该摆侧栏）。
- `MiScaledCanvas.scaleFor = clamp(min(1, 可用宽/设计宽, 可用高/设计高), minScale, maxScale)`：只缩不放、宽高同比例；`scale == 1` 走原样路径（零变换层，黄金图像素稳定）。
- 示例外壳 `DemoStage`（demo_app.dart，纯函数 `DemoStage.sizeFor(Size)→{logical,rendered}` 可单测）：**只有 compact 是"物理手机"**（等比缩 393×856，手机全屏 1:1）；**medium/expanded = 铺满窗口**（画面 = 可用尺寸，2026-10-18 平板实拍反馈「应该铺满屏幕，不需要外围卡片」后去掉 24 留白 / 圆角 56 / 投影 / 宽度上限 1000，`wideMaxWidth`·`minStageHeight`·`gutter` 已删）。
- 内容断点：主题卡 3/4/6 列、展示位 4/6/8 列；非 compact 页边距统一 24（compact 用实测 11.9/20）。
- **宽屏模式（2026-10-18，`MiGlassSideNavBar`）**：判定照 MReader 主壳层（`MReader/lib/ui/home_shell.dart`）—— `LayoutBuilder` 读**外壳自己的 `constraints.maxWidth`**，`> kShellRailBreakpoint`（**600**）切侧栏（`MiBreakpoints.navRail` + `usesSideNav(width)`，严格大于；`MiWindowSize.usesSideNav` 是枚举口径）。所以**平板也用侧栏**、只有手机/窄窗留底栏；`MiBreakpoints.desktop`（1024）只留给桌面专属样式（舞台加宽/网格 6-8 列）。侧栏与底部栏**共用 `MiGlassNavItem` / `selectedIndex` / `onTap`**（示例传同一份 items）→ 图标、选中态、跳转零差异；动效 token 也全复用（只把轴换纵向）。
  - **几何全部「推导（非实测）」**（无侧栏样张）：栏宽 95.4 = 实测格宽 82.2 + 2×内边距 6.6、条目高 49.3 = 实测胶囊高、条目间距 8（spaceSm）、左/顶留白 25.5 = `barMarginH`；图标墨盒/间距与底栏一字不改。`railHeightFor(n) = 2×6.6 + n×49.3 + (n−1)×8`（3 项 = 177.1）。
  - 胶囊中心 = `railInnerPad + itemHeight/2 + pitch×pos`（**不是** `pitch×(pos+0.5)`，否则整体下移 gap/2 = 4dp）；pitch = itemHeight + gap；首尾按 `railInnerPad` 夹紧。
  - 刻意的两处差异：**fab 挂栏尾下方、栏体不让位**（2026-10-18 起侧栏支持 `MiGlassNavFab`，与底栏同显隐契约；直径 55.4 / 间距 11.9 沿用实测，槽位恒定预留零跳动）；**栏体收缩到内容高、位置由宿主给**（示例贴顶 25.5 + 左 25.5）。
  - **内外圈等距（2026-10-18，用户反馈「以内圈为准」）**：栏体圆角 `railRadius = pillRadius + railInnerPad` = 31.25（不是 railWidth/2）——端头圆弧与胶囊顶角同心、间距四周恒 6.6；旧 stadium 与内圈不同心，肩部间距收缩到 0。**painter 曾自算 `size.width/2` 绕过 token，只改 metrics 预览图逐字节不变**（见「已知坑：测试与流程」）。
  - 示例布局：`DemoStage` 内套 `LayoutBuilder`，页面恒为 `Stack` 第一个 `Positioned`（`left: sideNav ? gutterWidth : 0`），仅改左缘 → 跨断点切换 `Element` 不重建、滚动位置保留；侧栏档外壳底色改成页底色（否则深色下 gutter 与页面之间有一道竖缝）。手机 Home 指示条只在底栏形态出现。
  - 预算（铺满后）：桌面 1366×768 深色首页 **7 层 / 137,506**、分类 8/194,809（页面列 1245.1 + 侧栏 1 层 16,896）；平板 768×1280（页面列 647.1）首页 7/78,562、我的 6/52,142、分类 8/109,360。层数不变，**面积随宽度线性增长**（edge-to-edge 的必然代价）。
  - **edge-to-edge**：`main.dart` 调 `SystemChrome.setEnabledSystemUIMode(edgeToEdge)`，`DemoHome` 用 `AnnotatedRegion<SystemUiOverlayStyle>`（透明状态栏/手势条 + 图标亮度随明暗）。不做的话应用窗口从状态栏下方开始，那一条是系统画的底色+压色（实测 250→183）= 平板上的「灰带」。代价：侧栏顶 = `padding.top + 25.5`、底栏底 = `24.2 + padding.bottom`、Home 指示条同款；顶栏本来读 `MediaQuery.padding.top`。

## 实测速查（dp @ 393 设计宽）
- 页底：亮 `#F3F3F3` / 暗 `#000000`；搜索栏灰：亮 `#E7E7E7` / 暗 `#242424`。
- MiPillTabBar：pill 87.6×39.9、gap/edge 11.9、标签 13.85dp w500。
- MiButton：`#4980F7`（明暗同色）、高 28.3、左右 17、标签 13dp w500、stadium；列表行距 56.1。
- MiSearchBar：高 44.1、inset 15.4、icon 17.8（笔画 1.8/镜片 6.9/r6.0）、gap 12、字 16.5dp w400；填充 alpha 亮 13 / 暗 36（专档），backdrop sigma 与导航栏同源 28；hint 亮 `#848484`/暗 `#6D6D6D`，icon `#9A9A9A`。
- MiGlassNavBar（`glass_nav_bar_metrics.dart`）：栏 342×55.4、边距 25.5、格宽 82.2、内边距 6.6、pill 垂直 inset 3.05 → pill 宽 = cellW+2(6.6−3.05)=89.3、icon 高 23.2、icon→label 5.5、label 10.5dp w500；fab ⌀55.4、gap 11.9；飞行 easeOutSine 260+20/cell ms + settle 350ms（overshoot 0.037 cell、squash 0.022）、按压 90ms。
- MiThemeCard：预览图 259:472≈0.549（有界父级内 AspectRatio 必铺满）、圆角 20（拟合 19.6）、标题 13.85dp w500 左对齐内缩 8.8、图→题 8 / 行距 15 / 列距 11.9；页面双轨页边距 = 壳层 11.9 + 文本列 20.5（区块标题 inset 8.6）；themeMode 可空跟随环境。

## MiTopBar（大标题折叠顶栏）
- 返回圆钮 ⌀44.1 / 左 11.9 / 垂心 76.0，箭头墨盒 11.68×21.31（笔宽 2.05、墨心左偏 1.3）；大标题 31.83dp（墨左 29.6 / 墨心 y 132.9）、紧凑标题 18.0dp（屏心 / 墨心 y 75.9）；按压圆盘 白@9.4% 420ms 淡入 / 300ms 淡出。
- 内容首行顶缘两档（都实测，不归一）：卡片类 `contentTopInset` **183.0**、搜索栏类 `searchBarTopInset` **168.5**（demo 首页用后者）。
- `showBack` 默认 false（顶层页无返回）；它同时决定紧凑标题的对称内缩（`backInset+backDiameter`）。
- **标题墨心靠 `Baseline(baselineType: alphabetic, baseline: 墨心 + 0.355em)` 钉死**，组件高度 = 大标题墨心 + 一行定值（`componentHeight`）。本 SDK（C:\src\flutter @3.47.5）`StrutStyle` 无 `ascent/descent`，`TextStyle.height` 只等比缩放 → 行盒内基线位置改不了，别再退回 em 换算。
- 折叠：大标题属于滚动内容（1:1 上移）+ 独立淡出（0→19.97 归零）；紧凑标题 19.97→29.31 才淡入，两段不重叠。
- **材质 = 渐进磨砂 + 叠色**（亮色「我的」页录屏实测）：栏顶 `blurSigma` 5.37，实测 σ(y)=5.37(0…35) → 4.96(50) → 4.34(67.5) → 1.85(90) → 0.76(103) → 0(119dp)；实现 = 分段定 σ 阶梯（`blurBands`，每段 `ClipRect+BackdropFilter`）。曲线形状固定、范围跟栏高走：`visibleBlurBands(extent:, underSurface:)` 把 119dp 曲线等比拉到材质盒（无头部 128.9 / 有头部 occupiedHeight），栏底归零。浅色叠色 #F3F3F3 @0.650(顶)→0(122.4dp)；深色不动。
- **两个独立开关**：磨砂是**内容区自己的顶部渐进模糊**（无顶栏的页面照样糊），`showBlur` 控它；`showSurface` 只控叠色。分类页 = `showBlur: true` + `showSurface: false`（整条栏都能看见模糊、无压色）。真机「上半段纯黑」是叠色 α=1 而非模糊。
- **头部区由顶栏自产**：声明式入参 `searchHint`/`onSearchTap` → 内部构造 `MiSearchBar`；`tabs`/`selectedTab`/`onTabChanged` → 内部构造 `MiPillTabBar`（必须显式下发 `themeMode`，其默认 deep）。换皮才用插槽 `searchBar`/`tabBar`/`header`。互斥由构造期断言保证；判定口径 `hasSearchBar`/`hasTabBar`/`hasHeaderSlot`。
  - 几何 `MiTopBarMetrics`：`headerTopInset` 56（`headerTopInsetFor(safeAreaTop)` 取大者）、`searchBarGap` 16、`headerContentGap` 12、`headerInset` 11.9、`searchBarSlotHeight` 44.1、`tabBarSlotHeight` 39.9（与零件 metrics 同值，测试钉住）。插槽高度是**声明值**，宿主用 `bar.occupiedHeight(context)` 让位 —— 两侧同源才不错位。
  - **「纳入组件内部统一渲染」= 顶栏自产组件**，不是页面 new 好传进来（用户 2026-10-17 反馈命中）；插槽是逃生口。
  - 材质层是**盖在整条顶栏上的底**（`Stack`+`Positioned(height: materialExtent)`），不占布局高度。**两形态规律不同（都实测）**：纯标题 = σ(y) 递减阶梯；头部区 = 整条栏恒定 σ 5.37（`uniformBlurBands`，无"越往下越清晰"）。`titleExtent` 在「有头部区且无标题」时为 0，否则材质盒把搜索栏下推 128.9。内置零件由顶栏传 `frosted: false`，全栏只糊一次。
  - **胶囊行必须满宽**（不套 `headerInset`）：它自带 edgeInset 且横向出血滚动；搜索栏才吃 `headerInset`。

## 性能：每帧模糊预算
- **`BackdropFilter` = 每帧全 QUAD 高斯**，滚动掉帧几乎全出在这。口径 = 一次 build 的**层数 + 覆盖面积 dp²**，钉在 `test/perf_budget_test.dart`。
- 平板 768×1280 深色：首页/我的 10 层/100,073 → **6~7 层/47,081~76,716**；分类 6 层 → **3 层**。三条零视觉差异优化：① 深色顶栏跳过 0…63.6dp（scrim α=1）；② 胶囊行 4 个 filter → 1 个（`_CapsuleStripClipper`）；③ `ImageFilter` 按 σ 缓存（`src/utils/filter_cache.dart`）+ 跳过 σ<0.5dp。
- **切 tab 不做 fade**：`FadeTransition` 的 Opacity 引入 saveLayer → 下层 backdrop 变空、磨砂消失 + 双份全宽高斯。任何"切换动画"都不要给含磨砂的子树套 Opacity。
- "感觉丢帧"先排除 debug 模式（开销数倍），用 `flutter run --profile` + `dumpsys gfxinfo`。

## 已知坑：模糊 / 材质
- **`BackdropFilter` 被任何半透明遮罩包住就失效**：`ShaderMask`（含 <1 alpha 的 gradient）/ `Opacity` 都引入新 saveLayer → backdrop 变空、整段恢复锐利（alpha 恒 1 的 ShaderMask 仍能糊，Skia 会优化掉）。所以渐进模糊只能**分段定 σ 并列**（段间 σ 比 ≤1.5、段高 ≤17dp 时台阶不可见）。回归测试断言「MiTopBar 下不得出现 ShaderMask」。
- **平坦色块判不了"有没有模糊"**：模糊不改平坦区亮度。要判必须用高频内容（照片边缘/文字笔画）并量**边缘宽度**。golden 里模糊是生效的，但 `matchesGoldenFile(finder)` 只截该子树 → 模糊源必须在被截子树内。
- **σ 与叠色 α 在窄窗口耦合退化**（<3σ 时解出假 α≈0.6）。可靠替代：① 频谱比 `log(Ŝ₁/Ŝ₀) = −2π²σ²f² + 2log(1−α)`（斜率只含 σ）；② 用带外帧平坦区反解 α；③ m<1 的混合剖面 10-90 宽度收敛到 2.08σ，m 只能在 m≳0.13 外反解。
- 纵向滚动录屏里**竖直边缘（水平剖面）不受运动模糊影响**；测模糊优先取图标/头像左右缘。
- **判据别被描边骗**：量卡片填充顶缘时用色差阈值会先撞描边（曾误报 177.17，真值 183.0）；要沿列剖面找单行内硬跳变。

## 已知坑：布局
- **网格断点必须按"容器宽"标定**：舞台 1000 − 48 页边距 = 952 < 1024，沿用窗口断点会永远停在 medium（实拍发现首页仍 4 列）。
- **`MiPillTabBar` 在宽父级里会居中**（横向 SingleChildScrollView shrink-wrap + Column 默认 center）→ 宽屏要包 `Align(centerStart)`。
- **全屏页壳的 Stack 子级一律 `Positioned`**：有非定位子级时 Stack 收缩到该子级尺寸，遇 loose 上级（Center / AnimatedSwitcher 内部）整页被居中 → 顶栏跑到屏幕正中（实测偏移 (856−152.8)/2 = 351.6dp）。
- `Container`/`Align` 带 `alignment` 在有界父级会拉满宽；要内容自适应用 `Center(widthFactor: 1.0)`。
- 叠在内容之上的透明层要包 `IgnorePointer`，否则吃掉下层点击（顶栏整体只有返回圆钮吃手势）；且必须包在 `GestureDetector` **外层**——后者 `behavior.opaque` 自身吃命中，包内层时收起的浮层（fab opacity 0）该区域仍吞点击（2026-10-18 实证，底栏+侧栏圆钮同款）。
- **布局类断言别用 `Column` 撑溢出**：比容器高的 mock 内容用 `Stack`+`Positioned` 逐行摆（Stack 只裁剪不报 `RenderFlex overflowed`），行距并进 `top`。
- **`Container` 的 `clipBehavior` 不要在两种状态间切**：`Clip.antiAlias ↔ Clip.none` 会让 Container 内部增删裁剪层 → widget 结构变化 → 子级 `Element` 重建（本项目里表现为跨断点后页面**滚动位置归零**）。要"有时圆角有时不圆"就固定 `Clip.antiAlias`、用 `BorderRadius.zero` + 空 `boxShadow` 表达"无卡片"（像素无差）。
- **给已截图界面加"外壳层"要零新增 render object**：给页面套 `Padding` / 垫 `ColoredBox` 会让黄金图出现 195px、1 级灰度的噪声差（2026-10-18 实测 `light_mode_golden_test` 挂）。正确做法 = 用 `Positioned(left: desktop ? gutter : 0)` 改几何、用容器自身颜色改底色 —— 紧凑档逐像素不变。

## 已知坑：字体与基线
- 墨心在基线上方 `k ≈ 0.355em` 跨字体很稳；但基线在行盒内的位置只能由字体度量决定（本 SDK 无 StrutStyle ascent/descent）→ 用 `Baseline` 让框架在布局期求解。
- **`Baseline` 语义**：基线距**自己 box 顶端** N，`size.height = (N − 子级基线距) + 子级高`（无 clamp）。用法 `Positioned(top: 0) → Center/Align → Baseline → Text`；无界高时 Center shrink-wrap、dy=0。
- **测试字体 CJK advance ≠ 1em**：「关注」13dp 实测宽 26.5。锁「内边距+收缩到内容」要断言 `btn.width == text.width + 2*padding`。
- **行盒高会被引擎向上取整**：31.83dp + height 1.0 → 实测 32.0，容差别写 0.01。

## 已知坑：测试与流程
- **改了几何 token 预览图却逐字节不变 = 有代码自算几何绕过了 token**（如 painter 里 `Radius.circular(size.width/2)`）；ClipRRect 半径改小也裁不到像素（比绘制区大）。先 grep 自算点，再用 PIL `ImageChops.difference(...).getbbox()` 定位差异区验证（2026-10-18 侧栏圆角实证）。
- **`test/` 不参与 app 构建**：`flutter build` 不编译测试 → 动过 `test/` 至少跑一次 `dart analyze`（`C:\src\flutter\bin\dart.bat`，0 error 才算过）。
- 构造期断言在 `harness()` 同步构造时就抛 → `expect(() => harness(...), throwsA(isA<AssertionError>()))`，不要 `pumpWidget`+`takeException`。
- **`getDistanceToBaseline` 不能在测试体里调**（有 layout/paint 期断言）→ 改断言输入契约：`tester.widget<Baseline>(...).baseline`。
- **`MaterialApp.theme` 是 `AnimatedTheme`（200ms）**：换 theme 当帧 `Theme.of().brightness` 仍是旧值 → 测跟随环境要 `pump(300ms)`。
- `const` 构造断言不能求值 `.length`（数量校验放 initState）。

## 工具
- 像素测量脚本：`.workbuddy/measure_*.py`（PIL，非交付物，不入库）。
- 本机 venv：`C:\Users\zmt\.workbuddy\binaries\python\envs\default\Scripts\python.exe`。
