import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../popup_host.dart';
import '../../theme/bottom_sheet_tokens.dart';
import '../../theme/mi_theme.dart';
import '../../theme/theme_mode.dart';
import '../../theme/transparency_tokens.dart';
import '../../theme/typography.dart';
import '../../foundations/squircle.dart';
import 'bottom_sheet_metrics.dart';

/// 底部弹窗 / 抽屉（`MiBottomSheet`）：贴底滑入的模态层，带拖拽手柄。
///
/// 结构（自外向内）：遮罩（压暗整屏，点按交宿主收起）→ 贴底抽屉本体
/// （**只圆上两角**，下缘贴屏）→ 手柄 + 标题行 + 内容。几何与动效口径见
/// [MiBottomSheetMetrics]，配色见 `theme/bottom_sheet_tokens.dart`。
///
/// ```dart
/// MiBottomSheet(
///   show: _showSheet,
///   title: '选择操作',
///   onDismissRequest: () => setState(() => _showSheet = false),
///   onDismissed: () => debugPrint('收起了'),
///   child: Column(children: [/* 任意内容 */]),
/// )
/// ```
///
/// ## 行为
///
///  * **声明式显隐**：[show] 是唯一开关。打开 = 挂载并弹簧滑入；关闭 =
///    弹簧滑出，**滑出收口后**才回调 [onDismissed]（组件不提前自毁 ——
///    与 `MiPullUpPanel` 同一契约），宿主在回调里清状态即可；
///  * **弹出层**：经 [MiPopup] 注册到最近的 [MiPopupHost] —— 有宿主时画在
///    宿主层区（弹层间 z 序 = 注册序，且不扰动页面 Stack）；无宿主时就地
///    渲染（单组件用法与既有组件一致）；
///  * **下拉关闭**：[showHandle] 的手柄是唯一拖拽把手（内容区留给内部
///    滚动，整面拖会与滚动抢手势）。下拉超过阈值 / 快速下甩触发
///    [onDismissRequest]；上拉受阻尼（抽屉已贴底，没有上拉空间）；
///  * **遮罩**：点按触发 [onDismissRequest]（`null` = 不响应，**是否收起
///    由宿主决定**）；[enableScrim] 为 false 时不压暗、仍留一层透明命中层
///    （同 `MiPullUpPanel` 的「无压暗遮罩」口径）；
///  * **宽度**：手机档铺满屏宽；宽屏限宽 [MiBottomSheetMetrics.maxWidth]
///    并居中（桌面端通栏抽屉没有边界感）；
///  * **高度**：内容自适应，上界 = 屏高 − 安全区上缘；内容超出时**内部
///    滚动**（内容自带滚动体），标题行与手柄保持可见；
///  * **键盘**：`viewInsets.bottom` 大于安全区时把抽屉整体抬到键盘之上
///    （否则贴底抽屉会被键盘整个盖住）。
///
/// **返回键不代管**：弹层不是路由，拦截返回键需要宿主自己挂 `PopScope`
/// （与 `MiDialog` 同一约定）。
class MiBottomSheet extends StatefulWidget {
  const MiBottomSheet({
    super.key,
    required this.show,
    required this.child,
    this.title,
    this.leading,
    this.trailing,
    this.onDismissRequest,
    this.onDismissed,
    this.enableDragDismiss = true,
    this.enableScrim = true,
    this.showHandle = true,
    this.cornerRadius = MiBottomSheetMetrics.cornerRadius,
    this.maxWidth = MiBottomSheetMetrics.maxWidth,
    this.themeMode,
  });

  /// 抽屉表面的 key（测试读几何 / 量贴底位置；不是公开 API 语义）。
  static const Key surfaceKey = Key('mi-bottom-sheet-surface');

  /// 拖拽手柄的 key（测试量手柄几何 / 发拖拽手势）。
  static const Key handleKey = Key('mi-bottom-sheet-handle');

  /// 遮罩的 key（测试点按 / 读压暗进度）。
  static const Key scrimKey = Key('mi-bottom-sheet-scrim');

  /// 是否显示（唯一开关；关闭时播滑出动画）。
  final bool show;

  /// 内容（在抽屉终态尺寸下排版；超出上界时自行滚动）。
  final Widget child;

  /// 标题（居中单行；与 [leading] / [trailing] 同排，左右各让一档内缩）。
  final String? title;

  /// 标题行左槽（如关闭钮）。
  final Widget? leading;

  /// 标题行右槽（如「完成」）。
  final Widget? trailing;

  /// 收起请求（遮罩点按 / 手柄下拉到位都会触发）；null = 不响应。
  ///
  /// 组件**不接管自身移除**：宿主把 [show] 置 false，滑出收口后才回调
  /// [onDismissed]。
  final VoidCallback? onDismissRequest;

