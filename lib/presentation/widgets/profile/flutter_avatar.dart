import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class PaintStroke {
  final List<Offset> points;
  final String color;
  final double width;

  PaintStroke({required this.points, required this.color, required this.width});

  factory PaintStroke.fromMap(Map<String, dynamic> map) {
    final list = map['points'] as List? ?? [];
    final pts = list.map((p) {
      final parts = p.toString().split(',');
      return Offset(double.parse(parts[0]), double.parse(parts[1]));
    }).toList();
    return PaintStroke(
      points: pts,
      color: map['color'] ?? '#FF0000',
      width: (map['width'] as num?)?.toDouble() ?? 4.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => '${p.dx.toStringAsFixed(3)},${p.dy.toStringAsFixed(3)}').toList(),
      'color': color,
      'width': width,
    };
  }
}

class AvatarConfig {
  final int hair;        // 0: Bald, 1: Classic, 2: Spiky, 3: Curly, 4: Cap, 5: Afro, 6: Bun, 7: Long, 8: Undercut, 9: Braids, 10: Headband, 11: Topknot
  final int eyes;        // 0: Normal, 1: Wink, 2: Happy, 3: Star, 4: Cute, 5: Squint
  final int mouth;       // 0: Smile, 1: Open, 2: Serious, 3: Smirk, 4: Laughing, 5: Frown
  final int acc;         // 0: None, 1: Glasses, 2: Shades, 3: Eyepatch, 4: Headphones, 5: Scar
  final int facialHair;  // 0: None, 1: Goatee, 2: Full Beard, 3: Stubble, 4: Mustache Only
  final int details;     // 0: None, 1: Blush, 2: Freckles
  final String bgColor;
  final String skinColor;
  final String hairColor;
  final String outfitColor;
  final List<PaintStroke> customStrokes;

  AvatarConfig({
    required this.hair,
    required this.eyes,
    required this.mouth,
    required this.acc,
    required this.facialHair,
    required this.details,
    required this.bgColor,
    required this.skinColor,
    required this.hairColor,
    required this.outfitColor,
    this.customStrokes = const [],
  });

  factory AvatarConfig.defaultConfig() {
    return AvatarConfig(
      hair: 1,
      eyes: 0,
      mouth: 0,
      acc: 0,
      facialHair: 0,
      details: 0,
      bgColor: '#FF6B6B',
      skinColor: '#FFDBB5',
      hairColor: '#2D3748',
      outfitColor: '#4A5568',
      customStrokes: const [],
    );
  }

  factory AvatarConfig.fromJson(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr);
      final strokesList = map['customStrokes'] as List? ?? [];
      final strokes = strokesList.map((s) => PaintStroke.fromMap(s)).toList();

      return AvatarConfig(
        hair: map['hair'] ?? 1,
        eyes: map['eyes'] ?? 0,
        mouth: map['mouth'] ?? 0,
        acc: map['acc'] ?? 0,
        facialHair: map['facialHair'] ?? 0,
        details: map['details'] ?? 0,
        bgColor: map['bgColor'] ?? '#FF6B6B',
        skinColor: map['skinColor'] ?? '#FFDBB5',
        hairColor: map['hairColor'] ?? '#2D3748',
        outfitColor: map['outfitColor'] ?? '#4A5568',
        customStrokes: strokes,
      );
    } catch (_) {
      return AvatarConfig.defaultConfig();
    }
  }

  String toJson() {
    return jsonEncode({
      'hair': hair,
      'eyes': eyes,
      'mouth': mouth,
      'acc': acc,
      'facialHair': facialHair,
      'details': details,
      'bgColor': bgColor,
      'skinColor': skinColor,
      'hairColor': hairColor,
      'outfitColor': outfitColor,
      'customStrokes': customStrokes.map((s) => s.toMap()).toList(),
    });
  }
}

class FlutterAvatar extends StatelessWidget {
  final AvatarConfig config;
  final double size;

  const FlutterAvatar({
    super.key,
    required this.config,
    this.size = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: AvatarPainter(config: config),
      ),
    );
  }
}

