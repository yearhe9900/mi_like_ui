import 'package:flutter_test/flutter_test.dart';

import 'package:mi_like_ui/mi_like_ui.dart';

/// `MiFilterCache` 值相等缓存的守门测试。
///
/// 契约：filter 是 σ 的**纯函数** —— 同 σ 必复用同实例（省 native 分配），
/// 异 σ 绝不串实例（key 即值，无「键命中但材质已变」的失效窗口）。
void main() {
  test('同 σ 复用同一实例', () {
    final a = MiFilterCache.blur(9.0);
    expect(identical(MiFilterCache.blur(9.0), a), isTrue);
    expect(identical(MiFilterCache.blur(5.37), a), isFalse, reason: '异 σ 不串');
    // σ key 按 3 位小数取整：token 集合里的值不会因浮点误差分叉。
    expect(identical(MiFilterCache.blur(9.0), MiFilterCache.blur(9.0001)), isTrue);
  });

  test('饱和度 token 恒等：全库磨砂零操作（golden 零变化依据）', () {
    expect(MiTransparencyTokens.blurSaturation, 1.0);
  });
}
