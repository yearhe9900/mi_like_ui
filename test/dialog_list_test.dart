import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel。
import 'package:mi_like_ui/mi_like_ui.dart';

/// 弹框测试画布：参考机 393×856（clamp 用例另设矮画布）。
void _useReferenceCanvas(WidgetTester tester, {double height = 856}) {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = Size(393 * 2, height * 2);
  addTearDown(tester.view.reset);
}

/// 操作列表测试外壳：393×856 画布 + 一层 mock 底（弹框自带遮罩）。
Widget _harness({
  MiThemeMode mode = MiThemeMode.dark,
  MiDialogLayout layout = MiDialogLayout.list,
  String? title = '图书操作',
  String? message,
  List<MiDialogItem> items = const [],
  List<MiDialogAction> actions = const [],
  VoidCallback? onScrimTap,
}) {
  return MaterialApp(
    theme: mode == MiThemeMode.light
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true),
    home: Scaffold(
      backgroundColor: mode == MiThemeMode.light
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF000000),
      body: MiDialog(
        layout: layout,
        title: title,
        message: message,
        messageAlign: TextAlign.start,
        items: items,
        actions: actions,
        themeMode: mode,
        onScrimTap: onScrimTap,
      ),
    ),
  );
}

/// 卡片本体：`MiDialog` 里唯一的 [ClipPath]。
Finder _card() => find.byType(ClipPath);

/// 列表行容器（带定高的 AnimatedContainer —— 按钮行那只是无约束的）。
Finder _rows() => find.descendant(
      of: find.byType(MiDialog),
      matching: find.byWidgetPredicate(
        (w) => w is AnimatedContainer && w.constraints != null,
      ),
    );

/// 两行左对齐标题（30 个 CJK 字，参考机上必 ≥ 2 行；上限 2 行 + ellipsis）。
const String _twoLineTitle =
    '一二三四五六七八九十一二三四五六七八九十一二三四五六七八九十';

/// 参考操作单（下游 MReader 形态）：项 1 无副标题，项 3 危险项。
List<MiDialogItem> _items({VoidCallback? onOne, VoidCallback? onTwo}) => [
      MiDialogItem(
        label: '收藏到书架',
        icon: const Icon(Icons.star_outline, size: 22),
        onPressed: onOne ?? _noop,
      ),
      MiDialogItem(
        label: '下载到本地',
        subtitle: '离线阅读',
        icon: const Icon(Icons.download_outlined, size: 22),
        onPressed: onTwo ?? _noop,
      ),
      const MiDialogItem(
        label: '删除',
        subtitle: '删除本地文件',
        destructive: true,
        icon: Icon(Icons.delete_outline, size: 22),
      ),
    ];

