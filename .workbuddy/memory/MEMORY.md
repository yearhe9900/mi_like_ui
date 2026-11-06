# mi_like_ui_demo 项目笔记

> 过程细节见 `.workbuddy/memory/YYYY-MM-DD.md`；本文件只留**长期有效的约定、坑、判据**。逐组件数值以各 `*_metrics.dart` 的 dartdoc 为准。

## 分层与约定
- 单向依赖：`theme`/`icons` → `foundations` → `layout` → `components` → `overlays` → barrel。`test/architecture_test.dart` 扫源码守门（6 条依赖方向 + barrel 死链/覆盖，排除 `*_painter.dart`）。
- 对外只经 barrel `lib/mi_like_ui.dart`；组件 `src/components/<类别>/<组件名>/`，类 `Mi` 前缀、文件名 snake_case。
- 上层要用下层数值 → **同源转发** `static const double x = MiSource.y;`，不抄数字；组件层不许反向依赖浮层（行几何已上提到 `theme/row_tokens.dart` 的 `MiRowMetrics`）。
- 透明参数只有 `theme/transparency_tokens.dart` 一个来源，alpha 保留原生表达（0.63 别写 161/255）。`transparency_config_test` / `motion_config_test` 扫整个 `lib/src`（含 `overlays`）。
- 主题解析统一 `MiTheme.modeOf(context, explicit:)`：组件显式参数 > `MiTheme` > `Theme.brightness`。
- **实测优先**：视觉参数 1:1 从素材量；无素材标「推导（非实测）」或「参考实现值」+ 写依据。性能/几何数字必须实测，别按推算写进注释/README/阈值。
- 每任务完成即 commit（精确路径 add，绝不 `git add .`）**并立即 push**；工作区不留未提交改动。analyze/test 由 agent 跑，build/adb 只给命令。
- CHANGELOG 只写发布级变更（1~2 行：改了什么 + 为什么）；README/CHANGELOG/dartdoc 用「设计度量/推导值/参考素材」+ 专业 API 口吻，不写过程叙事。
- demo 按页拆成 `part`：`lib/demo/pages/*.dart` + `part of '../mock_pages.dart'`（相对**主文件**解析）；跨页共享小件留主文件。

## 响应式（`src/layout/responsive.dart`）
- **三处断点各管一件事**：① 窗口宽 `MiViewport/ofWidth`（compact<600 / medium<1024 / expanded）；② **画面容器宽** `usesSideNav(w)=w>600` → 底栏 vs 侧栏；③ **内容容器宽** `MiResponsiveGrid` → 列数。混用会错。
- `MiScaledCanvas.scaleFor` 只缩不放；`scale==1` 走原样路径（零变换层）。`DemoStage.sizeFor`：**只有 compact 是物理手机**（等比 393×856）。
- 宽屏配方（推导）：内容列 ≤1120 + `MiContentColumn`（纵向撑满、只限内容不限底色）、页边距 32；列数 = max(断点台阶, `ceil((w+gap)/(maxCell+gap))`)——**加列不加速度**。内容列那层**三档恒挂**，增删会导致页面重建、滚动位置归零。

## 悬停 / 侧栏 / 顶栏 / 路由
- `MiHoverFeedback` 叠色（白/黑 @5.6%，150ms）**必须是实色 `AnimatedContainer`**，禁 `Opacity`；未悬停 `Colors.transparent` 保结构恒定。宽屏滚动条 `Scrollbar(thumbVisibility: !isCompact)`，页面需自带 `ScrollController`。
- 侧栏 `MiGlassSideNavBar`：读**外壳自己** `maxWidth>600`；`MiBreakpoints.desktop`(1024) 只给桌面样式。窄栏 95.4 = 82.2+2×6.6、条目 49.3、间距 8、留白 25.5；`railHeightFor(n)=2×6.6+n×49.3+(n−1)×8`；胶囊中心 = `railInnerPad + itemHeight/2 + pitch×pos`（**不是** `pitch×(pos+0.5)`）；`railRadius = pillRadius + railInnerPad`。展开栏宽 176，用 `navLabel` 10.5dp 字号，横排 Row **必须钉定宽**。底栏底让安全区用 `max(24.2, padding.bottom)`（24.2 已含手势条，不叠加）。
- 顶栏 `MiTopBar`：材质两套 —— 纯标题 = 渐进 σ 曲线（`visibleBlurBands`）；头部区 = 恒定 σ5.37 铺满 `occupiedHeight` 后硬切（`uniformBlurBands`）。`showBlur` / `showSurface` 两个独立开关。头部区由顶栏自产（`searchHint`→内部 `MiSearchBar`，`tabs`→内部 `MiPillTabBar`），换皮才用插槽。标题墨心靠 `Baseline(baseline: 墨心+0.355em)` 钉死。搜索态切换时**材质盒高钉住不插值**、**淡出必须走颜色 alpha**（`MiPillTabBar.fade` / `MiSearchCancelButton.fade`），否则 backdrop 输入被清空 + 每帧离屏。
- `MiCardPageRoute`：一个路由两种角色 —— `secondary != dismissed` 只画下层左移视差（`0.25×屏宽`，用 `FractionalTranslation`，禁 `LayoutBuilder+Transform`）；否则画全屏黑 scrim（终值 0.55）+ 滑入 + 前缘圆角 R=61.2 恒定。手机 300ms / 桌面 220ms。淡入禁用 `Opacity`（用同色幕布 `ColoredBox`）。压暗只能上层画、视差只能下层画 → 示例根路由也用它。

