import 'package:flutter/material.dart';

class AvatarMusicState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double liveEnergy;
  final double sensitivity; // 0.5 to 2.5 for user tuning
  final String? fileName;

  AvatarMusicState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.liveEnergy = 0.0,
    this.sensitivity = 1.0,
    this.fileName,
  });

  AvatarMusicState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? liveEnergy,
    double? sensitivity,
    String? fileName,
  }) {
    return AvatarMusicState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      liveEnergy: liveEnergy ?? this.liveEnergy,
      sensitivity: sensitivity ?? this.sensitivity,
      fileName: fileName ?? this.fileName,
    );
  }
}
