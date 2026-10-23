import 'package:flutter/painting.dart';

import 'theme_mode.dart';
import 'transparency_tokens.dart';

/// 弹框配色令牌（明暗双配方）。
///
/// 全部为设计度量值（明暗各一组系统弹框参考素材；卡片与按钮填充取自
/// 平坦区域采样）。透明度字面量只定义于 `transparency_tokens.dart`，
/// 此处仅引用。
///
/// **卡片不透明**（亮 #FFFFFF / 暗 #242424，平坦无渐变，压在彩色内容上
/// 读数不变）；无投影。
class MiDialogPalette {
  const MiDialogPalette({
    required this.surface,
    required this.title,
    required this.secondaryText,
    required this.neutralActionFill,
    required this.filledActionFill,
    required this.filledActionLabel,
    required this.destructiveActionLabel,
    required this.divider,
    required this.scrim,
  });

  /// 卡片填充（度量：暗 #242424 / 亮 #FFFFFF）。
  final Color surface;

  /// 标题墨色（度量上下界：暗 ≥#F5F5F5 取纯白、亮 mode 精确 #000000）。
  final Color title;

  /// 次级文字色（正文 + 中性按钮标签；onSurface@0.80，见
  /// [MiTransparencyTokens.dialogTextSecondaryAlpha]）。
  final Color secondaryText;

  /// 中性按钮填充（度量：暗 #434343 / 亮 #F0F0F0）。
  final Color neutralActionFill;

  /// 主按钮（filled）填充（度量：暗 #478AFF / 亮 #3383FF —— 深色强调色
  /// 比亮色亮一档，两图平坦区内胆采样差 20 级 R 通道，非 JPEG 噪声）。
  final Color filledActionFill;

  /// 主按钮标签（度量亮色精确 #FFFFFF）。
  final Color filledActionLabel;

  /// 破坏性按钮标签（度量红：两图 mode #DC5448 / #D85040，差 4…8 级在
  /// 细笔画 JPEG 噪声内，取均值 #DA5244 明暗同值）。操作列表的危险项
  /// （整行红字）也用它。
  final Color destructiveActionLabel;

  /// 操作列表分隔线（onSurface @0.08，**推导值** —— 参考素材没有列表
  /// 形态样张，见 [MiTransparencyTokens.dialogDividerAlpha]）。
  final Color divider;

  /// 背景遮罩（黑 @0.20/0.60，见 [MiTransparencyTokens.dialogScrimFor]）。
  final Color scrim;

  /// 深色配方。
  static const MiDialogPalette dark = MiDialogPalette(
    surface: Color(0xFF242424),
    title: Color(0xFFFFFFFF),
    secondaryText: MiTransparencyTokens.dialogTextSecondaryDark,
    neutralActionFill: Color(0xFF434343),
    filledActionFill: Color(0xFF478AFF),
    filledActionLabel: Color(0xFFFFFFFF),
    destructiveActionLabel: Color(0xFFDA5244),
    divider: MiTransparencyTokens.dialogDividerDark,
    scrim: MiTransparencyTokens.dialogScrimDark,
  );

  /// 浅色配方。
  static const MiDialogPalette light = MiDialogPalette(
    surface: Color(0xFFFFFFFF),
    title: Color(0xFF000000),
    secondaryText: MiTransparencyTokens.dialogTextSecondaryLight,
    neutralActionFill: Color(0xFFF0F0F0),
    filledActionFill: Color(0xFF3383FF),
    filledActionLabel: Color(0xFFFFFFFF),
    destructiveActionLabel: Color(0xFFDA5244),
    divider: MiTransparencyTokens.dialogDividerLight,
    scrim: MiTransparencyTokens.dialogScrimLight,
  );

  /// 按明暗模式取配方。
  static MiDialogPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;
}
