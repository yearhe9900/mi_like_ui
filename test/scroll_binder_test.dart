import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mi_like_ui/mi_like_ui.dart';

/// 滚动接线（MiScrollBinder + MiTopBar.scrollOffset 自动读取）回归。
///
/// 判据约定：
///  * 页面包 [MiScrollBinder] 后，`MiTopBar` 不传 `scrollOffset` 也随滚动
///    折叠（大标题淡出、位移 1:1 联动）—— 免去逐页 NotificationListener
///    样板；
///  * 只认 depth == 0 且同方向的滚动：嵌套滚动体（depth ≥ 1）与反方向
///    滚动体（横向胶囊行）不驱动竖向折叠；
///  * 显式 `scrollOffset` 压过作用域（滚动降 σ 等需要集中两个滚动量的
///    页面仍手写接线）；
///  * 无作用域且未传参 = 旧行为（未滚动，逐像素不变）。
void main() {
  /// 大标题的位移探针：取**大标题**（31.83dp）Text 的 y（折叠时上移）。
  /// 紧凑标题同文案不同字号，靠字号区分两个 finder。
  double largeTitleY(WidgetTester tester) => tester.getTopLeft(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.data == '显示与亮度' &&
              (w.style?.fontSize ?? 0) > 24,
        ),
      ).dy;

  Widget shell({double? explicitOffset}) => MaterialApp(
        home: Scaffold(
          body: MiScrollBinder(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 160, bottom: 400),
                    children: const [SizedBox(height: 1200, child: ColoredBox(color: Color(0xFF101010)))],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: MiTopBar(
                    title: '显示与亮度',
                    showBack: true,
                    scrollOffset: explicitOffset,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  testWidgets('包 binder 后不传 scrollOffset 也随滚动折叠', (tester) async {
    tester.view.physicalSize = const Size(393, 856);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shell());
    final y0 = largeTitleY(tester);

    // 滚 60dp：大标题 1:1 上移（位移联动，见 MiTopBar 折叠契约）。
    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pumpAndSettle();
    final y1 = largeTitleY(tester);
    expect(y1, lessThan(y0), reason: '未传 scrollOffset 时应从作用域读到位移');
    // 至少上移了 40dp（60dp 位移里标题淡出段归零 + 位移 1:1）。
    expect(y0 - y1, greaterThan(40));
  });

  testWidgets('无 binder 且未传参：不折叠（旧默认行为）', (tester) async {
    tester.view.physicalSize = const Size(393, 856);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: ListView(
                  padding: const EdgeInsets.only(top: 160, bottom: 400),
                  children: const [SizedBox(height: 1200)],
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: MiTopBar(title: '显示与亮度', showBack: true),
              ),
            ],
          ),
        ),
      ),
    );
    final y0 = largeTitleY(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pumpAndSettle();
    // 无作用域 → 位移恒 0 → 标题原地不动。
    expect(largeTitleY(tester), y0);
  });

  testWidgets('显式 scrollOffset 压过作用域', (tester) async {
    tester.view.physicalSize = const Size(393, 856);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shell(explicitOffset: 0));
    final y0 = largeTitleY(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pumpAndSettle();
    // 显式 0 压过作用域：不折叠。
    expect(largeTitleY(tester), y0);
  });

  testWidgets('横向滚动体不驱动竖向折叠', (tester) async {
    tester.view.physicalSize = const Size(393, 856);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiScrollBinder(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 160, bottom: 400),
                    children: const [SizedBox(height: 1200)],
                  ),
                ),
                // 横向滚动体（胶囊行同款语义）：滚它不应折叠竖向顶栏。
                Positioned(
                  left: 0,
                  right: 0,
                  top: 60,
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        SizedBox(width: 900, child: ColoredBox(color: Color(0xFF202020))),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: MiTopBar(title: '显示与亮度', showBack: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final y0 = largeTitleY(tester);
    await tester.drag(
      find.byType(ListView).at(1),
      const Offset(-80, 0),
    );
    await tester.pumpAndSettle();
    expect(largeTitleY(tester), y0, reason: '横向滚动不应驱动竖向折叠');
  });

  testWidgets('位移变化经作用域驱动消费者重建（等值去重由 ValueNotifier 保证）',
      (tester) async {
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiScrollBinder(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 600),
                    children: const [SizedBox(height: 1200)],
                  ),
                ),
                Positioned.fill(
                  child: Builder(
                    key: const ValueKey('probe'),
                    builder: (context) {
                      // 消费者：注册依赖，统计重建次数。
                      MiScrollBinder.offsetOf(context);
                      builds++;
                      // 透明命中层不挡 ListView 的拖动手势（
                      // ColoredBox 不吸收拖动）。
                      return const SizedBox.expand();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(builds, 1);
    // 拖列表滚动 → 位移变化 → 依赖驱动消费者重建（等值去重由
    // ValueNotifier 保证：同像素不通知，这里验证「变了就重建」）。
    await tester.drag(find.byType(ListView), const Offset(0, -20));
    await tester.pumpAndSettle();
    expect(builds, greaterThan(1));
  });
}
