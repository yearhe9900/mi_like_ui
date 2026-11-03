# 使用与配置

- 结构与依赖规则：见 [ARCHITECTURE.md](ARCHITECTURE.md)
- 每个模块的关键接口：见 [MODULES.md](MODULES.md)

## 1. 引入

本库 `publish_to: none`，按路径（或 git）依赖引入：

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  mi_like_ui:
    path: ../mi_like_ui        # 或 git: {url: …, ref: main}
```

```dart
// 只从这个 barrel 导入；不要直接 import src/ 内部文件
import 'package:mi_like_ui/mi_like_ui.dart';
```

要求 Dart SDK `>= 3.4.0`，无第三方运行时依赖。

## 2. 最小可运行骨架

两层包装解决「主题」与「浮层」两件事，其余组件随意组合：

```dart
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MiTheme(
        data: const MiThemeData(mode: MiThemeMode.dark),
        child: MaterialApp(
          // 浮层单点渲染层：弹框 / 抽屉 / 轻提示都注册到这里，按序叠在顶层
          home: MiPopupHost(child: Scaffold(body: MyPage())),
        ),
      );
}
```

```dart
Column(
  children: [
    MiButton(label: '关注', onPressed: () {}),
    MiSwitch(value: on, onChanged: (v) => setState(() => on = v)),
    MiSettingsCard(children: [
      MiSettingsRow(label: 'WLAN', value: '已连接', onTap: () {}),
    ]),
  ],
)
```

**没有 `MiPopupHost` 会怎样？** `MiPopup` 会就地渲染（仍在正确位置），但
`MiSnackbar.show` 要求宿主存在并会断言失败；页面里的弹框也不会浮在整页顶层。

## 3. 主题配置

```dart
MiTheme(
  data: const MiThemeData(
    mode: MiThemeMode.light,              // null = 跟随 Theme.of(context).brightness
    accent: Color(0xFF3482FF),            // 品牌色：按钮填充 / 光标 / 焦点环 / 转场幕布同源换
    pageBackgroundLight: Color(0xFFF3F3F3),
    pageBackgroundDark: Color(0xFF000000),
  ),
  child: child,
)
```

优先级：**组件显式 `themeMode:` > `MiTheme` 声明 > 环境 `Theme.brightness`**。
解析统一走 `MiTheme.modeOf(context, explicit: themeMode)`。

- 只改明暗：不包 `MiTheme` 也行，切 `MaterialApp.theme.brightness` 即可。
- 只改某一块：给该组件传 `themeMode`（局部覆盖，不影响其它组件）。
- 换肤粒度止于「模式 + 品牌色 + 页底色」。更细的维度（如阅读器日间 /
  羊皮纸）请在应用层自己做，不要往 token 里灌主题概念。

## 4. 浮层

| 需求 | 做法 |
|---|---|
| 声明式弹框（与页面同帧渲染、可被截图） | `Stack` 里 `if (visible) MiDialog(…)`，或页面内 `MiPopup(show: …, builder: …)` |
| 命令式弹框（`await` 结果） | `final index = await showMiDialog(context, dialog: MiDialog(…));` |
| 贴底抽屉 | `MiBottomSheet(show: sheetOpen, title: '选择操作', onDismissRequest: () => setState(...), child: …)` |
| 从按钮弹起的面板 | `MiPullUpPanel(controller: c, child: …)` + `c.show(...)` |
| 底部轻提示 | `MiSnackbar.show(context, message: '已保存')`（需要 `MiPopupHost`） |

注意：`MiPopupHost` 应放在**你希望浮层出现的那一层**（整窗最外层，或机身壳
内部 —— 演示应用选了后者，PC 套壳时弹框不会盖住整个窗口）。

## 5. 响应式

三处断点各管一件事，**别混用**：

| 断点 | 判据 | 决定 |
|---|---|---|
| 窗口宽 | `MiViewport.of(context)` / `MiBreakpoints.ofWidth(w)` | 当前档位（compact < 600 / medium 600–1023 / expanded ≥ 1024） |
| 画面容器宽 | `MiBreakpoints.usesSideNav(w) = w > 600` | 底部导航栏 vs 侧边栏 |
| 内容容器宽 | `MiResponsiveGrid` / `MiBreakpoints.contentMaxWidth` | 网格列数、内容列宽（≤ 1120） |

```dart
MiContentColumn(                       // 宽屏内容限宽居中（纵向撑满，只限内容不限底色）
  child: MiResponsiveGrid(
    maxCellWidth: 240,                 // 单元宽上限：加列不加速度
    children: cards,
  ),
)
```

`MiScaledCanvas(designSize: Size(393, 856))` 用于**等比缩放**（演示应用的手机
壳内画面）：只缩不放，`scale == 1` 时走零变换路径。

## 6. 桌面语义

- **悬停**：`MiHoverFeedback` 自动接入所有 `MiPressable` 包裹的组件（叠色
  白/黑 @5.6% + 手型光标）。
- **键盘**：`MiPressable` 的 `focus: true`（默认）即可 Tab 聚焦 + Enter/Space
  激活；焦点环由 `MiFocusRing` 画（2dp）。
- **⌘K / Ctrl+K 搜索**：库层不接管全局快捷键，示例层用
  `CallbackShortcuts`（`demo/pages/profile_page.dart`）演示绑定方式。

## 7. 自定义与扩展

**改一个已经存在的度量**：先看它是否在 `*_metrics.dart` → 改数值 → 跑
`flutter test`（黄金图会告诉你哪些地方动了）→ 若确属预期，更新基线。

**新增一个组件**（完整流程见 [ARCHITECTURE.md §7](ARCHITECTURE.md)）：
建目录 → 写 widget + metrics（+ painter）→ barrel 补 export → 补测试 → demo
加陈列。三个守门测试会自动检查：分层依赖、令牌字面量、barrel 覆盖。

**新增一个 token**：先判断属于哪一层 —— 全局（`colors` / `dimens` /
`typography` / `motion_tokens` / `transparency_tokens` / `row_tokens`）、组件
配色（`theme/<组件>_tokens.dart`）、组件几何（`*_metrics.dart`）。

## 8. 演示应用

```bash
flutter run                     # 桌面 / 移动
flutter run -d chrome           # Web（按 user-agent 判定设备语境）
flutter build web               # 发布产物
```

演示外壳按**设备语境**自适应：PC 窄窗套手机壳、宽窗套平板壳（机身 + 外圈底色
+ 投影），移动端铺满全屏并启用 edge-to-edge（`main.dart` 里
`SystemUiMode.edgeToEdge` + `AnnotatedRegion<SystemUiOverlayStyle>`）。

## 9. 测试

```bash
flutter analyze                                    # 静态分析
flutter test                                       # 全量（约 15 秒）
flutter test test/top_bar_test.dart                # 单文件
flutter test --update-goldens test/preview_capture_test.dart   # 刷新 README 配图
```

`preview_capture_test` 依赖系统中文字体（Windows 下生成），CI 以
`--exclude-tags preview` 排除。守门测试清单见
[ARCHITECTURE.md §8](ARCHITECTURE.md)。

## 10. 常见坑

| 现象 | 原因 / 解法 |
|---|---|
| 磨砂突然「变透明」或全黑 | 子树被套了 `Opacity` / `FadeTransition` / `ShaderMask`：`saveLayer` 会清空 `BackdropFilter` 的 backdrop。淡出请走颜色 alpha |
| 跨断点切换后滚动位置归零 | 组件在状态间增删了层级或改了 `clipBehavior`；结构保持恒定（如 `clipBehavior` 固定 `antiAlias` + `BorderRadius.zero`） |
| 首帧就挂浮层时崩 `setState() called during build` | 已在 `MiPopupRegistry` 内部处理（通知合并到帧末）；自研浮层要注意同一问题 |
| `MiPillTabBar` 在宽父级里居中而不是靠左 | 它按内容宽自适应，需要外层 `Align(alignment: Alignment.centerLeft)` |
| 无 child 的 `DecoratedBox` / `Container` 在松约束下宽 0 | 加 `SizedBox.expand()`（`constraints.smallest` 兜底） |
| 全屏页的 `Stack` 子级偏移 / 居中 | 子级一律 `Positioned`，自适应用 `Center(widthFactor: 1.0)` |
| 测试里 `Invalid WebSocket upgrade request` | `HTTP_PROXY` 劫持本地回环，用 `NO_PROXY=localhost,127.0.0.1 flutter test` |
| 小窗里进度条 / 卡片尺度不对 | 检查是否混用了「窗口宽」与「内容容器宽」两种断点判据 |
