# mi_like_ui

小米风格可扩展 UI 组件框架（Flutter）。

以像素级实测还原小米系视觉与动效，沉淀为分层清晰、可持续扩充的组件库。
当前已落地 `MiGlassNavBar`（玻璃悬浮底部导航栏）、`MiPillTabBar`
（胶囊分类标签行）、`MiButton`（胶囊按钮）、`MiSearchBar`（搜索栏，
透明磨砂参数与导航栏同源）、`MiTopBar`（大标题折叠顶部导航栏，
渐进磨砂材质 + 逐帧实测折叠曲线）与 `MiThemeCard`（竖向预览卡片，
主题商店精选卡）；弹窗、表单等组件按同一组织方式逐步扩充。

## 效果

### 深色

<img src="doc/preview/demo_dark.png" width="240" alt="深色模式 demo 整页" /> <img src="doc/preview/nav_dark.png" width="360" alt="深色模式导航栏特写" />

### 浅色

<img src="doc/preview/demo_light.png" width="240" alt="浅色模式 demo 整页" /> <img src="doc/preview/nav_light.png" width="360" alt="浅色模式导航栏特写" />

### 组件：胶囊分类标签行

<img src="doc/preview/pill_light.png" width="360" alt="浅色胶囊分类标签行" /> <img src="doc/preview/pill_dark.png" width="360" alt="深色胶囊分类标签行" />

### 组件：胶囊按钮（MiButton）

「我的关注」页关注按钮实测复刻（59.9×28.3dp stadium、#4980F7 明暗同色）；下图为 主 / 次级 / 禁用 三态：

<img src="doc/preview/button_light.png" width="360" alt="浅色胶囊按钮三态" /> <img src="doc/preview/button_dark.png" width="360" alt="深色胶囊按钮三态" />

### 组件：大标题折叠顶部导航栏（MiTopBar）

HyperOS 顶栏实测复刻（1220×2656 录屏逐帧反解）：大标题**属于滚动内容**
（质心位移与列表滚动逐帧相等），并另沿一条独立曲线淡出；紧凑标题在其归零后
（滚动 ≈20→27.4dp）才居中淡入，两段不重叠。标题用 `Baseline` 把基线钉到实测
反推的目标值（墨心 = 基线 − 0.355em），落点不随字体族的 ascent/descent 漂移。

材质是**渐进磨砂**：backdrop 模糊从栏顶的 σ = 5.37dp 向下衰减，到 119dp 处完全
锐利，再叠一层页底色（亮 #F3F3F3 @0.650→0，深色配方取自设置页、顶部不透明）。
Flutter 没有"位置相关模糊"，而用半透明遮罩削弱模糊层会让 backdrop 失效（实测
`ShaderMask` / `Opacity` 都会让模糊整段消失），故用**分段定 σ 阶梯**近似：
8 段各 `ClipRect + BackdropFilter`，σ 取实测曲线在段中点的值（段高 ≤ 17dp、
相邻 σ 比 ≤ 1.5，台阶不可见）。判据是高频内容（头像照片 / 圆角方块的竖直边缘）
在栏内被抹开、且越往下越清楚；σ 由「边缘 10-90% 宽度」与「同行频谱比
log(S₁/S₀) = −2π²σ²f²」两种独立方法交叉验证。

`title` **可空**：不传即**纯材质形态**（不内嵌任何组件，只画磨砂 + 叠色）。
返回圆钮**默认不显示**：`showBack: true` 才绘制，其可点性再由 `onBack` 决定
（`null` = 只显示不可点）。内容首行顶缘按实测分两档：卡片类
`contentTopInset` 183dp、搜索栏类 `searchBarTopInset` 168.5dp。

下图每格分别是：① 纯材质形态（标题不传，滚动 96dp → 头像滑进栏内被抹开）、
② 顶层页（无圆钮、首行搜索栏 168.5dp）、③ 次级页（带圆钮、首行卡片 183dp）、
④ 滚动 105dp（紧凑标题浮现、内容穿进磨砂）：

