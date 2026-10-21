import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel。
import 'package:mi_like_ui/mi_like_ui.dart';

/// 弹框测试画布：参考机 393×856。
void _useReferenceCanvas(WidgetTester tester) {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = const Size(393 * 2, 856 * 2);
  addTearDown(tester.view.reset);
}

/// 弹框测试外壳：393×856 画布 + 一层 mock 底（弹框自带遮罩）。
Widget _harness({
  MiThemeMode mode = MiThemeMode.dark,
  MiDialogPosition position = MiDialogPosition.bottom,
  String? title = '删除联系人',
  String? message = '第一行正文\n第二行正文',
  TextAlign messageAlign = TextAlign.center,
  List<MiDialogAction> actions = const [],
  VoidCallback? onScrimTap,
}) {
  return MaterialApp(
    theme: mode == MiThemeMode.light
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true),
    home: Scaffold(
      backgroundColor:
          mode == MiThemeMode.light ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
      body: MiDialog(
        title: title,
        message: message,
        actions: actions,
        position: position,
        messageAlign: messageAlign,
        themeMode: mode,
        onScrimTap: onScrimTap,
      ),
    ),
  );
}

/// 卡片本体：`MiDialog` 里唯一的 [ClipRRect]（按钮是圆角 DecoratedBox 不裁剪）。
Finder _card() => find.byType(ClipRRect);

