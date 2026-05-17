import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import '../core/avatar_engine.dart';
import '../emotions/emotion_preset.dart';
import 'music_state.dart';

final musicSyncProvider = NotifierProvider<MusicSyncNotifier, AvatarMusicState>(() => MusicSyncNotifier());

class MusicSyncNotifier extends Notifier<AvatarMusicState> {
  late AudioPlayer _player;
  final ValueNotifier<double> liveEnergyNotifier = ValueNotifier(0.0);
  
  Waveform? _currentWaveform;
  Timer? _ticker;
  
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _playStateSub;

  double _rollingAverage = 0.15; // 📈 Dynamic moving low-pass average
  double _prevRatio = 0.0; // 💾 UNCLAMPED high-precision memory
  double _longPeak = 0.5; // 🏔️ Long-term automatic gain normalization peak
  DateTime _lastBeat = DateTime.now();

  @override
  AvatarMusicState build() {
    _initSession();
    _player = AudioPlayer();
    _bindListeners();
    
    ref.onDispose(() {
      _cancelListeners();
      _player.dispose();
    });
    
    return AvatarMusicState();
  }

  void _cancelListeners() {
    _posSub?.cancel();
    _durSub?.cancel();
    _playStateSub?.cancel();
    _ticker?.cancel();
    _ticker = null;
  }

