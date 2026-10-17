# mi_like_ui_demo 项目笔记

## 架构与约定
- 对外只经 barrel `lib/mi_like_ui.dart`（新增组件/主题 token 记得补 export）；组件放 `src/components/<类别>/<组件名>/`，类 `Mi` 前缀、文件 snake_case；颜色/文字/间距一律走 `src/theme/` token，组件内不写字面量。
- **实测优先**：视觉参数 1:1 从参考截图像素测量；参考图没有的样式（如按钮禁用态）只能推导，并必须在 doc comment 标注「推导（非实测）」+ 写明取值来源。
- 变更节奏：每个任务完成即 git commit；`flutter analyze` / `flutter test` **由 agent 执行**（2026-10-17 用户明确「你自己执行命令」）；工作区不得留未提交改动。

## 响应式（2026-10-17，`src/utils/responsive.dart`）
- **两级断点**：① 窗口宽 `MiViewport.of(context)` / `MiBreakpoints.ofWidth`（compact<600 / medium 600…1023 / expanded≥1024）决定页面形态；② **容器宽** `MiResponsiveGrid.compactMax/mediumMax`（示例 520/800）决定网格列数。
- `MiScaledCanvas.scaleFor = clamp(min(1, 可用宽/设计宽, 可用高/设计高), minScale, maxScale)`：只缩不放、宽高同比例；`scale == 1` 走原样路径（零变换层，黄金图像素稳定），<1 走 `FittedBox`。
- 示例外壳 `DemoStage`（demo_app.dart，纯函数 `DemoStage.sizeFor(Size)→DemoStageSize{logical,rendered}` 可单测）：**只有 compact 才是"物理手机"**（等比缩 393×856，手机全屏 1:1）；**medium / expanded 一律铺成内容舞台** = `min(max(可用宽,393),1000) × max(可用高,480)`。2026-10-17 平板实机反馈：medium 若按 1x 居中，650×1138 屏里手机框只占 64% 高、上下留 170/240px 纯黑，故改为此策略。
- 内容断点：主题卡 3/4/6 列、展示位 4/6/8 列；非 compact 档页边距统一 24（compact 用实测 11.9/20）。

## 实测速查（dp @ 393 设计宽）
- 页底：亮 `#F3F3F3` / 暗 `#000000`；搜索栏灰：亮 `#E7E7E7` / 暗 `#242424`。
- 胶囊标签行 MiPillTabBar：pill 87.6×39.9、gap/edge 11.9、标签 13.85dp w500。
- MiButton：`#4980F7`（明暗同色）、高 28.3、左右 17、标签 13dp w500、stadium；列表行距 56.1。
- MiSearchBar：高 44.1、inset 15.4、icon 17.8（笔画 1.8/镜片 6.9/r6.0）、gap 12、字 16.5dp w400；填充 alpha 亮 13 / 暗 36（专档非 subtle），backdrop sigma 与导航栏同源 28；hint 亮 `#848484`/暗 `#6D6D6D`，icon `#9A9A9A`。
- MiTopBar（大标题折叠顶栏）：返回圆钮 ⌀44.1 / 左 11.9 / 垂心 76.0，箭头墨盒 11.68×21.31（笔宽 2.05、墨心**左偏 1.3**）；大标题 31.83dp（墨左 29.6 / 墨心 y 132.9）、紧凑标题 18.0dp（屏心 / 墨心 y 75.9）；按压圆盘 白@9.4% 420ms 淡入 / 300ms 淡出。
  - **内容首行顶缘分两档**（都实测，不归一）：卡片类 `contentTopInset` **183.0**（录屏卡片填充硬边 568px）、搜索栏类 `searchBarTopInset` **168.5**（「设置」首页搜索栏 523px）；demo 首页用后者。
  - **返回圆钮 `showBack` 默认 false**（顶层页无返回）→ true 才绘制，可点性另由 `onBack`（null = 只显示不可点）决定；`showBack` 也决定紧凑标题的对称内缩（`backInset + backDiameter`，false 时 0）。
  - **标题墨心落点靠 `Baseline` 钉死**：`Baseline(baselineType: alphabetic, baseline: 墨心 + 0.355em)`，组件高度取「大标题墨心 + 一整行」定值（`componentHeight`）。**本 SDK（C:\src\flutter @3.47.5）的 `StrutStyle` 没有 `ascent`/`descent` 参数**（`height` 只按比例缩放 ascent/descent，改不了二者之比），所以「钉行盒内基线」这条路走不通；`TextStyle.height` 同理。行盒中心反推的老换算（`largeTitleBoxCenterY` 等）已删除。
  - **材质 = 渐进磨砂 + 叠色**（亮色「我的」页录屏 1220×2656@24.26fps 实测；旧结论「纯色遮罩、无模糊」已废弃）：栏顶 `blurSigma` **5.37**，实测 σ(y) = 5.37(0…35dp) → 4.96(50) → 4.34(67.5) → 1.85(90) → 0.76(103) → **0(119dp)**；**实现 = 8 段定 σ 阶梯**（`MiTopBarPalette.blurBands`，每段 `ClipRect + BackdropFilter`，σ 取实测曲线段中点插值；`blurMask` 已删除）。浅色叠色 = 页底色 #F3F3F3 @**0.650**(顶)→0(**122.4dp**)；深色叠色不动（设置页顶部不透明黑）。材质盒高仍 `scrimHeight` 128.9。
  - **纯材质形态**：`title` 可空 → 顶栏不内嵌任何组件，高度收到 `scrimHeight`；`showBack` 可单独用。
  - **头部插槽（2026-10-17）**：顶栏 = 标题区（定高）+ 头部区（插槽），`searchBar` / `tabBar` / `header`（`PreferredSizeWidget`）三者互斥（构造期断言）。几何走 `MiTopBarMetrics`：`headerTopInset` 56（`headerTopInsetFor(safeAreaTop)` 取大者）、`searchBarGap` 16、`headerContentGap` 12、`headerInset` 11.9、`searchBarSlotHeight` 44.1、`tabBarSlotHeight` 39.9（后两个与 `MiSearchBarMetrics.barHeight` / `MiPillTabMetrics.pillHeight` 同值，跨层一致由测试钉住）。
    - **插槽高度是声明值**：组件按它排版，宿主用 `bar.occupiedHeight(context)` 给滚动内容让位 —— 两侧同源才不会错位。
    - **胶囊行必须满宽**（不套 `headerInset`）：它自带 11.9 `edgeInset` 且要横向出血滚动，套内边距会把末尾胶囊多裁一截；搜索栏才吃 `headerInset`。
    - `showSurface: false` 关磨砂 + 叠色（头部自带 backdrop 时必传，否则多叠 8 层模糊、且间隙被染叠色）。分类页即 `showSurface: false + searchBar + tabBar`，迁移后逐像素不变。
  - 折叠：大标题**属于滚动内容**（质心位移 = 滚动位移，1:1 上移）+ 独立淡出曲线（0→19.97dp 归零），紧凑标题 19.97→29.31dp 才淡入，两段不重叠。
