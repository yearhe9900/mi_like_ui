# mi_like_ui

小米风格（HyperOS 设计语言）Flutter UI 组件库：玻璃导航、折叠顶栏、搜索栏、
弹框等成套组件，像素级设计规格、明暗双模式、响应式布局。

组件视觉与动效规格取自设计度量（像素级测量），沉淀为分层清晰、可持续扩充的
组件库；渲染行为由视觉回归测试锁定。

## 特性

- **成套组件**：玻璃悬浮底部 / 侧边导航栏、胶囊标签行、胶囊按钮、搜索栏、
  大标题折叠顶栏、渐进模糊、主题卡片、弹框
- **明暗双模式**：全部组件提供深 / 浅两套配方，`MiThemeMode` 统一切换
- **像素级设计规格**：几何、排版、配色、动效曲线均以设计规格数值定义
  （见各组件 `*_metrics.dart`），跨字体排版稳定（基线锚定）
- **透明 / 磨砂体系**：模糊、叠色、玻璃膜参数集中在
  `MiTransparencyTokens` 单一来源，组件只引用不重复定义
- **响应式**：手机 / 平板 / 桌面三档断点，导航形态、网格列数、等比缩放画布
- **性能预算化**：每帧模糊层数与覆盖面积入回归预算，防止渲染开销回退

## 快速开始

运行演示应用（含全部组件、明暗切换、三档窗口自适应）：

```bash
flutter run
```

在应用中使用：

```dart
import 'package:mi_like_ui/mi_like_ui.dart';

// 底部导航栏（宽屏自动建议换侧栏，见「响应式」）
MiGlassNavBar(
  items: [
    MiGlassNavItem(label: '首页', painter: RollerIconPainter(ink)),
    MiGlassNavItem(label: '分类', painter: GridSparkleIconPainter(ink)),
    MiGlassNavItem(label: '我的', painter: SmileyBeretIconPainter(ink)),
  ],
  selectedIndex: 0,
  onTap: (i) => setState(() => _index = i),
  themeMode: MiThemeMode.dark,
);
```

`lib/mi_like_ui.dart` 是唯一对外 API 入口；`src/` 下未导出的实现属内部，
不承诺 API 稳定。

## 组件总览

| 组件 | 说明 |
|---|---|
| `MiGlassNavBar` | 玻璃悬浮底部导航栏（果冻胶囊选中动效、可挂 FAB） |
| `MiGlassSideNavBar` | 玻璃悬浮侧边导航栏（宽屏 / 桌面形态，与底部栏同语义同配方） |
| `MiPillTabBar` | 胶囊分类标签行（选中胶囊磨砂透镜、出血滚动） |
| `MiButton` | 胶囊按钮（主 / 次级 / 禁用三态） |
| `MiSearchBar` | 搜索栏（静态展示 / 可输入两态，磨砂与导航栏同源） |
| `MiSearchCancelButton` | 搜索取消按钮（搜索态配套） |
| `MiTopBar` | 大标题折叠顶部导航栏（渐进磨砂材质、可内嵌搜索栏 / 标签行、搜索态） |
| `MiGradientBlur` | 内容顶部渐进模糊（可独立使用，不依赖顶栏） |
| `MiThemeCard` | 竖向预览卡片（主题卡） |
| `MiDialog` | 弹框（遮罩 + 卡片、三档位置、三种按钮形态、按压动效） |
| `MiCardPageRoute` | 页面推入转场（右侧滑入 + 前缘圆角、下层页视差与压暗） |
| `MiScaledCanvas` / `MiResponsiveGrid` / `MiViewport` / `MiBreakpoints` | 断点判定、等比缩放画布、响应式网格 |

## 组件

### 玻璃悬浮底部导航栏（MiGlassNavBar）

悬浮式玻璃材质底部导航栏，选中态为「胶囊透镜」，支持果冻形变的切换动效
（按压挤压、拖拽跟随、弹簧沉降），可挂载浮动圆钮（`MiGlassNavFab`）。

**规格**（详见 `MiGlassNavMetrics`）：栏高 55.4dp、左右边距 25.5dp、
单格宽 82.2dp、胶囊高 49.3dp、图标高 23.2dp、标签 10.5dp Medium；
FAB 直径 55.4dp。玻璃配方（σ = 28dp 磨砂、栏体遮罩、透镜、外缘高光）见
`MiGlassPalette` 与 `MiTransparencyTokens`。

