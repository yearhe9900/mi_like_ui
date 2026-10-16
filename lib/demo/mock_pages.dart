import 'package:flutter/material.dart';
import 'package:mi_like_ui/mi_like_ui.dart';

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
        return const _MockPageShell(title: '首页', children: _homeItems);
      case 1:
        // 「分类」tab = 组件展示库：胶囊分类标签切分组，网格是展示位
        return _ShowcasePage(themeMode: themeMode);
      default:
        return _MockPageShell(title: '我的', children: [
          // 模式切换入口（demo 功能，放在「我的」里）
          if (onThemeModeChanged != null)
            _ThemeModeSwitch(mode: themeMode, onChanged: onThemeModeChanged!),
          if (onThemeModeChanged != null) const SizedBox(height: 12),
          ..._mineItems,
        ]);
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

class _MockPageShell extends StatelessWidget {
  const _MockPageShell({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Bottom padding stays small on purpose: the content must scroll BEHIND
    // the glass bar (y ≈ 776..832 of the 856-tall frame) or the frosted
    // transmission has nothing to show.
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      children: children,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
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
  _SectionTitle('精选主题'),
  Row(children: [
    Expanded(child: _GradientCard(colors: [Color(0xFF1B2735), Color(0xFF2E4A62)], caption: 'Retro Future')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(colors: [Color(0xFF232526), Color(0xFF414345)], caption: 'LUMIÈRE')),
  ]),
  SizedBox(height: 12),
  Row(children: [
    Expanded(child: _GradientCard(colors: [Color(0xFF134E5E), Color(0xFF71B280)], caption: '清爽夏日')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(colors: [Color(0xFF3E1E68), Color(0xFF8E54E9)], caption: '星空物语')),
  ]),
  _SectionTitle('热门 IP'),
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
  _SectionTitle('更多'),
  Row(children: [
    Expanded(child: _GradientCard(colors: [Color(0xFFFF512F), Color(0xFF242424)], caption: '暖橙日落')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)], caption: '海盐汽水')),
  ]),
  SizedBox(height: 12),
  _GradientCard(height: 90, colors: [Color(0xFF3E1E68), Color(0xFF8E54E9)], caption: '查看全部主题  ›'),
];

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
  /// 吸顶头部高度 = 状态栏让位 56 + 搜索框 44.1 + 间距 16 + 胶囊行 39.9；
  /// 滚动网格初始让出头部 + 12（胶囊行底 → 内容的实测间距）。
  static const double _headerHeight =
      56 + 44.1 + 16 + MiPillTabMetrics.pillHeight;

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
    // 内容左右 37px≈11.9dp（搜索框、标签行、下方内容同边距）
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
              padding:
                  const EdgeInsets.fromLTRB(11.9, _headerHeight + 12, 11.9, 0),
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
                    for (var row = 0; row * 4 < count; row++) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var col = 0; col < 4; col++) ...[
                              if (col > 0) const SizedBox(width: 12),
                              Expanded(
                                child: row * 4 + col < count
                                    ? _tileAt(row * 4 + col, logoMode, logos)
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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
                  padding: const EdgeInsets.fromLTRB(11.9, 56, 11.9, 0),
                  child: MiSearchBar(
                    hint: '搜索主题 / 壁纸 / 图标',
                    themeMode: widget.themeMode,
                  ),
                ),
                const SizedBox(height: 16), // 实测搜索框底 → 标签行 49px ≈ 15.8dp
                MiPillTabBar(
                  labels: _tabs,
                  selectedIndex: _tab,
                  onTap: (i) => setState(() => _tab = i),
                  themeMode: widget.themeMode,
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
