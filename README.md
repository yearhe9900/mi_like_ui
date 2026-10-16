# mi_like_ui

小米风格可扩展 UI 组件框架（Flutter）。

以像素级实测还原小米系视觉与动效，沉淀为分层清晰、可持续扩充的组件库。
当前已落地 `MiGlassNavBar`（玻璃悬浮底部导航栏）、`MiPillTabBar`
（胶囊分类标签行）、`MiButton`（胶囊按钮）与 `MiSearchBar`（搜索栏，
透明磨砂参数与导航栏同源）；弹窗、表单等组件按同一组织方式逐步扩充。

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

「分类」tab 为组件展示页（「Logo 展示」组前 6 位为 `nav_icons.dart` 全量 logo，「按钮展示」组陈列 `MiButton` 三态，其余为示例占位；标签行吸顶，滚动内容从半透明磨砂胶囊后方经过）：

<img src="doc/preview/showcase_light.png" width="200" alt="浅色组件展示页" /> <img src="doc/preview/showcase_dark.png" width="200" alt="深色组件展示页" />

> 预览图由 `test/preview_capture_test.dart` 生成，样式变更后重新执行
> `flutter test --update-goldens test/preview_capture_test.dart` 刷新。

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
    │   │   └── pill_tab_bar/
    │   ├── buttons/
    │   │   └── button/
    │   └── inputs/
    │       └── search_bar/
    ├── icons/               # nav_icons.dart：导航栏 logo 合集（含加号 logo）
    └── utils/               # 工具函数层（纯函数）

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
- [ ] `MiDialog` — 弹窗
- [ ] `MiForm` — 表单
- [ ] `MiTheme` — 主题聚合
