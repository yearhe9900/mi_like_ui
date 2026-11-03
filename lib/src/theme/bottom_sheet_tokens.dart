import 'package:flutter/painting.dart';

import 'dialog_tokens.dart';
import 'pull_up_panel_tokens.dart';
import 'theme_mode.dart';
import 'transparency_tokens.dart';

/// 底部弹窗配色（明暗双配方）—— **不新造色值**，全部引用既有 token：
///
///  * 表面 = **系统浮层表面同一档**（[MiPullUpPanelPalette]：暗 #2C2C2C /
///    亮 #FFFFFF）—— 弹窗、弹出面板、Snackbar 都是这一层，抽屉没有理由
///    再开一个表面色；比弹框卡片 #242424 高半档（那是对话框专用的不透明卡）；
///  * 标题墨色 = 弹框标题（[MiDialogPalette.title]，明暗双档实测墨色）；
///  * 遮罩 = 弹框遮罩档（黑 @0.20 / @0.60，见
///    [MiTransparencyTokens.dialogScrimProgressFor]），随滑入进度淡入；
///  * 拖拽手柄 = onSurface @0.20（按压 @0.35），见
///    [MiTransparencyTokens.sheetHandleFor]。
class MiBottomSheetPalette {
  const MiBottomSheetPalette._({
    required this.surface,
    required this.title,
    required this.scrim,
  });

  /// 抽屉表面（不透明，压在任意内容上读数一致）。
  final Color surface;

  /// 标题墨色。
  final Color title;

  /// 遮罩基色（`a` 已是终值；逐帧按进度取
  /// [MiTransparencyTokens.dialogScrimProgressFor]）。
  final Color scrim;

  /// 按明暗模式取配方。
  static MiBottomSheetPalette of(MiThemeMode mode) => mode == MiThemeMode.dark
      ? MiBottomSheetPalette._(
          surface: MiPullUpPanelPalette.dark.surface,
          title: MiDialogPalette.dark.title,
          scrim: MiTransparencyTokens.dialogScrimFor(mode),
        )
      : MiBottomSheetPalette._(
          surface: MiPullUpPanelPalette.light.surface,
          title: MiDialogPalette.light.title,
          scrim: MiTransparencyTokens.dialogScrimFor(mode),
        );

  /// 拖拽手柄色（[press] 0…1 在静止 / 按压两档之间插值）。
  Color handleFor(MiThemeMode mode, {double press = 0}) =>
      MiTransparencyTokens.sheetHandleFor(mode, press: press);
}
