import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Authentic signature field-furrow & seed-sprout motif for Upajo.
/// Represents fertile furrowed earth and a resilient growing sprout.
class SeedSproutMotif extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? soilColor;

  const SeedSproutMotif({
    super.key,
    this.size = 56.0,
    this.color,
    this.soilColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SeedSproutPainter(
        sproutColor: color ?? AppColors.primary500,
        furrowColor: soilColor ?? AppColors.soil400,
      ),
    );
  }
}

class _SeedSproutPainter extends CustomPainter {
  final Color sproutColor;
  final Color furrowColor;

  _SeedSproutPainter({required this.sproutColor, required this.furrowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soil furrow base lines (curved tilled ridges)
    final furrowPaint = Paint()
      ..color = furrowColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;

    final baseLine1 = Path()
      ..moveTo(w * 0.15, h * 0.85)
      ..quadraticBezierTo(w * 0.5, h * 0.90, w * 0.85, h * 0.85);
    canvas.drawPath(baseLine1, furrowPaint);

    final baseLine2 = Path()
      ..moveTo(w * 0.25, h * 0.95)
      ..quadraticBezierTo(w * 0.5, h * 1.0, w * 0.75, h * 0.95);
    canvas.drawPath(baseLine2, furrowPaint);

    // Sprout stem
    final stemPaint = Paint()
      ..color = sproutColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()
      ..moveTo(w * 0.5, h * 0.85)
      ..cubicTo(w * 0.48, h * 0.65, w * 0.52, h * 0.45, w * 0.5, h * 0.25);
    canvas.drawPath(stemPath, stemPaint);

    // Left Leaf (Sprouting out)
    final leafPaint = Paint()
      ..color = sproutColor
      ..style = PaintingStyle.fill;

    final leftLeaf = Path()
      ..moveTo(w * 0.5, h * 0.45)
      ..cubicTo(w * 0.25, h * 0.40, w * 0.20, h * 0.25, w * 0.35, h * 0.20)
      ..cubicTo(w * 0.45, h * 0.25, w * 0.48, h * 0.35, w * 0.5, h * 0.45);
    canvas.drawPath(leftLeaf, leafPaint);

    // Right Leaf (Young shoot)
    final rightLeafPaint = Paint()
      ..color = sproutColor.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final rightLeaf = Path()
      ..moveTo(w * 0.5, h * 0.35)
      ..cubicTo(w * 0.70, h * 0.30, w * 0.75, h * 0.18, w * 0.62, h * 0.12)
      ..cubicTo(w * 0.52, h * 0.18, w * 0.50, h * 0.25, w * 0.5, h * 0.35);
    canvas.drawPath(rightLeaf, rightLeafPaint);
  }

  @override
  bool shouldRepaint(covariant _SeedSproutPainter oldDelegate) =>
      oldDelegate.sproutColor != sproutColor || oldDelegate.furrowColor != furrowColor;
}

/// A subtle decorative furrow wave bar for headers and dividers
class FurrowHeaderPattern extends StatelessWidget {
  final double height;
  final Color? color;

  const FurrowHeaderPattern({
    super.key,
    this.height = 12.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _FurrowPatternPainter(
          lineColor: color ?? AppColors.soil200,
        ),
      ),
    );
  }
}

class _FurrowPatternPainter extends CustomPainter {
  final Color lineColor;

  _FurrowPatternPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double step = 20.0;
    path.moveTo(0, size.height / 2);

    for (double x = 0; x < size.width; x += step) {
      path.relativeQuadraticBezierTo(step / 4, -4, step / 2, 0);
      path.relativeQuadraticBezierTo(step / 4, 4, step / 2, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FurrowPatternPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

