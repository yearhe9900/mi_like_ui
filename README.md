# mi_like_ui

小米风格可扩展 UI 组件框架（Flutter）。

以像素级实测还原小米系视觉与动效，沉淀为分层清晰、可持续扩充的组件库。
当前已落地首个组件 `MiGlassNavBar`（玻璃悬浮底部导航栏）；
按钮、弹窗、表单等组件按同一组织方式逐步扩充。

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
    ├── theme/               # 样式/主题层（颜色·文字·间距·材质 token）
    ├── components/          # 组件层（类别/组件名/ 两级目录）
    │   └── navigation/glass_nav_bar/
    ├── icons/               # 图标 painter 集
    └── utils/               # 工具函数层（纯函数）

test/                        # 黄金图 + 交互测试
```

| 层 | 职责 |
|---|---|
| 导出层 `lib/mi_like_ui.dart` | 唯一对外 API 面 |
| 组件层 `src/components/` | 可复用组件：widget + metrics + painter |
| 主题层 `src/theme/` | 跨组件样式 token |
| 图标 `src/icons/` | `*IconPainter` 图标集 |
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
- [ ] `MiButton` — 按钮
- [ ] `MiDialog` — 弹窗
- [ ] `MiForm` — 表单
- [ ] `MiTheme` — 主题聚合