导航条目由 `MiGlassNavItem`（标签 + 图标 painter）声明，`selectedIndex` /
`onTap(index)` 受控；`MiGlassNavFab` 可选，与栏体显隐契约、弹出曲线同源。

<img src="doc/preview/nav_dark.png" width="360" alt="深色模式导航栏" /> <img src="doc/preview/nav_light.png" width="360" alt="浅色模式导航栏" />

### 玻璃悬浮侧边导航栏（MiGlassSideNavBar）

底部栏的纵向形态，用于宽屏 / 桌面：容器宽 **> 600dp** 时建议改用侧栏
（判定函数 `MiBreakpoints.usesSideNav(width)`），手机竖屏 / 窄窗保留底部栏。
两者共用同一份 `MiGlassNavItem`、`selectedIndex` 与 `onTap`，选中反馈与交互
语义完全一致；玻璃配方、动效曲线复用底部栏 token，仅运动轴换向。

**规格**（详见 `MiGlassSideNavMetrics`）：栏宽 95.4dp、条目高 49.3dp、
条目间距 8dp、栏体圆角与胶囊同心（内外圈等距 6.6dp）；FAB 挂于栏尾下方、
栏体不为其让位。侧栏几何为底部栏规格的纵向换算（推导值）。

> **形态切换建议直接替换子树、不做淡入淡出**：`Opacity` /
> `AnimatedSwitcher` 会对含 `BackdropFilter` 的子树引入 saveLayer，
> 切换期间磨砂会整段消失。

<img src="doc/preview/nav_side_light.png" width="150" alt="浅色侧边导航栏" /> <img src="doc/preview/nav_side_dark.png" width="150" alt="深色侧边导航栏" />

### 胶囊分类标签行（MiPillTabBar）

横向分类标签行，选中项为磨砂玻璃胶囊（透镜），支持出血滚动；适合吸顶
分类切换场景（滚动内容可从半透明胶囊后方经过）。

**规格**（详见 `MiPillTabBarMetrics`）：胶囊 87.6×39.9dp、胶囊间距 /
两端留白 11.9dp、标签 13.85dp Medium；磨砂膜与填充配方见
`MiPillTabPalette` 与 `MiTransparencyTokens`。

<img src="doc/preview/pill_light.png" width="360" alt="浅色胶囊分类标签行" /> <img src="doc/preview/pill_dark.png" width="360" alt="深色胶囊分类标签行" />

### 胶囊按钮（MiButton）

胶囊形按钮，主 / 次级 / 禁用三态；宽度随内容自适应。

**规格**（详见 `MiButtonMetrics`）：高 28.3dp stadium、左右内边距 17dp、
标签 13dp Medium；主按钮填充 `MiColors.accent`（#4980F7，明暗同色）。
`onPressed` 为 `null` 时进入禁用态。

<img src="doc/preview/button_light.png" width="360" alt="浅色胶囊按钮三态" /> <img src="doc/preview/button_dark.png" width="360" alt="深色胶囊按钮三态" />

### 搜索栏（MiSearchBar / MiSearchCancelButton）

圆角搜索栏，两态：

- **静态展示态**：放大镜 + 占位文字，可点按；
- **输入态**（`editable: true`）：真实 `TextField`，支持 `controller` /
  `focusNode` / `onChanged` / `onSubmitted` 等标准输入参数。

**规格**（详见 `MiSearchBarMetrics` / `MiSearchCancelMetrics`）：栏高 44.1dp、
图标 17.8dp、图标与文字间距 12dp、正文 16.5dp；取消钮直径 44.1dp（等于
栏高）。磨砂与填充同导航栏透明体系。

搜索态配套的布局行为（取消钮淡入、让位、光标闪烁）见「搜索态」一节。

### 大标题折叠顶部导航栏（MiTopBar)

滚动联动的顶栏，两种标题形态与可选头部区：

- **大标题折叠**：大标题随内容滚动上移并沿独立曲线淡出，紧凑标题在
  高度约 20dp 处淡入衔接，两段不重叠；标题基线以 `Baseline` 锚定，
  垂直落点不随字体族漂移；
- **头部区内嵌**（可选）：传 `searchHint` / `tabs` 等数据参数，顶栏内部
  产出 `MiSearchBar` / `MiPillTabBar` 并统一解析明暗配方；需要自定义时
  可用同名插槽 `searchBar` / `tabBar` / `header` 替换（与数据参数互斥，
  构造期校验）；
