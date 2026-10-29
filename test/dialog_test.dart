import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// 卡片本体：`MiDialog` 里唯一的 [ClipPath]（按钮是圆角 ShapeDecoration 不裁剪）。
Finder _card() => find.byType(ClipPath);

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
      // 明暗切换时填充同样走 150ms 补间（AnimatedContainer），等它落定再读渲染值
      await tester
          .pump(const Duration(milliseconds: MiDialogMetrics.pressDurationMs));

      // 卡片填充
      final cardDecoration = tester
          .widget<DecoratedBox>(
            find.ancestor(of: _card(), matching: find.byType(DecoratedBox)),
          )
          .decoration as ShapeDecoration;
      expect(cardDecoration.color, palette.surface);
      // 圆角 49.3（实测，连续圆角名义半径）
      expect(
        (cardDecoration.shape as MiSquircleBorder).cornerRadius,
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
              .decoration as ShapeDecoration)
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

  testWidgets('按压：填充 150ms 过渡到压色、松开回弹；禁用无反馈', (tester) async {
    _useReferenceCanvas(tester);
    for (final mode in MiThemeMode.values) {
      final palette = MiDialogPalette.of(mode);
      await tester.pumpWidget(_harness(
        mode: mode,
        actions: const [
          MiDialogAction(
            label: '确定',
            style: MiDialogActionStyle.filled,
            onPressed: _noop,
          ),
          MiDialogAction(label: '删除', style: MiDialogActionStyle.destructive),
        ],
      ));
      await tester.pump();

      Color? fillOf(String label) => (tester
              .widget<AnimatedContainer>(find
                  .ancestor(
                    of: find.text(label),
                    matching: find.byType(AnimatedContainer),
                  )
                  .first)
              .decoration as ShapeDecoration)
          .color;

      // 静止填充
      expect(fillOf('确定'), palette.filledActionFill);

      // 按下 → 150ms 过渡到压色（填充叠色、标签不变）
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('确定')));
      await tester.pump();
      await tester
          .pump(const Duration(milliseconds: MiDialogMetrics.pressDurationMs));
      expect(
        fillOf('确定'),
        MiTransparencyTokens.dialogPressedFill(
          palette.filledActionFill,
          mode,
        ),
      );

      // 松开 → 回弹（镜像同值）
      await gesture.up();
      await tester.pump();
      await tester
          .pump(const Duration(milliseconds: MiDialogMetrics.pressDurationMs));
      expect(fillOf('确定'), palette.filledActionFill);

      // 禁用（onPressed null）：按下不进压色
      final disabled =
          await tester.startGesture(tester.getCenter(find.text('删除')));
      await tester.pump();
      await tester
          .pump(const Duration(milliseconds: MiDialogMetrics.pressDurationMs));
      expect(fillOf('删除'), palette.neutralActionFill);
      await disabled.up();
    }
  });

  testWidgets('压色配方：亮 = 黑 @0.12 压、暗 = 白 @0.12 提（实测 + 推导）', (tester) async {
    int ch(double v) => (v * 255).round();
    // 亮色实测：蓝填充 (51,131,255) → ×0.88 ≈ (45,115,224)（录屏读数 (46,113,226)）
    final pressedLight = MiTransparencyTokens.dialogPressedFill(
      const Color(0xFF3383FF),
      MiThemeMode.light,
    );
    expect(ch(pressedLight.r), inInclusiveRange(43, 48));
    expect(ch(pressedLight.g), inInclusiveRange(112, 118));
    expect(ch(pressedLight.b), inInclusiveRange(221, 228));
    // 暗色推导：同一 state layer 反向提亮
    final pressedDark = MiTransparencyTokens.dialogPressedFill(
      const Color(0xFF434343),
      MiThemeMode.dark,
    );
    expect(ch(pressedDark.r), inInclusiveRange(85, 94));
  });

  testWidgets('桌面语义（推导）：按钮可悬停出叠色、聚焦出环、Enter 激活', (tester) async {
    _useReferenceCanvas(tester);
    var tapped = 0;
    await tester.pumpWidget(
      _harness(
        mode: MiThemeMode.dark,
        actions: [MiDialogAction(label: '确定', onPressed: () => tapped++)],
      ),
    );
    await tester.pump();

    // 悬停（鼠标进入按钮）→ 叠色 = 按压高光的 60%（桌面推导语义）
    final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await hover.addPointer(location: tester.getCenter(find.text('确定')));
    await tester.pump();
    final overlay = tester.widget<AnimatedContainer>(
      find.byKey(MiHoverFeedback.overlayKey).first,
    );
    expect(
      (overlay.decoration! as BoxDecoration).color,
      MiTransparencyTokens.hoverOverlayFor(MiThemeMode.dark),
    );
    await hover.removePointer();
    await tester.pumpAndSettle();

    // 聚焦（等价 Tab 走到）→ 环；Enter 激活 → onPressed
    tester
        .widget<Focus>(
          find.descendant(
            of: find.byType(MiFocusRing),
            matching: find.byType(Focus),
          ),
        )
        .focusNode!
        .requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final ring = tester.widget<AnimatedContainer>(
      find.byKey(MiFocusRing.ringKey).first,
    );
    expect(
      (ring.decoration! as BoxDecoration).border!.top.color,
      isNot(Colors.transparent),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(tapped, 1);
  });

  group('宽屏档（桌面 ≥1024：居中窄卡，推导值）', () {
    test('常量：440 上限 / 16 圆角 / 阈值与桌面断点同值', () {
      expect(MiDialogMetrics.wideCardMaxWidth, 440);
      expect(MiDialogMetrics.wideCardRadius, 16);
      expect(MiDialogMetrics.isWide(1023), isFalse);
      expect(MiDialogMetrics.isWide(1024), isTrue);
      // 手机档度量不变
      expect(MiDialogMetrics.cardWidth, 369.2);
      expect(MiDialogMetrics.cardRadius, 49.3);
    });

    testWidgets('桌面窗口：卡片居中、限宽 440、圆角 16（position 被忽略）',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      // 故意传 bottom 位置 —— 桌面档强制居中
      tester.view.physicalSize = const Size(1366, 768);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _harness(position: MiDialogPosition.bottom, message: '单行正文'),
      );
      await tester.pumpAndSettle();

      final card = tester.getRect(_card());
      expect(card.width, moreOrLessEquals(440, epsilon: 0.5),
          reason: '桌面档卡片限宽 440');
      expect(card.center.dx, moreOrLessEquals(1366 / 2, epsilon: 0.5),
          reason: '水平居中');
      expect(card.center.dy, moreOrLessEquals(768 / 2, epsilon: 0.5),
          reason: '垂直居中（position: bottom 被忽略）');

      final clip = tester.widget<ClipPath>(_card());
      expect((clip.clipper as MiSquircleClipper).radius, 16);
    });

    testWidgets('受限容器（460 宽）：卡片收到容器可用宽内（不溢出）', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1366, 768);
      addTearDown(tester.view.reset);

      // 弹框挂在 460 宽的容器里（窗口够宽但容器窄 —— 分屏 / 侧栏内嵌）：
      // 判定走**容器宽**，460 < 1024 → 手机档；卡片 = 容器宽 − 2×边距，
      // 不溢出容器。直接构建 MiDialog（不能套 _harness —— 它内含 MaterialApp，
      // 嵌套后内层会撑满窗口）。
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF000000),
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 460,
                height: 768,
                child: MiDialog(
                  themeMode: MiThemeMode.dark,
                  message: '单行正文',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = tester.getRect(_card());
      expect(
        card.width,
        moreOrLessEquals(460 - 2 * MiDialogMetrics.sideMargin, epsilon: 0.5),
        reason: '窄容器里卡片收到可用宽内（不溢出容器）',
      );
      expect(card.left, moreOrLessEquals(MiDialogMetrics.sideMargin, epsilon: 0.5));
    });

    testWidgets('平板窗口（768）：仍是手机档贴底卡（阈值以下不变）', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(768, 1280);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness(message: '单行正文'));
      await tester.pumpAndSettle();

      final card = tester.getRect(_card());
      // 手机档：卡片撑满边距之间（768 − 2×11.9 = 744.2）—— 与既有行为一致，
      // 不因桌面档改动而 clamp。
      expect(
        card.width,
        moreOrLessEquals(768 - 2 * MiDialogMetrics.sideMargin, epsilon: 0.5),
        reason: '平板仍走手机档（撑满边距之间）',
      );
      // bottom 位置：底缘距屏底 32.9
      expect(
        1280 - card.bottom,
        moreOrLessEquals(MiDialogMetrics.edgeInset, epsilon: 0.5),
      );
      final clip = tester.widget<ClipPath>(_card());
      expect((clip.clipper as MiSquircleClipper).radius, 49.3);
    });
  });
}

void _noop() {}
