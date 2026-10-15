import 'package:flutter/painting.dart';

import 'colors.dart';

/// 全局文字样式 token。
///
/// 组件内文字一律引用这里预置的 [TextStyle]，字号/字重不在组件里散落。
class MiTypography {
  MiTypography._();

  /// 导航栏标签：视频实测 CJK 字高 31px → 10.5dp、Medium 字重。
  static const TextStyle navLabel = TextStyle(
    color: MiColors.foreground,
    fontSize: 10.5,
    height: 1.0,
    fontWeight: FontWeight.w500,
  );
}
