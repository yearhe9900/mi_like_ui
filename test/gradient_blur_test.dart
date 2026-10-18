import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；若导出缺失会在这里暴露。
import 'package:mi_like_ui/mi_like_ui.dart';

/// 顶部渐进模糊（内容区自己那层）的独立组件。
///
/// 这层模糊**不属于顶栏**：参考 App 里有一页完全没有顶栏、内容顶部照样糊，
/// 所以它被抽成 `MiGradientBlur`，顶栏只是按自己的材质盒高复用它。
void main() {
  group('曲线（bandsFor）', () {
    test('默认按实测跨度 119dp：7 段（尾部 σ=0.30 亚像素已剔除）、σ 递减', () {
      final bands = MiGradientBlur.bandsFor();
      expect(bands, hasLength(7));
      expect(bands.first.top, 0);
      expect(bands.first.sigma, MiGradientBlurProfile.sigma);
      expect(bands.last.sigma, lessThan(bands.first.sigma));
      // 名义终点 119 → 末段 σ=0.30 < minVisibleSigma，不画；可见下沿 109
      expect(MiGradientBlurProfile.bands.last.bottom, 119);
      expect(bands.last.bottom, closeTo(109, 0.01));
      // 首尾相接、无缝隙
      for (var i = 1; i < bands.length; i++) {
        expect(bands[i].top, closeTo(bands[i - 1].bottom, 0.01));
      }
    });

    test('形状固定、范围跟作用区走：156dp 时等比拉伸到 156 归零，σ 不变', () {
      final base = MiGradientBlur.bandsFor();
      final tall = MiGradientBlur.bandsFor(extent: 156);
      expect(tall, hasLength(base.length));
      for (var i = 0; i < base.length; i++) {
        expect(tall[i].sigma, base[i].sigma, reason: 'σ 是曲线形状，不该被缩放');
        expect(tall[i].top, closeTo(base[i].top * 156 / 119, 0.01));
        expect(tall[i].bottom, closeTo(base[i].bottom * 156 / 119, 0.01));
      }
      // 名义终点精确落到作用区底（119 → 156）
      expect(tall.last.bottom, closeTo(109 * 156 / 119, 0.01));
    });

    test('上层有不透明压色时跳过被 100% 遮住的段；关掉压色则必须从 0 起画', () {
      final covered = MiGradientBlur.bandsFor(
        extent: 128.9,
        opaqueScrimBottom: 63.6,
      );
      expect(covered.first.top, closeTo(63.6, 0.01));
      expect(
        covered.length,
        lessThan(MiGradientBlur.bandsFor(extent: 128.9).length),
      );

      // 压色关掉：上半段裸露，跳过它等于顶部一片清晰（实机踩过）
      final bare = MiGradientBlur.bandsFor(
        extent: 128.9,
        opaqueScrimBottom: 63.6,
        underSurface: false,
      );
      expect(bare.first.top, 0);
      expect(bare.first.sigma, MiGradientBlurProfile.sigma);
    });

    test('作用区为 0 时不产生任何段', () {
      expect(MiGradientBlur.bandsFor(extent: 0), isEmpty);
    });
  });

  group('渲染', () {
    Future<void> pump(
      WidgetTester tester, {
      required double height,
      double opaqueScrimBottom = 0,
      bool underSurface = true,
    }) async {
      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize = const Size(393 * 2, 600 * 2);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                // 底下放高频内容，让模糊有东西可糊
                Positioned.fill(
                  child: ListView(
                    children: const [
                      SizedBox(height: 40, child: ColoredBox(color: Color(0xFF2244AA))),
                      SizedBox(height: 40, child: ColoredBox(color: Color(0xFFDDAACC))),
                      SizedBox(height: 40, child: ColoredBox(color: Color(0xFF336655))),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: height,
                  child: MiGradientBlur(
                    height: height,
                    opaqueScrimBottom: opaqueScrimBottom,
                    underSurface: underSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('每段一个定 σ 的 BackdropFilter，满宽、几何与 bandsFor 一致',
        (tester) async {
      const height = 128.9;
      await pump(tester, height: height);

      final bands = MiGradientBlur.bandsFor(extent: height);
      final filters = find.byType(BackdropFilter);
      expect(filters, findsNWidgets(bands.length));

      final widgets = tester.widgetList<BackdropFilter>(filters).toList();
      for (var i = 0; i < bands.length; i++) {
        final band = bands[i];
        expect(
          widgets[i].filter,
          ImageFilter.blur(sigmaX: band.sigma, sigmaY: band.sigma),
          reason: '第 $i 段 σ 与曲线不一致',
        );
        final rect = tester.getRect(filters.at(i));
        expect(rect.left, 0);
        expect(rect.width, 393);
        expect(rect.top, closeTo(band.top, 0.01));
        expect(rect.height, closeTo(band.height, 0.01));
      }

      // 组件自身高度 = 作用区高度（它只是叠在内容上的一层底，不占布局）
      expect(
        tester.getSize(find.byType(MiGradientBlur)).height,
        closeTo(height, 0.01),
      );
    });

    testWidgets('渐进效果不得用遮罩实现（ShaderMask 会让 backdrop 变空）',
        (tester) async {
      await pump(tester, height: 128.9);
      expect(
        find.descendant(
          of: find.byType(MiGradientBlur),
          matching: find.byType(ShaderMask),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(MiGradientBlur),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });

    testWidgets('不吃手势：叠在内容上也能正常拖滚动', (tester) async {
      await pump(tester, height: 128.9);
      expect(
        find.descendant(
          of: find.byType(MiGradientBlur),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );
      // 作用区上拖动，列表仍能滚动（不抛异常即可，且拿不到任何 GestureDetector）
      expect(
        find.descendant(
          of: find.byType(MiGradientBlur),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
    });

    testWidgets('不依赖顶栏：页面里没有 MiTopBar 也能单独用', (tester) async {
      await pump(tester, height: 119);
      expect(find.byType(MiTopBar), findsNothing);
      expect(find.byType(MiGradientBlur), findsOneWidget);
      expect(find.byType(BackdropFilter), findsWidgets);
    });

    testWidgets('同 σ 的 ImageFilter 跨帧复用（不每帧新建 native 对象）',
        (tester) async {
      await pump(tester, height: 128.9);
      ImageFilter? firstFilter() =>
          tester.widget<BackdropFilter>(find.byType(BackdropFilter).first).filter;
      final first = firstFilter();
      await pump(tester, height: 128.9);
      expect(identical(first, firstFilter()), isTrue);
    });
  });
}
