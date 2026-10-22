import 'package:flutter/material.dart';

import '../../../theme/transparency_tokens.dart';
import 'card_page_route_metrics.dart';

/// 卡片式页面推入转场：新页从右缘滑入、前缘带大圆角，下层页左移视差并压暗。
///
/// 规格见 [MiCardPageRouteMetrics]（逐帧度量）。用法与 `MaterialPageRoute`
/// 一致：
///
/// ```dart
/// Navigator.of(context).push(MiCardPageRoute<void>(
///   builder: (_) => const SearchPage(),
/// ));
/// ```
///
/// ## 两种角色
///
/// 一个路由在 `buildTransitions` 里可能是**上层**（正在进/出）或**下层**
/// （被别的路由压住），本类对两者分别处理：
///
///  * **上层**：`FractionalTranslation` 从 `+1`（整页在右缘外）滑到 `0`，
///    进度 `< 1` 时 `ClipRRect` 圆角 [MiCardPageRouteMetrics.cornerRadius]，
///    归位后不加任何图层（零额外 render object，静止页逐像素不变）；
///    同时在**自己的图层里**铺一层全屏压暗 —— 压暗不依赖下层页是谁，
///    即使下层是 `MaterialPageRoute` 也能得到同样的暗场。
///  * **下层**：`secondaryAnimation` 驱动左移视差
///    `−0.25 × 页宽 × 进度`（度量），只做位移、不缩放（度量依据见 metrics）。
///    **只有下层路由也是本类时才有视差** —— 平台自带路由没有这个钩子；
///    此时压暗仍由上层提供，视觉上只少一点点纵深。
///
/// ## 为什么压暗用纯色填充而不是 `Opacity`
///
/// `Opacity` / `FadeTransition` 会给整页引入 `saveLayer`，使下层
/// `BackdropFilter` 的 backdrop 变空 —— 转场期间磨砂整段消失。半透明
/// `ColoredBox` 只是一次普通绘制，不做离屏合成。
class MiCardPageRoute<T> extends PageRoute<T> {
  MiCardPageRoute({
    required this.builder,
    super.settings,
    this.cornerRadius = MiCardPageRouteMetrics.cornerRadius,
    this.parallaxFraction = MiCardPageRouteMetrics.parallaxFraction,
    this.motion = MiCardPageRouteMetrics.motion,
    Duration? duration,
  }) : _duration = duration;

  /// 新页内容。
  final WidgetBuilder builder;

  /// 新页前缘圆角（默认 [MiCardPageRouteMetrics.cornerRadius]）。
  final double cornerRadius;

  /// 下层页左移比例（× 页宽，默认 [MiCardPageRouteMetrics.parallaxFraction]）。
  final double parallaxFraction;

  /// 位置曲线（默认 [MiCardPageRouteMetrics.motion]，= `easeOutCubic`）。
  final Curve motion;

  final Duration? _duration;

  @override
  Duration get transitionDuration =>
      _duration ?? const Duration(milliseconds: MiCardPageRouteMetrics.durationMs);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  /// 保留下层页的状态（滚动位置、输入内容）：返回后不重新构建。
  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 下层：被别的路由压住 → 左移视差（压暗由上层负责，避免叠两次）。
    if (secondaryAnimation.status != AnimationStatus.dismissed) {
      return _MiPushParallax(
        animation: secondaryAnimation,
        motion: motion,
        fraction: parallaxFraction,
        child: child,
      );
    }
    // 上层：自己进/出场 → 滑入 + 圆角 + 压暗下层。
    if (animation.status != AnimationStatus.dismissed) {
      return _MiPushIncoming(
        animation: animation,
        motion: motion,
        cornerRadius: cornerRadius,
        child: child,
      );
    }
    return child;
  }
}

/// 上层页：全屏压暗 + 整页横向滑入（前缘圆角）。
class _MiPushIncoming extends StatelessWidget {
  const _MiPushIncoming({
    required this.animation,
    required this.motion,
    required this.cornerRadius,
    required this.child,
  });

  final Animation<double> animation;
  final Curve motion;
  final double cornerRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, page) {
        final progress = animation.value.clamp(0.0, 1.0);
        final visual = motion.transform(progress).clamp(0.0, 1.0);
        // 归位后：不加变换层、不裁剪、不铺遮罩（静止页零额外绘制）。
        if (visual >= 1) return page!;
        return Stack(
          children: [
            // 压暗在页面之下、屏幕之上：盖住下层页露出来的部分。
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: MiTransparencyTokens.pushDimAt(progress),
                ),
              ),
            ),
            // 整页横向位移按**页宽的比例**：不依赖具体窗口宽，缩放画布同理。
            Positioned.fill(
              child: FractionalTranslation(
                translation: Offset(1 - visual, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cornerRadius),
                  child: page,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 下层页：随上层进度左移 `−fraction × 页宽`（不缩放）。
class _MiPushParallax extends StatelessWidget {
  const _MiPushParallax({
    required this.animation,
    required this.motion,
    required this.fraction,
    required this.child,
  });

  final Animation<double> animation;
  final Curve motion;
  final double fraction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, page) {
        final progress = animation.value.clamp(0.0, 1.0);
        if (progress <= 0) return page!;
        final visual = motion.transform(progress).clamp(0.0, 1.0);
        return LayoutBuilder(
          builder: (context, constraints) => Transform.translate(
            offset: Offset(-fraction * constraints.maxWidth * visual, 0),
            child: page,
          ),
        );
      },
    );
  }
}
