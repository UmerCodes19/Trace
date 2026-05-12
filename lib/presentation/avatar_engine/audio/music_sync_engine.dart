import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import '../core/avatar_engine.dart';
import '../emotions/emotion_preset.dart';
import 'music_state.dart';

final musicSyncProvider = NotifierProvider<MusicSyncNotifier, AvatarMusicState>(() => MusicSyncNotifier());

class MusicSyncNotifier extends Notifier<AvatarMusicState> {
  late AudioPlayer _player;
  static const _controlChannel = MethodChannel('pk.edu.bahria.lostfound/visualizer_control');
  static const _eventChannel = EventChannel('pk.edu.bahria.lostfound/visualizer_events');
  
  final ValueNotifier<double> liveEnergyNotifier = ValueNotifier(0.0);
  
  StreamSubscription? _visualizerSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _playStateSub;

  double _rollingPeak = 0.0;
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
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> playFile(String filePath) async {
    // 1. MUST REQUEST RUNTIME MICROPHONE PERMISSION FOR VISUALIZER
    final perm = await Permission.microphone.request();
    if (!perm.isGranted) {
      debugPrint("⚠️ Microphone permission denied. Visualization engine won't capture data.");
    }

    try {
      debugPrint('🔄 RECYCLING ENGINE: Disposing old instance for pristine reboot...');
      await _player.stop().catchError((_) {});
      await _player.dispose().catchError((_) {});
      
      // ⚠️ CRITICAL BUG FIX: MUST reset debug flag so the second run attempts to latch!
      _hasPrintedDebug = false;
      _rollingPeak = 0.0;
      _debugCount = 0;

      // 🌟 CREATE FRESH NEW PLAYER FROM SCRATCH
      _player = AudioPlayer();
      _bindListeners();

      final cleanName = p.basename(filePath);
      state = state.copyWith(fileName: cleanName, isPlaying: true, liveEnergy: 0.0);

      debugPrint('📊 SYNC STEP 2: Loading File into NEW Engine...');
      await _player.setFilePath(filePath);
      
      debugPrint('📊 SYNC STEP 3: Dispatching Play command on NEW Engine...');
      // CRITICAL FIX: Do NOT await play(), as it blocks execution until track finishes!
      _player.play(); 

      debugPrint('📊 SYNC STEP 4: Starting smart reboot system...');
      // --- 🚀 HIGH-VELOCITY SMART REBOOT SYSTEM ---
      // Explicitly cycle driver binding dynamically until first bytes hit, ensuring physical devices catch.
      for (int attempt = 1; attempt <= 4; attempt++) {
         await Future.delayed(Duration(milliseconds: 600 + (attempt * 300)));
         if (_hasPrintedDebug) break; // ✅ WE HAVE BYTES! DO NOT INTERRUPT.
         
         debugPrint('⚡ SYSTEM DRIVER LINK: Executing latch attempt #$attempt...');
         await _attemptVisualizerLatch();
      }
    } catch (e) {
      debugPrint('Playback Init Error: $e');
    }
  }

  Future<void> _attemptVisualizerLatch() async {
    if (kIsWeb) return;
    final int? sessionId = _player.androidAudioSessionId;
    if (sessionId != null) {
      final bool ok = await _controlChannel.invokeMethod<bool>('startVisualizer', {'sessionId': sessionId}) ?? false;
      if (ok) {
        _startListening();
      } else {
        debugPrint('🔊 SYSTEM DEBUG: Latch failure reported by native bridge.');
      }
    } else {
      debugPrint('🔊 SYSTEM DEBUG: No active Session ID yet.');
    }
  }

  bool _hasPrintedDebug = false;
  void _startListening() {
    _visualizerSub?.cancel();
    _hasPrintedDebug = false;
    debugPrint('🔊 SYSTEM DEBUG: STARTING broadcast stream listener on Dart Side.');
    _visualizerSub = _eventChannel.receiveBroadcastStream().listen((dynamic data) {
      if (!_hasPrintedDebug) {
         debugPrint('🚀 CRITICAL SUCCESS: First binary FFT packet arrived in Dart from Kotlin! Size = ${data is Uint8List ? (data as Uint8List).length : "NULL"}');
         _hasPrintedDebug = true;
      }
      if (data is Uint8List) {
        _processFft(data);
      }
    });
  }

  int _debugCount = 0;
  void _processFft(Uint8List data) {
    if (data.isEmpty) return;
    
    double totalMagnitude = 0.0;
    // Capture all frequencies, not just the first 32! 
    // Let's look at the lower half of frequencies which contain most bass/power
    int limit = math.min(data.length, 128); 
    int pairs = 0;

    for (int i = 2; i < limit - 1; i += 2) {
      // Correctly interpret as SIGNED bytes!
      final int rInt = data[i].toSigned(8);
      final int imInt = data[i + 1].toSigned(8);
      
      final double magnitude = math.sqrt((rInt * rInt) + (imInt * imInt)).toDouble();
      totalMagnitude += magnitude;
      pairs++;
    }

    final double avgEnergy = pairs > 0 ? (totalMagnitude / pairs) : 0.0;
    _rollingPeak = math.max(_rollingPeak * 0.98, avgEnergy);
    
    // Periodic Diagnostic to help fix if it goes totally dead again
    _debugCount++;
    if (_debugCount % 100 == 0) {
       debugPrint('🔊 ENERGY CHECK: avg=$avgEnergy, peak=$_rollingPeak, data0=${data[0]}');
    }

    // Normalize for live UI bar - Multiply by a boost to make sure it is visible!
    final double normalizedEnergy = (avgEnergy / 50.0).clamp(0.0, 1.0);

    // 🚀 PERFORMANCE BOOST: Update specialized notifier INSTEAD of general app state!
    // This isolates the redraw only to the spectrum bar widget, keeping app lag-free!
    liveEnergyNotifier.value = normalizedEnergy;

    // 🎵 LIP-SYNC INJECTION: Directly pump energy into mouth physics real-time!
    // This causes the mouth to naturally vibrate, sync and pulse to the beat!
    ref.read(avatarEngineProvider.notifier).pulseMouth(normalizedEnergy * 0.8);

    final now = DateTime.now();
    final msSinceLast = now.difference(_lastBeat).inMilliseconds;

    // LOOSEN beat trigger thresholds slightly to favor sensitivity!
    if (msSinceLast > 160 && avgEnergy > 6.0 && avgEnergy > _rollingPeak * 0.75) {
      _lastBeat = now;
      // Use normalized value boosted by user slider
      _injectPhysicsBump(normalizedEnergy);
    }
  }

  void _injectPhysicsBump(double rawIntensity) {
    // Multiply raw intensity by user's active preference toggle!
    final double scaledIntensity = rawIntensity * state.sensitivity;
    
    final engine = ref.read(avatarEngineProvider.notifier);
    // Softened force ranges for natural vibe, with smooth variation
    final double lat = (math.Random().nextDouble() - 0.5) * 12.0 * scaledIntensity;
    final double vert = -14.0 - (18.0 * scaledIntensity); 
    
    engine.applyDirectForce(Offset(lat, vert));
    
    if (scaledIntensity > 1.1) { // Boosted detection for excitement
       engine.triggerReaction(AvatarEmotion.excited, duration: const Duration(milliseconds: 650));
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
    _controlChannel.invokeMethod('stopVisualizer').catchError((_) {});
    _visualizerSub?.cancel();
    _visualizerSub = null;
    state = AvatarMusicState(sensitivity: state.sensitivity); // Reset, keep sensitivity
  }
}
