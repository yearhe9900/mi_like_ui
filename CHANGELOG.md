# Changelog

本项目所有重要变更均记录于此。

格式参考 [Keep a Changelog](https://keepachangelog.com/)，版本号遵循 [Semantic Versioning](https://semver.org/)。

## [Unreleased]

### Added

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
  - **遮挡是纯色遮罩，不是磨砂玻璃**：实心段下沿 63.6dp + 1.5 次幂渐隐裙边至 128.9dp（拟合 `alpha(y)=1−clamp((y−63.6)/65.3,0,1)^1.5`，渐变为 8 等分采样）；实测依据 = 均匀色块在遮罩下出现亮度斜坡（排除 backdrop 模糊）+ 卡片硬边 3px 内完成跳变（无拖尾）。故刻意不复用 `MiGlassPalette`
  - 几何实测：返回圆钮 ⌀44.1 / 左 11.9 / 垂心 76.0，箭头墨盒 11.68×21.31 / 笔宽 2.05 / 墨心左偏 1.3dp（光学偏置）；大标题 31.83dp（墨左 29.6 / 墨心 y 132.9）、紧凑标题 18.0dp（屏内心 / 墨心 y 75.9）；内容首行顶缘 183dp
  - 按压反馈实测：⌀44.1 圆盘、白 @9.4%、420ms easeOut 淡入 / 300ms 淡出（逐帧 0→25%→83%→100%）
  - **受控组件**：`scrollOffset` 由宿主注入（与 `MiPillTabBar.selectedIndex` 同风格），组件不自带滚动；除返回圆钮外整体不参与手势。负位移 / NaN 构建期断言，+∞ 饱和为折叠完成态
  - `MiTopBarPalette` 配方入主题层（`theme/top_bar_tokens.dart`，**浅色配方为推导**：无亮色顶栏录屏，遮罩基色取实测页底 #F3F3F3）、`MiTopBarMetrics` 几何 + 折叠查找表入组件目录、返回箭头 `BackChevronIconPainter` 入 `icons/nav_icons.dart`
- demo 首页 / 「我的」页接入 `MiTopBar`（页面壳改 `StatefulWidget`，用 `ValueNotifier` 承接 `ScrollController` 位移，只重建顶栏一层）
- **顶栏 README 预览图** `doc/preview/top_bar_light|dark.png`（每格上=静止、下=滚动 105dp，内容穿进遮罩显形）

### Changed

- 组件展示页胶囊标签改名：`示例一` → **Logo 展示**、`示例二` → **按钮展示**（按分组内容命名，`示例三/四` 保持占位）
- 吸顶行为测试改为在滚动网格内定位分组标题（避免与同名胶囊标签冲突）

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
- **演示 app** 与黄金图回归测试（`test/preview_capture_test.dart`）

### Changed

- 重构为可扩展 `mi_like_ui` 框架骨架（之前为单文件 demo）
- 拖拽果冻拉伸改为平滑衰减，消除慢拖停顿时的宽度跳动
- `README` 重写为完整框架指南（架构、约定、扩充流程、路线图）
- 亮色胶囊移除虚构白描边，对齐录屏实测真值
- 脚手架：`flutter create` 平台工程 + Gradle wrapper 改用腾讯镜像

### Fixed

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
