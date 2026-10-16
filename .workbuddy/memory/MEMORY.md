# mi_like_ui_demo 项目笔记

## 架构与约定
- 对外只经 barrel `lib/mi_like_ui.dart`（新增组件/主题 token 记得补 export）；组件放 `src/components/<类别>/<组件名>/`，类 `Mi` 前缀、文件 snake_case；颜色/文字/间距一律走 `src/theme/` token，组件内不写字面量。
- **实测优先**：视觉参数 1:1 从参考截图像素测量；参考图没有的样式（如按钮禁用态）只能推导，并必须在 doc comment 标注「推导（非实测）」+ 写明取值来源。
- 变更节奏：每个任务完成即 git commit；`flutter analyze` / `flutter test` 由用户手动执行（agent 不代跑）。

## 实测速查（dp @ 393 设计宽）
- 页底：亮 `#F3F3F3` / 暗 `#000000`；搜索栏灰：亮 `#E7E7E7` / 暗 `#242424`。
- 胶囊标签行 MiPillTabBar：pill 87.6×39.9、gap/edge 11.9、标签 13.85dp w500。
- MiButton：`#4980F7`（明暗同色）、高 28.3、左右 17、标签 13dp w500、stadium；列表行距 56.1。
- MiSearchBar：高 44.1、inset 15.4、icon 17.8（笔画 1.8/镜片 6.9/r6.0）、gap 12、字 16.5dp w400；填充 alpha 亮 13 / 暗 36（专档非 subtle），backdrop sigma 与导航栏同源 28；hint 亮 `#848484`/暗 `#6D6D6D`，icon `#9A9A9A`。
- MiTopBar（大标题折叠顶栏）：返回圆钮 ⌀44.1 / 左 11.9 / 垂心 76.0，箭头墨盒 11.68×21.31（笔宽 2.05、墨心**左偏 1.3**）；大标题 31.83dp（墨左 29.6 / 墨心 y 132.9）、紧凑标题 18.0dp（屏心 / 墨心 y 75.9）；按压圆盘 白@9.4% 420ms 淡入 / 300ms 淡出。
  - **内容首行顶缘分两档**（都实测，不归一）：卡片类 `contentTopInset` **183.0**（录屏卡片填充硬边 568px）、搜索栏类 `searchBarTopInset` **168.5**（「设置」首页搜索栏 523px）；demo 首页用后者。
  - **返回圆钮 `showBack` 默认 false**（顶层页无返回）→ true 才绘制，可点性另由 `onBack`（null = 只显示不可点）决定；`showBack` 也决定紧凑标题的对称内缩（`backInset + backDiameter`，false 时 0）。
  - **标题墨心落点靠 `Baseline` 钉死**：`Baseline(baselineType: alphabetic, baseline: 墨心 + 0.355em)`，组件高度取「大标题墨心 + 一整行」定值（`componentHeight`）。**本 SDK（C:\src\flutter @3.47.5）的 `StrutStyle` 没有 `ascent`/`descent` 参数**（`height` 只按比例缩放 ascent/descent，改不了二者之比），所以「钉行盒内基线」这条路走不通；`TextStyle.height` 同理。行盒中心反推的老换算（`largeTitleBoxCenterY` 等）已删除。
  - **顶栏遮挡 = 纯色遮罩（实心段 63.6 + 1.5 次幂渐隐到 128.9），实测无 backdrop 模糊** —— 刻意不复用磨砂语言。
  - 折叠：大标题**属于滚动内容**（质心位移 = 滚动位移，1:1 上移）+ 独立淡出曲线（0→19.97dp 归零），紧凑标题 19.97→29.31dp 才淡入，两段不重叠。
- MiThemeCard（竖向主题卡）：预览图 259:472≈0.549（有界父级内 AspectRatio 必铺满）、圆角 radiusLg 20（拟合 19.6）、标题 13.85dp w500 **左对齐内缩 8.8**（与区块标题同列，非居中）、图→题 8 / 行距 15 / 列距 11.9；页面双轨页边距 = 壳层 11.9 + 文本列 20.5（区块标题 inset 8.6）；themeMode 可空跟随环境（同 MiSearchBar，保 const 用法）。

