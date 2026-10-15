import 'package:flutter/material.dart';
import 'package:mi_like_ui/mi_like_ui.dart';

import 'mock_pages.dart';

/// 演示应用（示例层，不属于框架公共 API）。
class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glass Jelly Bottom Nav Demo',
      theme: ThemeData.dark(useMaterial3: true),
      home: const DemoHome(),
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  int _index = 0;

  static const _iconColor = MiColors.foreground;

  late final List<MiGlassNavItem> _items = [
    MiGlassNavItem(label: '首页', painter: RollerIconPainter(_iconColor)),
    MiGlassNavItem(label: '分类', painter: GridSparkleIconPainter(_iconColor)),
    MiGlassNavItem(label: '我的', painter: SmileyBeretIconPainter(_iconColor)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080A),
      body: Center(
        child: Container(
          // phone frame, aspect follows the reference screen (1220x2656)
          width: 393,
          height: 856,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E11),
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
                  child: MockPage(_index, key: ValueKey(_index)),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24.2, // measured: bar bottom sits 24.2 dp above screen bottom
                child: MiGlassNavBar(
                  items: _items,
                  selectedIndex: _index,
                  onTap: (i) => setState(() => _index = i),
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
                      color: const Color(0xD9FFFFFF),
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
