import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/typography.dart';
import 'theme_card_metrics.dart';

/// 竖向预览卡片（明暗双模式）。
///
/// 结构 = 圆角预览图 + 下方左对齐标题（几何规格见 [MiThemeCardMetrics]，
/// 标题样式见 [MiTypography.cardTitle]）：
///
///  * [preview] 按 [MiThemeCardMetrics.imageAspectRatio]（259:472）定比
///    铺满图区 —— 宽随父级（需置于 `Expanded` / `SizedBox` 等有界容器，
///    两侧皆无界会抛 AspectRatio 约束错误），圆角 [MiDimens.radiusLg]；
///  * 标题单行省略，相对图左缘内缩 [MiThemeCardMetrics.titleIndent]
///    （与区块标题同列起排），与图间距 [MiThemeCardMetrics.titleTopGap]；
///  * 标题墨色经 `MiColors.foregroundFor` 取框架前景色。
///
/// [themeMode] 为空时跟随环境 `Theme.of(context).brightness`；[onTap]
/// 为空则不参与手势（无按压视觉反馈）。
class MiThemeCard extends StatelessWidget {
  const MiThemeCard({
    super.key,
    required this.title,
    required this.preview,
    this.onTap,
    this.themeMode,
  });

  /// 卡片标题（单行，超宽省略）。
  final String title;

  /// 锁屏预览内容，按图片区宽高比铺满并裁圆角。
  final Widget preview;

  /// 点按回调；null = 不参与手势。
  final VoidCallback? onTap;

  /// 明暗模式；null = 跟随环境 Theme 亮度。
  final MiThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    final mode = themeMode ??
        (Theme.of(context).brightness == Brightness.light
            ? MiThemeMode.light
            : MiThemeMode.dark);
    final card = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 预览图：宽随父级、按度量比例定高（AspectRatio 给子级 tight
        // 约束，任意 preview 都铺满）；ClipRRect 单层裁切 AA（preview
        // 是任意内容，不能像纯色填充那样借 Decoration 自带圆角）。
        AspectRatio(
          aspectRatio: MiThemeCardMetrics.imageAspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MiDimens.radiusLg),
            child: preview,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: MiThemeCardMetrics.titleIndent,
            top: MiThemeCardMetrics.titleTopGap,
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MiTypography.cardTitle.copyWith(
              color: MiColors.foregroundFor(mode),
            ),
          ),
        ),
      ],
    );
    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}
