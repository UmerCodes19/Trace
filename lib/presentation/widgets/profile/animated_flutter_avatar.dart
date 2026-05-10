import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'flutter_avatar.dart';

class AnimatedFlutterAvatar extends StatefulWidget {
  final AvatarConfig config;
  final double size;

  const AnimatedFlutterAvatar({
    super.key,
    required this.config,
    this.size = 100.0,
  });

  @override
  State<AnimatedFlutterAvatar> createState() => _AnimatedFlutterAvatarState();
}

class _AnimatedFlutterAvatarState extends State<AnimatedFlutterAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // State variables for animation values
  double _blinkPhase = 0.0;
  double _swayPhase = 0.0;
  double _bounceScale = 1.0;

  // We only run continuous animations if the avatar is large enough
  bool get _isMicro => widget.size <= 40;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _getVibeDuration(widget.config.vibe),
    );

    if (!_isMicro) {
      _controller.repeat();
      _controller.addListener(_updateAnimations);
    }
  }

  @override
  void didUpdateWidget(AnimatedFlutterAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update duration if vibe changes
    if (oldWidget.config.vibe != widget.config.vibe) {
      _controller.duration = _getVibeDuration(widget.config.vibe);
      if (!_isMicro && _controller.isAnimating) {
        _controller.repeat();
      }
    }

    if (oldWidget.size > 40 && widget.size <= 40) {
      _controller.stop();
    } else if (oldWidget.size <= 40 && widget.size > 40) {
      _controller.repeat();
    }
  }

  Duration _getVibeDuration(int vibe) {
    switch (vibe) {
      case 1: return const Duration(milliseconds: 6000); // Calm: Very slow
      case 2: return const Duration(milliseconds: 2500); // Chaotic: Fast
      case 3: return const Duration(milliseconds: 5000); // Dreamcore: Slow & floaty
      case 4: return const Duration(milliseconds: 4500); // Night Owl: Smooth
      case 5: return const Duration(milliseconds: 3000); // Techwear: Sharp/Fast
      default: return const Duration(milliseconds: 4000); // Balanced
    }
  }

  void _updateAnimations() {
    final t = _controller.value;
    final vibe = widget.config.vibe;
    
    // 1. Blinking
    // Calm (1) blinks less often. Chaotic (2) blinks more frequently.
    // Night Owl (4) sometimes does a rapid double blink.
    bool isBlinking = false;
    double blinkT = 0.0;

    if (vibe == 2 && t > 0.45 && t < 0.50) {
      // Chaotic: extra mid-cycle blink
      blinkT = (t - 0.45) / 0.05;
      isBlinking = true;
    } else if (vibe == 4 && t > 0.85 && t < 0.95) {
      // Night Owl: double blink
      blinkT = ((t - 0.85) / 0.10) * 2.0; // goes 0->2
      isBlinking = true;
    } else if (vibe != 1 || t > 0.90) { // Calm skips some cycles, standard blink otherwise
      if (t > 0.90 && t < 0.95) {
        blinkT = (t - 0.90) / 0.05;
        isBlinking = true;
      }
    }

    if (isBlinking) {
      _blinkPhase = math.sin(blinkT * math.pi).abs();
    } else {
      _blinkPhase = 0.0;
    }

    // 2. Sway
    if (vibe == 5) {
      // Techwear: linear, slight robotic sway
      _swayPhase = (t < 0.5 ? t * 2 : 2 - t * 2) * 2 - 1.0;
    } else {
      _swayPhase = math.sin(t * math.pi * 2);
    }

    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isMicro) return;
    setState(() => _bounceScale = 0.95);
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isMicro) return;
    setState(() => _bounceScale = 1.0);
  }

  void _handleTapCancel() {
    if (_isMicro) return;
    setState(() => _bounceScale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    // 3. Breathing (vertical translation)
    final vibe = widget.config.vibe;
    double floatAmp = 1.5;
    double rawBreath = math.sin(_controller.value * math.pi * 2);

    if (vibe == 1) floatAmp = 1.0;      // Calm
    else if (vibe == 2) floatAmp = 2.5; // Chaotic
    else if (vibe == 3) floatAmp = 3.0; // Dreamcore
    else if (vibe == 4) floatAmp = 0.8; // Night Owl

    if (vibe == 5) {
      // Techwear: sharper, stepped curve
      final curve = Curves.easeInOutCubic;
      final t = _controller.value;
      rawBreath = curve.transform(t < 0.5 ? t * 2 : 2 - (t * 2)) * 2 - 1;
    }

    final double breathY = _isMicro ? 0.0 : rawBreath * floatAmp;

    Widget avatar = SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: AvatarPainter(
          config: widget.config,
          renderSize: widget.size,
          blinkPhase: _blinkPhase,
          swayPhase: _swayPhase,
        ),
      ),
    );

    if (!_isMicro) {
      avatar = Transform.translate(
        offset: Offset(0, breathY),
        child: AnimatedScale(
          scale: _bounceScale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: avatar,
          ),
        ),
      );
    }

    return avatar;
  }
}
