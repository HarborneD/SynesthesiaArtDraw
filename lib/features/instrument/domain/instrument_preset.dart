import 'package:flutter/material.dart';

class InstrumentPreset {
  final String name;
  final double brushSpread;
  final double brushOpacity;
  final int bristleCount;
  final bool useNeonGlow;
  final int colorValue; // Store int value of color
  final bool triggerOnBoundary;
  final double minPixelsForTrigger;
  final String soundFont;
  final int programIndex;
  final bool isReverbOn;
  final double reverbDelay;
  final double reverbDecay;
  final bool isSustainOn;
  final double directionChangeThreshold;

  InstrumentPreset({
    required this.name,
    required this.brushSpread,
    required this.brushOpacity,
    required this.bristleCount,
    required this.useNeonGlow,
    required this.colorValue,
    required this.triggerOnBoundary,
    required this.minPixelsForTrigger,
    required this.soundFont,
    required this.programIndex,
    required this.isReverbOn,
    required this.reverbDelay,
    required this.reverbDecay,
    required this.isSustainOn,
    required this.directionChangeThreshold,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brushSpread': brushSpread,
      'brushOpacity': brushOpacity,
      'bristleCount': bristleCount,
      'useNeonGlow': useNeonGlow,
      'colorValue': colorValue,
      'triggerOnBoundary': triggerOnBoundary,
      'minPixelsForTrigger': minPixelsForTrigger,
      'soundFont': soundFont,
      'programIndex': programIndex,
      'isReverbOn': isReverbOn,
      'reverbDelay': reverbDelay,
      'reverbDecay': reverbDecay,
      'isSustainOn': isSustainOn,
      'directionChangeThreshold': directionChangeThreshold,
    };
  }

  factory InstrumentPreset.fromJson(Map<String, dynamic> json) {
    return InstrumentPreset(
      name: json['name'] as String? ?? 'Untitled Preset',
      brushSpread: (json['brushSpread'] as num?)?.toDouble() ?? 5.0,
      brushOpacity: (json['brushOpacity'] as num?)?.toDouble() ?? 0.5,
      bristleCount: (json['bristleCount'] as num?)?.toInt() ?? 20,
      useNeonGlow: json['useNeonGlow'] as bool? ?? true,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? Colors.teal.value,
      triggerOnBoundary: json['triggerOnBoundary'] as bool? ?? true,
      minPixelsForTrigger:
          (json['minPixelsForTrigger'] as num?)?.toDouble() ?? 10.0,
      soundFont: json['soundFont'] as String? ?? 'White Grand Piano II.sf2',
      programIndex: (json['programIndex'] as num?)?.toInt() ?? 0,
      isReverbOn: json['isReverbOn'] as bool? ?? true,
      reverbDelay: (json['reverbDelay'] as num?)?.toDouble() ?? 500.0,
      reverbDecay: (json['reverbDecay'] as num?)?.toDouble() ?? 0.6,
      isSustainOn: json['isSustainOn'] as bool? ?? false,
      directionChangeThreshold:
          (json['directionChangeThreshold'] as num?)?.toDouble() ?? 90.0,
    );
  }
}
