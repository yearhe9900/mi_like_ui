import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_like_ui/mi_like_ui.dart';

import 'host_device.dart';
import 'mock_pages.dart';

export 'host_device.dart' show DemoDevice, demoHostDevice;

/// 演示应用（示例层，不属于框架公共 API）。
///
/// 深/浅色模式切换入口放在「我的」页顶部；模式驱动手机框、mock 页、
/// 导航栏玻璃配方与墨色整体切换。
class DemoApp extends StatefulWidget {
  const DemoApp({super.key, this.device});

  /// 设备语境（null = 自动探测，见 [demoHostDevice]）：决定演示外壳
  /// 「PC 套机身壳 / 移动端铺满全屏」，见 [DemoStage]。
  final DemoDevice? device;

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
      // 首页**也走 [MiCardPageRoute]**：推入转场的「下层页左移视差」需要下层
      // 路由同样支持 `secondaryAnimation`，平台自带路由没有这个钩子（而且
      // Android 默认的 Zoom 转场会自己缩放退出页，与视差叠加）。
      initialRoute: '/',
      onGenerateRoute: (settings) => MiCardPageRoute<void>(
        settings: settings,
        builder: (_) => DemoHome(
          themeMode: _mode,
          device: widget.device,
          onThemeModeChanged: (m) => setState(() => _mode = m),
        ),
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

/// 演示外壳形态（见 [DemoStage] 类注释的形态表）。
enum DemoShellMode {
  /// 铺满全屏（移动端）：无机身壳、无圆角、无投影。
  fullscreen,

  /// 手机壳（PC 窄窗）：393×856 设计画布 + 圆角机身 44。
  phone,

  /// 平板壳（PC 宽窗）：820×1180 画布（横 / 竖择优）+ 圆角机身 32。
  tablet,
}

/// 外壳形态作用域：[DemoStage] 解算后下发，[DemoHome] 据此画机身装饰。
class DemoShellScope extends InheritedWidget {
  const DemoShellScope({super.key, required this.mode, required super.child});

  final DemoShellMode mode;

  static DemoShellMode of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DemoShellScope>()!.mode;

  @override
  bool updateShouldNotify(DemoShellScope oldWidget) => oldWidget.mode != mode;
}

/// 示例舞台：把「画面」摆进任意窗口的演示外壳。
///
/// ## 覆盖的布局区域
///
/// 只负责**外壳**这一层（画面的外部几何、缩放与机身装饰语境），不介入
/// 画面内部的组件几何 —— 内部由各页面的局部断点负责（见 [MockPage]）。
///
/// ## 外壳形态（按**设备语境 × 窗口**判档，见 [DemoDevice] / [modeFor]）
///
/// | 语境 | 形态 | 画面 |
/// |------|------|------|
/// | 移动端（handheld） | **铺满全屏**：无机身壳 / 圆角 / 投影 | = 窗口 |
/// | PC 窄窗（< 600dp） | **手机壳**：圆角机身 44 + 外圈底色 + 投影 | 393×856 设计画布 |
/// | PC 宽窗（≥ 600dp） | **平板壳**：圆角机身 32 + 外圈底色 + 投影 | 820×1180（横 / 竖择优） |
///
/// Web 演示按 `user-agent` 判设备（移动 UA 铺满、桌面 UA 套壳），原生按
/// 运行平台；窄 / 宽断点复用 [MiBreakpoints.navRail]（600dp）语义。
///
/// **为什么 PC 要套壳、真机不套**：PC 浏览器是「展台」，套上模拟机身才
/// 表达得出这是手机 / 平板 UI；真机自己就是机身，铺满即可 —— 套壳会出现
/// 「手机里再套一台手机」。
///
/// 各档都过同一道兜底：[DemoStageSize.rendered] 由
/// `min(1, 可用宽/逻辑宽, 可用高/逻辑高)` 得出 ——
///  * **不溢出**：窗口再小（哪怕 200×200）也只会继续缩小；
///  * **不变形**：宽高乘同一个比例，画面内部不会被宽高各自拉伸；
///  * **实时响应**：`LayoutBuilder` 随窗口/分屏/浏览器缩放自动重排，
///    无需 `setState` 或监听。
///
/// 缩放只缩不放（`scale ≤ 1`）；铺满档 `scale == 1`，**不加任何变换层**，
/// 视觉回归逐像素稳定。
class DemoStage extends StatelessWidget {
  const DemoStage({super.key, required this.child, this.device});

  /// 参考机设计画布：1220×2656 素材 @ 393dp 设计宽（393:856 ≈ 0.459）。
  static const Size designCanvas = Size(393, 856);

  /// 平板壳设计画布（iPad Air 档 820×1180；横 / 竖两副机身按窗口择优）。
  static const Size tabletCanvas = Size(820, 1180);

  /// 机身圆角：手机壳 44（沿用原手机框规格）、平板壳 32（机身大一圈、
  /// 圆角小一号）。
  static const double phoneShellRadius = 44;
  static const double tabletShellRadius = 32;

  /// 画面内容：拿到 [DemoStageSize.logical] 的 **tight** 约束。
  final Widget child;

  /// 设备语境（null = 自动探测，见 [demoHostDevice]）。
  final DemoDevice? device;

  /// 解算外壳形态（纯函数，可直接单测）。
  ///
  /// 移动端恒为 [DemoShellMode.fullscreen]；PC 按窗口宽判档：
  /// `< 600dp` 手机壳、`≥ 600dp` 平板壳（横 / 竖机身择优）。
  static DemoShellMode modeFor(Size available, {DemoDevice? device}) {
    if ((device ?? demoHostDevice()) == DemoDevice.handheld) {
      return DemoShellMode.fullscreen;
    }
    return available.width < MiBreakpoints.navRail
        ? DemoShellMode.phone
        : DemoShellMode.tablet;
  }

  /// 纯函数解算各形态下的舞台几何（可直接单测，不需要 widget 树）。
  static DemoStageSize sizeFor(Size available, {required DemoShellMode mode}) {
    final available0 = Size(
      math.max(0.0, available.width),
      math.max(0.0, available.height),
    );
    if (available0.width == 0 || available0.height == 0) {
      return const DemoStageSize(logical: Size.zero, rendered: Size.zero);
    }

    // fullscreen：画面 = 窗口；phone / tablet：设计画布等比缩到放得下。
    final logical = switch (mode) {
      DemoShellMode.fullscreen => available0,
      DemoShellMode.phone => designCanvas,
      DemoShellMode.tablet => _tabletCanvasFor(available0),
    };

    final scale = math.min(
      1.0,
      math.min(available0.width / logical.width, available0.height / logical.height),
    );
    return DemoStageSize(
      logical: logical,
      rendered: Size(logical.width * scale, logical.height * scale),
    );
  }

  /// 平板壳机身横 / 竖择优：哪副在窗口里摆得下（缩放比大）用哪副。
  static Size _tabletCanvasFor(Size available) {
    final landscape = Size(tabletCanvas.height, tabletCanvas.width);
    return _fitScale(available, landscape) > _fitScale(available, tabletCanvas)
        ? landscape
        : tabletCanvas;
  }

  static double _fitScale(Size available, Size canvas) => math.min(
        1.0,
        math.min(available.width / canvas.width, available.height / canvas.height),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = Size(constraints.maxWidth, constraints.maxHeight);
        final mode = modeFor(available, device: device);
        final stage = sizeFor(available, mode: mode);
        final frame = SizedBox.fromSize(size: stage.logical, child: child);
        final scaled = stage.isScaled
            ? FittedBox(fit: BoxFit.fill, child: frame)
            : frame;
        return Center(
          child: SizedBox.fromSize(
            size: stage.rendered,
            // 形态随窗口 / 设备变化只改**值**、不改结构：画面子树的
            // Element 不重建（跨壳切换滚动位置保留）。
            child: DemoShellScope(mode: mode, child: scaled),
          ),
        );
      },
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    this.device,
  });

