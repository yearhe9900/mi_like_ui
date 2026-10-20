import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/search_bar_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../utils/filter_cache.dart';
import 'search_cancel_metrics.dart';

/// 搜索态的取消钮：⌀44.1 圆盘 + 叉号，点按退出搜索态。
///
/// 几何 1:1 实测自参考录屏的搜索态（见 [MiSearchCancelMetrics]）：
/// 直径 = **搜索栏高**（同一帧里两者都是 66px），与搜索栏隔 10.0dp，
/// 右缘贴屏幕右缘（实测 0，闭合算式见 metrics 文档）。
///
/// ## 配色（有两处容易踩错，都有实测依据）
///
///  * **圆盘填充 = 搜索栏填充**（同一帧实测两者同为 244）：直接复用
///    [MiSearchBarPalette.fill]，不另立一档，也就天然继承「半透明表面 +
///    可选玻璃膜」的整条透明语言；
///  * **叉号墨色 = 前景墨色**，不是放大镜那档灰。同一页里实测放大镜
///    167、叉号 0 —— 差一整档，叉号是「可点控件」的实心前景色。
///
/// ## 磨砂 / 玻璃膜
///
/// 与搜索栏同规则：[frosted] 放进自带材质的顶栏时传 `false`（整条栏只糊
/// 一次）；[overContent] 在填充之下再垫一层玻璃膜
/// （[MiTransparencyTokens.veiledFill]），平底页观感不变。
class MiSearchCancelButton extends StatefulWidget {
  const MiSearchCancelButton({
    super.key,
    required this.onTap,
    this.themeMode,
    this.frosted = true,
    this.overContent = false,
    this.diameter = MiSearchCancelMetrics.diameter,
  });

  /// 点按回调；null = 只展示、不可点（不参与手势、无按压反馈）。
  final VoidCallback? onTap;

  /// 明暗模式；null = 跟随环境 Theme 亮度。
  final MiThemeMode? themeMode;

  /// 是否自绘 backdrop 磨砂（默认 true；顶栏内传 `false`）。
  final bool frosted;

  /// 是否铺玻璃膜（压在照片/视频上时开启，语义同搜索栏的 `overContent`）。
  final bool overContent;

  /// 圆钮直径（默认 [MiSearchCancelMetrics.diameter] = 搜索栏高）。
  final double diameter;

  @override
  State<MiSearchCancelButton> createState() => _MiSearchCancelButtonState();
}

class _MiSearchCancelButtonState extends State<MiSearchCancelButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.themeMode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    final palette = MiSearchBarPalette.of(mode);
    // 圆盘填充 = 搜索栏填充（实测同色）；压在内容上时同款玻璃膜。
    final fill = widget.overContent
        ? MiTransparencyTokens.veiledFill(palette.fill, mode)
        : palette.fill;
    final pressHighlight = mode == MiThemeMode.dark
        ? MiTransparencyTokens.pressHighlightDark
        : MiTransparencyTokens.pressHighlightLight;

    Widget content = SizedBox(
      width: widget.diameter,
      height: widget.diameter,
      child: ClipOval(
        child: widget.frosted
            ? BackdropFilter(
                filter: MiFilterCache.blur(MiTransparencyTokens.blurSigma),
                child: _disc(fill, pressHighlight, palette),
              )
            : _disc(fill, pressHighlight, palette),
      ),
    );

    final onTap = widget.onTap;
    if (onTap == null) return IgnorePointer(child: content);
    content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: onTap,
      child: content,
    );
    return content;
  }

  /// 圆盘本体：填充 → 按压反馈圆盘 → 叉号。
  Widget _disc(Color fill, Color pressHighlight, MiSearchBarPalette palette) {
    return ColoredBox(
      color: fill,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _pressed ? 1 : 0,
              duration: Duration(
                milliseconds: _pressed
                    ? MiSearchCancelMetrics.pressFadeInMs
                    : MiSearchCancelMetrics.pressFadeOutMs,
              ),
              curve: Curves.easeOut,
              child: ColoredBox(color: pressHighlight),
            ),
          ),
          Center(
            child: CustomPaint(
              painter: SearchCancelGlyphPainter(palette.cancelInk),
              size: const Size.square(MiSearchCancelMetrics.glyphSize),
            ),
          ),
        ],
      ),
    );
  }
}

/// 取消钮叉号：两条 45° 直线，round cap，墨盒铺满到盒角内缩半个笔画。
///
/// 笔画 1.9dp（45° 水平弦实测 4px → 正交 2.83px），round cap 让端点在
/// 墨盒角内收 `stroke/2·√2` 才恰好触边 —— 与 [SearchIconPainter] 的手柄
/// 同一套收角算法。
class SearchCancelGlyphPainter extends CustomPainter {
  const SearchCancelGlyphPainter(this.color);

  /// 墨色（palette 的 `cancelInk`，实测前景墨色）。
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / MiSearchCancelMetrics.glyphSize;
    final stroke = MiSearchCancelMetrics.glyphStroke * k;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    // round cap 端点每轴内缩 stroke/2·√2，cap 外缘才落在盒角上。
    final inset = stroke / 2 * math.sqrt(0.5);
    final a = Offset(inset, inset);
    final b = Offset(size.width - inset, size.height - inset);
    canvas.drawLine(a, b, paint);
    canvas.drawLine(Offset(b.dx, a.dy), Offset(a.dx, b.dy), paint);
  }

  @override
  bool shouldRepaint(covariant SearchCancelGlyphPainter old) =>
      old.color != color;
}