## 浮层与补件（`src/overlays/`、`inputs/checkbox`、`inputs/switch_control`）
- `MiBottomSheet` 必须经 `MiPopup` 渲染；滑入用 `FractionalTranslation(0, 1-p)`；遮罩 = `dialogScrimProgressFor` 随进度（不是 Opacity）；只圆上两角 `MiSquircleBorder(topOnly: true)`。
- `MiMenu`：**行高只由文案块决定**，行尾装饰（勾号 20 / 箭头 16）只占宽度 —— 槽钉 `height: 0` + `OverflowBox` 居中溢出绘制，溢出 2.05dp 落在 12dp 行内边距里。让 20dp 墨盒参与行高，正文 `dialogAction` 15.9dp/`height:1.0` 会把选中行顶高 4.1dp（相邻中心距各 +2dp）。首/末行 20dp 边距是参考实现刻意更松，**不是缺陷**。
- `MiFloatingToolbar` 投影必须走 `MiSquircleShadowPainter`（`BoxShadow` 是矩形、圆角漏影）。
- `MiCheckbox` 勾号 = 三点折线 `PathMetric` trim；`MiSwitch` 支持水平拖拽（`travel` 归一 + 0.5 阈值）、按压钮体放大 1.127、RTL 镜像。
- 三者（+下拉刷新等源自 flutter_miuix 的补件）几何/动效标「参考实现值、本库无素材」。

## 动效：进入 / 退出必须分方向（2026-11-05）
- **进入曲线禁止直接 `reverse()` 播退出**：`easeOutQuint` / `easeOutCubic` 反向播把「快起慢停」翻成「慢起快停」（旧值：原地态退出半程只回退 5%、整页路由前 120ms 只回退 7%）→「点返回没反应、然后突然弹回」。退出按「退出已过时间」插值 `1 - easeOut(1 - progress)`，位置 / 淡出 / 视差 / 压暗共用同一进度。
- 退出时长单独给：`AnimationController.reverseDuration` / `PageRoute.reverseTransitionDuration`（默认等于进入时长，必须覆写）。现档：原地 180/150ms、整页 220/180ms（手感推导值；曲线形状仍是素材拟合）。
- 线性淡出类（标题 / 胶囊行 / 透明度）收进 `Interval(0, 0.7)`，别按整段时间磨到末帧；取消钮淡入区间作用在「搜索态可见度」而非原始时间。
- 宽屏转场视觉进度铺满整段（`wideVisualFraction = 1`）：压进前 73% 会留 80ms 空转，pop 时前 80ms 画面完全不动。
- 键盘：进页首帧 `requestFocus` 与转场**并行**（推迟到落定反而更慢）；返回前先 `unfocus()` 再 pop，否则键盘收起串在转场之后。
- **转场中途截图（preview golden）按动画进度换算 pump 毫秒**（`durationMs * 0.30`），别写死绝对毫秒；累计时长保持不变以固定光标闪烁相位 → 压缩时长后 golden 仍逐像素一致，不必 `--update-goldens`。
- 已知边界：退出进度由 `animation.value` 直接解出，push 动画中途被打断会不连续（要归一化须另记打断起点）；本库搜索页在落定前不接受返回。

## 性能：每帧模糊预算
- 口径 = 一次 build 的**层数 + 面积 dp²**，钉在 `test/perf_budget_test.dart`（阈值 78k / 122k / 175k）。深色实测：手机 2 层/75.7k、平板 2/117.8k、桌面 2/~170k。
- 优化：深色顶栏跳过不透明段、胶囊行多 filter 合一（`_CapsuleStripClipper`）、`ImageFilter` 按 σ 缓存 + 跳过 σ<0.5。滚动降 σ（`sigmaScale` 0.6，停 120ms 恢复）。
- **任何含磨砂的子树都不要套 `Opacity`/`FadeTransition`/`ShaderMask`**：引 saveLayer → backdrop 变空 + 双份全宽高斯。切 tab / 底栏显隐 / 转场压暗 / 悬停一律换结构或实色填充。
- 「感觉丢帧」先排除 debug：`flutter run --profile` + `dumpsys gfxinfo`。

