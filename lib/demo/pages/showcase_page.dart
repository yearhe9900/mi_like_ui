part of '../mock_pages.dart';


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
/// 组件分组。四组都是**真实组件陈列**（不再有「示例组件N」占位组）：
///
/// | 组 | 内容 |
/// |----|------|
/// | Logo 展示 | `nav_icons.dart` 全量 logo + 占位展示位（补可滚长度） |
/// | 按钮展示 | `MiButton` 三态（关注 / 已关注 / 禁用）+ 占位展示位 |
/// | 组件展示 | 搜索栏两态 + 取消钮、设置行、开关、复选框、悬浮工具栏、桌面三态反馈、响应式网格、菜单 |
/// | 弹层与效果 | 弹框（声明式 + 命令式 `showMiDialog`）、弹出面板、底部弹窗、渐进模糊 |
///
/// 占位展示位只出现在前两组（它们要靠网格长度演示「滚动内容从吸顶胶囊
/// 后方经过」）；后两组内容本身足够长。
///
/// 吸顶展示：网格上滚时从胶囊后方经过，借胶囊的半透明磨砂直观展示
/// 透明/透射效果。
class _ShowcasePage extends StatefulWidget {
  const _ShowcasePage({
    required this.themeMode,
    this.onSearchActiveChanged,
    this.onShowDialog,
    this.onShowListDialog,
  });

  final MiThemeMode themeMode;
  final ValueChanged<bool>? onSearchActiveChanged;

  /// 弹框演示入口（demo 功能）：由外壳挂浮层（机身壳内），语义同 [MockPage]。
  final ValueChanged<MiDialogPosition>? onShowDialog;

  /// 操作列表弹框入口（demo 功能），语义同 [MockPage]。
  final VoidCallback? onShowListDialog;

  @override
  State<_ShowcasePage> createState() => _ShowcasePageState();
}


class _ShowcasePageState extends State<_ShowcasePage> {
  /// 分类胶囊标签（对应参考截图 推荐 / 背屏 / 小部件 / 主题 的位置）：
  /// 四组都是真实组件陈列（前两组另有占位展示位补可滚长度）。
  static const List<String> _tabs = [
    'Logo 展示',
    '按钮展示',
    '组件展示',
    '弹层与效果',
  ];

