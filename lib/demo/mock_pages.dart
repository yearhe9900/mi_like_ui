import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_like_ui/mi_like_ui.dart';

/// 页面内容左右页边距。
///
/// * compact（手机）：沿用 像素级度量值（首页 11.9 / 「我的」20）；
/// * medium / expanded（外壳已把画面铺成内容舞台）：收到 [MiDimens.spaceXxxl]
///   32 —— 宽画布上继续贴 11.9 会让内容顶到边，24 在 1000dp 以上仍偏窄。
double _pageInset(BuildContext context, double measured) =>
    MiViewport.of(context).isCompact ? measured : MiDimens.spaceXxxl;

/// 宽屏顶栏：搜索栏限宽（**推导值** 520）；手机 / 平板 = null（不限宽）。
///
/// 1120dp 的内容列上一条 1000dp+ 的搜索框既难用也不像桌面应用 —— 桌面
/// 搜索框通行宽度 400…600，取 520（= 内容列的一半不到，右侧留给动作区）。
double? _wideSearchMaxWidth(BuildContext context) =>
    MiViewport.of(context).isExpanded ? 520 : null;

/// 宽屏顶栏动作区：手机 / 平板 = null（**不渲染**，保持度量几何逐像素不变）。
///
/// [builder] 只在宽屏档被求值（动作件本身也是宽屏专属）。
List<Widget>? _wideActions(BuildContext context, List<Widget> Function() builder) =>
    MiViewport.of(context).isExpanded ? builder() : null;

/// 桌面键盘快捷键作用域（⌘K 聚焦搜索 / Esc 退出）。
///
/// **包装层结构恒定**（三档都挂 `MiSearchShortcuts`），只有 [MiSearchShortcuts.
/// autofocus] 随断点切：手机档不抢焦点（触屏没有物理键盘，抢一次焦点还会把
/// 搜索光标的闪烁相位推偏 —— 黄金图实测踩过）。
///
/// ⚠️ 不能写成「compact 档原样返回 child」：跨断点增删这一层会让下面的页面
/// Element 重建、滚动位置归零（`Focus`/`CallbackShortcuts` 换类型即换元素，
/// 同「内容列不能按断点增删」那条坑）。
Widget _keyboardScope(
  BuildContext context, {
  required VoidCallback onFocusSearch,
  required VoidCallback? onEscape,
  required Widget child,
}) =>
    MiSearchShortcuts(
      onFocusSearch: onFocusSearch,
      onEscape: onEscape,
      autofocus: !MiViewport.of(context).isCompact,
      child: child,
    );

/// 宽屏顶栏头部顶部让位（**推导值** 24）；手机 / 平板 = 度量 56。
///
/// 桌面窗口没有状态栏，继续留 56 会在窗口顶部悬出一条空带。
double _headerTopInset(BuildContext context) => MiViewport.of(context).isExpanded
    ? MiTopBarMetrics.desktopHeaderTopInset
    : MiTopBarMetrics.headerTopInset;

/// 顶栏右侧动作按钮（示例层）：⌀32 圆形热区 + 图标 painter。
///
/// 悬停叠色走框架的 [MiHoverFeedback]（实色，不引 saveLayer）；点按弹提示。
/// **不要给它套自带磨砂的子树** —— `MiTopBar.actions` 在搜索转场里会用
/// `Opacity` 淡出，磨砂进那层会被 saveLayer 清空底图。
class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.themeMode,
    required this.icon,
    required this.onTap,
  });

  final MiThemeMode themeMode;
  final CustomPainter icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MiHoverFeedback(
      mode: themeMode,
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: CustomPaint(painter: icon, size: const Size.square(18)),
          ),
        ),
      ),
    );
  }
}

/// 弹一条演示用提示（动作按钮 / 圆钮的统一反馈）。
void _demoSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(milliseconds: 800),
    ),
  );
}

/// 桌面键盘快捷键作用域（示例层）：**⌘/Ctrl + K 聚焦搜索**、**Esc 退出**。
///
/// 桌面应用的通行约定（VS Code / Slack / macOS 各设置页同款）。实现用
/// `CallbackShortcuts`：快捷键沿焦点链冒泡，所以搜索框获得焦点后 ⌘K 仍被
/// 这一层接住（输入框不会消费这个组合键），Esc 则先由输入框自己处理、
/// 剩下的落到 [onEscape]。
///
/// 内部再挂一个 `Focus(autofocus)`：页面初建时没有任何节点持有焦点，
/// 键盘事件没有冒泡路径 —— 自动聚焦一个空节点让事件能到达这里。
class MiSearchShortcuts extends StatelessWidget {
  const MiSearchShortcuts({
    super.key,
    required this.onFocusSearch,
    required this.onEscape,
    required this.child,
    this.autofocus = true,
  });

  /// 聚焦搜索（⌘/Ctrl + K）。
  final VoidCallback onFocusSearch;

  /// 退出当前浮层 / 搜索态（Esc）；null = 不处理（继续冒泡到系统，如退出 App）。
  final VoidCallback? onEscape;

  final Widget child;

  /// 是否自动聚焦内部空节点（默认 true）。
  ///
  /// **false 只在手机档用**：触屏没有物理键盘、快捷键无意义，抢一次焦点
  /// 反而会把搜索光标的闪烁相位推偏（黄金图实测踩过）。宿主按断点切这个
  /// 值即可 —— 但**包装层本身必须恒定**：跨断点增删 `CallbackShortcuts` /
  /// `Focus` 会让下面的页面 Element 重建、滚动位置归零（本项目已踩过的坑）。
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            onFocusSearch,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            onFocusSearch,
        if (onEscape != null)
          const SingleActivator(LogicalKeyboardKey.escape): onEscape!,
      },
      // autofocus：让页面一挂载就有焦点路径（否则键盘事件无处冒泡）。
      child: Focus(autofocus: autofocus, child: child),
    );
  }
}

/// ⌘/Ctrl + K 的提示小徽标（宽屏动作区里展示快捷键）。
///
/// 文案随平台：macOS = ⌘K，其余 = Ctrl K。
class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.themeMode});

  final MiThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    final label = mac ? '⌘K' : 'Ctrl K';
    final fg = MiColors.foregroundFor(themeMode);
    return Center(
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: themeMode == MiThemeMode.dark
              ? const Color(0x1FFFFFFF)
              : const Color(0x14000000),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
        ),
      ),
    );
  }
}

/// Simple mock pages (theme-store style) so the glass bar has
/// colorful content behind it — the pages themselves are not the
/// deliverable, the nav bar is. Dark & light variants follow the
/// reference shots; page colors read [Theme.of] brightness, which the
/// demo app switches with the theme mode.
class MockPage extends StatelessWidget {
  const MockPage(
    this.index, {
    super.key,
    this.themeMode = MiThemeMode.dark,
    this.onThemeModeChanged,
    this.onSearchActiveChanged,
    this.onShowDialog,
    this.onShowListDialog,
  });

  final int index;
  final MiThemeMode themeMode;
  final ValueChanged<MiThemeMode>? onThemeModeChanged;

  /// 搜索态开关（true = 页面进入搜索）。外壳据此收起浮动底栏 ——
  /// 参考素材里搜索页是整屏的，没有 App 级导航。
  final ValueChanged<bool>? onSearchActiveChanged;

  /// 弹框演示入口（demo 功能）：按位置弹出 [MiDialog]，由外壳挂浮层。
  final ValueChanged<MiDialogPosition>? onShowDialog;