- MiThemeCard（竖向主题卡）：预览图 259:472≈0.549（有界父级内 AspectRatio 必铺满）、圆角 radiusLg 20（拟合 19.6）、标题 13.85dp w500 **左对齐内缩 8.8**（与区块标题同列，非居中）、图→题 8 / 行距 15 / 列距 11.9；页面双轨页边距 = 壳层 11.9 + 文本列 20.5（区块标题 inset 8.6）；themeMode 可空跟随环境（同 MiSearchBar，保 const 用法）。

## 性能：每帧模糊预算（2026-10-17）
- **`BackdropFilter` = 每帧全 QUAD 高斯**，滚动时 backdrop 一变就重算 → 滚动掉帧几乎全出在这。量化口径 = 一次 build 的**层数 + 覆盖面积 dp²**（与 dpr 无关），钉在 `test/perf_budget_test.dart`。
- 平板 768×1280 深色实测：首页/我的 10 层/100,073 → **6~7 层/47,081~76,716**；分类 6 层 → **3 层**（面积略增 2.5%，因合并后含胶囊间隙）。
- 三条零视觉差异优化（逐像素最大差 1~2 级、**无像素差 > 2**）：
  1. **深色顶栏跳过 0…63.6dp**（scrim α=1.000 纯黑，其下模糊不可见）→ `MiTopBarPalette.scrimOpaqueBottom` + `MiTopBar.visibleBlurBands`，8 段→5 段；亮色 α 0.650 一段不省。
  2. **胶囊行 4 个 BackdropFilter → 1 个**（`_CapsuleStripClipper` + 单 BackdropFilter），相邻胶囊仍不串色（模糊层先于填充）。
  3. **`ImageFilter` 按 σ 缓存**（`src/utils/filter_cache.dart`，内部不导出）+ 跳过 σ<0.5dp（半径<1dp 亚像素）的段。
- **切 tab 不做 fade**：`FadeTransition` 的 Opacity 引入 saveLayer → 下层 backdrop 变空（既有坑的延伸），切页期间旧页磨砂消失 + 双份全宽高斯（层数 7→9）。底部 tab 惯例就是瞬时切换。
- **"感觉丢帧"先排除 debug 模式**：debug 渲染开销是 profile 的数倍；验证用 `flutter run --profile`（按 P 看 overlay）+ `adb shell dumpsys gfxinfo com.example.bottom_nav_demo` 看 Janky frames。

