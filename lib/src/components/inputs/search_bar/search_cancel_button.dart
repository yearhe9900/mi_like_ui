import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/search_bar_tokens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../utils/filter_cache.dart';
import '../../../utils/pressable.dart';
import 'search_cancel_metrics.dart';

/// 搜索态取消钮：⌀44.1 圆盘 + 叉号，点按退出搜索态。
///
/// 规格见 [MiSearchCancelMetrics]：直径等于搜索栏高（44.1dp，同一行
/// 自动垂直居中），与搜索栏间隔 10.0dp，右缘贴屏幕右缘。
///
/// ## 配色
///
///  * **圆盘填充 = 搜索栏填充**（[MiSearchBarPalette.fill]，同一行同色），
///    天然继承「半透明表面 + 可选玻璃膜」的透明语言；
///  * **叉号墨色 = 前景墨色**（可点控件的实心前景，与放大镜的图标灰
///    不同档）。
///
/// ## 磨砂 / 玻璃膜
///
/// 与搜索栏同规则：[frosted] 置于自带材质的顶栏内时传 `false`（整条栏
/// 只糊一次）；[overContent] 在填充之下加垫玻璃膜
/// （[MiTransparencyTokens.veiledFill]），平坦页面上观感不变。
class MiSearchCancelButton extends StatelessWidget {
  const MiSearchCancelButton({
    super.key,
    required this.onTap,
    this.themeMode,
    this.frosted = true,
    this.overContent = false,
    this.diameter = MiSearchCancelMetrics.diameter,
    this.fade = 1.0,
  }) : assert(fade >= 0 && fade <= 1);

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

  /// 淡入 / 淡出系数（0…1，默认 1 = 完全显示）。
  ///
  /// 供搜索态转场用：值乘进圆盘填充、按压反馈圆盘与叉号墨色的 alpha，
  /// 圆钮结构不变。
  ///
  /// **不要用父级 `Opacity` 代替**：圆钮内含 backdrop 磨砂（[frosted]），
  /// saveLayer 会让 backdrop 变空 —— 整段转场里磨砂消失，还每帧多一次
  /// 离屏合成（与搜索栏、胶囊行同一套规则）。
  final double fade;

  @override
  Widget build(BuildContext context) {
    final mode = themeMode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    final palette = MiSearchBarPalette.of(mode);
    // 淡入 / 淡出：alpha 乘进各层颜色（不做离屏合成，见 [fade]）。
    final f = fade;
    Color faded(Color c) => f >= 1 ? c : c.withValues(alpha: c.a * f);
    // 圆盘填充 = 搜索栏填充（度量同色）；压在内容上时同款玻璃膜。
    final fill = faded(overContent
        ? MiTransparencyTokens.veiledFill(palette.fill, mode)
        : palette.fill);
    final pressHighlight = faded(mode == MiThemeMode.dark
        ? MiTransparencyTokens.pressHighlightDark
        : MiTransparencyTokens.pressHighlightLight);
    final ink = faded(palette.cancelInk);

    // 叉号：圆盘内容的最内层。
    final glyph = Center(
      child: CustomPaint(
        painter: SearchCancelGlyphPainter(ink),
        size: const Size.square(MiSearchCancelMetrics.glyphSize),
      ),
    );

    // 填充层：填充 → 按压反馈圆盘 → 内容（叉号）。
    Widget fillLayer({required bool pressed, required Widget child}) =>
        ColoredBox(
          color: fill,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: pressed ? 1 : 0,
                  duration: Duration(
                    milliseconds: pressed
                        ? MiSearchCancelMetrics.pressFadeInMs
                        : MiSearchCancelMetrics.pressFadeOutMs,
                  ),
                  curve: Curves.easeOut,
                  child: ColoredBox(color: pressHighlight),
                ),
              ),
              child,
            ],
          ),
        );

    // 圆盘盒：裁形（+ 可选自绘磨砂）→ 填充层。层级与迁移前逐层等价
    //（手势层在盒外，由 MiPressable 提供）。
    Widget disc({required bool pressed, required Widget child}) => SizedBox(
          width: diameter,
          height: diameter,
          child: ClipOval(
            child: frosted && f > 0
                ? BackdropFilter(
                    filter: MiFilterCache.blur(MiTransparencyTokens.blurSigma),
                    child: fillLayer(pressed: pressed, child: child),
                  )
                : fillLayer(pressed: pressed, child: child),
          ),
        );

    // 禁用（onTap == null）：只展示、穿透命中（站点保留的早退契约）。
    if (onTap == null) {
      return IgnorePointer(child: disc(pressed: false, child: glyph));
    }
    // 按压状态机收编自 MiPressable；hover / focus 为**推导**的桌面语义
    //（触屏素材无此样张），圆钮为正圆，静止 / 未悬停时零像素。
    return MiPressable(
      onPressed: onTap,
      mode: mode,
      borderRadius: BorderRadius.circular(diameter / 2),
      pressBuilder: (context, pressed, child) =>
          disc(pressed: pressed, child: child),
      child: glyph,
    );
  }
}

/// 取消钮叉号：两条 45° 直线，round cap，墨盒铺满到盒角内缩半个笔画。
///
/// 笔画 1.9dp（45° 水平弦度量 4px → 正交 2.83px），round cap 让端点在
/// 墨盒角内收 `stroke/2·√2` 才恰好触边 —— 与 [SearchIconPainter] 的手柄
/// 同一套收角算法。
class SearchCancelGlyphPainter extends CustomPainter {
  const SearchCancelGlyphPainter(this.color);

  /// 墨色（palette 的 `cancelInk`，度量前景墨色）。
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
