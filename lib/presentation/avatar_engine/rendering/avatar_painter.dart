import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/avatar_config.dart';
import '../models/engine_state.dart';

/// Ultimate Dynamic Renderer combining the absolute full library of hair/eye/outfit customizations 
/// seamlessly coupled with Angular Kinematics, Lung Deformation, and Ambient VFX.
class AvatarPainter extends CustomPainter {
  final AvatarConfig config;
  final AvatarRenderSnapshot snapshot;
  final double renderSize;

  AvatarPainter({
    required this.config,
    required this.snapshot,
    this.renderSize = 100.0,
  });

  bool get _isMicro => renderSize <= 40;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double ox = w / 2;
    final double oy = h * 0.48;
    final Paint paint = Paint()..isAntiAlias = true;

    // ─── 1. GLOBAL BACKGROUND ───
    final Color bg = _parseColor(config.bgColor);
    if (!_isMicro && config.bgStyle > 0) {
      if (config.bgStyle == 1) {
        paint.shader = RadialGradient(colors: [bg.withValues(alpha: 0.6), bg], stops: const [0.0, 1.0]).createShader(Rect.fromCircle(center: Offset(ox, oy), radius: w / 2));
      } else if (config.bgStyle == 2) {
        paint.shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [bg.withValues(alpha: 0.8), bg], stops: const [0.4, 0.6]).createShader(Rect.fromCircle(center: Offset(ox, oy), radius: w / 2));
      } else if (config.bgStyle == 3) {
        paint.shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.2), bg, bg.withValues(alpha: 0.8)], stops: const [0.0, 0.5, 1.0], center: const Alignment(0, -0.2)).createShader(Rect.fromCircle(center: Offset(ox, oy), radius: w / 2));
      }
    } else {
      if (!_isMicro) {
        paint.shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bg, bg.withValues(alpha: 0.85)]).createShader(Rect.fromCircle(center: Offset(ox, oy), radius: w / 2));
      } else { paint.color = bg; }
    }
    canvas.drawCircle(Offset(ox, oy), w / 2, paint);
    paint.shader = null;

    canvas.save();
    final Path clipPath = Path()..addOval(Rect.fromLTWH(0, 0, w, h));
    canvas.clipPath(clipPath);

    // ─── ATMOSPHERE LAYER ───
    if (!_isMicro && config.bgStyle > 0) {
      final double time = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final double intensity = snapshot.moodColorIntensity;
      paint.style = PaintingStyle.fill;
      paint.color = Colors.white.withValues(alpha: 0.15 + (intensity * 0.1));
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.08);
      final double orbX = ox + math.cos(time * 0.8) * (w * 0.3);
      final double orbY = oy + math.sin(time * 0.8) * (h * 0.2);
      canvas.drawCircle(Offset(orbX, orbY), w * 0.2, paint);
      paint.maskFilter = null;
    }

    // Silhouette
    if (!_isMicro) {
      final Paint silhouetteShadow = Paint()..color = Colors.black.withValues(alpha: 0.1)..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05);
      canvas.drawOval(Rect.fromCenter(center: Offset(ox, oy + h * 0.1), width: w * 0.65, height: h * 0.7), silhouetteShadow);
    }

    // ─── 2. BREATHING OUTFITS LAYER ───
    canvas.save();
    canvas.translate(0, -snapshot.breathExpansion * h * 0.008); // Dynamic Lift
    final Color outfit = _parseColor(config.outfitColor);
    paint.color = outfit; paint.style = PaintingStyle.fill;

    if (config.outfit == 1) { // Hoodie
      paint.color = outfit.withValues(alpha: 0.7);
      final Path hood = Path()..moveTo(ox - w * 0.22, oy - h * 0.08)..quadraticBezierTo(ox, oy - h * 0.25, ox + w * 0.22, oy - h * 0.08)..quadraticBezierTo(ox + w * 0.3, oy + h * 0.05, ox + w * 0.26, oy + h * 0.15)..lineTo(ox - w * 0.26, oy + h * 0.15)..quadraticBezierTo(ox - w * 0.3, oy + h * 0.05, ox - w * 0.22, oy - h * 0.08)..close();
      canvas.drawPath(hood, paint); paint.color = outfit;
      final Path hoodieBody = Path()..moveTo(w * 0.08, h)..quadraticBezierTo(ox, h * 0.58, w * 0.92, h)..lineTo(w, h)..lineTo(0, h)..close();
      canvas.drawPath(hoodieBody, paint);
    } else if (config.outfit == 2) { // Jacket
      final Path jacketBody = Path()..moveTo(w * 0.1, h)..quadraticBezierTo(ox, h * 0.6, w * 0.9, h)..lineTo(w, h)..lineTo(0, h)..close();
      canvas.drawPath(jacketBody, paint);
      paint.color = outfit.withValues(alpha: 0.6); paint.style = PaintingStyle.stroke; paint.strokeWidth = w * 0.012;
      canvas.drawLine(Offset(ox, h * 0.62), Offset(ox - w * 0.1, h * 0.78), paint);
      canvas.drawLine(Offset(ox, h * 0.62), Offset(ox + w * 0.1, h * 0.78), paint);
      paint.style = PaintingStyle.fill;
    } else if (config.outfit == 3) { // Turtleneck
      final Path turtleBody = Path()..moveTo(w * 0.12, h)..quadraticBezierTo(ox, h * 0.62, w * 0.88, h)..lineTo(w, h)..lineTo(0, h)..close();
      canvas.drawPath(turtleBody, paint);
      paint.color = outfit.withValues(alpha: 0.85);
      final Rect collar = Rect.fromLTWH(ox - w * 0.1, oy + h * 0.12, w * 0.2, h * 0.1);
      canvas.drawRRect(RRect.fromRectAndRadius(collar, Radius.circular(w * 0.04)), paint);
    } else if (config.outfit == 4) { // Tank Top
      final Path tank = Path()..moveTo(w * 0.28, h)..quadraticBezierTo(ox, h * 0.65, w * 0.72, h)..lineTo(w, h)..lineTo(0, h)..close();
      canvas.drawPath(tank, paint);
    } else if (config.outfit == 5) { // Button Shirt
      final Path shirtBody = Path()..moveTo(w * 0.1, h)..quadraticBezierTo(ox, h * 0.6, w * 0.9, h)..lineTo(w, h)..lineTo(0, h)..close();
      canvas.drawPath(shirtBody, paint);
      paint.color = outfit.withValues(alpha: 0.7);
      final Path collarL = Path()..moveTo(ox - w * 0.02, h * 0.62)..lineTo(ox - w * 0.12, h * 0.66)..lineTo(ox - w * 0.06, h * 0.72)..close();
      final Path collarR = Path()..moveTo(ox + w * 0.02, h * 0.62)..lineTo(ox + w * 0.12, h * 0.66)..lineTo(ox + w * 0.06, h * 0.72)..close();
      canvas.drawPath(collarL, paint); canvas.drawPath(collarR, paint);
    } else if (config.outfit == 6) { // Sweater
      final Path sweater = Path()..moveTo(w * 0.08, h)..quadraticBezierTo(ox, h * 0.6, w * 0.92, h)..lineTo(w, h)..lineTo(0, h)..close();
      canvas.drawPath(sweater, paint);
      paint.style = PaintingStyle.stroke; paint.strokeWidth = w * 0.005; paint.color = outfit.withValues(alpha: 0.5);
      for (double dy = 0; dy < 3; dy++) { canvas.drawLine(Offset(ox - w * 0.08, h * 0.64 + dy * h * 0.012), Offset(ox + w * 0.08, h * 0.64 + dy * h * 0.012), paint); }
      paint.style = PaintingStyle.fill;
    } else { // Default Tee
      final Path outfitPath = Path()..moveTo(w * 0.12, h)..quadraticBezierTo(ox, h * 0.62, w * 0.88, h)..lineTo(w, h)..lineTo(0, h)..close();
      canvas.drawPath(outfitPath, paint);
    }
    canvas.restore(); // End outfit breathing wrap

    final double cx = ox + snapshot.headOffset.dx;
    final double cy = oy + snapshot.headOffset.dy;

    // Neck
    final Color skin = _parseColor(config.skinColor);
    final double neckY = oy + (cy - oy) * 0.5 + h * 0.08;
    final Rect neckRect = Rect.fromLTWH(cx - w * 0.08, neckY, w * 0.16, h * 0.18);
    paint.shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [skin.withValues(alpha: 0.6), skin.withValues(alpha: 0.95)], stops: const [0.0, 0.4]).createShader(neckRect);
    canvas.drawRRect(RRect.fromRectAndRadius(neckRect, Radius.circular(w * 0.03)), paint);
    paint.shader = null;

    // ─── 3. DYNAMIC TRANSFORM MATRIX (Pulse) ───
    canvas.save();
    final double scale = snapshot.expressionScale;
    canvas.translate(cx, cy);
    canvas.scale(scale, scale);
    canvas.translate(-cx, -cy);

    // BACK HAIR RESTORATION
    final Color hairColor = _parseColor(config.hairColor);
    paint.color = hairColor;
    canvas.save();
    canvas.translate(cx, cy - h * 0.1);
    canvas.rotate(snapshot.hairSway * 0.2);
    canvas.translate(-cx, -(cy - h * 0.1));
    if (config.hair == 7) {
      final double tS = (snapshot.hairSway * 0.4) * w;
      final Path hair = Path()..moveTo(cx - w * 0.32, cy - h * 0.1)..quadraticBezierTo(cx - w * 0.36, cy + h * 0.2, cx - w * 0.24 + tS, h * 0.95)..lineTo(cx + w * 0.24 + tS, h * 0.95)..quadraticBezierTo(cx + w * 0.36, cy + h * 0.2, cx + w * 0.32, cy - h * 0.1)..close();
      canvas.drawPath(hair, paint);
    } else if (config.hair == 6) {
      canvas.drawCircle(Offset(cx + w * 0.18, cy - h * 0.25), w * 0.1, paint);
    } else if (config.hair == 11) {
      canvas.drawCircle(Offset(cx, cy - h * 0.35), w * 0.07, paint);
    }
    canvas.restore();

    // HEAD SHAPE
    if (!_isMicro) {
      paint.shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [skin.withValues(alpha: 0.85), skin], stops: const [0.0, 0.3]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.28));
      canvas.drawCircle(Offset(cx, cy), w * 0.28, paint);
      paint.shader = null; paint.color = Colors.white.withValues(alpha: 0.15); paint.style = PaintingStyle.stroke; paint.strokeWidth = w * 0.015;
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.28 - (w * 0.007)), math.pi, math.pi / 1.5, false, paint);
      paint.style = PaintingStyle.fill;
    } else {
      paint.color = skin; canvas.drawCircle(Offset(cx, cy), w * 0.28, paint);
    }

    // EARRINGS PENDULUM RESTORATION
    if (!_isMicro && config.earring > 0) {
      final Offset leftPivot = Offset(cx - w * 0.28, cy + h * 0.04);
      final Offset rightPivot = Offset(cx + w * 0.28, cy + h * 0.04);
      paint.color = const Color(0xFFFFD700); paint.style = PaintingStyle.stroke; paint.strokeWidth = w * 0.008;
      void drawEarringAt(Offset pivot) {
        canvas.save();
        canvas.translate(pivot.dx, pivot.dy);
        canvas.rotate(snapshot.earringAngle);
        if (config.earring == 1) { // Stud
          paint.style = PaintingStyle.fill; canvas.drawCircle(Offset.zero, w * 0.012, paint);
        } else if (config.earring == 2) { // Hoop
          canvas.drawCircle(Offset(0, w * 0.025), w * 0.025, paint);
        } else if (config.earring == 3) { // Drop
          canvas.drawLine(Offset.zero, Offset(0, h * 0.04), paint);
          paint.style = PaintingStyle.fill; canvas.drawCircle(Offset(0, h * 0.04), w * 0.015, paint);
        }
        canvas.restore();
      }
      drawEarringAt(leftPivot); drawEarringAt(rightPivot);
    }

    // FACE DETAILS
    paint.style = PaintingStyle.fill;
    if (config.details == 1) {
      paint.color = Colors.pinkAccent.withValues(alpha: 0.25);
      canvas.drawCircle(Offset(cx - w * 0.16, cy + h * 0.05), w * 0.045, paint);
      canvas.drawCircle(Offset(cx + w * 0.16, cy + h * 0.05), w * 0.045, paint);
    } else if (config.details == 2) {
      paint.color = const Color(0xFF8D5524).withValues(alpha: 0.6);
      canvas.drawCircle(Offset(cx - w * 0.14, cy + h * 0.04), w * 0.006, paint);
      canvas.drawCircle(Offset(cx - w * 0.11, cy + h * 0.05), w * 0.006, paint);
      canvas.drawCircle(Offset(cx + w * 0.11, cy + h * 0.05), w * 0.006, paint);
      canvas.drawCircle(Offset(cx + w * 0.14, cy + h * 0.04), w * 0.006, paint);
    }

    // FACIAL HAIR RESTORATION
    paint.color = hairColor;
    if (config.facialHair == 1) {
      final Path g = Path()..moveTo(cx - w * 0.08, cy + h * 0.14)..quadraticBezierTo(cx, cy + h * 0.18, cx + w * 0.08, cy + h * 0.14)..quadraticBezierTo(cx, cy + h * 0.28, cx - w * 0.08, cy + h * 0.14)..close();
      canvas.drawPath(g, paint);
    } else if (config.facialHair == 2) {
      final Path fb = Path()..moveTo(cx - w * 0.26, cy)..quadraticBezierTo(cx - w * 0.28, cy + h * 0.18, cx - w * 0.15, cy + h * 0.24)..quadraticBezierTo(cx, cy + h * 0.32, cx + w * 0.15, cy + h * 0.24)..quadraticBezierTo(cx + w * 0.28, cy + h * 0.18, cx + w * 0.26, cy)..quadraticBezierTo(cx + w * 0.22, cy + h * 0.08, cx + w * 0.12, cy + h * 0.15)..quadraticBezierTo(cx, cy + h * 0.2, cx - w * 0.12, cy + h * 0.15)..quadraticBezierTo(cx - w * 0.22, cy + h * 0.08, cx - w * 0.26, cy)..close();
      canvas.drawPath(fb, paint);
    } else if (config.facialHair == 3) {
      paint.color = hairColor.withValues(alpha: 0.35);
      final Path st = Path()..moveTo(cx - w * 0.26, cy)..quadraticBezierTo(cx - w * 0.28, cy + h * 0.18, cx, cy + h * 0.28)..quadraticBezierTo(cx + w * 0.28, cy + h * 0.18, cx + w * 0.26, cy)..quadraticBezierTo(cx + w * 0.22, cy + h * 0.12, cx, cy + h * 0.18)..quadraticBezierTo(cx - w * 0.22, cy + h * 0.12, cx - w * 0.26, cy)..close();
      canvas.drawPath(st, paint);
    } else if (config.facialHair == 4) {
      final Path m = Path()..moveTo(cx - w * 0.11, cy + h * 0.07)..quadraticBezierTo(cx - w * 0.06, cy + h * 0.04, cx, cy + h * 0.07)..quadraticBezierTo(cx + w * 0.06, cy + h * 0.04, cx + w * 0.11, cy + h * 0.07)..quadraticBezierTo(cx + w * 0.14, cy + h * 0.05, cx + w * 0.16, cy + h * 0.08)..quadraticBezierTo(cx + w * 0.06, cy + h * 0.11, cx, cy + h * 0.09)..quadraticBezierTo(cx - w * 0.06, cy + h * 0.11, cx - w * 0.16, cy + h * 0.08)..quadraticBezierTo(cx - w * 0.14, cy + h * 0.05, cx - w * 0.11, cy + h * 0.07)..close();
      canvas.drawPath(m, paint);
    }

    // ─── FULL FRONT HAIR LIBRARY RESTORATION ───
    canvas.save();
    canvas.translate(cx, cy - h * 0.1);
    canvas.rotate(config.hair == 4 ? snapshot.hatWobble : snapshot.hairSway * 0.15);
    canvas.translate(-cx, -(cy - h * 0.1));
    paint.color = hairColor; paint.style = PaintingStyle.fill;

    if (config.hair == 1) { // Classic
      final Path p = Path()..moveTo(cx - w * 0.28, cy - h * 0.05)..cubicTo(cx - w * 0.35, cy - h * 0.35, cx + w * 0.35, cy - h * 0.35, cx + w * 0.28, cy - h * 0.05)..cubicTo(cx + w * 0.2, cy - h * 0.22, cx - w * 0.1, cy - h * 0.25, cx - w * 0.28, cy - h * 0.05)..close();
      canvas.drawPath(p, paint);
    } else if (config.hair == 2) { // Spiky
      final Path p = Path()..moveTo(cx - w * 0.28, cy - h * 0.05)..cubicTo(cx - w * 0.32, cy - h * 0.35, cx + w * 0.32, cy - h * 0.35, cx + w * 0.28, cy - h * 0.05)..lineTo(cx + w * 0.2, cy - h * 0.18)..lineTo(cx + w * 0.15, cy - h * 0.3)..lineTo(cx + w * 0.05, cy - h * 0.18)..lineTo(cx, cy - h * 0.34)..lineTo(cx - w * 0.05, cy - h * 0.18)..lineTo(cx - w * 0.15, cy - h * 0.3)..lineTo(cx - w * 0.2, cy - h * 0.18)..close();
      canvas.drawPath(p, paint);
    } else if (config.hair == 3) { // Curly
      for (double a = -2.2; a <= 0.6; a += 0.4) { canvas.drawCircle(Offset(cx + (w * 0.28) * math.cos(a), cy + (h * 0.28) * math.sin(a)), w * 0.09, paint); }
      canvas.drawCircle(Offset(cx, cy - h * 0.2), w * 0.15, paint);
    } else if (config.hair == 4) { // Cap
      paint.color = outfit; canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - w * 0.3, cy - h * 0.32, w * 0.6, h * 0.18), Radius.circular(w * 0.08)), paint);
      paint.color = outfit.withValues(alpha: 0.85); canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - w * 0.32, cy - h * 0.2, w * 0.64, h * 0.08), Radius.circular(w * 0.04)), paint);
    } else if (config.hair == 5) { // Afro
      canvas.drawCircle(Offset(cx, cy - h * 0.22), w * 0.22, paint); canvas.drawCircle(Offset(cx - w * 0.18, cy - h * 0.16), w * 0.16, paint); canvas.drawCircle(Offset(cx + w * 0.18, cy - h * 0.16), w * 0.16, paint); canvas.drawCircle(Offset(cx - w * 0.24, cy - h * 0.04), w * 0.13, paint); canvas.drawCircle(Offset(cx + w * 0.24, cy - h * 0.04), w * 0.13, paint);
    } else if (config.hair == 6) { // Bun Bangs
      final Path p = Path()..moveTo(cx - w * 0.28, cy - h * 0.05)..quadraticBezierTo(cx - w * 0.15, cy - h * 0.28, cx, cy - h * 0.12)..quadraticBezierTo(cx + w * 0.15, cy - h * 0.28, cx + w * 0.28, cy - h * 0.05)..quadraticBezierTo(cx, cy - h * 0.35, cx - w * 0.28, cy - h * 0.05)..close();
      canvas.drawPath(p, paint);
    } else if (config.hair == 7) { // Long bangs
      final Path p = Path()..moveTo(cx - w * 0.28, cy - h * 0.05)..quadraticBezierTo(cx, cy - h * 0.32, cx + w * 0.28, cy - h * 0.05)..quadraticBezierTo(cx + w * 0.18, cy - h * 0.2, cx, cy - h * 0.1)..quadraticBezierTo(cx - w * 0.18, cy - h * 0.2, cx - w * 0.28, cy - h * 0.05)..close();
      canvas.drawPath(p, paint);
    } else if (config.hair == 8) { // Undercut
      final Path p = Path()..moveTo(cx - w * 0.26, cy - h * 0.1)..quadraticBezierTo(cx, cy - h * 0.36, cx + w * 0.26, cy - h * 0.1)..quadraticBezierTo(cx, cy - h * 0.18, cx - w * 0.26, cy - h * 0.1)..close();
      canvas.drawPath(p, paint);
    } else if (config.hair == 9) { // Braids
      paint.style = PaintingStyle.stroke; paint.strokeWidth = w * 0.024; paint.strokeCap = StrokeCap.round;
      for (double x = -0.28; x <= 0.28; x += 0.08) { canvas.drawLine(Offset(cx + w * x, cy - h * 0.26), Offset(cx + w * x * 1.2, cy - h * 0.04), paint); }
      paint.style = PaintingStyle.fill;
    } else if (config.hair == 12) { // Curtain Bangs
      final Path p = Path()..moveTo(cx - w * 0.28, cy - h * 0.05)..cubicTo(cx - w * 0.34, cy - h * 0.34, cx + w * 0.34, cy - h * 0.34, cx + w * 0.28, cy - h * 0.05)..quadraticBezierTo(cx + w * 0.15, cy - h * 0.2, cx, cy - h * 0.08)..quadraticBezierTo(cx - w * 0.15, cy - h * 0.2, cx - w * 0.28, cy - h * 0.05)..close();
      canvas.drawPath(p, paint);
    } else if (config.hair == 13) { // Buzz
      final Path p = Path()..moveTo(cx - w * 0.22, cy - h * 0.08)..cubicTo(cx - w * 0.26, cy - h * 0.3, cx + w * 0.26, cy - h * 0.3, cx + w * 0.22, cy - h * 0.08)..quadraticBezierTo(cx, cy - h * 0.14, cx - w * 0.22, cy - h * 0.08)..close();
      canvas.drawPath(p, paint);
      paint.color = hairColor.withValues(alpha: 0.25); canvas.drawCircle(Offset(cx - w * 0.25, cy - h * 0.02), w * 0.06, paint); canvas.drawCircle(Offset(cx + w * 0.25, cy - h * 0.02), w * 0.06, paint);
    } else if (config.hair == 14) { // Wolf
      final Path p = Path()..moveTo(cx - w * 0.3, cy)..cubicTo(cx - w * 0.36, cy - h * 0.35, cx + w * 0.36, cy - h * 0.35, cx + w * 0.3, cy)..quadraticBezierTo(cx + w * 0.24, cy - h * 0.1, cx + w * 0.18, cy + h * 0.04)..quadraticBezierTo(cx, cy - h * 0.08, cx - w * 0.18, cy + h * 0.04)..quadraticBezierTo(cx - w * 0.24, cy - h * 0.1, cx - w * 0.3, cy)..close();
      canvas.drawPath(p, paint);
    } else if (config.hair == 19) { // Mohawk
      final Path p = Path()..moveTo(cx - w * 0.06, cy - h * 0.06)..cubicTo(cx - w * 0.08, cy - h * 0.42, cx + w * 0.08, cy - h * 0.42, cx + w * 0.06, cy - h * 0.06)..quadraticBezierTo(cx, cy - h * 0.12, cx - w * 0.06, cy - h * 0.06)..close();
      canvas.drawPath(p, paint);
      paint.color = hairColor.withValues(alpha: 0.15); canvas.drawCircle(Offset(cx - w * 0.2, cy - h * 0.1), w * 0.08, paint); canvas.drawCircle(Offset(cx + w * 0.2, cy - h * 0.1), w * 0.08, paint);
    } else if (config.hair == 21) { // Space Buns
      final Path p = Path()..moveTo(cx - w * 0.28, cy - h * 0.05)..cubicTo(cx - w * 0.32, cy - h * 0.3, cx + w * 0.32, cy - h * 0.3, cx + w * 0.28, cy - h * 0.05)..quadraticBezierTo(cx, cy - h * 0.18, cx - w * 0.28, cy - h * 0.05)..close();
      canvas.drawPath(p, paint);
      canvas.drawCircle(Offset(cx - w * 0.16, cy - h * 0.3), w * 0.1, paint); canvas.drawCircle(Offset(cx + w * 0.16, cy - h * 0.3), w * 0.1, paint);
    } else {
      // Default Fallback Simple
      final Path simple = Path()..moveTo(cx - w * 0.28, cy - h * 0.05)..cubicTo(cx - w * 0.35, cy - h * 0.35, cx + w * 0.35, cy - h * 0.35, cx + w * 0.28, cy - h * 0.05)..close();
      canvas.drawPath(simple, paint);
    }
    canvas.restore();

    // ─── SHARED EYES COORDINATE PLANE ───
    final double leftEyeY = cy + snapshot.gazeOffset.dy;
    final double rightEyeY = cy + snapshot.gazeOffset.dy;
    final double leftEyeX = cx - w * 0.09 + snapshot.gazeOffset.dx;
    final double rightEyeX = cx + w * 0.09 + snapshot.gazeOffset.dx;
    final double eyeSize = w * 0.035;

    // ─── FULL EYEBROW LIBRARY RESTORATION ───
    if (!_isMicro) {
      paint.color = hairColor; paint.style = PaintingStyle.stroke; paint.strokeCap = StrokeCap.round;
      final double browY = cy - h * 0.06; final double browSpan = w * 0.07;
      if (config.eyebrows == 0) {
        paint.strokeWidth = w * 0.012;
        canvas.drawArc(Rect.fromCenter(center: Offset(leftEyeX, browY), width: browSpan, height: w * 0.03), -2.8, 1.6, false, paint);
        canvas.drawArc(Rect.fromCenter(center: Offset(rightEyeX, browY), width: browSpan, height: w * 0.03), -2.8 + 1.2, 1.6, false, paint);
      } else if (config.eyebrows == 1) { // Arched
        paint.strokeWidth = w * 0.014;
        canvas.drawPath(Path()..moveTo(leftEyeX - browSpan*0.6, browY + h*0.01)..quadraticBezierTo(leftEyeX, browY - h*0.025, leftEyeX + browSpan*0.6, browY), paint);
        canvas.drawPath(Path()..moveTo(rightEyeX - browSpan*0.6, browY)..quadraticBezierTo(rightEyeX, browY - h*0.025, rightEyeX + browSpan*0.6, browY + h*0.01), paint);
      } else if (config.eyebrows == 2) { // Straight
        paint.strokeWidth = w * 0.015;
        canvas.drawLine(Offset(leftEyeX - browSpan * 0.5, browY), Offset(leftEyeX + browSpan * 0.5, browY), paint);
        canvas.drawLine(Offset(rightEyeX - browSpan * 0.5, browY), Offset(rightEyeX + browSpan * 0.5, browY), paint);
      } else if (config.eyebrows == 3) { // Thick
        paint.strokeWidth = w * 0.022;
        canvas.drawArc(Rect.fromCenter(center: Offset(leftEyeX, browY), width: browSpan, height: w * 0.03), -2.8, 1.6, false, paint);
        canvas.drawArc(Rect.fromCenter(center: Offset(rightEyeX, browY), width: browSpan, height: w * 0.03), -2.8 + 1.2, 1.6, false, paint);
      } else if (config.eyebrows == 5) { // Angry
        paint.strokeWidth = w * 0.016;
        canvas.drawLine(Offset(leftEyeX - browSpan*0.5, browY - h*0.01), Offset(leftEyeX + browSpan*0.4, browY + h*0.015), paint);
        canvas.drawLine(Offset(rightEyeX - browSpan*0.4, browY + h*0.015), Offset(rightEyeX + browSpan*0.5, browY - h*0.01), paint);
      } else if (config.eyebrows == 6) { // Worried
        paint.strokeWidth = w * 0.013;
        canvas.drawLine(Offset(leftEyeX - browSpan*0.5, browY + h*0.015), Offset(leftEyeX + browSpan*0.4, browY - h*0.01), paint);
        canvas.drawLine(Offset(rightEyeX - browSpan*0.4, browY - h*0.01), Offset(rightEyeX + browSpan*0.5, browY + h*0.015), paint);
      }
    }

    // ─── FULL EYE LIBRARY RESTORATION ───
    paint.style = PaintingStyle.fill; paint.color = const Color(0xFF1A202C);
    if (config.eyes == 0) { // Normal
      canvas.drawCircle(Offset(leftEyeX, leftEyeY), eyeSize, paint); canvas.drawCircle(Offset(rightEyeX, rightEyeY), eyeSize, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(leftEyeX - w * 0.008, leftEyeY - h * 0.008), eyeSize * 0.35, paint);
      canvas.drawCircle(Offset(rightEyeX - w * 0.008, rightEyeY - h * 0.008), eyeSize * 0.35, paint);
    } else if (config.eyes == 1) { // Wink
      paint.style = PaintingStyle.stroke; paint.strokeWidth = w * 0.012;
      canvas.drawPath(Path()..moveTo(leftEyeX - eyeSize, leftEyeY)..quadraticBezierTo(leftEyeX, leftEyeY + eyeSize * 0.8, leftEyeX + eyeSize, leftEyeY), paint);
      paint.style = PaintingStyle.fill; canvas.drawCircle(Offset(rightEyeX, rightEyeY), eyeSize, paint);
      paint.color = Colors.white; canvas.drawCircle(Offset(rightEyeX - w * 0.008, rightEyeY - h * 0.008), eyeSize * 0.35, paint);
    } else if (config.eyes == 2) { // Happy
      paint.style = PaintingStyle.stroke; paint.strokeWidth = w * 0.012;
      canvas.drawPath(Path()..moveTo(leftEyeX - eyeSize, leftEyeY + eyeSize * 0.3)..quadraticBezierTo(leftEyeX, leftEyeY - eyeSize * 0.8, leftEyeX + eyeSize, leftEyeY + eyeSize * 0.3), paint);
      canvas.drawPath(Path()..moveTo(rightEyeX - eyeSize, rightEyeY + eyeSize * 0.3)..quadraticBezierTo(rightEyeX, rightEyeY - eyeSize * 0.8, rightEyeX + eyeSize, rightEyeY + eyeSize * 0.3), paint);
    } else if (config.eyes == 3) { // Star ✨
      paint.color = Colors.amber;
      _drawStar(canvas, Offset(leftEyeX, leftEyeY), 5, eyeSize * 1.5, eyeSize * 0.6);
      _drawStar(canvas, Offset(rightEyeX, rightEyeY), 5, eyeSize * 1.5, eyeSize * 0.6);
    } else if (config.eyes == 4) { // Anime
      canvas.drawCircle(Offset(leftEyeX, leftEyeY), eyeSize * 1.4, paint); canvas.drawCircle(Offset(rightEyeX, rightEyeY), eyeSize * 1.4, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(leftEyeX - eyeSize*0.4, leftEyeY - eyeSize*0.4), eyeSize*0.5, paint); canvas.drawCircle(Offset(rightEyeX - eyeSize*0.4, rightEyeY - eyeSize*0.4), eyeSize*0.5, paint);
    } else if (config.eyes == 5) { // Squint
      paint.style = PaintingStyle.stroke; paint.strokeWidth = w * 0.012;
      canvas.drawLine(Offset(leftEyeX - eyeSize, leftEyeY), Offset(leftEyeX + eyeSize, leftEyeY), paint);
      canvas.drawLine(Offset(rightEyeX - eyeSize, rightEyeY), Offset(rightEyeX + eyeSize, rightEyeY), paint);
    } else if (config.eyes == 6) { // Sleepy
      paint.style = PaintingStyle.stroke; paint.strokeWidth = w * 0.012;
      canvas.drawPath(Path()..moveTo(leftEyeX - eyeSize, leftEyeY + eyeSize*0.2)..quadraticBezierTo(leftEyeX, leftEyeY - eyeSize*0.3, leftEyeX + eyeSize, leftEyeY + eyeSize*0.2), paint);
      canvas.drawPath(Path()..moveTo(rightEyeX - eyeSize, rightEyeY + eyeSize*0.2)..quadraticBezierTo(rightEyeX, rightEyeY - eyeSize*0.3, rightEyeX + eyeSize, rightEyeY + eyeSize*0.2), paint);
    } else if (config.eyes == 7) { // Sharp
      paint.style = PaintingStyle.fill;
      canvas.drawPath(Path()..moveTo(leftEyeX - eyeSize*1.2, leftEyeY + eyeSize*0.3)..lineTo(leftEyeX, leftEyeY - eyeSize*0.5)..lineTo(leftEyeX + eyeSize*1.2, leftEyeY + eyeSize*0.1)..close(), paint);
      canvas.drawPath(Path()..moveTo(rightEyeX - eyeSize*1.2, rightEyeY + eyeSize*0.1)..lineTo(rightEyeX, rightEyeY - eyeSize*0.5)..lineTo(rightEyeX + eyeSize*1.2, rightEyeY + eyeSize*0.3)..close(), paint);
    } else if (config.eyes == 10) { // Crescent
      paint.style = PaintingStyle.stroke; paint.strokeWidth = w * 0.014;
      canvas.drawArc(Rect.fromCenter(center: Offset(leftEyeX, leftEyeY), width: eyeSize*2.2, height: eyeSize*1.6), -2.6, 1.2, false, paint);
      canvas.drawArc(Rect.fromCenter(center: Offset(rightEyeX, rightEyeY), width: eyeSize*2.2, height: eyeSize*1.6), -2.6 + 1.4, 1.2, false, paint);
    }

    // BLINK MASK OVERLAY
    final Color lidColor = _parseColor(config.skinColor);
    void drawBlink(double x, double y, double v) {
      if (v <= 0.05) return;
      canvas.drawCircle(Offset(x, y), eyeSize * 1.5, Paint()..color = lidColor);
      canvas.drawPath(Path()..moveTo(x - eyeSize, y)..quadraticBezierTo(x, y + eyeSize * (0.3 + v * 0.4), x + eyeSize, y), Paint()..color = const Color(0xFF1A202C)..style = PaintingStyle.stroke..strokeWidth = w * 0.012..strokeCap = StrokeCap.round);
    }
    drawBlink(leftEyeX, leftEyeY, snapshot.leftBlink);
    drawBlink(rightEyeX, rightEyeY, snapshot.rightBlink);

    // ─── FULL MOUTH LIBRARY RESTORATION ───
    paint.style = PaintingStyle.stroke; paint.color = const Color(0xFF1A202C); paint.strokeCap = StrokeCap.round; paint.strokeWidth = w * 0.012;
    
    final double bias = snapshot.mouthStretch; // Derived directly from physics engine emotion bias (-0.5 to 2.0)
    final double mouthY = cy + h * 0.1 + (bias * h * 0.005);
    
    // 🚀 1. EXTREME EMOTION OVERRIDE (Laughing / Excited High Magnitude)
    // Smoothly transitions fully into an expressive laugh mask if bias > 1.3
    if (bias > 1.3) { 
      paint.style = PaintingStyle.fill;
      final double openHeight = (h * 0.06 * (0.5 + bias * 0.4)).clamp(h * 0.03, h * 0.12);
      canvas.drawPath(Path()..moveTo(cx - w * 0.07, mouthY)..quadraticBezierTo(cx, mouthY + openHeight, cx + w * 0.07, mouthY)..close(), paint);
    } else {
      // 🚀 2. ADAPTIVE PROCEDURAL MORPH (Continual Math interpolation applied directly into path control points)
      final double curveMod = bias * h * 0.022; // Dynamic vertical deflection applied to center gravity point
      
      if (config.mouth == 0) { // Smile
        canvas.drawPath(Path()..moveTo(cx - w * 0.06, mouthY)..quadraticBezierTo(cx, mouthY + h * 0.03 + curveMod, cx + w * 0.06, mouthY), paint);
      } else if (config.mouth == 1) { // Surprised
        final double circScale = (1.0 + bias * 0.4).clamp(0.6, 1.6);
        canvas.drawCircle(Offset(cx, mouthY + h * 0.02), w * 0.035 * circScale, paint);
      } else if (config.mouth == 2) { // Serious (Lines curve subtly into smiles!)
        canvas.drawPath(Path()..moveTo(cx - w * 0.05, mouthY + h * 0.02)..quadraticBezierTo(cx, mouthY + h * 0.02 + curveMod, cx + w * 0.05, mouthY + h * 0.02), paint);
      } else if (config.mouth == 3) { // Smirk
        canvas.drawPath(Path()..moveTo(cx - w * 0.05, mouthY + h * 0.02)..quadraticBezierTo(cx + w * 0.03, mouthY + h * 0.03 + curveMod, cx + w * 0.06, mouthY + h * 0.01), paint);
      } else if (config.mouth == 4) { // Laughing
        paint.style = PaintingStyle.fill;
        canvas.drawPath(Path()..moveTo(cx - w * 0.07, mouthY)..quadraticBezierTo(cx, mouthY + h * 0.06 + curveMod * 0.5, cx + w * 0.07, mouthY)..close(), paint);
      } else if (config.mouth == 5) { // Frown (Procedurally inverts back upward if happy bias is positive!)
        canvas.drawPath(Path()..moveTo(cx - w * 0.05, mouthY + h * 0.03)..quadraticBezierTo(cx, mouthY + curveMod, cx + w * 0.05, mouthY + h * 0.03), paint);
      } else if (config.mouth == 6) { // Cat
        canvas.drawPath(Path()..moveTo(cx, mouthY)..quadraticBezierTo(cx - w*0.04, mouthY + h*0.03 + curveMod*0.6, cx - w*0.07, mouthY), paint);
        canvas.drawPath(Path()..moveTo(cx, mouthY)..quadraticBezierTo(cx + w*0.04, mouthY + h*0.03 + curveMod*0.6, cx + w*0.07, mouthY), paint);
      } else if (config.mouth == 7) { // Grin
        final double grinW = w * 0.07 + (bias.clamp(0.0, 1.0) * w * 0.02);
        canvas.drawPath(Path()..moveTo(cx - grinW, mouthY + h*0.01)..quadraticBezierTo(cx, mouthY + h*0.035 + curveMod, cx + grinW, mouthY + h*0.01), paint);
        canvas.drawLine(Offset(cx - grinW * 0.7, mouthY + h*0.022 + curveMod*0.4), Offset(cx + grinW * 0.7, mouthY + h*0.022 + curveMod*0.4), paint);
      } else if (config.mouth == 8) { // Tongue
        paint.style = PaintingStyle.fill;
        final double tongueOpen = (h * 0.05 + curveMod).clamp(h*0.02, h*0.08);
        final Path mouthShape = Path()..moveTo(cx - w * 0.06, mouthY)..quadraticBezierTo(cx, mouthY + tongueOpen, cx + w * 0.06, mouthY)..close();
        canvas.drawPath(mouthShape, paint);
        // Draw pink tongue
        final Paint tonguePaint = Paint()..color = const Color(0xFFFF7597)..style = PaintingStyle.fill;
        canvas.save();
        canvas.clipPath(mouthShape);
        canvas.drawCircle(Offset(cx, mouthY + tongueOpen * 0.9), w * 0.035 + (bias.clamp(0.0, 1.0) * w * 0.01), tonguePaint);
        canvas.restore();
      } else if (config.mouth == 9) { // Whisper
        paint.style = PaintingStyle.stroke;
        final double wRad = (w * 0.016 + (bias * w * 0.01)).clamp(w * 0.008, w * 0.05);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, mouthY + h * 0.02), width: wRad * 1.6, height: wRad * 2.2), paint);
      } else {
        // Fallback
        canvas.drawPath(Path()..moveTo(cx - w * 0.06, mouthY)..quadraticBezierTo(cx, mouthY + h * 0.03 + curveMod, cx + w * 0.06, mouthY), paint);
      }
    }

    // ─── FULL ACCESSORIES LIBRARY RESTORATION ───
    paint.style = PaintingStyle.stroke; paint.color = const Color(0xFF2D3748);
    final double eyeY = (leftEyeY + rightEyeY) / 2;
    if (config.acc == 1) { // Glasses
      paint.strokeWidth = w * 0.012;
      canvas.drawCircle(Offset(leftEyeX, eyeY), w * 0.08, paint);
      canvas.drawCircle(Offset(rightEyeX, eyeY), w * 0.08, paint);
      canvas.drawLine(Offset(cx - w * 0.03, eyeY), Offset(cx + w * 0.03, eyeY), paint);
    } else if (config.acc == 2) { // Sunglasses
      paint.style = PaintingStyle.fill; paint.color = const Color(0xFF1A202C).withValues(alpha: 0.95);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(leftEyeX-w*0.08, eyeY-h*0.05, w*0.16, h*0.09), Radius.circular(w*0.02)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rightEyeX-w*0.08, eyeY-h*0.05, w*0.16, h*0.09), Radius.circular(w*0.02)), paint);
      paint.style = PaintingStyle.stroke; paint.strokeWidth = w * 0.015; paint.color = const Color(0xFF1A202C);
      canvas.drawLine(Offset(cx-w*0.04, eyeY-h*0.02), Offset(cx+w*0.04, eyeY-h*0.02), paint);
    } else if (config.acc == 3) { // Eyepatch
      paint.style = PaintingStyle.fill; paint.color = const Color(0xFF1A202C);
      canvas.drawCircle(Offset(leftEyeX, eyeY), w * 0.065, paint);
      paint.style = PaintingStyle.stroke; paint.strokeWidth = w * 0.015;
      canvas.drawLine(Offset(cx-w*0.28, cy-h*0.12), Offset(cx+w*0.2, cy+h*0.08), paint);
    } else if (config.acc == 4) { // Headset
      paint.style = PaintingStyle.stroke; paint.strokeWidth = w * 0.04; paint.color = _parseColor(config.bgColor);
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.29), math.pi, math.pi, false, paint);
      paint.style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx-w*0.33, cy-h*0.08, w*0.07, h*0.16), Radius.circular(w*0.03)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx+w*0.26, cy-h*0.08, w*0.07, h*0.16), Radius.circular(w*0.03)), paint);
    } else if (config.acc == 5) { // Scar
      paint.color = const Color(0xFFE53E3E).withValues(alpha: 0.7); paint.strokeWidth = w * 0.008;
      canvas.drawLine(Offset(rightEyeX-w*0.04, eyeY-h*0.06), Offset(rightEyeX+w*0.04, eyeY+h*0.06), paint);
    } else if (config.acc == 9) { // AirPods
      paint.style = PaintingStyle.fill; paint.color = Colors.white;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx-w*0.27, cy+h*0.02), width: w*0.04, height: h*0.06), Radius.circular(w*0.02)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx+w*0.27, cy+h*0.02), width: w*0.04, height: h*0.06), Radius.circular(w*0.02)), paint);
    } else if (config.acc == 10) { // Nose Ring
      paint.style = PaintingStyle.stroke; paint.color = const Color(0xFFFFD700); paint.strokeWidth = w * 0.008;
      canvas.drawArc(Rect.fromCenter(center: Offset(cx+w*0.02, cy+h*0.06), width: w*0.03, height: h*0.03), 0.3, 2.5, false, paint);
    }

    canvas.restore(); // Pop Main Scaler

    // ─── VFX PARTICLE LAYER ───
    if (snapshot.activeParticles.isNotEmpty) {
      for (final p in snapshot.activeParticles) {
        paint.style = PaintingStyle.fill;
        final double opacity = p.life.clamp(0.0, 1.0);
        final double px = cx + p.position.dx;
        final double py = cy - h * 0.1 + p.position.dy;
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(p.rotation);
        if (p.type == 1) { // Zzz
          final tp = TextPainter(text: TextSpan(text: 'z', style: TextStyle(color: Colors.white.withValues(alpha: opacity * 0.8), fontSize: 12, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
          tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        } else if (p.type == 2) { // Confetti
          paint.color = Colors.primaries[p.position.dx.toInt().abs() % Colors.primaries.length].withValues(alpha: opacity);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 6, height: 6), paint);
        } else { // Sparkle
          paint.color = Colors.yellowAccent.withValues(alpha: opacity * 0.9);
          final Path dia = Path()..moveTo(0, -6)..lineTo(4, 0)..lineTo(0, 6)..lineTo(-4, 0)..close();
          canvas.drawPath(dia, paint);
        }
        canvas.restore();
      }
    }

    canvas.restore(); // Pop Global Clip
  }

  void _drawStar(Canvas canvas, Offset center, int points, double outerR, double innerR) {
    final Path p = Path(); double a = -math.pi / 2; final double inc = math.pi / points;
    for (int i = 0; i < points * 2; i++) {
      final double r = i.isEven ? outerR : innerR;
      final double x = center.dx + r * math.cos(a); final double y = center.dy + r * math.sin(a);
      i == 0 ? p.moveTo(x, y) : p.lineTo(x, y); a += inc;
    }
    p.close(); canvas.drawPath(p, Paint()..color = Colors.amber);
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF' + hex;
    return Color(int.parse(hex, radix: 16));
  }

  @override
  bool shouldRepaint(covariant AvatarPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.snapshot != snapshot || snapshot.activeParticles.isNotEmpty;
  }
}
