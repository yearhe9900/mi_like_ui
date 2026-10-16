# Changelog

本项目所有重要变更均记录于此。

格式参考 [Keep a Changelog](https://keepachangelog.com/)，版本号遵循 [Semantic Versioning](https://semver.org/)。

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
- [ ] `MiButton` — 按钮
- [ ] `MiDialog` — 弹窗
- [ ] `MiForm` — 表单
- [ ] `MiTheme` — 主题聚合