- **搜索态**（`searchActive` / `onSearchCancel`）：内置搜索栏切换为输入态，
  右侧淡入取消钮、胶囊标签淡出并退出排版；
- **材质开关**：`showBlur`（顶部磨砂）与 `showSurface`（顶部压色）独立控制。

**规格**（详见 `MiTopBarMetrics`）：紧凑标题 18.0dp Medium（居中）、
大标题 31.83dp Medium；内容首行顶缘分两档 —— 卡片类 `contentTopInset`
183dp、搜索栏类 `searchBarTopInset` 168.5dp；返回圆钮直径 44.1dp
（`showBack: true` 显示，`onBack` 决定可点性）。

**磨砂材质**按是否有头部分两种形态：

- 无头部区（纯标题 / 纯材质）：**渐进磨砂** —— σ 自栏顶 5.37dp 向下衰减，
  在材质盒底归零（曲线标称跨度 119dp，按盒高等比拉伸）；
- 有头部区（搜索栏 + 标签行）：**恒定磨砂** —— σ 5.37dp 铺满整条头部区，
  栏底硬切回清晰。

Flutter 无位置相关模糊，渐进曲线以**分段定 σ 阶梯**实现（相邻段 σ 比
≤ 1.5、段高 ≤ 17dp，视觉无台阶）；高度以 `bar.occupiedHeight(context)`
对外声明，供滚动内容让位。

下图每格分别为：纯材质形态、顶层页（首行搜索栏）、次级页（返回钮 + 卡片）、
滚动折叠中（紧凑标题浮现）：

<img src="doc/preview/top_bar_light.png" width="200" alt="浅色顶栏四态" /> <img src="doc/preview/top_bar_dark.png" width="200" alt="深色顶栏四态" />

### 顶部渐进模糊（MiGradientBlur）

「内容顶部被磨开、越往下越清晰」的渐进模糊层，可独立挂载于任意滚动内容，
不依赖顶栏：

```dart
Stack(children: [
  ListView(children: [...]),
  Positioned(
    top: 0, left: 0, right: 0,
    child: MiGradientBlur(height: 120), // 120dp 内由 σ5.37 衰减至 0
  ),
]);
```

曲线形状固定、作用区高度随 `height` 等比伸缩，区底无硬边。上层若有
不透明压色，可传 `opaqueScrimBottom` + `underSurface: true` 跳过被完全
遮住的段落以节省渲染（此配置下压色必须不透明）。`MiTopBar(showBlur: true)`
内部即复用本组件，曲线与几何同源。

### 主题卡片（MiThemeCard）

竖向预览卡片：上部预览图（定比 259:472、圆角 20dp）、下部单行标题
（13.85dp Medium，较图左缘内缩 8.8dp，与区块标题同列起排）。

<img src="doc/preview/card_light.png" width="360" alt="浅色主题卡片" /> <img src="doc/preview/card_dark.png" width="360" alt="深色主题卡片" />

### 弹框（MiDialog）

遮罩 + 卡片一体的模态弹框，明暗双模式；支持三档位置、三种按钮形态、
按压动效，卡片高度随正文行数自适应。

**规格**（详见 `MiDialogMetrics`）：卡片宽 369.2dp、圆角 49.3dp、底缘距屏
32.9dp；标题 18.0dp、正文 15.9dp（行距 23.2dp、内容内缩 28dp）；按钮高
49.9dp、圆角 15.0dp、行内缩 24.2dp、按钮间距 12.6dp；标题 / 正文 / 按钮
标签的垂直落点以 `Baseline` 锚定，跨字体稳定。

```dart
MiDialog(
  position: MiDialogPosition.bottom,   // top / center / bottom（默认 bottom）
  title: '删除联系人',
  message: '确定从本地和云端同时删除"方太安装师傅"吗？',
  messageAlign: TextAlign.start,       // 默认居中
  actions: [
    MiDialogAction(label: '取消', onPressed: close),
    MiDialogAction(
      label: '删除',
      style: MiDialogActionStyle.destructive,   // neutral / filled / destructive
      onPressed: close,
    ),
  ],
  onScrimTap: close,
);
```

- **位置**（`MiDialogPosition`）：`bottom`（默认）/ `top`（让开安全区）/
  `center`；