void main() {
  test('默认形态：layout=buttons、items 空；条目默认非危险', () {
    const dialog = MiDialog();
    expect(dialog.layout, MiDialogLayout.buttons);
    expect(dialog.items, isEmpty);
    expect(const MiDialogItem(label: '项').destructive, isFalse);
  });

  test('度量常量（全推导值，见 MiDialogListMetrics 类注释）', () {
    // 行高：无副标题 = 2×12 + max(23.2, 22)；有副标题 = 2×12 + 23.2 + 3 + 18
    expect(
      MiDialogListMetrics.rowHeight(hasSubtitle: false),
      closeTo(47.2, 0.001),
    );
    expect(
      MiDialogListMetrics.rowHeight(hasSubtitle: true),
      closeTo(68.2, 0.001),
    );
    expect(MiDialogListMetrics.titleLinePitch, 23.0);
    expect(MiDialogListMetrics.titleMaxLines, 2);
    // 墨心/基线换算沿用弹框口径（墨心 + 0.355em）
    expect(
      MiDialogListMetrics.labelBaseline,
      closeTo(23.6 + 0.355 * 15.9, 0.01),
    );
    expect(
      MiDialogListMetrics.subtitleBaseline,
      closeTo(47.2 + 0.355 * 13.0, 0.01),
    );
    expect(MiDialogListMetrics.iconTopY, closeTo(12.6, 0.001));
    // 列表顶：两行标题（墨心 36.4 / 59.4）+ 上距 18
    expect(
      MiDialogListMetrics.listTopFor(titleLines: 2, messageLines: 0),
      closeTo(77.4, 0.001),
    );
    // 标题 + 双行正文：正文末行墨心 98.75 + 上距 18
    expect(
      MiDialogListMetrics.listTopFor(titleLines: 1, messageLines: 2),
      closeTo(116.75, 0.001),
    );
    expect(
      MiDialogListMetrics.listTopFor(titleLines: 0, messageLines: 0),
      MiDialogListMetrics.listPadTop,
    );
    // clamp 下限与滚动区基线（新增到既有度量，不动旧值）
    expect(MiDialogMetrics.minCardHeight, 120.0);
    expect(MiDialogMetrics.messageScrollBaseline, closeTo(17.24, 0.01));
    // 分隔线配色：onSurface @0.08（推导值，走统一透明 token）
    expect(
      MiDialogPalette.of(MiThemeMode.light).divider,
      MiTransparencyTokens.dialogDividerLight,
    );
    expect(
      MiDialogPalette.of(MiThemeMode.dark).divider,
      MiTransparencyTokens.dialogDividerDark,
    );
  });

  testWidgets('几何：两行标题 + 三项 + 按钮行（先算后摆，全部对上公式）',
      (tester) async {
    _useReferenceCanvas(tester);
    await tester.pumpWidget(_harness(
      title: _twoLineTitle,
      items: _items(),
      actions: const [MiDialogAction(label: '取消')],
    ));
    await tester.pump();

    // 行区 = 47.2 + 1 + 68.2 + 1 + 68.2
    const rowsHeight = 47.2 + 1 + 68.2 + 1 + 68.2;
    // 卡高 = 列表顶 77.4 + 行区 + 列表-按钮间隙 20 + 按钮区（49.9 + 24.1）
    const cardHeight = 77.4 + rowsHeight + 20 + 49.9 + 24.1; // = 357.0

    final card = tester.getSize(_card());
    expect(card.width, closeTo(MiDialogMetrics.cardWidth, 0.05));
    expect(card.height, closeTo(cardHeight, 0.05));
    final cardTop = tester.getTopLeft(_card()).dy;
    expect(cardTop, closeTo(856 - 32.9 - cardHeight, 0.05));

    // 行区起点 = 列表顶（卡顶起 77.4），行高 47.2 / 68.2 / 68.2
    expect(
      tester.getTopLeft(_rows().at(0)).dy,
      closeTo(cardTop + 77.4, 0.05),
    );
    final rowHeights = [
      for (var i = 0; i < 3; i++) tester.getSize(_rows().at(i)).height,
    ];
    expect(rowHeights, hasLength(3));
    expect(rowHeights[0], closeTo(47.2, 0.05));
    expect(rowHeights[1], closeTo(68.2, 0.05));
    expect(rowHeights[2], closeTo(68.2, 0.05));
    for (var i = 0; i < 3; i++) {
      expect(
        tester.getSize(_rows().at(i)).width,
        closeTo(MiDialogMetrics.cardWidth, 0.05),
      );
    }
  });

  testWidgets('行内落位：图标 22 盒、主/副文案基线锚定、图标列全员让位',
      (tester) async {
    _useReferenceCanvas(tester);
    await tester.pumpWidget(_harness(
      title: _twoLineTitle,
      items: _items(),
      actions: const [MiDialogAction(label: '取消')],
    ));
    await tester.pump();

    final cardTop = tester.getTopLeft(_card()).dy;
    final cardLeft = tester.getTopLeft(_card()).dx; // 手机档边距 11.9
    final firstRowTop = cardTop + 77.4;

    // 图标盒：行内缩 20、盒顶 = 行顶 + 12.6、边长 22
    final iconTopLeft = tester.getTopLeft(find.byIcon(Icons.star_outline));
    expect(iconTopLeft.dx, closeTo(cardLeft + 20, 0.05));
    expect(iconTopLeft.dy, closeTo(firstRowTop + 12.6, 0.05));
    expect(tester.getSize(find.byIcon(Icons.star_outline)).width, closeTo(22, 0.05));

    // 文字列让出图标位（三项都带图标 → 全员对齐 56）
    expect(
      tester.getTopLeft(find.text('收藏到书架')).dx,
      closeTo(cardLeft + 20 + 22 + 14, 0.05),
    );
    expect(
      tester.getTopLeft(find.text('删除')).dx,
      closeTo(cardLeft + 20 + 22 + 14, 0.05),
    );

    // 行内 Baseline：主文案 23.6 + 0.355em、副标题 47.2 + 0.355em（行顶起算）
    final rowBaselines = tester
        .widgetList<Baseline>(
          find.descendant(of: _rows(), matching: find.byType(Baseline)),
        )
        .toList(growable: false);
    expect(rowBaselines, hasLength(5)); // 1 主 + (1 主 + 1 副) + (1 主 + 1 副)
    expect(
      rowBaselines[0].baseline,
      closeTo(23.6 + 0.355 * 15.9, 0.01),
    );
    expect(
      rowBaselines[2].baseline,
      closeTo(47.2 + 0.355 * 13.0, 0.01),
    );

    // 无图标条目：文字列贴行内缩 20
    await tester.pumpWidget(_harness(items: const [
      MiDialogItem(label: '无图标项', subtitle: '副标题'),
    ]));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('无图标项')).dx,
      closeTo(cardLeft + 20, 0.05),
    );
    expect(
      tester.getTopLeft(find.text('副标题')).dx,
      closeTo(cardLeft + 20, 0.05),
    );
  });

  testWidgets('标题：列表形态左对齐最多两行（行距 23.0 并进 height）',
      (tester) async {
    _useReferenceCanvas(tester);
    await tester.pumpWidget(_harness(
      title: _twoLineTitle,
      items: const [MiDialogItem(label: '项')],
    ));
    await tester.pump();

    final title = tester.widget<Text>(find.text(_twoLineTitle));
    expect(title.maxLines, MiDialogListMetrics.titleMaxLines);
    expect(title.textAlign, TextAlign.start);
    expect(
      title.style?.height,
      closeTo(MiDialogListMetrics.titleLinePitch / 18.0, 0.0001),
    );
    // 首行墨心仍是度量 36.4（Baseline 钉基线）
    final titleBaseline = tester
        .widgetList<Baseline>(
          find.descendant(of: find.byType(MiDialog), matching: find.byType(Baseline)),
        )
        .first;
    expect(
      titleBaseline.baseline,
      closeTo(36.4 + 0.355 * 18.0, 0.01),
    );
    // 副标题单行 + ellipsis
    await tester.pumpWidget(_harness(
      items: const [MiDialogItem(label: '项', subtitle: '副')],
    ));
    await tester.pump();
    final sub = tester.widget<Text>(find.text('副'));
    expect(sub.maxLines, 1);
    expect(sub.overflow, TextOverflow.ellipsis);
  });

  testWidgets('配色：行主文案 / 副标题 / 危险项整行红字 / 分隔线随明暗',
      (tester) async {
    _useReferenceCanvas(tester);
    for (final mode in MiThemeMode.values) {
      final palette = MiDialogPalette.of(mode);
      await tester.pumpWidget(_harness(
        mode: mode,
        title: _twoLineTitle,
        items: _items(),
        actions: const [MiDialogAction(label: '取消')],
      ));
      await tester.pump(const Duration(
        milliseconds: MiDialogMetrics.pressDurationMs,
      ));

      Color? labelOf(String text) =>
          tester.widget<Text>(find.text(text)).style?.color;
      // 常规项：主文案 = 标题墨色，副标题 = 次级文字
      expect(labelOf('收藏到书架'), palette.title);
      expect(labelOf('离线阅读'), palette.secondaryText);
      // 危险项：整行（主 + 副）红字
      expect(labelOf('删除'), palette.destructiveActionLabel);
      expect(labelOf('删除本地文件'), palette.destructiveActionLabel);
      // 图标色走 IconTheme（随行墨色 / 危险色）
      Iterable<Color?> iconThemeColors(IconData icon) => tester
          .widgetList<IconTheme>(
            find.ancestor(
              of: find.byIcon(icon),
              matching: find.byType(IconTheme),
            ),
          )
          .map((w) => w.data.color);
      expect(iconThemeColors(Icons.star_outline), contains(palette.title));
      expect(
        iconThemeColors(Icons.delete_outline),
        contains(palette.destructiveActionLabel),
      );

      // 分隔线：两道、1dp、左右内缩 20、色取 palette.divider
      final dividers = find.descendant(
        of: find.byType(MiDialog),
        matching: find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == palette.divider,
        ),
      );
      expect(dividers, findsNWidgets(2));
      expect(tester.getSize(dividers.first).height, closeTo(1, 0.05));
      expect(tester.getSize(dividers.first).width, closeTo(369.2 - 40, 0.05));
    }
  });

  testWidgets('行为：点按触发 / null 不触发 / 遮罩点按；按压整行叠压色回弹',
      (tester) async {
    _useReferenceCanvas(tester);
    var one = 0;
    var two = 0;
    var scrimTapped = 0;
    await tester.pumpWidget(_harness(
      title: _twoLineTitle,
      items: _items(onOne: () => one++, onTwo: () => two++),
      actions: const [MiDialogAction(label: '取消')],
      onScrimTap: () => scrimTapped++,
    ));
    await tester.pump();

    await tester.tap(find.text('收藏到书架'));
    expect(one, 1);
    await tester.tap(find.text('离线阅读')); // 副标题也在同一行热区
    expect(two, 1);
    await tester.tap(find.text('删除')); // onPressed null：不崩、不触发
    expect(one, 1);
    await tester.tapAt(const Offset(8, 8));
    expect(scrimTapped, 1);

    // 按压：整行叠按压色（压在卡片填充上），150ms 落定、松开回弹
    for (final mode in MiThemeMode.values) {
      final palette = MiDialogPalette.of(mode);
      await tester.pumpWidget(_harness(
        title: _twoLineTitle,
        items: _items(),
        mode: mode,
      ));
      await tester.pump();

      Color? fillOf(String label) => (
            tester
                .widget<AnimatedContainer>(
                  find.ancestor(of: find.text(label), matching: _rows()).first,
                )
                .decoration as BoxDecoration
              )
              .color;

      expect(fillOf('收藏到书架'), palette.surface);
      final gesture = await tester
          .startGesture(tester.getCenter(find.text('收藏到书架')));
      await tester.pump();
      await tester
          .pump(const Duration(milliseconds: MiDialogMetrics.pressDurationMs));
      expect(
        fillOf('收藏到书架'),
        MiTransparencyTokens.dialogPressedFill(palette.surface, mode),
      );
      await gesture.up();
      await tester
          .pump(const Duration(milliseconds: MiDialogMetrics.pressDurationMs));
      expect(fillOf('收藏到书架'), palette.surface);
    }
  });

  testWidgets('含正文：正文末行墨心 + 18 起列表（静止几何）', (tester) async {
    _useReferenceCanvas(tester);
    await tester.pumpWidget(_harness(
      title: '图书操作',
      message: '第一行正文\n第二行正文',
      items: _items(),
      actions: const [MiDialogAction(label: '取消')],
    ));
    await tester.pump();

    // 列表顶 = 75.55 + 23.2 + 18 = 116.75；卡高 = 116.75 + 185.6 + 20 + 74
    const cardHeight = 116.75 + 185.6 + 20 + 49.9 + 24.1;
    expect(tester.getSize(_card()).height, closeTo(cardHeight, 0.05));
    expect(
      tester.getTopLeft(_rows().first).dy,
      closeTo(tester.getTopLeft(_card()).dy + 116.75, 0.05),
    );
  });

  testWidgets('高度 clamp：超长列表压回屏内、列表区转滚动（issue #1）',
      (tester) async {
    // 矮画布 393×360：可用高 = 360 − 2×32.9 = 294.2
    _useReferenceCanvas(tester, height: 360);
    await tester.pumpWidget(_harness(
      title: '图书操作',
      items: [
        for (var i = 0; i < 8; i++)
          MiDialogItem(label: '项$i', subtitle: '说明$i'),
      ],
    ));
    await tester.pump();

    // 期望高 = 54.4 + 8×68.2 + 7×1 + 20 = 627 → clamp 到 294.2
    final card = tester.getSize(_card());
    expect(card.height, closeTo(360 - 2 * 32.9, 0.05));
    // 卡片仍在屏内：顶 32.9、底 32.9
    expect(tester.getTopLeft(_card()).dy, closeTo(32.9, 0.05));
    expect(360 - tester.getBottomLeft(_card()).dy, closeTo(32.9, 0.05));
    // 列表区转为内部滚动
    expect(
      find.descendant(
        of: find.byType(MiDialog),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
  });

  testWidgets('高度 clamp：超长正文不再顶出屏、正文区转滚动、按钮钉卡底',
      (tester) async {
    _useReferenceCanvas(tester, height: 360);
    await tester.pumpWidget(_harness(
      layout: MiDialogLayout.buttons,
      title: '删除联系人',
      // 20 行正文：期望高 133 + 18×23.2 + 49.9 + 24.1 = 614.6
      message: [for (var i = 0; i < 20; i++) '第$i行'].join('\n'),
      actions: const [MiDialogAction(label: '取消')],
    ));
    await tester.pump();

    final card = tester.getSize(_card());
    expect(card.height, closeTo(360 - 2 * 32.9, 0.05));
    // 正文区滚动
    expect(
      find.descendant(
        of: find.byType(MiDialog),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    // 按钮行钉在卡底：盒顶 = 卡底 − 下留白 24.1 − 按钮高 49.9
    final cardTop = tester.getTopLeft(_card()).dy;
    final cancelButton = tester
        .getTopLeft(
          find.ancestor(of: find.text('取消'), matching: find.byType(AnimatedContainer)).first,
        )
        .dy;
    expect(
      cancelButton,
      closeTo(cardTop + card.height - 24.1 - 49.9, 0.05),
    );
  });
}

void _noop() {}
