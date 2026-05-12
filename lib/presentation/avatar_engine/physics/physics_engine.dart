import 'dart:math' as math;
import 'dart:ui';
import '../models/engine_state.dart';
import '../emotions/emotion_preset.dart';

/// Expanded Simulator handling Lagrangian dynamics, Pendulum Harmonics, and Particle Emitters.
class AvatarPhysicsEngine {
  // Primary Dynamics Vectors
  Offset headPos = Offset.zero;
  Offset headVel = Offset.zero;
  Offset eyePos = Offset.zero;
  Offset eyeVel = Offset.zero;
  double hairRot = 0.0;
  double hairVel = 0.0;

  // --- DEEP KINEMATICS (NEW) ---
  // Angular Pendulum metrics for Earring Gravity Simulation
  double earTheta = 0.0; // Angle
  double earOmega = 0.0; // Angular Velocity
  
  // Accessory Spring (Hat loose fit)
  double hatWobble = 0.0;
  double hatVel = 0.0;

  // --- MOUTH KINEMATICS (Lip-Sync & Talking Engine) ---
  double mouthStretch = 0.0;
  double mouthVel = 0.0;

  // --- PARTICLE SYSTEM ---
  final List<AvatarParticle> _particles = [];
  final math.Random _rand = math.Random();

  // Cumulative Simulation Clock
  double _totalTime = 0.0;
  Offset _externalMomentum = Offset.zero;
  double _postureShiftSeed = 0.0;

  AvatarRenderSnapshot computeNextFrame({
    required double dt,
    required EmotionMetrics emotion,
    required Offset ambientGazeTarget,
    required double leftBlink,
    required double rightBlink,
  }) {
    _totalTime += dt;
    _externalMomentum *= math.exp(-8.0 * dt);

    final double tension = emotion.physicsTension;
    final double speed = emotion.breatheSpeed;
    final double swayAmp = emotion.baseSwayAmp;

    // --- COMPOUND BREATHING ---
    final double breathBase = math.sin(_totalTime * 2.4 * speed);
    final double breathY = breathBase * 1.2 * emotion.breatheAmp;
    
    // Organic slow drift
    final double slowSwayX = math.sin(_totalTime * 0.9 * speed) * 1.4 * swayAmp;
    _postureShiftSeed += dt * 0.15;
    final double driftX = math.sin(_postureShiftSeed) * 1.0;
    final double driftY = math.cos(_postureShiftSeed * 0.7) * 0.8;

    final Offset baseTarget = Offset(slowSwayX + driftX, breathY + driftY) + _externalMomentum;

    // --- 1. HEAD SOLVER ---
    final Offset headForce = (baseTarget - headPos) * (24.0 * tension) - (headVel * (10.0 * math.sqrt(tension)));
    headVel += headForce * dt;
    headPos += headVel * dt;

    // --- 2. EYE FIXATION INERTIA ---
    final Offset eyeTarget = (headVel * -0.075) + (ambientGazeTarget * emotion.gazeEntropy);
    final Offset eyeForce = (eyeTarget - eyePos) * (35.0 * tension) - (eyeVel * 16.0);
    eyeVel += eyeForce * dt;
    eyePos += eyeVel * dt;

    // --- 3. HAIR & HAT WOBBLE (Loose Physics) ---
    final double hairForce = ((headVel.dx * -0.06) - hairRot) * (16.0 * tension) - (hairVel * 6.5);
    hairVel += hairForce * dt;
    hairRot += hairVel * dt;

    // Hat wobbles less stiffly than hair
    final double hatForce = ((headVel.dx * -0.03) - hatWobble) * (12.0 * tension) - (hatVel * 5.0);
    hatVel += hatForce * dt;
    hatWobble += hatVel * dt;

    // --- 4. EARRING PENDULUM HARMONICS ---
    // Gravity pull toward resting 0 (sin theta) + horizontal acceleration nudge
    final double accelX = headVel.dx * 1.5; // lateral drive
    final double gravity = 15.0; // Constant down force
    final double earAlpha = -gravity * math.sin(earTheta) - accelX - (earOmega * 4.0); // Damped torque
    earOmega += earAlpha * dt;
    earTheta += earOmega * dt;
    earTheta = earTheta.clamp(-math.pi / 4, math.pi / 4); // Structural collision limit

    // --- 5. MOUTH MANDIBLE ELASTIC SOLVER ---
    // Natural bounce-back to base emotional bias, but allow rapid-response oscillations 
    final double mouthTarget = emotion.expressionBias;
    final double mouthForce = (mouthTarget - mouthStretch) * (30.0 * tension) - (mouthVel * 8.0);
    mouthVel += mouthForce * dt;
    mouthStretch += mouthVel * dt;

    // --- 6. PARTICLE QUEUE STEP ---
    _stepParticles(dt);

    return AvatarRenderSnapshot(
      headOffset: headPos,
      gazeOffset: eyePos,
      hairSway: hairRot,
      leftBlink: leftBlink,
      rightBlink: rightBlink,
      mouthStretch: mouthStretch,
      expressionScale: 1.0 + (breathY * 0.01),
      // --- NEW VECTORS ---
      earringAngle: earTheta,
      hatWobble: hatWobble,
      breathExpansion: breathBase.clamp(-0.5, 1.0), // Flatten exhale slightly
      moodColorIntensity: tension / 2.5, // Normalized excitement scaler
      activeParticles: List<AvatarParticle>.from(_particles),
    );
  }

  void _stepParticles(double dt) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      final double nextLife = p.life - dt * 1.2;
      if (nextLife <= 0) {
        _particles.removeAt(i);
      } else {
        _particles[i] = AvatarParticle(
          position: p.position + p.velocity * dt,
          velocity: p.velocity + const Offset(0, -8.0) * dt, // slight float gravity
          life: nextLife,
          type: p.type,
          rotation: p.rotation + dt * 2.0,
        );
      }
    }
  }

  void emitBurst(int count, int type) {
    for (int i = 0; i < count; i++) {
      _particles.add(AvatarParticle(
        position: Offset((_rand.nextDouble() - 0.5) * 40, -10.0),
        velocity: Offset((_rand.nextDouble() - 0.5) * 20.0, (_rand.nextDouble() - 1.0) * 30.0),
        life: 1.0,
        type: type,
        rotation: _rand.nextDouble() * math.pi,
      ));
    }
  }

  void applyForce(Offset force) {
    _externalMomentum += force;
    headVel += force * 0.5;
    hairVel += force.dx * 0.1;
    hatVel += force.dx * 0.08;
    earOmega += force.dx * 0.5; // Transfer impact directly to pendulum spin
  }
  
  void stabilize() {
    headVel = Offset.zero;
    eyeVel = Offset.zero;
    hairVel = 0.0;
    earOmega = 0.0;
    earTheta = 0.0;
    hatVel = 0.0;
    hatWobble = 0.0;
    mouthStretch = 0.0;
    mouthVel = 0.0;
    _externalMomentum = Offset.zero;
    _particles.clear();
  }

  void injectMouthForce(double force) {
     // Directly acceleration impulse applied to mouth velocity
     mouthVel += force * 15.0; 
  }
}