- **按钮形态**（`MiDialogActionStyle`）：`neutral`（中性填充）/ `filled`
  （强调填充 + 白字）/ `destructive`（中性填充 + 红字）；
- **遮罩**：亮色黑 @0.20 / 暗色黑 @0.60，点按触发 `onScrimTap`，由宿主
  决定收起；
- **按压动效**：按下时填充叠按压色（亮色压暗 / 暗色提亮，@0.12），标签
  不变、不缩放，150ms `easeOutQuad` 过渡，松开回弹。

静止态（左「删除联系人」/ 右「删除1项资源」两种内容形态）与按压态（右列）：

<img src="doc/preview/dialog_bottom_dark.png" width="200" alt="深色弹框" /> <img src="doc/preview/dialog_bottom_light.png" width="200" alt="浅色弹框" /> <img src="doc/preview/dialog_bottom_filled_dark.png" width="200" alt="深色弹框（主按钮）" /> <img src="doc/preview/dialog_pressed_dark.png" width="200" alt="深色弹框（主按钮按压态）" />

三档位置：

<img src="doc/preview/dialog_top_dark.png" width="200" alt="深色顶部弹框" /> <img src="doc/preview/dialog_top_light.png" width="200" alt="浅色顶部弹框" /> <img src="doc/preview/dialog_center_dark.png" width="200" alt="深色居中弹框" /> <img src="doc/preview/dialog_center_light.png" width="200" alt="浅色居中弹框" />

### 页面推入转场（MiCardPageRoute）

自右缘推入新页、前缘带大圆角，下层页同时左移视差并压暗 —— 用于「搜索页 /
详情页」这类推进一级的场景。用法与 `MaterialPageRoute` 一致：

```dart
Navigator.of(context).push(MiCardPageRoute<void>(
  builder: (_) => const SearchPage(),
));
```

**规格**（详见 `MiCardPageRouteMetrics`）：时长 400ms、位置曲线 `easeOutCubic`；
新页前缘圆角 61.2dp；下层页左移 `0.25 × 页宽`（只平移、不缩放）；下层页压暗
由 0 线性升至黑 @0.55。新页归位后不保留任何变换层与遮罩（静止页零额外绘制）。

- **两种角色**：`buildTransitions` 同时处理「本页正在进入」与「本页被上层压住」。
  下层页的视差依赖下层路由同样为本类（`secondaryAnimation` 钩子）；下层是平台
  自带路由时仍有压暗，只是没有视差。
- **压暗以纯色填充实现**，不用 `Opacity` / `FadeTransition` —— 后者会给整页引入
  saveLayer，使下层 `BackdropFilter` 的 backdrop 变空、磨砂整段消失。

<img src="doc/preview/push_transition_light.png" width="180" alt="浅色推入转场中" /> <img src="doc/preview/push_transition_dark.png" width="180" alt="深色推入转场中" /> <img src="doc/preview/search_page_dark.png" width="180" alt="落定后的搜索页头部" />

## 材质与透明体系

透明相关参数（模糊 σ、各级填充 / 叠色 alpha、玻璃膜、按压叠色）**只定义于**
`MiTransparencyTokens`，各组件 token 仅引用常量与自身几何；`withOpacity` /
`fromRGBO` / 带 alpha 的色值不允许出现在组件层，由
`test/transparency_config_test.dart` 扫描源码约束。

其中「玻璃膜」用于压在滚动内容上的零件（`overContent: true`）：垫在低调
填充之下预合成（`veiledFill`），使零件在平坦页面上与普通填充无异、内容滚到
其后方时才显出磨砂玻璃质感，无需随滚动状态切换配方。

## 搜索态

搜索两条路径都支持，按页面结构选用：

**① 原地搜索态**（`MiTopBar.searchActive`）—— 搜索栏就地变输入框，右侧淡入
取消钮（`MiSearchCancelButton`），胶囊标签行淡出并退出排版（`occupiedHeight`
由 156dp 收至 100.1dp）；转场 480ms（起手静止 48ms + 位移 `easeOutQuint`），
取消钮淡入与位移不同步、落在转场中段。示例在「分类」页。

**② 推入搜索页**（`MiCardPageRoute`）—— 整页自右缘滑入（见上一节），落定后
头部为「返回圆钮 + 输入框 + 搜索钮」三段：头部行顶缘 52.2dp、圆钮 ⌀44.1dp、
圆钮与输入框 / 输入框与搜索钮各间距 11dp、搜索钮 53.5×40.9dp。示例在首页。

