part of '../mock_pages.dart';



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
