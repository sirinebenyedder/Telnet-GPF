import 'package:flutter/material.dart';
import 'dart:math';

class ShimmerButton extends StatefulWidget {
  final String text;
  final bool disabled;
  final ShimmerEffect effect;
  final ShimmerLevel level;
  final VoidCallback? onPressed;
  final bool showTextShine;
  final bool isRound;
  final double? width;
  final double? height;
  final IconData? icon;

  const ShimmerButton({
    super.key,
    required this.text,
    this.disabled = false,
    this.effect = ShimmerEffect.wipe2,
    this.level = ShimmerLevel.level0,
    this.onPressed,
    this.showTextShine = false,
    this.isRound = false,
    this.width,
    this.height,
    this.icon,
  });

  @override
  State<ShimmerButton> createState() => _ShimmerButtonState();
}

enum ShimmerEffect { spin, wipe, wipe2, pulse, pulse2, flicker, circular }

enum ShimmerLevel { level0, level1, level2 }

class _ShimmerButtonState extends State<ShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;
  bool _isPressed = false;

  // Color definitions
  static const Color shimmerColor1 = Color.fromARGB(255, 216, 217, 235);
  static const Color shimmerColor2 = Color.fromARGB(255, 200, 180, 255);
  static const Color shimmerColor3 = Color.fromARGB(255, 255, 180, 252);
  static const Color disabledColor = Color.fromARGB(255, 76, 76, 92);
  static const Color textColor = Color.fromARGB(255, 27, 23, 36);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1330),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit:
          (_) => setState(() {
            _isHovering = false;
            _isPressed = false;
          }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.disabled ? null : widget.onPressed,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale =
                _isPressed
                    ? 1.05
                    : _isHovering
                    ? _scaleAnimation.value
                    : 1.0;

            return Transform.scale(
              scale: scale,
              child: Container(
                width: widget.isRound ? widget.width ?? 150 : double.infinity,
                height:
                    widget.isRound
                        ? widget.height ?? 150
                        : null, // Fixed height for round buttons
                padding:
                    widget.isRound
                        ? EdgeInsets
                            .zero // No padding for round buttons
                        : const EdgeInsets.symmetric(
                          vertical: 12.8,
                          horizontal: 22.4,
                        ),
                decoration: BoxDecoration(
                  borderRadius:
                      widget.isRound
                          ? BorderRadius.circular(
                            widget.width != null ? widget.width! / 2 : 75,
                          ) // Fully round
                          : BorderRadius.circular(
                            10.56,
                          ), // Original rounded rectangle
                  gradient:
                      widget.disabled || widget.level == ShimmerLevel.level0
                          ? null
                          : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              shimmerColor1,
                              shimmerColor2,
                              shimmerColor3,
                            ],
                            stops: const [0.0, 0.47, 1.0],
                          ),
                  color:
                      widget.disabled
                          ? disabledColor
                          : widget.level == ShimmerLevel.level0
                          ? shimmerColor1
                          : null,
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        128,
                        34,
                        17,
                        51,
                      ).withOpacity(0.5),
                      blurRadius: 2,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shimmer effect
                    if (!widget.disabled &&
                        widget.level.index >= ShimmerLevel.level1.index)
                      Positioned.fill(child: _buildShimmerEffect()),

                    // Icon or Text
                    if (widget.isRound && widget.icon != null)
                      Icon(
                        widget.icon,
                        color: widget.disabled ? disabledColor : textColor,
                        size: widget.width != null ? widget.width! * 0.4 : 60,
                      )
                    else
                      Text(
                        widget.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              widget.showTextShine && !widget.disabled
                                  ? Colors.transparent
                                  : textColor,
                          background:
                              widget.showTextShine && !widget.disabled
                                  ? (Paint()
                                    ..shader = LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        const Color.fromARGB(
                                          168,
                                          255,
                                          200,
                                          255,
                                        ),
                                        const Color.fromARGB(
                                          230,
                                          255,
                                          230,
                                          255,
                                        ),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.4, 0.5, 0.52],
                                      transform: _TextGradientTransform(
                                        _controller.value,
                                      ),
                                    ).createShader(
                                      const Rect.fromLTWH(0, 0, 300, 300),
                                    ))
                                  : null,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    switch (widget.effect) {
      case ShimmerEffect.spin:
        return _buildSpinEffect();
      case ShimmerEffect.wipe:
        return _buildWipeEffect();
      case ShimmerEffect.wipe2:
        return _buildWipe2Effect();
      case ShimmerEffect.pulse:
        return _buildPulseEffect();
      case ShimmerEffect.pulse2:
        return _buildPulse2Effect();
      case ShimmerEffect.flicker:
        return _buildFlickerEffect();
      case ShimmerEffect.circular:
        return _buildCircularEffect();
    }
  }

  Widget _buildCircularEffect() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _CircularShimmerPainter(
            progress: _controller.value,
            borderWidth: 5.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  widget.isRound
                      ? BorderRadius.circular(
                        widget.width != null ? widget.width! / 2 : 75,
                      )
                      : BorderRadius.circular(10.56),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpinEffect() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConicMaskPainter(
            angle: _controller.value * 2 * pi,
            stops: const [0.0, 0.1, 0.36, 0.45, 0.5, 0.6, 0.85, 0.95, 1.0],
            isRound: widget.isRound,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  widget.isRound
                      ? BorderRadius.circular(
                        widget.width != null ? widget.width! / 2 : 75,
                      )
                      : BorderRadius.circular(10.56),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWipeEffect() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipPath(
          clipper: _WipeClipper(
            progress: _controller.value,
            direction: _WipeDirection.leftToRight,
            width: 0.2,
            isRound: widget.isRound,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  widget.isRound
                      ? BorderRadius.circular(
                        widget.width != null ? widget.width! / 2 : 75,
                      )
                      : BorderRadius.circular(10.56),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.8),
                  Colors.transparent,
                ],
                stops: const [0.2, 0.5, 0.8],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWipe2Effect() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipPath(
          clipper: _WipeClipper(
            progress: _controller.value * 2,
            direction: _WipeDirection.leftToRight,
            width: 0.3,
            isRound: widget.isRound,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  widget.isRound
                      ? BorderRadius.circular(
                        widget.width != null ? widget.width! / 2 : 75,
                      )
                      : BorderRadius.circular(10.56),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.9),
                  Colors.transparent,
                ],
                stops: const [0.15, 0.45, 0.55, 0.85],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulseEffect() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = _pulseOpacity(_controller.value);
        return Opacity(
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  widget.isRound
                      ? BorderRadius.circular(
                        widget.width != null ? widget.width! / 2 : 75,
                      )
                      : BorderRadius.circular(10.56),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [Colors.white.withOpacity(0.9), Colors.transparent],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulse2Effect() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = _pulse2Opacity(_controller.value);
        return Opacity(
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  widget.isRound
                      ? BorderRadius.circular(
                        widget.width != null ? widget.width! / 2 : 75,
                      )
                      : BorderRadius.circular(10.56),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [Colors.white.withOpacity(0.9), Colors.transparent],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlickerEffect() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = _flickerOpacity(_controller.value * 3.33);
        return Opacity(
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  widget.isRound
                      ? BorderRadius.circular(
                        widget.width != null ? widget.width! / 2 : 75,
                      )
                      : BorderRadius.circular(10.56),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [Colors.white.withOpacity(0.9), Colors.transparent],
              ),
            ),
          ),
        );
      },
    );
  }

  double _pulseOpacity(double progress) {
    if (progress < 0.2 / 3.0) {
      return progress * 15.0;
    } else if (progress < 0.9 / 3.0) {
      return 1.0 - (progress - 0.2 / 3.0) * 1.428;
    } else {
      return 0.0;
    }
  }

  double _pulse2Opacity(double progress) {
    if (progress < 0.08 / 3.0) {
      return progress * 12.5;
    } else if (progress < 0.14 / 3.0) {
      return 1.0 - (progress - 0.08 / 3.0) * 16.666;
    } else if (progress < 0.20 / 3.0) {
      return (progress - 0.14 / 3.0) * 16.666;
    } else {
      return 0.0;
    }
  }

  double _flickerOpacity(double progress) {
    // Simplified flicker pattern
    if (progress < 0.01) return 0.1;
    if (progress < 0.02) return 1.0;
    if (progress < 0.03) return 0.5;
    if (progress < 0.04) return 0.1;
    if (progress < 0.05) return 0.7;
    if (progress < 0.07) return 1.0;
    if (progress < 0.08) return 0.7;
    if (progress < 0.10) return 0.1;
    if (progress < 0.13) return 0.4;
    if (progress < 0.15) return 1.0;
    if (progress < 0.17) return 0.1;
    if (progress < 0.19) return 0.8;
    if (progress < 0.215) return 0.3;
    if (progress < 0.23) return 0.0;
    if (progress < 0.39) return 1.0;
    if (progress < 0.45) return 0.7;
    if (progress < 0.49) return 0.2;
    if (progress < 0.52) return 0.9;
    if (progress < 0.535) return 0.7;
    if (progress < 0.57) return 0.2;
    if (progress < 0.63) return 0.8;
    if (progress < 0.75) return 1.0;
    if (progress < 0.77) return 0.85;
    if (progress < 0.80) return 1.0;
    if (progress < 0.82) return 0.9;
    if (progress < 0.83) return 0.95;
    if (progress < 0.86) return 0.85;
    if (progress < 0.89) return 1.0;
    if (progress < 0.91) return 0.85;
    if (progress < 0.92) return 1.0;
    return 0.9;
  }
}