  void _bindListeners() {
    _cancelListeners();
    _posSub = _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _durSub = _player.durationStream.listen((dur) {
      if (dur != null) state = state.copyWith(duration: dur);
    });
    _playStateSub = _player.playerStateStream.listen((pState) {
      final playing = pState.playing;
      if (pState.processingState == ProcessingState.completed) {
        stop();
      } else {
        state = state.copyWith(isPlaying: playing);
      }
    });
    
    // 🎯 HIGH-PRECISION SIMULATION TICKER (Replaces Visualizer EventStream)
    // Fires 30 times per second to sample pre-calculated waveform amplitude.
    _ticker = Timer.periodic(const Duration(milliseconds: 33), (_) => _onTick());
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> playFile(String filePath) async {
    try {
      debugPrint('🔄 OFFLINE WAVE ANALYSIS: Booting secure processing engine...');
      
      // 1. Kill old instance completely to prevent memory crossover
      await _player.stop().catchError((_) {});
      await _player.dispose().catchError((_) {});
      
      _rollingAverage = 0.15;
      _prevRatio = 0.0;
      _longPeak = 0.5;
      _currentWaveform = null;

      // 🌟 CREATE FRESH NEW PLAYER FROM SCRATCH
      _player = AudioPlayer();
      _bindListeners();

      final cleanName = p.basename(filePath);
      state = state.copyWith(
        fileName: cleanName, 
        isPlaying: false, // Don't state 'playing' until fully prepped!
        isAnalyzing: true, // 🚀 ALERT UI: Show skeleton loader!
        liveEnergy: 0.0
      );

      debugPrint('📊 WAVE STEP 1: Checking Persistence Cache / Analyzing...');
      
      final tempDir = await getTemporaryDirectory();
      // 🛡️ SECURE CACHING: Deterministic file storage preventing repeat analysis!
      final int cacheId = filePath.hashCode.abs();
      final waveFile = File('${tempDir.path}/wave_cache_$cacheId.wave');
      
      bool analysisRequired = true;
      if (await waveFile.exists()) {
        final int sz = await waveFile.length();
        if (sz > 100) { // Valid wave header length
          try {
             _currentWaveform = await JustWaveform.parse(waveFile);
             debugPrint('⚡ FLASH CACHE HIT: Instant waveform loaded!');
             analysisRequired = false;
          } catch (e) {
             debugPrint('⚠️ Cache corruption detected, forcing re-analysis.');
          }
        }
      }

      // Fallback to synchronous awaited extraction ONLY if cache missing
      if (analysisRequired) {
        final progressStream = JustWaveform.extract(
          audioInFile: File(filePath),
          waveOutFile: waveFile,
          zoom: const WaveformZoom.pixelsPerSecond(50),
        );

        await for (final progress in progressStream) {
          if (progress.waveform != null) {
            _currentWaveform = progress.waveform;
            debugPrint('✅ WAVE EXTRACTION COMPLETE! Total Frames=${_currentWaveform?.length}');
            break;
          }
        }
      }

      // 🚀 UNLOCK UI: Analysis Done!
      state = state.copyWith(isAnalyzing: false);

      debugPrint('📊 WAVE STEP 2: Initializing File Audio Engine...');
      await _player.setFilePath(filePath);
      
      debugPrint('📊 WAVE STEP 3: Commencing Perfectly-Synced Secure Audio...');
      state = state.copyWith(isPlaying: true);
      _player.play(); 
      
    } catch (e) {
      debugPrint('🔒 Wave Analysis Error: $e');
    }
  }

  void _onTick() {
    final waveform = _currentWaveform;
    if (!_player.playing || waveform == null) return;

    final Duration currentPos = _player.position;
    
    // 🔍 DERIVE PRECISE INTENSITY SLICE FROM PRE-LOADED WAVEFORM
    final double pixelIndex = waveform.positionToPixel(currentPos);
    final int idx = pixelIndex.toInt();
    
    // Fetch bipolar sample boundaries
    final int rawMax = waveform.getPixelMax(idx);
    final int rawMin = waveform.getPixelMin(idx);
    
    // Transform to absolute unscaled energy
    final double rawEnergy = (rawMax.abs() + rawMin.abs()) / 2.0;
    
    // Correctly interpret source resolution (16-bit vs 8-bit)
    final double scale = waveform.flags == 0 ? 32767.0 : 127.0;
    
    final double rawRatio = rawEnergy / scale; 
    
    // 🏔️ 1. AUTO-GAIN TRACKER (Tracks long-term peak to prevent wall-of-sound clipping!)
    _longPeak = math.max(_longPeak * 0.998, rawRatio); // Gradual decay to allow downward adaptation
    _longPeak = math.max(_longPeak, 0.1); // Safety floor
    
    // Balance signal based on real-time adaptive range
    final double adaptiveEnergy = (rawRatio / _longPeak).clamp(0.0, 1.0);
    
    // 📊 2. SIGNAL COMPRESSION (Standard Audio Root-Curve gives rich headroom instead of flatline!)
    final double compressedEnergy = math.sqrt(adaptiveEnergy);
    
    // 💡 FEED COMPRESSED MOUTH & UI REFRESH
    liveEnergyNotifier.value = compressedEnergy;
    ref.read(avatarEngineProvider.notifier).pulseMouth(compressedEnergy * 0.82);

    // 🧠 3. DYNAMIC CONTRAST CALCULUS (The Multi-Metric Solver)
    // Update dynamic low-pass average to track local song density (wall-of-lyrics vs silence)
    _rollingAverage += (rawRatio - _rollingAverage) * 0.12; // High-tempo dynamic tracking
    
    // Calculate local rate-of-change transient WITHOUT clamping!
    final double rawContrast = (rawRatio - _prevRatio);
    _prevRatio = rawRatio; // Save unclamped high-precision state

    // 🎯 4. ADAPTIVE THRESHOLD (Relative contrast to local average!)
    // As song gets louder, threshold rises. In quietness, it becomes hyper-sensitive!
    final double adaptiveThreshold = math.max(0.006, _rollingAverage * 0.16);
    
    // Triggers if local spike breaks adaptive threshold OR sudden absolute impact
    final bool isPercussiveHit = (rawContrast > adaptiveThreshold && rawContrast > 0.003);

    final now = DateTime.now();
    final msSinceLast = now.difference(_lastBeat).inMilliseconds;
    
    if (msSinceLast > 180 && (isPercussiveHit || rawContrast > 0.09)) {
      _lastBeat = now;
      // Deliver kinetic impact scaled perfectly to long-term peak!
      final double hitMagnitude = (rawContrast / _longPeak).clamp(0.1, 1.5) * 2.2;
      _injectPhysicsBump(hitMagnitude);
    }
  }

  void _injectPhysicsBump(double rawIntensity) {
    final double scaledIntensity = rawIntensity * state.sensitivity;
    final engine = ref.read(avatarEngineProvider.notifier);
    
    // 🚀 HIGH-FIDELITY HEAD BOB: Massive vertical impulse downwards driven by real beat math!
    final double lateral = (math.Random().nextDouble() - 0.5) * 10.0 * scaledIntensity;
    final double verticalBob = -18.0 - (22.0 * scaledIntensity); // Intense downward slam recoil
    
    engine.applyDirectForce(Offset(lateral, verticalBob));
    
    // 🥳 OCCASIONAL EXCITEMENT: If it's a HUGE heavy drop spike!
    if (scaledIntensity > 1.3) { 
       engine.triggerReaction(AvatarEmotion.excited, duration: const Duration(milliseconds: 700));
    }
  }

  void setSensitivity(double val) {
    state = state.copyWith(sensitivity: val.clamp(0.1, 3.0));
  }

  void seek(Duration pos) {
    _player.seek(pos);
  }

  void pauseResume() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void stop() {
    _player.stop();
    _currentWaveform = null;
    state = AvatarMusicState(sensitivity: state.sensitivity); // Reset, keep sensitivity
  }
}
