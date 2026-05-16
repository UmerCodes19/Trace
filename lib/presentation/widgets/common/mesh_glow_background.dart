import 'dart:math';
import 'package:flutter/material.dart';

class MeshGlowBackground extends StatefulWidget {
  const MeshGlowBackground({super.key, required this.child});
  final Widget child;

  @override
  State<MeshGlowBackground> createState() => _MeshGlowBackgroundState();
}

class _MeshGlowBackgroundState extends State<MeshGlowBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA);
    
    return Stack(
      children: [
        Positioned.fill(child: Container(color: bgColor)),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _MeshGlowPainter(
                  animation: _controller.value,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),
        // Noise Texture Overlay
        Positioned.fill(
          child: Opacity(
            opacity: isDark ? 0.03 : 0.02,
            child: Image.network(
              'https://grainy-gradients.vercel.app/noise.svg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _MeshGlowPainter extends CustomPainter {
  final double animation;
  final bool isDark;

  _MeshGlowPainter({required this.animation, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    
    final accentColor = const Color(0xFF00A676); // Jade Primary
    final secondaryColor = isDark ? const Color(0xFF004D40) : const Color(0xFFB2DFDB);

    void drawBlob(Offset center, double radius, Color color) {
      paint.color = color.withOpacity(isDark ? 0.15 : 0.1);
      canvas.drawCircle(center, radius, paint);
    }

    // Dynamic blobs
    final t1 = animation * 2 * pi;
    final t2 = (animation + 0.3) * 2 * pi;
    final t3 = (animation + 0.6) * 2 * pi;

    drawBlob(
      Offset(
        size.width * 0.2 + sin(t1) * 50,
        size.height * 0.2 + cos(t1) * 50,
      ),
      size.width * 0.6,
      accentColor,
    );

    drawBlob(
      Offset(
        size.width * 0.8 + sin(t2) * 80,
        size.height * 0.7 + cos(t2) * 80,
      ),
      size.width * 0.7,
      secondaryColor,
    );

    drawBlob(
      Offset(
        size.width * 0.5 + cos(t3) * 100,
        size.height * 0.4 + sin(t3) * 100,
      ),
      size.width * 0.5,
      isDark ? Colors.blueGrey.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
    );
  }

  @override
  bool shouldRepaint(covariant _MeshGlowPainter oldDelegate) => true;
}
