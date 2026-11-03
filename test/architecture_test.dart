import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 分层守门：**依赖只允许自上而下**，barrel 必须覆盖全部公开实现文件。
///
/// 分层（越靠前越底层，只能被后面的层依赖）：
///
/// ```
/// theme（设计 token）  icons（图标 painter）
///        ↓
/// foundations（squircle / 按压 / 悬停 / 焦点 / 滤镜缓存 / 格位数学）
///        ↓
/// layout（响应式 / 滚动作用域）
///        ↓
/// components（导航 / 按钮 / 输入 / 行 / 卡片 / 效果）
///        ↓
/// overlays（宿主 + 弹框 / 抽屉 / 面板 / 轻提示 / 悬浮容器）
/// ```
///
/// 这些规则不是洁癖：越层依赖会制造「改下层要动上层、复用下层得连带上层」
/// 的循环风险。此前 `MiPreferenceTileMetrics` 直接引 `MiDialogListMetrics`
/// 拿行高，就是组件层向上层要几何的真实例 —— 行几何因此上提为
/// `MiRowMetrics`（theme）。
void main() {
  /// 目录下全部 dart 文件（路径统一成正斜杠，便于前缀比较）。
  List<String> dartFilesIn(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path.replaceAll(r'\', '/'))
      .where((p) => p.endsWith('.dart'))
      .toList();

  /// 把相对 import 折叠成「从仓库根起算」的路径。
  String resolve(String fromFile, String relative) {
    final segments = fromFile.split('/')..removeLast();
    for (final seg in relative.split('/')) {
      if (seg == '..') {
        if (segments.isNotEmpty) segments.removeLast();
      } else if (seg != '.') {
        segments.add(seg);
      }
    }
    return segments.join('/');
  }

  /// 文件里指向本仓库的相对 import（`package:` / `dart:` 除外）。
  List<String> internalImportsOf(String path) {
    final source = File(path).readAsStringSync();
    return RegExp(r"""import '(?!package:|dart:)([^']+)'""")
        .allMatches(source)
        .map((m) => resolve(path, m.group(1)!))
        .toList();
  }

  /// 断言 [layer] 下的文件都不 import [forbidden] 下的任何文件。
  void expectNoDependency(String layer, List<String> forbidden) {
    final offenders = <String>[];
    for (final file in dartFilesIn(layer)) {
      for (final target in internalImportsOf(file)) {
        for (final f in forbidden) {
          if (target.startsWith('$f/')) {
            offenders.add('$file → $target');
          }
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: '依赖只能自上而下；把共享的规格上提到 theme / foundations，'
          '不要在 $layer 里反向引用',
    );
  }

  group('依赖方向', () {
    test('theme 不依赖任何内部层', () {
      expectNoDependency('lib/src/theme', [
        'lib/src/foundations',
        'lib/src/layout',
        'lib/src/components',
        'lib/src/overlays',
        'lib/src/icons',
      ]);
    });

    test('icons 不依赖任何内部层（只吃 flutter）', () {
      expectNoDependency('lib/src/icons', [
        'lib/src/theme',
        'lib/src/foundations',
        'lib/src/layout',
        'lib/src/components',
        'lib/src/overlays',
      ]);
    });

    test('foundations 不依赖 layout / components / overlays', () {
      expectNoDependency('lib/src/foundations', [
        'lib/src/layout',
        'lib/src/components',
        'lib/src/overlays',
      ]);
    });

    test('layout 不依赖 components / overlays', () {
      expectNoDependency('lib/src/layout', [
        'lib/src/components',
        'lib/src/overlays',
      ]);
    });

    test('components 不依赖 overlays（组件层不向浮层要东西）', () {
      expectNoDependency('lib/src/components', ['lib/src/overlays']);
    });

    test('overlays 不依赖 components（浮层自带零件，不反向吃组件）', () {
      expectNoDependency('lib/src/overlays', ['lib/src/components']);
    });
  });

  group('barrel 覆盖', () {
    /// barrel 里 export 的路径集合（barrel 在 `lib/` 下，路径相对它解析）。
    Set<String> exportedPaths() {
      final source = File('lib/mi_like_ui.dart').readAsStringSync();
      return RegExp(r"""export '([^']+)'""")
          .allMatches(source)
          .map((m) => 'lib/${m.group(1)!}')
          .toSet();
    }

    test('每个 export 指向的文件都存在（改名/搬家后不留死链）', () {
      final missing = exportedPaths()
          .where((p) => !File(p).existsSync())
          .toList();
      expect(missing, isEmpty, reason: '文件已重命名或移动，barrel 未跟上');
    });

    test('src 下除内部 painter 外，每个文件都被 barrel 导出', () {
      final exported = exportedPaths();
      final uncovered = dartFilesIn('lib/src')
          // `*_painter.dart` 是框架内部实现（不承诺 API 稳定），刻意不导出。
          .where((p) => !p.endsWith('_painter.dart'))
          .where((p) => !exported.contains(p))
          .toList();
      expect(uncovered, isEmpty,
          reason: '新增实现文件后请在 lib/mi_like_ui.dart 补一行 export；'
              '若确属内部件，文件名加 _painter 后缀或在此登记例外');
    });
  });
}