<img src="doc/preview/search_state_light.png" width="180" alt="浅色原地搜索态" /> <img src="doc/preview/search_state_dark.png" width="180" alt="深色原地搜索态" /> <img src="doc/preview/search_page_dark.png" width="180" alt="推入搜索页" />

> 宿主建议：搜索态下收起 App 级导航（专注输入），且键盘弹出时保持画面尺寸
> （`Scaffold(resizeToAvoidBottomInset: false)`），由键盘覆盖而非压缩布局。

> 切换底栏显隐请用换结构（`Visibility` / 条件子树）而非 `Opacity` 淡出，
> 理由同上文「形态切换」。

## 响应式

框架层 `src/utils/responsive.dart` 提供断点判定与等比缩放画布，
示例层 `DemoStage` 据此把内容摆进任意窗口。三类断点各司其职：

| 档位 | 窗口逻辑宽 | 网格列数（主题卡 / 展示位） | 导航形态 |
|---|---|---|---|
| compact | < 600dp | 3 / 4 | 底部栏 |
| medium | 600…1023dp | 4 / 6 | 侧栏 |
| expanded | ≥ 1024dp | 6 / 8 | 侧栏 |

- **窗口断点**（`MiViewport` / `MiBreakpoints.ofWidth`）：决定外壳是否加宽内容；
- **容器断点**（`MiBreakpoints.usesSideNav`，严格 > 600）：决定导航形态；
  判据跟随容器宽度而非窗口宽度，手机画布嵌入宽窗口也不会切换形态；
- **内容断点**（`MiResponsiveGrid`，按容器宽切列）：决定网格列数。

三者判据不同源，请按上表分别取用。等比缩放画布 `MiScaledCanvas` 只缩不放
（`scale = min(1, 可用宽/设计宽, 可用高/设计高)`）：不溢出、不变形，1:1 时
不引入任何变换层。

<img src="doc/preview/adaptive_phone.png" width="120" alt="手机 393×856" /> <img src="doc/preview/adaptive_small_window.png" width="120" alt="小窗 260×470" /> <img src="doc/preview/adaptive_tablet.png" width="200" alt="平板 768×1280" /> <img src="doc/preview/adaptive_desktop.png" width="420" alt="桌面 1366×768" />

桌面浅色（侧栏玻璃体与投影落在浅底上，无拼接缝）：

<img src="doc/preview/adaptive_desktop_light.png" width="520" alt="桌面 1366×768 浅色" />

## 性能

磨砂（`BackdropFilter`）是本库最主要的绘制开销：每帧对 backdrop 重算全
QUAD 高斯，滚动时随 backdrop 变化。为此将「单次构建的模糊层数 + 覆盖面积
（dp²）」固化为性能预算（`test/perf_budget_test.dart`），防止渲染开销回退：

| 形态（深色） | 层数 / 覆盖面积 |
|---|---|
| 手机 393×856 | 7 层 / 52,081 dp² |
| 平板 768×1280 | 首页 7 / 78,562 · 我的 6 / 52,142 · 分类 8 / 109,360 |
| 桌面 1366×768 | 首页 7 / 137,506 · 分类 8 / 194,809 |

已内置的等效优化（视觉零差异）：

1. **跳过被完全遮挡的模糊段**：深色顶栏不透明压色覆盖的区段不参与模糊
   （`MiTopBar.visibleBlurBands`）；
2. **胶囊行模糊合并**：全部胶囊形状一次 `ClipPath` 裁切 + 单次 backdrop
   模糊，相邻胶囊不串色；
3. **`ImageFilter` 按 σ 缓存复用**（`src/utils/filter_cache.dart`），
   σ < 0.5dp 的段（亚像素高斯）不绘制。

性能验证请在 profile 模式下进行（debug 渲染开销数倍于 profile）：

```bash
flutter run --profile                       # 运行后按 P 打开性能 overlay
adb shell dumpsys gfxinfo com.example.bottom_nav_demo reset
# … 在应用里连续滚动 / 切换约 20 秒 …
adb shell dumpsys gfxinfo com.example.bottom_nav_demo | Select-String "Janky frames"
```

## 架构