  final MiThemeMode themeMode;
  final ValueChanged<MiThemeMode> onThemeModeChanged;

  /// 设备语境（透传给 [DemoStage]，null = 自动探测）。
  final DemoDevice? device;

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> with SingleTickerProviderStateMixin {
  int _index = 0;

  /// 当前页是否处于搜索态 —— 搜索是**聚焦态**（参考素材里那屏没有 App 级
  /// 导航），所以手机档的浮动底栏要收起来。
  bool _searchActive = false;

  void _setSearchActive(bool value) {
    if (value == _searchActive) return;
    setState(() => _searchActive = value);
  }

  /// 弹框演示：当前弹出的位置（null = 未弹）。「我的」页三个入口触发，
  /// 遮罩点按 / 按钮点按都收起。
  MiDialogPosition? _dialogPosition;

  /// 弹框演示（列表形态）：是否弹出纵向操作列表（issue #1）。
  bool _listDialog = false;

  /// 弹出面板演示：首页右下「更多」圆钮唤起（从按钮弹起、可自定义长高）。
  /// `_pullPanel` = 面板挂载（含收回动画进行中）；`_panelExpanded` = 圆钮
  /// 展开态（变深，点按收回时先回绿、收回结束后卸面板）。
  bool _pullPanel = false;
  bool _panelExpanded = false;

  /// 面板控制器：圆钮点按触发**收回动画**（反向弹簧 + 淡出，收口卸载）。
  final _panelController = MiPullUpPanelController();

  /// 圆钮形态交叉淡变（绿⇄展开色）：慢速素材 313 帧中间态实测 —— 填充
  /// 白→绿与点阵黑→白**同时**渐变，~200ms（拟合，收回全程同步）。
  late final AnimationController _fabColorCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  /// 展开态切换（驱动圆钮淡变；v=恢复绿钮）。
  void _setFabExpanded(bool v) {
    setState(() => _panelExpanded = v);
    if (v) {
      _fabColorCtrl.forward();
    } else {
      _fabColorCtrl.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    // 圆钮淡变时刷新 fab 声明（fab 是配置对象、非 widget，靠重建下发新色）。
    _fabColorCtrl.addListener(_onFabColorTick);
  }

  void _onFabColorTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fabColorCtrl.removeListener(_onFabColorTick);
    _fabColorCtrl.dispose();
    super.dispose();
  }

  /// 圆钮图标 Paint 的 key：唤起面板时取它的圆心做缩放锚点。
  final GlobalKey _fabKey = GlobalKey();

  /// 圆钮圆心（全局坐标，面板唤起锚点）。
  Offset? get _fabAnchor {
    final box = _fabKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize) {
      return box.localToGlobal(box.size.center(Offset.zero));
    }
    return null;
  }

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
    // 外壳形态（PC 窄窗手机壳 / 宽窗平板壳、移动端铺满）由 [DemoStage]
    // 按「窗口 × 设备语境」解算后经 [DemoShellScope] 下发，在下方
    // LayoutBuilder 里取用（见 [DemoStage] 类注释）。
    // 页底色（侧栏那一列与页面同底，避免宽屏上出现一道拼接缝）。
    final pageBg = light ? const Color(0xFFF3F3F3) : const Color(0xFF000000);
    // 预留空位圆钮：两种导航形态**共用同一份声明**（仅「首页」选中时展示、
    // 点按弹提示）—— 手机 / 窄窗挂在底部栏右侧（栏体左移让位），平板 /
    // 桌面挂在侧栏栏尾下方（栏体不动、槽位恒定预留）。显隐契约、弹出曲线
    // 与直径/间距 token 两种形态逐帧同源。
    // 展开态圆钮：填充与点阵随 _fabColorCtrl 交叉淡变（度量：暗 #131313 /
    // 浅 #FBFBFB 填充，浅色点阵黑、暗色点阵白；静止 t=0 时传 null 走导航栏
    // 自带绿钮 token，与既有像素一致）。
    final fabT = Curves.easeInOut.transform(_fabColorCtrl.value);
    final fabLight = widget.themeMode == MiThemeMode.light;
    final fab = MiGlassNavFab(
      tabIndex: 0,
      color: fabT == 0
          ? null
          : Color.lerp(
              MiColors.fabGreenFor(widget.themeMode),
              fabLight ? const Color(0xFFFBFBFB) : const Color(0xFF131313),
              fabT,
            ),
      onTap: () {
        // 震动反馈（素材按键有触感；推导：小圆钮点按取 lightImpact 档）。
        HapticFeedback.lightImpact();
        if (_panelExpanded) {
          // 展开态点按 → 播收回动画（反向弹簧 + 淡出），收口后
          // onDismissed 卸载；圆钮同步淡变回绿（素材时序）。
          _setFabExpanded(false);
          _panelController.dismiss();
        } else {
          setState(() {
            _pullPanel = true;
          });
          _setFabExpanded(true);
        }
      },
      child: CustomPaint(
        key: _fabKey,
        painter: GridDotsIconPainter(
          Color.lerp(
            Colors.white,
            fabLight ? Colors.black : Colors.white,
            fabT,
          )!,
        ),
        size: const Size.square(18.2),
      ),
    );
    // edge-to-edge 下内容会铺到状态栏 / 手势条下面，浮层类元素要让开安全区。
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 状态栏透明 + 图标随明暗翻转：状态栏背后就是页面自己的底色 / 顶栏磨砂，
      // 系统不再叠一层灰压色（否则出现一条系统绘制的灰带）。
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
        // **键盘弹出不能让画面重新排版**：`resizeToAvoidBottomInset` 默认 true
        // 会把 body 的高度减掉 `viewInsets.bottom`，而 [DemoStage] 是按可用
        // 高度等比缩放画面的 —— 键盘一弹整块画布就缩水。这里关掉，让键盘
        // **覆盖**在画面上：搜索态
        // 的输入行本就在屏幕顶端，下方那块是空的，被盖住正好。
        resizeToAvoidBottomInset: false,
        body: DemoStage(
          device: widget.device,
          // 导航形态按**画面自己的容器宽**判（`LayoutBuilder` 的
          // `constraints.maxWidth`），不读窗口宽 —— 与 MReader 主壳层
          // （`lib/ui/home_shell.dart`：`LayoutBuilder` + `maxWidth > 600`）
          // 同一做法。差别只在这里的画布可能被等比缩小或嵌在手机框里：
          // 手机框 393 再宽的窗口也不摆侧栏，平板/桌面画面就摆。
          // 断点 `MiBreakpoints.navRail` = 600，**严格大于**才切侧栏。
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sideNav = MiBreakpoints.usesSideNav(constraints.maxWidth);
              // 展开侧栏（带文字标签）：容器宽 ≥ 1024 才换 —— 平板竖屏让出
              // 展开栏 + 留白（201.5）会吃掉 26% 画布，桌面让出后仍剩 ≥822dp。
              final expandedRail =
                  sideNav && MiBreakpoints.usesExpandedRail(constraints.maxWidth);
              // 外壳形态（[DemoStage.modeFor] 解算、[DemoShellScope] 下发）：
              // 壳体画圆角机身 + 投影，铺满档不画。
              final shell = DemoShellScope.of(context);
              final framed = shell != DemoShellMode.fullscreen;
              return Container(
                // `clipBehavior` 恒为 antiAlias（圆角只改数值、不增删裁剪层）：
                // 切换 framed 若增删裁剪层，`Container` 内部的 widget 结构会变，
                // 页面 Element 被重建 → 跨断点 / 跨壳切换时滚动位置会丢。
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  // 壳体用设备底色；铺满全屏时用**页底色**（页面只占右侧
                  // 内容列，侧栏那一列若不是页底色，深色下会与页面之间出现
                  // 一道竖缝）。
                  color: framed
                      ? (light ? const Color(0xFFF7F7F7) : const Color(0xFF0E0E11))
                      : pageBg,
                  // 机身圆角：手机壳 44 / 平板壳 32；铺满（移动端）恒为
                  // [BorderRadius.zero] —— 显式声明而非省略字段，与
                  // 「铺满时无外围卡片」的测试契约一致。
                  borderRadius: framed
                      ? BorderRadius.circular(shell == DemoShellMode.phone
                          ? DemoStage.phoneShellRadius
                          : DemoStage.tabletShellRadius)
                      : BorderRadius.zero,
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
                      left: sideNav
                          ? MiGlassSideNavMetrics.contentInsetFor(
                              expanded: expandedRail,
                            )
                          : 0,
                      top: 0,
                      right: 0,
                      bottom: 0,
                      // 切 tab **不做淡入淡出**（原 260ms `AnimatedSwitcher`）：
                      //  `FadeTransition` 会给整页套一层 `Opacity` → 引入
                      //  saveLayer，而 saveLayer 会让下层 `BackdropFilter` 的
                      //  backdrop 变空（已知行为）—— 切页的 260ms 里旧页
                      //  磨砂直接消失、还多算一份 5 段全宽高斯（度量模糊层
                      //  7 → 9、另有 6 层 opacity）。底部 tab 惯例也是瞬时切换，
                      //  参考 App 同款。
                      //
                      // 内容列上限（[MiContentColumn] 1120dp）**恒定套着**，
                      // 不按断点增删这一层：增删会重建页面 Element、跨断点时
                      // 滚动位置归零。手机 / 平板画面本来 ≤ 1120，套上也一样宽。
                      child: MiContentColumn(
                        child: MockPage(
                          _index,
                          key: ValueKey(_index),
                          themeMode: widget.themeMode,
                          onThemeModeChanged: widget.onThemeModeChanged,
                          onSearchActiveChanged: _setSearchActive,
                          onShowDialog: (position) =>
                              setState(() => _dialogPosition = position),
                          onShowListDialog: () =>
                              setState(() => _listDialog = true),
                        ),
                      ),
                    ),
                    // 弹出面板演示（从圆钮弹起）：插在导航栏**之下**绘制 ——
                    // 圆钮要压在面板右下角上（与素材同：展开态深色圆钮可见）。
                    if (_pullPanel)
                      Positioned.fill(
                        key: const ValueKey('pullUpPanelOverlay'),
                        child: MiPullUpPanel(
                          // 自定义长高：演示传固定 240（null = 内容自适应）
                          height: 240,
                          anchorPoint: _fabAnchor,
                          themeMode: widget.themeMode,
                          controller: _panelController,
                          onDismissed: () {
                            setState(() => _pullPanel = false);
                            // 面板外点按收回：面板收口后圆钮才淡变回绿
                            //（圆钮点按收回的路径已在触发时淡变）。
                            if (_panelExpanded) _setFabExpanded(false);
                          },
                          child: _QuickActionsPanel(
                            themeMode: widget.themeMode,
                          ),
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
                        width: MiGlassSideNavMetrics.gutterWidthFor(
                          expanded: expandedRail,
                        ),
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
                            onTap: (i) => setState(() {
                              _index = i;
                              _pullPanel = false;
                              if (_panelExpanded) {
                                _panelExpanded = false;
                                _fabColorCtrl.value = 0;
                              }
                            }),
                            themeMode: widget.themeMode,
                            expanded: expandedRail,
                            // 绿色圆钮挂在栏尾下方（选中「首页」时弹出）
                            fab: fab,
                          ),
                          ),
                        ),
                      )
                    else if (!_searchActive)
                      // 手机 / 窄窗：浮动玻璃底栏 + 绿色圆钮（栏体浮起 24.2dp）。
                      //
                      // **搜索态收起**（`_searchActive`）：参考素材里搜索页是
                      // 整屏的，没有 App 级导航；不复用 Opacity 淡出 —— 那会给
                      // 含 backdrop 的子树加 saveLayer、模糊当场消失（本库已
                      // 已知行为），所以直接换结构。
                      //
                      // 浮起量是**距屏幕物理底缘**的度量值（参考截图里系统手势
                      // 条就落在这 24.2 之内），所以不能再叠加一遍安全区 ——
                      // edge-to-edge 之后 `padding.bottom` 拿到的是手势条高度
                      // (~20dp)，叠加会把栏顶到 45dp、比参考高 20dp，手势条就悬
                      // 在栏下空档里。只有安全区**本身比 24.2 还大**（三键导航
                      // 48dp）时才抬起来，否则栏会压在系统按键上。
                      //
                      // 画面里的那张手势条**由系统自己画**：示例不自绘 Home
                      // 指示条（自绘 + 系统绘制会出现两条）。
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: math.max(24.2, safeBottom),
                        child: MiGlassNavBar(
                          items: items,
                          selectedIndex: _index,
                          onTap: (i) => setState(() {
                            _index = i;
                            _pullPanel = false;
                            if (_panelExpanded) {
                              _panelExpanded = false;
                              _fabColorCtrl.value = 0;
                            }
                          }),
                          themeMode: widget.themeMode,
                          // 预留空位圆钮：仅选中「首页」时显示（切走收起）；
                          // 与侧栏形态共用同一份声明。
                          fab: fab,
                        ),
                      ),
                    // 弹框演示浮层（遮罩 + 卡片一体）：恒在 Stack **末尾**，
                    // 前面子级的下标 / Element 不受影响（已知行为：
                    // Stack 子级增删按槽位配对，中插会让后面的子树重建）。
                    if (_dialogPosition != null)
                      Positioned.fill(
                        key: const ValueKey('dialogOverlay'),
                        child: MiDialog(
                          position: _dialogPosition!,
                          themeMode: widget.themeMode,
                          onScrimTap: () =>
                              setState(() => _dialogPosition = null),
                          title: '删除联系人',
                          message: '确定从本地和云端同时删除“方太安装师傅”吗？',
                          messageAlign: TextAlign.start,
                          actions: [
                            MiDialogAction(
                              label: '取消',
                              onPressed: () =>
                                  setState(() => _dialogPosition = null),
                            ),
                            MiDialogAction(
                              label: '删除',
                              style: MiDialogActionStyle.destructive,
                              onPressed: () =>
                                  setState(() => _dialogPosition = null),
                            ),
                          ],
                        ),
                      ),
                    // 操作列表弹框演示（issue #1）：长按操作单的典型内容 ——
                    // 两行左对齐标题 + 三项（图标 + 主文案 + 副标题、末项
                    // 危险红字）+ 「取消」按钮行。几何全为推导值。
                    if (_listDialog)
                      Positioned.fill(
                        key: const ValueKey('listDialogOverlay'),
                        child: MiDialog(
                          layout: MiDialogLayout.list,
                          themeMode: widget.themeMode,
                          onScrimTap: () =>
                              setState(() => _listDialog = false),
                          title: '图书操作：《置身事内：中国政府与经济发展》',
                          items: [
                            MiDialogItem(
                              label: '收藏到书架',
                              icon: const Icon(Icons.star_outline, size: 22),
                              onPressed: () =>
                                  setState(() => _listDialog = false),
                            ),
                            MiDialogItem(
                              label: '下载到本地',
                              subtitle: '离线阅读，Wi-Fi 下自动更新',
                              icon: const Icon(
                                Icons.download_outlined,
                                size: 22,
                              ),
                              onPressed: () =>
                                  setState(() => _listDialog = false),
                            ),
                            MiDialogItem(
                              label: '删除',
                              subtitle: '从书架移除并删除本地文件',
                              destructive: true,
                              icon: const Icon(Icons.delete_outline, size: 22),
                              onPressed: () =>
                                  setState(() => _listDialog = false),
                            ),
                          ],
                          actions: [
                            MiDialogAction(
                              label: '取消',
                              onPressed: () =>
                                  setState(() => _listDialog = false),
                            ),
                          ],
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

/// 弹出面板演示内容（demo 功能，非框架组件）：标题 + 3×2 快捷操作网格。
///
/// 高度由外层 `MiPullUpPanel.height` 自定义（240dp）；内容在终态尺寸下
/// 排版、随面板一起缩放。
class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({required this.themeMode});

  final MiThemeMode themeMode;

  static const List<(IconData, String)> _entries = [
    (Icons.qr_code_scanner, '扫一扫'),
    (Icons.payment, '付款码'),
    (Icons.nfc, '乘车卡'),
    (Icons.screenshot, '截图'),
    (Icons.dark_mode_outlined, '深色模式'),
    (Icons.settings_outlined, '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    final ink = MiColors.foregroundFor(themeMode);
    // 副文字 = 墨色 @70%（demo 层示意值）。
    final sub = themeMode == MiThemeMode.dark
        ? const Color(0xB3FFFFFF)
        : const Color(0xB3000000);

    Widget cell((IconData, String) entry) => Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(entry.$1, size: 26, color: ink),
          const SizedBox(height: 8),
          Text(
            entry.$2,
            style: MiTypography.dialogItemSubtitle.copyWith(color: sub),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快捷操作',
            style: MiTypography.dialogTitle.copyWith(color: ink),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (final e in _QuickActionsPanel._entries.sublist(0, 3)) cell(e),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final e in _QuickActionsPanel._entries.sublist(3)) cell(e),
            ],
          ),
        ],
      ),
    );
  }
}
