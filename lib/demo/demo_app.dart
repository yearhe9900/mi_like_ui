import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_like_ui/mi_like_ui.dart';

import 'mock_pages.dart';

/// 演示应用（示例层，不属于框架公共 API）。
///
/// 深/浅色模式切换入口放在「我的」页顶部；模式驱动手机框、mock 页、
/// 导航栏玻璃配方与墨色整体切换。
class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  MiThemeMode _mode = MiThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    final light = _mode == MiThemeMode.light;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glass Jelly Bottom Nav Demo',
      theme: light ? ThemeData.light(useMaterial3: true) : ThemeData.dark(useMaterial3: true),
      home: DemoHome(
        themeMode: _mode,
        onThemeModeChanged: (m) => setState(() => _mode = m),
      ),
    );
  }
}

/// 舞台尺寸解算结果：逻辑尺寸（内容按它布局）+ 渲染尺寸（实际占位）。
///
/// 两者只在 `rendered` 被等比缩小时不同；`scale == 1` 表示 1:1 原尺寸。
@immutable
class DemoStageSize {
  const DemoStageSize({required this.logical, required this.rendered});

  /// 画面布局用的逻辑尺寸（≤ 1x 时恒为设计画布）。
  final Size logical;

  /// 画面在窗口里实际占据的尺寸（= `logical × scale`）。
  final Size rendered;

  /// 统一缩放比（宽高共用）。
  double get scale => logical.width > 0 ? rendered.width / logical.width : 0;

  /// 是否需要缩放（false = 1:1，渲染路径不加变换层）。
  bool get isScaled => (rendered.width - logical.width).abs() > 0.01;

  @override
  String toString() =>
      'DemoStageSize(logical: $logical, rendered: $rendered, scale: ${scale.toStringAsFixed(3)})';
}

/// 示例舞台：把「画面」摆进任意窗口的自适应外壳。
///
/// ## 覆盖的布局区域
///
/// 只负责**外壳**这一层（画面的外部几何与缩放），不介入画面内部的组件
/// 几何 —— 内部由各页面的局部断点负责（见 [MockPage]）。
///
/// ## 断点与缩放策略（按**窗口**逻辑宽判档，见 [MiBreakpoints]）
///
/// | 档位 | 窗口宽 | 策略 |
/// |------|--------|------|
/// | compact | < 600dp | **物理手机画布** 393×856，等比缩到放得下（手机全屏时恰好 1:1、零留白） |
/// | medium | 600…1023dp | **铺满窗口**（edge-to-edge）：画面 = 可用尺寸，不再有外边距 / 圆角卡片 —— 平板就是一个真实平板 App 的样子 |
/// | expanded | ≥ 1024dp | 同上，铺满窗口 |
///
/// **为什么大屏不再做「背景 + 圆角卡片」**：那是模拟手机外壳的产物。真机上
/// 平板/桌面本来就是整个窗口的 App，卡片外那圈底色 + 圆角既不是 UI 的一部分，
/// 还会让内容（以及状态栏后面那一条）与页面底色对不上 —— 2026-10-18 平板
/// 实拍反馈「应该铺满屏幕，不需要外围卡片效果」。
///
/// 各档都过同一道兜底：[DemoStageSize.rendered] 由
/// `min(1, 可用宽/逻辑宽, 可用高/逻辑高)` 得出 ——
///  * **不溢出**：窗口再小（哪怕 200×200）也只会继续缩小；
///  * **不变形**：宽高乘同一个比例，画面内部不会被宽高各自拉伸；
///  * **实时响应**：`LayoutBuilder` 随窗口/分屏/浏览器缩放自动重排，
///    无需 `setState` 或监听。
///
/// 缩放只发生在 compact 档（窗口比设计画布还小）；大屏 `scale == 1`，
/// **不加任何变换层**，黄金图逐像素稳定。
class DemoStage extends StatelessWidget {
  const DemoStage({super.key, required this.child});

  /// 参考机设计画布：1220×2656 录屏 @ 393dp 设计宽（393:856 ≈ 0.459）。
  static const Size designCanvas = Size(393, 856);

  /// 画面内容：拿到 [DemoStageSize.logical] 的 **tight** 约束。
  final Widget child;

