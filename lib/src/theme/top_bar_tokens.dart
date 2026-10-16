import 'package:flutter/painting.dart';

import 'colors.dart';
import 'theme_mode.dart';

/// 顶部导航栏 [MiTopBar] 的配色 / 遮罩 token（明暗双配方）。
///
/// 深色配方 1:1 实测自参考录屏（1220×2656，HyperOS 设置「显示与亮度」页，
/// 采样密度 3.104 px/dp，逐帧分析）。
///
/// **顶栏遮挡是"实心段 + 渐隐裙边"的纯色遮罩，不是磨砂玻璃** —— 实测依据：
///  * 沿蓝卡填充色做纵向取样，透射比 m(y) = 1 − alpha(y) 实测为
///    0.01/0.03/0.07/0.14/0.22/0.26/0.47/0.53/0.82/0.96/1.00
///    （y = 64.4…128.9dp）；均匀色块在模糊下不会产生亮度斜坡，
///    故排除 backdrop 模糊；
///  * 同帧内卡片下缘 113 → 0 在 3px 内完成（无拖尾），进一步佐证无模糊；
///  * 拟合 `alpha(y) = 1 − clamp((y − 63.6) / 65.3, 0, 1)^1.5`：全不透明
///    段下沿 63.6dp、完全透明处 128.9dp（= `MiTopBarMetrics.scrimHeight`）。
///    下列渐变 stop 即该拟合的 8 等分采样，逐行注释给出 (y, alpha)。
///
/// 墨色沿用框架前景色 [MiColors.foreground]（实测标题笔画内部 246）；
/// 返回圆钮按压反馈为**白 @9.4%**（叠纯黑底实测 24 级，圆盘内均匀）。
///
/// 浅色配方**为推导**（参考录屏只有暗色，无亮色顶栏实测）：遮罩基色取
/// 项目实测亮色页底 #F3F3F3、按压反馈取同 alpha 的反相黑 @9.4%、墨色取
/// [MiColors.foregroundLight]，遮罩渐隐曲线与深色同一条。
class MiTopBarPalette {
  const MiTopBarPalette({
    required this.scrimGradient,
    required this.ink,
    required this.pressHighlight,
  });

  /// 顶栏遮罩：纵向渐变，顶部全不透明 → [MiTopBarMetrics.scrimHeight]
  /// 处完全透明（渐变坐标已按该高度归一化）。
  final Gradient scrimGradient;

  /// 标题墨色 / 返回箭头墨色。
  final Color ink;

  /// 返回圆钮按压反馈圆盘底色（半径 = 圆钮半径，实测平坦无角向变化）。
  final Color pressHighlight;

  /// 深色配方（录屏逐帧实测）。
  static const MiTopBarPalette dark = MiTopBarPalette(
    scrimGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [
        0.0, // y  0.0dp
        0.49340, // y 63.6dp  —— alpha 1.000（实心段下沿）
        0.55672, // y 71.8dp  —— 0.956
        0.62009, // y 79.9dp  —— 0.875
        0.68340, // y 88.1dp  —— 0.770
        0.74670, // y 96.3dp  —— 0.646
        0.81001, // y 104.4dp —— 0.506
        0.87339, // y 112.6dp —— 0.351
        0.93670, // y 120.7dp —— 0.182
        1.0, // y 128.9dp —— 0.000
      ],
      colors: [
        Color.fromRGBO(0, 0, 0, 1.000),
        Color.fromRGBO(0, 0, 0, 1.000),
        Color.fromRGBO(0, 0, 0, 0.956),
        Color.fromRGBO(0, 0, 0, 0.875),
        Color.fromRGBO(0, 0, 0, 0.770),
        Color.fromRGBO(0, 0, 0, 0.646),
        Color.fromRGBO(0, 0, 0, 0.506),
        Color.fromRGBO(0, 0, 0, 0.351),
        Color.fromRGBO(0, 0, 0, 0.182),
        Color.fromRGBO(0, 0, 0, 0.000),
      ],
    ),
    ink: MiColors.foreground,
    pressHighlight: Color.fromRGBO(255, 255, 255, 0.094),
  );

  /// 浅色配方（**推导**，无亮色参考录屏；遮罩基色 = 实测亮色页底 #F3F3F3）。
  static const MiTopBarPalette light = MiTopBarPalette(
    scrimGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [
        0.0,
        0.49340,
        0.55672,
        0.62009,
        0.68340,
        0.74670,
        0.81001,
        0.87339,
        0.93670,
        1.0,
      ],
      colors: [
        Color.fromRGBO(243, 243, 243, 1.000),
        Color.fromRGBO(243, 243, 243, 1.000),
        Color.fromRGBO(243, 243, 243, 0.956),
        Color.fromRGBO(243, 243, 243, 0.875),
        Color.fromRGBO(243, 243, 243, 0.770),
        Color.fromRGBO(243, 243, 243, 0.646),
        Color.fromRGBO(243, 243, 243, 0.506),
        Color.fromRGBO(243, 243, 243, 0.351),
        Color.fromRGBO(243, 243, 243, 0.182),
        Color.fromRGBO(243, 243, 243, 0.000),
      ],
    ),
    ink: MiColors.foregroundLight,
    pressHighlight: Color.fromRGBO(0, 0, 0, 0.094),
  );

  /// 按明暗模式取配方。
  static MiTopBarPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;
}