## 已知坑
### 测量与判据
- **平坦色块判不了有没有模糊**（模糊不改平坦区亮度）→ 用高频边缘宽度；`matchesGoldenFile(finder)` 只截该子树，模糊源必须在内。
- σ 与 α 在窄窗口耦合退化 → 用频谱比 `log(Ŝ₁/Ŝ₀)=−2π²σ²f²+2log(1−α)`、带外平坦区反解 α、剖面 10-90 宽 = 2.08σ。
- 纵向滚动录屏里竖直边缘（水平剖面）不受运动模糊影响 → 优先取图标/头像左右缘。判据别被描边骗：沿列找单行硬跳变；「是不是阴影」看压暗沿 x 是否平坦（平坦 = scrim）。
### 布局
- **`MiPopupRegistry` 变更通知必须在帧末**：构建期同步 `notifyListeners()` → 宿主 `setState() called during build`。测试里浮层几何要 **pump 两帧**才生效。
- 无 child 的 `DecoratedBox`/`Container` 松约束下取 `constraints.smallest`（宽 0 不报错）→ 加 `SizedBox.expand()`。
- 网格断点按**容器宽**标定；`MiPillTabBar` 在宽父级里会居中 → 包 `Align(centerStart)`。
- 全屏页壳 Stack 子级一律 `Positioned`；叠层包 `IgnorePointer` 且包在 `GestureDetector` **外层**；`ListView` 里塞 `Column` 必须 `mainAxisSize.min`。
- **`clipBehavior` 不要在状态间切**、**包装层不要在断点间换**（换 Element → 滚动位置归零）。
- 给已截图界面加外壳层要**零新增 render object**（黄金图噪声差）→ 改 `Positioned` 几何 + 容器颜色。
### 字体
- 墨心在基线上方 `k≈0.355em` 跨字体稳；行盒内基线位置只能由字体度量定 → 用 `Baseline`,语义 `size.height = (N − 子级基线距) + 子级高`。
- 测试字体 CJK advance ≠ 1em（「关注」13dp = 26.5）→ 锁「收缩到内容」写 `width == text.width + 2*padding`。行盒高被引擎向上取整（31.83 → 32.0）。
### 测试
- **`Invalid WebSocket upgrade request` ≠ 代码问题**：`HTTP_PROXY` 劫持 → 一律 `NO_PROXY=localhost,127.0.0.1 flutter test`。
- 改了几何 token 而预览图不变 = 有代码自算几何绕过 token → grep 自算点 + `ImageChops.difference().getbbox()`。
- 断言速记：构造断言 `throwsA(isA<AssertionError>())`；`getDistanceToBaseline` 不能在测试体调 → 断 `Baseline.baseline`；`MaterialApp.theme` 是 200ms `AnimatedTheme` → `pump(300ms)`；位移用 `position.jumpTo`。
- 路由：`push` 后 pump 两帧；`getTopLeft/getRect` **会应用祖先变换**；上层不透明时下层 offstage → `skipOffstage: false`。
- 鼠标悬停：`createGesture(kind: mouse)` + `addPointer` + `moveTo`，pump 两帧；`find.byType(MouseRegion)` 会命中 MaterialApp → 按 `cursor == click` 过滤。键盘：`sendKeyDown/UpEvent(modifier)` 包 `sendKeyEvent(key)`。
- 截含光标的页面**不能 pumpAndSettle** → 固定 pump 到确定时长；手机档 `Focus(autofocus)` 要关（推偏光标相位 → 黄金图噪声）。
- 换皮/改样式后先跑失败 → 读 `test/failures/*_testImage.png` 与 master 做 numpy 差值、确认 bbox 只在预期矩形内，才 `--update-goldens`。

## 工具
- **issue / PR 走 GitHub CLI `gh`**：仓库 `yearhe9900/mi_like_ui`，**默认分支 `main`**（不是 master，`git push origin master` 会报 refspec 不存在）。取正文必须带 `--json`（`gh issue view <n> -R owner/repo --json title,body,state,labels,comments`），纯 `--comments` 会输出空。
- 像素脚本 `.workbuddy/measure_*.py / extract_*.py / fit_*.py`（非交付物，已 gitignore）；venv `C:\Users\zmt\.workbuddy\binaries\python\envs\default\Scripts\python.exe`。
- 快速出图：临时测试 `.workbuddy/scratch_*_test.dart` + `--update-goldens`（跑完删除）。
