import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../foundations/squircle.dart';
import '../../theme/menu_tokens.dart';
import '../../theme/mi_theme.dart';
import '../../theme/theme_mode.dart';
import '../../theme/transparency_tokens.dart';
import '../popup_host.dart';
import 'menu_item_row.dart';
import 'menu_metrics.dart';
import 'menu_painter.dart';

/// 菜单项（`MiMenuItem`）：一行文案 + 可选前导 / 副标题 + 可选子菜单。
///
/// [children] 非空时该项变成**级联触发器**：点按不平铺回调，而是把面板内容
/// 换成子列表（首行是返回上级的同名行 —— 参考实现的级联导航就是这么表达的）；
/// 叶子项点按后回调 [MiMenu.onSelected] 并收起菜单（[MiMenu.collapseOnSelect]
/// 可关）。
///
/// [value] 是给调用方带业务数据的自由槽位（`onSelected` 会把它原样带回来），
/// 本组件不读它。
@immutable
class MiMenuItem {
  const MiMenuItem({
    required this.label,
    this.subtitle,
    this.leading,
    this.enabled = true,
    this.selected = false,
    this.children = const <MiMenuItem>[],
    this.value,
  });

  /// 主文案（单行，超宽省略）。
  final String label;

  /// 副标题（主文案下方一行，次级墨色）。
  final String? subtitle;

  /// 前导内容（图标 / 色块等，落在 26dp 的单元格里）。
  final Widget? leading;

  /// 是否可点（false = 整行禁用墨色、不响应）。
  final bool enabled;

  /// 是否处于选中态（主文案转强调色 + 尾部勾号）。
  final bool selected;

  /// 子菜单项（非空 = 该项是级联触发器）。
  final List<MiMenuItem> children;

  /// 业务数据槽（`onSelected` 原样带回）。
  final Object? value;

  /// 是否是级联触发器。
  bool get hasChildren => children.isNotEmpty;
}

/// 菜单分组（`MiMenuGroup`）：组间画一条内缩分隔线。
///
/// [enabled] 为 false 时整组降为禁用（仍占位，不做过滤 —— 让「这里本来有
/// 一项、现在不可用」有地方表达）。空组直接跳过。
@immutable
class MiMenuGroup {
  const MiMenuGroup(this.items, {this.enabled = true});

  /// 组内菜单项。
  final List<MiMenuItem> items;

  /// 整组是否启用。
  final bool enabled;
}

/// 选中结果（`MiMenuSelection`）：被点的叶子项 + 从一级到叶子的路径。
///
/// [path] 让级联场景不必自己回查父项（第 0 项是一级菜单项、末项即 [item]）；
/// 非级联时 [path] 只有一个元素。
@immutable
class MiMenuSelection {
  const MiMenuSelection({required this.item, required this.path});

  /// 被点的叶子项。
  final MiMenuItem item;

  /// 一级 → 叶子的完整路径（末项 = [item]）。
  final List<MiMenuItem> path;
}

/// 菜单开合控制器（`MiMenuController`）：给「触发器在菜单外面」的用法准备。
///
/// 典型形态是设置行：行自己的 `onTap` 必须照常响应（整行可点），菜单只借用
/// 行的位置当锚点 —— 于是行里调 `controller.toggle()`，[MiMenu] 负责量出
/// 锚点并弹层。
///
/// ```dart
/// final _menu = MiMenuController();
///
/// MiMenu(
///   controller: _menu,
///   groups: [MiMenuGroup([...])],
///   onSelected: (s) => setState(() => _sort = s.item.label),
///   child: MiSettingsRow(
///     label: '排序方式',
///     value: _sort,
///     trailing: const MiMenuArrow(),
///     onTap: _menu.toggle,
///   ),
/// )
/// ```
class MiMenuController extends ChangeNotifier {
  bool _open = false;

  /// 当前是否展开（含收起动画进行中：以「菜单还在屏幕上」为准）。
  bool get isOpen => _open;

  /// 展开（已展开时无事发生）。
  void open() {
    if (_open) return;
    _open = true;
    notifyListeners();
  }

