import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/constants/app_colors.dart';

class FallingPatternBackground extends StatefulWidget {
  const FallingPatternBackground({
    super.key,
    required this.child,
    this.color,
    this.backgroundColor,
  });

  final Widget child;
  final Color? color;
  final Color? backgroundColor;

  @override
  State<FallingPatternBackground> createState() => _FallingPatternBackgroundState();
}

class _FallingPatternBackgroundState extends State<FallingPatternBackground> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() {
          _progress = (DateTime.now().millisecondsSinceEpoch % 22000) / 22000.0;
        });
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = AppColors.pageBg(context);
    final defaultPatternColor = AppColors.jadePrimary.withOpacity(isDark ? 0.20 : 0.12);

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _FallingPatternPainter(
              progress: _progress,
              patternColor: widget.color ?? defaultPatternColor,
              bgColor: widget.backgroundColor ?? defaultBg,
              isDark: isDark,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.4,
                colors: [
                  Colors.transparent,
                  (widget.backgroundColor ?? defaultBg).withOpacity(0.4),
                ],
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _FallingPatternPainter extends CustomPainter {
  _FallingPatternPainter({
    required this.progress,
    required this.patternColor,
    required this.bgColor,
    required this.isDark,
  });

  final double progress;
  final Color patternColor;
  final Color bgColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw solid background
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Draw dot-matrix grid overlay
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)
      ..style = PaintingStyle.fill;
    
    const double gridSize = 18.0;
    for (double gx = 0; gx < size.width; gx += gridSize) {
      for (double gy = 0; gy < size.height; gy += gridSize) {
        canvas.drawCircle(Offset(gx, gy), 1.0, gridPaint);
      }
    }

    // 3. Draw drifting vertical neon columns
    final dotPaint = Paint()
      ..color = patternColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    const columns = 14;
    final columnWidth = size.width / columns;

    for (int col = 0; col < columns; col++) {
      final double seed = (col * 31.415) % 1.0;
      final double speed = 0.4 + (seed * 0.5);
      final double currentY = (progress * size.height * speed + (seed * size.height)) % size.height;

      final double x = col * columnWidth + (columnWidth / 2);
      final double streakHeight = 80.0 + (seed * 120.0);
      final double startY = currentY - streakHeight;
      
      if (startY < 0) {
        _drawStreak(canvas, x, size.height + startY, streakHeight, dotPaint);
      }
      _drawStreak(canvas, x, startY, streakHeight, dotPaint);
    }
  }

  void _drawStreak(Canvas canvas, double x, double startY, double height, Paint dotPaint) {
    final double endY = startY + height;
    final rect = Rect.fromLTRB(x - 3, startY, x + 3, endY);
    
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, patternColor, Colors.transparent],
    ).createShader(rect);

    final Paint fadePaint = Paint()
      ..shader = shader
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(x, startY), Offset(x, endY), fadePaint);
    
    // Glowing neon head matching the pattern center
    canvas.drawCircle(Offset(x, startY + height * 0.5), 2.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _FallingPatternPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.patternColor != patternColor ||
        oldDelegate.bgColor != bgColor;
  }
}
