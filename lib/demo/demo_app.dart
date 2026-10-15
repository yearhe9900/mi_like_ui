import 'package:flutter/material.dart';
import 'package:mi_like_ui/mi_like_ui.dart';

import 'mock_pages.dart';

/// 演示应用（示例层，不属于框架公共 API）。
///
/// 深/浅色模式切换入口放在「我的」页顶部；模式驱动手机框、mock 页、
/// 导航栏玻璃配方与墨色整体切换。
class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  MiThemeMode _mode = MiThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    final light = _mode == MiThemeMode.light;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glass Jelly Bottom Nav Demo',
      theme: light ? ThemeData.light(useMaterial3: true) : ThemeData.dark(useMaterial3: true),
      home: DemoHome(
        themeMode: _mode,
        onThemeModeChanged: (m) => setState(() => _mode = m),
      ),
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key, required this.themeMode, required this.onThemeModeChanged});

  final MiThemeMode themeMode;
  final ValueChanged<MiThemeMode> onThemeModeChanged;

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final light = widget.themeMode == MiThemeMode.light;
    // 图标墨色随模式（与导航栏标签一致）
    final ink = MiColors.foregroundFor(widget.themeMode);
    final items = [
      MiGlassNavItem(label: '首页', painter: RollerIconPainter(ink)),
      MiGlassNavItem(label: '分类', painter: GridSparkleIconPainter(ink)),
      MiGlassNavItem(label: '我的', painter: SmileyBeretIconPainter(ink)),
    ];

    return Scaffold(
      backgroundColor: light ? const Color(0xFFE4E4E6) : const Color(0xFF08080A),
      body: Center(
        child: Container(
          // phone frame, aspect follows the reference screen (1220x2656)
          width: 393,
          height: 856,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: light ? const Color(0xFFF3F3F3) : const Color(0xFF0E0E11),
            borderRadius: BorderRadius.circular(44),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 16)),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: MockPage(
                    _index,
                    key: ValueKey(_index),
                    themeMode: widget.themeMode,
                    onThemeModeChanged: widget.onThemeModeChanged,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24.2, // measured: bar bottom sits 24.2 dp above screen bottom
                child: MiGlassNavBar(
                  items: items,
                  selectedIndex: _index,
                  onTap: (i) => setState(() => _index = i),
                  themeMode: widget.themeMode,
                  // 预留空位圆钮：仅选中「首页」时显示（切走收起）
                  fab: MiGlassNavFab(
                    tabIndex: 0,
                    onTap: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('圆形按钮被点击'),
                        duration: Duration(milliseconds: 800),
                      ),
                    ),
                    child: CustomPaint(
                      painter: GridDotsIconPainter(Colors.white),
                      size: const Size.square(18.2),
                    ),
                  ),
                ),
              ),
              // home indicator (phone chrome, not part of the nav bar)
              Positioned(
                left: 0,
                right: 0,
                bottom: 9,
                child: Center(
                  child: Container(
                    width: 138,
                    height: 5,
                    decoration: BoxDecoration(
                      color: light ? const Color(0xD9000000) : const Color(0xD9FFFFFF),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
