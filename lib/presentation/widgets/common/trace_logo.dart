// lib/presentation/widgets/common/trace_logo.dart
import 'package:flutter/material.dart';

class TraceLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const TraceLogo({
    super.key,
    this.size = 120,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TraceLogoPainter(color: themeColor),
      ),
    );
  }
}

class _TraceLogoPainter extends CustomPainter {
  final Color color;

  _TraceLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // --- 1. The stylized curved "T" shape ---
    // Top-left wing
    final tPath = Path();
    tPath.moveTo(w * 0.1, h * 0.15);
    tPath.lineTo(w * 0.35, h * 0.15);
    tPath.lineTo(w * 0.25, h * 0.25);
    tPath.lineTo(w * 0.15, h * 0.25);
    tPath.close();
    canvas.drawPath(tPath, paint);
    canvas.drawPath(tPath, fillPaint);

    // Main curved "T" bar tracing path
    final mainTPath = Path();
    mainTPath.moveTo(w * 0.4, h * 0.15);
    mainTPath.lineTo(w * 0.8, h * 0.15);
    mainTPath.lineTo(w * 0.75, h * 0.23);
    mainTPath.lineTo(w * 0.55, h * 0.23);
    // Draw sweeping curves for the stem down to the center
    mainTPath.quadraticBezierTo(w * 0.45, h * 0.23, w * 0.45, h * 0.4);
    mainTPath.lineTo(w * 0.45, h * 0.65);
    mainTPath.lineTo(w * 0.4, h * 0.65);
    mainTPath.lineTo(w * 0.4, h * 0.15);
    canvas.drawPath(mainTPath, paint);

    // Inside tracing path
    final innerTPath = Path();
    innerTPath.moveTo(w * 0.5, h * 0.2);
    innerTPath.quadraticBezierTo(w * 0.5, h * 0.28, w * 0.5, h * 0.42);
    innerTPath.lineTo(w * 0.5, h * 0.65);
    canvas.drawPath(innerTPath, paint);

    // --- 2. Symmetrical Laurel Wreath wrapping around the T ---
    final leftWreath = Path();
    leftWreath.moveTo(w * 0.15, h * 0.4);
    leftWreath.quadraticBezierTo(w * 0.1, h * 0.6, w * 0.35, h * 0.75);
    canvas.drawPath(leftWreath, paint);

    final rightWreath = Path();
    rightWreath.moveTo(w * 0.85, h * 0.4);
    rightWreath.quadraticBezierTo(w * 0.9, h * 0.6, w * 0.65, h * 0.75);
    canvas.drawPath(rightWreath, paint);

    // Wreath leaves - Left side
    for (int i = 0; i < 4; i++) {
      final leafY = h * (0.42 + i * 0.08);
      final leafX = w * (0.15 + i * 0.04);
      final leafPath = Path();
      leafPath.addOval(Rect.fromLTWH(leafX - w * 0.03, leafY - h * 0.02, w * 0.04, h * 0.03));
      canvas.drawPath(leafPath, paint);
      canvas.drawPath(leafPath, fillPaint);
    }

    // Wreath leaves - Right side
    for (int i = 0; i < 4; i++) {
      final leafY = h * (0.42 + i * 0.08);
      final leafX = w * (0.85 - i * 0.04);
      final leafPath = Path();
      leafPath.addOval(Rect.fromLTWH(leafX - w * 0.01, leafY - h * 0.02, w * 0.04, h * 0.03));
      canvas.drawPath(leafPath, paint);
      canvas.drawPath(leafPath, fillPaint);
    }

    // --- 3. The Anchor at the bottom center ---
    final anchorPath = Path();
    final ax = w * 0.5;
    final ay = h * 0.78;

    // Anchor stock & ring
    canvas.drawCircle(Offset(ax, ay), w * 0.025, paint);
    anchorPath.moveTo(ax, ay + w * 0.025);
    anchorPath.lineTo(ax, ay + h * 0.08);

    // Anchor crossbar
    anchorPath.moveTo(ax - w * 0.04, ay + h * 0.04);
    anchorPath.lineTo(ax + w * 0.04, ay + h * 0.04);

    // Anchor flukes (curved arc at bottom)
    anchorPath.moveTo(ax - w * 0.07, ay + h * 0.08);
    anchorPath.quadraticBezierTo(ax, ay + h * 0.12, ax + w * 0.07, ay + h * 0.08);

    // Left fluke point
    anchorPath.moveTo(ax - w * 0.07, ay + h * 0.08);
    anchorPath.lineTo(ax - w * 0.085, ay + h * 0.065);
    anchorPath.lineTo(ax - w * 0.05, ay + h * 0.07);

    // Right fluke point
    anchorPath.moveTo(ax + w * 0.07, ay + h * 0.08);
    anchorPath.lineTo(ax + w * 0.085, ay + h * 0.065);
    anchorPath.lineTo(ax + w * 0.05, ay + h * 0.07);

    canvas.drawPath(anchorPath, paint);
  }

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) => false;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
