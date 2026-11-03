# 架构

本文件说明 `mi_like_ui` 的**分层、依赖规则、目录职责与扩展方式**。
组件用法与 API 细节见 [MODULES.md](MODULES.md) 与 [USAGE.md](USAGE.md)，
逐组件的设计度量见 [README](../README.md) 的组件章节。

## 1. 定位

小米 HyperOS 设计语言的 Flutter 组件库：视觉与动效规格来自**设计度量**
（像素级测量换算到 393dp 设计宽），无第三方运行时依赖，只依赖 Flutter SDK。

四条贯穿全库的原则：

| 原则 | 落地方式 |
|---|---|
| **度量驱动** | 几何 / 排版 / 动效一律进 `*_metrics.dart`，注释写明「度量 / 推导 / 参考实现值」三种口径；素材没有的一律标推导并写依据 |
| **单一来源** | 透明与磨砂只有 `transparency_tokens.dart` 一个来源，跨组件动效只有 `motion_tokens.dart`，列表行几何只有 `row_tokens.dart`；其余层**只引用**，由源码扫描测试守门 |
| **结构恒定** | 组件在状态间不增删渲染层级（避免滚动位置归零、黄金图抖动）；淡出用颜色 alpha 而非 `Opacity`（磨砂子树套 `Opacity` 会让 backdrop 变空） |
| **可回归** | 视觉、性能、令牌约束、分层全部由测试锁定；改动必须让 400+ 例测试与黄金图基线同时成立 |

## 2. 分层与依赖方向

```
┌─────────────┐  ┌──────────────┐
│   theme     │  │    icons     │   最底层：设计 token / 图标 painter
└──────┬──────┘  └──────┬───────┘
       ↓                ↓
┌────────────────────────────────┐
│  foundations                   │  squircle、按压 / 悬停 / 焦点、滤镜缓存、格位数学
└──────────────┬─────────────────┘
               ↓
┌────────────────────────────────┐
│  layout                        │  断点 / 视口 / 缩放画布 / 内容列 / 自适应网格 / 滚动作用域
└──────────────┬─────────────────┘
               ↓
┌────────────────────────────────┐
│  components                    │  navigation / buttons / inputs / lists / cards / effects
└──────────────┬─────────────────┘
               ↓
┌────────────────────────────────┐
│  overlays                      │  宿主与注册表 + 弹框 / 抽屉 / 面板 / 轻提示 / 悬浮容器
└──────────────┬─────────────────┘
               ↓
        lib/mi_like_ui.dart       唯一对外出口（barrel）
```

规则（`test/architecture_test.dart` 逐条断言）：

- `theme` 不依赖任何内部层；
- `icons` 只吃 Flutter（不依赖 theme，图标是纯 painter）；
- `foundations` 不依赖 `layout` / `components` / `overlays`；
- `layout` 不依赖 `components` / `overlays`；
- `components` **不依赖** `overlays`；
- `overlays` **不依赖** `components`（浮层自带零件）。

> 为什么较真：越层依赖会让「改下层要动上层、复用下层得连带上层」。上一版
> `MiPreferenceTileMetrics` 直接引 `MiDialogListMetrics.rowHeight` 拿行高，
> 组件层向上层要几何 —— 行几何因此上提为 `MiRowMetrics`（theme），
> `MiDialogListMetrics` 改为同源转发。

## 3. 目录地图

