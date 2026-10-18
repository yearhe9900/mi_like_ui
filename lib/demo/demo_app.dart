import 'dart:math' as math;

import 'package:flutter/material.dart';
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

/// 示例舞台：把「物理手机画面」摆进任意窗口的自适应外壳。
///
/// ## 覆盖的布局区域
///
/// 只负责**外壳**这一层（窗口背景 + 手机画面的外部几何与缩放），不介入
/// 画面内部的组件几何 —— 内部由各页面的局部断点负责（见 [MockPage]）。
///
/// ## 断点与缩放策略（按**窗口**逻辑宽判档，见 [MiBreakpoints]）
///
/// | 档位 | 窗口宽 | 策略 |
/// |------|--------|------|
/// | compact | < 600dp | 设计画布 393×856 **等比缩小**到放得下（无外边距，手机全屏时恰好 1:1） |
/// | medium | 600…1023dp | 画面**铺成内容舞台**：宽 = 可用宽（上限 [wideMaxWidth]）、高 = 可用高 —— 平板竖屏不再是一个居中的小手机，而是让步数/列数真正利用屏幕 |
/// | expanded | ≥ 1024dp | 同上，宽度上限 [wideMaxWidth]（桌面端不让内容无限拉宽） |
///
/// **为什么 medium 不放大手机、而改成舞台**：平板实测反馈（2026-10-17，
/// 一张 650×1138 的平板截图）里，1x 手机框只占屏高的 64%，上下各留 170/240px
/// 纯黑 —— 大屏上「小手机居中」既浪费空间，也让内容列数停在手机档。改成舞台
/// 后内容宽随屏幕增大 → 网格从 3 列升到 4 列（平板）/ 6 列（桌面），
/// 是**重新布局**而不是把手机拉大（拉大会让 1dp 实测值失去物理意义）。
///
/// 各档都过同一道兜底：[DemoStageSize.rendered] 由
/// `min(1, 可用宽/逻辑宽, 可用高/逻辑高)` 得出 ——
///  * **不溢出**：窗口再小（哪怕 200×200）也只会继续缩小；
///  * **不变形**：宽高乘同一个比例，画面内部不会被宽高各自拉伸；
///  * **实时响应**：`LayoutBuilder` 随窗口/分屏/浏览器缩放自动重排，
///    无需 `setState` 或监听。
///
/// 缩放走 `FittedBox`（Skia 变换 + 矢量重绘），文字与图标不会糊；`scale == 1`
/// 时**不加任何变换层**，黄金图逐像素稳定。
class DemoStage extends StatelessWidget {
  const DemoStage({super.key, required this.child});

  /// 参考机设计画布：1220×2656 录屏 @ 393dp 设计宽（393:856 ≈ 0.459）。
  static const Size designCanvas = Size(393, 856);

  /// 舞台的最大宽度（桌面端不让内容无限拉宽）。
  static const double wideMaxWidth = 1000;

  /// 舞台的最小高度（更矮的窗口交给兜底缩放）。
  static const double minStageHeight = 480;

  /// medium / expanded 档的四周留白；compact（手机全屏）为 0，保证 1:1。
  static const double gutter = 24;

  /// 画面内容：拿到 [DemoStageSize.logical] 的 **tight** 约束。
  final Widget child;

