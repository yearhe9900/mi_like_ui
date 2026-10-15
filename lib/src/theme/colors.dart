import 'package:flutter/painting.dart';

/// 全局颜色 token（框架级，跨组件共用）。
///
/// 新组件取色一律引用这里，不在组件内散落字面量颜色。
class MiColors {
  MiColors._();

  /// 前景主色：图标、标签等近白内容色（视频实测 #F5F5F5）。
  static const Color foreground = Color(0xFFF5F5F5);
}
