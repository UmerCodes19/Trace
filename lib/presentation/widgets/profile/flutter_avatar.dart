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
  final int hair;        // 0–23 hairstyles
  final int eyes;        // 0–10 eye styles
  final int mouth;       // 0–9 mouth styles
  final int acc;         // 0–10 accessories
  final int facialHair;  // 0–4 facial hair
  final int details;     // 0–2 face details
  final int eyebrows;    // 0–6 eyebrow shapes
  final int noseStyle;   // 0–3 nose types
  final int outfit;      // 0–6 outfit silhouettes
  final int earring;     // 0–3 earring types
  final int hatOverride; // 0: use hair, 1: Beanie, 2: Bucket, 3: Snapback
  final int bgStyle;     // 0: solid, 1: radial gradient, 2: diagonal split, 3: glow
  final int vibe;        // 0–5 personality archetype
  final String bgColor;
  final String skinColor;
  final String hairColor;
  final String outfitColor;
  final String? hairGradient; // secondary color for split/gradient hair
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
    this.eyebrows = 0,
    this.noseStyle = 0,
    this.outfit = 0,
    this.earring = 0,
    this.hatOverride = 0,
    this.bgStyle = 0,
    this.vibe = 0,
    this.hairGradient,
    this.customStrokes = const [],
  });

  factory AvatarConfig.defaultConfig() {
    return AvatarConfig(
      hair: 1, eyes: 0, mouth: 0, acc: 0, facialHair: 0, details: 0,
      bgColor: '#FF6B6B', skinColor: '#FFDBB5', hairColor: '#2D3748', outfitColor: '#4A5568',
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
        eyebrows: map['eyebrows'] ?? 0,
        noseStyle: map['noseStyle'] ?? 0,
        outfit: map['outfit'] ?? 0,
        earring: map['earring'] ?? 0,
        hatOverride: map['hatOverride'] ?? 0,
        bgStyle: map['bgStyle'] ?? 0,
        vibe: map['vibe'] ?? 0,
        bgColor: map['bgColor'] ?? '#FF6B6B',
        skinColor: map['skinColor'] ?? '#FFDBB5',
        hairColor: map['hairColor'] ?? '#2D3748',
        outfitColor: map['outfitColor'] ?? '#4A5568',
        hairGradient: map['hairGradient'],
        customStrokes: strokes,
      );
    } catch (_) {
      return AvatarConfig.defaultConfig();
    }
  }

  String toJson() {
    final map = <String, dynamic>{
      'hair': hair, 'eyes': eyes, 'mouth': mouth, 'acc': acc,
      'facialHair': facialHair, 'details': details,
      'eyebrows': eyebrows, 'noseStyle': noseStyle, 'outfit': outfit,
      'earring': earring, 'hatOverride': hatOverride,
      'bgStyle': bgStyle, 'vibe': vibe,
      'bgColor': bgColor, 'skinColor': skinColor,
      'hairColor': hairColor, 'outfitColor': outfitColor,
    };
    if (hairGradient != null) map['hairGradient'] = hairGradient;
    if (customStrokes.isNotEmpty) {
      map['customStrokes'] = customStrokes.map((s) => s.toMap()).toList();
    }
    return jsonEncode(map);
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
        painter: AvatarPainter(config: config, renderSize: size),
      ),
    );
  }
}

class AvatarPainter extends CustomPainter {
  final AvatarConfig config;
  final double blinkPhase;  // 0.0 = eyes open, 1.0 = eyes fully closed
  final double swayPhase;   // -1.0 to 1.0 sine wave for hair motion
  final double renderSize;  // actual pixel size for adaptive detail

  AvatarPainter({
    required this.config,
    this.blinkPhase = 0.0,
    this.swayPhase = 0.0,
    this.renderSize = 100.0,
  });

  // Adaptive detail: skip fine details at micro scale
  bool get _isMicro => renderSize <= 40;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    // Signature Trace proportion: head sits slightly higher for a stylized look
    final double cy = h * 0.48;

    final Paint paint = Paint()..isAntiAlias = true;

    // 1. Background Circle
    final Color bg = _parseColor(config.bgColor);
    