class AvatarPainter extends CustomPainter {
  final AvatarConfig config;
  AvatarPainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;

    final Paint paint = Paint()..isAntiAlias = true;

    // 1. Background Circle
    final Color bg = _parseColor(config.bgColor);
    paint.color = bg;
    canvas.drawCircle(Offset(cx, cy), w / 2, paint);

    // Save state to clip shoulders/outfit to the background circle boundary
    canvas.save();
    final Path clipPath = Path()..addOval(Rect.fromLTWH(0, 0, w, h));
    canvas.clipPath(clipPath);

    // 2. Draw Shoulders & Outfit
    final Color outfit = _parseColor(config.outfitColor);
    paint.color = outfit;
    final Path outfitPath = Path()
      ..moveTo(w * 0.12, h)
      ..quadraticBezierTo(cx, h * 0.62, w * 0.88, h)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(outfitPath, paint);

    // Draw Neck
    final Color skin = _parseColor(config.skinColor);
    paint.color = skin.withOpacity(0.85); // Slight shadow logic
    final Rect neckRect = Rect.fromLTWH(cx - w * 0.08, cy + h * 0.08, w * 0.16, h * 0.18);
    canvas.drawRRect(RRect.fromRectAndRadius(neckRect, Radius.circular(w * 0.03)), paint);

    // 3. Draw Back Hair (for long hairstyles)
    final Color hairColor = _parseColor(config.hairColor);
    paint.color = hairColor;
    if (config.hair == 7) {
      // Long hair draped behind shoulders
      final Path longHairBack = Path()
        ..moveTo(cx - w * 0.32, cy - h * 0.1)
        ..quadraticBezierTo(cx - w * 0.36, cy + h * 0.2, cx - w * 0.24, h * 0.95)
        ..lineTo(cx + w * 0.24, h * 0.95)
        ..quadraticBezierTo(cx + w * 0.36, cy + h * 0.2, cx + w * 0.32, cy - h * 0.1)
        ..close();
      canvas.drawPath(longHairBack, paint);
    } else if (config.hair == 6) {
      // Bun hair back circle
      canvas.drawCircle(Offset(cx + w * 0.18, cy - h * 0.25), w * 0.1, paint);
    } else if (config.hair == 11) {
      // Samurai Topknot knot
      canvas.drawCircle(Offset(cx, cy - h * 0.35), w * 0.07, paint);
    }

    // 4. Head Circle
    paint.color = skin;
    canvas.drawCircle(Offset(cx, cy), w * 0.28, paint);

    // 5. Facial Details (Blush / Freckles)
    if (config.details == 1) {
      // Blush rosy cheeks
      paint.color = Colors.pinkAccent.withOpacity(0.25);
      canvas.drawCircle(Offset(cx - w * 0.16, cy + h * 0.05), w * 0.045, paint);
      canvas.drawCircle(Offset(cx + w * 0.16, cy + h * 0.05), w * 0.045, paint);
    } else if (config.details == 2) {
      // Freckles
      paint.color = const Color(0xFF8D5524).withOpacity(0.6);
      canvas.drawCircle(Offset(cx - w * 0.14, cy + h * 0.04), w * 0.006, paint);
      canvas.drawCircle(Offset(cx - w * 0.11, cy + h * 0.05), w * 0.006, paint);
      canvas.drawCircle(Offset(cx - w * 0.08, cy + h * 0.04), w * 0.006, paint);
      canvas.drawCircle(Offset(cx + w * 0.08, cy + h * 0.04), w * 0.006, paint);
      canvas.drawCircle(Offset(cx + w * 0.11, cy + h * 0.05), w * 0.006, paint);
      canvas.drawCircle(Offset(cx + w * 0.14, cy + h * 0.04), w * 0.006, paint);
    }