  /// 收起（已收起时无事发生）。收起动画收口后才真正卸载。
  void close() {
    if (!_open) return;
    _open = false;
    notifyListeners();
  }

  /// 开 ↔ 关。
  void toggle() => _open ? close() : open();
}

/// 锚定式菜单（`MiMenu`）：包住**触发器**，从它的位置展开一张选项面板。
///
/// 结构（自外向内）：锚点子树 → 遮罩（压暗 + 点外收起）→ 面板（连续圆角
/// 表面 + 分组项 + 分组分隔线）。几何与动效口径见 [MiMenuMetrics]，配色见
/// `theme/menu_tokens.dart`。
///
/// ```dart
/// MiMenu(
///   groups: [
///     MiMenuGroup([
///       MiMenuItem(label: '名称', selected: true, value: 'name'),
///       MiMenuItem(label: '大小', value: 'size'),
///     ]),
///   ],
///   onSelected: (s) => print(s.item.value),
///   child: MiButton(label: '排序', onPressed: _menu.toggle),
/// )
/// ```
///
/// ## 行为
///
///  * **锚点即子级**：菜单的位置量自 [child] 的盒子（右缘对齐、优先下方，
///    见 [MiMenuMetrics.panelOffset]）—— 行 / 图标 / 按钮都能直接当触发器，
///    不需要额外的定位参数；
///  * **弹出层**：经 [MiPopup] 注册到最近的 [MiPopupHost]，与弹框 / 抽屉共用
///    单点渲染层（z 序 = 注册序，不扰动页面 Stack）；无宿主时就地渲染，
///    位置退化为锚点自身坐标系（建议在宿主内使用）；
///  * **开合**：由 [controller] 驱动（不传时内部持有一个，但仍需调用方在
///    触发器上调用 `toggle()` —— 本组件**不劫持**子级的点按，行 / 按钮的
///    `onTap` 语义原样保留）；
///  * **级联**：带 [MiMenuItem.children] 的项点开子列表，子列表首行是返回
///    上级的同名行；收起后级联路径复位；
///  * **收起**：选中叶子项（[collapseOnSelect]）、点遮罩、系统返回 —— 收起
///    动画收口后才回调 [onDismissed]（组件不提前自毁，宿主不必等）；
///  * **不发震动**：触感属业务语义，由调用方在 `onSelected` 里自行触发
///    （与 `MiCheckbox` / `MiBottomSheet` 同一口径）。
///
/// **锚点位置只在展开那一刻量一次**：菜单开着时页面滚动 / 旋转不会带着面板
/// 走（参考实现同口径）—— 需要跟随的场景请先收起。
class MiMenu extends StatefulWidget {
  const MiMenu({
    super.key,
    required this.groups,
    required this.child,
    this.controller,
    this.onSelected,
    this.onDismissed,
    this.themeMode,
    this.maxHeight,
    this.enableScrim = true,
    this.collapseOnSelect = true,
  });

  /// 面板表面的 key（测试读几何；不是公开 API 语义）。
  static const Key panelKey = Key('mi-menu-panel');

  /// 遮罩的 key（测试点按 / 读压暗；不是公开 API 语义）。
  static const Key scrimKey = Key('mi-menu-scrim');

  /// 菜单内容（多组 = 组间带分隔线）。
  final List<MiMenuGroup> groups;

  /// 锚点子树：菜单从它的盒子位置展开。
  final Widget child;

  /// 开合控制器；null = 内部自持（仍需触发器调 `toggle()`）。
  final MiMenuController? controller;

  /// 选中叶子项回调（在收起之前触发）。
  final ValueChanged<MiMenuSelection>? onSelected;

  /// 收起动画**收口后**的回调。
  final VoidCallback? onDismissed;

  /// 明暗模式；为空时跟随 [MiTheme]，未声明时跟环境 `Theme` 亮度。
  final MiThemeMode? themeMode;

  /// 面板高度上限；null = 宿主高度减两侧留白（超出面板内滚动）。
  final double? maxHeight;

  /// 是否压暗背景（false = 透明命中层，点外部仍能收起）。
  final bool enableScrim;

