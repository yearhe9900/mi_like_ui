import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mi_like_ui/mi_like_ui.dart';

/// 页面内容左右页边距。
///
/// * compact（手机）：沿用 1:1 实测值（首页 11.9 / 「我的」20）；
/// * medium / expanded（外壳已把画面铺成内容舞台）：收到 [MiDimens.spaceXxl]
///   24 —— 宽画布上继续贴 11.9 会让内容顶到边。
double _pageInset(BuildContext context, double measured) =>
    MiViewport.of(context).isCompact ? measured : MiDimens.spaceXxl;

/// 顶部状态栏让位：参考页实测 56dp；真机/平板安全区更大时取更大者，
/// 避免大标题被刘海压住（桌面窗口 padding 为 0 → 仍是 56）。
double _statusBarInset(BuildContext context) =>
    math.max(56.0, MediaQuery.paddingOf(context).top);

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
  });

  final int index;
  final MiThemeMode themeMode;
  final ValueChanged<MiThemeMode>? onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        // 首页页边距实测 25~28px ≈ 11.9dp（搜索框 28 / 横幅 25 / 卡片
        // 25~26 同量级，与分类页一致）；区块标题行经 _SectionTitle.inset
        // 收进 ≈20.5dp 文本列（实测 x46），卡标题再由卡片自身 8.8dp
        // 内缩与之同列起排。
        // 顶层页形态：**无返回圆钮**（`showBack` 默认 false）。首行是搜索栏，
        // 其顶缘实测 168.5dp（比卡片档少一档 14.5dp）→ 用搜索栏档上内边距。
        final inset = _pageInset(context, 11.9);
        return _MockPageShell(
          title: '首页',
          padding: EdgeInsets.fromLTRB(
            inset,
            MiTopBarMetrics.searchBarTopInset,
            inset,
            20,
          ),
          children: _homeItems,
        );
      case 1:
        // 「分类」tab = 组件展示库：胶囊分类标签切分组，网格是展示位
        return _ShowcasePage(themeMode: themeMode);
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

/// 页面壳：滚动内容 + 顶部导航栏 [MiTopBar]（大标题 = 页面名）。
///
/// [MiTopBar] 是受控组件（不自带滚动），这里用 [ValueNotifier] 承接
/// [ScrollController] 的位移，只重建顶栏一层而非整页 setState。
/// 页底取参考页实测色（亮 #F3F3F3 / 暗 #000000）——同时让顶栏遮罩
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

  /// 滚动内容内边距：左右默认 20（「我的」页沿用原值）；首页按实测
  /// 页边距 11.9dp + 搜索栏档上内边距 168.5dp 覆盖（见 `MockPage.build`
  /// 的 `case 0`）。
  final EdgeInsetsGeometry padding;

  @override
  State<_MockPageShell> createState() => _MockPageShellState();
}

class _MockPageShellState extends State<_MockPageShell> {
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
    return ColoredBox(
      color: light ? const Color(0xFFF3F3F3) : const Color(0xFF000000),
      child: Stack(
        children: [
          // Bottom padding stays small on purpose: the content must scroll
          // BEHIND the glass bar (y ≈ 776..832 of the 856-tall frame) or the
          // frosted transmission has nothing to show.
          Positioned.fill(
            child: ListView(
              controller: _controller,
              padding: widget.padding,
              children: widget.children,
            ),
          ),
          // 顶栏必须用 Positioned 钉在顶部：本 Stack 若留下**非定位子级**，
          // 它会按该子级尺寸收缩（= 顶栏自身的 152.8dp 高）而不是撑满父级，
          // 于是整页在 loose 约束的上级（AnimatedSwitcher 内部是
          // `alignment: center` 的 Stack）里被垂直居中 —— 顶栏会跑到屏幕正中，
          // 页底黑与 ListView 只剩 152.8dp 高、内容全被裁掉。
          // 2026-10-16 实机截图实测：整体下移 351.1dp =（856 − 152.8）/ 2。
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

  /// 左内缩：首页区块标题行实测 x46 ≈ 20.5dp（页边距 11.9 + 8.6），
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

class _GradientCard extends StatelessWidget {
  const _GradientCard({required this.colors, required this.caption, this.height = 118});

  final List<Color> colors;
  final String caption;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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
  }
}

/// 搜索位即框架组件 [MiSearchBar]（亮/暗完整截图实测 + 与底部导航栏同源的
/// 透明磨砂参数，见 `src/components/inputs/search_bar/`）：占位文案与
/// 页面级左右 inset（11.9）由 demo 提供，明暗配方由组件 palette 供给。
const List<Widget> _homeItems = [
  MiSearchBar(hint: '搜索主题 / 壁纸 / 图标'),
  SizedBox(height: 16),
  _GradientCard(
    height: 150,
    colors: [Color(0xFF2E3A8C), Color(0xFF7B4DBE), Color(0xFFD06A8A)],
    caption: '湾区升明月  肆好时光',
  ),
  _SectionTitle('精选主题', inset: 8.6),
  _ThemeCardGrid(),
  _SectionTitle('热门 IP', inset: 8.6),
  Row(children: [
    Expanded(child: _GradientCard(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)], caption: '热门IP')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(colors: [Color(0xFFFF8177), Color(0xFFB24592)], caption: '插画合集')),
  ]),
  SizedBox(height: 12),
  Row(children: [
    Expanded(child: _GradientCard(colors: [Color(0xFF4568DC), Color(0xFFB06AB3)], caption: '设计师专区')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(colors: [Color(0xFF11998E), Color(0xFF38EF7D)], caption: '清新绿意')),
  ]),
  _SectionTitle('更多', inset: 8.6),
  Row(children: [
    Expanded(child: _GradientCard(colors: [Color(0xFFFF512F), Color(0xFF242424)], caption: '暖橙日落')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)], caption: '海盐汽水')),
  ]),
  SizedBox(height: 12),
  _GradientCard(height: 90, colors: [Color(0xFF3E1E68), Color(0xFF8E54E9)], caption: '查看全部主题  ›'),
];