<img src="doc/preview/top_bar_light.png" width="200" alt="浅色顶栏四态对照" /> <img src="doc/preview/top_bar_dark.png" width="200" alt="深色顶栏四态对照" />

### 组件：主题卡片（MiThemeCard）

主题商店「精选主题」卡实测复刻（881×1920 首页截图）：预览图按 259:472 定比 +
`radiusLg` 20dp 圆角（外缘拟合 R=44px），标题 13.85dp Medium、较图左缘内缩
8.8dp 与区块标题同列起排；下图为 3 列实测壁纸主色渐变占位：

<img src="doc/preview/card_light.png" width="360" alt="浅色主题卡片" /> <img src="doc/preview/card_dark.png" width="360" alt="深色主题卡片" />

「分类」tab 为组件展示页（「Logo 展示」组前 6 位为 `nav_icons.dart` 全量 logo，「按钮展示」组陈列 `MiButton` 三态，其余为示例占位；标签行吸顶，滚动内容从半透明磨砂胶囊后方经过）：

<img src="doc/preview/showcase_light.png" width="200" alt="浅色组件展示页" /> <img src="doc/preview/showcase_dark.png" width="200" alt="深色组件展示页" />

> 预览图由 `test/preview_capture_test.dart` 生成，样式变更后重新执行
> `flutter test --update-goldens test/preview_capture_test.dart` 刷新。

### 自适应（响应式）

框架层 `src/utils/responsive.dart` 提供断点判定与等比缩放画布，示例层
`DemoStage` 用它们把「物理手机画面」摆进任意窗口。**两级断点**分工明确：

| 档位 | 窗口逻辑宽 | 示例外壳（`DemoStage`） | 内容网格列数（主题卡 / 展示位） |
|---|---|---|---|
| compact | < 600dp | 393×856 设计画布**等比缩小**到放得下（手机全屏时正好 1:1、零留白） | 3 / 4 |
| medium | 600…1023dp | 画面**铺成内容舞台**（宽 = 可用宽、高 = 可用高，四周 24dp） | 4 / 6 |
| expanded | ≥ 1024dp | 同上，宽度上限 1000dp（桌面端不让内容无限拉宽） | 6 / 8 |

> 平板不再是一个 1x 居中的小手机：medium 档也铺成内容舞台，内容宽随屏幕增大，
> 网格从 3 列升到 4 列 —— 是**重新布局**，而不是把手机画面等比拉大（拉大后
> 1dp 实测值会失去物理意义）。2026-10-17 平板实机反馈：旧策略下 650×1138 的
> 屏幕里手机框只占 64% 高、上下各留 170/240px 纯黑。

- **窗口断点**（`MiViewport` / `MiBreakpoints.ofWidth`）决定页面形态；
  **容器断点**（`MiResponsiveGrid.compactMax / mediumMax`，示例取 520 / 800）
  决定网格列数 —— 限宽画布里的容器永远够不到窗口断点，两者混用会让宽屏换不到列。
- **只缩不放、宽高同比例**：`MiScaledCanvas.scaleFor` 取
  `min(1, 可用宽/设计宽, 可用高/设计高)` → 不溢出、不变形；`scale == 1` 时走
  原样路径、不加任何变换层（黄金图逐像素稳定），缩小走 `FittedBox` 矢量重绘。
- **实时响应**：`MediaQuery.sizeOf` + `LayoutBuilder` 依赖注入，窗口/分屏/浏览器
  缩放一变即重排，不需要 `setState` 或尺寸监听。
- **不丢内容**：网格行内 `Expanded` 等分、末行留空不拉伸；长文案一律
  `maxLines: 1 + ellipsis`；分类页胶囊行显式左对齐（否则宽屏会被 `Column`
  默认居中、与搜索框/网格左缘失配）。

验证：`test/responsive_test.dart` —— 断点边界、`scaleFor` 纯函数、三档外壳尺寸、
260×470 小窗与 1366×768 桌面端的实际渲染（无溢出 + 关键部件在窗口内 + 宽高比
不变）、窗口尺寸热切换、网格 3/4/6 与 4/6/8 列。

