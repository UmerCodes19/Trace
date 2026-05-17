
/// Comprehensive emotional taxonomy powering dynamic blend tree states.
enum AvatarEmotion {
  idle,
  focused,
  curious,
  excited,
  sleepy,
  confused,
  happy,
  alert,
}

/// Quantitative physical matrix driving variable-scale rendering transforms per mood.
class EmotionMetrics {
  final double physicsTension;
  final double gazeEntropy;
  final double blinkFrequencySec;
  final double defaultScale;
  
  // Physics Engine Parameter Extensions
  final double breatheSpeed;
  final double breatheAmp;
  final double baseSwayAmp;
  final double expressionBias;

  const EmotionMetrics({
    required this.physicsTension,
    required this.gazeEntropy,
    required this.blinkFrequencySec,
    required this.breatheSpeed,
    required this.breatheAmp,
    required this.baseSwayAmp,
    required this.expressionBias,
    this.defaultScale = 1.0,
  });

  static EmotionMetrics lerp(EmotionMetrics a, EmotionMetrics b, double t) {
    double l(double x, double y) => x + (y - x) * t.clamp(0.0, 1.0);
    return EmotionMetrics(
      physicsTension: l(a.physicsTension, b.physicsTension),
      gazeEntropy: l(a.gazeEntropy, b.gazeEntropy),
      blinkFrequencySec: l(a.blinkFrequencySec, b.blinkFrequencySec),
      breatheSpeed: l(a.breatheSpeed, b.breatheSpeed),
      breatheAmp: l(a.breatheAmp, b.breatheAmp),
      baseSwayAmp: l(a.baseSwayAmp, b.baseSwayAmp),
      expressionBias: l(a.expressionBias, b.expressionBias),
      defaultScale: l(a.defaultScale, b.defaultScale),
    );
  }
}

/// Central lookup table for high-definition emotional physics constants.
class EmotionPreset {
  static final Map<AvatarEmotion, EmotionMetrics> _presets = {
    AvatarEmotion.idle: const EmotionMetrics(
      physicsTension: 1.0,
      gazeEntropy: 1.0,
      blinkFrequencySec: 4.0,
      breatheSpeed: 1.0,
      breatheAmp: 1.0,
      baseSwayAmp: 1.0,
      expressionBias: 0.0,
    ),
    AvatarEmotion.focused: const EmotionMetrics(
      physicsTension: 1.8,
      gazeEntropy: 0.2,
      blinkFrequencySec: 8.0,
      breatheSpeed: 0.7,
      breatheAmp: 0.5,
      baseSwayAmp: 0.4,
      expressionBias: 0.3,
      defaultScale: 1.02,
    ),
    AvatarEmotion.curious: const EmotionMetrics(
      physicsTension: 1.4,
      gazeEntropy: 2.5,
      blinkFrequencySec: 3.0,
      breatheSpeed: 1.3,
      breatheAmp: 1.2,
      baseSwayAmp: 1.4,
      expressionBias: 1.0,
      defaultScale: 1.04,
    ),
    AvatarEmotion.excited: const EmotionMetrics(
      physicsTension: 3.5,
      gazeEntropy: 4.0,
      blinkFrequencySec: 1.5,
      breatheSpeed: 2.5,
      breatheAmp: 2.0,
      baseSwayAmp: 2.5,
      expressionBias: 2.0,
      defaultScale: 1.1,
    ),
    AvatarEmotion.sleepy: const EmotionMetrics(
      physicsTension: 0.3,
      gazeEntropy: 0.5,
      blinkFrequencySec: 2.0,
      breatheSpeed: 0.4,
      breatheAmp: 0.6,
      baseSwayAmp: 1.2, // slower wider sway
      expressionBias: -0.5,
      defaultScale: 0.98,
    ),
    AvatarEmotion.confused: const EmotionMetrics(
      physicsTension: 1.2,
      gazeEntropy: 3.5,
      blinkFrequencySec: 3.0,
      breatheSpeed: 1.1,
      breatheAmp: 1.1,
      baseSwayAmp: 1.6,
      expressionBias: 0.7,
    ),
    AvatarEmotion.happy: const EmotionMetrics(
      physicsTension: 1.5,
      gazeEntropy: 1.5,
      blinkFrequencySec: 3.5,
      breatheSpeed: 1.4,
      breatheAmp: 1.3,
      baseSwayAmp: 1.3,
      expressionBias: 1.5,
      defaultScale: 1.05,
    ),
    AvatarEmotion.alert: const EmotionMetrics(
      physicsTension: 2.5,
      gazeEntropy: 3.0,
      blinkFrequencySec: 6.0,
      breatheSpeed: 2.0,
      breatheAmp: 1.6,
      baseSwayAmp: 1.8,
      expressionBias: 0.8,
      defaultScale: 1.08,
    ),
  };

  static EmotionMetrics get(AvatarEmotion e) => _presets[e] ?? _presets[AvatarEmotion.idle]!;
}
