///
/// * author: hunghd
/// * email: hunghd.yb@gmail.com
///
/// A package provides an easy way to add shimmer effect to Flutter application
///

library shimmer;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

///
/// An enum defines all supported directions of shimmer effect
///
/// * [ShimmerDirection.ltr] left to right direction
/// * [ShimmerDirection.rtl] right to left direction
/// * [ShimmerDirection.ttb] top to bottom direction
/// * [ShimmerDirection.btt] bottom to top direction
///
/// * [ShimmerDirection.blttr] bottomLeft to topRight direction
/// * [ShimmerDirection.brttl] bottomRight to topLeft direction
/// * [ShimmerDirection.tltbr] topLeft to bottomRight direction
/// * [ShimmerDirection.trtbl] topRight to BottomLeft direction
///
enum ShimmerDirection { ltr, rtl, ttb, btt, blttr, brttl, tltbr, trtbl }

///
/// A widget renders shimmer effect over [child] widget tree.
///
/// [child] defines an area that shimmer effect blends on. You can build [child]
/// from whatever [Widget] you like but there're some notices in order to get
/// exact expected effect and get better rendering performance:
///
/// * Use static [Widget] (which is an instance of [StatelessWidget]).
/// * [Widget] should be a solid color element. Every colors you set on these
/// [Widget]s will be overridden by colors of [gradient].
/// * Shimmer effect only affects to opaque areas of [child], transparent areas
/// still stays transparent.
///
/// [period] controls the speed of shimmer effect. The default value is 1500
/// milliseconds.
///
/// [direction] controls the direction of shimmer effect. The default value
/// is [ShimmerDirection.ltr].
///
/// [gradient] controls colors of shimmer effect.
///
/// [loop] the number of animation loop, set value of `0` to make animation run
/// forever.
///
/// [enabled] controls if shimmer effect is active. When set to false the animation
/// is paused
///
/// [hideOnDisabled] hides the shimmer effect when [enabled] is `false`.
///
///
/// ## Pro tips:
///
/// * [child] should be made of basic and simple [Widget]s, such as [Container],
/// [Row] and [Column], to avoid side effect.
///
/// * use one [Shimmer] to wrap list of [Widget]s instead of a list of many [Shimmer]s
///
@immutable
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration period;
  final Curve curve;
  final Duration delay;
  final ShimmerDirection direction;
  final Gradient gradient;
  final int loop;
  final bool enabled;
  final bool hideOnDisabled;

  const Shimmer({
    Key? key,
    required this.child,
    required this.gradient,
    this.direction = ShimmerDirection.ltr,
    this.delay = Duration.zero,
    this.period = const Duration(milliseconds: 1500),
    this.loop = 0,
    this.enabled = true,
    this.curve = Curves.linear,
    this.hideOnDisabled = false,
  }) : super(key: key);

  ///
  /// A convenient constructor provides an easy and convenient way to create a
  /// [Shimmer] which [gradient] is [LinearGradient] made up of `baseColor` and
  /// `highlightColor`.
  ///
  Shimmer.fromColors({
    Key? key,
    required this.child,
    required Color baseColor,
    required Color highlightColor,
    this.delay = Duration.zero,
    this.period = const Duration(milliseconds: 1500),
    this.direction = ShimmerDirection.ltr,
    this.loop = 0,
    this.enabled = true,
    this.curve = Curves.linear,
    this.hideOnDisabled = false,
  })  : gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            baseColor,
            baseColor,
            highlightColor,
            baseColor,
            baseColor
          ],
          stops: const <double>[0.0, 0.35, 0.5, 0.65, 1.0],
        ),
        super(key: key);

  @override
  _ShimmerState createState() => _ShimmerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Gradient>('gradient', gradient,
        defaultValue: null));
    properties.add(EnumProperty<ShimmerDirection>('direction', direction));
    properties.add(DiagnosticsProperty<Duration>('period', period,
        defaultValue: const Duration(milliseconds: 1500)));
    properties.add(DiagnosticsProperty<Duration>('delay', delay,
        defaultValue: Duration.zero));
    properties
        .add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: true));
    properties.add(DiagnosticsProperty<int>('loop', loop, defaultValue: 0));
  }
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..addStatusListener(_controllerStateListener);
    if (widget.enabled) {
      _controller.forward();
    }
  }

  Future<void> _controllerStateListener(AnimationStatus status) async {
    if (status != AnimationStatus.completed) {
      return;
    }
    _count++;
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
    }
    if (!mounted) {
      return;
    }
    if (widget.loop <= 0) {
      if (widget.delay == Duration.zero) {
        _controller.repeat();
      } else {
        _controller.forward(from: 0.0);
      }
    } else if (_count < widget.loop) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(Shimmer oldWidget) {
    if (widget.enabled) {
      _controller.forward();
    } else {
      _controller.stop();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _controller, curve: widget.curve),
      child: widget.child,
      builder: (BuildContext context, Widget? child) =>
          widget.hideOnDisabled && !widget.enabled
              ? child ?? Container()
              : _Shimmer(
                  child: child,
                  direction: widget.direction,
                  gradient: widget.gradient,
                  percent: _controller.value,
                ),
    );
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_controllerStateListener);
    _controller.dispose();
    super.dispose();
  }
}

