import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；若导出缺失会在这里暴露。
import 'package:mi_like_ui/mi_like_ui.dart';

/// 统一透明配置的**守门测试**。
///
/// 约定（见 `MiTransparencyTokens` 类文档）：透明参数（alpha / blur σ /
/// 膜色）只允许在 `lib/src/theme/transparency_tokens.dart` 里出现字面量，
/// 其它 theme 文件与所有组件都只能**引用常量**。透明效果是这套 UI 的主线，
/// 数值抄两遍时改一处漏一处的代价太高 —— 这里用源码扫描把它钉死。
const String _configFile = 'transparency_tokens.dart';

/// 去掉行注释（含 `///` 文档注释），避免文档里举例的写法被误判。
String _stripComments(String source) {
  final out = StringBuffer();
  for (final line in source.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//')) continue;
    final idx = line.indexOf('//');
    out.writeln(idx >= 0 ? line.substring(0, idx) : line);
  }
  return out.toString();
}

/// 该文件里出现的「透明参数字面量」违规项（描述 + 行号）。
List<String> _violationsIn(String path) {
  final source = _stripComments(File(path).readAsStringSync());
  final rules = <(String, RegExp)>[
    // rgba(...) / fromRGBO 的 alpha 位写成数字字面量
    ('fromRGBO 的 alpha 是字面量', RegExp(r'fromRGBO\([^)]*,\s*[\d.]+\s*\)')),
    // fromARGB 的 alpha 位写成数字字面量
    ('fromARGB 的 alpha 是字面量', RegExp(r'fromARGB\(\s*\d')),
    // 带 alpha 的 8 位十六进制色（0xFF…… 是不透明，放行）
    ('带 alpha 的十六进制色', RegExp(r'Color\(0x(?!FF)[0-9A-Fa-f]{8}\)')),
    // 运行时改透明度
    ('运行时改透明度', RegExp(r'\.with(Opacity|Alpha)\(')),
  ];
  final hits = <String>[];
  for (final (label, re) in rules) {
    for (final m in re.allMatches(source)) {
      final line = '\n'.allMatches(source.substring(0, m.start)).length + 1;
      hits.add('$path:$line —— $label（${m.group(0)}）');
    }
  }
  return hits;
}