  /// 纯函数解算（可直接单测，不需要 widget 树）。
  static DemoStageSize sizeFor(Size available) {
    final available0 = Size(
      math.max(0.0, available.width),
      math.max(0.0, available.height),
    );
    if (available0.width == 0 || available0.height == 0) {
      return const DemoStageSize(logical: Size.zero, rendered: Size.zero);
    }

    final sizeClass = MiBreakpoints.ofWidth(available0.width);
    // compact：物理手机画布（只缩不放）；medium / expanded：画面 = 窗口。
    final logical = sizeClass.isCompact ? designCanvas : available0;

    final scale = math.min(
      1.0,
      math.min(available0.width / logical.width, available0.height / logical.height),
    );
    return DemoStageSize(
      logical: logical,
      rendered: Size(logical.width * scale, logical.height * scale),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stage = sizeFor(Size(constraints.maxWidth, constraints.maxHeight));
        final frame = SizedBox.fromSize(size: stage.logical, child: child);
        final scaled = stage.isScaled
            ? FittedBox(fit: BoxFit.fill, child: frame)
            : frame;
        return Center(
          child: SizedBox.fromSize(size: stage.rendered, child: scaled),
        );
      },
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key, required this.themeMode, required this.onThemeModeChanged});

  final MiThemeMode themeMode;
  final ValueChanged<MiThemeMode> onThemeModeChanged;

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final light = widget.themeMode == MiThemeMode.light;
    // 图标墨色随模式（与导航栏标签一致）
    final ink = MiColors.foregroundFor(widget.themeMode);
    // 导航条目**只有一份**：底部栏与侧栏吃同一份 items，图标 / 标签 /
    // 选中下标 / onTap 全部同源 —— 换布局不会让任何一项产生差异。
    final items = [
      MiGlassNavItem(label: '首页', painter: RollerIconPainter(ink)),
      MiGlassNavItem(label: '分类', painter: GridSparkleIconPainter(ink)),
      MiGlassNavItem(label: '我的', painter: SmileyBeretIconPainter(ink)),
    ];
    // 只有 **compact（手机档）** 是"物理手机"：给圆角 + 投影，模拟设备外观。
    // 平板 / 桌面铺满窗口，不加任何外围卡片效果（见 [DemoStage] 类注释）。
    final viewport = MiViewport.of(context);
    final framed = viewport.isCompact;
    // 页底色（侧栏那一列与页面同底，避免宽屏上出现一道拼接缝）。
    final pageBg = light ? const Color(0xFFF3F3F3) : const Color(0xFF000000);
    // 预留空位圆钮：两种导航形态**共用同一份声明**（仅「首页」选中时展示、
    // 点按弹提示）—— 手机 / 窄窗挂在底部栏右侧（栏体左移让位），平板 /
    // 桌面挂在侧栏栏尾下方（栏体不动、槽位恒定预留）。显隐契约、弹出曲线
    // 与直径/间距 token 两种形态逐帧同源。
    final fab = MiGlassNavFab(
      tabIndex: 0,
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('圆形按钮被点击'),
          duration: Duration(milliseconds: 800),
        ),
      ),
      child: CustomPaint(
        painter: GridDotsIconPainter(Colors.white),
        size: const Size.square(18.2),
      ),
    );
    // edge-to-edge 下内容会铺到状态栏 / 手势条下面，浮层类元素要让开安全区。
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 状态栏透明 + 图标随明暗翻转：状态栏背后就是页面自己的底色 / 顶栏磨砂，
      // 系统不再加那层灰压色（2026-10-18 平板实拍「状态栏灰带」的成因）。
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: light ? Brightness.dark : Brightness.light,
        statusBarBrightness: light ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            light ? Brightness.dark : Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: light ? const Color(0xFFFAFAFA) : const Color(0xFF08080A),
        body: DemoStage(
          // 导航形态按**画面自己的容器宽**判（`LayoutBuilder` 的
          // `constraints.maxWidth`），不读窗口宽 —— 与 MReader 主壳层
          // （`lib/ui/home_shell.dart`：`LayoutBuilder` + `maxWidth > 600`）
          // 同一做法。差别只在这里的画布可能被等比缩小或嵌在手机框里：
          // 手机框 393 再宽的窗口也不摆侧栏，平板/桌面画面就摆。
          // 断点 `MiBreakpoints.navRail` = 600，**严格大于**才切侧栏。
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sideNav = MiBreakpoints.usesSideNav(constraints.maxWidth);
              return Container(
                // `clipBehavior` 恒为 antiAlias（圆角在铺满时给 `zero`）：
                // 切换 framed 若增删裁剪层，`Container` 内部的 widget 结构会变，
                // 页面 Element 被重建 → 跨断点时滚动位置会丢。
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  // 手机档用设备底色；铺满窗口时用**页底色**（页面只占右侧
                  // 内容列，侧栏那一列若不是页底色，深色下会与页面之间出现
                  // 一道竖缝）。
                  color: framed
                      ? (light ? const Color(0xFFF7F7F7) : const Color(0xFF0E0E11))
                      : pageBg,
                  borderRadius:
                      framed ? BorderRadius.circular(44) : BorderRadius.zero,
                  boxShadow: framed
                      ? const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 40,
                            offset: Offset(0, 16),
                          ),
                        ]
                      : const [],
                ),
                // Stack 子级一律 Positioned，且页面恒为第一个子级（索引稳定）：
                // 底栏 ⇄ 侧栏切换时 MockPage 的 Element 不重建（滚动位置与页内
                // 状态保留），只是左缘从 0 变成侧栏列宽。
                child: Stack(
                  children: [
                    Positioned(
                      left: sideNav ? MiGlassSideNavMetrics.gutterWidth : 0,
                      top: 0,
                      right: 0,
                      bottom: 0,
                      // 切 tab **不做淡入淡出**（原 260ms `AnimatedSwitcher`）：
                      //  `FadeTransition` 会给整页套一层 `Opacity` → 引入
                      //  saveLayer，而 saveLayer 会让下层 `BackdropFilter` 的
                      //  backdrop 变空（本项目已实测的坑）—— 切页的 260ms 里旧页
                      //  磨砂直接消失、还多算一份 5 段全宽高斯（实测模糊层
                      //  7 → 9、另有 6 层 opacity）。底部 tab 惯例也是瞬时切换，
                      //  参考 App 同款。
                      child: MockPage(
                        _index,
                        key: ValueKey(_index),
                        themeMode: widget.themeMode,
                        onThemeModeChanged: widget.onThemeModeChanged,
                      ),
                    ),
                    if (sideNav)
                      // 侧栏贴顶对齐、距画面左缘与安全区各一档留白（与底部栏
                      // 距屏底一档留白同一口径）；栏体自身收缩到内容高。
                      // 一定要让开状态栏：铺满窗口后侧栏顶就在状态栏那一带。
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: MiGlassSideNavMetrics.gutterWidth,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: MiGlassSideNavMetrics.railMargin,
                            top: safeTop + MiGlassSideNavMetrics.railMargin,
                          ),
                          child: Align(
                            alignment: Alignment.topLeft,
                          child: MiGlassSideNavBar(
                            items: items,
                            selectedIndex: _index,
                            onTap: (i) => setState(() => _index = i),
                            themeMode: widget.themeMode,
                            // 绿色圆钮挂在栏尾下方（选中「首页」时弹出）
                            fab: fab,
                          ),
                          ),
                        ),
                      )
                    else
                      // 手机 / 窄窗：浮动玻璃底栏 + 绿色圆钮（栏体浮起 24.2dp）。
                      //
                      // 浮起量是**距屏幕物理底缘**的实测值（参考截图里系统手势
                      // 条就落在这 24.2 之内），所以不能再叠加一遍安全区 ——
                      // edge-to-edge 之后 `padding.bottom` 拿到的是手势条高度
                      // (~20dp)，叠加会把栏顶到 45dp、比参考高 20dp，手势条就悬
                      // 在栏下空档里。只有安全区**本身比 24.2 还大**（三键导航
                      // 48dp）时才抬起来，否则栏会压在系统按键上。
                      //
                      // 画面里的那张手势条**由系统自己画**：示例不再自绘 Home
                      // 指示条（旧版自绘一条 138×5 的灰条 + 系统真条 = 两条，
                      // 2026-10-20 真机反馈）。
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: math.max(24.2, safeBottom),
                        child: MiGlassNavBar(
                          items: items,
                          selectedIndex: _index,
                          onTap: (i) => setState(() => _index = i),
                          themeMode: widget.themeMode,
                          // 预留空位圆钮：仅选中「首页」时显示（切走收起）；
                          // 与侧栏形态共用同一份声明。
                          fab: fab,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
