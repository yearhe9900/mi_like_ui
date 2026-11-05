import 'package:flutter/animation.dart';

/// 菜单（`MiMenu`）几何、定位与动效规格。
///
/// **全部为参考实现值，不是本库实测度量**：本库没有菜单类组件的设计素材，
/// 数值取自 `flutter_miuix`（Apache-2.0）的 `MiuixListPopupDefaults` /
/// `MiuixDropdownDefaults`（其上游为 compose-miuix 的 HyperOS 组件规格），
/// 只把「参考实现的默认档」提成命名常量，便于日后拿到样张逐项替换并在
/// 这里改标「设计度量」。
///
/// 与参考实现的对应关系（括号里是上游字段名）：
///
/// | 本类 | 参考 | 值 |
/// |------|------|----|
/// | [cornerRadius] | `MiuixListPopupDefaults.cornerRadius` | 16 |
/// | [minWidth] / [maxWidth] | 列表列宽 clamp 区间 | 200 / 288 |
/// | [minHeight] | `MiuixListPopupDefaults.minPopupHeight` | 50 |
/// | [margin] | `dropdownPositionProvider(verticalMargin:)` | 8 |
/// | [rowInsetX] | `insideHorizontalPadding` | 20 |
/// | [rowPadY] / [rowEdgePadY] | `middle…` / `firstLastVerticalPadding` | 12 / 20 |
/// | [iconCell] / [iconGap] | `iconMinSize` / `iconEndPadding` | 26 / 12 |
/// | [checkSide] / [trailingGap] | `checkIconSize` / `checkIconStartPadding` | 20 / 12 |
/// | [arrowSize] | `chevronSize` | 10×16 |
/// | [dividerThickness] / [dividerInsetX] / [dividerPadY] | 分组分隔线 | 1.5 / 20 / 4 |
/// | [enterScale] | `0.15 + 0.85 × fraction` | 0.15 |
/// | [fractionSpring] | `fractionAnimationSpec`（ζ 0.82、k 362.5） | c = 31.2 |
/// | [alphaInMs] / [alphaOutMs] | `alphaEnter/ExitAnimationSpec` | 200 / 150 |
/// | [scrimInMs] / [scrimOutMs] | `dimEnter/ExitAnimationSpec` | 300 / 150 |
class MiMenuMetrics {
  MiMenuMetrics._();

  // ── 面板几何 ──────────────────────────────────────────────────────────

  /// 面板圆角（连续圆角，与弹框 / 抽屉同一画法）。
  static const double cornerRadius = 16;

  /// 面板宽度下限（内容再窄也按这个宽度出图）。
  static const double minWidth = 200;

  /// 面板宽度上限（超出后主文案单行省略）。
  static const double maxWidth = 288;

  /// 面板高度下限。
  static const double minHeight = 50;

  /// 面板与锚点、窗口边缘的留白。
  static const double margin = 8;

  // ── 行几何 ────────────────────────────────────────────────────────────

  /// 行左右内边距。
  static const double rowInsetX = 20;

  /// 中间行上下内边距。
  static const double rowPadY = 12;

  /// 首 / 末行上下内边距（整张菜单的上下两行，参考实现刻意给得更松）。
  static const double rowEdgePadY = 20;

  /// 前导图标单元格最小边长。
  static const double iconCell = 26;

  /// 前导图标与主文案的间距。
  static const double iconGap = 12;

  /// 尾部装饰（勾号 / 箭头）与文案的间距。
  static const double trailingGap = 12;

  /// 勾号墨盒边长。
  static const double checkSide = 20;

  /// 尾部箭头墨盒（宽×高）。
  static const Size arrowSize = Size(10, 16);

  /// 主 / 副文案行距（参考实现是紧凑堆叠，没有独立间距档）。
  static const double subtitleGap = 2;

  // ── 分组分隔线 ────────────────────────────────────────────────────────

  /// 分隔线粗细。
  static const double dividerThickness = 1.5;

  /// 分隔线左右内缩。
  static const double dividerInsetX = 20;

  /// 分隔线上下留白。
  static const double dividerPadY = 4;

