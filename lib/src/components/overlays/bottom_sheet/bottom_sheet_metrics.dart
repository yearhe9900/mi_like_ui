import 'package:flutter/physics.dart';

import '../../../theme/motion_tokens.dart';

/// `MiBottomSheet` 的几何与动效规格。
///
/// **来源说明**：本库**没有底部抽屉的实机素材**（参考素材是主题商店 / 设置
/// 页截图，不含抽屉）。下列数值取自 `flutter_miuix` 的
/// `MiuixBottomSheetDefaults` 与其 `_SheetLayout`（其源自 HyperOS
/// `OverlayBottomSheet` 规格），属「参考实现值」；素材到位后应复核。
///
/// 取值口径：
///  * 圆角 28、**只圆上两角**（下缘贴屏）；宽屏限宽 640 —— 再宽的话
///    桌面端一条通栏抽屉会显得没有边界（与弹框 440 居中窄卡同一思路，
///    抽屉只是宽一档）；
///  * 左右内缩 24：标题行与内容同一条内缩（源实现的 `insideMargin`）；
///  * 拖拽手柄 45×4（圆角 2）、承托区高 24：手柄是本组件的**唯一拖拽
///    把手**（内容区要留给内部滚动，整面拖会与滚动抢手势）；按下时手柄
///    变长 + 变亮（[handlePressGrow] / [handlePressHeightGrow]），
///    「抓住」这件事要有反馈；
///  * 标题行上下 6 / 12，无标题时留 18 —— 抽屉顶缘不能贴内容，空标题也
///    要有一段呼吸；
///  * 滑入 / 滑出用同一条弹簧 [spring]（ζ ≈ 0.9、≈0.38s 收敛、过冲
///    ~0.15%）：抽屉是「贴底滑上来」而非「长出来」，用阻尼比高的弹簧，
///    只有极轻的一点回弹；源实现 stiffness 273.4 / ratio 0.9，按本库
///    Folme 口径换算即 `miSpring(damping: 0.9, response: 0.38)`
///   （stiffness = (2π/0.38)² ≈ 273.4，数值吻合）；
///  * 下拉关闭阈值：速度 > [flingVelocity]（dp/s）**或**位移 >
///    [dismissDistance] 且未在快速回拉 —— 上拖受 [dragResistance] 阻尼
///    （抽屉已贴底，上拉没有空间，只能表达「拉到头了」）；
///  * 手柄按压时长 100ms 入 / 150ms 出（短于常规 420ms 按压语言：手柄
///    是拖拽把手，反馈要跟手）。
class MiBottomSheetMetrics {
  MiBottomSheetMetrics._();

  // ── 几何 ───────────────────────────────────────────────────────────────

  /// 圆角（参考实现值 28；只圆上两角）。
  static const double cornerRadius = 28;

  /// 宽屏限宽（参考实现值 640）。
  static const double maxWidth = 640;

  /// 左右内缩（标题行、内容同一条）。
  static const double insideInset = 24;

  /// 顶缘让位：可用高 = 屏高 − 安全区上缘（参考实现口径）。
  static const double topReserve = 0;

  /// 标题行：上 / 下留白。
  static const double titleTop = 6;
  static const double titleBottom = 12;

  /// 无标题时的顶缘留白。
  static const double emptyTitleGap = 18;

  /// 手柄尺寸（静止态）。
  static const double handleWidth = 45;
  static const double handleHeight = 4;
  static const double handleRadius = 2;

  /// 手柄承托区高（拖拽热区）。
  static const double handleAreaHeight = 24;

  /// 手柄按压：宽度增量 / 高度比例增量。
  static const double handlePressGrow = 10;
  static const double handlePressHeightGrow = 0.15;

  /// 手柄按压时长：入 / 出（ms）。
  static const int handlePressInMs = 100;
  static const int handlePressOutMs = 150;

  // ── 动效 ───────────────────────────────────────────────────────────────

  /// 滑入 / 滑出弹簧（见类注释的换算）。
  static final SpringDescription spring =
      miSpring(damping: 0.9, response: 0.38);

  /// 弹簧上界：允许 ~0.15% 的轻微过冲（上界 1 会把那一点回弹钳平）。
  static const double springUpperBound = 1.02;

  // ── 下拉关闭 ───────────────────────────────────────────────────────────

  /// 关闭判定：速度阈值（dp/s）。
  static const double flingVelocity = 800;

  /// 关闭判定：位移阈值（dp，未在快速回拉时生效）。
  static const double dismissDistance = 150;

  /// 上拉阻尼（越过 0 位移后的位移折减）。
  static const double dragResistance = 0.1;
}
