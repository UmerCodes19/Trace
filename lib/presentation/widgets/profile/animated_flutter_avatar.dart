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

class _AnimatedFlutterAvatarState extends State<AnimatedFlutterAvatar> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  
  double _bounceScale = 1.0;

  bool get _isMicro => widget.size <= 40;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: _getVibeDuration(widget.config.vibe),
    );

    if (!_isMicro) {
      _controller.repeat();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isMicro) {
      if (state == AppLifecycleState.resumed) {
        if (!_controller.isAnimating) _controller.repeat();
      } else {
        _controller.stop(); // Battery hardener
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedFlutterAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.config.vibe != widget.config.vibe) {
      _controller.duration = _getVibeDuration(widget.config.vibe);
      if (!_isMicro) {
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
      case 1: return const Duration(milliseconds: 6000);
      case 2: return const Duration(milliseconds: 2500);
      case 3: return const Duration(milliseconds: 5000);
      case 4: return const Duration(milliseconds: 4500);
      case 5: return const Duration(milliseconds: 3000);
      default: return const Duration(milliseconds: 4000);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final vibe = widget.config.vibe;

        // 1. Blinking Math
        double blinkPhase = 0.0;
        bool isBlinking = false;
        double blinkT = 0.0;

        if (vibe == 2 && t > 0.45 && t < 0.50) {
          blinkT = (t - 0.45) / 0.05;
          isBlinking = true;
        } else if (vibe == 4 && t > 0.85 && t < 0.95) {
          blinkT = ((t - 0.85) / 0.10) * 2.0;
          isBlinking = true;
        } else if (vibe != 1 || t > 0.90) {
          if (t > 0.90 && t < 0.95) {
            blinkT = (t - 0.90) / 0.05;
            isBlinking = true;
          }
        }
        
        if (isBlinking) {
          blinkPhase = math.sin(blinkT * math.pi).abs();
        }

        // 2. Sway Math
        double swayPhase = 0.0;
        if (vibe == 5) {
          swayPhase = (t < 0.5 ? t * 2 : 2 - t * 2) * 2 - 1.0;
        } else {
          swayPhase = math.sin(t * math.pi * 2);
        }

        // 3. Breathing (vertical translation)
        double floatAmp = 1.5;
        double rawBreath = math.sin(t * math.pi * 2);

        if (vibe == 1) {
          floatAmp = 1.0;
        } else if (vibe == 2) floatAmp = 2.5;
        else if (vibe == 3) floatAmp = 3.0;
        else if (vibe == 4) floatAmp = 0.8;

        if (vibe == 5) {
          const curve = Curves.easeInOutCubic;
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
              blinkPhase: blinkPhase,
              swayPhase: swayPhase,
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
      },
    );
  }
}
