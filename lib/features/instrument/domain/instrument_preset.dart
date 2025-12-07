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
  final bool isDelayOn;
  final double delayTime; // Renamed from reverbDelay
  final double delayFeedback; // Renamed from reverbDecay
  final double reverbLevel; // New True Reverb (0-127 or 0.0-1.0)

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
    required this.isDelayOn,
    required this.delayTime,
    required this.delayFeedback,
    required this.reverbLevel,
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
      'isDelayOn': isDelayOn,
      'delayTime': delayTime,
      'delayFeedback': delayFeedback,
      'reverbLevel': reverbLevel,
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
      isDelayOn:
          json['isDelayOn'] as bool? ?? json['isReverbOn'] as bool? ?? true,
      delayTime:
          (json['delayTime'] as num?)?.toDouble() ??
          (json['reverbDelay'] as num?)?.toDouble() ??
          500.0,
      delayFeedback:
          (json['delayFeedback'] as num?)?.toDouble() ??
          (json['reverbDecay'] as num?)?.toDouble() ??
          0.6,
      reverbLevel:
          (json['reverbLevel'] as num?)?.toDouble() ??
          0.3, // Default 30% reverb
      isSustainOn: json['isSustainOn'] as bool? ?? false,
      directionChangeThreshold:
          (json['directionChangeThreshold'] as num?)?.toDouble() ?? 90.0,
    );
  }
}