  /// 弹框演示入口（demo 功能）：弹出纵向操作列表形态
  /// （[MiDialogLayout.list]），由外壳挂浮层。
  final VoidCallback? onShowListDialog;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        // 首页 = 参考页形态：**悬浮头部**（搜索栏 + 胶囊标签行）压在高频横幅
        // 上，横幅与下方区块一起从头部后方滚过 —— 头部区那层恒定 σ 磨砂在
        // 这一页才看得见（见 [_HomePage]）。点搜索栏由本页自己推入搜索页，
        // 不需要外壳配合。
        return _HomePage(themeMode: themeMode);
      case 1:
        // 「分类」tab = 组件展示库：胶囊分类标签切分组，网格是展示位
        return _ShowcasePage(
          themeMode: themeMode,
          onSearchActiveChanged: onSearchActiveChanged,
        );
      default:
        // 次级页形态：**带返回圆钮**（`showBack: true`），首行是卡片 →
        // 用卡片档上内边距（183，即 `_MockPageShell` 默认值）。
        final inset = _pageInset(context, 20);
        return _MockPageShell(
          title: '我的',
          showBack: true,
          padding: EdgeInsets.fromLTRB(
            inset,
            MiTopBarMetrics.contentTopInset,
            inset,
            20,
          ),
          children: [
            // 模式切换入口（demo 功能，放在「我的」里）
            if (onThemeModeChanged != null)
              _ThemeModeSwitch(mode: themeMode, onChanged: onThemeModeChanged!),
            if (onThemeModeChanged != null) const SizedBox(height: 12),
            // 弹框演示：三档位置（默认底部），遮罩点按收起
            if (onShowDialog != null) ...[
              const _SectionTitle('弹框演示'),
              _DialogDemoRow(
                caption: '底部弹框（默认）',
                onTap: () => onShowDialog!(MiDialogPosition.bottom),
              ),
              const SizedBox(height: 12),
              _DialogDemoRow(
                caption: '顶部弹框',
                onTap: () => onShowDialog!(MiDialogPosition.top),
              ),
              const SizedBox(height: 12),
              _DialogDemoRow(
                caption: '居中弹框',
                onTap: () => onShowDialog!(MiDialogPosition.center),
              ),
              const SizedBox(height: 12),
              // 纵向操作列表形态（issue #1）：两行左对齐标题 + 图标 /
              // 副标题 / 危险项红字（几何全为推导值）。
              if (onShowListDialog != null)
                _DialogDemoRow(
                  caption: '操作列表弹框（纵向）',
                  onTap: onShowListDialog!,
                ),
              if (onShowListDialog != null) const SizedBox(height: 12),
            ],
            ..._mineItems,
          ],
        );
    }
  }
}

/// 深/浅色模式切换卡片（demo 功能项，非框架组件）。
class _ThemeModeSwitch extends StatelessWidget {
  const _ThemeModeSwitch({required this.mode, required this.onChanged});

  final MiThemeMode mode;
  final ValueChanged<MiThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final light = mode == MiThemeMode.light;
    final fg = Theme.of(context).colorScheme.onSurface;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: light ? const Color(0xFFE7E7E7) : const Color(0xFF1F1F22),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Text('外观模式',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
          const Spacer(),
          Text(light ? '浅色' : '深色',
              style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.6))),
          const SizedBox(width: 8),
          Switch(
            value: !light,
            onChanged: (v) => onChanged(v ? MiThemeMode.dark : MiThemeMode.light),
          ),
        ],
      ),
    );
  }
}

/// 弹框演示入口行（demo 功能项，非框架组件）：点按把弹框挂到外壳浮层。
class _DialogDemoRow extends StatelessWidget {
  const _DialogDemoRow({required this.caption, required this.onTap});

  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _GradientCard(
        height: 56,
        colors: const [Color(0xFF2E3A8C), Color(0xFF49A09D)],
        caption: caption,
      ),
    );
  }
}

/// 页面壳：滚动内容 + 顶部导航栏 [MiTopBar]（大标题 = 页面名）。
///
/// [MiTopBar] 是受控组件（不自带滚动），这里用 [ValueNotifier] 承接
/// [ScrollController] 的位移，只重建顶栏一层而非整页 setState。
/// 页底取参考页度量色（亮 #F3F3F3 / 暗 #000000）——同时让顶栏遮罩
/// 实心段与页底同色（遮罩基色即页底色）。
///
/// 两种页面形态各演示一次：[showBack] 默认 `false`（顶层页，首页），
/// 「我的」传 `true`（次级页，带返回圆钮）。
class _MockPageShell extends StatefulWidget {
  const _MockPageShell({
    required this.title,
    required this.children,
    this.showBack = false,
    this.padding = const EdgeInsets.fromLTRB(
      20,
      MiTopBarMetrics.contentTopInset,
      20,
      20,
    ),
  });

  final String title;
  final List<Widget> children;

  /// 是否显示返回圆钮（默认 false，对齐 [MiTopBar.showBack]）。
  final bool showBack;

  /// 滚动内容内边距：左右默认 20（「我的」页沿用原值）；首页按度量
  /// 页边距 11.9dp + 搜索栏档上内边距 168.5dp 覆盖（见 `MockPage.build`
  /// 的 `case 0`）。
  final EdgeInsetsGeometry padding;

  @override
  State<_MockPageShell> createState() => _MockPageShellState();
}

class _MockPageShellState extends State<_MockPageShell> {
  /// 「我的」这类设置页的内容列上限（**推导值**）：表单/列表行超过 ~720dp
  /// 之后「标签在左、开关在右」的两端距离太远，读起来要来回扫视。手机档
  /// （353dp）根本碰不到这个上限，所以手机观感不变。
  static const double _contentMaxWidth = 720;