```
lib/
├── mi_like_ui.dart            唯一对外 API（barrel；分区导出 + 分层说明）
├── main.dart                  演示应用入口
├── demo/                      示例层（模拟真实使用方，不参与库导出）
│   ├── demo_app.dart          演示外壳：明暗切换 / 设备语境 / 导航形态
│   ├── mock_pages.dart        页面入口（MockPage）+ 跨页面共享小件 + part 声明
│   ├── pages/                 按页面拆的 part：profile / home / showcase / search
│   └── host_device*.dart      平台设备语境判定（io / web 条件导入）
└── src/
    ├── theme/                 设计 token（22 个文件）
    │   ├── colors.dart        度量色板（强调色 / 页底色 / 墨色阶梯）
    │   ├── dimens.dart        间距阶梯 / 圆角 / 禁用透明档
    │   ├── typography.dart    字号 / 字重 / 行距（含基线锚定口径）
    │   ├── theme_mode.dart    明暗枚举
    │   ├── mi_theme.dart      App 级注入点（模式 / 品牌色 / 页底色）
    │   ├── motion_tokens.dart 跨组件动效（按压 / 弹簧 / miSpring 换算）
    │   ├── transparency_tokens.dart  透明·磨砂·叠色·遮罩的唯一来源
    │   ├── row_tokens.dart    列表行几何（设置行 / 偏好行 / 弹框列表共用）
    │   └── <组件>_tokens.dart 各组件配色（glass / pill_tab / button / dialog / …）
    ├── foundations/           视觉与交互基元
    │   ├── squircle.dart      G2 连续圆角：path / clipper / border / shadow
    │   ├── pressable.dart     按压状态机 + 悬停 + 焦点三态合一
    │   ├── hover_feedback.dart  指针悬停叠色 + 手型光标
    │   ├── focus_ring.dart    键盘焦点环 + Enter / Space 激活
    │   ├── glass_rim.dart     玻璃边缘高光 painter
    │   ├── filter_cache.dart  ImageFilter 按 σ 缓存
    │   └── cell_grid.dart     等分格位数学（下标 / 最近格）
    ├── layout/                响应式与滚动
    │   ├── responsive.dart    断点 / 视口 / 缩放画布 / 内容列 / 自适应网格
    │   └── scroll_binder.dart 滚动位移作用域（免逐页 NotificationListener）
    ├── components/            组件层（类别 / 组件名 /）
    │   ├── navigation/        top_bar · glass_nav_bar · glass_side_nav_bar · pill_tab_bar · card_page_route
    │   ├── buttons/           button · action_entry
    │   ├── inputs/            search_bar（含取消钮）· switch · checkbox · slider
    │   ├── lists/             settings_row（卡片 / 行 / 图标块）· preference_tile
    │   ├── cards/             theme_card
    │   └── effects/           gradient_blur
    ├── overlays/              浮层
    │   ├── popup_host.dart    宿主 + 注册表 + MiPopup（单点渲染层）
    │   ├── dialog/            弹框（含列表形态 / 命令式 showMiDialog）
    │   ├── bottom_sheet/      底部弹窗
    │   ├── pull_up_panel/     弹出面板（按钮弹起）
    │   ├── snackbar/          轻提示
    │   └── floating_toolbar/  悬浮工具栏
    └── icons/                 导航图标 painter 合集

test/                          单元 / 交互 / 视觉回归 / 约束守门
doc/preview/                   README 配图（由 preview_capture_test 生成）
```

单个组件目录的固定形态：

```
components/<类别>/<组件名>/
├── <组件名>.dart             widget（公开类 Mi<组件名>）
├── <组件名>_metrics.dart     几何与动效规格（含口径注释）
└── <组件名>_painter.dart     内部 painter（可选；不导出）
```

## 4. Token 的三层

| 种类 | 位置 | 例子 | 谁能改 |
|---|---|---|---|
| 全局基础 | `colors` / `dimens` / `typography` / `motion_tokens` / `transparency_tokens` / `row_tokens` | `MiColors.accent`、`MiDimens.spaceLg`、`MiMotionTokens.pressMs` | 跨组件复用，改动需全量回归 |
| 组件配色 | `theme/<组件>_tokens.dart` | `MiDialogPalette.title`、`MiGlassPalette.of(mode)` | 组件内部消费；跨组件复用优先上提 |
| 组件几何 | `components/**/<组件>_metrics.dart` | `MiDialogMetrics.cardWidth`、`MiSwitchMetrics.travel` | 该组件私有，可自由调整 |

**「同源转发」手法**：需要把某个值公开到组件层、但真源在别处时，用一行
`static const double x = MiSource.y;` 转发，而不是抄数值。已用于
`MiTopBarMetrics.pressFadeInMs`、`MiDialogListMetrics.rowHeight`、
`MiSwitchMetrics.disabledOpacity`、`MiCheckboxMetrics.pressMs` 等。

**明暗双配方**：配色 token 一律给 `of(MiThemeMode)` / `xxxFor(mode)` 两个
入口，组件只传 `mode`。模式解析统一走 `MiTheme.modeOf(context, explicit:)`，
优先级 **组件显式参数 > `MiTheme` 声明 > 环境 `Theme.brightness`**。

## 5. 关键机制

- **连续圆角**：全库圆角走 `MiSquircleBorder` / `MiSquircleClipper`（G2 连续
  曲率，extension 1.1 / control 0.643）；半径 ≥ 半短边时退化为真半圆。
  描边用 `side`，贴底形态用 `topOnly`。