    if (!_isMicro && config.bgStyle > 0) {
      if (config.bgStyle == 1) {
        // Radial Gradient — gentle center glow
        paint.shader = RadialGradient(
          colors: [bg.withOpacity(0.6), bg],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w / 2));
      } else if (config.bgStyle == 2) {
        // Diagonal Split
        paint.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg.withOpacity(0.8), bg],
          stops: const [0.4, 0.6],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w / 2));
      } else if (config.bgStyle == 3) {
        // Atmospheric Glow
        paint.shader = RadialGradient(
          colors: [Colors.white.withOpacity(0.2), bg, bg.withOpacity(0.8)],
          stops: const [0.0, 0.5, 1.0],
          center: const Alignment(0, -0.2),
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w / 2));
      }
    } else {
      // Solid base with subtle top-to-bottom depth for premium feel even on default
      if (!_isMicro) {
        paint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bg, bg.withOpacity(0.85)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w / 2));
      } else {
        paint.color = bg;
      }
    }
    
    canvas.drawCircle(Offset(cx, cy), w / 2, paint);
    paint.shader = null; // reset shader

    // Save state to clip shoulders/outfit to the background circle boundary
    canvas.save();
    final Path clipPath = Path()..addOval(Rect.fromLTWH(0, 0, w, h));
    canvas.clipPath(clipPath);

    // ─── Silhouette Separation Pass ──────────────────────────────────────────
    // Inject a soft contrast blob behind all components to separate from BG
    if (!_isMicro) {
      final Paint silhouetteShadow = Paint()
        ..color = Colors.black.withOpacity(0.1) // Extremely soft dark glow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05);
      // Draw an oval encompassing roughly head and torso
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + h * 0.1), width: w * 0.65, height: h * 0.7),
        silhouetteShadow,
      );
    }
    // ─────────────────────────────────────────────────────────────────────────

    // 2. Draw Shoulders & Outfit (with silhouette variants)
    final Color outfit = _parseColor(config.outfitColor);
    paint.color = outfit;
    if (config.outfit == 1) {
      // Hoodie — wider shoulders + hood behind head
      paint.color = outfit.withOpacity(0.7);
      // Hood silhouette behind head
      final Path hood = Path()
        ..moveTo(cx - w * 0.22, cy - h * 0.08)
        ..quadraticBezierTo(cx, cy - h * 0.25, cx + w * 0.22, cy - h * 0.08)
        ..quadraticBezierTo(cx + w * 0.3, cy + h * 0.05, cx + w * 0.26, cy + h * 0.15)
        ..lineTo(cx - w * 0.26, cy + h * 0.15)
        ..quadraticBezierTo(cx - w * 0.3, cy + h * 0.05, cx - w * 0.22, cy - h * 0.08)
        ..close();
      canvas.drawPath(hood, paint);
      paint.color = outfit;
      final Path hoodieBody = Path()
        ..moveTo(w * 0.08, h)..quadraticBezierTo(cx, h * 0.58, w * 0.92, h)
        ..lineTo(w, h)..lineTo(0, h)..close();
      canvas.drawPath(hoodieBody, paint);
    } else if (config.outfit == 2) {
      // Jacket — V-lapel collar
      final Path jacketBody = Path()
        ..moveTo(w * 0.1, h)..quadraticBezierTo(cx, h * 0.6, w * 0.9, h)
        ..lineTo(w, h)..lineTo(0, h)..close();
      canvas.drawPath(jacketBody, paint);
      // Lapel lines
      paint.color = outfit.withOpacity(0.6);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      canvas.drawLine(Offset(cx, h * 0.62), Offset(cx - w * 0.1, h * 0.78), paint);
      canvas.drawLine(Offset(cx, h * 0.62), Offset(cx + w * 0.1, h * 0.78), paint);
      paint.style = PaintingStyle.fill;
    } else if (config.outfit == 3) {
      // Turtleneck — raised collar cylinder
      final Path turtleBody = Path()
        ..moveTo(w * 0.12, h)..quadraticBezierTo(cx, h * 0.62, w * 0.88, h)
        ..lineTo(w, h)..lineTo(0, h)..close();
      canvas.drawPath(turtleBody, paint);
      // Tall collar
      paint.color = outfit.withOpacity(0.85);
      final Rect collar = Rect.fromLTWH(cx - w * 0.1, cy + h * 0.12, w * 0.2, h * 0.1);
      canvas.drawRRect(RRect.fromRectAndRadius(collar, Radius.circular(w * 0.04)), paint);
    } else if (config.outfit == 4) {
      // Tank Top — narrow straps, exposed shoulders
      final Path tank = Path()
        ..moveTo(w * 0.28, h)..quadraticBezierTo(cx, h * 0.65, w * 0.72, h)
        ..lineTo(w, h)..lineTo(0, h)..close();
      canvas.drawPath(tank, paint);
    } else if (config.outfit == 5) {
      // Button Shirt — collared with center seam
      final Path shirtBody = Path()
        ..moveTo(w * 0.1, h)..quadraticBezierTo(cx, h * 0.6, w * 0.9, h)
        ..lineTo(w, h)..lineTo(0, h)..close();
      canvas.drawPath(shirtBody, paint);
      // Collar wings
      paint.color = outfit.withOpacity(0.7);
      final Path collarL = Path()..moveTo(cx - w * 0.02, h * 0.62)..lineTo(cx - w * 0.12, h * 0.66)..lineTo(cx - w * 0.06, h * 0.72)..close();
      final Path collarR = Path()..moveTo(cx + w * 0.02, h * 0.62)..lineTo(cx + w * 0.12, h * 0.66)..lineTo(cx + w * 0.06, h * 0.72)..close();
      canvas.drawPath(collarL, paint); canvas.drawPath(collarR, paint);
    } else if (config.outfit == 6) {
      // Sweater — rounded soft shoulders, ribbed neck hint
      final Path sweater = Path()
        ..moveTo(w * 0.08, h)..quadraticBezierTo(cx, h * 0.6, w * 0.92, h)
        ..lineTo(w, h)..lineTo(0, h)..close();
      canvas.drawPath(sweater, paint);
      // Ribbed collar hint
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.005;
      paint.color = outfit.withOpacity(0.5);
      for (double dy = 0; dy < 3; dy++) {
        canvas.drawLine(Offset(cx - w * 0.08, h * 0.64 + dy * h * 0.012), Offset(cx + w * 0.08, h * 0.64 + dy * h * 0.012), paint);
      }
      paint.style = PaintingStyle.fill;
    } else {
      // 0: Default Tee — simple clean
      final Path outfitPath = Path()
        ..moveTo(w * 0.12, h)..quadraticBezierTo(cx, h * 0.62, w * 0.88, h)
        ..lineTo(w, h)..lineTo(0, h)..close();
      canvas.drawPath(outfitPath, paint);
    }

    // Draw Neck
    final Color skin = _parseColor(config.skinColor);
    final Rect neckRect = Rect.fromLTWH(cx - w * 0.08, cy + h * 0.08, w * 0.16, h * 0.18);
    
    if (!_isMicro) {
      // Chin drop shadow
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skin.withValues(alpha: 0.6), skin.withValues(alpha: 0.95)],
        stops: const [0.0, 0.4],
      ).createShader(neckRect);
      canvas.drawRRect(RRect.fromRectAndRadius(neckRect, Radius.circular(w * 0.03)), paint);
      paint.shader = null;
    } else {
      paint.color = skin.withOpacity(0.85); // Slight flat shadow logic
      canvas.drawRRect(RRect.fromRectAndRadius(neckRect, Radius.circular(w * 0.03)), paint);
    }

    // 3. Draw Back Hair (for long hairstyles)
    final Color hairColor = _parseColor(config.hairColor);
    paint.color = hairColor;
    if (config.hair == 7) {
      // Long hair draped behind shoulders
      final double sway = w * swayPhase * 0.06;
      final Path longHairBack = Path()
        ..moveTo(cx - w * 0.32, cy - h * 0.1)
        ..quadraticBezierTo(cx - w * 0.36, cy + h * 0.2, cx - w * 0.24 + sway, h * 0.95)
        ..lineTo(cx + w * 0.24 + sway, h * 0.95)
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
    if (!_isMicro) {
      // Base skin with subtle gradient and hair drop shadow
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skin.withValues(alpha: 0.85), skin], // Darker at top for hair shadow
        stops: const [0.0, 0.3],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.28));
      canvas.drawCircle(Offset(cx, cy), w * 0.28, paint);
      paint.shader = null;
      
      // Global rim light (top-left edge highlight)
      paint.color = Colors.white.withValues(alpha: 0.15);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.015;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.28 - (w * 0.007)),
        math.pi, // from left
        math.pi / 1.5, // curve up to top right
        false,
        paint,
      );
      paint.style = PaintingStyle.fill;
    } else {
      paint.color = skin;
      canvas.drawCircle(Offset(cx, cy), w * 0.28, paint);
    }

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
    } else if (config.hair == 12) {
      // Curtain Bangs — split parted flowing fringe
      final Path curtain = Path()
        ..moveTo(cx - w * 0.28, cy - h * 0.05)
        ..cubicTo(cx - w * 0.34, cy - h * 0.34, cx + w * 0.34, cy - h * 0.34, cx + w * 0.28, cy - h * 0.05)
        ..quadraticBezierTo(cx + w * 0.15, cy - h * 0.2, cx, cy - h * 0.08)
        ..quadraticBezierTo(cx - w * 0.15, cy - h * 0.2, cx - w * 0.28, cy - h * 0.05)
        ..close();
      canvas.drawPath(curtain, paint);
    } else if (config.hair == 13) {
      // Buzz Fade — tight top with skin fade sides
      final Path buzz = Path()
        ..moveTo(cx - w * 0.22, cy - h * 0.08)
        ..cubicTo(cx - w * 0.26, cy - h * 0.3, cx + w * 0.26, cy - h * 0.3, cx + w * 0.22, cy - h * 0.08)
        ..quadraticBezierTo(cx, cy - h * 0.14, cx - w * 0.22, cy - h * 0.08)
        ..close();
      canvas.drawPath(buzz, paint);
      // Fade gradient on sides
      paint.color = hairColor.withOpacity(0.25);
      canvas.drawCircle(Offset(cx - w * 0.25, cy - h * 0.02), w * 0.06, paint);
      canvas.drawCircle(Offset(cx + w * 0.25, cy - h * 0.02), w * 0.06, paint);
    } else if (config.hair == 14) {
      // Wolf Cut — layered shaggy with volume
      final Path wolf = Path()
        ..moveTo(cx - w * 0.3, cy)
        ..cubicTo(cx - w * 0.36, cy - h * 0.35, cx + w * 0.36, cy - h * 0.35, cx + w * 0.3, cy)
        ..quadraticBezierTo(cx + w * 0.24, cy - h * 0.1, cx + w * 0.18, cy + h * 0.04)
        ..quadraticBezierTo(cx, cy - h * 0.08, cx - w * 0.18, cy + h * 0.04)
        ..quadraticBezierTo(cx - w * 0.24, cy - h * 0.1, cx - w * 0.3, cy)
        ..close();
      canvas.drawPath(wolf, paint);
    } else if (config.hair == 15) {
      // Box Braids — thick parallel strands
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.035;
      paint.strokeCap = StrokeCap.round;
      // Base volume
      paint.style = PaintingStyle.fill;
      final Path base = Path()
        ..moveTo(cx - w * 0.28, cy - h * 0.05)
        ..cubicTo(cx - w * 0.34, cy - h * 0.34, cx + w * 0.34, cy - h * 0.34, cx + w * 0.28, cy - h * 0.05)
        ..close();
      canvas.drawPath(base, paint);
      // Braid lines
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.028;
      paint.color = hairColor.withOpacity(0.5);
      for (double dx = -0.2; dx <= 0.2; dx += 0.08) {
        canvas.drawLine(Offset(cx + w * dx, cy - h * 0.24), Offset(cx + w * dx * 1.3, cy + h * 0.1), paint);
      }
      paint.style = PaintingStyle.fill;
      paint.color = hairColor;
    } else if (config.hair == 16) {
      // Shag — messy textured layers
      final Path shag = Path()
        ..moveTo(cx - w * 0.3, cy + h * 0.02)
        ..cubicTo(cx - w * 0.36, cy - h * 0.34, cx + w * 0.36, cy - h * 0.34, cx + w * 0.3, cy + h * 0.02)
        ..lineTo(cx + w * 0.22, cy - h * 0.04)
        ..lineTo(cx + w * 0.26, cy + h * 0.01)
        ..lineTo(cx + w * 0.15, cy - h * 0.02)
        ..lineTo(cx - w * 0.15, cy - h * 0.02)
        ..lineTo(cx - w * 0.26, cy + h * 0.01)
        ..lineTo(cx - w * 0.22, cy - h * 0.04)
        ..close();
      canvas.drawPath(shag, paint);
    } else if (config.hair == 17) {
      // Pixie — short elegant crop
      final Path pixie = Path()
        ..moveTo(cx - w * 0.26, cy - h * 0.06)
        ..cubicTo(cx - w * 0.3, cy - h * 0.32, cx + w * 0.3, cy - h * 0.32, cx + w * 0.26, cy - h * 0.06)
        ..quadraticBezierTo(cx + w * 0.1, cy - h * 0.18, cx - w * 0.26, cy - h * 0.06)
        ..close();
      canvas.drawPath(pixie, paint);
    } else if (config.hair == 18) {
      // Sleek Bob — clean angular cut
      final Path bob = Path()
        ..moveTo(cx - w * 0.28, cy + h * 0.06)
        ..cubicTo(cx - w * 0.34, cy - h * 0.34, cx + w * 0.34, cy - h * 0.34, cx + w * 0.28, cy + h * 0.06)
        ..lineTo(cx + w * 0.24, cy - h * 0.02)
        ..quadraticBezierTo(cx, cy - h * 0.12, cx - w * 0.24, cy - h * 0.02)
        ..close();
      canvas.drawPath(bob, paint);
    } else if (config.hair == 19) {
      // Mohawk — dramatic center ridge
      final Path mohawk = Path()
        ..moveTo(cx - w * 0.06, cy - h * 0.06)
        ..cubicTo(cx - w * 0.08, cy - h * 0.42, cx + w * 0.08, cy - h * 0.42, cx + w * 0.06, cy - h * 0.06)
        ..quadraticBezierTo(cx, cy - h * 0.12, cx - w * 0.06, cy - h * 0.06)
        ..close();
      canvas.drawPath(mohawk, paint);
      // Shaved sides hint
      paint.color = hairColor.withOpacity(0.15);
      canvas.drawCircle(Offset(cx - w * 0.2, cy - h * 0.1), w * 0.08, paint);
      canvas.drawCircle(Offset(cx + w * 0.2, cy - h * 0.1), w * 0.08, paint);
      paint.color = hairColor;
    } else if (config.hair == 20) {
      // Cornrows — tight parallel rows
      final Path base = Path()
        ..moveTo(cx - w * 0.28, cy - h * 0.05)
        ..cubicTo(cx - w * 0.32, cy - h * 0.32, cx + w * 0.32, cy - h * 0.32, cx + w * 0.28, cy - h * 0.05)
        ..quadraticBezierTo(cx, cy - h * 0.15, cx - w * 0.28, cy - h * 0.05)
        ..close();
      canvas.drawPath(base, paint);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.008;
      paint.color = hairColor.withOpacity(0.35);
      for (double dx = -0.18; dx <= 0.18; dx += 0.06) {
        final Path row = Path()
          ..moveTo(cx + w * dx, cy - h * 0.28)
          ..quadraticBezierTo(cx + w * dx, cy - h * 0.15, cx + w * dx * 0.8, cy - h * 0.06);
        canvas.drawPath(row, paint);
      }
      paint.style = PaintingStyle.fill;
      paint.color = hairColor;
    } else if (config.hair == 21) {
      // Space Buns — two round buns on top
      final Path base = Path()
        ..moveTo(cx - w * 0.28, cy - h * 0.05)
        ..cubicTo(cx - w * 0.32, cy - h * 0.3, cx + w * 0.32, cy - h * 0.3, cx + w * 0.28, cy - h * 0.05)
        ..quadraticBezierTo(cx, cy - h * 0.18, cx - w * 0.28, cy - h * 0.05)
        ..close();
      canvas.drawPath(base, paint);
      canvas.drawCircle(Offset(cx - w * 0.16, cy - h * 0.3), w * 0.1, paint);
      canvas.drawCircle(Offset(cx + w * 0.16, cy - h * 0.3), w * 0.1, paint);
    } else if (config.hair == 22) {
      // Locs — thick textured locks
      final Path base = Path()
        ..moveTo(cx - w * 0.28, cy - h * 0.05)
        ..cubicTo(cx - w * 0.34, cy - h * 0.34, cx + w * 0.34, cy - h * 0.34, cx + w * 0.28, cy - h * 0.05)
        ..close();
      canvas.drawPath(base, paint);
      // Thick cylindrical locs falling down
      for (double dx = -0.22; dx <= 0.22; dx += 0.088) {
        final RRect loc = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + w * dx - w * 0.02, cy - h * 0.22, w * 0.04, h * 0.28),
          Radius.circular(w * 0.02),
        );
        canvas.drawRRect(loc, paint);
      }
    } else if (config.hair == 23) {
      // Side Shave — asymmetric with volume on one side
      final Path sideShave = Path()
        ..moveTo(cx - w * 0.28, cy - h * 0.05)
        ..cubicTo(cx - w * 0.32, cy - h * 0.34, cx + w * 0.32, cy - h * 0.34, cx + w * 0.28, cy - h * 0.05)
        ..quadraticBezierTo(cx + w * 0.1, cy - h * 0.15, cx, cy - h * 0.05)
        ..quadraticBezierTo(cx - w * 0.2, cy - h * 0.25, cx - w * 0.28, cy - h * 0.05)
        ..close();
      canvas.drawPath(sideShave, paint);
      // Shaved right side hint
      paint.color = hairColor.withOpacity(0.15);
      canvas.drawCircle(Offset(cx + w * 0.22, cy - h * 0.06), w * 0.08, paint);
      paint.color = hairColor;
    }

    // Shared eye coordinates (used by both eyebrows and eyes)
    // Signature Asymmetry: Slight natural offset to prevent robotic perfection
    final double asymY = _isMicro ? 0.0 : h * 0.004; 
    final double leftEyeY = cy - asymY;
    final double rightEyeY = cy + asymY * 0.5;
    final double leftEyeX = cx - w * 0.09 - (_isMicro ? 0.0 : w * 0.002);
    final double rightEyeX = cx + w * 0.09 + (_isMicro ? 0.0 : w * 0.002);
    final double eyeSize = w * 0.035;

    // 7b. Eyebrows (skip at micro scale for readability)
    if (!_isMicro) {
    paint.color = hairColor;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    final double browY = cy - h * 0.06;
    final double browSpan = w * 0.07;
    if (config.eyebrows == 0) {
      // Default — subtle natural arcs
      paint.strokeWidth = w * 0.012;
      canvas.drawArc(Rect.fromCenter(center: Offset(leftEyeX, browY), width: browSpan, height: w * 0.03), -2.8, 1.6, false, paint);
      canvas.drawArc(Rect.fromCenter(center: Offset(rightEyeX, browY), width: browSpan, height: w * 0.03), -2.8 + 1.2, 1.6, false, paint);
    } else if (config.eyebrows == 1) {
      // Arched — elegant high arch
      paint.strokeWidth = w * 0.014;
      final Path lb = Path()..moveTo(leftEyeX - browSpan * 0.6, browY + h * 0.01)..quadraticBezierTo(leftEyeX, browY - h * 0.025, leftEyeX + browSpan * 0.6, browY);
      final Path rb = Path()..moveTo(rightEyeX - browSpan * 0.6, browY)..quadraticBezierTo(rightEyeX, browY - h * 0.025, rightEyeX + browSpan * 0.6, browY + h * 0.01);
      canvas.drawPath(lb, paint); canvas.drawPath(rb, paint);
    } else if (config.eyebrows == 2) {
      // Straight — flat serious
      paint.strokeWidth = w * 0.015;
      canvas.drawLine(Offset(leftEyeX - browSpan * 0.5, browY), Offset(leftEyeX + browSpan * 0.5, browY), paint);
      canvas.drawLine(Offset(rightEyeX - browSpan * 0.5, browY), Offset(rightEyeX + browSpan * 0.5, browY), paint);
    } else if (config.eyebrows == 3) {
      // Thick — bold statement
      paint.strokeWidth = w * 0.022;
      canvas.drawArc(Rect.fromCenter(center: Offset(leftEyeX, browY), width: browSpan, height: w * 0.03), -2.8, 1.6, false, paint);
      canvas.drawArc(Rect.fromCenter(center: Offset(rightEyeX, browY), width: browSpan, height: w * 0.03), -2.8 + 1.2, 1.6, false, paint);
    } else if (config.eyebrows == 4) {
      // Thin — delicate
      paint.strokeWidth = w * 0.007;
      canvas.drawArc(Rect.fromCenter(center: Offset(leftEyeX, browY), width: browSpan, height: w * 0.025), -2.8, 1.6, false, paint);
      canvas.drawArc(Rect.fromCenter(center: Offset(rightEyeX, browY), width: browSpan, height: w * 0.025), -2.8 + 1.2, 1.6, false, paint);
    } else if (config.eyebrows == 5) {
      // Angry — angled inward
      paint.strokeWidth = w * 0.016;
      canvas.drawLine(Offset(leftEyeX - browSpan * 0.5, browY - h * 0.01), Offset(leftEyeX + browSpan * 0.4, browY + h * 0.015), paint);
      canvas.drawLine(Offset(rightEyeX - browSpan * 0.4, browY + h * 0.015), Offset(rightEyeX + browSpan * 0.5, browY - h * 0.01), paint);
    } else if (config.eyebrows == 6) {
      // Worried — angled outward
      paint.strokeWidth = w * 0.013;
      canvas.drawLine(Offset(leftEyeX - browSpan * 0.5, browY + h * 0.015), Offset(leftEyeX + browSpan * 0.4, browY - h * 0.01), paint);
      canvas.drawLine(Offset(rightEyeX - browSpan * 0.4, browY - h * 0.01), Offset(rightEyeX + browSpan * 0.5, browY + h * 0.015), paint);
    }
    paint.style = PaintingStyle.fill;
    } // end _isMicro for eyebrows

    // 8. Eyes Rendering
    paint.color = const Color(0xFF1A202C);

    // Blink animation override — when blinking, draw closed eye arcs
    if (blinkPhase > 0.5) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      paint.strokeCap = StrokeCap.round;
      final Path closedL = Path()
        ..moveTo(leftEyeX - eyeSize, leftEyeY)
        ..quadraticBezierTo(leftEyeX, leftEyeY + eyeSize * 0.6, leftEyeX + eyeSize, leftEyeY);
      final Path closedR = Path()
        ..moveTo(rightEyeX - eyeSize, rightEyeY)
        ..quadraticBezierTo(rightEyeX, rightEyeY + eyeSize * 0.6, rightEyeX + eyeSize, rightEyeY);
      canvas.drawPath(closedL, paint);
      canvas.drawPath(closedR, paint);
      paint.style = PaintingStyle.fill;
    } else {
    // Normal eye rendering (inside else block)
    if (config.eyes == 0) {
      // Normal cute eyes
      canvas.drawCircle(Offset(leftEyeX, leftEyeY), eyeSize, paint);
      canvas.drawCircle(Offset(rightEyeX, rightEyeY), eyeSize, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(leftEyeX - w * 0.008, leftEyeY - h * 0.008), eyeSize * 0.35, paint);
      canvas.drawCircle(Offset(rightEyeX - w * 0.008, rightEyeY - h * 0.008), eyeSize * 0.35, paint);
    } else if (config.eyes == 1) {
      // Wink
      final Path winkPath = Path()
        ..moveTo(leftEyeX - eyeSize, leftEyeY)
        ..quadraticBezierTo(leftEyeX, leftEyeY + eyeSize * 0.8, leftEyeX + eyeSize, leftEyeY);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      paint.strokeCap = StrokeCap.round;
      canvas.drawPath(winkPath, paint);

      paint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(rightEyeX, rightEyeY), eyeSize, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(rightEyeX - w * 0.008, rightEyeY - h * 0.008), eyeSize * 0.35, paint);
    } else if (config.eyes == 2) {
      // Happy curves
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      paint.strokeCap = StrokeCap.round;
      final Path happyLeft = Path()
        ..moveTo(leftEyeX - eyeSize, leftEyeY + eyeSize * 0.3)
        ..quadraticBezierTo(leftEyeX, leftEyeY - eyeSize * 0.8, leftEyeX + eyeSize, leftEyeY + eyeSize * 0.3);
      final Path happyRight = Path()
        ..moveTo(rightEyeX - eyeSize, rightEyeY + eyeSize * 0.3)
        ..quadraticBezierTo(rightEyeX, rightEyeY - eyeSize * 0.8, rightEyeX + eyeSize, rightEyeY + eyeSize * 0.3);
      canvas.drawPath(happyLeft, paint);
      canvas.drawPath(happyRight, paint);
    } else if (config.eyes == 3) {
      // Star Eyes ✨
      paint.color = Colors.amber;
      _drawStar(canvas, Offset(leftEyeX, leftEyeY), 5, eyeSize * 1.5, eyeSize * 0.6);
      _drawStar(canvas, Offset(rightEyeX, rightEyeY), 5, eyeSize * 1.5, eyeSize * 0.6);
    } else if (config.eyes == 4) {
      // Cute Anime Eyes (big glassy)
      canvas.drawCircle(Offset(leftEyeX, leftEyeY), eyeSize * 1.4, paint);
      canvas.drawCircle(Offset(rightEyeX, rightEyeY), eyeSize * 1.4, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(leftEyeX - eyeSize * 0.4, leftEyeY - eyeSize * 0.4), eyeSize * 0.5, paint);
      canvas.drawCircle(Offset(leftEyeX + eyeSize * 0.4, leftEyeY + eyeSize * 0.4), eyeSize * 0.25, paint);
      canvas.drawCircle(Offset(rightEyeX - eyeSize * 0.4, rightEyeY - eyeSize * 0.4), eyeSize * 0.5, paint);
      canvas.drawCircle(Offset(rightEyeX + eyeSize * 0.4, rightEyeY + eyeSize * 0.4), eyeSize * 0.25, paint);
    } else if (config.eyes == 5) {
      // Cool Squint
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      paint.strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(leftEyeX - eyeSize, leftEyeY), Offset(leftEyeX + eyeSize, leftEyeY), paint);
      canvas.drawLine(Offset(rightEyeX - eyeSize, rightEyeY), Offset(rightEyeX + eyeSize, rightEyeY), paint);
    } else if (config.eyes == 6) {
      // Sleepy — droopy half-lids
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      paint.strokeCap = StrokeCap.round;
      final Path sl = Path()..moveTo(leftEyeX - eyeSize, leftEyeY + eyeSize * 0.2)..quadraticBezierTo(leftEyeX, leftEyeY - eyeSize * 0.3, leftEyeX + eyeSize, leftEyeY + eyeSize * 0.2);
      final Path sr = Path()..moveTo(rightEyeX - eyeSize, rightEyeY + eyeSize * 0.2)..quadraticBezierTo(rightEyeX, rightEyeY - eyeSize * 0.3, rightEyeX + eyeSize, rightEyeY + eyeSize * 0.2);
      canvas.drawPath(sl, paint); canvas.drawPath(sr, paint);
    } else if (config.eyes == 7) {
      // Sharp / Fox — angular upward tilt
      paint.style = PaintingStyle.fill;
      final Path fl = Path()..moveTo(leftEyeX - eyeSize * 1.2, leftEyeY + eyeSize * 0.3)..lineTo(leftEyeX, leftEyeY - eyeSize * 0.5)..lineTo(leftEyeX + eyeSize * 1.2, leftEyeY + eyeSize * 0.1)..close();
      final Path fr = Path()..moveTo(rightEyeX - eyeSize * 1.2, rightEyeY + eyeSize * 0.1)..lineTo(rightEyeX, rightEyeY - eyeSize * 0.5)..lineTo(rightEyeX + eyeSize * 1.2, rightEyeY + eyeSize * 0.3)..close();
      canvas.drawPath(fl, paint); canvas.drawPath(fr, paint);
    } else if (config.eyes == 8) {
      // Round / Doe — large gentle circles
      canvas.drawCircle(Offset(leftEyeX, leftEyeY), eyeSize * 1.2, paint);
      canvas.drawCircle(Offset(rightEyeX, rightEyeY), eyeSize * 1.2, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(leftEyeX - eyeSize * 0.3, leftEyeY - eyeSize * 0.3), eyeSize * 0.45, paint);
      canvas.drawCircle(Offset(rightEyeX - eyeSize * 0.3, rightEyeY - eyeSize * 0.3), eyeSize * 0.45, paint);
    } else if (config.eyes == 9) {
      // Heterochromia — two different colored eyes
      paint.color = const Color(0xFF1565C0);
      canvas.drawCircle(Offset(leftEyeX, leftEyeY), eyeSize * 1.1, paint);
      paint.color = const Color(0xFF4E342E);
      canvas.drawCircle(Offset(rightEyeX, rightEyeY), eyeSize * 1.1, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(leftEyeX - w * 0.008, leftEyeY - h * 0.008), eyeSize * 0.35, paint);
      canvas.drawCircle(Offset(rightEyeX - w * 0.008, rightEyeY - h * 0.008), eyeSize * 0.35, paint);
    } else if (config.eyes == 10) {
      // Crescent — soft gentle crescents
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.014;
      paint.strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: Offset(leftEyeX, leftEyeY), width: eyeSize * 2.2, height: eyeSize * 1.6), -2.6, 1.2, false, paint);
      canvas.drawArc(Rect.fromCenter(center: Offset(rightEyeX, rightEyeY), width: eyeSize * 2.2, height: eyeSize * 1.6), -2.6 + 1.4, 1.2, false, paint);
    }
    } // end blink else

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
    } else if (config.mouth == 6) {
      // Cat mouth — :3
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.01;
      paint.strokeCap = StrokeCap.round;
      final Path catL = Path()..moveTo(cx, mouthY)..quadraticBezierTo(cx - w * 0.04, mouthY + h * 0.03, cx - w * 0.07, mouthY);
      final Path catR = Path()..moveTo(cx, mouthY)..quadraticBezierTo(cx + w * 0.04, mouthY + h * 0.03, cx + w * 0.07, mouthY);
      canvas.drawPath(catL, paint); canvas.drawPath(catR, paint);
    } else if (config.mouth == 7) {
      // Teeth Grin — wide confident smile showing teeth
      final Path grin = Path()..moveTo(cx - w * 0.07, mouthY)..quadraticBezierTo(cx, mouthY + h * 0.05, cx + w * 0.07, mouthY)..close();
      canvas.drawPath(grin, paint);
      paint.color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(cx - w * 0.05, mouthY, w * 0.1, h * 0.018), paint);
    } else if (config.mouth == 8) {
      // Tongue Out — playful
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.012;
      paint.strokeCap = StrokeCap.round;
      final Path smile = Path()..moveTo(cx - w * 0.05, mouthY)..quadraticBezierTo(cx, mouthY + h * 0.04, cx + w * 0.05, mouthY);
      canvas.drawPath(smile, paint);
      paint.style = PaintingStyle.fill;
      paint.color = const Color(0xFFE57373);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, mouthY + h * 0.04), width: w * 0.04, height: h * 0.03), paint);
    } else if (config.mouth == 9) {
      // Tiny O — surprised whisper
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.01;
      canvas.drawCircle(Offset(cx, mouthY + h * 0.01), w * 0.02, paint);
    }

    paint.style = PaintingStyle.fill;

    // 10. Accessories
    final double avgEyeY = (leftEyeY + rightEyeY) / 2;
    // We use avgEyeY for most things, but can still access leftEyeY / rightEyeY.
    // Re-alias to eyeY for legacy code compatibility below.
    final double eyeY = avgEyeY; 

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
    } else if (config.acc == 6) {
      // Face Mask — covers mouth area
      paint.color = Colors.white.withOpacity(0.92);
      paint.style = PaintingStyle.fill;
      final Path mask = Path()
        ..moveTo(cx - w * 0.2, cy + h * 0.02)
        ..quadraticBezierTo(cx - w * 0.22, cy + h * 0.18, cx, cy + h * 0.22)
        ..quadraticBezierTo(cx + w * 0.22, cy + h * 0.18, cx + w * 0.2, cy + h * 0.02)
        ..close();
      canvas.drawPath(mask, paint);
      // Ear loops
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.006;
      paint.color = Colors.grey.withOpacity(0.5);
      canvas.drawLine(Offset(cx - w * 0.2, cy + h * 0.04), Offset(cx - w * 0.27, cy), paint);
      canvas.drawLine(Offset(cx + w * 0.2, cy + h * 0.04), Offset(cx + w * 0.27, cy), paint);
    } else if (config.acc == 7) {
      // Bandaid — small cross bandage on cheek
      paint.color = const Color(0xFFFFCC80);
      paint.style = PaintingStyle.fill;
      final center = Offset(cx + w * 0.15, cy + h * 0.04);
      
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(0.15); // subtle 8-degree tilt for signature asymmetry
      
      final Rect bandH = Rect.fromCenter(center: Offset.zero, width: w * 0.08, height: h * 0.025);
      final Rect bandV = Rect.fromCenter(center: Offset.zero, width: w * 0.025, height: h * 0.08);
      canvas.drawRRect(RRect.fromRectAndRadius(bandH, Radius.circular(w * 0.01)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(bandV, Radius.circular(w * 0.01)), paint);
      
      canvas.restore();
    } else if (config.acc == 8) {
      // Chain Necklace — thin chain around neck
      paint.color = const Color(0xFFFFD700).withOpacity(0.85);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.008;
      final Path chain = Path()
        ..moveTo(cx - w * 0.15, cy + h * 0.2)
        ..quadraticBezierTo(cx, cy + h * 0.26, cx + w * 0.15, cy + h * 0.2);
      canvas.drawPath(chain, paint);
    } else if (config.acc == 9) {
      // AirPods — small white buds at ears
      paint.color = Colors.white;
      paint.style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - w * 0.27, cy + h * 0.02), width: w * 0.04, height: h * 0.06),
        Radius.circular(w * 0.02),
      ), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + w * 0.27, cy + h * 0.02), width: w * 0.04, height: h * 0.06),
        Radius.circular(w * 0.02),
      ), paint);
    } else if (config.acc == 10) {
      // Nose Ring — small ring on one side of nose
      paint.color = const Color(0xFFFFD700);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = w * 0.008;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx + w * 0.02, cy + h * 0.06), width: w * 0.03, height: h * 0.03),
        0.3, 2.5, false, paint,
      );
    }

    // Draw Custom Paint Strokes (Freehand drawing layer)
    if (!_isMicro) {
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
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