/// 「精选主题」卡片网格（示例层）：竖向预览卡 [MiThemeCard]。
///
/// 列数按**容器可用宽**断点切换（[MiResponsiveGrid]，局部断点 —— 外壳把
/// 画面加宽后才生效；393 设计宽下恒为 3 列，与参考截图一致）：
///  * compact（< 600）→ 3 列；
///  * medium（600…1023）→ 4 列；
///  * expanded（≥ 1024）→ 6 列。
///
/// 几何对齐参考截图实测：列距取 [MiThemeCardMetrics.columnGap]（11.9，
/// 页边距同值）、行距取 [MiThemeCardMetrics.rowGap]（15）；标题经卡片
/// 自身 8.8dp 内缩与区块标题「精选主题」（11.9 + 8.6 ≈ 20.5）同列起排。
/// 卡片宽度由网格等分，预览图按 259:472 定比 → 列数变化时卡片整体缩放，
/// 不会被横向拉伸。
/// 预览图为实测 6 张卡壁纸主色上→下渐变占位（截图采样均值，顺序左→右、
/// 上→下）；标题为示例命名（参考图卡名字迹不作字面复刻）。
class _ThemeCardGrid extends StatelessWidget {
  const _ThemeCardGrid();

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
    return MiResponsiveGrid(
      compactColumns: 3,
      mediumColumns: 4,
      expandedColumns: 6,
      // 内容宽断点（不是窗口断点）：393 设计宽下内容宽 369 → 3 列；
      // 舞台加宽到 1000 后内容宽 952 → 6 列。
      compactMax: 520,
      mediumMax: 800,
      itemSpacing: MiThemeCardMetrics.columnGap,
      runSpacing: MiThemeCardMetrics.rowGap,
      children: [
        for (var i = 0; i < _titles.length; i++)
          MiThemeCard(
            title: _titles[i],
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
/// 顶部胶囊分类标签是框架组件 [MiPillTabBar]（明暗完整截图实测），
/// 用来切分组件分组；下方网格是各组件的展示位 —— 「Logo 展示」组前 6 位
/// 展示 `nav_icons.dart` 的全部 logo（真实框架 logo），「按钮展示」组先
/// 陈列 `MiButton` 按钮本体（关注 / 已关注 / 禁用三态），各组其余铺占位
/// 补足可滚长度，其它分组为示例占位（渐变圆角方块 + 抽象图形 + 「示例组件N」）。
///
/// 吸顶展示：搜索框 + 标签行悬浮吸顶，网格上滚时从胶囊后方经过，
/// 借胶囊的半透明磨砂直观展示透明/透射效果。
class _ShowcasePage extends StatefulWidget {
  const _ShowcasePage({required this.themeMode});

  final MiThemeMode themeMode;

  @override
  State<_ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<_ShowcasePage> {
  /// 吸顶头部高度 = 状态栏让位 + 搜索框 44.1 + 间距 16 + 胶囊行 39.9；
  /// 滚动网格初始让出头部 + 12（胶囊行底 → 内容的实测间距）。
  ///
  /// 状态栏让位在真机取安全区上边距（参考页实测 56，见 [_statusBarInset]），
  /// 因此不再是编译期常量 —— 头部高度与吸顶内边距共用同一个值，改一处即
  /// 同步，不会出现「搜索框下移而网格没让位」的错位。
  double _headerHeight(BuildContext context) =>
      _statusBarInset(context) +
      MiSearchBarMetrics.barHeight +
      16 +
      MiPillTabMetrics.pillHeight;

  /// 分类胶囊标签（对应截图 推荐/背屏/小部件/主题 的位置）：前两个按
  /// 分组内容命名（Logo 展示 / 按钮展示），后两个仍是占位示例。
  static const List<String> _tabs = ['Logo 展示', '按钮展示', '示例三', '示例四'];

  /// 每个分类下的展示位数量（示例内容）；取足够行数使网格溢出可滚，
  /// 以便演示「滚动内容从吸顶胶囊后方经过」的透明/磨砂透射。
  static const List<int> _counts = [32, 32, 32, 32];

  /// 「Logo 展示」组的 logo 名称（与 [_logos] 顺序一致）。
  static const List<String> _logoNames = [
    '滚筒刷',
    '网格闪光',
    '卡片星',
    '点阵圆钮',
    '笑脸贝雷',
    '加号',
  ];

  /// 「Logo 展示」组 = `nav_icons.dart` 全量 logo 展示（真实框架 logo，非占位）。
  List<CustomPainter> _logos(Color ink) => [
        RollerIconPainter(ink),
        GridSparkleIconPainter(ink),
        CardsStarIconPainter(ink),
        GridDotsIconPainter(ink),
        SmileyBeretIconPainter(ink),
        PlusIconPainter(ink),
      ];

  int _tab = 0;

  /// 展示位：「Logo 展示」组前 6 位给真实 logo 全量展示位，其余铺占位展示位
  /// （补足可滚长度）；其余分组全给占位展示位。
  Widget _tileAt(int i, bool logoMode, List<CustomPainter> logos) {
    if (logoMode && i < _logoNames.length) {
      return _ShowcaseTile(
        colors: _tileGradients[i % _tileGradients.length],
        glyph: CustomPaint(painter: logos[i], size: const Size.square(26)),
        name: _logoNames[i],
      );
    }
    // 占位下标从头计（「Logo 展示」组的占位跟在 6 个 logo 之后，命名从一重排）
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
    // 页底色与内容边距按完整截图实测：亮 #F3F3F3 / 暗 #000000，
    // 内容左右 37px≈11.9dp（搜索框、标签行、下方内容同边距）；
    // 外壳加宽成内容舞台（expanded）时页边距收到 24。
    final inset = _pageInset(context, 11.9);
    final statusTop = _statusBarInset(context);
    return Container(
      color: widget.themeMode == MiThemeMode.light
          ? const Color(0xFFF3F3F3)
          : const Color(0xFF000000),
      child: Stack(
        children: [
          // 滚动网格：初始让出吸顶头部高度；上滚后内容从胶囊行后方经过，
          // 胶囊的半透明磨砂把透上来的网格磨出毛玻璃感。
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                inset,
                _headerHeight(context) + 12,
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
          // 吸顶头部：搜索框 + 胶囊分类标签悬浮在滚动内容之上
          //（标签行吸附搜索框下方，网格从胶囊后方滚过）。
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(inset, statusTop, inset, 0),
                  child: MiSearchBar(
                    hint: '搜索主题 / 壁纸 / 图标',
                    themeMode: widget.themeMode,
                  ),
                ),
                const SizedBox(height: 16), // 实测搜索框底 → 标签行 49px ≈ 15.8dp
                // 左对齐：胶囊行自身宽度只到内容（4 个胶囊 + 边距），宽屏舞台
                // 下若不显式左对齐，会因 Column 默认居中而飘到页面中间，
                // 与搜索框、下方网格的左缘失配。
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: MiPillTabBar(
                    labels: _tabs,
                    selectedIndex: _tab,
                    onTap: (i) => setState(() => _tab = i),
                    themeMode: widget.themeMode,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 「按钮展示」分组内容（示例层）：复刻「我的关注」页的关注按钮本体。
///
/// 参考图 = 亮/暗两张完整截图（1220x2656）实测：按钮 59.9×28.3dp stadium、
/// 填充 #4980F7 明暗同色、标签 13dp Medium 白字；行节奏沿用实测行距
/// 56.1dp。三行分别是主按钮（点按在 关注 ↔ 已关注 间切换）、次级态、
/// 禁用态；按钮直接陈列在分组页底上（亮 #F3F3F3 / 暗 #000000），
/// 与参考图同底对照。
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
            '实测自「我的关注」页 1220×2656：59.9×28.3dp stadium · '
            '填充 #4980F7 明暗同色 · 标签 13dp/500 · 左右内边距 17dp',
            style: _subStyle(context, 11),
          ),
        ),
      ],
    );
  }

  /// 规格行：左说明、右按钮（参考页按钮靠右陈列），行高沿用实测行距。
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
