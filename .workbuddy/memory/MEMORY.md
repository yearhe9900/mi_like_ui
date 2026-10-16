# mi_like_ui_demo 项目笔记

## 架构与约定
- 对外只经 barrel `lib/mi_like_ui.dart`（新增组件/主题 token 记得补 export）；组件放 `src/components/<类别>/<组件名>/`，类 `Mi` 前缀、文件 snake_case；颜色/文字/间距一律走 `src/theme/` token，组件内不写字面量。
- **实测优先**：视觉参数 1:1 从参考截图像素测量；参考图没有的样式（如按钮禁用态）只能推导，并必须在 doc comment 标注「推导（非实测）」+ 写明取值来源。
- 变更节奏：每个任务完成即 git commit；`flutter analyze` / `flutter test` 由用户手动执行（agent 不代跑）。

## 实测速查（dp @ 393 设计宽）
- 页底：亮 `#F3F3F3` / 暗 `#000000`；搜索栏灰：亮 `#E7E7E7` / 暗 `#242424`。
- 胶囊标签行 MiPillTabBar：pill 87.6×39.9、gap/edge 11.9、标签 13.85dp w500。
- MiButton：`#4980F7`（明暗同色）、高 28.3、左右 17、标签 13dp w500、stadium；列表行距 56.1。

## 已知坑
- `Container`/`Align` 带 `alignment` 在**有界**父级（Center/Column）会拉满宽；需要「内容自适应」的控件用 `Center(widthFactor: 1.0)` 收缩。
- `const` 构造断言不能求值 `.length`（数量校验放 initState，见玻璃导航栏）。
- 样式改动后必须重跑 `flutter test --update-goldens test/preview_capture_test.dart`，否则 `doc/preview/*.png` 预览测试挂。

## 工具
- 像素测量脚本：`.workbuddy/measure_*.py`（PIL，分析用非交付物，不入库）。
- 本机 venv Python：`C:\Users\zmt\.workbuddy\binaries\python\envs\default\Scripts\python.exe`（注意在 `Scripts\` 下，PIL 可用）。
