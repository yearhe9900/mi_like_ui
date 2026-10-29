/// Web 设备探测：读 `navigator.userAgent` 判移动端。
///
/// 平板 iPadOS 的 Safari 也带 `Mobile` 标记，算手持（铺满全屏）；
/// 桌面版 Safari / Chrome on Mac 不带，走桌面壳。
library;

import 'dart:js_interop';

@JS('navigator.userAgent')
external JSString get _userAgent;

bool hostIsMobile() => RegExp(
      r'Android|iPhone|iPad|iPod|Mobile|webOS|BlackBerry|IEMobile|Opera '
      r'Mini|Silk|HarmonyOS',
      caseSensitive: false,
    ).hasMatch(_userAgent.toDart);
