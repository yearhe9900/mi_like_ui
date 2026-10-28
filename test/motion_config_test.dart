import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；若导出缺失会在这里暴露。
import 'package:mi_like_ui/mi_like_ui.dart';

/// 动效配置的**守门测试**。
///
/// 约定（见 `MiMotionTokens` 类文档）：跨组件动效数值只定义在
/// `lib/src/theme/motion_tokens.dart`，组件私有动效定义在各 `*_metrics.dart`；
/// 其余实现层不得出现裸的时长 / 弹簧 / 自创曲线字面量 —— 动效数值抄两遍时
/// 改一处漏一处的代价是「手感漂移」，这里用源码扫描把它钉死。
///
/// 白名单口径：
///  * `*_metrics.dart` —— 组件私有动效数值的家；
///  * `motion_tokens.dart` —— 跨组件动效数值的家；
///  * `lib/src/utils/` —— 公开参数默认值是 API 的一部分（如
///    `MiHoverFeedback(duration: …)` 的默认 150ms），不是隐藏常量，不扫；
///  * demo（`lib/demo/`）不扫 —— 示例层模拟真实使用方，用裸值是合法用法。
///
/// 刻意**放行** `Curves.xxx`：那是 Flutter 官方命名常量（token），不是字面量；
/// 纪律钉死的是「数值字面量散落」，不骚扰命名引用。
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

/// 该文件里出现的「动效字面量」违规项（描述 + 行号）。
List<String> _violationsIn(String path) {
  final source = _stripComments(File(path).readAsStringSync());
  final rules = <(String, RegExp)>[
    // 裸时长：Duration(milliseconds: 300) 这类
    ('裸时长字面量', RegExp(r'Duration\(\s*(milliseconds|seconds|microseconds)\s*:\s*\d')),
    // 裸弹簧：必须引用 MiMotionTokens 的命名弹簧
    ('裸弹簧字面量', RegExp(r'SpringDescription\(')),
    // 自创贝塞尔：只允许用 Curves 命名曲线或 metrics 里有出处的定义
    ('自创曲线字面量', RegExp(r'Cubic\(')),
    // 实现层私设 ms 常量（合法的家只有 metrics / tokens）
    ('私设 ms 常量', RegExp(r'\w+Ms\s*=\s*\d')),
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

/// 组件层扫描目标：排除各组件私有动效的家（`*_metrics.dart`）。
Iterable<String> _componentFiles() => _dartFilesIn('lib/src/components')
    .where((p) => !p.endsWith('_metrics.dart'));

/// theme 层扫描目标：排除跨组件动效的家。
Iterable<String> _themeFiles() => _dartFilesIn('lib/src/theme')
    .where((p) => !p.endsWith('/motion_tokens.dart'));

void main() {
  group('动效字面量只允许出现在各自的家里', () {
    test('组件层（除 *_metrics.dart）不得有裸时长 / 弹簧 / 曲线 / ms 常量', () {
      final offenders = _componentFiles().expand(_violationsIn).toList();
      expect(offenders, isEmpty,
          reason: '把这个值挪进组件 metrics 或 MiMotionTokens，再引用它');
    });

    test('theme 层（除 motion_tokens.dart）不得有动效字面量', () {
      final offenders = _themeFiles().expand(_violationsIn).toList();
      expect(offenders, isEmpty,
          reason: '跨组件动效数值进 MiMotionTokens，其余 theme 文件只引用');
    });

    test('utils 放行有据：默认值是公开参数（规则不空转的旁证之一）', () {
      // MiHoverFeedback / MiFocusRing 的默认时长是 API 的一部分，
      // 白名单放行；这里只确认文件确实存在、白名单口径没有漂移。
      expect(File('lib/src/utils/hover_feedback.dart').existsSync(), isTrue);
      expect(File('lib/src/utils/focus_ring.dart').existsSync(), isTrue);
    });
  });

  group('防空转：规则在「合法的家」上必须能匹配到真实代码', () {
    test('motion_tokens.dart 含字面量（它是数值的家，规则对它应有命中）', () {
      expect(_violationsIn('lib/src/theme/motion_tokens.dart'), isNotEmpty);
    });

    test('组件 metrics 含字面量（同上，证明扫描规则能匹配真实写法）', () {
      expect(
        _violationsIn(
            'lib/src/components/navigation/glass_nav_bar/glass_nav_bar_metrics.dart'),
        isNotEmpty,
      );
    });
  });

  group('跨组件「同一套按压语言」：转发与语义一致性', () {
    test('按压淡入 / 淡出：顶栏返回钮、搜索取消钮、token 三方同值', () {
      expect(MiTopBarMetrics.pressFadeInMs, MiMotionTokens.pressFadeInMs);
      expect(MiSearchCancelMetrics.pressFadeInMs, MiMotionTokens.pressFadeInMs);
      expect(MiTopBarMetrics.pressFadeOutMs, MiMotionTokens.pressFadeOutMs);
      expect(
          MiSearchCancelMetrics.pressFadeOutMs, MiMotionTokens.pressFadeOutMs);
    });

    test('按压叠色：弹框 metrics 转发自 token', () {
      expect(MiDialogMetrics.pressDurationMs, MiMotionTokens.pressMs);
    });

    test('弹出面板弹簧：展开欠阻尼（过冲 ~1.4%）、收回临界阻尼（无过冲）', () {
      const expand = MiMotionTokens.panelExpand;
      expect(expand.mass, 1);
      expect(expand.stiffness, 260);
      expect(expand.damping, 26);
      // ζ = c / 2√(km)
      expect(expand.damping / (2 * math.sqrt(expand.stiffness * expand.mass)),
          closeTo(0.807, 0.001));

      const collapse = MiMotionTokens.panelCollapse;
      expect(collapse.stiffness, 530);
      expect(collapse.damping, 46);
      expect(
          collapse.damping /
              (2 * math.sqrt(collapse.stiffness * collapse.mass)),
          closeTo(1.0, 0.02));
    });

    test('miSpring 换算自洽：stiffness = (2π/response)²，ζ = 给定阻尼比', () {
      final s = miSpring(damping: 0.85, response: 0.4);
      final k = math.pow(2 * math.pi / 0.4, 2).toDouble();
      expect(s.stiffness, closeTo(k, 1e-9));
      expect(s.damping / (2 * math.sqrt(s.stiffness * s.mass)),
          closeTo(0.85, 1e-9));
    });
  });
}