    // 6. Draw Facial Hair
    paint.color = hairColor;
    if (config.facialHair == 1) {
      // Goatee
      final Path goatee = Path()
        ..moveTo(cx - w * 0.08, cy + h * 0.14)
        ..quadraticBezierTo(cx, cy + h * 0.18, cx + w * 0.08, cy + h * 0.14)
        ..quadraticBezierTo(cx, cy + h * 0.28, cx - w * 0.08, cy + h * 0.14)
        ..close();
      canvas.drawPath(goatee, paint);
    } else if (config.facialHair == 2) {
      // Full beard wrapping around cheeks
      final Path fullBeard = Path()
        ..moveTo(cx - w * 0.26, cy)
        ..quadraticBezierTo(cx - w * 0.28, cy + h * 0.18, cx - w * 0.15, cy + h * 0.24)
        ..quadraticBezierTo(cx, cy + h * 0.32, cx + w * 0.15, cy + h * 0.24)
        ..quadraticBezierTo(cx + w * 0.28, cy + h * 0.18, cx + w * 0.26, cy)
        ..quadraticBezierTo(cx + w * 0.22, cy + h * 0.08, cx + w * 0.12, cy + h * 0.15)
        ..quadraticBezierTo(cx, cy + h * 0.2, cx - w * 0.12, cy + h * 0.15)
        ..quadraticBezierTo(cx - w * 0.22, cy + h * 0.08, cx - w * 0.26, cy)
        ..close();
      canvas.drawPath(fullBeard, paint);
    } else if (config.facialHair == 3) {
      // Light Stubble
      paint.color = hairColor.withOpacity(0.35);
      final Path stubble = Path()
        ..moveTo(cx - w * 0.26, cy)
        ..quadraticBezierTo(cx - w * 0.28, cy + h * 0.18, cx, cy + h * 0.28)
        ..quadraticBezierTo(cx + w * 0.28, cy + h * 0.18, cx + w * 0.26, cy)
        ..quadraticBezierTo(cx + w * 0.22, cy + h * 0.12, cx, cy + h * 0.18)
        ..quadraticBezierTo(cx - w * 0.22, cy + h * 0.12, cx - w * 0.26, cy)
        ..close();
      canvas.drawPath(stubble, paint);
    } else if (config.facialHair == 4) {
      // Elegant Handlebar Mustache
      final Path moustache = Path()
        ..moveTo(cx - w * 0.11, cy + h * 0.07)
        ..quadraticBezierTo(cx - w * 0.06, cy + h * 0.04, cx, cy + h * 0.07)
        ..quadraticBezierTo(cx + w * 0.06, cy + h * 0.04, cx + w * 0.11, cy + h * 0.07)
        ..quadraticBezierTo(cx + w * 0.14, cy + h * 0.05, cx + w * 0.16, cy + h * 0.08)
        ..quadraticBezierTo(cx + w * 0.06, cy + h * 0.11, cx, cy + h * 0.09)
        ..quadraticBezierTo(cx - w * 0.06, cy + h * 0.11, cx - w * 0.16, cy + h * 0.08)
        ..quadraticBezierTo(cx - w * 0.14, cy + h * 0.05, cx - w * 0.11, cy + h * 0.07)
        ..close();
      canvas.drawPath(moustache, paint);
    }

