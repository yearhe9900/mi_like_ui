import 'package:flutter/painting.dart';

import 'theme_mode.dart';
import 'transparency_tokens.dart';

/// 弹框配色 token（明暗双配方）。
///
/// 全部 1:1 实测自两张 MIUI 系统弹框参考图（联系人「删除联系人」+ 主题商店
/// 「删除1项资源」，各含亮/暗共 4 张截图；卡片填充与按钮填充为平坦区采样，
/// 抗 JPEG 噪声）。透明度相关的字面量只住在 `transparency_tokens.dart`，
/// 这里只引用。
///
/// **卡片不透明**（亮 #FFFFFF 纯白、暗 #242424 平坦无渐变，压在彩色缩略图
/// 上读数不变）—— 参考图无投影（卡片外侧 13px 平坦），故无阴影 token。
class MiDialogPalette {
  const MiDialogPalette({
    required this.surface,
    required this.title,
    required this.secondaryText,
    required this.neutralActionFill,
    required this.filledActionFill,
    required this.filledActionLabel,
    required this.destructiveActionLabel,
    required this.scrim,
  });

  /// 卡片填充（实测：暗 #242424 / 亮 #FFFFFF）。
  final Color surface;

  /// 标题墨色（实测上下界：暗 ≥#F5F5F5 取纯白、亮 mode 精确 #000000）。
  final Color title;

  /// 次级文字色（正文 + 中性按钮标签；onSurface@0.80，见
  /// [MiTransparencyTokens.dialogTextSecondaryAlpha]）。
  final Color secondaryText;

  /// 中性按钮填充（实测：暗 #434343 / 亮 #F0F0F0）。
  final Color neutralActionFill;

  /// 主按钮（filled）填充（实测：暗 #478AFF / 亮 #3383FF —— 深色强调色
  /// 比亮色亮一档，两图平坦区内胆采样差 20 级 R 通道，非 JPEG 噪声）。
  final Color filledActionFill;

  /// 主按钮标签（实测亮色精确 #FFFFFF）。
  final Color filledActionLabel;

  /// 破坏性按钮标签（实测红：两图 mode #DC5448 / #D85040，差 4…8 级在
  /// 细笔画 JPEG 噪声内，取均值 #DA5244 明暗同值）。
  final Color destructiveActionLabel;

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
    scrim: MiTransparencyTokens.dialogScrimLight,
  );

  /// 按明暗模式取配方。
  static MiDialogPalette of(MiThemeMode mode) =>
      mode == MiThemeMode.dark ? dark : light;
}
