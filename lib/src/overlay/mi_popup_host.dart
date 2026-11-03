import 'package:flutter/material.dart';

/// 弹层句柄：宿主渲染一条弹层所需的最小描述。
///
/// 由 [MiPopup] 创建并持有（字段经 [MiPopupRegistry.notify] 刷新），
/// 宿主只读渲染 —— 弹层本体的构造闭包以**注册方的 build context** 求值，
/// Theme / MediaQuery / Navigator 按弹层声明位置解析，与就地渲染同语义。
class MiPopupHandle {
  MiPopupHandle({required this.build, required this.modal, this.tag});

  /// 构造弹层本体（入参 = [MiPopup] 的 build context）。
  final Widget Function(BuildContext context) build;

  /// 模态性：true = 弹层本体自己处理命中（遮罩吸收下层点按）；
  /// false = 宿主包 [IgnorePointer]（如 Snackbar —— 不拦下层交互）。
  final bool modal;

  /// 类型标签（如 `'snackbar'`）：供 [MiPopupRegistry.removeByTag]
  /// 做「同类替换」（新消息顶掉旧消息）。
  final String? tag;
}

/// 弹层注册表：宿主内弹层的**有序**清单（插入序即绘制序，后开在上）。
///
/// 不做 zIndex 状态机：本库同时可见的浮层 ≤ 2（弹框 / 面板 / snackbar
/// 排队出现），插入序足以表达全部偏序 —— 这是相对 flutter_miuix 四件套
/// （PopupEntry/Registry/Scope/Layout/Host，千行）的刻意裁剪。
class MiPopupRegistry extends ChangeNotifier {
  final List<MiPopupHandle> _entries = <MiPopupHandle>[];

  /// 当前注册的弹层（只读视图，宿主按序渲染）。
  List<MiPopupHandle> get entries => List<MiPopupHandle>.unmodifiable(_entries);

  void add(MiPopupHandle handle) {
    _entries.add(handle);
    notifyListeners();
  }

  void remove(MiPopupHandle handle) {
    if (_entries.remove(handle)) notifyListeners();
  }

  /// 移除某类标签的全部弹层（snackbar 的「同类替换」）。
  void removeByTag(String tag) {
    final before = _entries.length;
    _entries.removeWhere((h) => h.tag == tag);
    if (_entries.length != before) notifyListeners();
  }

  /// 句柄内容变更（非增删）时请求宿主重建 —— 注册方专用，
  /// 补上 `notifyListeners` 的 `@protected` 可见性。
  void refresh() => notifyListeners();
}

/// 弹层宿主作用域：把 [MiPopupRegistry] 暴露给最近的后代 [MiPopup]。
class MiPopupScope extends InheritedWidget {
  const MiPopupScope({
    super.key,
    required this.registry,
    required super.child,
  });

  final MiPopupRegistry registry;

  /// 取最近宿主的注册表；没有则返回 null（调用方自行降级）。
  static MiPopupRegistry? maybeOf(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<MiPopupScope>()
          ?.registry;

  @override
  bool updateShouldNotify(MiPopupScope oldWidget) =>
      registry != oldWidget.registry;
}

/// 弹层宿主：页面 / 应用级的**单点渲染层**。
///
/// 包住内容子树，其上按注册序渲染全部可见弹层（每条
/// `Positioned.fill` + 模态性处理）。收益（相对「在页面栈里手工插
/// `Positioned.fill`」）：
///
///  * **z 序 = 注册序**：弹框 / snackbar 后开在上，不依赖栈位手工排序；
///  * **不扰动内容栈**：页面栈中插弹层会让其后的子树重建（Stack 子级
///    按槽位配对，滚动位置归零 —— demo 注释里踩过的坑）；注册到宿主
///    完全不动内容栈；
///  * **同类替换**：snackbar 经 [MiPopupRegistry.removeByTag] 顶掉旧条。
///
/// **不入宿主的浮层**：`MiPullUpPanel` 刻意保留在页面栈内 —— 它的绘制位
/// 契约是「导航栏**之下**」（圆钮要压在面板角上），比「一切浮层置顶」
/// 优先。
class MiPopupHost extends StatefulWidget {
  const MiPopupHost({super.key, required this.child});

  /// 被包住的内容（弹层永远渲染在其上）。
  final Widget child;

  @override
  State<MiPopupHost> createState() => _MiPopupHostState();
}

class _MiPopupHostState extends State<MiPopupHost> {
  late final MiPopupRegistry _registry = MiPopupRegistry();

  @override
  void initState() {
    super.initState();
    _registry.addListener(_onRegistryChanged);
  }

  void _onRegistryChanged() => setState(() {});

  @override
  void dispose() {
    _registry
      ..removeListener(_onRegistryChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MiPopupScope(
      registry: _registry,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          for (final handle in _registry.entries)
            Positioned.fill(
              // 非模态（snackbar）：不吃下层命中，只做展示。
              child: IgnorePointer(
                ignoring: !handle.modal,
                child: handle.build(context),
              ),
            ),
        ],
      ),
    );
  }
}

/// 声明式弹层：[show] 为 true 时向最近的 [MiPopupHost] 注册本体。
///
/// **无宿主时就地渲染**（`builder` 直接返回）—— 既有组件用法与黄金图
/// 零变化；有宿主时自身退为占位、由宿主在其层区渲染。
///
/// [builder] 以本组件的 build context 求值（Inherited 解析与就地渲染
/// 一致）；属性变更经注册表通知宿主重建，`show` 切换即注册 / 移除。
class MiPopup extends StatefulWidget {
  const MiPopup({
    super.key,
    required this.show,
    required this.builder,
    this.modal = true,
    this.tag,
  });

  /// 是否可见。
  final bool show;

  /// 弹层本体（以本组件的 context 求值）。
  final WidgetBuilder builder;

  /// 模态性（见 [MiPopupHandle.modal]）。
  final bool modal;

  /// 类型标签（见 [MiPopupHandle.tag]）。
  final String? tag;

  @override
  State<MiPopup> createState() => _MiPopupState();
}

class _MiPopupState extends State<MiPopup> {
  MiPopupRegistry? _registry;
  MiPopupHandle? _handle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registry = MiPopupScope.maybeOf(context);
    if (!identical(registry, _registry)) {
      _unregister();
      _registry = registry;
      _register();
    }
  }

  @override
  void didUpdateWidget(MiPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show != oldWidget.show ||
        widget.modal != oldWidget.modal ||
        widget.tag != oldWidget.tag) {
      _unregister();
      _register();
    } else if (widget.show && _handle != null) {
      // 属性变更（内容 / 回调）：刷新句柄并通知宿主重建（builder 闭包
      // 读的是最新 widget）。
      _registry?.refresh();
    }
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  void _register() {
    final registry = _registry;
    if (!widget.show || registry == null) return;
    _handle = MiPopupHandle(
      build: (context) => widget.builder(context),
      modal: widget.modal,
      tag: widget.tag,
    );
    registry.add(_handle!);
  }

  void _unregister() {
    final registry = _registry, handle = _handle;
    _handle = null;
    if (handle != null) registry?.remove(handle);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();
    // 无宿主：就地渲染（与既有用法逐像素一致）。
    if (_registry == null) return widget.builder(context);
    // 有宿主：本体由宿主在层区渲染，这里只占位保住注册方的 Element。
    return const SizedBox.shrink();
  }
}