void main() {
  test('默认形态：位置=底部、对齐=居中、无按钮', () {
    const dialog = MiDialog();
    expect(dialog.position, MiDialogPosition.bottom);
    expect(dialog.messageAlign, TextAlign.center);
    expect(dialog.actions, isEmpty);
  });

  testWidgets('几何：卡片宽 369.2 / 双行高 207.0 / 底缘距屏底 32.9', (tester) async {
    _useReferenceCanvas(tester);
    await tester.pumpWidget(_harness(
      actions: const [MiDialogAction(label: '取消')],
    ));
    await tester.pump();

    final card = tester.getSize(_card());
    expect(card.width, closeTo(MiDialogMetrics.cardWidth, 0.05)); // 369.2
    expect(card.height, closeTo(207.0, 0.05)); // 133.0 + 49.9 + 24.1
    final topLeft = tester.getTopLeft(_card());
    expect(topLeft.dx, closeTo(MiDialogMetrics.sideMargin, 0.05)); // 11.9
    expect(topLeft.dy, closeTo(856 - 32.9 - 207.0, 0.05));
    final bottomLeft = tester.getBottomLeft(_card());
    expect(bottomLeft.dy, closeTo(856 - MiDialogMetrics.edgeInset, 0.05));
  });

  testWidgets('几何：单行正文矮一行距 23.2、按钮行同步上移', (tester) async {
    _useReferenceCanvas(tester);
    await tester.pumpWidget(_harness(
      message: '单行正文',
      actions: const [MiDialogAction(label: '取消')],
    ));
    await tester.pump();

    expect(tester.getSize(_card()).height, closeTo(207.0 - 23.2, 0.05));
  });

  testWidgets('位置三档：top 镜像 32.9、center 垂直居中', (tester) async {
    _useReferenceCanvas(tester);

    await tester.pumpWidget(_harness(position: MiDialogPosition.top));
    await tester.pump();
    expect(
      tester.getTopLeft(_card()).dy,
      closeTo(MiDialogMetrics.edgeInset, 0.05),
    );

    await tester.pumpWidget(_harness(position: MiDialogPosition.center));
    await tester.pump();
    final h = tester.getSize(_card()).height;
    expect(
      tester.getTopLeft(_card()).dy,
      closeTo((856 - h) / 2, 0.05),
    );
  });

  testWidgets('墨心钉点：标题/正文/按钮标签基线 = 墨心 + 0.355em', (tester) async {
    _useReferenceCanvas(tester);
    await tester.pumpWidget(_harness(
      actions: const [MiDialogAction(label: '取消')],
    ));
    await tester.pump();

    final baselines = tester
        .widgetList<Baseline>(find.byType(Baseline))
        .toList(growable: false);
    expect(baselines, hasLength(3)); // 标题、正文、按钮标签
    // 实测墨心：标题 36.4 / 正文首行 75.55 / 按钮标签 = 盒心 24.95。
    expect(
      baselines[0].baseline,
      closeTo(36.4 + 0.355 * 18.0, 0.01),
    );
    expect(
      baselines[1].baseline,
      closeTo(75.55 + 0.355 * 15.9, 0.01),
    );
    expect(
      baselines[2].baseline,
      closeTo(49.9 / 2 + 0.355 * 15.9, 0.01),
    );
  });

  testWidgets('配色：卡片 / 遮罩 / 三种按钮形态随明暗走 palette', (tester) async {
    _useReferenceCanvas(tester);
    for (final mode in MiThemeMode.values) {
      final palette = MiDialogPalette.of(mode);
      await tester.pumpWidget(_harness(
        mode: mode,
        actions: const [
          MiDialogAction(label: '取消'),
          MiDialogAction(label: '确定', style: MiDialogActionStyle.filled),
          MiDialogAction(
            label: '删除',
            style: MiDialogActionStyle.destructive,
            onPressed: _noop,
          ),
        ],
      ));
      await tester.pump();

      // 卡片填充
      final cardDecoration = tester
          .widget<DecoratedBox>(
            find.ancestor(of: _card(), matching: find.byType(DecoratedBox)),
          )
          .decoration as BoxDecoration;
      expect(cardDecoration.color, palette.surface);
      // 圆角 49.3（实测）
      expect(
        (cardDecoration.borderRadius as BorderRadius).topLeft.x,
        closeTo(MiDialogMetrics.cardRadius, 0.01),
      );
      // 遮罩（MiDialog 内唯一的 ColoredBox）
      expect(
        tester
            .widget<ColoredBox>(find.descendant(
              of: find.byType(MiDialog),
              matching: find.byType(ColoredBox),
            ))
            .color,
        palette.scrim,
      );
      // 按钮填充
      Color? fillOf(String label) => (tester
              .widget<DecoratedBox>(find
                  .ancestor(
                    of: find.text(label),
                    matching: find.byType(DecoratedBox),
                  )
                  .first)
              .decoration as BoxDecoration)
          .color;
      expect(fillOf('取消'), palette.neutralActionFill);
      expect(fillOf('确定'), palette.filledActionFill);
      expect(fillOf('删除'), palette.neutralActionFill);
      // 按钮标签色
      Color? labelOf(String label) =>
          tester.widget<Text>(find.text(label)).style?.color;
      expect(labelOf('取消'), palette.secondaryText);
      expect(labelOf('确定'), palette.filledActionLabel);
      expect(labelOf('删除'), palette.destructiveActionLabel);
    }
  });

  testWidgets('行数解算：\\n 强制换行按行距 23.2 增高，宽文本自动换行', (tester) async {
    _useReferenceCanvas(tester);
    await tester.pumpWidget(_harness(
      message: '一二三\n四五六\n七',
      actions: const [MiDialogAction(label: '取消')],
    ));
    await tester.pump();
    // 3 行 = 双行实测 207.0 + 一行距
    expect(tester.getSize(_card()).height, closeTo(207.0 + 23.2, 0.05));

    // 参考图原文（22 字，正文框宽 313.2）至少换行一次 —— 具体断点随字体，
    // 只锁「不是单行」（单行高 183.8、双行 207.0）。
    await tester.pumpWidget(_harness(
      message: '确定从本地和云端同时删除“方太安装师傅”吗？',
      actions: const [MiDialogAction(label: '取消')],
    ));
    await tester.pump();
    expect(tester.getSize(_card()).height, greaterThan(183.8 + 1));
  });

  testWidgets('行为：按钮点按触发回调、null 不触发、遮罩点按触发 onScrimTap', (tester) async {
    _useReferenceCanvas(tester);
    var tapped = 0;
    var scrimTapped = 0;
    await tester.pumpWidget(_harness(
      onScrimTap: () => scrimTapped++,
      actions: [
        MiDialogAction(label: '取消', onPressed: () => tapped++),
        const MiDialogAction(label: '确定', onPressed: _noop),
        const MiDialogAction(label: '删除'),
      ],
    ));
    await tester.pump();

    await tester.tap(find.text('取消'));
    expect(tapped, 1);
    await tester.tap(find.text('确定'));
    expect(tapped, 1); // _noop 不改计数
    await tester.tap(find.text('删除')); // onPressed null：不崩、不触发
    expect(tapped, 1);

    // 遮罩点按（点卡片外的角落）
    await tester.tapAt(const Offset(20, 20));
    expect(scrimTapped, 1);
  });

  testWidgets('位置/对齐透传：start 正文左对齐（联系人弹框形态）', (tester) async {
    _useReferenceCanvas(tester);
    await tester.pumpWidget(_harness(
      messageAlign: TextAlign.start,
      message: '确定从本地和云端同时删除“方太安装师傅”吗？',
    ));
    await tester.pump();

    final text = tester.widget<Text>(
      find.descendant(of: find.byType(MiDialog), matching: find.textContaining('确定从本地')),
    );
    expect(text.textAlign, TextAlign.start);
  });
}

void _noop() {}
