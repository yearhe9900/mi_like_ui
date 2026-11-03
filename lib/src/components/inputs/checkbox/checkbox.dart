import 'package:flutter/material.dart';

import '../../../theme/checkbox_tokens.dart';
import '../../../theme/dimens.dart';
import '../../../theme/mi_theme.dart';
import '../../../theme/theme_mode.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../foundations/pressable.dart';
import 'checkbox_metrics.dart';
import 'checkbox_painter.dart';

/// 复选框（`MiCheckbox`）：⌀26 圆底 + 勾号，三态（开 / 关 / 半选）。
///
/// [value] 三档语义：`true` = 开（强调色圆底 + 白勾）、`false` = 关
/// （onSurface @12% 圆底、无勾）、`null` = **半选**（同开态圆底，勾号收拢成
/// 一条横杠 —— 列表「部分选中」的标准表达）。三态之间是**连续变形**：
/// 勾号先淡入、再沿路径划开（trim），半选与开态之间只改控制点位置
/// （几何与动效口径见 [MiCheckboxMetrics]）。
///
/// ```dart
/// MiCheckbox(
///   value: _agreed,
///   onChanged: (v) => setState(() => _agreed = v),
/// )
/// ```
///
/// ## 行为
///
///  * **点按**切换：`false → true → false`，半选 `null → true`（源实现的
///    语义：半选点一下即全选）—— 回调**永远给确定的下一态**，`onChanged`
///    的入参因此是 `bool` 而非 `bool?`；
///  * **禁用**（[onChanged] 为 null）：不响应点按、不可聚焦，整件降透明至
///    [MiDimens.disabledOpacity]（与开关 / 滑条同档）；
///  * **三态反馈**收编自 [MiPressable]：按压 = 圆底叠按压色（
///    [MiTransparencyTokens.dialogPressedFill]，150ms `easeOutQuad`；与按钮 /
///    弹框同一套按压语言，**不缩放**），另有悬停叠色与键盘焦点环；
///  * **不发震动**：触感属于业务语义（表单里每勾一项都震一下会很吵），
///    由调用方在 `onChanged` 里自行 `HapticFeedback` —— 与 `MiPullUpPanel`
///    「面板不越权代发触感」同一口径；
///  * **语义**：`checked` + `mixed`（半选）+ `enabled`，读屏可读出三态。
///
/// 尺寸固定 [MiCheckboxMetrics.size]；需要「复选行」时由宿主组合
/// （`MiSettingsRow` / `MiPreferenceTile` 一类行 + 尾部放本件）。
class MiCheckbox extends StatefulWidget {
  const MiCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.themeMode,
    this.hover = true,
    this.focus = true,
  });

  /// 画笔 key（测试读 painter 状态；不是公开 API 语义）。
  static const Key painterKey = Key('mi-checkbox-painter');

  /// 当前状态：`true` 开 / `false` 关 / `null` 半选。
  final bool? value;

  /// 切换回调（入参 = 下一态，恒非 null）；为 null 时禁用。
  final ValueChanged<bool>? onChanged;

  /// 明暗模式；为空时跟随 [MiTheme]，未声明时跟环境 `Theme` 亮度。
  final MiThemeMode? themeMode;

  /// 是否启用悬停反馈（叠色 + 手型光标；禁用时自动失效）。
  final bool hover;

  /// 是否启用键盘焦点（焦点环 + Enter / Space 激活；禁用时自动失效）。
  final bool focus;

  @override
  State<MiCheckbox> createState() => _MiCheckboxState();
}

class _MiCheckboxState extends State<MiCheckbox>
    with TickerProviderStateMixin {
  /// 勾号不透明度（0…1，半选同为 1）。
  late final AnimationController _alpha = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: MiCheckboxMetrics.alphaMs),
    value: _showsCheck(widget.value) ? 1 : 0,
  );

  /// 勾号 trim（0…1）。
  late final AnimationController _trim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: MiCheckboxMetrics.trimMs),
    value: _showsCheck(widget.value) ? 1 : 0,
  );

  /// 半选变形（0 = 勾号，1 = 横杠）。
  late final AnimationController _indet = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: MiCheckboxMetrics.indetMs),
    value: widget.value == null ? 1 : 0,
  );

  /// 开态与半选态都画勾号（半选只是把勾号收拢成横杠）。
  static bool _showsCheck(bool? value) => value != false;

  @override
  void didUpdateWidget(MiCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    final shows = _showsCheck(widget.value);
    _alpha.animateTo(
      shows ? 1 : 0,
      duration: const Duration(milliseconds: MiCheckboxMetrics.alphaMs),
      curve: MiCheckboxMetrics.transition,
    );
    _trim.animateTo(
      shows ? 1 : 0,
      duration: const Duration(milliseconds: MiCheckboxMetrics.trimMs),
      curve: MiCheckboxMetrics.transition,
    );
    _indet.animateTo(
      widget.value == null ? 1 : 0,
      duration: const Duration(milliseconds: MiCheckboxMetrics.indetMs),
      curve: MiCheckboxMetrics.transition,
    );
  }

  @override
  void dispose() {
    _alpha.dispose();
    _trim.dispose();
    _indet.dispose();
    super.dispose();
  }

  void _toggle() {
    // 半选 → 全选（源实现语义）；其余取反。
    widget.onChanged?.call(widget.value != true);
  }

  @override
  Widget build(BuildContext context) {
    final mode = MiTheme.modeOf(context, explicit: widget.themeMode);
    final palette = MiCheckboxPalette.of(mode);
    final enabled = widget.onChanged != null;
    final shows = _showsCheck(widget.value);
    final fill = shows ? palette.checkedFill : palette.uncheckedFill;

    Widget painted(double press, Widget box) => AnimatedBuilder(
          animation: Listenable.merge([_alpha, _trim, _indet]),
          builder: (context, child) => CustomPaint(
            key: MiCheckbox.painterKey,
            // 按压只在填充上叠色（标签 / 勾号不动 —— 与弹框按钮同配方）。
            painter: MiCheckboxPainter(
              fill: press <= 0
                  ? fill
                  : MiTransparencyTokens.dialogPressedFill(fill, mode),
              checkColor: palette.checkInk,
              alpha: _alpha.value,
              trim: _trim.value,
              indeterminate: _indet.value,
            ),
            child: child,
          ),
          child: box,
        );

    return Semantics(
      checked: widget.value ?? false,
      mixed: widget.value == null,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : MiDimens.disabledOpacity,
        child: MiPressable(
          onPressed: enabled ? _toggle : null,
          mode: mode,
          hover: widget.hover,
          focus: widget.focus,
          borderRadius: BorderRadius.circular(MiCheckboxMetrics.size / 2),
          // 按压叠色用隐式补间驱动（无需再开控制器）：t 进画笔做填充预合成。
          pressBuilder: (context, pressed, child) => TweenAnimationBuilder<double>(
            tween: Tween<double>(end: pressed ? 1 : 0),
            duration: const Duration(milliseconds: MiCheckboxMetrics.pressMs),
            curve: MiCheckboxMetrics.pressCurve,
            child: child,
            builder: (context, t, box) => painted(t, box!),
          ),
          child: const SizedBox.square(dimension: MiCheckboxMetrics.hitSize),
        ),
      ),
    );
  }
}