  /// 纯函数解算（可直接单测，不需要 widget 树）。
  static DemoStageSize sizeFor(Size available) {
    final sizeClass = MiBreakpoints.ofWidth(available.width);
    final inset = sizeClass.isCompact ? 0.0 : gutter;
    final availW = math.max(0.0, available.width - 2 * inset);
    final availH = math.max(0.0, available.height - 2 * inset);

    var logicalW = designCanvas.width;
    var logicalH = designCanvas.height;
    if (!sizeClass.isCompact) {
      // 平板/桌面：铺成内容舞台 —— 横向用满（可窄至设计宽），纵向用满
      //（不矮于 minStageHeight，再矮由下面的兜底缩放处理）。
      logicalW = math.min(math.max(availW, designCanvas.width), wideMaxWidth);
      logicalH = math.max(availH, minStageHeight);
    }

    final scale = math.min(1.0, math.min(availW / logicalW, availH / logicalH));
    final logical = Size(logicalW, logicalH);
    return DemoStageSize(
      logical: logical,
      rendered: Size(logicalW * scale, logicalH * scale),
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
    // 舞台档（平板/桌面）圆角随画布尺寸小幅放粗，避免大方块上 44 显得过锐。
    final viewport = MiViewport.of(context);
    final radius = viewport.isCompact ? 44.0 : 56.0;

    // **桌面模式**（视口 ≥ 桌面断点）：底部栏换成左侧悬浮侧栏，页面内容给
    // 侧栏让位（左内边距 = 侧栏列宽），页边距/网格列数由容器宽自行重排。
    // 切换是整棵子树替换、**不做淡入淡出**：`Opacity` / `AnimatedSwitcher`
    // 会给含 `BackdropFilter` 的子树引入 saveLayer，磨砂会在切换期间消失
    // （本项目已实测的坑，切 tab 也是同理瞬时切换）。
    final desktop = viewport.isDesktop;
    // 页底色（侧栏那一列与页面同底，避免宽屏上出现一道拼接缝）。
    final pageBg = light ? const Color(0xFFF3F3F3) : const Color(0xFF000000);

    return Scaffold(
      backgroundColor: light ? const Color(0xFFFAFAFA) : const Color(0xFF08080A),
      body: DemoStage(
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            // 桌面档：侧栏那一列改用**页底色**（页面只占右侧内容列），否则
            // 深色下这一列会是 #0E0E11、与页面 #000000 之间出现一道竖缝。
            color: desktop
                ? pageBg
                : (light ? const Color(0xFFF7F7F7) : const Color(0xFF0E0E11)),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 16)),
            ],
          ),
          // Stack 子级一律 Positioned，且页面恒为第一个子级（索引稳定）：
          // 手机 ↔ 桌面切换时 MockPage 的 Element 不重建（滚动位置与页内
          // 状态保留），只是左缘从 0 变成侧栏列宽。
          child: Stack(
            children: [
              Positioned(
                left: desktop ? MiGlassSideNavMetrics.gutterWidth : 0,
                top: 0,
                right: 0,
                bottom: 0,
                // 切 tab **不做淡入淡出**（原 260ms `AnimatedSwitcher`）：
                //  `FadeTransition` 会给整页套一层 `Opacity` → 引入 saveLayer，
                //  而 saveLayer 会让下层 `BackdropFilter` 的 backdrop 变空
                //  （本项目已实测的坑）—— 切页的 260ms 里旧页磨砂直接消失、
                //  还多算一份 5 段全宽高斯（实测模糊层 7 → 9、另有 6 层 opacity）。
                //  底部 tab 惯例也是瞬时切换，参考 App 同款。
                child: MockPage(
                  _index,
                  key: ValueKey(_index),
                  themeMode: widget.themeMode,
                  onThemeModeChanged: widget.onThemeModeChanged,
                ),
              ),
              if (desktop)
                // 侧栏贴顶对齐、距窗口左缘与顶缘各一档留白（与底部栏距屏底
                // 一档留白同一口径）；栏体自身收缩到内容高。
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: MiGlassSideNavMetrics.gutterWidth,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: MiGlassSideNavMetrics.railMargin,
                      top: MiGlassSideNavMetrics.railMargin,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: MiGlassSideNavBar(
                        items: items,
                        selectedIndex: _index,
                        onTap: (i) => setState(() => _index = i),
                        themeMode: widget.themeMode,
                      ),
                    ),
                  ),
                )
              else ...[
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24.2, // measured: bar bottom sits 24.2 dp above screen bottom
                  child: MiGlassNavBar(
                    items: items,
                    selectedIndex: _index,
                    onTap: (i) => setState(() => _index = i),
                    themeMode: widget.themeMode,
                    // 预留空位圆钮：仅选中「首页」时显示（切走收起）
                    fab: MiGlassNavFab(
                      tabIndex: 0,
                      onTap: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('圆形按钮被点击'),
                          duration: Duration(milliseconds: 800),
                        ),
                      ),
                      child: CustomPaint(
                        painter: GridDotsIconPainter(Colors.white),
                        size: const Size.square(18.2),
                      ),
                    ),
                  ),
                ),
                // home indicator (phone chrome, not part of the nav bar)
                // 桌面模式没有手机 Home 指示条（那一档不是"物理手机"画面）。
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 9,
                  child: Center(
                    child: Container(
                      width: 138,
                      height: 5,
                      decoration: BoxDecoration(
                        color: light ? const Color(0xFF959595) : const Color(0xD9FFFFFF),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
