/// [MiThemeCard] 的几何 / 文字参数：1:1 实测自主题商店首页「精选主题」截图。
///
/// Source: 881x1920 首页截图（1220x2656 原图等比缩放副本），亮色模式。
/// Scale to a 393 dp design width: s = 393 / 881 = 0.4461.
///
/// | item                     | shot px    | dp           |
/// |--------------------------|------------|--------------|
/// | image w x h (3 列)       | 259 x 472  | 115.5 x 210.6 |
/// | image radius (最小二乘拟合) | R = 44    | 19.6         |
/// | column gap               | 26.5       | 11.9         |
/// | page edge inset          | 25~28      | 11.9         |
/// | title pitch (CJK em)     | 31         | 13.85        |
/// | title indent from image  | 19.5       | 8.8          |
/// | image bottom -> title ink | 19        | 8*           |
/// | title -> next row image  | 35         | 15*          |
/// | row pitch (图顶 -> 图顶)  | 554        | 247          |
///
/// * ink -> 行盒换算：`height: 1.0` 行盒 = 字号（31px 字面 / ink 28px，
///   上下留白对称各 ≈1.5px）—— 图→标题墨迹 19px 扣上留白 ≈17.5px ≈
///   7.8dp，取 8；标题→次行图墨迹 35px 扣下留白 ≈33.5px ≈ 15。
///
/// 实测要点：
///  * 预览图固定宽高比 259:472（高 = 宽 / 比值，宽随父级）；圆角外缘
///    最小二乘拟合 R=44px ≈ 19.6dp，取 [MiDimens.radiusLg]（20）；
///  * 标题相对图片左缘内缩 19~20px —— 三张卡一致（45-26、330-310、
///    615-595）且与区块标题「精选主题」（x=46）同列，故为**左对齐 +
///    内缩**而非居中；
///  * 页面文本列 ≈20.5dp（区块标题 x46、查看更多右缘 x836），卡片图区
///    页边距 11.9dp（搜索框 28 / 横幅 25 / 卡片 25~26 同量级）—— 标题
///    内缩 8.8 恰把两者对齐，demo 首页壳层即按此布置；
///  * 标签字重 Medium（笔画核心 2~3px @31px em ≈ 0.07em，与胶囊标签同
///    档同值），单行省略。
///
/// 文字样式见 `theme/typography.dart`（[MiTypography.cardTitle]）；标题
/// 墨色经 `MiColors.foregroundFor(mode)` 取全框架前景色（截图最暗值 0
/// ≈ 近黑），故无独立配色 token。
class MiThemeCardMetrics {
  MiThemeCardMetrics._();

  /// 预览图宽高比 = 259:472 ≈ 0.549（实测 3 列卡图 259x472px）。
  static const double imageAspectRatio = 259 / 472;

  /// 标题相对图片左缘的内缩（实测 19~20px 三卡一致，取中 8.8dp）。
  static const double titleIndent = 8.8;

  /// 图片底 -> 标题行盒（实测墨迹 19px ≈ 8.5dp，扣字形上留白 ≈7.8dp，
  /// 取 8 ≈ [MiDimens.spaceSm]）。
  static const double titleTopGap = 8;

  /// 标题行盒底 -> 次行图片顶（实测墨迹 35px ≈ 15.6dp，扣字形下留白
  /// ≈15dp；行距 15 + 卡高 232.45 = 247.45 ≈ 实测行距 247）。
  static const double rowGap = 15;

  /// 网格列间距（实测 26.5px ≈ 11.8dp，与页边距同量级取 11.9）。
  static const double columnGap = 11.9;
}