- **三态反馈**：按压 / 悬停 / 焦点统一由 `MiPressable` 组装（手势 + 叠色 +
  焦点环），按压**视觉**留在组件层（`pressBuilder`）—— 各组件的按压语言不同
  （按钮换填充、返回钮淡入圆盘、开关放大钮体、设置行满铺高亮带）。
- **浮层**：`MiPopupHost` 是**单点渲染层**，`MiPopup` 把自身注册进
  `MiPopupRegistry`（插入序即 z 序）。没有宿主时就地渲染，包了宿主则统一画
  在宿主 Stack 顶层。注册表变更通知合并到帧末（构建期同步通知会触发宿主的
  `setState() called during build`）。
- **响应式三断点各管一件事**：窗口宽 `MiViewport`（compact < 600 /
  medium 600–1023 / expanded ≥ 1024）、画面容器宽 `usesSideNav(w) = w > 600`
  （底栏 vs 侧栏）、内容容器宽 `MiResponsiveGrid`（列数）。混用会错。
- **性能**：`BackdropFilter` 每帧一次全 QUAD 高斯，口径是「一次 build 的
  层数 + 覆盖面积 dp²」，由 `perf_budget_test.dart` 钉住；滚动时降 σ
  （`sigmaScale`）换帧率。

## 6. 命名规范

| 对象 | 规范 | 反例 |
|---|---|---|
| 公开类 | `Mi` 前缀 + 大驼峰 | ~~GlassBar~~ |
| 私有零件 | `_` 前缀（同文件）或 `_Xxx` 类 | — |
| 文件名 | snake_case，且与主类同名去前缀 | `side_nav_bar.dart` 里放 `MiGlassSideNavBar` ✗ |
| metrics | `<文件名>_metrics.dart` | `search_cancel_metrics.dart`（缺 `button`）✗ |
| painter | `<文件名>_painter.dart`，类名 `XxxPainter` | — |
| token | `theme/<组件>_tokens.dart`，类名 `Mi<组件>Palette` | — |
| 常量 | 语义命名（`pressMs` / `travel`），带单位后缀 `Ms` / `Px`（dp 不加后缀） | ~~k300~~ |

## 7. 扩展一个组件

1. 选类别建目录：`src/components/<类别>/<组件名>/`（浮层则 `src/overlays/<组件名>/`）
2. 写 `<组件名>.dart`（`Mi` 前缀公开类）、`<组件名>_metrics.dart`（几何 + 口径注释）
3. 配色：先看能否复用既有 `*_tokens.dart`；不够再新建 `theme/<组件>_tokens.dart`
4. 交互：三态走 `MiPressable`，圆角走 `MiSquircleBorder`，动效取 `MiMotionTokens`
   或本组件 metrics（**别在实现文件里写裸时长 / 裸 alpha**）
5. `lib/mi_like_ui.dart` 补 export（`architecture_test` 会检查遗漏）
6. 补测试：`test/<组件名>_test.dart`（几何 / 交互 / 语义 / 主题）
7. 演示：`lib/demo/pages/showcase_page.dart` 加一节陈列
8. 跑 `flutter analyze` + `flutter test`；若样式变化，用
   `flutter test --update-goldens test/preview_capture_test.dart` 刷新 README 配图

## 8. 质量门

| 测试 | 守什么 |
|---|---|
| `architecture_test.dart` | 分层依赖方向、barrel 死链与覆盖 |
| `transparency_config_test.dart` | alpha / 模糊 / 叠色字面量只允许在 `transparency_tokens.dart`；theme 层与组件层（含浮层）一律只引用 |
| `motion_config_test.dart` | 裸时长 / 裸弹簧 / 自创贝塞尔只允许在 `motion_tokens.dart` 与 `*_metrics.dart`；另断「同一套按压语言」三方同值 |
| `perf_budget_test.dart` | 每帧模糊层数与覆盖面积上限（手机 / 平板 / 桌面三档） |
| `*_golden_test.dart` / `preview_capture_test.dart` | 逐像素视觉回归（同时产出 README 配图） |
| `*_test.dart`（各组件） | 几何、交互、语义、键盘可达性、明暗配方 |

`flutter test` 全量约 15 秒；`preview_capture_test` 依赖系统中文字体（Windows
环境下生成），CI 以 `--exclude-tags preview` 排除。
