import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/transparency_tokens.dart';
import '../../../utils/squircle.dart';
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

  /// 宽屏档淡入幕布的 key（测试用来读当前 alpha；不是公开 API 语义）。
  static const Key wideVeilKey = Key('mi-route-wide-veil');

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
    // 宽屏档（窗口 ≥ 1024）：换桌面通行的「淡入 + 4dp 抬起」转场 ——
    // 手机档的「大圆角滑入 + 视差」在桌面读作「两个窗口叠在一起」。
    //
    // ⚠️ 淡入**不能**用 `Opacity` / `FadeTransition`：新页里含磨砂顶栏
    // （`BackdropFilter`），给它套 saveLayer 会让 backdrop 变空 —— 转场期间
    // 磨砂整段消失（本项目已实测的坑）。改用**同色幕布**：新页本身不透明、
    // 上面盖一层页底色实色（`ColoredBox`，无离屏合成），幕布 alpha 1 → 0
    // 就是观感上的淡入。
    final wide = MiCardPageRouteMetrics.isWide(
      MediaQuery.sizeOf(context).width,
    );
    if (wide) {
      // 下层：桌面窗口不做视差（也不压暗 —— 幕布由上层画）。
      if (secondaryAnimation.status != AnimationStatus.dismissed) {
        return child;
      }
      if (animation.status != AnimationStatus.dismissed) {
        return _MiPushWide(
          animation: animation,
          motion: motion,
          cornerRadius:
              math.min(cornerRadius, MiCardPageRouteMetrics.wideCornerRadius),
          child: child,
        );
      }
      return child;
    }
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
                child: ClipPath(
                  clipper: MiSquircleClipper(cornerRadius),
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
        // 位移按**页宽的比例** → `FractionalTranslation`（绘制期变换，不参与
        // 布局）。旧写法是 `LayoutBuilder + Transform.translate`：每帧重建
        // builder、多跑一次布局，而这里只需要一个平移。
        return FractionalTranslation(
          translation: Offset(-fraction * visual, 0),
          child: page,
        );
      },
    );
  }
}

/// 上层页（**桌面档**）：4dp 抬起落位 + 同色幕布淡入（前缘小圆角）。
///
/// 与手机档的 [_MiPushIncoming] 的差别（全部推导，见
/// [MiCardPageRouteMetrics] 宽屏档注释）：
///
///  * **不横移、不压暗下层**（桌面窗口没有「叠两个窗口」的读法）；
///  * **淡入用幕布而不是 `Opacity`**：新页含磨砂顶栏（`BackdropFilter`），
///    给它套 saveLayer 会让 backdrop 变空 —— 转场期间磨砂整段消失（本项目
///    已实测的坑）。改在新页**之上**盖一层页底色实色（`ColoredBox`，
///    一次普通绘制、无离屏合成），alpha 1 → 0 即观感上的淡入；
///  * 视觉时长 = 前 [MiCardPageRouteMetrics.wideVisualFraction] 段
///    （220ms，`Interval`），之后直接返回原页（零额外图层）。
class _MiPushWide extends StatelessWidget {
  const _MiPushWide({
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
    // 幕布色 = 页底色（亮 #F3F3F3 / 暗 #000000），与本库页面同底 ——
    // 淡入读作「从页面底色里浮出来」，不是「从黑色里亮起来」。
    final veilColor = Theme.of(context).brightness == Brightness.light
        ? MiColors.pageBackgroundLight
        : MiColors.pageBackgroundDark;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, page) {
        final progress = animation.value.clamp(0.0, 1.0);
        // 归位（视觉完成）：不加变换层、不裁剪、不铺幕布（零额外绘制）。
        if (progress >= MiCardPageRouteMetrics.wideVisualFraction) return page!;
        // 视觉进度：0 → 1 落在前 55%（220ms）里，其后由上面的分支接管。
        final visual = motion
            .transform(
              (progress / MiCardPageRouteMetrics.wideVisualFraction)
                  .clamp(0.0, 1.0),
            )
            .clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            // 4dp 抬起落位（自下而上）+ 转场期小圆角。
            Transform.translate(
              offset: Offset(0, MiCardPageRouteMetrics.wideRiseDp * (1 - visual)),
              child: ClipPath(
                clipper: MiSquircleClipper(cornerRadius),
                child: page,
              ),
            ),
            // 同色幕布：alpha 1 → 0。`IgnorePointer` 防止淡入途中吃点击。
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  key: MiCardPageRoute.wideVeilKey,
                  color: Color.fromRGBO(
                    veilColor.red,
                    veilColor.green,
                    veilColor.blue,
                    1 - visual,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
