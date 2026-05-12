import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/engine_state.dart';
import '../emotions/emotion_preset.dart';
import '../physics/physics_engine.dart';

final avatarEngineProvider = NotifierProvider<AvatarEngineNotifier, AvatarRenderSnapshot>(
  () => AvatarEngineNotifier(),
);

class AvatarEngineNotifier extends Notifier<AvatarRenderSnapshot> {
  final AvatarPhysicsEngine _physics = AvatarPhysicsEngine();
  late final Ticker _ticker;
  
  Duration _lastElapsed = Duration.zero;
  final math.Random _rand = math.Random();

  AvatarEmotion _currentEmotion = AvatarEmotion.idle;
  EmotionMetrics _blendedMetrics = EmotionPreset.get(AvatarEmotion.idle);
  Timer? _emotionOverrideTimer;
  Offset _ambientGaze = Offset.zero;
  double _gazeTimer = 0.0;

  double _leftBlinkVal = 0.0;
  double _rightBlinkVal = 0.0;
  double _blinkCycleTimer = 0.0;
  bool _isBlinking = false;

  // --- THROTTLES & LIFECYCLES ---
  double _hapticThrottle = 0.0;

  @override
  AvatarRenderSnapshot build() {
    _ticker = Ticker(_onTick);
    _ticker.start();
    ref.onDispose(() { _ticker.dispose(); _emotionOverrideTimer?.cancel(); });
    return AvatarRenderSnapshot.idle;
  }

  void _onTick(Duration elapsed) {
    final double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt > 0.1) return;

    // Decay throttles
    if (_hapticThrottle > 0) _hapticThrottle -= dt;

    final targetMetrics = EmotionPreset.get(_currentEmotion);
    _blendedMetrics = EmotionMetrics.lerp(_blendedMetrics, targetMetrics, 5.0 * dt);

    _gazeTimer -= dt;
    if (_gazeTimer <= 0) {
      final double angle = _rand.nextDouble() * 2 * math.pi;
      final double dist = _rand.nextDouble() * 6.0;
      _ambientGaze = Offset(math.cos(angle) * dist, math.sin(angle) * dist * 0.5);
      _gazeTimer = 1.5 + (_rand.nextDouble() * 4.0) / math.max(0.1, _blendedMetrics.gazeEntropy);
    }

    _updateBlinkPhysiology(dt);

    final snapshot = _physics.computeNextFrame(
      dt: dt,
      emotion: _blendedMetrics,
      ambientGazeTarget: _ambientGaze,
      leftBlink: _leftBlinkVal,
      rightBlink: _rightBlinkVal,
    );

    // Check physical resonance for Haptic Heartbeat/Recoil Sync
    if (_blendedMetrics.physicsTension > 2.0 && _physics.headVel.dy.abs() > 30.0 && _hapticThrottle <= 0) {
      HapticFeedback.selectionClick();
      _hapticThrottle = 0.3; // prevent buzz storm
    }

    state = snapshot;
  }

  void _updateBlinkPhysiology(double dt) {
    if (_isBlinking) {
      _blinkCycleTimer += dt * 12.0;
      final double baseBlink = math.sin(_blinkCycleTimer.clamp(0.0, math.pi));
      _leftBlinkVal = baseBlink;
      _rightBlinkVal = math.sin((_blinkCycleTimer - 0.2).clamp(0.0, math.pi));
      if (_blinkCycleTimer >= math.pi + 0.2) {
        _isBlinking = false;
        _leftBlinkVal = 0.0; _rightBlinkVal = 0.0;
        _blinkCycleTimer = _blendedMetrics.blinkFrequencySec * (0.5 + _rand.nextDouble());
      }
    } else {
      _blinkCycleTimer -= dt;
      if (_blinkCycleTimer <= 0) { _isBlinking = true; _blinkCycleTimer = 0.0; }
    }
  }

  void setBaseEmotion(AvatarEmotion emotion) {
    _currentEmotion = emotion;
  }

  void triggerReaction(AvatarEmotion reaction, {Duration duration = const Duration(seconds: 3)}) {
    final previous = _currentEmotion;
    _currentEmotion = reaction;
    
    // Haptic Blast on initial recoil
    HapticFeedback.mediumImpact();

    // Physical Recoil + Immediate Mouth Opening (Gasp/Giggle)
    _physics.applyForce(Offset((_rand.nextDouble() - 0.5) * 20.0, -25.0));
    _physics.injectMouthForce(2.5); // Sudden energetic mouth bounce on tap!
    
    // Particle Burst injection matching emotion signature
    int type = 0; // default sparkle
    if (reaction == AvatarEmotion.sleepy) type = 1; // Zzz
    if (reaction == AvatarEmotion.excited) type = 2; // Confetti
    _physics.emitBurst(8, type);

    _emotionOverrideTimer?.cancel();
    _emotionOverrideTimer = Timer(duration, () {
      if (_currentEmotion == reaction) _currentEmotion = previous;
    });
  }

  /// Facilitates injection of RAW physical force vectors (e.g. from Audio Bass Peaks)
  void applyDirectForce(Offset force) {
    _physics.applyForce(force);
  }

  /// Directly injects kinematic energy specifically into the mandible actuator (mouth).
  /// Ideal for lip-sync visualization and real-time audio energy injection!
  void pulseMouth(double intensity) {
    _physics.injectMouthForce(intensity);
    _physics.injectMusicPulse(intensity); // 🎶 Pipe explicitly to visuals ONLY on music sync!
  }

  void registerScrollImpact(double velocityY) {
    final double nudgeX = (velocityY / 700.0).clamp(-18.0, 18.0);
    _physics.applyForce(Offset(nudgeX, velocityY.abs() * -0.006));
  }

  void updateAppFocus(bool hasFocus) {
    setBaseEmotion(hasFocus ? AvatarEmotion.focused : AvatarEmotion.idle);
  }
}
