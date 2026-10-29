---
name: mi-like-ui
description: 在 mi_like_ui（小米 / HyperOS 风格 Flutter 组件库）项目中开发或调用组件时使用 —— 组件 API 速览、度量驱动纪律、常见坑清单。真源是 README 与各 *_metrics.dart / theme tokens，本文件只是索引与避坑卡。
---

# mi_like_ui 使用与开发指南

**真源永远是仓库本身**：组件参数与规格看各 `*_metrics.dart` 与
`theme/*_tokens.dart` 的文档注释，总览看根目录 `README.md`。本文件只做
三件事：① API 面速览 ② 纪律 ③ 坑清单。**禁止编造 API** —— 用任何组件前
先在 barrel（`lib/mi_like_ui.dart`）里确认它存在。

## 硬纪律（违反会被守门测试抓住或被 review 打回）

1. **度量驱动**：任何新数值必须是「度量」（注明素材与拟合方法 / 残差）
   或「推导」（注明换算链）。外部库（如 flutter_miuix）的数值只作交叉
   参考，写进注释，不当真源。
2. **token 单一来源**：透明 / 磨砂参数只在 `theme/transparency_tokens.dart`；
   跨组件动效只在 `theme/motion_tokens.dart`；组件私有动效进
   `*_metrics.dart`。组件层不许裸写 `Duration(ms: 数字)` / `SpringDescription`
   / `Cubic`（`motion_config_test` 源码扫描）。
3. **磨砂子树禁 `Opacity` / saveLayer**：会让下层 `BackdropFilter` 的
   backdrop 变空（磨砂整段消失）。叠色用实色层；淡入用「alpha 乘进颜色」。
4. **结构恒定**：悬停 / 焦点 / 按压层未激活时全透明常驻，不许条件增删
   （黄金图零变化的前提）。
5. **新组件流程**：`src/components/<类别>/<名>/` 建 widget/metrics →
   取 token → barrel 补 export → 测试 + golden → demo 一例 → README 同步。
6. 使用方与测试**只 import barrel**（`package:mi_like_ui/mi_like_ui.dart`）。

## 组件 API 速览（公开面以 barrel 为准）

| 组件 | 关键参数 |
|---|---|
| `MiGlassNavBar` / `MiGlassSideNavBar` | `items(MiGlassNavItem: label + IconPainter)`、`selectedIndex`、`onTap(i)`、`themeMode` |
| `MiPillTabBar` | `labels`、`selectedIndex`、`onTap(i)`；`fade`（转场 alpha 乘色） |
| `MiButton` | `label`、`onPressed`（null = 禁用）、`variant(filled/tonal)` |
| `MiSearchBar` | `editable`（false 时 `onTap`）；输入态走 `controller/focusNode/onChanged` |
| `MiSearchCancelButton` | `onTap`、`fade`（转场用，勿用父级 Opacity 代替） |
| `MiTopBar` | `title`、`scrollOffset`、`showBack/onBack`、`searchHint`/`tabs`（数据参数）、`searchActive`、`palette` |
| `MiGradientBlur` | `height`、`sigmaScale`（滚动降 σ） |
| `MiThemeCard` | `title/onTap`、`quickActions`（悬停操作条，桌面） |
| `MiDialog` | `position(top/center/bottom)`、`layout(buttons/list)`、`title/message`、`actions(MiDialogAction)`、`items(MiDialogItem)`、`onScrimTap` |
| `MiPullUpPanel` | `anchorPoint`（触发钮圆心）、`height`、`controller`、`onDismissed` |
| `MiCardPageRoute` | `Navigator.push(MiCardPageRoute(builder: …))` |
| `MiSnackbar` | `show(context, message:, actionLabel:, onAction:)`（需最近祖先有 `MiPopupHost`）；或直接当组件用（`Positioned.fill` + `onDismissed`） |
| `MiSwitch` | `value`、`onChanged(bool)`（null = 禁用） |
| `MiSlider` | `value/onChanged`（受控）、`min/max`、`divisions`、`focusNode` |
| `MiPreferenceTile` | `title/subtitle`、`leading/trailing`（尾随放 `MiSwitch` / 箭头）、`onTap`、`showDivider` |
| `MiPressable` | 可点元素统一反馈入口：`onPressed`、`pressBuilder(ctx, pressed, child)`（按压视觉留组件层）、`hover/focus`、`borderRadius` |
| `MiHoverFeedback` / `MiFocusRing` | 底层单件（一般经 `MiPressable` 使用） |
| `MiPopupHost` / `MiPopup` | 弹层单点渲染：`MiPopupHost(child: …)` 包页面；`MiPopup(show:, builder:)` 注册（无宿主时就地渲染，兼容） |
| 响应式 | `MiBreakpoints.usesSideNav/usesExpandedRail`、`MiScaledCanvas`、`MiResponsiveGrid`、`MiContentColumn` |

## 常见任务配方

- **设置页**：`MiPreferenceTile(title, trailing: MiSwitch(...), showDivider: …)`
  纵向排一列；行高与弹框列表行同源，勿另发明。
- **轻提示**：应用根部（路由内容外）挂 `MiPopupHost`，任意页内
  `MiSnackbar.show(context, message: …)`（新消息顶旧条）。
- **确认 / 操作单**：`MiDialog`（buttons 或 list 形态）；宿主决定收起。
- **搜索**：原地搜索态用 `MiTopBar(searchActive: …)`；整页搜索用
  `MiCardPageRoute` 推入。

## 坑清单（本库实测踩过的）

- 磨砂子树里 `Opacity`/`FadeTransition`/saveLayer → 磨砂消失（见硬纪律 3）。
- 页面 Stack **中插**浮层 → 其后子树重建、滚动位置归零（用 `MiPopupHost`）。
- 内容列 / 包装层**不许按断点增删** → 同样重建问题。
- `Focus.hasFocus` 含**后代聚合**：包装层套着输入框时环会被点亮
  （`MiSearchBar` 因此不做 Tab 停靠）。
- 转场中的磨砂：σ 缩放量化 0.05 档（`MiFilterCache` 以 σ 为键）。
- 拖拽取值用 `globalToLocal` 坐标换算，勿用 `details.delta` 累加。
- 测试找按压 / 悬停态用 `MiHoverFeedback.overlayKey`、`MiFocusRing.ringKey`、
  `MiSwitch.knobKey`；弹框按钮压色用 `AnimatedContainer.decoration.color` finder。
