// lib/presentation/widgets/common/trace_logo.dart
import 'package:flutter/material.dart';

class TraceLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final double progress;

  const TraceLogo({
    super.key,
    this.size = 120,
    this.color,
    this.progress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TraceLogoPainter(color: themeColor, progress: progress),
      ),
    );
  }
}

class _TraceLogoPainter extends CustomPainter {
  final Color color;
  final double progress;

  _TraceLogoPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.15 * progress)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    void drawAnimatedPath(Path path, Paint p) {
      final pathMetrics = path.computeMetrics();
      for (final metric in pathMetrics) {
        final extractPath = metric.extractPath(0.0, metric.length * progress);
        canvas.drawPath(extractPath, p);
      }
    }

    // --- 1. The stylized curved "T" shape ---
    final tPath = Path();
    tPath.moveTo(w * 0.1, h * 0.15);
    tPath.lineTo(w * 0.35, h * 0.15);
    tPath.lineTo(w * 0.25, h * 0.25);
    tPath.lineTo(w * 0.15, h * 0.25);
    tPath.close();
    drawAnimatedPath(tPath, paint);
    if (progress > 0.8) canvas.drawPath(tPath, fillPaint);

    final mainTPath = Path();
    mainTPath.moveTo(w * 0.4, h * 0.15);
    mainTPath.lineTo(w * 0.8, h * 0.15);
    mainTPath.lineTo(w * 0.75, h * 0.23);
    mainTPath.lineTo(w * 0.55, h * 0.23);
    mainTPath.quadraticBezierTo(w * 0.45, h * 0.23, w * 0.45, h * 0.4);
    mainTPath.lineTo(w * 0.45, h * 0.65);
    mainTPath.lineTo(w * 0.4, h * 0.65);
    mainTPath.lineTo(w * 0.4, h * 0.15);
    drawAnimatedPath(mainTPath, paint);

    final innerTPath = Path();
    innerTPath.moveTo(w * 0.5, h * 0.2);
    innerTPath.quadraticBezierTo(w * 0.5, h * 0.28, w * 0.5, h * 0.42);
    innerTPath.lineTo(w * 0.5, h * 0.65);
    drawAnimatedPath(innerTPath, paint);

    // --- 2. Symmetrical Laurel Wreath ---
    final leftWreath = Path();
    leftWreath.moveTo(w * 0.15, h * 0.4);
    leftWreath.quadraticBezierTo(w * 0.1, h * 0.6, w * 0.35, h * 0.75);
    drawAnimatedPath(leftWreath, paint);

    final rightWreath = Path();
    rightWreath.moveTo(w * 0.85, h * 0.4);
    rightWreath.quadraticBezierTo(w * 0.9, h * 0.6, w * 0.65, h * 0.75);
    drawAnimatedPath(rightWreath, paint);

    // Wreath leaves
    if (progress > 0.5) {
      final leafProgress = (progress - 0.5) / 0.5;
      for (int i = 0; i < 4; i++) {
        final leafY = h * (0.42 + i * 0.08);
        final leafXLeft = w * (0.15 + i * 0.04);
        final leafXRight = w * (0.85 - i * 0.04);
        
        final leafPathLeft = Path();
        leafPathLeft.addOval(Rect.fromLTWH(leafXLeft - w * 0.03, leafY - h * 0.02, w * 0.04, h * 0.03));
        drawAnimatedPath(leafPathLeft, paint..color = color.withOpacity(leafProgress));
        
        final leafPathRight = Path();
        leafPathRight.addOval(Rect.fromLTWH(leafXRight - w * 0.01, leafY - h * 0.02, w * 0.04, h * 0.03));
        drawAnimatedPath(leafPathRight, paint..color = color.withOpacity(leafProgress));
      }
    }

    // --- 3. The Anchor ---
    if (progress > 0.3) {
      final anchorProgress = (progress - 0.3) / 0.7;
      final anchorPath = Path();
      final ax = w * 0.5;
      final ay = h * 0.78;

      canvas.drawCircle(Offset(ax, ay), w * 0.025 * anchorProgress, paint);
      anchorPath.moveTo(ax, ay + w * 0.025);
      anchorPath.lineTo(ax, ay + h * 0.08);
      anchorPath.moveTo(ax - w * 0.04, ay + h * 0.04);
      anchorPath.lineTo(ax + w * 0.04, ay + h * 0.04);
      anchorPath.moveTo(ax - w * 0.07, ay + h * 0.08);
      anchorPath.quadraticBezierTo(ax, ay + h * 0.12, ax + w * 0.07, ay + h * 0.08);
      anchorPath.moveTo(ax - w * 0.07, ay + h * 0.08);
      anchorPath.lineTo(ax - w * 0.085, ay + h * 0.065);
      anchorPath.lineTo(ax - w * 0.05, ay + h * 0.07);
      anchorPath.moveTo(ax + w * 0.07, ay + h * 0.08);
      anchorPath.lineTo(ax + w * 0.085, ay + h * 0.065);
      anchorPath.lineTo(ax + w * 0.05, ay + h * 0.07);
      
      drawAnimatedPath(anchorPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TraceLogoPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.color != color;
}