  final ScrollController _controller = ScrollController();
  final ValueNotifier<double> _offset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncOffset);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncOffset);
    _controller.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _syncOffset() => _offset.value = _controller.offset;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    // 宽屏显式给滚动条：滚轮是隐式的，没有可见刻度就丢掉了「还有多少」。
    // 手机档（触屏）不显示，避免压住内容边缘。
    final showScrollbar = !MiViewport.of(context).isCompact;
    return ColoredBox(
      color: light ? const Color(0xFFF3F3F3) : const Color(0xFF000000),
      child: Stack(
        children: [
          // Bottom padding stays small on purpose: the content must scroll
          // BEHIND the glass bar (y ≈ 776..832 of the 856-tall frame) or the
          // frosted transmission has nothing to show.
          Positioned.fill(
            child: Scrollbar(
              controller: _controller,
              thumbVisibility: showScrollbar,
              child: ListView(
                controller: _controller,
                padding: widget.padding,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _contentMaxWidth),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: widget.children,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 顶栏必须用 Positioned 钉在顶部：本 Stack 若留下**非定位子级**，
          // 它会按该子级尺寸收缩（= 顶栏自身的 152.8dp 高）而不是撑满父级，
          // 于是整页在 loose 约束的上级（AnimatedSwitcher 内部是
          // `alignment: center` 的 Stack）里被垂直居中 —— 顶栏会跑到屏幕正中，
          // 页底黑与 ListView 只剩 152.8dp 高、内容全被裁掉。
          // 偏移量 =（856 − 152.8）/ 2 = 351.1dp。
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _offset,
              builder: (context, offset, _) => MiTopBar(
                title: widget.title,
                showBack: widget.showBack,
                scrollOffset: offset,
                // 只有 showBack 为 true 时圆钮才存在，回调此时才可能被触发
                onBack: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('返回圆钮被点击'),
                    duration: Duration(milliseconds: 800),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.inset = 0});

  final String text;

  /// 左内缩：首页区块标题行度量 x46 ≈ 20.5dp（页边距 11.9 + 8.6），
  /// 较卡片图区多一档缩进、与卡标题缩进同源对齐；其余页面走默认 0。
  final double inset;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.only(top: 22, bottom: 12, left: inset),
      child: Text(
        text,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

/// 渐变占位卡（示例层，不是框架组件）。
///
/// 高度两种口径，二者取其一：
///  * [height] —— 固定高（手机素材的量法；列表行、账号条这类"行"用它）；
///  * [aspect] —— **宽高比**（宽 / 高），高度跟着列宽算。宽屏必须用这个：
///    手机档两张卡各 172dp 宽、150 高（1.15:1），同一张卡铺到桌面 516dp
///    宽还固定 150 高就成了 3.4:1 的横条。
class _GradientCard extends StatelessWidget {
  const _GradientCard({
    required this.colors,
    required this.caption,
    this.height,
    this.aspect,
  }) : assert(height != null || aspect != null,
            'height 与 aspect 至少给一个');

  final List<Color> colors;
  final String caption;
  final double? height;
  final double? aspect;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(10),
      child: Text(
        caption,
        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
    if (aspect != null) return AspectRatio(aspectRatio: aspect!, child: card);
    return SizedBox(height: height, child: card);
  }
}

/// 首页（参考页形态）：**悬浮头部 + 顶部横幅 + 区块列表**。
///
/// 结构照亮/暗两张完整截图（881×1920）：
///  * 顶部是一条**高频横幅**（[_HeroBanner]，底缘圆角 20dp），从屏幕最顶端
///    （含状态栏后面）铺到度量 ~186dp；
///  * 搜索栏 + 胶囊标签行**悬浮**在横幅上（[MiTopBar] 头部区形态，由顶栏
///    自己产出两个组件），页面只给数据；
///  * 列表**上内边距为 0** —— 横幅与下方区块一起从头部后方滚过，那条恒定 σ
///    的整栏磨砂才有东西可糊（这正是本页要演示的效果）；
///  * 参考页这一形态**没有顶栏压色**（整条栏都能看见被模糊的背景）→
///    `showSurface: false`。
///
/// 与「我的」页的分工：那页保留**大标题折叠**形态（`showBack: true`），
/// 本页换成头部区形态 —— 顶栏两种形态在 demo 里各有一处。
class _HomePage extends StatefulWidget {
  const _HomePage({required this.themeMode});

  final MiThemeMode themeMode;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  /// 胶囊分类标签：取参考截图原文（推荐 / 背屏 / 小部件 / 主题）。
  static const List<String> _tabs = ['推荐', '背屏', '小部件', '主题'];

  int _tab = 0;

  /// 列表滚动控制器：宽屏给可见滚动条（见 build 里的 `Scrollbar`）。
  final ScrollController _scroll = ScrollController();

  /// 是否正在滚动（驱动顶栏「滚动降 σ」）。
  ///
  /// 滚动中 backdrop 每帧重算 —— 把磨砂 σ 压到 0.6，停下 120ms 后恢复度量
  /// 材质。σ 与高斯成本近似线性，运动掩蔽下视觉几乎无差，GPU 省近半。
  bool _scrolling = false;
  Timer? _scrollSettle;

  /// 滚动中的 σ 缩放（**推导值**：0.6 —— 再低就能看出「糊变轻」了）。
  static const double _scrollingSigmaScale = 0.6;

  /// 停止滚动后多久恢复度量 σ（比一帧长、比「人眼觉得停了」短）。
  static const Duration _settleDelay = Duration(milliseconds: 120);

  void _onScroll() {
    if (!_scrolling) setState(() => _scrolling = true);
    _scrollSettle?.cancel();
    _scrollSettle = Timer(_settleDelay, () {
      if (mounted && _scrolling) setState(() => _scrolling = false);
    });
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollSettle?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  /// 点搜索栏 = **推入搜索页**（参考素材的交互），转场见 [MiCardPageRoute]。
  ///
  /// 与「分类」页的**原地搜索态**（`MiTopBar.searchActive`）是两条并行路径：
  /// 那一页搜索栏就地变成输入框、胶囊行淡出；这一页整页推入，下层页左移
  /// 压暗。两种都支持，示例各演示一种。
  void _openSearch() {
    Navigator.of(context).push(
      MiCardPageRoute<void>(
        settings: const RouteSettings(name: 'demo-search'),
        builder: (_) => DemoSearchPage(themeMode: widget.themeMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 首页页边距度量 25~28px ≈ 11.9dp（搜索框 28 / 横幅 25 / 卡片 25~26
    // 同量级，与分类页一致）；宽屏舞台下收到 32。
    final inset = _pageInset(context, 11.9);
    // 头部区形态：搜索栏 + 胶囊行由顶栏内部产出（自带状态栏让位、间距、
    // 页边距），磨砂是**恒定 σ 的整条栏**（参考素材度量，见 MiTopBar 文档）。
    // `overContent: true` —— 横幅从 y=0 起铺、从头部下方滚过，搜索栏与未选
    // 胶囊要铺那层玻璃膜才读得出来（参考素材度量，见 MiTransparencyTokens）。
    final bar = MiTopBar(
      themeMode: widget.themeMode,
      headerInset: inset,
      // 宽屏收敛（手机 / 平板传默认值 → 逐像素不变）：
      //  * 头部顶部让位 56 → 24（桌面窗口没有状态栏）；
      //  * 搜索栏限宽 520（1120 列上一条满宽搜索框既难用也不像桌面应用）；
      //  * 右侧动作区（宽屏才出现），随搜索转场淡出。
      headerTopInset: _headerTopInset(context),
      searchBarMaxWidth: _wideSearchMaxWidth(context),
      actions: _wideActions(context, () => [
        // 快捷键提示徽标（宽屏才出现）：⌘K / Ctrl K —— 按下即聚焦搜索。
        _ShortcutChip(themeMode: widget.themeMode),
        const SizedBox(width: 8),
        _TopBarAction(
          themeMode: widget.themeMode,
          icon: PlusIconPainter(MiColors.foregroundFor(widget.themeMode)),
          onTap: () => _demoSnack(context, '动作按钮被点击'),
        ),
        _TopBarAction(
          themeMode: widget.themeMode,
          icon: GridDotsIconPainter(MiColors.foregroundFor(widget.themeMode)),
          onTap: () => _demoSnack(context, '网格按钮被点击'),
        ),
      ]),
      searchHint: '搜索主题 / 壁纸 / 图标',
      onSearchTap: _openSearch,
      // 滚动降 σ：滚动中磨砂压到 0.6，停下 120ms 恢复度量材质（见 _onScroll）。
      sigmaScale: _scrolling ? _scrollingSigmaScale : 1.0,
      tabs: _tabs,
      selectedTab: _tab,
      onTabChanged: (i) => setState(() => _tab = i),
      showSurface: false,
      overContent: true,
    );
    return _keyboardScope(
      context,
      // 桌面：⌘/Ctrl + K 直达搜索（推入搜索页，与点按搜索栏同一路径）。
      // Esc 不处理（本页没有浮层；搜索页是路由，有自己的作用域）。
      onFocusSearch: _openSearch,
      onEscape: null,
      child: ColoredBox(
        // 页底度量：亮 #F3F3F3 / 暗 #000000。
        color: MiColors.pageBackgroundFor(widget.themeMode),
        child: Stack(
          children: [
            // 列表不留给头部让位：横幅从 y = 0 起铺（含状态栏后面），滚动时从
            // 头部后方经过 —— 与参考素材一致，也是磨砂的可见性来源。
            Positioned.fill(
              key: const ValueKey('homeList'),
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: !MiViewport.of(context).isCompact,
                child: ListView(
                  controller: _scroll,
                  padding: EdgeInsets.zero,
                  children: [
                    const _HeroBanner(key: ValueKey('homeHero')),
                    Padding(
                      padding: EdgeInsets.fromLTRB(inset, 0, inset, 20),
                      // 区块内容随断点变排布（双卡宽幅 / 四卡网格），所以不再是
                      // const 列表 —— 排布规则见 `_homeSections`。
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _homeSections(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 悬浮头部：必须用 Positioned 钉顶（非定位子级会让外层 Stack 收缩）。
            //
            // ⚠️ Stack 的子级一律带 key：增删兄弟节点时按下标配对，否则后面的
            // 子树会被当成新子树重建（顶栏 State 重来 → 搜索态转场直接跳到终态）。
            Positioned(
              key: const ValueKey('homeTopBar'),
              left: 0,
              right: 0,
              top: 0,
              child: bar,
            ),
          ],
        ),
      ),
    );
  }
}

/// 首页顶部横幅（示例占位）：程序化绘制的风景图。
///
/// **为什么不用渐变占位**：平坦色块在模糊下亮度不变，判不了"有没有磨砂"
/// （已知行为）。参考页横幅是一张高频照片（天空 / 树线 / 草地），
/// 这里用 [CustomPainter] 按同样构图生成 —— 树线剪影 + 随机草叶提供了足量
/// 高频细节，滚到头部区后方时能被磨砂明显抹开。
///
/// 几何取参考素材度量：底缘 ≈ 186dp、下圆角 20dp，左右**满幅**（不受页边距
/// 约束，横幅是通栏图）；磨砂带（[MiTopBar.occupiedHeight] ≈ 156dp）落在
/// 横幅上半段，所以静止态就能看到"上半被糊、下半清晰"。
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({super.key});

  /// 横幅高度（度量底缘 ≈ 416px ≈ 186dp）。
  static const double height = 186;

  /// 下圆角（度量底缘收角 ≈ 20dp）。
  static const double bottomRadius = 20;

  @override
  Widget build(BuildContext context) {
    return const ClipRRect(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(bottomRadius),
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _HeroPainter(),
          // 静态图：标成 complex 让引擎缓存成图片，滚动时只做变换不重画。
          isComplex: true,
          willChange: false,
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}

/// 横幅内容：天空 → 远山 → 树线 → 草地（含随机草叶）。
///
/// 全部用固定种子，保证每次布局/截图完全一致（视觉回归可比）。
class _HeroPainter extends CustomPainter {
  const _HeroPainter();

  /// 地平线（天空 → 草地的分界）在横幅内的比例。
  static const double _horizon = 0.62;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // 1) 天空：上深下浅，贴近地平线转暖
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4E86BD), Color(0xFF9CC6E4), Color(0xFFDCE2C6)],
          stops: [0, 0.40, _horizon],
        ).createShader(rect),
    );

    // 2) 太阳光晕（右上）
    final glowCenter = Offset(w * 0.72, h * 0.15);
    final glowRadius = h * 0.32;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x88FFFFFF), Color(0x00FFFFFF)],
        ).createShader(
          Rect.fromCircle(center: glowCenter, radius: glowRadius),
        ),
    );

    // 3) 云：几条横向椭圆
    final cloud = Paint()..color = const Color(0x4DFFFFFF);
    for (final (cx, cy, rx, ry) in const [
      (0.16, 0.13, 0.26, 0.035),
      (0.52, 0.06, 0.34, 0.028),
      (0.86, 0.20, 0.28, 0.040),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * cx, h * cy),
          width: w * rx,
          height: h * ry,
        ),
        cloud,
      );
    }

    // 4) 远山（低饱和紫灰）
    final far = Path()
      ..moveTo(0, h * 0.58)
      ..lineTo(w * 0.16, h * 0.45)
      ..lineTo(w * 0.30, h * 0.51)
      ..lineTo(w * 0.46, h * 0.41)
      ..lineTo(w * 0.62, h * 0.50)
      ..lineTo(w * 0.78, h * 0.44)
      ..lineTo(w, h * 0.53)
      ..lineTo(w, h * _horizon)
      ..lineTo(0, h * _horizon)
      ..close();
    canvas.drawPath(far, Paint()..color = const Color(0xFF8E8DA6));

    // 5) 树线剪影：逐列随机构成锯齿顶缘 —— 模糊下最先被抹成一片的依据
    final rnd = math.Random(20261020);
    final trees = Path()..moveTo(0, h * _horizon);
    var x = 0.0;
    while (x < w) {
      trees.lineTo(x, h * (0.545 + rnd.nextDouble() * 0.055));
      x += 2.5 + rnd.nextDouble() * 4.5;
      trees.lineTo(x, h * (_horizon - 0.035 + rnd.nextDouble() * 0.035));
    }
    trees
      ..lineTo(w, h * _horizon)
      ..close();
    canvas.drawPath(trees, Paint()..color = const Color(0xFF6B5C63));

    // 6) 草地
    final grassRect = Rect.fromLTWH(0, h * _horizon, w, h * (1 - _horizon));
    canvas.drawRect(
      grassRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFAFA954), Color(0xFF7C7A32)],
        ).createShader(grassRect),
    );

    // 7) 草叶：随机竖笔（越靠下越长越粗 → 有透视感，也补足高频纹理）
    final rnd2 = math.Random(7);
    const bladeColors = [
      Color(0xFFCFC163),
      Color(0xFF6E7B33),
      Color(0xFF8E9A3E),
      Color(0xFF5C6428),
    ];
    for (var i = 0; i < 460; i++) {
      final gx = rnd2.nextDouble() * w;
      final gy = h * (_horizon + rnd2.nextDouble() * (1 - _horizon));
      final depth = (gy - h * _horizon) / (h * (1 - _horizon)); // 0 远 → 1 近
      final len = (2 + 9 * depth) * (0.6 + rnd2.nextDouble());
      canvas.drawLine(
        Offset(gx, gy),
        Offset(gx + (rnd2.nextDouble() - 0.5) * 1.6, gy - len),
        Paint()
          ..color = bladeColors[rnd2.nextInt(bladeColors.length)]
          ..strokeWidth = 0.8 + 1.4 * depth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_HeroPainter oldDelegate) => false;
}

/// 首页区块（横幅下方的滚动内容）。
///
/// 分节照亮/暗参考截图：横幅下方依次是「背屏创意设计大赛」（两张大卡）→
/// 「精选主题」（[MiThemeCard] 网格）→「热门 IP」→「经典表盘」→「更多」。
/// 区块标题行经 [_SectionTitle.inset] 收进 ≈20.5dp 文本列（度量 x46），
/// 卡标题再由卡片自身 8.8dp 内缩与之同列起排。
///
/// **排布按断点推导**（参考素材只有手机档，宽屏无样张）：
///  * 双卡宽幅（创意大赛 / 更多）：恒 2 列，卡面比例 1.15 → 1.9 → 2.45。
///    手机档 172×150 与素材一致；若宽屏仍固定 150 高，同一张卡铺到 516dp
///    宽就是 3.4:1 的横条 —— 这就是"拉伸的手机"观感的来源；
///  * 四卡小方（热门 IP / 经典表盘）：手机 2 列 ×2 行，平板/桌面 **4 列 1 行**
///    （[MiResponsiveGrid] 换成网格，密度随宽度增长）；
///  * 通栏卡：手机 4.1:1，宽屏 8:1（高度按比例长，不按像素钉死）。
///
/// 内容量不只是"好看"：磨砂效果需要内容**不断从头部后方经过**才有东西可糊，
/// 页面太短（比如只有一两节）在平板 / 桌面上会直接不可滚。
List<Widget> _homeSections(BuildContext context) {
  final size = MiViewport.of(context).windowSize;
  final promo = switch (size) {
    MiWindowSize.compact => 1.15,
    MiWindowSize.medium => 1.9,
    MiWindowSize.expanded => 2.45,
  };
  // 四卡网格的单元比例：手机两列时维持素材的方卡观感，宽屏一行四张略扁一点。
  final tile = size == MiWindowSize.compact ? 1.15 : 1.45;
  final banner = switch (size) {
    MiWindowSize.compact => 4.1,
    MiWindowSize.medium => 6.0,
    MiWindowSize.expanded => 8.0,
  };
  return [
    const _SectionTitle('背屏创意设计大赛', inset: 8.6),
    _cardRow([
      _GradientCard(
        aspect: promo,
        colors: const [Color(0xFF2E3A8C), Color(0xFF7B4DBE), Color(0xFFD06A8A)],
        caption: '湾区升明月  肆好时光',
      ),
      _GradientCard(
        aspect: promo,
        colors: const [Color(0xFF4A2C6E), Color(0xFFB24592)],
        caption: '分秒皆经典  奢韵不喧哗',
      ),
    ]),
    const _SectionTitle('精选主题', inset: 8.6),
    const _ThemeCardGrid(),
    const _SectionTitle('热门 IP', inset: 8.6),
    _tileGrid(tile, const [
      ([Color(0xFF00B4DB), Color(0xFF0083B0)], '热门IP'),
      ([Color(0xFFFF8177), Color(0xFFB24592)], '插画合集'),
      ([Color(0xFF4568DC), Color(0xFFB06AB3)], '设计师专区'),
      ([Color(0xFF11998E), Color(0xFF38EF7D)], '清新绿意'),
    ]),
    const _SectionTitle('经典表盘', inset: 8.6),
    _tileGrid(tile, const [
      ([Color(0xFF232526), Color(0xFF414345)], '光轴指针'),
      ([Color(0xFF8E7B5A), Color(0xFF3B342A)], '金属律动'),
      ([Color(0xFFFF512F), Color(0xFF242424)], '暖橙日落'),
      ([Color(0xFF2193B0), Color(0xFF6DD5ED)], '海盐汽水'),
    ]),
    const _SectionTitle('更多', inset: 8.6),
    _cardRow([
      _GradientCard(
        aspect: promo,
        colors: const [Color(0xFF396AFC), Color(0xFF2948FF)],
        caption: '极简蓝调',
      ),
      _GradientCard(
        aspect: promo,
        colors: const [Color(0xFFB993D6), Color(0xFF8CA6DB)],
        caption: '莫兰迪',
      ),
    ]),
    const SizedBox(height: 12),
    _GradientCard(
      aspect: banner,
      colors: const [Color(0xFF3E1E68), Color(0xFF8E54E9)],
      caption: '查看全部主题  ›',
    ),
  ];
}

/// 双卡（或多卡）等分一行，间距 12（与卡片网格列距同一档）。
Widget _cardRow(List<Widget> cards) {
  final cells = <Widget>[];
  for (var i = 0; i < cards.length; i++) {
    if (i > 0) cells.add(const SizedBox(width: 12));
    cells.add(Expanded(child: cards[i]));
  }
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: cells);
}

/// 四卡小网格：手机 2 列、平板 / 桌面 4 列；行距 12。
Widget _tileGrid(double aspect, List<(List<Color>, String)> tiles) {
  return MiResponsiveGrid(
    compactColumns: 2,
    mediumColumns: 4,
    expandedColumns: 4,
    compactMax: 520,
    mediumMax: 800,
    itemSpacing: 12,
    runSpacing: 12,
    children: [
      for (final (colors, caption) in tiles)
        _GradientCard(aspect: aspect, colors: colors, caption: caption),
    ],
  );
}

/// 「精选主题」卡片网格（示例层）：预览卡 [MiThemeCard]。
///
/// 列数按**容器可用宽**断点切换（[MiResponsiveGrid]，局部断点 —— 外壳把
/// 画面加宽后才生效；393 设计宽下恒为 3 列，与参考截图一致）：
///  * compact（< 600）→ 3 列；
///  * medium（600…1023）→ 3 列（6 张卡刚好 3+3，不出现 4+2 的缺角）；
///  * expanded（≥ 1024）→ 6 列，且**单元宽上限 210dp**：再宽的画布加列不加宽
///    （[MiResponsiveGrid.maxCellWidth]），避免卡片被拉成 500dp 的巨型海报。
///
/// **卡面比例按断点切换**（`previewAspectRatio`）：
///  * 手机 / 平板竖屏 → 度量值 259:472（竖版海报，与素材一致）；
///  * 桌面（≥ 1024，视口矮、宽） → **16:10 横版**。竖版卡在 1366×768 里
///    一屏只放得下 1.4 行，横版能放 2 行以上，是桌面档信息密度的主要来源。
///
/// 几何对齐参考素材度量：列距取 [MiThemeCardMetrics.columnGap]（11.9，
/// 页边距同值）、行距取 [MiThemeCardMetrics.rowGap]（15）；标题经卡片
/// 自身 8.8dp 内缩与区块标题「精选主题」（11.9 + 8.6 ≈ 20.5）同列起排。
/// 预览图为度量 6 张卡壁纸主色上→下渐变占位（截图采样均值，顺序左→右、
/// 上→下）；标题为示例命名（参考素材卡名字迹不作字面复刻）。
class _ThemeCardGrid extends StatelessWidget {
  const _ThemeCardGrid();

  /// 横版预览的宽高比（**推导值**）：16:10 是桌面卡片缩略图的常见比例，
  /// 与竖版 259:472 的"手机"语义区分开，也不至于扁到看不清渐变。
  static const double landscapeAspect = 16 / 10;

  static const List<List<Color>> _wallpapers = [
    [Color(0xFF6A7A61), Color(0xFF587132)], // 绿林
    [Color(0xFF918D80), Color(0xFF746656)], // 落日
    [Color(0xFFB6B9C4), Color(0xFF8E7377)], // 天空粉
    [Color(0xFF73726E), Color(0xFFCCCCCB)], // 灰调
    [Color(0xFFB9C0CA), Color(0xFFCCCDCD)], // 淡蓝灰
    [Color(0xFF99B3ED), Color(0xFFD3DAE9)], // 晴空蓝
  ];

  static const List<String> _titles = [
    '雾林晨光',
    '落日熔金',
    '云端暮色',
    '灰调都市',
    '极地微光',
    '晴空之旅',
  ];

  @override
  Widget build(BuildContext context) {
    final landscape = MiViewport.of(context).isExpanded;
    return MiResponsiveGrid(
      compactColumns: 3,
      mediumColumns: 3,
      expandedColumns: 6,
      // 内容宽断点（不是窗口断点）：393 设计宽下内容宽 369 → 3 列；
      // 宽舞台加宽后 → 6 列。
      compactMax: 520,
      mediumMax: 800,
      // 单元宽上限：宽屏只加列、不把卡片拉宽。
      // 240 让平板竖屏停在 3 列（736 宽 → 3×237），桌面才跳到 6 列。
      maxCellWidth: 240,
      itemSpacing: MiThemeCardMetrics.columnGap,
      runSpacing: MiThemeCardMetrics.rowGap,
      children: [
        for (var i = 0; i < _titles.length; i++)
          MiThemeCard(
            title: _titles[i],
            previewAspectRatio: landscape
                ? landscapeAspect
                : MiThemeCardMetrics.imageAspectRatio,
            // 悬停快捷操作（桌面）：预览图底部滑出「应用 / 收藏」。
            // 手机档不传（触屏没有悬停语义，操作条永不出现）。
            quickActions: landscape
                ? [
                    MiButton(
                      label: '应用',
                      themeMode: MiThemeMode.dark,
                      onPressed: () => _demoSnack(
                        context,
                        '应用「${_titles[i]}」',
                      ),
                    ),
                    MiButton(
                      label: '收藏',
                      variant: MiButtonVariant.tonal,
                      themeMode: MiThemeMode.dark,
                      onPressed: () => _demoSnack(
                        context,
                        '收藏「${_titles[i]}」',
                      ),
                    ),
                  ]
                : null,
            onTap: () => _demoSnack(context, '打开「${_titles[i]}」'),
            preview: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _wallpapers[i],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 「分类」tab = 组件展示库（示例层）。
///
/// 顶部吸顶头部（搜索框 + 胶囊分类标签行）**由框架组件 [MiTopBar] 内部
/// 产出**：本页只传数据（`searchHint` / `tabs` / `selectedTab` /
/// `onTabChanged`），`MiSearchBar` 与 `MiPillTabBar` 都是顶栏自己构造的；
/// 页边距、两者间距、状态栏让位、以及给滚动内容让位的高度也全部由顶栏算
/// （[MiTopBar.occupiedHeight]），本页不再手算
/// `状态栏 + 搜索框 + 间距 + 胶囊行`。顶部材质也归顶栏：整条头部区（含
/// 搜索栏 / 胶囊行及其间隙）盖在**同一条渐进磨砂**下，零件不再各绘 backdrop。
///
/// 胶囊分类标签是框架组件 [MiPillTabBar]（明暗完整素材度量），用来切分
/// 组件分组；下方网格是各组件的展示位 —— 「Logo 展示」组前 N 位（N =
/// `nav_icons.dart` 全量 logo 数）展示全部真实框架 logo，「按钮展示」组先陈列
/// `MiButton` 按钮本体（关注 / 已关注 / 禁用三态），各组其余铺占位补足
/// 可滚长度，其它分组为示例占位（渐变圆角方块 + 抽象图形 + 「示例组件N」）。
///
/// 吸顶展示：网格上滚时从胶囊后方经过，借胶囊的半透明磨砂直观展示
/// 透明/透射效果。
class _ShowcasePage extends StatefulWidget {
  const _ShowcasePage({required this.themeMode, this.onSearchActiveChanged});

  final MiThemeMode themeMode;
  final ValueChanged<bool>? onSearchActiveChanged;

  @override
  State<_ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<_ShowcasePage> {
  /// 分类胶囊标签（对应截图 推荐/背屏/小部件/主题 的位置）：前两个按
  /// 分组内容命名（Logo 展示 / 按钮展示），后两个仍是占位示例。
  static const List<String> _tabs = ['Logo 展示', '按钮展示', '示例三', '示例四'];

  /// 每个分类下的展示位数量（示例内容）；取足够行数使网格溢出可滚，
  /// 以便演示「滚动内容从吸顶胶囊后方经过」的透明/磨砂透射。
  static const List<int> _counts = [32, 32, 32, 32];

  /// 「Logo 展示」组的 logo 名称（与 [_logos] 顺序一致；`nav_icons.dart`
  /// 全量，含顶栏返回箭头与竖点「更多」）。
  static const List<String> _logoNames = [
    '滚筒刷',
    '网格闪光',
    '卡片星',
    '点阵圆钮',
    '笑脸贝雷',
    '加号',
    '返回箭头',
    '竖点更多',
  ];

  /// 「Logo 展示」组 = `nav_icons.dart` 全量 logo 展示（真实框架 logo，非占位）。
  List<CustomPainter> _logos(Color ink) => [
        RollerIconPainter(ink),
        GridSparkleIconPainter(ink),
        CardsStarIconPainter(ink),
        GridDotsIconPainter(ink),
        SmileyBeretIconPainter(ink),
        PlusIconPainter(ink),
        BackChevronIconPainter(ink),
        MoreVerticalIconPainter(ink),
      ];

  int _tab = 0;

  /// 搜索态（与首页同一套交互，见 `MiTopBar.searchActive`）。
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// 网格滚动控制器：宽屏要给可见滚动条（见 build 里的 `Scrollbar`）。
  final ScrollController _scroll = ScrollController();

  /// 是否正在滚动（驱动顶栏「滚动降 σ」，同首页 [_HomePageState._onScroll]）。
  bool _scrolling = false;
  Timer? _scrollSettle;

  void _onScroll() {
    if (!_scrolling) setState(() => _scrolling = true);
    _scrollSettle?.cancel();
    _scrollSettle = Timer(
      const Duration(milliseconds: 120),
      () {
        if (mounted && _scrolling) setState(() => _scrolling = false);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    // 页面被换掉（切 tab）时若还在搜索态，要让外壳把底栏装回来。
    if (_searching) widget.onSearchActiveChanged?.call(false);
    _scrollSettle?.cancel();
    _scroll.removeListener(_onScroll);
    _searchController.dispose();
    _searchFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _openSearch() {
    if (_searching) return;
    setState(() => _searching = true);
    widget.onSearchActiveChanged?.call(true);
  }

  void _closeSearch() {
    if (!_searching) return;
    _searchFocus.unfocus();
    setState(() => _searching = false);
    widget.onSearchActiveChanged?.call(false);
  }

  /// 展示位：「Logo 展示」组前 [_logoNames.length] 位给真实 logo 全量展示位
  /// （= `nav_icons.dart` 全部 logo），其余铺占位展示位（补足可滚长度）；
  /// 其余分组全给占位展示位。
  Widget _tileAt(int i, bool logoMode, List<CustomPainter> logos) {
    if (logoMode && i < _logoNames.length) {
      return _ShowcaseTile(
        colors: _tileGradients[i % _tileGradients.length],
        glyph: CustomPaint(painter: logos[i], size: const Size.square(26)),
        name: _logoNames[i],
      );
    }
    // 占位下标从头计（「Logo 展示」组的占位跟在全量 logo 之后，命名从一重排）
    final k = logoMode ? i - _logoNames.length : i;
    return _ShowcaseTile(
      colors: _tileGradients[(k + _tab * 2) % _tileGradients.length],
      glyph: Icon(
        _tileIcons[(k + _tab * 2) % _tileIcons.length],
        color: Colors.white,
        size: 26,
      ),
      name: _tileNames[k % _tileNames.length],
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoMode = _tab == 0;
    final logos = logoMode ? _logos(Colors.white) : const <CustomPainter>[];
    final count = _counts[_tab];
    // 页底色与内容边距按完整素材度量：亮 #F3F3F3 / 暗 #000000，
    // 内容左右 37px≈11.9dp（搜索框、标签行、下方内容同边距）；
    // 外壳加宽成内容舞台（wide 档）时页边距收到 32。
    final inset = _pageInset(context, 11.9);
    // 顶部吸顶头部（搜索栏 + 胶囊分类标签）**由 MiTopBar 自己产出**：本页
    // 只给数据（占位文案 / 标签文案 / 选中下标 / 回调），搜索栏与胶囊行都是
    // 顶栏内部构造的框架组件 —— 页边距、两者间距、状态栏让位、给滚动内容
    // 让位的高度也全部由顶栏算（[MiTopBar.occupiedHeight]），本页不再手算
    // `状态栏 + 搜索框 + 间距 + 胶囊行`，也不再 new 这两个组件。
    //
    // 材质**开着**（默认 showSurface: true）：搜索栏与胶囊行既然在顶栏内，
    // 就该共用顶栏那条渐进磨砂 —— 网格从后面滚过时，整条头部区（含两者之间
    // 的间隙与四周）一起被磨砂盖住、越往上越糊，到栏底渐隐；零件自身不再
    // 各绘一层 backdrop（顶栏会把内置组件的 `frosted` 关掉），所以只糊一次。
    final bar = MiTopBar(
      themeMode: widget.themeMode,
      headerInset: inset,
      // 宽屏收敛：同首页（顶部让位 24 / 搜索限宽 520 / 右侧动作区）。
      headerTopInset: _headerTopInset(context),
      searchBarMaxWidth: _wideSearchMaxWidth(context),
      actions: _wideActions(context, () => [
        _TopBarAction(
          themeMode: widget.themeMode,
          icon: CardsStarIconPainter(MiColors.foregroundFor(widget.themeMode)),
          onTap: () => _demoSnack(context, '收藏按钮被点击'),
        ),
      ]),
      searchHint: '搜索主题 / 壁纸 / 图标',
      onSearchTap: _openSearch,
      searchActive: _searching,
      onSearchCancel: _closeSearch,
      searchController: _searchController,
      searchFocusNode: _searchFocus,
      // 滚动降 σ：同首页（滚动中 0.6，停下 120ms 恢复度量材质）。
      sigmaScale: _scrolling ? 0.6 : 1.0,
      tabs: _tabs,
      selectedTab: _tab,
      onTabChanged: (i) => setState(() => _tab = i),
      // 参考截图里分类页**没有**顶上那层压色：整条栏都能看见被模糊的背景，
      // 压色只在大标题形态需要（保证标题可读）。磨砂保留 —— 它是内容区的
      // 顶部渐进模糊，到这里只是顺带复用。
      showSurface: false,
      // 网格上滚后从头部区下方经过（真机截图里第一排色块正压在搜索栏与
      // 胶囊行后方）→ 搜索栏与未选胶囊同样要那层玻璃膜，否则色块直接透上来、
      // 边界只能靠文字认。膜垫在同色页底上等于没垫，静止态观感不变。
      overContent: true,
    );
    return _keyboardScope(
      context,
      // 桌面：⌘/Ctrl + K 进入原地搜索态；Esc 退出（仅搜索态时接管，
      // 平时交给系统 —— 如退出全屏 / 关窗口）。
      onFocusSearch: _openSearch,
      onEscape: _searching ? _closeSearch : null,
      child: Container(
        color: MiColors.pageBackgroundFor(widget.themeMode),
        child: Stack(
        children: [
          // 滚动网格：初始让出顶栏高度 + 胶囊行底 → 内容的度量间距 12dp；
          // 上滚后内容从胶囊行后方经过，胶囊的半透明磨砂把透上来的网格
          // 磨出毛玻璃感。
          Positioned.fill(
            key: const ValueKey('showcaseList'),
            child: Scrollbar(
              controller: _scroll,
              thumbVisibility: !MiViewport.of(context).isCompact,
              child: ListView(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(
                  inset,
                  bar.occupiedHeight(context) + MiTopBarMetrics.headerContentGap,
                  inset,
                  0,
                ),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 分组头：「按钮展示」组先陈列按钮本体，占位网格另起一节；
                    // 其余组单节（Logo 组 / 占位组）。
                    if (_tab == 1) ...[
                      _ButtonShowcase(themeMode: widget.themeMode),
                      const _SectionTitle('组件展示'),
                    ] else
                      _SectionTitle(logoMode ? 'Logo 展示' : '组件展示'),
                    // 展示位网格：列数按容器宽断点切换（4 / 6 / 8），
                    // 行距 18 沿用原「每行 bottom: 18」的节奏。
                    MiResponsiveGrid(
                      compactColumns: 4,
                      mediumColumns: 6,
                      expandedColumns: 8,
                      // 内容宽断点（同主题卡网格）：369 → 4 列、776 → 6 列、
                      // 舞台 952 → 8 列。
                      compactMax: 520,
                      mediumMax: 800,
                      itemSpacing: 12,
                      runSpacing: 18,
                      children: [
                        for (var i = 0; i < count; i++)
                          _tileAt(i, logoMode, logos),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
              ),
            ),
          ),
          // 搜索态：内容让位给输入（与首页同款；Stack 子级必须带 key，见首页注释）。
          if (_searching)
            Positioned.fill(
              key: const ValueKey('showcaseSearchCover'),
              child: ColoredBox(
                color: MiColors.pageBackgroundFor(widget.themeMode),
              ),
            ),
          // 吸顶头部：搜索框 + 胶囊分类标签悬浮在滚动内容之上
          //（标签行吸附搜索框下方，网格从胶囊后方滚过）。
          Positioned(
            key: const ValueKey('showcaseTopBar'),
            left: 0,
            right: 0,
            top: 0,
            child: bar,
          ),
        ],
        ),
      ),
    );
  }
}

/// 「按钮展示」分组内容（示例层）：复刻「我的关注」页的关注按钮本体。
///
/// 参考素材 = 亮/暗两张完整截图（1220x2656）度量：按钮 59.9×28.3dp stadium、
/// 填充 #4980F7 明暗同色、标签 13dp Medium 白字；行节奏沿用度量行距
/// 56.1dp。三行分别是主按钮（点按在 关注 ↔ 已关注 间切换）、次级态、
/// 禁用态；按钮直接陈列在分组页底上（亮 #F3F3F3 / 暗 #000000），
/// 与参考素材同底对照。
class _ButtonShowcase extends StatefulWidget {
  const _ButtonShowcase({required this.themeMode});

  final MiThemeMode themeMode;

  @override
  State<_ButtonShowcase> createState() => _ButtonShowcaseState();
}

class _ButtonShowcaseState extends State<_ButtonShowcase> {
  /// 关注态（demo 交互：点按主按钮切换 关注 ↔ 已关注）。
  bool _followed = false;

  /// 说明文字的次级墨色（随 Material 页明暗）。
  TextStyle _subStyle(BuildContext context, double size) {
    final sub =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    return TextStyle(fontSize: size, height: 1.5, color: sub);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('按钮展示'),
        _specRow(
          context,
          caption: '主按钮 · 点按切换关注态',
          button: MiButton(
            label: _followed ? '已关注' : '关注',
            variant: _followed ? MiButtonVariant.tonal : MiButtonVariant.filled,
            themeMode: widget.themeMode,
            onPressed: () => setState(() => _followed = !_followed),
          ),
        ),
        _specRow(
          context,
          caption: '次级 · 已关注态（推导样式）',
          button: MiButton(
            label: '已关注',
            variant: MiButtonVariant.tonal,
            themeMode: widget.themeMode,
            onPressed: () {},
          ),
        ),
        _specRow(
          context,
          caption: '禁用态 · onPressed = null',
          button: MiButton(
            label: '关注',
            themeMode: widget.themeMode,
            onPressed: null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '规格（设计度量 1220×2656 素材）：59.9×28.3dp stadium · '
            '填充 #4980F7 明暗同色 · 标签 13dp/500 · 左右内边距 17dp',
            style: _subStyle(context, 11),
          ),
        ),
      ],
    );
  }

  /// 规格行：左说明、右按钮（参考页按钮靠右陈列），行高沿用度量行距。
  Widget _specRow(
    BuildContext context, {
    required String caption,
    required Widget button,
  }) {
    return SizedBox(
      height: MiButtonMetrics.listRowPitch,
      child: Row(
        children: [
          Expanded(
            child: Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _subStyle(context, 12.5),
            ),
          ),
          const SizedBox(width: MiDimens.spaceMd),
          button,
        ],
      ),
    );
  }
}

/// 组件展示位：渐变底 + 墨迹图形 + 名称（logo / 占位共用）。
class _ShowcaseTile extends StatelessWidget {
  const _ShowcaseTile({
    required this.colors,
    required this.glyph,
    required this.name,
  });

  final List<Color> colors;
  final Widget glyph;
  final String name;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: glyph,
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: fg),
        ),
      ],
    );
  }
}

/// 展示位渐变底（「Logo 展示」组配真实 logo，其余分组配抽象占位图形）。
const List<List<Color>> _tileGradients = [
  [Color(0xFF396AFC), Color(0xFF2948FF)],
  [Color(0xFF00B4DB), Color(0xFF0083B0)],
  [Color(0xFF11998E), Color(0xFF38EF7D)],
  [Color(0xFFFC5C7D), Color(0xFF6A82FB)],
  [Color(0xFFB993D6), Color(0xFF8CA6DB)],
  [Color(0xFFFF512F), Color(0xFFDD2476)],
  [Color(0xFFF2994A), Color(0xFFF2C94C)],
  [Color(0xFF606C88), Color(0xFF3F4C6B)],
];

const List<IconData> _tileIcons = [
  Icons.blur_on,
  Icons.change_history,
  Icons.filter_vintage,
  Icons.grain,
  Icons.star_border,
  Icons.whatshot,
  Icons.wb_sunny,
  Icons.bubble_chart,
];

/// 示例分类名称（占位内容）。
const List<String> _tileNames = [
  '示例组件一',
  '示例组件二',
  '示例组件三',
  '示例组件四',
  '示例组件五',
  '示例组件六',
  '示例组件七',
  '示例组件八',
];

const List<Widget> _mineItems = [
  _GradientCard(
    height: 120,
    colors: [Color(0xFF232526), Color(0xFF414345)],
    caption: 'LJ_li   已绑定小米账号',
  ),
  _SectionTitle('模块混搭'),
  Row(children: [
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFF5F2C82), Color(0xFF49A09D)], caption: '主题')),
    SizedBox(width: 10),
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFF134E5E), Color(0xFF71B280)], caption: '壁纸')),
    SizedBox(width: 10),
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFFB24592), Color(0xFFF15F79)], caption: '字体')),
    SizedBox(width: 10),
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFF396AFC), Color(0xFF2948FF)], caption: '息屏')),
  ]),
  _SectionTitle('我的服务'),
  _GradientCard(height: 56, colors: [Color(0xFF1F1F22), Color(0xFF2A2A2E)], caption: '我的关注 / 我的点赞 / 我的收藏 / 我的订单'),
  SizedBox(height: 12),
  _GradientCard(height: 56, colors: [Color(0xFF1F1F22), Color(0xFF2A2A2E)], caption: '主题圈子 / 混搭搭配'),
  SizedBox(height: 12),
  _GradientCard(height: 56, colors: [Color(0xFF1F1F22), Color(0xFF2A2A2E)], caption: '设置 / 关于'),
  SizedBox(height: 12),
  _SectionTitle('我的作品'),
  Row(children: [
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)], caption: '混搭')),
    SizedBox(width: 10),
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFFED213A), Color(0xFF93291E)], caption: '收藏')),
    SizedBox(width: 10),
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFFF2994A), Color(0xFFF2C94C)], caption: '下载')),
    SizedBox(width: 10),
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFF606C88), Color(0xFF3F4C6B)], caption: '投稿')),
  ]),
  SizedBox(height: 12),
  _GradientCard(height: 90, colors: [Color(0xFF0F3443), Color(0xFF34E89E)], caption: '会员中心 / 客服与反馈  ›'),
];