List<String> _dartFilesIn(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .map((f) => f.path.replaceAll(r'\', '/'))
    .where((p) => p.endsWith('.dart'))
    .toList();

void main() {
  group('透明参数只允许出现在统一配置里', () {
    test('theme 层：除 $_configFile 外不得有 alpha 字面量', () {
      final offenders = _dartFilesIn('lib/src/theme')
          .where((p) => !p.endsWith('/$_configFile'))
          .expand(_violationsIn)
          .toList();
      expect(offenders, isEmpty,
          reason: '把这个值挪进 MiTransparencyTokens，再在这里引用它');
    });

    test('组件层：完全不得出现 alpha 字面量（一律取 token）', () {
      final offenders =
          _dartFilesIn('lib/src/components').expand(_violationsIn).toList();
      expect(offenders, isEmpty,
          reason: '组件只消费 token，不自己定透明度');
    });

    test('统一配置文件自身确实带字面量（防止规则空转）', () {
      expect(_violationsIn('lib/src/theme/$_configFile'), isNotEmpty);
    });
  });

  group('组件 token 引用的是统一配置的同一份数值', () {
    test('渐进曲线 σ 表 = blurSigmaRamp（逐档、同长、峰值一致）', () {
      expect(MiTopBarPalette.blurBands, hasLength(
        MiTransparencyTokens.blurSigmaRamp.length,
      ));
      for (var i = 0; i < MiTopBarPalette.blurBands.length; i++) {
        expect(MiTopBarPalette.blurBands[i].sigma,
            MiTransparencyTokens.blurSigmaRamp[i],
            reason: '第 $i 段的 σ 应取自统一配置');
      }
      expect(MiGradientBlurProfile.sigma, MiTransparencyTokens.blurSigmaTop);
      expect(MiGradientBlurProfile.sigma,
          MiTransparencyTokens.blurSigmaRamp.first);
      expect(MiGradientBlurProfile.minVisibleSigma,
          MiTransparencyTokens.minVisibleSigma);
      expect(MiGradientBlurProfile.nominalExtent,
          MiTransparencyTokens.nominalBlurExtent);
    });

    test('顶栏压色曲线：色值逐档来自统一配置，且与 stops 一一对应', () {
      void check(MiTopBarPalette palette, List<Color> expected) {
        final gradient = palette.scrimGradient;
        expect(gradient.colors, expected);
        expect(gradient.stops, hasLength(expected.length),
            reason: 'stops 与色值必须逐档对应（比例值，属几何）');
      }

      check(MiTopBarPalette.dark, MiTransparencyTokens.scrimGradientDark);
      check(MiTopBarPalette.light, MiTransparencyTokens.scrimGradientLight);
      expect(MiTopBarPalette.dark.pressHighlight,
          MiTransparencyTokens.pressHighlightDark);
      expect(MiTopBarPalette.light.pressHighlight,
          MiTransparencyTokens.pressHighlightLight);
      // 压色基色：暗纯黑、亮页底色
      expect(MiTransparencyTokens.scrimGradientDark.first.a, 1.0);
      expect(MiTransparencyTokens.scrimGradientLight.first.a,
          closeTo(0.650, 1e-9));
    });

    test('搜索栏 / 胶囊 / 玻璃导航栏 / 玻璃膜都取统一档位', () {
      expect(MiSearchBarPalette.dark.fill.a * 255,
          closeTo(MiTransparencyTokens.fillAlphaSearchDark, 1e-6));
      expect(MiSearchBarPalette.light.fill.a * 255,
          closeTo(MiTransparencyTokens.fillAlphaSearchLight, 1e-6));

      expect(MiPillTabPalette.dark.unselectedFill.a * 255,
          closeTo(MiTransparencyTokens.fillAlphaSubtle, 1e-6));
      expect(MiPillTabPalette.dark.selectedFill.a * 255,
          closeTo(MiTransparencyTokens.fillAlphaStrongDark, 1e-6));
      expect(MiPillTabPalette.light.selectedFill.a * 255,
          closeTo(MiTransparencyTokens.fillAlphaStrongLight, 1e-6));

      expect(MiGlassTokens.blurSigma, MiTransparencyTokens.blurSigma);
      final lightScrim = MiGlassPalette.light.scrimGradient!.colors;
      expect(lightScrim[0].a,
          closeTo(MiTransparencyTokens.glassScrimLightAlphaTop, 1e-6));
      expect(lightScrim[1].a,
          closeTo(MiTransparencyTokens.glassScrimLightAlphaMid, 1e-6));
      expect(lightScrim[2].a,
          closeTo(MiTransparencyTokens.glassScrimLightAlphaBottom, 1e-6));
      expect(MiGlassTokens.lensShade.a,
          closeTo(MiTransparencyTokens.glassLensShadeAlpha, 1e-6));

      expect(MiTransparencyTokens.veilFor(MiThemeMode.light).a * 255,
          closeTo(MiTransparencyTokens.veilAlphaLight, 1e-6));
      expect(MiTransparencyTokens.veilFor(MiThemeMode.dark).a * 255,
          closeTo(MiTransparencyTokens.veilAlphaDark, 1e-6));
    });

    /// 垫在同色页底上的结果（取 r 通道 —— 这几档填充都是中性灰/黑/白）。
    double over(double pageChannel, Color fill) =>
        pageChannel * (1 - fill.a) + fill.r * 255 * fill.a;

    test('玻璃膜 + 低调填充 = 平底页观感不变（只有背景有内容才显出玻璃片）', () {
      // 亮页底 #F3F3F3 / 暗页底 #000000；每档都断言「垫膜前后合成结果不变」
      void unchanged(double page, Color fill, String label) {
        expect(over(page, MiTransparencyTokens.veiledFill(fill, page == 243
                ? MiThemeMode.light
                : MiThemeMode.dark)),
            closeTo(over(page, fill), 0.5),
            reason: '$label 在平底页上不应因为垫膜而变色');
      }

      unchanged(243, MiPillTabPalette.light.unselectedFill, '亮色未选胶囊');
      unchanged(0, MiPillTabPalette.dark.unselectedFill, '暗色未选胶囊');
      unchanged(243, MiSearchBarPalette.light.fill, '亮色搜索栏');
      unchanged(0, MiSearchBarPalette.dark.fill, '暗色搜索栏');
    });
  });
}