  // ── 动效 ──────────────────────────────────────────────────────────────

  /// 展开 / 收起弹簧：ζ = 0.82、k = 362.5（参考 `fractionAnimationSpec`），
  /// 由 `c = 2ζ√(km)` 得阻尼 31.2 —— 轻微过冲，收起时略带回弹。
  static const SpringDescription fractionSpring = SpringDescription(
    mass: 1,
    stiffness: 362.5,
    damping: 31.2,
  );

  /// 面板缩放的起始比例（参考实现 `0.15 + 0.85 × fraction`）。
  static const double enterScale = 0.15;

  /// 淡入 / 淡出时长。
  static const int alphaInMs = 200;
  static const int alphaOutMs = 150;

  /// 淡入 / 淡出曲线（参考实现同为 `fastOutSlowIn`）。
  static const Curve alphaInCurve = Curves.fastOutSlowIn;
  static const Curve alphaOutCurve = Curves.fastOutSlowIn;

  /// 遮罩淡入 / 淡出时长与曲线（参考实现 300 / 150ms，正弦缓出）。
  static const int scrimInMs = 300;
  static const int scrimOutMs = 150;
  static const Curve scrimCurve = Curves.easeOutSine;

  /// 级联子菜单切换：淡入 + 0.95 → 1 缩放。
  static const int submenuMs = 200;
  static const double submenuScale = 0.95;

  /// 行按压高亮过渡（沿用弹框按钮 150ms `easeOutQuad` 的按压语言）。
  static const int pressMs = 150;
  static const Curve pressCurve = Curves.easeOutQuad;

  // ── 定位 ──────────────────────────────────────────────────────────────

  /// 面板左上角在**宿主坐标系**里的位置（[anchor] / [host] / [panel] 同系）。
  ///
  /// 规则（参考实现的 `_fallbackVerticalPosition` + 边缘夹紧）：
  ///
  ///  1. 横向**右缘对齐锚点右缘**（`alignment = end`）—— 菜单从触发点的
  ///     右侧生长，与右侧的箭头 / 图标同一竖向基准；
  ///  2. 纵向优先落在锚点**下方**（`anchor.bottom + margin`）；下方放不下
  ///     且上方放得下时翻到上方（`anchor.top - margin - 高度`）；
  ///  3. 两端都放不下（矮屏）时以锚点竖向中心居中，再夹紧到
  ///     `[margin, host - margin]` 之间 —— 宁可盖住锚点，也不让面板出界。
  static Offset panelOffset({
    required Rect anchor,
    required Size host,
    required Size panel,
  }) {
    final belowSpace = host.height - anchor.bottom - margin * 2;
    final aboveSpace = anchor.top - margin * 2;
    final double top;
    if (panel.height <= belowSpace) {
      top = anchor.bottom + margin;
    } else if (panel.height <= aboveSpace) {
      top = anchor.top - margin - panel.height;
    } else {
      top = anchor.center.dy - panel.height / 2;
    }
    final double left = anchor.right - panel.width;
    final maxLeft = (host.width - panel.width).clamp(0.0, double.infinity);
    final maxTop = (host.height - panel.height - margin).clamp(0.0, double.infinity);
    final minTop = margin <= maxTop ? margin : maxTop;
    return Offset(
      left.clamp(0.0, maxLeft),
      top.clamp(minTop, maxTop),
    );
  }

  /// 揭示动画是否**自下而上**展开（= 面板开在锚点上方）。
  ///
  /// 用「上下剩余空间谁大」判定，而不是等面板量出高度之后：揭示方向要在
  /// 首帧就定（决定裁剪边与缩放原点），而面板高度要等一次布局。两者在
  /// 「下方确实放得下」这个主路径上结论一致，只有矮屏折中档（上下都放不下、
  /// 居中盖住锚点）可能差一档 —— 那时裁剪边只影响 200ms 的展开方向，不影响
  /// 终态位置。
  static bool revealFromBottom({required Rect anchor, required Size host}) =>
      host.height - anchor.bottom < anchor.top;
}
