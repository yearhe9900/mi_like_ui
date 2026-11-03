/// 示例层（demo）的页面与零件。
///
/// 对外只暴露 [MockPage]（页面路由入口）、[MiSearchShortcuts]（首页头部的
/// 搜索快捷入口）与 [DemoSearchPage]（推入的搜索页）；其余 `_` 前缀零件是
/// 实现细节。
///
/// 文件组织（同一 library 的 `part`，私有名跨文件可见，便于拆巨石而不改符号）：
///  * `pages/profile_page.dart`  ——「我的」设置页与外壳（[MockPage] 路由）
///  * `pages/home_page.dart`     —— 首页（横幅 / 主题卡网格）
///  * `pages/showcase_page.dart` ——「分类」展示页与四组组件陈列
///  * `pages/search_page.dart`   —— 推入式搜索页
library;


import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:mi_like_ui/mi_like_ui.dart';

part 'pages/profile_page.dart';
part 'pages/home_page.dart';
part 'pages/showcase_page.dart';
part 'pages/search_page.dart';


/// 页面内容左右页边距。
///
/// * compact（手机）：沿用 像素级度量值（首页 11.9 / 「我的」20）；
/// * medium / expanded（外壳已把画面铺成内容舞台）：收到 [MiDimens.spaceXxxl]
///   32 —— 宽画布上继续贴 11.9 会让内容顶到边，24 在 1000dp 以上仍偏窄。
double _pageInset(BuildContext context, double measured) =>
    MiViewport.of(context).isCompact ? measured : MiDimens.spaceXxxl;

/// 宽屏顶栏：搜索栏限宽（**推导值** 520）；手机 / 平板 = null（不限宽）。
///
/// 1120dp 的内容列上一条 1000dp+ 的搜索框既难用也不像桌面应用 —— 桌面
/// 搜索框通行宽度 400…600，取 520（= 内容列的一半不到，右侧留给动作区）。
double? _wideSearchMaxWidth(BuildContext context) =>
    MiViewport.of(context).isExpanded ? 520 : null;

/// 宽屏顶栏动作区：手机 / 平板 = null（**不渲染**，保持度量几何逐像素不变）。
///
/// [builder] 只在宽屏档被求值（动作件本身也是宽屏专属）。
List<Widget>? _wideActions(BuildContext context, List<Widget> Function() builder) =>
    MiViewport.of(context).isExpanded ? builder() : null;


/// 桌面键盘快捷键作用域（⌘K 聚焦搜索 / Esc 退出）。
///
/// **包装层结构恒定**（三档都挂 `MiSearchShortcuts`），只有 [MiSearchShortcuts.
/// autofocus] 随断点切：手机档不抢焦点（触屏没有物理键盘，抢一次焦点还会把
/// 搜索光标的闪烁相位推偏 —— 黄金图实测踩过）。
///
/// ⚠️ 不能写成「compact 档原样返回 child」：跨断点增删这一层会让下面的页面
/// Element 重建、滚动位置归零（`Focus`/`CallbackShortcuts` 换类型即换元素，
/// 同「内容列不能按断点增删」那条坑）。
Widget _keyboardScope(
  BuildContext context, {
  required VoidCallback onFocusSearch,
  required VoidCallback? onEscape,
  required Widget child,
}) =>
    MiSearchShortcuts(
      onFocusSearch: onFocusSearch,
      onEscape: onEscape,
      autofocus: !MiViewport.of(context).isCompact,
      child: child,
    );


/// 宽屏顶栏头部顶部让位（**推导值** 24）；手机 / 平板 = 度量 56。
///
/// 桌面窗口没有状态栏，继续留 56 会在窗口顶部悬出一条空带。
double _headerTopInset(BuildContext context) => MiViewport.of(context).isExpanded
    ? MiTopBarMetrics.desktopHeaderTopInset
    : MiTopBarMetrics.headerTopInset;


/// 顶栏右侧动作按钮（示例层）：⌀32 圆形热区 + 图标 painter。
///
/// 悬停叠色走框架的 [MiHoverFeedback]（实色，不引 saveLayer）；点按弹提示。
/// **不要给它套自带磨砂的子树** —— `MiTopBar.actions` 在搜索转场里会用
/// `Opacity` 淡出，磨砂进那层会被 saveLayer 清空底图。
class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.themeMode,
    required this.icon,
    required this.onTap,
  });

  final MiThemeMode themeMode;
  final CustomPainter icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MiHoverFeedback(
      mode: themeMode,
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: CustomPaint(painter: icon, size: const Size.square(18)),
          ),
        ),
      ),
    );
  }
}


/// 弹一条演示用提示（动作按钮 / 圆钮的统一反馈）。
/// 示例层的轻量消息条：投放到 demo 根部的 `MiPopupHost`（同类替换、
/// 不扰动页面栈；`ScaffoldMessenger` 的 Material 视觉与本库不一致）。
void _demoSnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  MiSnackbar.show(
    context,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}


/// 设置页风格 tokens 已收编为库组件（`MiSettingsCard` / `MiSettingsRow` /
/// `MiSettingsTile`，度量与配方见 `MiSettingsMetrics` / `MiSettingsPalette`）；
/// 此处只保留 demo 专属的头像块。

/// 设置页风格行占位点按（demo 层）：与圆钮/返回钮同一套 SnackBar 反馈。
void _mockTap(BuildContext context, String label) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label 被点击'),
        duration: const Duration(milliseconds: 800),
      ),
    );


class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.inset = 0});

  final String text;

  /// 左内缩：首页区块标题行度量 x46 ≈ 20.5dp（页边距 11.9 + 8.6），
  /// 较卡片图区多一档缩进、与卡标题缩进同源对齐；其余页面走默认 0。
  final double inset;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.only(top: 22, bottom: 12, left: inset),
      child: Text(
        text,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}


// ── 「组件展示」组（示例层）：库组件的可交互陈列 ────────────────────────────

/// 分组说明小字（示例层）：每个小节下方的口径说明。
Widget _demoNote(BuildContext context, String text) {
  final fg = Theme.of(context).colorScheme.onSurface;
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        height: 1.5,
        color: fg.withValues(alpha: 0.55),
      ),
    ),
  );
}


/// 弹层演示的空回调（命令式弹框的原 `onPressed` 仍会执行，演示不接行为）。
void _noop() {}