class _CircularShimmerPainter extends CustomPainter {
  final double progress;
  final double borderWidth;

  _CircularShimmerPainter({required this.progress, required this.borderWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Calculate the start and end angles for the arc
    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..strokeCap = StrokeCap.round;

    // Draw the shimmering arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - borderWidth / 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularShimmerPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        borderWidth != oldDelegate.borderWidth;
  }
}

class _ConicMaskPainter extends CustomPainter {
  final double angle;
  final List<double> stops;
  final bool isRound;

  _ConicMaskPainter({
    required this.angle,
    required this.stops,
    this.isRound = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint =
        Paint()
          ..shader = SweepGradient(
            startAngle: angle,
            endAngle: angle + 2 * pi,
            colors: List.generate(
              stops.length - 1,
              (i) => i % 2 == 0 ? Colors.transparent : Colors.black,
            ),
            stops: stops,
            transform: GradientRotation(angle),
          ).createShader(rect);

    if (isRound) {
      final center = Offset(size.width / 2, size.height / 2);
      final radius = min(size.width, size.height) / 2;
      canvas.drawCircle(center, radius, paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConicMaskPainter oldDelegate) {
    return angle != oldDelegate.angle ||
        stops != oldDelegate.stops ||
        isRound != oldDelegate.isRound;
  }
}

class _WipeClipper extends CustomClipper<Path> {
  final double progress;
  final _WipeDirection direction;
  final double width;
  final bool isRound;

  _WipeClipper({
    required this.progress,
    required this.direction,
    required this.width,
    this.isRound = false,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final adjustedProgress = progress % 1.0;

    if (isRound) {
      // For round buttons, create a circular clip with a rotating sector
      final center = Offset(size.width / 2, size.height / 2);
      final radius = min(size.width, size.height) / 2;

      if (direction == _WipeDirection.leftToRight) {
        final startX = size.width * (adjustedProgress - width);
        final endX = size.width * adjustedProgress;

        // Create a path that moves across the circle
        path.addOval(Rect.fromCircle(center: center, radius: radius));

        // Create a rectangular path to intersect with the circle
        final clipPath = Path();
        clipPath.addRect(Rect.fromLTWH(startX, 0, endX - startX, size.height));

        // Intersect paths to get only the part of the circle we want to show
        return Path.combine(PathOperation.intersect, path, clipPath);
      }
    } else {
      if (direction == _WipeDirection.leftToRight) {
        final startX = size.width * (adjustedProgress - width);
        final endX = size.width * adjustedProgress;

        path.moveTo(startX, 0);
        path.lineTo(endX, 0);
        path.lineTo(endX, size.height);
        path.lineTo(startX, size.height);
      } else {
        // Implement other directions if needed
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _WipeClipper oldClipper) {
    return progress != oldClipper.progress ||
        direction != oldClipper.direction ||
        width != oldClipper.width ||
        isRound != oldClipper.isRound;
  }
}

enum _WipeDirection { leftToRight, rightToLeft, topToBottom, bottomToTop }

class _TextGradientTransform extends GradientTransform {
  final double progress;

  const _TextGradientTransform(this.progress);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * (1.0 - progress * 2);
    return Matrix4.translationValues(dx, 0, 0);
  }
}
