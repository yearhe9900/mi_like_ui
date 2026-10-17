import 'dart:ui';

/// `ImageFilter.blur` 的**进程内缓存**（框架内部工具，不经 barrel 导出）。
///
/// 每帧 `build` 里直接 `ImageFilter.blur(...)` 会新建 native filter 对象
/// （FFI 调用 + 内存分配 + 首次使用时的采样表构建）。本框架的模糊 σ 全部来自
/// 固定 token（磨砂 5.37、顶栏阶梯 5.37/5.15/4.68/…、搜索栏 同上），取值集合
/// 是有限且不变的 —— 完全可以缓存复用同一个 `ImageFilter` 实例。
///
/// `ImageFilter` 是不可变 native 对象，可安全地被多个 `BackdropFilter` 共享；
/// 缓存按 σ（保留 3 位小数的整数 key，避免浮点误差分叉）索引。
///
/// 省下的是一次 build 内 N 次 native 分配。实测（平板 768×1280 深色首页）：
/// 顶栏 8 + 导航栏 1 + 搜索栏 1 = 10 次/帧，滚动时每帧都发生。
class MiFilterCache {
  MiFilterCache._();

  static final Map<int, ImageFilter> _blurCache = <int, ImageFilter>{};

  /// 取 σ 对应的高斯模糊 filter（同 σ 复用同一实例）。
  static ImageFilter blur(double sigma) {
    assert(sigma >= 0, 'sigma 不能为负');
    final key = (sigma * 1000).round();
    return _blurCache.putIfAbsent(
      key,
      () => ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    );
  }

  /// 仅供测试/诊断：当前缓存的 filter 个数。
  static int get debugCacheSize => _blurCache.length;
}
