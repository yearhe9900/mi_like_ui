import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo/demo_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 内容铺到状态栏 / 手势条下面（edge-to-edge）。
  //
  // 不铺的话，应用窗口从状态栏下方开始，状态栏那一条就是**系统自己画的
  // 底色 + 压色** —— 在平板上看起来就是一条灰带，与页面
  // 底色对不上。铺开之后状态栏背后是页面自己的底色 / 顶栏磨砂，配合
  // `DemoHome` 里的 `AnnotatedRegion<SystemUiOverlayStyle>`（透明状态栏 +
  // 图标随明暗翻转）才是一条连续的界面。
  //
  // 代价是内容要自己让开安全区：顶栏读 `MediaQuery.padding.top`，
  // 侧栏 / 底栏 / Home 指示条各自加 `padding`（见 `demo_app.dart`）。
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const DemoApp());
}
