/// [MiPillTabBar] 的几何 / 文字参数：1:1 实测自完整分类 tab 截图。
///
/// Source: 1220x2656 px full screenshots of the theme-store 分类 tab
/// (light & dark — geometry identical). Scale to a 393 dp design width:
/// s = 393 / 1220 = 0.32213.
///
/// | item                    | shot px | dp        |
/// |-------------------------|---------|-----------|
/// | pill size               | 272 x 124 | 87.6 x 39.9 |
/// | pill gap                | 37      | 11.9      |
/// | strip edge inset        | 37      | 11.9      |
/// | label pitch (CJK em)    | 43      | 13.85     |
///
/// 实测要点：
///  * 4 个胶囊等宽定宽（2 字与 3 字标签同宽），不随标签字数变化；
///  * 标签行横向可滚动 —— 第 4 个胶囊被屏幕右缘裁切 16px（行内容宽
///    11.9 + n×87.6 + (n-1)×11.9 + 11.9 = 410dp 超出 393dp 视口）；
///  * 胶囊为 stadium 形：圆角外缘拟合 R=63px ≈ 高/2(62px)，取
///    [MiDimens.radiusPill]（半径钳位后渲染即 stadium）；纯平填充，
///    无描边无投影；
///  * 标签字重 Medium（笔画核心 3~4px @ 43px em ≈ 0.08em）。
///
/// 注：初版按 1220x266 裁剪图实测（276x125 / 32.5 / 34.5 / 裁切 17.5），
/// 该裁剪图被编辑放大 ~1.5%，数值整体偏大且间距失真，已废弃；
/// 本表以完整原图为准（881x1920 副本等比复核一致）。
///
/// 文字样式见 `theme/typography.dart`，配色见 `theme/pill_tab_tokens.dart`。
class MiPillTabMetrics {
  MiPillTabMetrics._();

  /// 单个胶囊宽度（定宽，不随标签字数变化）。
  static const double itemWidth = 87.6;

  /// 胶囊高度。
  static const double pillHeight = 39.9;

  /// 相邻胶囊间距。
  static const double gap = 11.9;

  /// 标签行首/尾内边距（横滑内容区，与搜索框等页面内容同为 37px 页边距）。
  static const double edgeInset = 11.9;
}
