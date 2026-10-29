import 'host_device_io.dart'
    if (dart.library.js_interop) 'host_device_web.dart' as impl;

/// 演示宿主设备语境（决定演示外壳形态，见 `DemoStage.modeFor`）。
///
///  * [handheld] —— 移动端：手机 / 平板实机、移动 UA 浏览器 → **铺满全屏**，
///    不套机身壳（真机自己就是机身）；
///  * [desktop] —— PC：桌面 OS / 桌面 UA 浏览器 → 窄窗套**手机壳**、宽窗套
///    **平板壳**（模拟机身 + 外圈底色 + 投影，见 `DemoStage` 类注释）。
enum DemoDevice { handheld, desktop }

DemoDevice? _cached;

/// 探测宿主设备：web 读 `navigator.userAgent`，原生读运行平台。
///
/// 结果缓存（UA / 平台在会话内不变，且探测会碰正则）。
DemoDevice demoHostDevice() =>
    _cached ??= impl.hostIsMobile() ? DemoDevice.handheld : DemoDevice.desktop;