/// 搜索页（示例层）：首页点搜索栏后由 [MiCardPageRoute] 推入。
///
/// 头部几何为**度量值**（参考素材 1220×2656，s = 1220 / 393 = 3.104 px/dp）：
///
/// | 项目                 | 素材 px        | dp          |
/// |----------------------|----------------|-------------|
/// | 头部行顶缘           | 162            | 52.2        |
/// | 返回圆钮             | ⌀137 / 左 38   | ⌀44.1 / 11.9 |
/// | 圆钮 ↔ 输入框        | 34             | 11.0        |
/// | 输入框               | 777 × 137      | 250.3 × 44.1（弹性占满） |
/// | 输入框 ↔ 搜索钮      | 34             | 11.0        |
/// | 搜索钮               | 166 × 127      | 53.5 × 40.9 |
/// | 搜索钮右缘距屏幕右缘 | 39             | 12.6 ≈ 11.9 |
///
/// 三数闭合校验：11.9 + 44.1 + 11.0 + 250.3 + 11.0 + 53.5 + 11.9 = 393.7
/// ≈ 屏宽 393（±0.7dp，AA 与取整）。
///
/// 头部顶缘取 `max(52.2, 安全区 + 12)`：52.2 是素材的绝对值，叠加安全区
/// 是**推导**（素材状态栏约 40dp，头部在其下 ~12dp），保证真机不被状态栏压住。
///
/// 正文是示例内容（主题卡网格），与参考素材的「热搜榜单」无关：搜索结果的
/// 排版属于宿主 App，本示例只演示**推入转场 + 头部交互**。
class DemoSearchPage extends StatefulWidget {
  const DemoSearchPage({
    super.key,
    this.themeMode = MiThemeMode.dark,
    this.hint = '搜索主题 / 壁纸 / 图标',
  });