  /// 滑出动画收口后的回调（宿主可在此清状态 / 做后续动作）。
  final VoidCallback? onDismissed;

  /// 是否允许下拉关闭（false = 手柄仍可按下反馈，但下拉只是阻尼回弹）。
  final bool enableDragDismiss;

  /// 是否压暗背景（false = 透明命中层，同 `MiPullUpPanel`）。
  final bool enableScrim;

  /// 是否显示拖拽手柄（false = 无拖拽把手，只能点遮罩 / 调 [show] 收起）。
  final bool showHandle;

  /// 圆角（只作用于上两角）。
  final double cornerRadius;

  /// 宽屏限宽。
  final double maxWidth;

  /// 明暗模式；为空时跟随 [MiTheme]，未声明时跟环境 `Theme` 亮度。
  final MiThemeMode? themeMode;

  @override
  State<MiBottomSheet> createState() => _MiBottomSheetState();
}

class _MiBottomSheetState extends State<MiBottomSheet>
    with TickerProviderStateMixin {
  /// 开合进度 0（完全滑出）…1（就位）；弹簧可轻微过冲到
  /// [MiBottomSheetMetrics.springUpperBound]，故用无界控制器。
  late final AnimationController _progress =
      AnimationController.unbounded(vsync: this, value: 0);

  /// 手柄按压反馈（变长 + 变亮）。
  late final AnimationController _handlePress = AnimationController(
    vsync: this,
    duration: const Duration(
      milliseconds: MiBottomSheetMetrics.handlePressInMs,
    ),
    reverseDuration: const Duration(
      milliseconds: MiBottomSheetMetrics.handlePressOutMs,
    ),
  );

  /// 是否登记到弹层宿主（滑出动画期间仍为 true —— 提前注销会让抽屉瞬移）。
  late bool _registered = widget.show;

  /// 下拉位移（dp，正 = 向下）。
  double _drag = 0;

  /// 拖拽速度追踪（松手时的速度比 `DragEndDetails.velocity` 更贴近手指）。
  VelocityTracker? _tracker;

  @override
  void initState() {
    super.initState();
    if (widget.show) _springTo(1);
  }

  @override
  void didUpdateWidget(MiBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show == oldWidget.show) return;
    if (widget.show) {
      setState(() {
        _registered = true;
        _drag = 0;
      });
      _springTo(1);
    } else {
      _springTo(0);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _handlePress.dispose();
    super.dispose();
  }

  /// 弹簧到 [target]（1 = 就位 / 0 = 完全滑出）。
  void _springTo(double target) {
    _progress
        .animateWith(
          SpringSimulation(
            MiBottomSheetMetrics.spring,
            _progress.value,
            target,
            0,
          ),
        )
        .orCancel
        .then((_) => _settle(target), onError: (Object _) {
      // 期间被反向弹簧接管（重新打开 / 又关一次）：忽略，新的 ticker 负责收尾。
    });
  }

  /// 滑出收口：注销弹层条目并回调宿主。
  void _settle(double target) {
    if (!mounted || target != 0 || widget.show) return;
    setState(() {
      _registered = false;
      _drag = 0;
    });
    widget.onDismissed?.call();
  }

  void _onDragStart(DragStartDetails details) {
    _handlePress.forward();
    _tracker = VelocityTracker.withKind(details.kind ?? PointerDeviceKind.touch)
      ..addPosition(
        details.sourceTimeStamp ?? Duration.zero,
        details.globalPosition,
      );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _tracker?.addPosition(
      details.sourceTimeStamp ?? Duration.zero,
      details.globalPosition,
    );
    var next = _drag + details.delta.dy;
    // 上拉没有空间（抽屉已贴底）、禁用下拉时也不跟随：一律折减成阻尼。
    if (next < 0 || (!widget.enableDragDismiss && next > 0)) {
      next = _drag + details.delta.dy * MiBottomSheetMetrics.dragResistance;
    }
    setState(() => _drag = next);
  }

  void _onDragEnd(DragEndDetails details) {
    _handlePress.reverse();
    final velocity = _tracker?.getVelocity().pixelsPerSecond.dy ??
        details.velocity.pixelsPerSecond.dy;
    _tracker = null;
    final shouldDismiss = widget.enableDragDismiss &&
        (velocity > MiBottomSheetMetrics.flingVelocity ||
            (_drag > MiBottomSheetMetrics.dismissDistance &&
                velocity > -MiBottomSheetMetrics.flingVelocity));
    if (!shouldDismiss) {
      setState(() => _drag = 0);
      return;
    }
    widget.onDismissRequest?.call();
    // 宿主没接（回调为 null / 明确不收起）：把抽屉弹回去，别卡在半截。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.show || _drag == 0) return;
      setState(() => _drag = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_registered) return const SizedBox.shrink();
    // 弹层本体由宿主在其层区渲染（无宿主时就地渲染）。
    return MiPopup(show: true, builder: _body);
  }

  Widget _body(BuildContext context) {
    final mode = MiTheme.modeOf(context, explicit: widget.themeMode);
    final palette = MiBottomSheetPalette.of(mode);
    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = math.max(
      MediaQuery.paddingOf(context).bottom,
      MediaQuery.viewInsetsOf(context).bottom,
    );

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        // 进度可轻微过冲（>1）；遮罩只取 0…1 档。
        final visible = _progress.value.clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onDismissRequest,
                child: ColoredBox(
                  key: MiBottomSheet.scrimKey,
                  color: widget.enableScrim
                      ? MiTransparencyTokens.dialogScrimProgressFor(
                          mode,
                          visible,
                        )
                      : MiTransparencyTokens.clear,
                ),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform.translate(
                      // 拖拽位移用逐帧平移（绘制期变换，不跑布局）。
                      offset: Offset(0, _drag),
                      child: FractionalTranslation(
                        // 按**自身高度**滑：1 = 完全滑出屏外，0 = 就位。
                        // 不必先量高度，短抽屉 / 长抽屉的观感一致。
                        translation: Offset(0, 1 - _progress.value),
                        child: _sheet(
                          mode,
                          palette,
                          constraints.maxHeight - safeTop,
                          safeBottom,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sheet(
    MiThemeMode mode,
    MiBottomSheetPalette palette,
    double maxHeight,
    double bottomInset,
  ) {
    final hasTitleRow =
        widget.title != null || widget.leading != null || widget.trailing != null;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
        maxHeight: math.max(0.0, maxHeight),
      ),
      child: DecoratedBox(
        key: MiBottomSheet.surfaceKey,
        decoration: ShapeDecoration(
          color: palette.surface,
          shape: MiSquircleBorder(widget.cornerRadius, topOnly: true),
        ),
        // 裁形恒定挂（不按状态增删裁剪层，避免子树重建）。
        child: ClipPath(
          clipper: MiSquircleClipper(widget.cornerRadius, topOnly: true),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showHandle) _handle(mode, palette),
              if (hasTitleRow)
                _titleRow(palette)
              else
                const SizedBox(height: MiBottomSheetMetrics.emptyTitleGap),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MiBottomSheetMetrics.insideInset,
                  ),
                  child: widget.child,
                ),
              ),
              // 让开手势条 / 键盘：抽屉表面一直铺到屏底，只把内容抬起来。
              SizedBox(height: bottomInset),
            ],
          ),
        ),
      ),
    );
  }

  /// 拖拽手柄（承托区 24 高的整宽热区；按下变长 + 变亮）。
  Widget _handle(MiThemeMode mode, MiBottomSheetPalette palette) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _handlePress.forward(),
      onTapUp: (_) => _handlePress.reverse(),
      onTapCancel: _handlePress.reverse,
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: SizedBox(
        key: MiBottomSheet.handleKey,
        height: MiBottomSheetMetrics.handleAreaHeight,
        width: double.infinity,
        child: Center(
          child: AnimatedBuilder(
            animation: _handlePress,
            builder: (context, _) {
              final press = _handlePress.value;
              return Container(
                width: MiBottomSheetMetrics.handleWidth +
                    MiBottomSheetMetrics.handlePressGrow * press,
                height: MiBottomSheetMetrics.handleHeight *
                    (1 + MiBottomSheetMetrics.handlePressHeightGrow * press),
                decoration: BoxDecoration(
                  color: palette.handleFor(mode, press: press),
                  borderRadius: BorderRadius.circular(
                    MiBottomSheetMetrics.handleRadius,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 标题行：标题居中，左右槽贴边（同一行内缩）。
  Widget _titleRow(MiBottomSheetPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MiBottomSheetMetrics.insideInset,
        MiBottomSheetMetrics.titleTop,
        MiBottomSheetMetrics.insideInset,
        MiBottomSheetMetrics.titleBottom,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MiBottomSheetMetrics.insideInset,
              ),
              child: Text(
                widget.title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: MiTypography.dialogTitle.copyWith(color: palette.title),
              ),
            ),
          if (widget.leading != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: widget.leading,
            ),
          if (widget.trailing != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: widget.trailing,
            ),
        ],
      ),
    );
  }
}