```
lib/
├── mi_like_ui.dart          # 唯一对外 API（barrel 导出层）
├── main.dart                # 演示应用入口
├── demo/                    # 示例层（演示 app）
└── src/
    ├── theme/               # 样式令牌层（颜色 / 文字 / 间距 / 透明与磨砂，明暗双配方）
    ├── components/          # 组件层（类别 / 组件名 / 两级目录）
    │   ├── navigation/      #   glass_nav_bar · glass_side_nav_bar · pill_tab_bar · top_bar · card_page_route
    │   ├── buttons/         #   button
    │   ├── inputs/          #   search_bar（含取消钮）
    │   ├── cards/           #   theme_card
    │   ├── feedback/        #   dialog
    │   └── effects/         #   gradient_blur
    ├── icons/               # 图标 painter 合集
    └── utils/               # 工具层（断点 / 缩放 / 响应式网格 / 滤镜缓存）

test/                        # 单元 / 交互 / 视觉回归测试
```

| 层 | 职责 |
|---|---|
| 导出层 `lib/mi_like_ui.dart` | 唯一对外 API 面 |
| 组件层 `src/components/` | 可复用组件：widget + metrics + painter |
| 主题层 `src/theme/` | 跨组件样式令牌；透明 / 磨砂参数统一在 `transparency_tokens.dart` |
| 图标 `src/icons/` | 导航图标 painter 合集（`*IconPainter`） |
| 工具层 `src/utils/` | 无状态纯函数 |
| 示例层 `lib/demo/` | 演示应用，模拟真实使用方 |

## 开发与贡献

```bash
flutter run      # 运行演示应用
flutter test     # 全量测试（含视觉回归）
```

**命名与组织约定**

- 公共类型 `Mi` 前缀（`MiGlassNavBar`、`MiColors`）；图标 painter 用
  `*IconPainter`
- 文件名 snake_case；组件常量进 `<组件名>_metrics.dart`，配色进
  `theme/` 对应 `*_tokens.dart`
- 使用方与测试只 import barrel；未导出的 `src/` 实现不承诺 API 稳定
- 透明参数只有一个来源（`transparency_tokens.dart`），其余令牌与组件只引用

**新增组件流程**

1. `src/components/<类别>/<组件名>/` 建目录（widget / metrics / painter）
2. 样式取主题层令牌，缺失则先补令牌
3. barrel 补一行 `export`
4. 测试与演示应用各补一例
5. `flutter analyze` + `flutter test` 全绿后提交

**测试**

- 单元 / 交互测试：`test/*_test.dart`
- 视觉回归：`test/*_golden_test.dart`、`test/preview_capture_test.dart`
  （文档配图亦由此生成，样式变更后以
  `flutter test --update-goldens test/preview_capture_test.dart` 刷新）
- 性能预算：`test/perf_budget_test.dart`
- 令牌约束：`test/transparency_config_test.dart`

## 设计规格与度量

本库的视觉 / 动效参数以**设计度量**为准：从设计参考素材按像素测量、换算为
统一设计宽度（393dp）下的规格值；无直接参考的派生值标注**推导**并在源码注释
中写明换算来源。度量数据与推导过程记录于各组件 `*_metrics.dart` 与
`theme/*_tokens.dart` 的文档注释，排版落点采用基线锚定保证跨字体稳定，
渲染行为由视觉回归测试锁定。

## 路线图

- [x] `MiGlassNavBar` — 玻璃悬浮底部导航栏
- [x] `MiGlassSideNavBar` — 玻璃悬浮侧边导航栏
- [x] `MiPillTabBar` — 胶囊分类标签行
- [x] `MiButton` — 胶囊按钮
- [x] `MiSearchBar` / `MiSearchCancelButton` — 搜索栏与取消钮
- [x] `MiTopBar` — 大标题折叠顶部导航栏（材质 / 头部区 / 搜索态）
- [x] `MiGradientBlur` — 顶部渐进模糊
- [x] `MiThemeCard` — 主题卡片
- [x] `MiDialog` — 弹框
- [x] `MiCardPageRoute` — 页面推入转场
- [x] 响应式工具 — `MiScaledCanvas` / `MiResponsiveGrid` / `MiViewport` / `MiBreakpoints`
- [ ] `MiForm` — 表单
- [ ] `MiTheme` — 主题聚合

## 版本记录

见 [CHANGELOG.md](CHANGELOG.md)，版本号遵循 [Semantic Versioning](https://semver.org/)。
