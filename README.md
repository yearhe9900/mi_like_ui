# mi_like_ui

小米风格可扩展 UI 组件框架（Flutter）。

以「像素级实测复刻」为方法论：所有视觉与动效参数都从参考视频逐帧测量得到，再落成
分层清晰、可持续扩充的组件库。首个组件 **`MiGlassNavBar`**（深色玻璃悬浮底部导航栏）
复刻自 1220×2656 @ 24fps 屏幕录制，全部行为与测量值对齐。

## 特性

`MiGlassNavBar` 的六个实测行为：

| 行为 | 实测参数 |
|---|---|
| 磨砂玻璃 | 深色遮罩 `rgba(20,20,20,0.63)` + 胶囊透镜，透射 `out = 0.37·in + 12.6`（非纯色块） |
| 果冻切换 | 飞行 easeOutSine、260+20×格数 ms，形变峰值 +35% 宽 / -7.5% 高 |
| 弹簧沉降 | 落位过冲 +3.7% 格宽、宽 -2.2%，350 ms 阻尼回弹；端部钳位转宽度压缩 |
| 按压缩圈 | 按下即胶囊 -3% 宽 / -7.5% 高（90 ms），被按 tab 瞬时变暗 55% |
| 拖拽切换 | 胶囊 1:1 跟手，速度拉伸 +5.6%（停手 80 ms 衰减），松手吸附最近 tab |
| 图标对齐 | 四个图标与标签严格共心（视频同约定，偏差 ≤0.5 px） |

## 快速开始

运行演示（含四个 mock 页面、按压/拖拽交互）：

```bash
flutter run
```

作为组件使用 —— 只需一行 barrel 导入：

```dart
import 'package:mi_like_ui/mi_like_ui.dart';

MiGlassNavBar(
  items: [
    MiGlassNavItem(label: '首页', painter: RollerIconPainter(MiColors.foreground)),
    MiGlassNavItem(label: '分类', painter: GridSparkleIconPainter(MiColors.foreground)),
    MiGlassNavItem(label: '每日精选', painter: CardsStarIconPainter(MiColors.foreground)),
    MiGlassNavItem(label: '我的', painter: SmileyBeretIconPainter(MiColors.foreground)),
  ],
  selectedIndex: _index,
  onTap: (i) => setState(() => _index = i),
)
```

## 架构

```
lib/
├── mi_like_ui.dart                  # ★ 入口导出层（barrel）——对外唯一 API 入口
├── main.dart                        # demo 引导（仅 runApp）
├── demo/                            # 示例层（只 import barrel，不被框架引用）
│   ├── demo_app.dart                #   DemoApp / DemoHome
│   └── mock_pages.dart              #   演示用 mock 页面
└── src/                             # 框架实现（未导出即内部）
    ├── theme/                       # 样式/主题层
    │   ├── colors.dart              #   MiColors —— 颜色 token
    │   ├── typography.dart          #   MiTypography —— 文字样式 token
    │   ├── dimens.dart              #   MiDimens —— 间距/圆角 token
    │   └── glass_tokens.dart        #   MiGlassTokens —— 磨砂玻璃材质配方
    ├── components/                  # 组件层（类别/组件名/ 两级目录）
    │   └── navigation/
    │       └── glass_nav_bar/
    │           ├── glass_nav_bar.dart           # MiGlassNavBar / MiGlassNavItem
    │           ├── glass_nav_bar_metrics.dart   # MiGlassNavMetrics（几何/动效参数）
    │           └── glass_nav_bar_painter.dart   # GlassBarPainter（内部，不导出）
    ├── icons/
    │   └── nav_icons.dart           # *IconPainter 图标 painter 集
    └── utils/
        └── cell_grid.dart           # 等分格位索引/吸附纯函数

test/
├── golden_test.dart                 # 黄金图 + 交互 widget 测试（只 import barrel）
└── goldens/                         # 黄金图基线（5 张）
```

| 层 | 目录 | 职责 | 谁可以引用 |
|---|---|---|---|
| 导出层 | `lib/mi_like_ui.dart` | 唯一对外 API 面；`src/` 未导出的即内部实现 | 使用方 |
| 组件层 | `src/components/<类别>/<组件名>/` | 自包含组件：widget + metrics + painter | 经 barrel |
| 主题层 | `src/theme/` | 跨组件 token：颜色、文字、间距、材质配方 | 组件层、使用方 |
| 图标 | `src/icons/` | `*IconPainter` 图标 painter | 组件层、使用方 |
| 工具层 | `src/utils/` | 无状态纯函数 | 组件层 |
| 示例层 | `lib/demo/` | 演示 app，模拟真实使用方 | 不被框架引用 |

## 命名与导出约定

- **公共类**：组件与主题 token 用 `Mi` 前缀（`MiGlassNavBar`、`MiColors`）；图标 painter 用 `*IconPainter` 后缀。
- **内部类**：不加 `Mi` 前缀、不进 barrel（如 `GlassBarPainter`），不承诺 API 稳定。
- **文件名**：snake_case 取事物名（`glass_nav_bar.dart`、`colors.dart`）；组件目录 = 组件名；
  组件专属几何/动效常量拆 `<组件名>_metrics.dart`。
- **常量**：`static const` lowerCamelCase；组件参数不散落在 widget 内，一律进 metrics。
- **导出**：一律经 barrel 一行 `export`；使用方与测试**只 import barrel**（导出面缺失测试即报错）。

## 新增组件流程

1. `src/components/<类别>/<组件名>/` 建目录：`<组件名>.dart`（类名 `MiXxx`）、
   `<组件名>_metrics.dart`、内部 painter 拆 `<组件名>_painter.dart`。
2. 颜色/文字/间距/材质一律取 `src/theme/` token；缺 token 先补 token，不在组件里写字面量。
3. 通用纯函数下沉 `src/utils/`；组件之间不互相 import 内部文件。
4. `lib/mi_like_ui.dart` 补一行 `export`。
5. `test/` 加黄金图/交互测试，`lib/demo/` 加一页演示。
6. `flutter analyze` + `flutter test` 全绿后提交。

## 测试

```bash
flutter test                    # 5 例全量回归
flutter test --update-goldens   # 视觉变更后重生成基线（须人工复核像素 diff）
```

| 黄金图 | 锁住的行为 |
|---|---|
| `settled_tab1/tab4.png` | 静止态胶囊几何（端部钳位） |
| `midflight.png` | 飞行果冻形变峰值 |
| `press_tab1.png` | 按压缩圈 + 被按 tab 变暗 |
| `drag_mid.png` | 拖拽跟手 + 速度拉伸（另有吸附切换断言） |

## 实测依据

- 参考视频：1220×2656 @ 24fps 屏幕录制（小米主题商店）；几何按 393dp 设计宽换算（s = 0.32213）。
- 全部测量模型（几何、飞行/沉降曲线、按压/拖拽、玻璃透射）记录在
  `src/components/navigation/glass_nav_bar/glass_nav_bar_metrics.dart` 顶部注释。
- 排查方法：以 1px 原始像素数值为准，目测截图在缩放下不可靠；黄金图字节级比对
  （逐像素 diff）是"零破坏"的验收标准。

## 路线图

- [x] `MiGlassNavBar` — 玻璃悬浮底部导航栏
- [ ] `MiButton` — 胶囊/玻璃按钮
- [ ] `MiDialog` — 玻璃弹窗
- [ ] `MiForm` — 输入框/表单
- [ ] `MiTheme` — 整体主题聚合与深浅色切换

新组件按「新增组件流程」落地，视觉参数同样以实测/设计稿像素值为准。
