/// 原生（VM）设备探测：移动端 OS = 手持设备。
library;

import 'dart:io' show Platform;

bool hostIsMobile() => Platform.isAndroid || Platform.isIOS;
