import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/dimens.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/typography.dart';
import 'theme_card_metrics.dart';

/// 小米主题商店风格的竖向预览卡片（深/浅色双模式）。
///
/// 结构 = 圆角锁屏预览图 + 下方左对齐标题（几何 1:1 实测见
/// [MiThemeCardMetrics]，标题样式见 [MiTypography.cardTitle]）：
///  * [preview] 按 [MiThemeCardMetrics.imageAspectRatio]（实测 259:472）
///    定比铺满图区 —— 宽随父级（放进 Expanded / SizedBox 等**有界**容器，
///    两侧皆无界会抛 AspectRatio 约束错误），圆角取 [MiDimens.radiusLg]
///    （外缘拟合 R=44px ≈ 19.6dp）；
///  * 标题单行省略，相对图左缘内缩 [MiThemeCardMetrics.titleIndent]
///    （实测 19~20px，三张卡一致、非居中 —— 内缩后恰与区块标题同列
///    起排），与图间距 [MiThemeCardMetrics.titleTopGap]；
///  * 标题墨色经 `MiColors.foregroundFor` 取框架前景色（深 #F5F5F5 /
///    浅 #050505，截图最暗值 0 ≈ 近黑）。
///
/// [themeMode] 为空时跟随环境 `Theme.of(context).brightness`（demo 首页
/// const 列表里的用法即靠此推导，与 MiSearchBar 同约定）；[onTap] 为空
/// 则不参与手势 —— 参考图为静态截图、无按压实测，故点按不加视觉反馈。
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
        // 预览图：宽随父级、按实测比例定高（AspectRatio 给子级 tight
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