<img src="doc/preview/adaptive_phone.png" width="120" alt="手机 393×856：1:1" /> <img src="doc/preview/adaptive_small_window.png" width="120" alt="小窗 260×470：整机等比缩小" /> <img src="doc/preview/adaptive_tablet.png" width="180" alt="平板 800×1000：1x 居中" /> <img src="doc/preview/adaptive_desktop.png" width="420" alt="桌面 1366×768：加宽舞台，主题卡 6 列" />


## 设计原则

- **实测优先** — 视觉与动效参数以像素测量值为准，黄金图回归锁行为
- **组件自包含** — widget / 参数 / 绘制同目录组织，互不泄漏
- **token 驱动** — 颜色、文字、间距、材质统一走主题层，组件内不写字面量
- **API 最小暴露** — 只经 barrel 导出，内部实现可自由演进

## 架构

```
lib/
├── mi_like_ui.dart          # 入口导出层（barrel，唯一对外 API）
├── main.dart                # demo 引导
├── demo/                    # 示例层（演示 app）
└── src/
    ├── theme/               # 样式/主题层（颜色·文字·间距·材质·透明/磨砂 token，明暗双配方）
    ├── components/          # 组件层（类别/组件名/ 两级目录）
    │   ├── navigation/
    │   │   ├── glass_nav_bar/
    │   │   ├── pill_tab_bar/
    │   │   └── top_bar/
    │   ├── buttons/
    │   │   └── button/
    │   ├── inputs/
    │   │   └── search_bar/
    │   └── cards/
    │       └── theme_card/
    ├── icons/               # nav_icons.dart：导航栏 logo 合集（含加号 logo）
    └── utils/               # 工具函数层（纯函数 + 断点/缩放/响应式网格）

test/                        # 黄金图 + 交互测试
```

| 层 | 职责 |
|---|---|
| 导出层 `lib/mi_like_ui.dart` | 唯一对外 API 面 |
| 组件层 `src/components/` | 可复用组件：widget + metrics + painter |
| 主题层 `src/theme/` | 跨组件样式 token（玻璃/透明参数统一配置，组件同源取值） |
| 图标 `src/icons/nav_icons.dart` | 导航栏 logo 合集（`*IconPainter`） |
| 工具层 `src/utils/` | 无状态纯函数 |
| 示例层 `lib/demo/` | 演示 app，模拟真实使用方 |

## 约定

- 公共类 `Mi` 前缀（`MiGlassNavBar`、`MiColors`）；图标 painter 用 `*IconPainter`
- 文件名 snake_case 取事物名；组件常量进 `<组件名>_metrics.dart`
- 使用方与测试只 import barrel；未导出的 `src/` 实现即内部，不承诺 API 稳定

## 扩充新组件

1. `src/components/<类别>/<组件名>/` 建目录（widget / metrics / painter）
2. 样式取主题层 token，缺则先补 token
3. barrel 补一行 `export`
4. 测试与 demo 各补一例
5. `flutter analyze` + `flutter test` 全绿后提交

## 开发

```bash
flutter run      # 运行演示
flutter test     # 回归测试
```

## 路线图

- [x] `MiGlassNavBar` — 玻璃悬浮底部导航栏
- [x] `MiPillTabBar` — 胶囊分类标签行
- [x] `MiButton` — 按钮
- [x] `MiSearchBar` — 搜索栏（与导航栏共用透明磨砂参数）
- [x] `MiTopBar` — 大标题折叠顶部导航栏（渐进磨砂材质）
- [x] `MiThemeCard` — 竖向预览卡片（主题商店精选卡）
- [x] `MiScaledCanvas` / `MiResponsiveGrid` / `MiViewport` — 断点与等比缩放（桌面/平板/手机自适应）
- [ ] `MiDialog` — 弹窗
- [ ] `MiForm` — 表单
- [ ] `MiTheme` — 主题聚合