    // 7. Draw Front Hair Styles
    paint.color = hairColor;
    if (config.hair == 1) {
      // Classic Side Crop
      final Path hairPath = Path()
        ..moveTo(cx - w * 0.28, cy - h * 0.05)
        ..cubicTo(cx - w * 0.35, cy - h * 0.35, cx + w * 0.35, cy - h * 0.35, cx + w * 0.28, cy - h * 0.05)
        ..cubicTo(cx + w * 0.2, cy - h * 0.22, cx - w * 0.1, cy - h * 0.25, cx - w * 0.28, cy - h * 0.05)
        ..close();
      canvas.drawPath(hairPath, paint);
    } else if (config.hair == 2) {
      // Spiky
      final Path hairPath = Path()
        ..moveTo(cx - w * 0.28, cy - h * 0.05)
        ..cubicTo(cx - w * 0.32, cy - h * 0.35, cx + w * 0.32, cy - h * 0.35, cx + w * 0.28, cy - h * 0.05)
        ..lineTo(cx + w * 0.2, cy - h * 0.18)
        ..lineTo(cx + w * 0.15, cy - h * 0.3)
        ..lineTo(cx + w * 0.05, cy - h * 0.18)
        ..lineTo(cx, cy - h * 0.34)
        ..lineTo(cx - w * 0.05, cy - h * 0.18)
        ..lineTo(cx - w * 0.15, cy - h * 0.3)
        ..lineTo(cx - w * 0.2, cy - h * 0.18)
        ..close();
      canvas.drawPath(hairPath, paint);
    } else if (config.hair == 3) {
      // Curly curls
      for (double angle = -2.2; angle <= 0.6; angle += 0.4) {
        final double hx = cx + (w * 0.28) * math.cos(angle);
        final double hy = cy + (h * 0.28) * math.sin(angle);
        canvas.drawCircle(Offset(hx, hy), w * 0.09, paint);
      }
      canvas.drawCircle(Offset(cx, cy - h * 0.2), w * 0.15, paint);
    } else if (config.hair == 4) {
      // Cool Cap
      paint.color = outfit;
      final Rect capRect = Rect.fromLTWH(cx - w * 0.3, cy - h * 0.32, w * 0.6, h * 0.18);
      canvas.drawRRect(RRect.fromRectAndRadius(capRect, Radius.circular(w * 0.08)), paint);
      paint.color = outfit.withOpacity(0.85);
      final Rect capFold = Rect.fromLTWH(cx - w * 0.32, cy - h * 0.2, w * 0.64, h * 0.08);
      canvas.drawRRect(RRect.fromRectAndRadius(capFold, Radius.circular(w * 0.04)), paint);
    } else if (config.hair == 5) {
      // Beautiful Afro Cloud
      canvas.drawCircle(Offset(cx, cy - h * 0.22), w * 0.22, paint);
      canvas.drawCircle(Offset(cx - w * 0.18, cy - h * 0.16), w * 0.16, paint);
      canvas.drawCircle(Offset(cx + w * 0.18, cy - h * 0.16), w * 0.16, paint);
      canvas.drawCircle(Offset(cx - w * 0.24, cy - h * 0.04), w * 0.13, paint);
      canvas.drawCircle(Offset(cx + w * 0.24, cy - h * 0.04), w * 0.13, paint);
    } else if (config.hair == 6) {
      // Ponytail bun front bangs
      final Path bangs = Path()
        ..moveTo(cx - w * 0.28, cy - h * 0.05)
        ..quadraticBezierTo(cx - w * 0.15, cy - h * 0.28, cx, cy - h * 0.12)
        ..quadraticBezierTo(cx + w * 0.15, cy - h * 0.28, cx + w * 0.28, cy - h * 0.05)
        ..quadraticBezierTo(cx, cy - h * 0.35, cx - w * 0.28, cy - h * 0.05)
        ..close();
      canvas.drawPath(bangs, paint);
    } else if (config.hair == 7) {
      // Long hair front bangs
      final Path bangs = Path()
        ..moveTo(cx - w * 0.28, cy - h * 0.05)
        ..quadraticBezierTo(cx, cy - h * 0.32, cx + w * 0.28, cy - h * 0.05)
        ..quadraticBezierTo(cx + w * 0.18, cy - h * 0.2, cx, cy - h * 0.1)
        ..quadraticBezierTo(cx - w * 0.18, cy - h * 0.2, cx - w * 0.28, cy - h * 0.05)
        ..close();
      canvas.drawPath(bangs, paint);
    } else if (config.hair == 8) {
      // Undercut
      final Path undercutTop = Path()
        ..moveTo(cx - w * 0.26, cy - h * 0.1)
        ..quadraticBezierTo(cx, cy - h * 0.36, cx + w * 0.26, cy - h * 0.1)
        ..quadraticBezierTo(cx, cy - h * 0.18, cx - w * 0.26, cy - h * 0.1)
        ..close();
      canvas.drawPath(undercutTop, paint);
    } else if (config.hair == 9) {
      // Braids / Dreadlocks lines
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.024;
      paint.strokeCap = StrokeCap.round;
      for (double offsetMultiplier = -0.28; offsetMultiplier <= 0.28; offsetMultiplier += 0.08) {
        canvas.drawLine(
          Offset(cx + w * offsetMultiplier, cy - h * 0.26),
          Offset(cx + w * offsetMultiplier * 1.2, cy - h * 0.04),
          paint,
        );
      }
      paint.style = PaintingStyle.fill;
    } else if (config.hair == 10) {
      // Hair + Sporty Headband
      // Base Hair
      final Path baseHair = Path()
        ..moveTo(cx - w * 0.28, cy - h * 0.05)
        ..cubicTo(cx - w * 0.35, cy - h * 0.35, cx + w * 0.35, cy - h * 0.35, cx + w * 0.28, cy - h * 0.05)
        ..close();
      canvas.drawPath(baseHair, paint);
      // Headband
      paint.color = _parseColor(config.bgColor).withOpacity(0.9);
      final Path band = Path()
        ..moveTo(cx - w * 0.27, cy - h * 0.16)
        ..quadraticBezierTo(cx, cy - h * 0.22, cx + w * 0.27, cy - h * 0.16)
        ..lineTo(cx + w * 0.26, cy - h * 0.10)
        ..quadraticBezierTo(cx, cy - h * 0.16, cx - w * 0.26, cy - h * 0.10)
        ..close();
      canvas.drawPath(band, paint);
    } else if (config.hair == 11) {
      // Topknot samurai head hair
      final Path samuraiHair = Path()
        ..moveTo(cx - w * 0.28, cy - h * 0.05)
        ..cubicTo(cx - w * 0.32, cy - h * 0.32, cx + w * 0.32, cy - h * 0.32, cx + w * 0.28, cy - h * 0.05)
        ..quadraticBezierTo(cx, cy - h * 0.2, cx - w * 0.28, cy - h * 0.05)
        ..close();
      canvas.drawPath(samuraiHair, paint);
    }