@immutable
class _Shimmer extends SingleChildRenderObjectWidget {
  final double percent;
  final ShimmerDirection direction;
  final Gradient gradient;

  const _Shimmer({
    Widget? child,
    required this.percent,
    required this.direction,
    required this.gradient,
  }) : super(child: child);

  @override
  _ShimmerFilter createRenderObject(BuildContext context) {
    return _ShimmerFilter(percent, direction, gradient);
  }

  @override
  void updateRenderObject(BuildContext context, _ShimmerFilter shimmer) {
    shimmer.percent = percent;
    shimmer.gradient = gradient;
    shimmer.direction = direction;
  }
}

class _ShimmerFilter extends RenderProxyBox {
  ShimmerDirection _direction;
  Gradient _gradient;
  double _percent;

  _ShimmerFilter(this._percent, this._direction, this._gradient);

  @override
  ShaderMaskLayer? get layer => super.layer as ShaderMaskLayer?;

  @override
  bool get alwaysNeedsCompositing => child != null;

  set percent(double newValue) {
    if (newValue == _percent) {
      return;
    }
    _percent = newValue;
    markNeedsPaint();
  }

  set gradient(Gradient newValue) {
    if (newValue == _gradient) {
      return;
    }
    _gradient = newValue;
    markNeedsPaint();
  }

  set direction(ShimmerDirection newDirection) {
    if (newDirection == _direction) {
      return;
    }
    _direction = newDirection;
    markNeedsLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      assert(needsCompositing);

      final double width = child!.size.width;
      final double height = child!.size.height;
      Rect rect;
      double dx, dy;
      switch (_direction) {
        case ShimmerDirection.ltr:
          dx = _offset(-width, width, _percent);
          dy = 0.0;
          rect = Rect.fromLTWH(dx - width, dy, 3 * width, height);
          break;
        case ShimmerDirection.rtl:
          dx = _offset(width, -width, _percent);
          dy = 0.0;
          rect = Rect.fromLTWH(dx - width, dy, 3 * width, height);
          break;
        case ShimmerDirection.ttb:
          dx = 0.0;
          dy = _offset(-height, height, _percent);
          rect = Rect.fromLTWH(dx, dy - height, width, 3 * height);
          break;
        case ShimmerDirection.btt:
          dx = 0.0;
          dy = _offset(height, -height, _percent);
          rect = Rect.fromLTWH(dx, dy - height, width, 3 * height);
          break;
        case ShimmerDirection.blttr:
          dx = _offset(width, -width, _percent * 2);
          dy = _offset(height, -height, _percent * 2);
          rect = Rect.fromLTWH(width, dy - height, -3 * width, 6 * height);
          break;
        case ShimmerDirection.brttl:
          dx = _offset(width, -width, _percent * 1.5);
          dy = _offset(height, -height, _percent * 1.5);
          rect = Rect.fromLTWH(dx - width, dy - height, 4 * width, 6 * height);
          break;
        case ShimmerDirection.tltbr:
          dx = _offset(-width, width, _percent * 1.5);
          dy = _offset(-height, height, _percent * 1.5);
          rect = Rect.fromLTWH(dx - width, dy - height, 2 * width, 4 * height);
          break;
        case ShimmerDirection.trtbl:
          dx = _offset(width, -width, _percent * 1.5);
          dy = _offset(-height, height, _percent * 1.5);
          rect = Rect.fromLTWH(dx - width, height, 3 * width, -4 * height);
          break;
      }
      layer ??= ShaderMaskLayer();
      layer!
        ..shader = _gradient.createShader(rect)
        ..maskRect = offset & size
        ..blendMode = BlendMode.srcIn;
      context.pushLayer(layer!, super.paint, offset);
    } else {
      layer = null;
    }
  }

  double _offset(double start, double end, double percent) {
    return start + (end - start) * percent;
  }
}