## 已知坑
- **网格断点必须按"容器宽"标定，不能沿用窗口断点**：示例舞台 1000 宽减两侧 24 页边距只剩 952 < 1024，沿用窗口断点的网格会永远停在 medium 档、宽屏换不到 expanded 列数（2026-10-17 实拍发现首页仍是 4 列）。修法 = 给网格自己的 `compactMax/mediumMax`（示例 520/800 ≈ 设计宽 1.3/2 倍）。
- **`MiPillTabBar` 在宽父级里会居中**：它是横向 `SingleChildScrollView`，拿到 loose 宽时 shrink-wrap 到内容宽（4×87.6+3×11.9+2×11.9 ≈ 410），再被 `Column`（默认 `crossAxisAlignment.center`）居中 → 与左对齐的搜索框/网格错位。宽屏场景要包 `Align(centerStart)`（393 下内容 410 > 视口，行为与原来一致、黄金图不变）。
- **`BackdropFilter` 一旦被半透明遮罩包住，backdrop 立刻变空、模糊整段消失**（2026-10-17 探针实证）：`ShaderMask`（任何 alpha<1 的 gradient）/ `Opacity` 都会引入新的 saveLayer，模糊读不到下层内容。判据实验：同一 260×120 黑白色条底，`ClipRect+BackdropFilter` 有糊；套一层「alpha 恒 1」的 ShaderMask **仍有糊**（Skia 把恒定不透明优化掉了）；换成任何含 <1 alpha 的 gradient（哪怕顶部就是 1）**完全恢复锐利**。所以「渐进模糊」不能用遮罩调强度 → 只能**分段定 σ 并列**（`MiTopBarPalette.blurBands`：段间 σ 比 ≤1.5、段高 ≤17dp 时台阶不可见）。写回归测试就断言「MiTopBar 下不得出现 ShaderMask」。
- **测试字体的 CJK 字面 advance 不是 1em**：本 SDK 里「关注」13dp 两字实测宽 **26.5**（1.019em/字），所以别把按钮宽写死成 `2*13 + 2*17 = 60`（实测会 60.5 挂）。要锁「内边距 + 收缩到内容」就断言 `btn.width == text.width + 2*padding`。
- **golden 里 backdrop 模糊是生效的**，别再把「预览图看不出来」当成环境不支持：`matchesGoldenFile(finder)` 只截该子树，**模糊源必须也在被截子树内**（顶栏单独截会拿到空 backdrop）。判断有没有糊要量高频内容（条纹/照片边缘）的对比度幅度，平坦色块与渐变圆在模糊下几乎不变。
- `Container`/`Align` 带 `alignment` 在**有界**父级（Center/Column）会拉满宽；需要「内容自适应」的控件用 `Center(widthFactor: 1.0)` 收缩。
- `const` 构造断言不能求值 `.length`（数量校验放 initState，见玻璃导航栏）。
- 样式改动后必须重跑 `flutter test --update-goldens test/preview_capture_test.dart`，否则 `doc/preview/*.png` 预览测试挂。
- 组件的**构造期断言**（如 `MiTopBar` 的 `scrollOffset >= 0`）在 `harness()` 同步构造时就抛，走不到 `pumpWidget`：测试要写 `expect(() => harness(...), throwsA(isA<AssertionError>()))`，不要写 `pumpWidget` + `takeException()`。
- 顶栏/滚动类组件若用「叠在内容之上的 Stack」，其透明区域要包 `IgnorePointer`，否则会把下层内容的点击吃掉（顶栏整体只有返回圆钮吃手势）。
- **全屏页壳的 `Stack` 子级一律用 `Positioned`**：只要有**非定位子级**（如叠在顶部的顶栏），Stack 就不再撑满父级、而是收缩到该子级尺寸；一旦上级给的是 loose 约束（`Center`、`AnimatedSwitcher` 内部那个 `alignment: center` 的 Stack），整页会被居中 → 顶栏跑到屏幕正中。2026-10-16 实机截图实测偏移 =（856 − 152.8）/ 2 = 351.6dp。
- **文字的墨心落点依赖字体族 → 已用 `Baseline` 解决**：墨心在**基线上方** `k ≈ 0.355em` 跨字体很稳（simhei/msyh/simsun 实测 0.350~0.360），但**基线在行盒内的位置**只能由字体度量决定（`StrutStyle` 在本 SDK 无 `ascent`/`descent`；`TextStyle.height` 只按比例缩放），字体间可差 0.14em（参考录屏 MiSans ≈0.807 vs Android CJK 回退字体 ≈0.95；0.14em × 31.83 ≈ 4.5dp）。2026-10-16 实机实测大标题墨心比模型低 **6.9dp**（chevron 是 CustomPainter、字体无关，精确吻合 0.5dp 内 → 组件几何没问题）；字号经墨盒宽度交叉验证仍为 31.83dp。修法 = 标题外包 `Baseline(baselineType: alphabetic, baseline: 墨心 + 0.355em)`，由框架在布局期求解，**别再退回 em 经验换算/行盒中心反推**。
- **`Baseline` 的定位语义**：`RenderBaseline` 把子级基线放到「距**它自己 box 顶端** N 处」，`size.height = (N − 子级基线距) + 子级高`、无 clamp（可负）。所以用法是 `Positioned(left:/top: 0) → (Padding) → Center/Align → Baseline → Text`：`top` 必须给 0（基线从 box 顶量起），`Center` 在**无界高**约束下 shrink-wrap 且 dy 偏移为 0（`maxHeight == ∞` → `shrinkWrapHeight`），所以水平居中不会破坏垂直落点。
- **平坦色块判不了「有没有模糊」**：模糊不改变平坦区的亮度，所以「沿均匀色块取样看有没有亮度斜坡」这种判据既不能证明、也不能否定 backdrop 模糊（上一版据此误判顶栏「无磨砂」）。要判模糊必须用**高频内容**（照片边缘 / 圆角方块的竖直边缘 / 文字笔画），并量**边缘宽度**而不是亮度。
- **σ 与叠色 α 在窄窗口上耦合退化**：把「同行锐利剖面模糊后与带内剖面做最小二乘」时若窗口太窄（< 3σ），衰减幅值会被 α 吸收 → 解出偏小的 σ + 偏大的 α（本机实测就解出假的 α≈0.6）。三种可靠替代：① **频谱比** `log(S₁/S₀) = −2π²σ²f² + 2log(1−α)`（斜率只含 σ，α 只进常数项）；② 只用**带外帧做 α 的平坦区硬判据**（如白卡 255→249 反解 α=0.5）；③ 由边缘宽度反解 m 时注意 **m<1 的混合剖面 10-90 宽度会收敛到 2.08σ**（不随 m 变），故 m 只能在 m≳0.13 之外反解。
- **纵向滚动的录屏里，竖直边缘（水平剖面）不受运动模糊影响**：测模糊优先取「图标的左右缘、头像左右测点」，避开水平边缘；静止帧（滚动停止后）当然更好。
- **判据别被描边骗**：测「卡片填充顶缘」时用 `(B−R)>15` 之类的色差阈值会先撞上**卡片描边**（录屏帧因此在 177.17dp 误报，真值是 183.0dp）。要沿列剖面找**单行内的硬跳变**（亮度 0 → 135）才可靠。
- **`test/` 不参与 app 构建**：`flutter build` 只编译 app，测试代码里的编译错误（如 `AnimatedSwitcher` 缺必填 `duration`）不会暴露 → 动过 `test/` 后至少跑一次 `dart analyze`（`C:\src\flutter\bin\dart.bat`，**0 error 才算过**；`flutter analyze` 同级）。教训来自 2026-10-16：`flutter build` 只报了 `StrutStyle.ascent` 那一处，测试里另一处错误是 `dart analyze` 才翻出来的。
- **`getDistanceToBaseline` 不能在测试体里调**：本 SDK 的 `RenderBox.getDistanceToBaseline`（无 `dry` 参数）有「只能在父级 layout / paint 期调用」的断言 → 测试里调必抛。要验「文字落点」就断言组件的**输入契约**：`tester.widget<Baseline>(find.ancestor(of: text, matching: find.byType(Baseline))).baseline`（`RenderBaseline` 保证落点 = 该入参）。
- **`MaterialApp.theme` 是 `AnimatedTheme`（默认 200ms）**：换 theme 的**当帧** `Theme.of().brightness` 仍是旧值（`ThemeData.lerp` 在 `t<0.5` 取前者）→ 测「跟随环境亮度」必须换完 theme 再 `pump(300ms)`，否则拿到上一套配方。
- **布局类断言别用 `Column` 撑溢出**：写「比容器高」的 mock 内容（如顶栏预览的背景行卡）要用 `Stack` + `Positioned` 逐行摆 —— `Stack` 只按自身边界裁剪、不报 `RenderFlex overflowed`，`Column`/`ClipRect` 组合会报错。行距直接并进 `top` 还能省掉 `Transform`。
- **行盒高会被引擎向上取整**：`TextStyle(height: 1.0)` + 字号 31.83 时 `Text` 实测高 **32.0**（整数像素）→ 断言容差别写 0.01。

## 工具
- 像素测量脚本：`.workbuddy/measure_*.py`（PIL，分析用非交付物，不入库）。
- 本机 venv Python：`C:\Users\zmt\.workbuddy\binaries\python\envs\default\Scripts\python.exe`（注意在 `Scripts\` 下，PIL 可用）。
