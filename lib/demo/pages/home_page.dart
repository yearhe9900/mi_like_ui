part of '../mock_pages.dart';


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


/// 「滚动降 σ」的**实时**驱动器（推导值的性能优化，非素材度量）。
///
/// 磨砂 σ 缩放跟随滚动**速度**连续变化：运动越快磨砂越轻（1.0 → 0.6，
/// 满速 [vRef] 封顶），速度衰减后逐帧平滑回升 —— 实时渐变，不在停顿瞬间
/// 从 0.6 跳回 1.0（实机反馈：那一下「突然更糊」很扎眼）。σ 与高斯成本
/// 近似线性，运动掩蔽下视觉几乎无差，GPU 省近半。
///
/// 输入取相邻帧的滚动位移差（帧时间戳用 `SchedulerBinding` 的假时钟友
/// 好时间源）+ EMA 抹平 —— **不碰墙钟 / 定时器**：逐帧值只取决于滚动事件
/// 序列，golden 回归可复现（用 `DateTime.now()` 差分速度会因测试时假
/// 时钟与真实时钟错位而漂移）。
///
/// 用法：`attach(controller)` 后把本对象当 [ValueListenable<double>] 交给
/// `ValueListenableBuilder` 包住 `MiTopBar`（只重建顶栏，不重建整页），
/// `value` 即 `sigmaScale`。
class _ScrollSigma extends ValueNotifier<double> {
  _ScrollSigma() : super(1.0);

  /// 满速参考（dp/s，**推导**）：常规滑动 600…1500，取 1200 封顶。
  static const double vRef = 1200;

  /// 满速下的 σ 缩放（**推导值**：0.6 —— 再低就能看出「糊变轻」了）。
  static const double minScale = 0.6;

  /// 速度低于该值（dp/s）即视为静止。
  static const double _stopEpsilon = 24;

  ScrollController? _controller;
  double _speed = 0;
  double _lastOffset = 0;
  Duration _lastFrame = Duration.zero;

  void attach(ScrollController controller) {
    _controller = controller..addListener(_onScroll);
  }

  void _onScroll() {
    final position = _controller?.position;
    if (position == null || !position.hasPixels) return;
    // 帧时间戳（不是墙钟）：测试里跟随假时钟，序列可复现。
    final now = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    final dt = (now - _lastFrame).inMicroseconds / 1e6;
    final offset = position.pixels;
    if (dt > 0) {
      final v = (offset - _lastOffset).abs() / dt;
      // EMA 抹平逐帧抖动；慢速（含收尾）直接归零 → σ 确定地回到 1.0。
      _speed = v < _stopEpsilon ? 0.0 : _speed * 0.55 + v * 0.45;
    }
    _lastFrame = now;
    _lastOffset = offset;
    final target = 1.0 - (1.0 - minScale) * (_speed / vRef).clamp(0.0, 1.0);
    // 量化到 0.05 档：MiFilterCache 以 σ 为键，连续值会让每帧新建 native
    // filter（快速滑动丢帧主因）。
    final snapped = (target * 20).roundToDouble() / 20;
    if (snapped != value) value = snapped;
    // 值量化只护 filter 缓存；**通知仍逐滚动事件** —— 亮边（rimProgress）
    // 这类滚动位置派生量要逐帧刷新。若只在换档时通知，极快滑动时 σ 饱和
    // 在同一档不再换档 → 亮边冻在旧值（实机反馈：快滑不暗、轻碰才变）。
    notifyListeners();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onScroll);
    super.dispose();
  }
}


/// 首页（参考页形态）：**悬浮头部 + 顶部横幅 + 区块列表**。
///
/// 结构照亮/暗两张完整截图（881×1920）：
///  * 顶部是一条**高频横幅**（[_HeroBanner]，底缘圆角 20dp），从屏幕最顶端
///    （含状态栏后面）铺到度量 ~186dp；
///  * 搜索栏 + 胶囊标签行**悬浮**在横幅上（[MiTopBar] 头部区形态，由顶栏
///    自己产出两个组件），页面只给数据；
///  * 列表**上内边距为 0** —— 横幅与下方区块一起从头部后方滚过，那条渐进
///    磨砂（顶强底弱、羽化收尾）才有东西可糊（这正是本页要演示的效果）；
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

  /// 「滚动降 σ」实时驱动器（σ 缩放随速度连续变化，见 [_ScrollSigma]）。
  final _ScrollSigma _sigma = _ScrollSigma();

  @override
  void initState() {
    super.initState();
    _sigma.attach(_scroll);
  }

  @override
  void dispose() {
    _sigma.dispose();
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
    // 页边距），磨砂是**渐进磨砂的整条栏**（顶部最糊、向下衰减、胶囊行底
    // 羽化收尾；1220×2656 明暗双素材实测，见 MiHeaderBlurProfile）。
    // `overContent: true` —— 横幅从 y=0 起铺、从头部下方滚过，搜索栏与未选
    // 胶囊要铺那层玻璃膜才读得出来（参考素材度量，见 MiTransparencyTokens）。
    //
    // σ 缩放随滚动速度实时渐变（[_ScrollSigma]）：只重建顶栏这一棵子树。
    final bar = ValueListenableBuilder<double>(
      valueListenable: _sigma,
      builder: (context, sigmaScale, _) => MiTopBar(
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
      // 滚动降 σ：随速度实时渐变（0.6…1.0，见 _ScrollSigma）。
      sigmaScale: sigmaScale,
      // 滚动偏移驱动内缘亮边的渐亮（rimProgress，见 MiTopBarMetrics）。
      scrollOffset: _scroll.hasClients ? _scroll.offset : 0,
      tabs: _tabs,
      selectedTab: _tab,
      onTabChanged: (i) => setState(() => _tab = i),
      showSurface: false,
      overContent: true,
      ),
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
