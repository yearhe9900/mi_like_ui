part of '../mock_pages.dart';


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
        // 上，横幅与下方区块一起从头部后方滚过 —— 头部区那层渐进磨砂（平台
        // 段最糊、向下衰减、胶囊行底羽化收尾）在这一页才看得见（见 [_HomePage]）。
        // 点搜索栏由本页自己推入搜索页，不需要外壳配合。
        return _HomePage(themeMode: themeMode);
      case 1:
        // 「分类」tab = 组件展示库：胶囊分类标签切分组，网格是展示位
        return _ShowcasePage(
          themeMode: themeMode,
          onSearchActiveChanged: onSearchActiveChanged,
          // 弹层演示入口（「弹层与效果」组）：与「我的」页共用外壳的
          // 浮层挂载点 —— 弹框画在机身壳**内**（PC 套壳演示里不会盖住整窗）。
          onShowDialog: onShowDialog,
          onShowListDialog: onShowListDialog,
        );
      default:
        // 设置页风格（参考素材：系统设置页明暗截图）：顶层页形态
        // （showBack: false），首行搜索栏 → 内容顶缘 168.5dp（度量
        // `searchBarTopInset`），卡片页边距 11.9dp，分组卡片 + 整行按压。
        final inset = _pageInset(context, 11.9);
        return _MockPageShell(
          title: '我的',
          showBack: false,
          padding: EdgeInsets.fromLTRB(
            inset,
            MiTopBarMetrics.searchBarTopInset,
            inset,
            20,
          ),
          children: [
            // 搜索栏（静态展示；平底页不开磨砂，填充仍是度量合成色）
            MiSearchBar(
              hint: '搜索系统设置项',
              themeMode: themeMode,
              frosted: false,
            ),
            const SizedBox(height: 16),
            // 外观模式（demo 功能行：右侧开关，无 chevron）
            if (onThemeModeChanged != null) ...[
              MiSettingsCard(children: [
                MiSettingsRow(
                  label: '外观模式',
                  value: themeMode == MiThemeMode.light ? '浅色' : '深色',
                  leading: const MiSettingsTile(Icons.light_mode_outlined, Color(0xFF7A5CFA)),
                  chevron: false,
                  trailing: MiSwitch(
                    value: themeMode != MiThemeMode.light,
                    themeMode: themeMode,
                    onChanged: (v) => onThemeModeChanged!(
                      v ? MiThemeMode.dark : MiThemeMode.light,
                    ),
                  ),
                  onTap: () => onThemeModeChanged!(
                    themeMode == MiThemeMode.light
                        ? MiThemeMode.dark
                        : MiThemeMode.light,
                  ),
                ),
              ]),
              const SizedBox(height: 14),
            ],
            // 弹框演示（demo 功能行）
            if (onShowDialog != null) ...[
              MiSettingsCard(children: [
                MiSettingsRow(
                  label: '底部弹框（默认）',
                  leading: const MiSettingsTile(Icons.arrow_downward_rounded, Color(0xFF2F9BFF)),
                  onTap: () => onShowDialog!(MiDialogPosition.bottom),
                ),
                MiSettingsRow(
                  label: '顶部弹框',
                  leading: const MiSettingsTile(Icons.arrow_upward_rounded, Color(0xFF34C759)),
                  onTap: () => onShowDialog!(MiDialogPosition.top),
                ),
                MiSettingsRow(
                  label: '居中弹框',
                  leading: const MiSettingsTile(Icons.crop_square_rounded, Color(0xFFFF9500)),
                  onTap: () => onShowDialog!(MiDialogPosition.center),
                ),
                // 纵向操作列表形态（issue #1）：两行左对齐标题 + 图标 /
                // 副标题 / 危险项红字（几何全为推导值）。
                if (onShowListDialog != null)
                  MiSettingsRow(
                    label: '操作列表弹框（纵向）',
                    leading: const MiSettingsTile(Icons.view_agenda_outlined, Color(0xFF7A5CFA)),
                    onTap: onShowListDialog,
                  ),
              ]),
              const SizedBox(height: 14),
            ],
            // 账号卡（参考素材：头像 + 名称 + 副标题）
            MiSettingsCard(children: [
              MiSettingsRow(
                label: 'LJ_li',
                subtitle: '账号、云服务、会员权益等',
                leading: const _SettingsAvatar(),
                onTap: () => _mockTap(context, '账号中心'),
              ),
              MiSettingsRow(
                label: '我的设备',
                leading: const MiSettingsTile(Icons.smartphone, Color(0xFF8E8E93)),
                onTap: () => _mockTap(context, '我的设备'),
              ),
              MiSettingsRow(
                label: '妙享背屏',
                leading: const MiSettingsTile(Icons.picture_in_picture_alt, Color(0xFF7A5CFA)),
                onTap: () => _mockTap(context, '妙享背屏'),
              ),
            ]),
            const SizedBox(height: 14),
            // 网络卡（参考素材：右侧状态文案 + chevron）
            MiSettingsCard(children: [
              MiSettingsRow(
                label: 'WLAN',
                value: '已开启',
                leading: const MiSettingsTile(Icons.wifi, Color(0xFF2F9BFF)),
                onTap: () => _mockTap(context, 'WLAN'),
              ),
              MiSettingsRow(
                label: '蓝牙',
                value: '已开启',
                leading: const MiSettingsTile(Icons.bluetooth, Color(0xFF2F9BFF)),
                onTap: () => _mockTap(context, '蓝牙'),
              ),
              MiSettingsRow(
                label: '移动网络',
                leading: const MiSettingsTile(Icons.signal_cellular_alt, Color(0xFF34C759)),
                onTap: () => _mockTap(context, '移动网络'),
              ),
              MiSettingsRow(
                label: '设备互联',
                leading: const MiSettingsTile(Icons.devices_other, Color(0xFF5AC8FA)),
                onTap: () => _mockTap(context, '设备互联'),
              ),
              MiSettingsRow(
                label: '个人热点',
                value: '已关闭',
                leading: const MiSettingsTile(Icons.wifi_tethering, Color(0xFF2F9BFF)),
                onTap: () => _mockTap(context, '个人热点'),
              ),
              MiSettingsRow(
                label: 'VPN',
                leading: const MiSettingsTile(Icons.public, Color(0xFF0A84FF)),
                onTap: () => _mockTap(context, 'VPN'),
              ),
            ]),
            const SizedBox(height: 20),
          ],
        );
    }
  }
}



