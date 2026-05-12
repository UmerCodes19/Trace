import 'dart:ui';

/// Immutable definition of a lightweight temporary visual particle effect.
class AvatarParticle {
  final Offset position;
  final Offset velocity;
  final double life; // 1.0 -> 0.0
  final int type; // 0: Sparkle, 1: Zzz, 2: Confetti
  final double rotation;

  const AvatarParticle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.type,
    this.rotation = 0.0,
  });
}

/// Expanded frozen payload housing the expanded Feature-Set physics metrics.
class AvatarRenderSnapshot {
  final Offset headOffset;
  final Offset gazeOffset;
  final double hairSway;
  final double leftBlink;
  final double rightBlink;
  final double mouthStretch;
  final double expressionScale;
  final double emotionBias; // Bridge scalar driving dynamic path morphing 
  
  // --- DEEP EXPANSION KINEMATICS ---
  final double earringAngle;
  final double hatWobble;
  final double breathExpansion; // Decoupled scalar strictly for outfit inflation
  
  // --- ATMOSPHERIC LAYERS ---
  final double moodColorIntensity; 
  final List<AvatarParticle> activeParticles;
  
  // --- WAVEFORM VISUALS ---
  final List<double> waveSamples; // Rolling historic samples for background visualizer
  final double waveFade; // 0.0 to 1.0 for in/out transparency

  const AvatarRenderSnapshot({
    this.headOffset = Offset.zero,
    this.gazeOffset = Offset.zero,
    this.hairSway = 0.0,
    this.leftBlink = 0.0,
    this.rightBlink = 0.0,
    this.mouthStretch = 0.0,
    this.expressionScale = 1.0,
    this.emotionBias = 0.0,
    this.earringAngle = 0.0,
    this.hatWobble = 0.0,
    this.breathExpansion = 0.0,
    this.moodColorIntensity = 0.0,
    this.activeParticles = const [],
    this.waveSamples = const [],
    this.waveFade = 0.0,
  });

  static const AvatarRenderSnapshot idle = AvatarRenderSnapshot();

  AvatarRenderSnapshot copyWith({
    Offset? headOffset,
    Offset? gazeOffset,
    double? hairSway,
    double? leftBlink,
    double? rightBlink,
    double? mouthStretch,
    double? expressionScale,
    double? emotionBias,
    double? earringAngle,
    double? hatWobble,
    double? breathExpansion,
    double? moodColorIntensity,
    List<AvatarParticle>? activeParticles,
    List<double>? waveSamples,
    double? waveFade,
  }) {
    return AvatarRenderSnapshot(
      headOffset: headOffset ?? this.headOffset,
      gazeOffset: gazeOffset ?? this.gazeOffset,
      hairSway: hairSway ?? this.hairSway,
      leftBlink: leftBlink ?? this.leftBlink,
      rightBlink: rightBlink ?? this.rightBlink,
      mouthStretch: mouthStretch ?? this.mouthStretch,
      expressionScale: expressionScale ?? this.expressionScale,
      emotionBias: emotionBias ?? this.emotionBias,
      earringAngle: earringAngle ?? this.earringAngle,
      hatWobble: hatWobble ?? this.hatWobble,
      breathExpansion: breathExpansion ?? this.breathExpansion,
      moodColorIntensity: moodColorIntensity ?? this.moodColorIntensity,
      activeParticles: activeParticles ?? this.activeParticles,
      waveSamples: waveSamples ?? this.waveSamples,
      waveFade: waveFade ?? this.waveFade,
    );
  }
}
