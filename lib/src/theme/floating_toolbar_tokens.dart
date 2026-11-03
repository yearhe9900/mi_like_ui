import 'package:flutter/painting.dart';

import 'settings_tokens.dart';
import 'theme_mode.dart';
import 'transparency_tokens.dart';

/// 悬浮工具栏配色（明暗双配方）—— **不新造色值**，全部引用既有 token：
///
///  * 表面 = 设置分组卡同一档（[MiSettingsPalette.cardFor]：亮 #FFFFFF /
///    暗 #1E1E1E）—— 工具栏浮在页底之上，「比页底高一档的表面层」正是
///    设置卡的语言；不取系统浮层表面 #2C2C2C（那是压在内容上的模态层，
///    工具栏是常驻控件）；
///  * 描边 = 弹框分隔线色（onSurface @0.08，
///    [MiTransparencyTokens.dialogDividerFor]）—— 同一档「细边界」墨量；
///  * 投影 = 弹出面板投影色（黑 @0.12，[MiTransparencyTokens.panelShadow]），
///    几何固定见 [MiFloatingToolbarMetrics.shadowBlurRadius]。
class MiFloatingToolbarPalette {
  const MiFloatingToolbarPalette._({
    required this.surface,
    required this.divider,
    required this.shadow,
  });

  /// 表面填充。
  final Color surface;

  /// 描边色（[MiFloatingToolbar.showDivider] 时才画）。
  final Color divider;

  /// 投影色。
  final Color shadow;

  /// 按明暗模式取配方。
  static MiFloatingToolbarPalette of(MiThemeMode mode) =>
      MiFloatingToolbarPalette._(
        surface: MiSettingsPalette.cardFor(mode),
        divider: MiTransparencyTokens.dialogDividerFor(mode),
        shadow: MiTransparencyTokens.panelShadow,
      );
}