/// 设置页风格头像（demo 层）：圆形底 + 笑脸贝雷 logo（复用框架 painter）。
class _SettingsAvatar extends StatelessWidget {
  const _SettingsAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MiSettingsMetrics.tileSide,
      height: MiSettingsMetrics.tileSide,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C565F), Color(0xFF23272B)],
        ),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        painter: SmileyBeretIconPainter(Colors.white),
        size: const Size.square(24),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    // 宽屏显式给滚动条：滚轮是隐式的，没有可见刻度就丢掉了「还有多少」。
    // 手机档（触屏）不显示，避免压住内容边缘。
    final showScrollbar = !MiViewport.of(context).isCompact;
    return ColoredBox(
      color: light ? const Color(0xFFF3F3F3) : const Color(0xFF000000),
      // 滚动接线：顶栏折叠位移由作用域自动供给（不再手写 ValueNotifier +
      // listener 样板）；Scrollbar 仍自持 controller。
      child: MiScrollBinder(
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
              child: MiTopBar(
                title: widget.title,
                showBack: widget.showBack,
                // scrollOffset 不传：从 MiScrollBinder 作用域自动读取。
                // 只有 showBack 为 true 时圆钮才存在，回调此时才可能被触发
                onBack: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('返回圆钮被点击'),
                    duration: Duration(milliseconds: 800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