    // 8. Eyes Rendering
    paint.color = const Color(0xFF1A202C);
    final double eyeY = cy;
    final double leftEyeX = cx - w * 0.09;
    final double rightEyeX = cx + w * 0.09;
    final double eyeSize = w * 0.035;

    if (config.eyes == 0) {
      // Normal cute eyes
      canvas.drawCircle(Offset(leftEyeX, eyeY), eyeSize, paint);
      canvas.drawCircle(Offset(rightEyeX, eyeY), eyeSize, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(leftEyeX - w * 0.008, eyeY - h * 0.008), eyeSize * 0.35, paint);
      canvas.drawCircle(Offset(rightEyeX - w * 0.008, eyeY - h * 0.008), eyeSize * 0.35, paint);
    } else if (config.eyes == 1) {
      // Wink
      final Path winkPath = Path()
        ..moveTo(leftEyeX - eyeSize, eyeY)
        ..quadraticBezierTo(leftEyeX, eyeY + eyeSize * 0.8, leftEyeX + eyeSize, eyeY);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      paint.strokeCap = StrokeCap.round;
      canvas.drawPath(winkPath, paint);

      paint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(rightEyeX, eyeY), eyeSize, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(rightEyeX - w * 0.008, eyeY - h * 0.008), eyeSize * 0.35, paint);
    } else if (config.eyes == 2) {
      // Happy curves
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      paint.strokeCap = StrokeCap.round;
      final Path happyLeft = Path()
        ..moveTo(leftEyeX - eyeSize, eyeY + eyeSize * 0.3)
        ..quadraticBezierTo(leftEyeX, eyeY - eyeSize * 0.8, leftEyeX + eyeSize, eyeY + eyeSize * 0.3);
      final Path happyRight = Path()
        ..moveTo(rightEyeX - eyeSize, eyeY + eyeSize * 0.3)
        ..quadraticBezierTo(rightEyeX, eyeY - eyeSize * 0.8, rightEyeX + eyeSize, eyeY + eyeSize * 0.3);
      canvas.drawPath(happyLeft, paint);
      canvas.drawPath(happyRight, paint);
    } else if (config.eyes == 3) {
      // Star Eyes ✨
      paint.color = Colors.amber;
      _drawStar(canvas, Offset(leftEyeX, eyeY), 5, eyeSize * 1.5, eyeSize * 0.6);
      _drawStar(canvas, Offset(rightEyeX, eyeY), 5, eyeSize * 1.5, eyeSize * 0.6);
    } else if (config.eyes == 4) {
      // Cute Anime Eyes (big glassy)
      canvas.drawCircle(Offset(leftEyeX, eyeY), eyeSize * 1.4, paint);
      canvas.drawCircle(Offset(rightEyeX, eyeY), eyeSize * 1.4, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(leftEyeX - eyeSize * 0.4, eyeY - eyeSize * 0.4), eyeSize * 0.5, paint);
      canvas.drawCircle(Offset(leftEyeX + eyeSize * 0.4, eyeY + eyeSize * 0.4), eyeSize * 0.25, paint);
      canvas.drawCircle(Offset(rightEyeX - eyeSize * 0.4, eyeY - eyeSize * 0.4), eyeSize * 0.5, paint);
      canvas.drawCircle(Offset(rightEyeX + eyeSize * 0.4, eyeY + eyeSize * 0.4), eyeSize * 0.25, paint);
    } else if (config.eyes == 5) {
      // Cool Squint
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      paint.strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(leftEyeX - eyeSize, eyeY), Offset(leftEyeX + eyeSize, eyeY), paint);
      canvas.drawLine(Offset(rightEyeX - eyeSize, eyeY), Offset(rightEyeX + eyeSize, eyeY), paint);
    }

    paint.style = PaintingStyle.fill;

    // 9. Mouth Expressions
    paint.color = const Color(0xFF1A202C);
    final double mouthY = cy + h * 0.1;

    if (config.mouth == 0) {
      // Smile
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      paint.strokeCap = StrokeCap.round;
      final Path smilePath = Path()
        ..moveTo(cx - w * 0.06, mouthY)
        ..quadraticBezierTo(cx, mouthY + h * 0.04, cx + w * 0.06, mouthY);
      canvas.drawPath(smilePath, paint);
    } else if (config.mouth == 1) {
      // Surprised open mouth
      canvas.drawCircle(Offset(cx, mouthY + h * 0.01), w * 0.035, paint);
    } else if (config.mouth == 2) {
      // Serious flat mouth
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      paint.strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - w * 0.04, mouthY + h * 0.01), Offset(cx + w * 0.04, mouthY + h * 0.01), paint);
    } else if (config.mouth == 3) {
      // Cheeky smirk
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      paint.strokeCap = StrokeCap.round;
      final Path smirk = Path()
        ..moveTo(cx - w * 0.04, mouthY)
        ..quadraticBezierTo(cx + w * 0.04, mouthY + h * 0.01, cx + w * 0.06, mouthY - h * 0.02);
      canvas.drawPath(smirk, paint);
    } else if (config.mouth == 4) {
      // Laughing open mouth with teeth/tongue
      final Rect mouthRect = Rect.fromLTWH(cx - w * 0.06, mouthY - h * 0.01, w * 0.12, h * 0.07);
      final Path laughPath = Path()
        ..moveTo(cx - w * 0.06, mouthY)
        ..lineTo(cx + w * 0.06, mouthY)
        ..quadraticBezierTo(cx, mouthY + h * 0.08, cx - w * 0.06, mouthY)
        ..close();
      canvas.drawPath(laughPath, paint);
      // Teeth line
      paint.color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(cx - w * 0.04, mouthY, w * 0.08, h * 0.015), paint);
    } else if (config.mouth == 5) {
      // Sad / Frown
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      paint.strokeCap = StrokeCap.round;
      final Path frownPath = Path()
        ..moveTo(cx - w * 0.05, mouthY + h * 0.03)
        ..quadraticBezierTo(cx, mouthY, cx + w * 0.05, mouthY + h * 0.03);
      canvas.drawPath(frownPath, paint);
    }

    paint.style = PaintingStyle.fill;

    // 10. Accessories
    if (config.acc == 1) {
      // Glasses
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      paint.color = const Color(0xFF2D3748);
      canvas.drawCircle(Offset(leftEyeX, eyeY), w * 0.08, paint);
      canvas.drawCircle(Offset(rightEyeX, eyeY), w * 0.08, paint);
      canvas.drawLine(Offset(cx - w * 0.03, eyeY), Offset(cx + w * 0.03, eyeY), paint);
    } else if (config.acc == 2) {
      // Sleek Sunglasses
      paint.color = const Color(0xFF1A202C).withOpacity(0.95);
      final Rect leftGlass = Rect.fromLTWH(leftEyeX - w * 0.08, eyeY - h * 0.05, w * 0.16, h * 0.09);
      final Rect rightGlass = Rect.fromLTWH(rightEyeX - w * 0.08, eyeY - h * 0.05, w * 0.16, h * 0.09);
      canvas.drawRRect(RRect.fromRectAndRadius(leftGlass, Radius.circular(w * 0.02)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(rightGlass, Radius.circular(w * 0.02)), paint);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.015;
      paint.color = const Color(0xFF1A202C);
      canvas.drawLine(Offset(cx - w * 0.04, eyeY - h * 0.02), Offset(cx + w * 0.04, eyeY - h * 0.02), paint);
    } else if (config.acc == 3) {
      // Eyepatch (Pirate)
      paint.color = const Color(0xFF1A202C);
      canvas.drawCircle(Offset(leftEyeX, eyeY), w * 0.065, paint);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.015;
      canvas.drawLine(Offset(cx - w * 0.28, cy - h * 0.12), Offset(cx + w * 0.2, cy + h * 0.08), paint);
    } else if (config.acc == 4) {
      // Headset / Headphones
      paint.color = _parseColor(config.bgColor);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.04;
      // Headband arc
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.29),
        math.pi,
        math.pi,
        false,
        paint,
      );
      // Ear cups
      paint.style = PaintingStyle.fill;
      final Rect leftCup = Rect.fromLTWH(cx - w * 0.33, cy - h * 0.08, w * 0.07, h * 0.16);
      final Rect rightCup = Rect.fromLTWH(cx + w * 0.26, cy - h * 0.08, w * 0.07, h * 0.16);
      canvas.drawRRect(RRect.fromRectAndRadius(leftCup, Radius.circular(w * 0.03)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(rightCup, Radius.circular(w * 0.03)), paint);
    } else if (config.acc == 5) {
      // Cool Face Scar
      paint.color = const Color(0xFFE53E3E).withOpacity(0.7);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.008;
      canvas.drawLine(Offset(rightEyeX - w * 0.04, eyeY - h * 0.06), Offset(rightEyeX + w * 0.04, eyeY + h * 0.06), paint);
    }

    // Draw Custom Paint Strokes (Freehand drawing layer)
    for (final stroke in config.customStrokes) {
      if (stroke.points.isEmpty) continue;
      final Paint strokePaint = Paint()
        ..color = _parseColor(stroke.color)
        ..strokeWidth = stroke.width * (w / 200.0) // Scale stroke width relative to canvas size
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      
      final Path strokePath = Path();
      strokePath.moveTo(stroke.points[0].dx * w, stroke.points[0].dy * h);
      for (int i = 1; i < stroke.points.length; i++) {
        strokePath.lineTo(stroke.points[i].dx * w, stroke.points[i].dy * h);
      }
      canvas.drawPath(strokePath, strokePaint);
    }

    canvas.restore();
  }

  void _drawStar(Canvas canvas, Offset center, int points, double outerRadius, double innerRadius) {
    final Path path = Path();
    double angle = -math.pi / 2;
    final double increment = math.pi / points;

    for (int i = 0; i < points * 2; i++) {
      final double r = i.isEven ? outerRadius : innerRadius;
      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      angle += increment;
    }
    path.close();
    canvas.drawPath(path, Paint()..color = Colors.amber);
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF' + hex;
    return Color(int.parse(hex, radix: 16));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