  /// 选中叶子项后是否自动收起（false = 多选 / 连续操作型菜单）。
  final bool collapseOnSelect;

  @override
  State<MiMenu> createState() => _MiMenuState();
}

class _MiMenuState extends State<MiMenu> {
  final GlobalKey _anchorKey = GlobalKey();

  /// 外部未给控制器时内部自持（跟随本 State 生命周期）。
  MiMenuController? _owned;

  MiMenuController get _controller => widget.controller ?? (_owned ??= MiMenuController());

  /// 是否已登记到弹层宿主（收起动画期间仍为 true —— 提前注销会瞬移）。
  bool _registered = false;

  /// 期望可见（false = 正在播收起动画）。
  bool _visible = false;

  /// 锚点矩形（宿主坐标系）与宿主尺寸，展开那一刻量一次。
  Rect _anchor = Rect.zero;
  Size _host = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(MiMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, widget.controller)) return;
    (oldWidget.controller ?? _owned)?.removeListener(_onControllerChanged);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _owned?.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final open = _controller.isOpen;
    if (open == _visible) return;
    if (!open) {
      setState(() => _visible = false);
      return;
    }
    if (!_measureAnchor()) return;
    setState(() {
      _visible = true;
      _registered = true;
    });
  }

  /// 量锚点盒子，并换算到**弹层宿主坐标系**。
  ///
  /// 直接用宿主的 `RenderBox` 做 `globalToLocal`：演示外壳会把画面等比缩放
  /// （`MiScaledCanvas`），用 `MediaQuery` 当窗口边界会拿到窗外尺寸、换算出来
  /// 的面板整体漂移；`globalToLocal` 自带祖先变换，缩放档下同样成立。
  bool _measureAnchor() {
    final box = _anchorKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return false;
    final global = box.localToGlobal(Offset.zero) & box.size;
    final hostBox =
        context.getElementForInheritedWidgetOfExactType<MiPopupScope>()?.findRenderObject();
    if (hostBox is RenderBox && hostBox.hasSize) {
      _anchor = Rect.fromPoints(
        hostBox.globalToLocal(global.topLeft),
        hostBox.globalToLocal(global.bottomRight),
      );
      _host = hostBox.size;
    } else {
      // 无宿主（就地渲染）：面板画在锚点自己的坐标系里。
      _anchor = Offset.zero & box.size;
      _host = box.size;
    }
    return true;
  }

  void _dismiss() => _controller.close();

  @override
  Widget build(BuildContext context) {
    // Stack 用 passthrough：锚点子树拿到的约束与没有这层时**完全一致**
    // （行在卡片里仍然被 stretch 撑满，不会退化成内容宽度）。
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        KeyedSubtree(key: _anchorKey, child: widget.child),
        if (_registered)
          Positioned.fill(
            child: MiPopup(
              key: const ValueKey<String>('mi-menu-popup'),
              show: true,
              modal: true,
              builder: (context) => _MiMenuPanel(
                groups: widget.groups,
                anchor: _anchor,
                host: _host,
                show: _visible,
                themeMode: widget.themeMode,
                maxHeight: widget.maxHeight,
                enableScrim: widget.enableScrim,
                collapseOnSelect: widget.collapseOnSelect,
                onDismissRequest: _dismiss,
                onSelected: widget.onSelected,
                onDismissed: () {
                  if (!mounted) return;
                  setState(() => _registered = false);
                  widget.onDismissed?.call();
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// 菜单面板（浮层本体）：遮罩 + 定位 + 揭示动效 + 级联内容。
class _MiMenuPanel extends StatefulWidget {
  const _MiMenuPanel({
    required this.groups,
    required this.anchor,
    required this.host,
    required this.show,
    required this.onDismissRequest,
    required this.onSelected,
    required this.onDismissed,
    required this.collapseOnSelect,
    this.themeMode,
    this.maxHeight,
    this.enableScrim = true,
  });

  final List<MiMenuGroup> groups;
  final Rect anchor;
  final Size host;
  final bool show;
  final VoidCallback onDismissRequest;
  final ValueChanged<MiMenuSelection>? onSelected;
  final VoidCallback onDismissed;
  final bool collapseOnSelect;
  final MiThemeMode? themeMode;
  final double? maxHeight;
  final bool enableScrim;

  @override
  State<_MiMenuPanel> createState() => _MiMenuPanelState();
}

class _MiMenuPanelState extends State<_MiMenuPanel>
    with TickerProviderStateMixin {
  /// 揭示 / 缩放进度（弹簧可过冲，控制器无界）。
  late final AnimationController _fraction =
      AnimationController.unbounded(vsync: this);

  /// 面板淡入淡出。
  late final AnimationController _alpha = AnimationController(vsync: this);

  /// 遮罩淡入淡出（与面板分开：参考实现的 dim 比 alpha 慢一倍）。
  late final AnimationController _scrim = AnimationController(vsync: this);

  /// 级联路径（空 = 一级菜单，末项 = 当前展开的父项）。
  final List<MiMenuItem> _path = <MiMenuItem>[];

  @override
  void initState() {
    super.initState();
    if (widget.show) _enter();
  }

  @override
  void didUpdateWidget(_MiMenuPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show == oldWidget.show) return;
    if (widget.show) {
      // 重新展开：级联路径复位（收起时保留会让下次直接落在子列表）。
      _path.clear();
      _enter();
    } else {
      _exit();
    }
  }

  @override
  void dispose() {
    _fraction.dispose();
    _alpha.dispose();
    _scrim.dispose();
    super.dispose();
  }

  void _enter() {
    _fraction.animateWith(
      SpringSimulation(
        MiMenuMetrics.fractionSpring,
        _fraction.value,
        1,
        _fraction.velocity,
      ),
    );
    _alpha.animateTo(
      1,
      duration: const Duration(milliseconds: MiMenuMetrics.alphaInMs),
      curve: MiMenuMetrics.alphaInCurve,
    );
    _scrim.animateTo(
      1,
      duration: const Duration(milliseconds: MiMenuMetrics.scrimInMs),
      curve: MiMenuMetrics.scrimCurve,
    );
  }

  void _exit() {
    _fraction.animateWith(
      SpringSimulation(
        MiMenuMetrics.fractionSpring,
        _fraction.value,
        0,
        _fraction.velocity,
      ),
    );
    _alpha.animateTo(
      0,
      duration: const Duration(milliseconds: MiMenuMetrics.alphaOutMs),
      curve: MiMenuMetrics.alphaOutCurve,
    );
    _scrim
        .animateTo(
          0,
          duration: const Duration(milliseconds: MiMenuMetrics.scrimOutMs),
          curve: MiMenuMetrics.scrimCurve,
        )
        .then((_) {
      // 期间又被打开（淡出被反向接管）就不收口。
      if (!mounted || widget.show) return;
      widget.onDismissed();
    });
  }

  void _select(MiMenuItem item) {
    widget.onSelected?.call(
      MiMenuSelection(
        item: item,
        path: List<MiMenuItem>.unmodifiable(<MiMenuItem>[..._path, item]),
      ),
    );
    if (widget.collapseOnSelect) widget.onDismissRequest();
  }

  @override
  Widget build(BuildContext context) {
    final mode = MiTheme.modeOf(context, explicit: widget.themeMode);
    final fromBottom = MiMenuMetrics.revealFromBottom(
      anchor: widget.anchor,
      host: widget.host,
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, Object? result) {
        if (!didPop) widget.onDismissRequest();
      },
      // 浮层画在 `MiPopupHost` 的层区里 —— 那一层通常**在页面的 `Scaffold`
      // 之外**，拿不到 `Material` 提供的文字默认样式（测试环境里会直接渲染
      // 成方框 + 黄色下划线）。垫一层透明 `Material` 把主题排版接回来，
      // 与参考实现的 popup 同口径；它本身不画任何像素。
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_fraction, _alpha, _scrim]),
          builder: (context, _) {
            final fraction = _fraction.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                // 遮罩：点按交宿主收起；不压暗时仍是透明命中层。
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onDismissRequest,
                    child: ColoredBox(
                      key: MiMenu.scrimKey,
                      color: widget.enableScrim
                          ? MiMenuPalette.scrimFor(mode, _scrim.value)
                          : MiTransparencyTokens.clear,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomSingleChildLayout(
                    delegate: _MiMenuLayoutDelegate(anchor: widget.anchor),
                    child: Transform.scale(
                      scale: MiMenuMetrics.enterScale +
                          (1 - MiMenuMetrics.enterScale) * fraction,
                      // 缩放原点与揭示边同一个角：开在下方时是右上角，
                      // 开在上方时是右下角。
                      alignment: Alignment(1, fromBottom ? 1 : -1),
                      child: Opacity(
                        opacity: _alpha.value.clamp(0.0, 1.0),
                        child: ClipPath(
                          clipper: MiMenuRevealClipper(
                            progress: fraction,
                            fromBottom: fromBottom,
                          ),
                          child: GestureDetector(
                            // 吃掉面板内的点按，别漏给遮罩。
                            behavior: HitTestBehavior.opaque,
                            onTap: () {},
                            child: _surface(mode),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _surface(MiThemeMode mode) {
    final palette = MiMenuPalette.of(mode);
    final maxHeight =
        widget.maxHeight ?? (widget.host.height - MiMenuMetrics.margin * 2);
    return DecoratedBox(
      key: MiMenu.panelKey,
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: const MiSquircleBorder(MiMenuMetrics.cornerRadius),
      ),
      child: ClipPath(
        clipper: const MiSquircleClipper(MiMenuMetrics.cornerRadius),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MiMenuMetrics.minWidth,
            maxWidth: MiMenuMetrics.maxWidth,
            minHeight: MiMenuMetrics.minHeight,
            maxHeight: maxHeight < MiMenuMetrics.minHeight
                ? MiMenuMetrics.minHeight
                : maxHeight,
          ),
          // 面板尺寸跟着层级内容走：3 行 → 4 行这类切换不再「先跳到最大
          // 再落定」，宽度与高度按 `submenuMs` 一起过渡（与 Compose 原版
          // AnimatedContent 的 SizeTransform 同义；Flutter 移植版直接用
          // AnimatedSwitcher，是不管尺寸的）。顶对齐：面板吊在锚点那侧，
          // 长高 / 收短都该从固定边推出去。
          child: AnimatedSize(
            duration: const Duration(milliseconds: MiMenuMetrics.submenuMs),
            curve: Curves.easeOut,
            alignment: AlignmentDirectional.topCenter,
            // 宽度按内容取（下限 200 / 上限 288）；行少时面板就是内容宽，
            // 长文案单行省略 —— 与参考实现的「按前 8 项最宽者定宽」同效。
            child: IntrinsicWidth(
              // 切换层级：整层（含各自的滚动体）做 0.95→1 + 淡入淡出，两层
              // 在同一个顶对齐 Stack 里就地换 —— 与参考实现的口径一致。
              // 滚动体必须**在切换子树之内**（每层各一个），否则两层共用
              // 一条滚动轴，旧层的偏移会带到新层。
              child: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: MiMenuMetrics.submenuMs,
                ),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                // 退出层不参与定尺寸：默认 `layoutBuilder` 取两层最大值，
                // 面板会先长到两层之和再缩回。这里按**当前层**定尺寸，
                // 退出层顶对齐溢出、由外层的 AnimatedSize / squircle 裁掉；
                // 退出层同样拿当前层的宽（tight width），两层按行对齐。
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: AlignmentDirectional.topStart,
                  children: <Widget>[
                    for (final child in previousChildren)
                      Positioned(top: 0, left: 0, right: 0, child: child),
                    if (currentChild != null) currentChild,
                  ],
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: MiMenuMetrics.submenuScale,
                      end: 1,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _levelView(mode, palette),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 当前层级的滚动体（键随层级变化，`AnimatedSwitcher` 才会换内容）。
  Widget _levelView(MiThemeMode mode, MiMenuPalette palette) {
    final level = _path.length;
    return SingleChildScrollView(
      key: ValueKey<String>(
        'mi-menu-level-$level-${level == 0 ? '' : _path.last.label}',
      ),
      physics: const ClampingScrollPhysics(),
      child: _content(mode, palette),
    );
  }

  Widget _content(MiThemeMode mode, MiMenuPalette palette) {
    final level = _path.length;
    final columns = <Widget>[];
    if (level == 0) {
      var groups = 0;
      for (final group in widget.groups) {
        if (group.items.isEmpty) continue;
        if (groups > 0) columns.add(_divider(palette));
        for (final item in group.items) {
          columns.add(
            MiMenuItemRow(
              label: item.label,
              subtitle: item.subtitle,
              leading: item.leading,
              selected: item.selected,
              hasChildren: item.hasChildren,
              enabled: group.enabled && item.enabled,
              onTap: item.hasChildren
                  ? () => setState(() => _path.add(item))
                  : () => _select(item),
              themeMode: mode,
            ),
          );
        }
        groups++;
      }
    } else {
      final parent = _path.last;
      final children = parent.children;
      // 子列表首行 = 返回上级（同名行 + 左向箭头，参考实现的级联导航）。
      // 副文照抄父项：参考实现同样整行复用父项，两层的首行等高才能让切换
      // 时上下两层按行对齐（少写副文会让整列上移，看起来是「两页错位叠」）。
      columns.add(
        MiMenuItemRow(
          label: parent.label,
          subtitle: parent.subtitle,
          leading: parent.leading,
          showBackArrow: true,
          enabled: true,
          onTap: () => setState(() => _path.removeLast()),
          themeMode: mode,
        ),
      );
      for (final item in children) {
        columns.add(
          MiMenuItemRow(
            label: item.label,
            subtitle: item.subtitle,
            leading: item.leading,
            selected: item.selected,
            hasChildren: item.hasChildren,
            enabled: item.enabled,
            onTap: item.hasChildren
                ? () => setState(() => _path.add(item))
                : () => _select(item),
            themeMode: mode,
          ),
        );
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: columns,
    );
  }

  Widget _divider(MiMenuPalette palette) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MiMenuMetrics.dividerInsetX,
          vertical: MiMenuMetrics.dividerPadY,
        ),
        child: SizedBox(
          height: MiMenuMetrics.dividerThickness,
          child: ColoredBox(color: palette.divider),
        ),
      );

}

/// 面板定位：把面板放到锚点旁边（规则见 [MiMenuMetrics.panelOffset]）。
class _MiMenuLayoutDelegate extends SingleChildLayoutDelegate {
  const _MiMenuLayoutDelegate({required this.anchor});

  /// 锚点矩形（与布局尺寸同一坐标系）。
  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: constraints.maxWidth,
        maxHeight: constraints.maxHeight,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      MiMenuMetrics.panelOffset(anchor: anchor, host: size, panel: childSize);

  @override
  bool shouldRelayout(_MiMenuLayoutDelegate oldDelegate) =>
      oldDelegate.anchor != anchor;
}

/// 菜单箭头（上下双向箭头，10×16）：偏好行 / 按钮的「点开是列表」尾饰。
///
/// 只画字形、不带交互：放进 `MiSettingsRow.trailing` 或按钮内部，点按行为
/// 仍归宿主（行 / 按钮自己的 `onTap`）—— 与 [MiMenu] 不劫持子级的口径一致。
///
/// ```dart
/// MiSettingsRow(
///   label: '排序方式',
///   value: '名称',
///   trailing: MiMenuArrow(color: MiSettingsPalette.secondaryFor(mode)),
///   onTap: _menu.toggle,
/// )
/// ```
class MiMenuArrow extends StatelessWidget {
  const MiMenuArrow({super.key, required this.color});

  /// 箭头墨色（一般取次级墨色，与值文同档）。
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MiMenuMetrics.arrowSize.width,
      height: MiMenuMetrics.arrowSize.height,
      child: CustomPaint(painter: MiMenuArrowPainter(color)),
    );
  }
}
