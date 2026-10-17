# Changelog

本项目所有重要变更均记录于此。

格式参考 [Keep a Changelog](https://keepachangelog.com/)，版本号遵循 [Semantic Versioning](https://semver.org/)。

## [Unreleased]

### Added

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