  /// 前两组占位展示位数量（示例内容）：取足够行数使网格溢出可滚，
  /// 以便演示「滚动内容从吸顶胶囊后方经过」的透明 / 磨砂透射。
  /// 后两组（组件展示 / 弹层与效果）内容本身可滚，不用占位。
  static const List<int> _counts = [32, 32, 0, 0];

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
    '前进箭头',
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
        ForwardChevronIconPainter(ink),
        MoreVerticalIconPainter(ink),
      ];

  int _tab = 0;

  /// 弹出面板演示（「弹层与效果」组，从组内按钮弹起）：`_panel` = 面板挂载
  /// （含收回动画进行中）；点面板外或经控制器收回，收口后卸载。
  bool _panel = false;
  final _panelController = MiPullUpPanelController();

  /// 面板触发按钮（面板唤起锚点：它的圆心即缩放原点）。
  final GlobalKey _panelTriggerKey = GlobalKey();

  /// 触发按钮圆心（全局坐标，面板唤起锚点）。
  Offset? get _panelAnchor {
    final box = _panelTriggerKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize) {
      return box.localToGlobal(box.size.center(Offset.zero));
    }
    return null;
  }

  /// 搜索态（与首页同一套交互，见 `MiTopBar.searchActive`）。
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// 网格滚动控制器：宽屏要给可见滚动条（见 build 里的 `Scrollbar`）。
  final ScrollController _scroll = ScrollController();

  /// 「滚动降 σ」实时驱动器（同首页 [_ScrollSigma]）。
  final _ScrollSigma _sigma = _ScrollSigma();

  @override
  void initState() {
    super.initState();
    _sigma.attach(_scroll);
  }

  @override
  void dispose() {
    // 页面被换掉（切 tab）时若还在搜索态，要让外壳把底栏装回来。
    if (_searching) widget.onSearchActiveChanged?.call(false);
    _sigma.dispose();
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

  /// 分组内容（四组均为真实组件陈列，见类文档的分组表）。
  ///
  /// 前两组带占位展示位网格（补可滚长度，吸顶磨砂要有内容从后方经过）；
  /// 后两组内容本身可滚。
  List<Widget> _tabBody({
    required bool logoMode,
    required List<CustomPainter> logos,
    required int count,
  }) {
    switch (_tab) {
      case 0:
        return [
          const _SectionTitle('Logo 展示'),
          _logoGrid(logoMode: logoMode, logos: logos, count: count),
          const SizedBox(height: 20),
        ];
      case 1:
        return [
          _ButtonShowcase(themeMode: widget.themeMode),
          const _SectionTitle('展示位'),
          _logoGrid(logoMode: logoMode, logos: logos, count: count),
          const SizedBox(height: 20),
        ];
      case 2:
        return [
          _ComponentShowcase(themeMode: widget.themeMode),
          const SizedBox(height: 20),
        ];
      default:
        return [
          _LayerShowcase(
            themeMode: widget.themeMode,
            onShowDialog: widget.onShowDialog,
            onShowListDialog: widget.onShowListDialog,
            panelTriggerKey: _panelTriggerKey,
            // 面板已在挂载中（收回动画未收口）时不再重复唤起。
            onShowPanel: () {
              if (_panel) return;
              HapticFeedback.lightImpact();
              setState(() => _panel = true);
            },
          ),
          const SizedBox(height: 20),
        ];
    }
  }

  /// 列表底部让位：手机 / 窄窗有**浮动底栏**（栏体浮起 24.2 + 栏高 55.4，
  /// ≈ 80），末节要能滚出栏外 → 100；宽屏导航是侧栏、不占底部 → 20。
  double _listBottomInset(BuildContext context) =>
      MiViewport.of(context).isCompact ? 100 : 20;

  /// 占位展示位网格（Logo 组 / 按钮组补可滚长度）：列数按容器宽断点
  /// 切换（4 / 6 / 8），行距 18 沿用原「每行 bottom: 18」的节奏。
  Widget _logoGrid({
    required bool logoMode,
    required List<CustomPainter> logos,
    required int count,
  }) =>
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
          for (var i = 0; i < count; i++) _tileAt(i, logoMode, logos),
        ],
      );

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
    // 的间隙与四周）一起被磨砂盖住、越往上越糊，到栏底渐隐；零件自身另有
    // 一层玻璃磨砂（自己的「透明模糊属性」+ 内缘亮边），与背景磨砂叠加。
    // σ 缩放随滚动速度实时渐变（[_ScrollSigma]），只重建顶栏子树。
    MiTopBar makeBar(double sigmaScale) => MiTopBar(
      themeMode: widget.themeMode,
      headerInset: inset,
      // 宽屏收敛：同首页（顶部让位 24 / 搜索限宽 520 / 右侧动作区）。
      headerTopInset: _headerTopInset(context),
      searchBarMaxWidth: _wideSearchMaxWidth(context),
      actions: _wideActions(context, () => [
        _TopBarAction(
          themeMode: widget.themeMode,
          icon: CardsStarIconPainter(MiColors.foregroundFor(widget.themeMode)),
          onTap: () => _demoSnack(
            context,
            '已添加到收藏',
            actionLabel: '撤销',
            onAction: () => _demoSnack(context, '已撤销'),
          ),
        ),
      ]),
      searchHint: '搜索主题 / 壁纸 / 图标',
      onSearchTap: _openSearch,
      searchActive: _searching,
      onSearchCancel: _closeSearch,
      searchController: _searchController,
      searchFocusNode: _searchFocus,
      // 滚动降 σ：随速度实时渐变（0.6…1.0，同首页 _ScrollSigma）。
      sigmaScale: sigmaScale,
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
      // 滚动偏移驱动内缘亮边的渐亮（rimProgress，见 MiTopBarMetrics）。
      scrollOffset: _scroll.hasClients ? _scroll.offset : 0,
    );
    final bar = ValueListenableBuilder<double>(
      valueListenable: _sigma,
      builder: (context, sigmaScale, _) => makeBar(sigmaScale),
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
                  makeBar(1.0).occupiedHeight(context) +
                      MiTopBarMetrics.headerContentGap,
                  inset,
                  // 底部让开浮动底栏：栏浮在内容之上（内容从栏后滚过），
                  // 滚到底时末节不能压在玻璃栏下 —— 「弹层与效果」组的
                  // 面板触发行就在列表末尾。
                  _listBottomInset(context),
                ),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 分组内容由 [_tabBody] 按胶囊下标给出。
                    ..._tabBody(
                      logoMode: logoMode,
                      logos: logos,
                      count: count,
                    ),
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
          // 弹出面板（「弹层与效果」组的触发按钮唤起）：插在吸顶头部之下
          // 绘制（面板贴底部、与头部区不重叠）；子级带 key —— 增删时按 key
          // 配对，后面的顶栏子树不重建。
          if (_panel)
            Positioned.fill(
              key: const ValueKey('showcasePanelOverlay'),
              child: MiPullUpPanel(
                // 自定义长高：演示传固定 240（null = 内容自适应）。
                height: 240,
                anchorPoint: _panelAnchor,
                themeMode: widget.themeMode,
                controller: _panelController,
                onDismissed: () => setState(() => _panel = false),
                child: _PanelDemoContent(themeMode: widget.themeMode),
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
        _specRow(
          context,
          caption: '大号档 · 高 40（参考实现值）',
          button: MiButton(
            label: '开始',
            size: MiButtonSize.large,
            themeMode: widget.themeMode,
            onPressed: () {},
          ),
        ),
        _specRow(
          context,
          caption: '前置图标 · 16dp 定尺',
          button: MiButton(
            label: '下载',
            icon: const Icon(Icons.download_rounded),
            themeMode: widget.themeMode,
            onPressed: () {},
          ),
        ),
        _specRow(
          context,
          caption: '文本形态 · 无填充 + 强调色标签',
          button: MiButton(
            label: '取消',
            variant: MiButtonVariant.text,
            themeMode: widget.themeMode,
            onPressed: () {},
          ),
        ),
        _specRow(
          context,
          caption: '最小宽 120 · minWidth',
          button: MiButton(
            label: '确定',
            minWidth: 120,
            themeMode: widget.themeMode,
            onPressed: () {},
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '规格（设计度量 1220×2656 素材）：59.9×28.3dp stadium · '
            '填充 #4980F7 明暗同色 · 标签 13dp/500 · 左右内边距 17dp；'
            '大号 / 图标 / 最小宽为参考实现值或推导值',
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


/// 展示底座（示例层）：圆角中性面 + 下方说明文字 —— 「组件展示」组的
/// 陈列容器（设置行 / 弹框这类自带卡片的组件直接用 [MiSettingsCard]，
/// 不再套一层底）。
///
/// 底色是**演示层中性面**（不是库组件 token）：只是给组件一块干净的
/// 陈列底；组件自带的表面（搜索栏填充 / 焦点环 …）仍在其上自绘，
/// 正好能看出「组件材质」与「页面底」的叠压关系。
class _DemoSurface extends StatelessWidget {
  const _DemoSurface({
    required this.themeMode,
    required this.caption,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final MiThemeMode themeMode;
  final String caption;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final light = themeMode == MiThemeMode.light;
    final fg = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: light ? Colors.white : const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
        const SizedBox(height: 8),
        Text(
          caption,
          style: TextStyle(
            fontSize: 11,
            height: 1.5,
            color: fg.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}


/// 「组件展示」分组（示例层）：库组件的**可交互**陈列。
///
/// 九小节各演示一处 API 面：
///  * 搜索栏 —— 静态展示态（`onTap`）与输入态（`editable: true`）同列，
///    取消钮随输入态以 `fade` 0 → 1 淡入（alpha 乘进填充与叉号墨色，
///    **不套 Opacity**：圆钮内含 backdrop 磨砂，saveLayer 会让它变空）；
///  * 设置行 —— 值文 + chevron / 开关尾部 / 副标题三种尾部形态；
///  * 开关 —— 开 / 关 / 禁用三态（点按或左右拖拽切换）；
///  * 复选框 —— 开 / 关 / 半选 / 禁用四态；
///  * 滑条 —— 连续 + 关键点 / 分档刻度 / 反向 / 禁用四态（[MiSlider]）；
///  * 悬浮工具栏 —— 胶囊托盘容器（投影按形状绘制）；
///  * 桌面三态反馈 —— 按压 / 悬停 / 键盘焦点环（触屏素材没有样张，
///    按桌面惯例推导的那层）；
///  * 响应式网格 —— 列数随容器宽 4 / 6 / 8 切换；
///  * 菜单 —— `MiMenu` 三种锚点形态：单选偏好行、级联子菜单、图标触发的
///    多分组动作菜单（[_MenuShowcase]）。
///
/// 全部是真实组件，不再是「示例组件N」渐变占位。
class _ComponentShowcase extends StatefulWidget {
  const _ComponentShowcase({required this.themeMode});

  final MiThemeMode themeMode;

  @override
  State<_ComponentShowcase> createState() => _ComponentShowcaseState();
}


class _ComponentShowcaseState extends State<_ComponentShowcase> {
  final TextEditingController _query = TextEditingController();
  final FocusNode _queryFocus = FocusNode();
  final FocusNode _ringFocus = FocusNode();

  /// 输入态（聚焦或有输入）：取消钮才可见 —— 与顶栏搜索态同一契约。
  bool _focused = false;
  String _text = '';

  /// 开关行（设置行尾部开关的演示态）。
  bool _wifi = true;

  /// 开关陈列（开 / 关两态各一，第三行禁用）。
  bool _switchOn = true;
  bool _switchOff = false;

  /// 复选三态（开 / 关 / 半选）与一条禁用行。
  bool _checkOn = true;
  bool _checkOff = false;
  bool? _checkMixed;

  /// 滑条演示态：连续 / 分档（0…4 五档）/ 反向。
  double _sliderValue = 0.35;
  double _sliderStepped = 2;
  double _sliderReversed = 0.5;

  /// 按压计数（三态反馈演示的点按反馈）。
  int _presses = 0;

  @override
  void initState() {
    super.initState();
    _queryFocus.addListener(() {
      if (mounted) setState(() => _focused = _queryFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _queryFocus.dispose();
    _ringFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.themeMode;
    final light = mode == MiThemeMode.light;
    final ink = MiColors.foregroundFor(mode);
    final searching = _focused || _text.isNotEmpty;
    // 陈列面（chip 底）：白面上浅一档 / 黑面上深一档。
    final chipColor =
        light ? const Color(0xFFF2F2F7) : const Color(0xFF2C2C2E);

    // 三态反馈的一格：64 高的陈列块 + 下方说明。
    Widget feedbackTile(String caption, Widget chip) => Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip,
          const SizedBox(height: 8),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.4,
              color: ink.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );

    Widget chipBox(String label) => Container(
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 搜索栏 ─────────────────────────────────────────────
        const _SectionTitle('搜索栏'),
        _DemoSurface(
          themeMode: mode,
          caption: 'MiSearchBar：上为静态展示态（点按经 onTap），下为输入态'
              '（editable: true）+ 取消钮 —— 聚焦或有输入时 fade 0 → 1 淡入'
              '（alpha 乘进填充与叉号墨色，不套 Opacity：圆钮内含 backdrop '
              '磨砂，saveLayer 会让它变空）。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MiSearchBar(
                hint: '搜索主题 / 壁纸 / 图标',
                themeMode: mode,
                onTap: () => _demoSnack(context, '静态搜索栏被点击'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MiSearchBar(
                      hint: '点这里输入',
                      themeMode: mode,
                      editable: true,
                      controller: _query,
                      focusNode: _queryFocus,
                      onChanged: (v) => setState(() => _text = v),
                    ),
                  ),
                  const SizedBox(width: MiDimens.spaceMd),
                  // 取消钮常驻排版、只动 fade（结构不变，磨砂不掉）。
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: searching ? 1 : 0),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, fade, _) => MiSearchCancelButton(
                      themeMode: mode,
                      fade: fade,
                      onTap: searching
                          ? () {
                              _query.clear();
                              _queryFocus.unfocus();
                              setState(() => _text = '');
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── 设置行 ─────────────────────────────────────────────
        const _SectionTitle('设置行'),
        MiSettingsCard(
          themeMode: mode,
          children: [
            MiSettingsRow(
              themeMode: mode,
              label: 'WLAN',
              value: '已开启',
              leading: const MiSettingsTile(Icons.wifi, Color(0xFF2F9BFF)),
              onTap: () => _demoSnack(context, '值文 + chevron 行'),
            ),
            MiSettingsRow(
              themeMode: mode,
              label: '蓝牙',
              leading:
                  const MiSettingsTile(Icons.bluetooth, Color(0xFF2F9BFF)),
              // 尾部开关：给出 trailing 时 chevron 自动让位。
              trailing: MiSwitch(
                value: _wifi,
                themeMode: mode,
                onChanged: (v) => setState(() => _wifi = v),
              ),
              onTap: () => setState(() => _wifi = !_wifi),
            ),
            MiSettingsRow(
              themeMode: mode,
              label: '个人热点',
              subtitle: '允许其他设备通过 Wi-Fi 连接',
              value: _wifi ? '已连接' : '未连接',
              leading: const MiSettingsTile(
                Icons.wifi_tethering,
                Color(0xFF34C759),
              ),
              onTap: () => _demoSnack(context, '副标题 + 值文行'),
            ),
          ],
        ),
        _demoNote(
          context,
          '行 = 前导块 + 主文案（+ 副标题）+ 值文 / 尾部 + chevron；整行'
              '按压高亮带，三态反馈走 MiPressable。',
        ),
        const SizedBox(height: 14),
        // ── 开关 ───────────────────────────────────────────────
        const _SectionTitle('开关'),
        MiSettingsCard(
          themeMode: mode,
          children: [
            MiSettingsRow(
              themeMode: mode,
              label: '已开启',
              chevron: false,
              trailing: MiSwitch(
                value: _switchOn,
                themeMode: mode,
                onChanged: (v) => setState(() => _switchOn = v),
              ),
            ),
            MiSettingsRow(
              themeMode: mode,
              label: '已关闭',
              chevron: false,
              trailing: MiSwitch(
                value: _switchOff,
                themeMode: mode,
                onChanged: (v) => setState(() => _switchOff = v),
              ),
            ),
            MiSettingsRow(
              themeMode: mode,
              label: '禁用态（开关）',
              chevron: false,
              trailing: const MiSwitch(value: true, onChanged: null),
            ),
          ],
        ),
        _demoNote(
          context,
          'MiSwitch：点按或左右拖拽切换（拖过行程中点即吸附，未过则弹回）；'
              '按下 / 拖拽时钮体放大 1.127、轨道色随行程插值，松手弹簧吸附，'
              '无涟漪；禁用整件降透明。',
        ),
        const SizedBox(height: 14),
        // ── 复选框 ─────────────────────────────────────────────
        const _SectionTitle('复选框'),
        MiSettingsCard(
          themeMode: mode,
          children: [
            MiSettingsRow(
              themeMode: mode,
              label: '全部同步',
              chevron: false,
              trailing: MiCheckbox(
                value: _checkOn,
                themeMode: mode,
                onChanged: (v) => setState(() => _checkOn = v),
              ),
            ),
            MiSettingsRow(
              themeMode: mode,
              label: '仅 Wi-Fi 下同步',
              chevron: false,
              trailing: MiCheckbox(
                value: _checkOff,
                themeMode: mode,
                onChanged: (v) => setState(() => _checkOff = v),
              ),
            ),
            MiSettingsRow(
              themeMode: mode,
              label: '部分选中（半选）',
              chevron: false,
              trailing: MiCheckbox(
                value: _checkMixed,
                themeMode: mode,
                onChanged: (v) => setState(() => _checkMixed = v),
              ),
            ),
            MiSettingsRow(
              themeMode: mode,
              label: '禁用态（复选框）',
              chevron: false,
              trailing: const MiCheckbox(value: true, onChanged: null),
            ),
          ],
        ),
        _demoNote(
          context,
          'MiCheckbox：三态（开 / 关 / 半选 —— 半选点一下即全选）；勾号'
              '先淡入再沿路径划开，半选是同一套路径点收拢成横杠；按压叠色'
              '与弹框按钮同配方，禁用整件降透明。',
        ),
        const SizedBox(height: 14),
        // ── 滑条 ───────────────────────────────────────────────
        const _SectionTitle('滑条'),
        _DemoSurface(
          themeMode: mode,
          caption: '连续 · 关键点 0.25 / 0.5 / 0.75（越过的点换选中色，'
              '阈值内磁吸）',
          child: MiSlider(
            value: _sliderValue,
            keyPoints: const [0.25, 0.5, 0.75],
            themeMode: mode,
            onChanged: (v) => setState(() => _sliderValue = v),
          ),
        ),
        const SizedBox(height: 10),
        _DemoSurface(
          themeMode: mode,
          caption: '分档 · 0…4 五档 + 等分刻度（拖拽 / 点按 / ← → 都按档吸附）',
          child: MiSlider(
            value: _sliderStepped,
            min: 0,
            max: 4,
            divisions: 5,
            showKeyPoints: true,
            themeMode: mode,
            onChanged: (v) => setState(() => _sliderStepped = v),
          ),
        ),
        const SizedBox(height: 10),
        _DemoSurface(
          themeMode: mode,
          caption: '反向 · reverseDirection（右小左大；RTL 下自动再镜像）',
          child: MiSlider(
            value: _sliderReversed,
            reverseDirection: true,
            themeMode: mode,
            onChanged: (v) => setState(() => _sliderReversed = v),
          ),
        ),
        const SizedBox(height: 10),
        _DemoSurface(
          themeMode: mode,
          caption: '禁用态 · onChanged = null',
          child: const MiSlider(value: 0.6, onChanged: null),
        ),
        _demoNote(
          context,
          'MiSlider：拖拽跟手、点按落到点击处并以弹簧收敛；拇指在按下 / '
              '拖拽 / 悬停时放大 1.127，松手回原尺寸；关键点给出即陈列，'
              '分档与磁性吸附共用一套取值量化；禁用整件降透明。',
        ),
        const SizedBox(height: 14),
        // ── 悬浮工具栏 ──────────────────────────────────────────
        const _SectionTitle('悬浮工具栏'),
        _DemoSurface(
          themeMode: mode,
          caption: 'MiFloatingToolbar：胶囊容器（外留白 12 / 8、圆角 50、投影'
              '几何固定、可选 0.75dp 描边）—— 只做容器，横 / 纵由内容自定；'
              '容器吃掉点击、内部按钮照常响应。',
          child: Center(
            child: MiFloatingToolbar(
              themeMode: mode,
              showDivider: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (icon, label) in const [
                    (Icons.share_outlined, '分享'),
                    (Icons.edit_outlined, '编辑'),
                    (Icons.delete_outline, '删除'),
                  ])
                    SizedBox(
                      width: 64,
                      height: 56,
                      child: MiActionEntry(
                        icon: icon,
                        label: label,
                        themeMode: mode,
                        onPressed: () => _demoSnack(context, '$label 被点击'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // ── 桌面三态反馈 ────────────────────────────────────────
        const _SectionTitle('桌面三态反馈'),
        _DemoSurface(
          themeMode: mode,
          caption: '悬停叠色与键盘焦点环是推导的桌面语义（触屏素材没有样张）：'
              'Tab 走焦点、Enter / Space 激活、鼠标移入叠色。',
          child: Row(
            children: [
              feedbackTile(
                'MiPressable\n按压 + 悬停 + 焦点环',
                // 新组件统一入口：三态一体（按压视觉由 pressBuilder 给）。
                MiPressable(
                  mode: mode,
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () => setState(() => _presses++),
                  pressBuilder: (context, pressed, child) => AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    color: pressed
                        ? MiColors.accent.withValues(alpha: 0.18)
                        : Colors.transparent,
                    child: child,
                  ),
                  child: chipBox(_presses == 0 ? '按我' : '按了 $_presses 次'),
                ),
              ),
              const SizedBox(width: 12),
              feedbackTile(
                'MiHoverFeedback\n只有悬停叠色',
                MiHoverFeedback(
                  mode: mode,
                  borderRadius: BorderRadius.circular(14),
                  child: chipBox('悬停我'),
                ),
              ),
              const SizedBox(width: 12),
              feedbackTile(
                'MiFocusRing\nTab 聚焦 / Enter 激活',
                MiFocusRing(
                  mode: mode,
                  focusNode: _ringFocus,
                  borderRadius: BorderRadius.circular(14),
                  onActivate: () => _demoSnack(context, 'Enter / Space 激活'),
                  // 点按请求聚焦：焦点环是键盘语义，鼠标点按也该看得见。
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _ringFocus.requestFocus(),
                    child: chipBox('点我聚焦'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── 响应式网格 ────────────────────────────────────────
        const _SectionTitle('响应式网格'),
        _DemoSurface(
          themeMode: mode,
          caption: 'MiResponsiveGrid：列数按容器宽断点切换（< 520 → 4 列、'
              '< 800 → 6 列、更宽 → 8 列）；与展示位网格、主题卡网格同一机制。',
          child: MiResponsiveGrid(
            compactColumns: 4,
            mediumColumns: 6,
            expandedColumns: 8,
            compactMax: 520,
            mediumMax: 800,
            itemSpacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < 8; i++)
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _tileGradients[i % _tileGradients.length],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── 菜单 ───────────────────────────────────────────────
        const _SectionTitle('菜单'),
        _MenuShowcase(themeMode: mode),
      ],
    );
  }
}


/// 「菜单」小节（示例层）：`MiMenu` 的三种锚点形态 —— 偏好行下拉、级联
/// 子菜单、图标触发的多分组动作菜单。
///
/// 三处都**不劫持触发器**：行 / 图标的点按走 `MiMenuController.toggle()`，
/// 菜单只借触发器的盒子当锚点（右缘对齐、优先下方）。几何上的口径全在库里
/// （`MiMenuMetrics`），示例层不复制任何数字。
class _MenuShowcase extends StatefulWidget {
  const _MenuShowcase({required this.themeMode});

  final MiThemeMode themeMode;

  @override
  State<_MenuShowcase> createState() => _MenuShowcaseState();
}


class _MenuShowcaseState extends State<_MenuShowcase> {
  final MiMenuController _sort = MiMenuController();
  final MiMenuController _share = MiMenuController();
  final MiMenuController _actions = MiMenuController();

  /// 排序方式（单选菜单的选中下标）。
  static const List<String> _sorts = ['默认', '名称', '修改时间', '大小'];
  int _sortIndex = 1;

  /// 最近一次选择结果（回填到行的值文）。
  String _shareTarget = '未选择';
  String _action = '未选择';

  @override
  void dispose() {
    _sort.dispose();
    _share.dispose();
    _actions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.themeMode;
    final sub = MiSettingsPalette.secondaryFor(mode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MiSettingsCard(
          themeMode: mode,
          children: [
            // ── 单选：选中项转强调色 + 尾部勾号 ──────────────────
            MiMenu(
              controller: _sort,
              themeMode: mode,
              groups: [
                MiMenuGroup([
                  for (var i = 0; i < _sorts.length; i++)
                    MiMenuItem(
                      label: _sorts[i],
                      selected: _sortIndex == i,
                      value: i,
                    ),
                ]),
              ],
              onSelected: (s) =>
                  setState(() => _sortIndex = s.item.value! as int),
              child: MiSettingsRow(
                themeMode: mode,
                label: '排序方式',
                subtitle: '单选菜单：选中项带勾号，选完自动收起',
                value: _sorts[_sortIndex],
                trailing: MiMenuArrow(color: sub),
                onTap: _sort.toggle,
              ),
            ),
            // ── 级联：子列表首行是返回上级的同名行 ────────────────
            MiMenu(
              controller: _share,
              themeMode: mode,
              groups: const [
                MiMenuGroup([
                  MiMenuItem(
                    label: '分享到',
                    subtitle: '级联子菜单（微信 / 邮件 / 二维码）',
                    children: [
                      MiMenuItem(label: '微信', value: '微信'),
                      MiMenuItem(label: '邮件', value: '邮件'),
                      MiMenuItem(
                        label: '二维码',
                        enabled: false,
                        value: '二维码',
                      ),
                    ],
                  ),
                  MiMenuItem(label: '复制链接', value: '复制链接'),
                  MiMenuItem(label: '保存到相册', value: '相册'),
                  // 四个叶子行 + 二级也是四行：两层等高，切换时面板尺寸不变，
                  // 只做内容就地淡换（与参考示例的陈列口径一致 —— 行数不同
                  // 的层级切换会连带面板长高，那是内容差异不是动效差异）。
                  MiMenuItem(label: '添加到收藏', value: '收藏'),
                ]),
              ],
              onSelected: (s) =>
                  setState(() => _shareTarget = s.item.value! as String),
              child: MiSettingsRow(
                themeMode: mode,
                label: '分享',
                subtitle: '带子菜单：点开第二级，箭头行返回上级',
                value: _shareTarget,
                trailing: MiMenuArrow(color: sub),
                onTap: _share.toggle,
              ),
            ),
            // ── 多分组动作菜单：组间分隔线 + 整组禁用 ─────────────
            MiMenu(
              controller: _actions,
              themeMode: mode,
              groups: const [
                MiMenuGroup([
                  MiMenuItem(label: '编辑', value: '编辑'),
                  MiMenuItem(label: '复制', value: '复制'),
                  MiMenuItem(label: '重命名', value: '重命名'),
                ]),
                // 整组禁用：项照常占位、墨色降档、不响应点按。
                MiMenuGroup([MiMenuItem(label: '删除', value: '删除')], enabled: false),
              ],
              onSelected: (s) =>
                  setState(() => _action = s.item.value! as String),
              child: MiSettingsRow(
                themeMode: mode,
                label: '操作菜单（图标触发）',
                subtitle: '多分组 + 整组禁用，锚点 = 右侧竖点图标',
                value: _action,
                trailing: SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: CustomPaint(
                      size: const Size(4, 18),
                      painter: MoreVerticalIconPainter(sub),
                    ),
                  ),
                ),
                onTap: _actions.toggle,
              ),
            ),
          ],
        ),
        _demoNote(
          context,
          'MiMenu：锚点量自子级盒子（右缘对齐、下方优先，放不下翻上方并夹紧'
              '在宿主内）→ 0.15→1 缩放 + 单向揭示 + 淡入（弹簧 ζ 0.82）→ '
              '面板圆角 16 / 宽 200–288 / 行内距 20、首末行 20 中间 12。'
              '经 MiPopup 注册到宿主，z 序 = 注册序；点遮罩 / 系统返回收起，'
              '收口后才回调 onDismissed。',
        ),
        _demoNote(
          context,
          '进二级：整层 0.95→1 + 淡换，返回行照抄父项整行（含副文）好让两层'
              '按行对齐；两层行数不同时面板宽 / 高按同一 200ms 跟随内容过渡'
              '（Compose 原版 SizeTransform 的语义），不会先跳到最大再落定。',
        ),
        _demoNote(
          context,
          '配色不新造：面板 = 弹框表面（暗 #242424 / 亮 #FFFFFF）、选中 = '
              '品牌强调色、副文 = 设置行同一档 55%、遮罩取参考实现的窗口压暗'
              '（亮 0.30 / 暗 0.60）。几何与动效为「参考实现值」（本库无菜单'
              '素材），见 MiMenuMetrics 的对照表。',
        ),
      ],
    );
  }
}


// ── 「弹层与效果」组（示例层）：弹框 / 弹出面板 / 渐进模糊 ───────────────────

/// 「弹层与效果」分组（示例层）：三类弹层与效果层组件的可交互陈列。
///
///  * 弹框（声明式）—— 由**外壳挂浮层**（与「我的」页同一入口），所以
///    PC 套壳演示里弹框画在机身壳内、不盖整窗；
///  * 弹框（命令式 `showMiDialog`）—— `await` 拿被点下标，免去 Stack
///    挂浮层与显隐状态；它挂**根导航器**（`showDialog` 同口径），
///    PC 套壳演示里会盖住整窗（这正是与壳内声明式浮层的差异）；
///  * 弹出面板 —— 从本组的触发行弹起（锚点 = 触发行圆心），自定义高 240；
///  * 底部弹窗 —— 贴底滑入的抽屉（只圆上两角、手柄下拉 / 点遮罩收起），
///    同样经弹层宿主渲染；
///  * 渐进模糊 —— [MiGradientBlur] 的独立用法（顶栏那条材质不依赖顶栏）。
class _LayerShowcase extends StatefulWidget {
  const _LayerShowcase({
    required this.themeMode,
    required this.onShowDialog,
    required this.onShowListDialog,
    required this.panelTriggerKey,
    required this.onShowPanel,
  });

  final MiThemeMode themeMode;

  /// 声明式弹框入口（外壳挂浮层）；null = 外壳未接（如单独渲染本页）。
  final ValueChanged<MiDialogPosition>? onShowDialog;

  /// 操作列表弹框入口；语义同 [onShowDialog]。
  final VoidCallback? onShowListDialog;

  /// 面板触发行（唤起锚点）与唤起回调。
  final GlobalKey panelTriggerKey;
  final VoidCallback onShowPanel;

  @override
  State<_LayerShowcase> createState() => _LayerShowcaseState();
}


class _LayerShowcaseState extends State<_LayerShowcase> {
  /// σ 缩放（渐进模糊演示）：1.0 = 度量材质；0.4 ≈ 满速滚动的省帧档。
  double _sigmaScale = 1.0;

  /// 底部弹窗显隐（示例层）：遮罩点按 / 手柄下拉都交宿主置 false。
  bool _sheet = false;

  /// 命令式弹框：await 拿下标，弹一条提示说明结果。
  Future<void> _imperativeDialog() async {
    final i = await showMiDialog(
      context,
      dialog: MiDialog(
        themeMode: widget.themeMode,
        title: '删除联系人',
        message: '确定从本地和云端同时删除“方太安装师傅”吗？',
        messageAlign: TextAlign.start,
        actions: [
          // 原 onPressed 仍会执行（先回调后关闭）；演示不接行为。
          const MiDialogAction(label: '取消', onPressed: _noop),
          const MiDialogAction(
            label: '删除',
            style: MiDialogActionStyle.destructive,
            onPressed: _noop,
          ),
        ],
      ),
    );
    if (!mounted) return;
    _demoSnack(
      context,
      i == null ? '弹框被关闭（点遮罩 / 系统返回）' : '被点的是第 $i 个按钮',
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.themeMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 弹框（声明式，外壳挂浮层） ───────────────────────────
        const _SectionTitle('弹框'),
        MiSettingsCard(
          themeMode: mode,
          children: [
            MiSettingsRow(
              themeMode: mode,
              label: '底部弹框（默认）',
              leading: const MiSettingsTile(
                Icons.arrow_downward_rounded,
                Color(0xFF2F9BFF),
              ),
              onTap: widget.onShowDialog == null
                  ? null
                  : () => widget.onShowDialog!(MiDialogPosition.bottom),
            ),
            MiSettingsRow(
              themeMode: mode,
              label: '顶部弹框',
              leading: const MiSettingsTile(
                Icons.arrow_upward_rounded,
                Color(0xFF34C759),
              ),
              onTap: widget.onShowDialog == null
                  ? null
                  : () => widget.onShowDialog!(MiDialogPosition.top),
            ),
            MiSettingsRow(
              themeMode: mode,
              label: '居中弹框',
              leading: const MiSettingsTile(
                Icons.crop_square_rounded,
                Color(0xFFFF9500),
              ),
              onTap: widget.onShowDialog == null
                  ? null
                  : () => widget.onShowDialog!(MiDialogPosition.center),
            ),
            MiSettingsRow(
              themeMode: mode,
              label: '操作列表弹框（纵向）',
              leading: const MiSettingsTile(
                Icons.view_agenda_outlined,
                Color(0xFF7A5CFA),
              ),
              onTap: widget.onShowListDialog,
            ),
          ],
        ),
        _demoNote(
          context,
          '声明式：if (visible) MiDialog(…) 挂在页面 Stack 里 —— 这里由'
              '外壳统一挂浮层（与「我的」页同一入口），弹框画在机身壳内。',
        ),
        const SizedBox(height: 14),
        // ── 弹框（命令式 showMiDialog） ─────────────────────────
        const _SectionTitle('命令式弹框'),
        MiSettingsCard(
          themeMode: mode,
          children: [
            MiSettingsRow(
              themeMode: mode,
              label: '删除联系人（await 拿下标）',
              leading: const MiSettingsTile(
                Icons.delete_outline,
                Color(0xFFFF3B30),
              ),
              onTap: _imperativeDialog,
            ),
          ],
        ),
        _demoNote(
          context,
          'showMiDialog：final i = await showMiDialog(context, dialog: …) '
              '返回被点按钮 / 列表项下标（点遮罩 / 系统返回 = null），免去'
              'Stack 挂浮层与显隐状态；挂根导航器（showDialog 同口径）。',
        ),
        const SizedBox(height: 14),
        // ── 弹出面板 ──────────────────────────────────────
        const _SectionTitle('弹出面板'),
        MiSettingsCard(
          themeMode: mode,
          children: [
            MiSettingsRow(
              key: widget.panelTriggerKey,
              themeMode: mode,
              label: '从按钮弹起（自定义高 240）',
              leading: const MiSettingsTile(
                Icons.open_in_new,
                Color(0xFF7A5CFA),
              ),
              onTap: widget.onShowPanel,
            ),
          ],
        ),
        _demoNote(
          context,
          'MiPullUpPanel：从触发按钮圆心等比放大长到终态（弹簧 + 轻微过冲），'
              '面板外不压暗、点面板外收回；高度 / 内容由调用方定义。',
        ),
        const SizedBox(height: 14),
        // ── 底部弹窗 ──────────────────────────────────────
        const _SectionTitle('底部弹窗'),
        MiSettingsCard(
          themeMode: mode,
          children: [
            MiSettingsRow(
              themeMode: mode,
              label: '贴底滑入（手柄 + 遮罩）',
              leading: const MiSettingsTile(
                Icons.vertical_align_bottom,
                Color(0xFF34C759),
              ),
              onTap: () => setState(() => _sheet = true),
            ),
          ],
        ),
        _demoNote(
          context,
          'MiBottomSheet：只圆上两角、弹簧滑入滑出（过冲 ~0.15%）；手柄下拉'
              '到位或点遮罩触发 onDismissRequest，滑出收口后才回调 onDismissed；'
              '宽屏限宽 640 居中。',
        ),
        const SizedBox(height: 14),
        // ── 渐进模糊 ──────────────────────────────────────
        const _SectionTitle('渐进模糊'),
        _GradientBlurDemo(themeMode: mode),
        // 弹层本体：经 MiPopup 注册到外壳的 MiPopupHost（与弹框同一宿主）。
        MiBottomSheet(
          show: _sheet,
          title: '选择操作',
          themeMode: mode,
          onDismissRequest: () => setState(() => _sheet = false),
          child: MiActionEntryRow(
            entries: [
              MiActionEntry(
                icon: Icons.share_outlined,
                label: '分享',
                themeMode: mode,
                onPressed: () => setState(() => _sheet = false),
              ),
              MiActionEntry(
                icon: Icons.edit_outlined,
                label: '编辑',
                themeMode: mode,
                onPressed: () => setState(() => _sheet = false),
              ),
              MiActionEntry(
                icon: Icons.delete_outline,
                label: '删除',
                themeMode: mode,
                onPressed: () => setState(() => _sheet = false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


/// 渐进模糊独立用法演示（示例层）：高频内容（复用首页横幅 painter）压在
/// 顶部 120dp 的渐进模糊下 —— 顶最糊、向下衰减、区底归零。
///
/// 下方滑杆演示 [MiGradientBlur.sigmaScale]：运动中把各段 σ 等比压低是
/// 本库的省帧档（0.6 ≈ 满速滚动），曲线**形状**不变、只改强度。
class _GradientBlurDemo extends StatefulWidget {
  const _GradientBlurDemo({required this.themeMode});

  final MiThemeMode themeMode;

  @override
  State<_GradientBlurDemo> createState() => _GradientBlurDemoState();
}


class _GradientBlurDemoState extends State<_GradientBlurDemo> {
  /// 模糊区高（度量曲线跨度 119dp 取整档）与演示面高。
  static const double _blurExtent = 120;
  static const double _surfaceHeight = 190;

  double _sigmaScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final light = widget.themeMode == MiThemeMode.light;
    final fg = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: _surfaceHeight,
            child: Stack(
              children: [
                // 高频内容：平坦色块在模糊下不变，判不出「有没有糊」。
                const Positioned.fill(
                  child: CustomPaint(
                    painter: _HeroPainter(),
                    child: SizedBox.expand(),
                  ),
                ),
                // 渐进模糊：叠在滚动内容之上、其它内容之下（组件自带
                // IgnorePointer，不参与手势）。`underSurface: false` ——
                // 上面没有不透明压色，模糊真的会被看到，一段都不能跳。
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: MiGradientBlur(
                    height: _blurExtent,
                    sigmaScale: _sigmaScale,
                    underSurface: false,
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 12,
                  child: Text(
                    '顶部最糊 → 向下变清晰',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _demoNote(
          context,
          'MiGradientBlur：分段定 σ 的顶部渐进模糊，可独立于顶栏使用'
              '（顶栏 showBlur: true 内部复用的就是它）。',
        ),
        Row(
          children: [
            Text(
              'σ 缩放 ${_sigmaScale.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11.5,
                color: fg.withValues(alpha: 0.7),
              ),
            ),
            Expanded(
              child: Slider(
                value: _sigmaScale,
                min: 0.4,
                max: 1.0,
                divisions: 12,
                label: _sigmaScale.toStringAsFixed(2),
                onChanged: (v) => setState(() => _sigmaScale = v),
              ),
            ),
          ],
        ),
        _demoNote(
          context,
          'σ 缩放是运动中的省帧档（0.6 ≈ 满速滚动）：各段 σ 同比例压低，'
              '曲线形状不变、只改强度；停稳后传回 1.0 即恢复度量材质。',
        ),
      ],
    );
  }
}


/// 弹出面板内容（demo 功能，非框架组件）：标题 + 2×2 快捷操作。
///
/// 高度由外层 `MiPullUpPanel.height` 自定义（240dp）；内容在终态尺寸下
/// 排版、随面板一起缩放。
class _PanelDemoContent extends StatelessWidget {
  const _PanelDemoContent({required this.themeMode});

  final MiThemeMode themeMode;

  static const List<(IconData, String)> _entries = [
    (Icons.wallpaper, '壁纸'),
    (Icons.radio_button_checked, '图标'),
    (Icons.lock_outline, '锁屏'),
    (Icons.font_download_outlined, '字体'),
    (Icons.music_note, '铃声'),
    (Icons.palette_outlined, '主题色'),
  ];

  @override
  Widget build(BuildContext context) {
    final ink = MiColors.foregroundFor(themeMode);
    final sub = themeMode == MiThemeMode.dark
        ? const Color(0xB3FFFFFF)
        : const Color(0xB3000000);

    Widget cell((IconData, String) e) => Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(e.$1, size: 26, color: ink),
          const SizedBox(height: 8),
          Text(
            e.$2,
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
            '主题装扮',
            style: MiTypography.dialogTitle.copyWith(color: ink),
          ),
          const SizedBox(height: 18),
          Row(
            children: [for (final e in _entries.sublist(0, 3)) cell(e)],
          ),
          const SizedBox(height: 16),
          Row(
            children: [for (final e in _entries.sublist(3)) cell(e)],
          ),
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
