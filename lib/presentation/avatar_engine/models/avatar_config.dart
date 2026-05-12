import 'dart:convert';
import 'package:flutter/material.dart';

class PaintStroke {
  final List<Offset> points;
  final String color;
  final double width;

  PaintStroke({required this.points, required this.color, required this.width});

  factory PaintStroke.fromMap(Map<String, dynamic> map) {
    final list = map['points'] as List? ?? [];
    final pts = list.map((p) {
      final parts = p.toString().split(',');
      return Offset(double.parse(parts[0]), double.parse(parts[1]));
    }).toList();
    return PaintStroke(
      points: pts,
      color: map['color'] ?? '#FF0000',
      width: (map['width'] as num?)?.toDouble() ?? 4.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => '${p.dx.toStringAsFixed(3)},${p.dy.toStringAsFixed(3)}').toList(),
      'color': color,
      'width': width,
    };
  }
}

class AvatarConfig {
  final int hair;
  final int eyes;
  final int mouth;
  final int acc;
  final int facialHair;
  final int details;
  final int eyebrows;
  final int noseStyle;
  final int outfit;
  final int earring;
  final int hatOverride;
  final int bgStyle;
  final int vibe;
  final String bgColor;
  final String skinColor;
  final String hairColor;
  final String outfitColor;
  final String? hairGradient;
  final List<PaintStroke> customStrokes;

  AvatarConfig({
    required this.hair,
    required this.eyes,
    required this.mouth,
    required this.acc,
    required this.facialHair,
    required this.details,
    required this.bgColor,
    required this.skinColor,
    required this.hairColor,
    required this.outfitColor,
    this.eyebrows = 0,
    this.noseStyle = 0,
    this.outfit = 0,
    this.earring = 0,
    this.hatOverride = 0,
    this.bgStyle = 0,
    this.vibe = 0,
    this.hairGradient,
    this.customStrokes = const [],
  });

  factory AvatarConfig.defaultConfig() {
    return AvatarConfig(
      hair: 1, eyes: 0, mouth: 0, acc: 0, facialHair: 0, details: 0,
      bgColor: '#FF6B6B', skinColor: '#FFDBB5', hairColor: '#2D3748', outfitColor: '#4A5568',
    );
  }

  factory AvatarConfig.fromJson(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr);
      final strokesList = map['customStrokes'] as List? ?? [];
      final strokes = strokesList.map((s) => PaintStroke.fromMap(s)).toList();
      return AvatarConfig(
        hair: map['hair'] ?? 1,
        eyes: map['eyes'] ?? 0,
        mouth: map['mouth'] ?? 0,
        acc: map['acc'] ?? 0,
        facialHair: map['facialHair'] ?? 0,
        details: map['details'] ?? 0,
        eyebrows: map['eyebrows'] ?? 0,
        noseStyle: map['noseStyle'] ?? 0,
        outfit: map['outfit'] ?? 0,
        earring: map['earring'] ?? 0,
        hatOverride: map['hatOverride'] ?? 0,
        bgStyle: map['bgStyle'] ?? 0,
        vibe: map['vibe'] ?? 0,
        bgColor: map['bgColor'] ?? '#FF6B6B',
        skinColor: map['skinColor'] ?? '#FFDBB5',
        hairColor: map['hairColor'] ?? '#2D3748',
        outfitColor: map['outfitColor'] ?? '#4A5568',
        hairGradient: map['hairGradient'],
        customStrokes: strokes,
      );
    } catch (_) {
      return AvatarConfig.defaultConfig();
    }
  }

  String toJson() {
    final map = <String, dynamic>{
      'hair': hair, 'eyes': eyes, 'mouth': mouth, 'acc': acc,
      'facialHair': facialHair, 'details': details,
      'eyebrows': eyebrows, 'noseStyle': noseStyle, 'outfit': outfit,
      'earring': earring, 'hatOverride': hatOverride,
      'bgStyle': bgStyle, 'vibe': vibe,
      'bgColor': bgColor, 'skinColor': skinColor,
      'hairColor': hairColor, 'outfitColor': outfitColor,
    };
    if (hairGradient != null) map['hairGradient'] = hairGradient;
    if (customStrokes.isNotEmpty) {
      map['customStrokes'] = customStrokes.map((s) => s.toMap()).toList();
    }
    return jsonEncode(map);
  }

  AvatarConfig copyWith({
    int? hair, int? eyes, int? mouth, int? acc, int? facialHair, int? details,
    int? eyebrows, int? noseStyle, int? outfit, int? earring, int? hatOverride,
    int? bgStyle, int? vibe, String? bgColor, String? skinColor, String? hairColor,
    String? outfitColor, List<PaintStroke>? customStrokes,
  }) {
    return AvatarConfig(
      hair: hair ?? this.hair,
      eyes: eyes ?? this.eyes,
      mouth: mouth ?? this.mouth,
      acc: acc ?? this.acc,
      facialHair: facialHair ?? this.facialHair,
      details: details ?? this.details,
      eyebrows: eyebrows ?? this.eyebrows,
      noseStyle: noseStyle ?? this.noseStyle,
      outfit: outfit ?? this.outfit,
      earring: earring ?? this.earring,
      hatOverride: hatOverride ?? this.hatOverride,
      bgStyle: bgStyle ?? this.bgStyle,
      vibe: vibe ?? this.vibe,
      bgColor: bgColor ?? this.bgColor,
      skinColor: skinColor ?? this.skinColor,
      hairColor: hairColor ?? this.hairColor,
      outfitColor: outfitColor ?? this.outfitColor,
      customStrokes: customStrokes ?? this.customStrokes,
    );
  }
}
