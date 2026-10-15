# mi_like_ui

小米风格可扩展 UI 组件框架雏形。首个组件 `MiGlassNavBar`（深色玻璃悬浮底部导航栏）
为参考视频（1220x2656 @ 24fps）逐帧实测 1:1 复刻：果冻胶囊切换、弹簧沉降、
按压缩圈、拖拽切换、磨砂玻璃透射均与视频测量值对齐。

## 目录结构

```
lib/
├── mi_like_ui.dart                  # ★ 入口导出层（barrel）——对外唯一 API 入口
├── main.dart                        # demo 引导（仅 runApp，示例层入口）
├── demo/                            # 示例层（不属于框架 API，不导出）
│   ├── demo_app.dart                #   DemoApp / DemoHome
│   └── mock_pages.dart              #   演示用 mock 页面
└── src/                             # 框架实现（对外仅经 barrel 暴露）
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
        └── cell_grid.dart           # 等分格位索引/吸附数学

test/
├── golden_test.dart                 # 黄金图 + 交互 widget 测试（只 import barrel）
└── goldens/                         # 黄金图基线（5 张）
```

## 分层职责

| 层 | 目录 | 职责 | 谁可以引用 |
|---|---|---|---|
| 导出层 | `lib/mi_like_ui.dart` | 唯一对外 API 面；`src/` 未导出的即内部实现 | 使用方 |
| 组件层 | `src/components/<类别>/<组件名>/` | 自包含组件：widget + metrics + painter | 经 barrel |
| 主题层 | `src/theme/` | 跨组件 token：颜色、文字、间距、材质配方 | 组件层、使用方 |
| 图标 | `src/icons/` | `*IconPainter` 图标 painter | 组件层、使用方 |
| 工具层 | `src/utils/` | 无状态纯函数 | 组件层 |
| 示例层 | `lib/demo/` | 演示 app，模拟真实使用方（只 import barrel） | 不被框架引用 |

## 命名与导出约定

- **公共类**：组件与主题 token 用 `Mi` 前缀 + 大驼峰（`MiGlassNavBar`、`MiColors`）；
  图标 painter 用 `*IconPainter` 后缀。
- **内部类**：不加 `Mi` 前缀、不进 barrel（如 `GlassBarPainter`），不承诺 API 稳定。
- **文件名**：snake_case，取"事物名"本身（`glass_nav_bar.dart`、`colors.dart`）。
  组件目录 = 组件名；每个组件自己的几何/动效常量放 `<组件名>_metrics.dart`。
- **常量**：lowerCamelCase `static const`；组件专属参数不得散落在 widget 内。
- **对外导出**：一律经 `lib/mi_like_ui.dart` 一行 `export`；使用方与测试**只 import barrel**。

## 新增组件的流程（如按钮、弹窗、表单）

1. 在 `src/components/<类别>/<组件名>/` 建目录，写 `<组件名>.dart`（类名 `MiXxx`）；
   专属几何/动效常量拆到 `<组件名>_metrics.dart`，内部 painter 拆到 `<组件名>_painter.dart`。
2. 颜色/文字/间距/材质一律取 `src/theme/` token；缺 token 就先补 token，不在组件里写字面量。
3. 通用纯函数放 `src/utils/`，组件间不互相 import 内部文件（只能经 barrel 或 theme/utils）。
4. 在 `lib/mi_like_ui.dart` 补一行 `export`。
5. `test/` 加黄金图/交互测试（import barrel），`lib/demo/` 加一页演示。
6. `flutter analyze` + `flutter test` 全绿后提交。

## 运行 demo

```
flutter run
```

## 测试

```
flutter test                 # 5 例：settled x2 / mid-flight / 按压缩圈 / 拖拽跟手
flutter test --update-goldens  # 视觉变更后重生成基线（须人工复核 diff）
```

黄金图基线与参考视频测量模型的对应关系见
`src/components/navigation/glass_nav_bar/glass_nav_bar_metrics.dart` 顶部注释。