  final MiThemeMode themeMode;
  final String hint;

  @override
  State<DemoSearchPage> createState() => _DemoSearchPageState();
}

class _DemoSearchPageState extends State<DemoSearchPage> {
  // ── 头部几何（度量，见类文档）──
  static const double _headerTop = 52.2;
  static const double _headerInset = 11.9;
  static const double _controlGap = 11.0;
  static const double _actionWidth = 53.5;
  static const double _actionHeight = 40.9;
  static const double _controlHeight = MiSearchBarMetrics.barHeight;
  static const double _fieldTextInset = 12.6;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // 进页即聚焦（参考素材：推入过程中键盘已经在弹）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.themeMode;
    final palette = MiSearchBarPalette.of(mode);
    final ink = MiColors.foregroundFor(mode);
    final safeTop = MediaQuery.paddingOf(context).top;
    final headerTop = math.max(_headerTop, safeTop + 12);
    final inset = _pageInset(context, _headerInset);

    return Scaffold(
      backgroundColor: MiColors.pageBackgroundFor(mode),
      body: _keyboardScope(
        context,
        // 桌面：Esc = 返回（同头部返回圆钮）；⌘/Ctrl + K = 重新聚焦输入框
        //（焦点在别处时的快捷回归）。
        onFocusSearch: () => _focus.requestFocus(),
        onEscape: () {
          if (mounted) Navigator.of(context).maybePop();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(inset, headerTop, inset, 0),
              child: SizedBox(
                height: _controlHeight,
                child: Row(
                  children: [
                    _BackCircle(
                      key: const ValueKey('searchBack'),
                      ink: ink,
                      palette: palette,
                    ),
                    const SizedBox(width: _controlGap),
                    Expanded(child: _field(palette)),
                    const SizedBox(width: _controlGap),
                    _searchAction(ink: ink, palette: palette),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(inset, MiDimens.spaceXl, inset, 20),
                children: const [
                  _SectionTitle('精选主题', inset: 8.6),
                  _ThemeCardGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 输入框：stadium + 半透明表面填充（与静态搜索栏同一档填充色）。
  ///
  /// 参考素材这一页的输入框**没有放大镜**、占位左缩进 12.6dp —— 与首页那条
  /// 搜索栏（放大镜 + 15.4dp 缩进）不是同一个零件，故此处不复用
  /// [MiSearchBar]，只共用配色 token。
  Widget _field(MiSearchBarPalette palette) {
    return DecoratedBox(
      key: const ValueKey('searchField'),
      decoration: BoxDecoration(
        color: palette.fill,
        borderRadius: BorderRadius.circular(_controlHeight / 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _fieldTextInset),
        child: Center(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            style: MiTypography.searchHint.copyWith(color: palette.cancelInk),
            cursorColor: palette.caret,
            cursorHeight: MiSearchBarMetrics.caretHeight,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration.collapsed(
              hintText: widget.hint,
              hintStyle:
                  MiTypography.searchHint.copyWith(color: palette.hint),
            ),
          ),
        ),
      ),
    );
  }

  /// 搜索钮：度量 53.5×40.9 的浅灰圆角块 + 纯前景墨色标签。
  Widget _searchAction({required Color ink, required MiSearchBarPalette palette}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        width: _actionWidth,
        height: _actionHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.fill,
          borderRadius: BorderRadius.circular(_actionHeight / 2),
        ),
        child: Text(
          '搜索',
          style: MiTypography.searchHint.copyWith(
            color: ink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 返回圆钮（示例层）：⌀44.1 圆盘 + 顶栏同一枚箭头墨迹。
class _BackCircle extends StatelessWidget {
  const _BackCircle({super.key, required this.ink, required this.palette});

  final Color ink;
  final MiSearchBarPalette palette;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: MiSearchBarMetrics.barHeight,
        height: MiSearchBarMetrics.barHeight,
        decoration: BoxDecoration(
          color: palette.fill,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Transform.translate(
            // 箭头墨心左偏一档（顶栏回退钮同一套光学偏置，度量）
            offset: const Offset(MiTopBarMetrics.chevronCenterDx, 0),
            child: CustomPaint(
              painter: BackChevronIconPainter(palette.cancelInk),
              size: const Size(
                MiTopBarMetrics.chevronWidth,
                MiTopBarMetrics.chevronHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
