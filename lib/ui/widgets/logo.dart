import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The MindDrop logo drawn in code (same geometry as assets/branding/logo.svg),
/// so it stays crisp at any size without an SVG dependency.
class LogoPainter extends CustomPainter {
  const LogoPainter({this.spark = 1, this.withBackground = false});

  /// Scale of the inner spark, used for the twinkle animation.
  final double spark;
  final bool withBackground;

  static const _dropRect = Rect.fromLTRB(124, 64, 388, 436);

  static Path _star(double cx, double cy, double rx, double ry, double pinch) {
    return Path()
      ..moveTo(cx, cy - ry)
      ..quadraticBezierTo(cx + pinch, cy - pinch, cx + rx, cy)
      ..quadraticBezierTo(cx + pinch, cy + pinch, cx, cy + ry)
      ..quadraticBezierTo(cx - pinch, cy + pinch, cx - rx, cy)
      ..quadraticBezierTo(cx - pinch, cy - pinch, cx, cy - ry)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 512;
    canvas.save();
    canvas.translate((size.width - 512 * scale) / 2, (size.height - 512 * scale) / 2);
    canvas.scale(scale);

    if (withBackground) {
      final bg = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 512, 512),
        const Radius.circular(116),
      );
      canvas.drawRRect(
        bg,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1648), Color(0xFF090A18)],
          ).createShader(bg.outerRect),
      );
    }

    // Soft glow behind the drop.
    const glowCenter = Offset(256, 300);
    canvas.drawCircle(
      glowCenter,
      210,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x8C7C5CFF), Color(0x007C5CFF)],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: 210)),
    );

    final drop = Path()
      ..moveTo(256, 64)
      ..cubicTo(300, 132, 388, 206, 388, 304)
      ..arcToPoint(
        const Offset(124, 304),
        radius: const Radius.circular(132),
        largeArc: true,
        clockwise: true,
      )
      ..cubicTo(124, 206, 212, 132, 256, 64)
      ..close();
    canvas.drawPath(
      drop,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-0.6, -1),
          end: Alignment(0.6, 1),
          colors: [Color(0xFFC084FC), Color(0xFF7C5CFF), Color(0xFF22D3EE)],
        ).createShader(_dropRect),
    );

    // Glossy highlight.
    final shine = Path()
      ..moveTo(206, 168)
      ..cubicTo(178, 206, 158, 246, 156, 292)
      ..cubicTo(155, 306, 170, 310, 174, 296)
      ..cubicTo(184, 254, 200, 222, 224, 186)
      ..cubicTo(232, 174, 216, 158, 206, 168)
      ..close();
    canvas.drawPath(
      shine,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x8CFFFFFF), Color(0x00FFFFFF)],
        ).createShader(const Rect.fromLTRB(155, 160, 232, 310)),
    );

    // The spark of an idea.
    final white = Paint()..color = Colors.white;
    canvas.save();
    canvas.translate(256, 306);
    canvas.scale(spark);
    canvas.translate(-256, -306);
    canvas.drawPath(_star(256, 306, 68, 70, 6), white);
    canvas.restore();

    final small = 0.75 + (1.2 - spark) * 1.2;
    canvas.save();
    canvas.translate(322, 238);
    canvas.scale(small.clamp(0.6, 1.25));
    canvas.translate(-322, -238);
    canvas.drawPath(
      _star(322, 238, 24, 24, 2),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.restore();

    canvas.drawCircle(
      const Offset(200, 372),
      9,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(LogoPainter oldDelegate) =>
      oldDelegate.spark != spark || oldDelegate.withBackground != withBackground;
}

class MindDropLogo extends StatelessWidget {
  const MindDropLogo({super.key, this.size = 40, this.withBackground = false});

  final double size;
  final bool withBackground;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: LogoPainter(withBackground: withBackground),
      );
}

/// The logo gently floating with a twinkling spark.
class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key, this.size = 160});

  final double size;

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return MindDropLogo(size: widget.size);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        return Transform.translate(
          offset: Offset(0, math.sin(t) * widget.size * 0.035),
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: LogoPainter(spark: 0.9 + 0.12 * math.sin(t * 2)),
          ),
        );
      },
    );
  }
}
