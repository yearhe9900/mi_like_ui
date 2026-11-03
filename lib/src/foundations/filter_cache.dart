import 'dart:ui';

/// `ImageFilter.blur` 的进程内缓存（框架内部工具，不经 barrel 导出）。
///
/// 每帧 `build` 中直接 `ImageFilter.blur(...)` 会新建 native filter 对象
/// （FFI 调用 + 内存分配 + 采样表构建）。本库的模糊 σ 全部来自固定令牌
/// （磨砂 5.37、顶栏阶梯、搜索栏同源），取值集合有限且不变，可缓存复用
/// 同一 `ImageFilter` 实例。
///
/// `ImageFilter` 为不可变 native 对象，可安全地被多个 `BackdropFilter`
/// 共享；缓存按 σ（保留 3 位小数的整数 key，避免浮点误差分叉）索引。
///
/// **key 即值（缓存失效审计）**：filter 是 σ 的纯函数 —— 键相等 ⇔ 实例
/// 可复用，不存在「键命中但材质已变」的失效窗口。教训参照：OS4 玻璃
/// （flutter_miuix）以「材质对象」为纹理缓存 key，引用相等会让材质每帧
/// 重建 → 每帧重跑离屏模糊；本库的 key 全部是值类型，无此问题。
///
/// **饱和度色控暂无入口（SDK 能力审计）**：磨砂后的饱和 / 亮度调整
/// （HyperOS `textureBlur` 的色控段）在 `BackdropFilter` 路线上需要
/// `ImageFilter.colorFilter` 组合，当前 SDK（3.47）无该工厂（`ImageFilter.
/// matrix` 是几何变换）；`MiTransparencyTokens.blurSaturation` 为预留
/// token（恒等 1.0），待 SDK 支持或纹理玻璃路线（快照 + `ColorFilter.matrix`）
/// 落地时接入。
///
/// 省去单次构建内的 N 次 native 分配（如平板深色首页 10 次/帧）。
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