## 已知坑
- `Container`/`Align` 带 `alignment` 在**有界**父级（Center/Column）会拉满宽；需要「内容自适应」的控件用 `Center(widthFactor: 1.0)` 收缩。
- `const` 构造断言不能求值 `.length`（数量校验放 initState，见玻璃导航栏）。
- 样式改动后必须重跑 `flutter test --update-goldens test/preview_capture_test.dart`，否则 `doc/preview/*.png` 预览测试挂。
- 组件的**构造期断言**（如 `MiTopBar` 的 `scrollOffset >= 0`）在 `harness()` 同步构造时就抛，走不到 `pumpWidget`：测试要写 `expect(() => harness(...), throwsA(isA<AssertionError>()))`，不要写 `pumpWidget` + `takeException()`。
- 顶栏/滚动类组件若用「叠在内容之上的 Stack」，其透明区域要包 `IgnorePointer`，否则会把下层内容的点击吃掉（顶栏整体只有返回圆钮吃手势）。
- **全屏页壳的 `Stack` 子级一律用 `Positioned`**：只要有**非定位子级**（如叠在顶部的顶栏），Stack 就不再撑满父级、而是收缩到该子级尺寸；一旦上级给的是 loose 约束（`Center`、`AnimatedSwitcher` 内部那个 `alignment: center` 的 Stack），整页会被居中 → 顶栏跑到屏幕正中。2026-10-16 实机截图实测偏移 =（856 − 152.8）/ 2 = 351.6dp。
- **文字的墨心落点依赖字体族 → 已用 `Baseline` 解决**：墨心在**基线上方** `k ≈ 0.355em` 跨字体很稳（simhei/msyh/simsun 实测 0.350~0.360），但**基线在行盒内的位置**只能由字体度量决定（`StrutStyle` 在本 SDK 无 `ascent`/`descent`；`TextStyle.height` 只按比例缩放），字体间可差 0.14em（参考录屏 MiSans ≈0.807 vs Android CJK 回退字体 ≈0.95；0.14em × 31.83 ≈ 4.5dp）。2026-10-16 实机实测大标题墨心比模型低 **6.9dp**（chevron 是 CustomPainter、字体无关，精确吻合 0.5dp 内 → 组件几何没问题）；字号经墨盒宽度交叉验证仍为 31.83dp。修法 = 标题外包 `Baseline(baselineType: alphabetic, baseline: 墨心 + 0.355em)`，由框架在布局期求解，**别再退回 em 经验换算/行盒中心反推**。
- **`Baseline` 的定位语义**：`RenderBaseline` 把子级基线放到「距**它自己 box 顶端** N 处」，`size.height = (N − 子级基线距) + 子级高`、无 clamp（可负）。所以用法是 `Positioned(left:/top: 0) → (Padding) → Center/Align → Baseline → Text`：`top` 必须给 0（基线从 box 顶量起），`Center` 在**无界高**约束下 shrink-wrap 且 dy 偏移为 0（`maxHeight == ∞` → `shrinkWrapHeight`），所以水平居中不会破坏垂直落点。
- **判据别被描边骗**：测「卡片填充顶缘」时用 `(B−R)>15` 之类的色差阈值会先撞上**卡片描边**（录屏帧因此在 177.17dp 误报，真值是 183.0dp）。要沿列剖面找**单行内的硬跳变**（亮度 0 → 135）才可靠。
- **`test/` 不参与 app 构建**：`flutter build` 只编译 app，测试代码里的编译错误（如 `AnimatedSwitcher` 缺必填 `duration`）不会暴露 → 动过 `test/` 后至少跑一次 `dart analyze`（`C:\src\flutter\bin\dart.bat`，**0 error 才算过**；`flutter analyze` 同级）。教训来自 2026-10-16：`flutter build` 只报了 `StrutStyle.ascent` 那一处，测试里另一处错误是 `dart analyze` 才翻出来的。
- **`getDistanceToBaseline` 不能在测试体里调**：本 SDK 的 `RenderBox.getDistanceToBaseline`（无 `dry` 参数）有「只能在父级 layout / paint 期调用」的断言 → 测试里调必抛。要验「文字落点」就断言组件的**输入契约**：`tester.widget<Baseline>(find.ancestor(of: text, matching: find.byType(Baseline))).baseline`（`RenderBaseline` 保证落点 = 该入参）。
- **`MaterialApp.theme` 是 `AnimatedTheme`（默认 200ms）**：换 theme 的**当帧** `Theme.of().brightness` 仍是旧值（`ThemeData.lerp` 在 `t<0.5` 取前者）→ 测「跟随环境亮度」必须换完 theme 再 `pump(300ms)`，否则拿到上一套配方。
- **布局类断言别用 `Column` 撑溢出**：写「比容器高」的 mock 内容（如顶栏预览的背景行卡）要用 `Stack` + `Positioned` 逐行摆 —— `Stack` 只按自身边界裁剪、不报 `RenderFlex overflowed`，`Column`/`ClipRect` 组合会报错。行距直接并进 `top` 还能省掉 `Transform`。
- **行盒高会被引擎向上取整**：`TextStyle(height: 1.0)` + 字号 31.83 时 `Text` 实测高 **32.0**（整数像素）→ 断言容差别写 0.01。

## 工具
- 像素测量脚本：`.workbuddy/measure_*.py`（PIL，分析用非交付物，不入库）。
- 本机 venv Python：`C:\Users\zmt\.workbuddy\binaries\python\envs\default\Scripts\python.exe`（注意在 `Scripts\` 下，PIL 可用）。
