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
  - **标题垂心靠 strut 钉基线**：`StrutStyle(height: 1.0, ascent: 0.825, descent: 0.175, forceStrutHeight: true)`，行盒 = 1em、基线固定在行盒顶下方 0.825em（字体无关）；行盒中心 = 墨心 − (0.825 − k)·em + em/2 → `largeTitleBoxCenterY` 133.9 / `compactTitleBoxCenterY` 76.4。**不要再用「墨心 + 0.126em」的老换算**（那是按 MiSans 反解的，换字体即失效）。
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
- **文字的墨心落点依赖字体族 → 已用 strut 解决**：墨心在基线上方 `k ≈ 0.355em` 跨字体很稳（simhei/msyh/simsun 实测 0.350~0.360），但**基线在行盒内的位置 = 字体 `ascent/(ascent+descent)`**，字体间可差 0.14em（参考录屏 MiSans ≈0.807 vs Android CJK 回退字体 ≈0.95；0.14em × 31.83 ≈ 4.5dp）。2026-10-16 实机实测大标题墨心比模型低 **6.9dp**（chevron 是 CustomPainter、字体无关，精确吻合 0.5dp 内 → 组件几何没问题）；字号经墨盒宽度交叉验证仍为 31.83dp。修法 = `MiTopBar` 两条标题挂 `_titleStrut` 把基线钉死，别再退回 em 经验换算。
- **判据别被描边骗**：测「卡片填充顶缘」时用 `(B−R)>15` 之类的色差阈值会先撞上**卡片描边**（录屏帧因此在 177.17dp 误报，真值是 183.0dp）。要沿列剖面找**单行内的硬跳变**（亮度 0 → 135）才可靠。

## 工具
- 像素测量脚本：`.workbuddy/measure_*.py`（PIL，分析用非交付物，不入库）。
- 本机 venv Python：`C:\Users\zmt\.workbuddy\binaries\python\envs\default\Scripts\python.exe`（注意在 `Scripts\` 下，PIL 可用）。
