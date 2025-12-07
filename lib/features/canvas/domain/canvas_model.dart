import 'package:flutter/foundation.dart';
import '../../drawing/domain/drawn_line.dart';
import '../../drawing/domain/gradient_stroke.dart';
import '../../midi/domain/music_configuration.dart';

class CanvasModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DrawnLine> lines;
  final List<GradientStroke> gradientStrokes;
  final MusicConfiguration musicConfig;
  final int
  drawingModeIndex; // 0: Line, 1: Gradient, 2: Erase (just to save state)

  CanvasModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.lines,
    required this.gradientStrokes,
    required this.musicConfig,
    this.drawingModeIndex = 0,
  });

  CanvasModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<DrawnLine>? lines,
    List<GradientStroke>? gradientStrokes,
    MusicConfiguration? musicConfig,
    int? drawingModeIndex,
  }) {
    return CanvasModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lines: lines ?? this.lines,
      gradientStrokes: gradientStrokes ?? this.gradientStrokes,
      musicConfig: musicConfig ?? this.musicConfig,
      drawingModeIndex: drawingModeIndex ?? this.drawingModeIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lines': lines.map((e) => e.toJson()).toList(),
      'gradientStrokes': gradientStrokes.map((e) => e.toJson()).toList(),
      'musicConfig': musicConfig.toJson(),
      'drawingModeIndex': drawingModeIndex,
    };
  }

  factory CanvasModel.fromJson(Map<String, dynamic> json) {
    return CanvasModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lines: (json['lines'] as List<dynamic>)
          .map((e) => DrawnLine.fromJson(e))
          .toList(),
      gradientStrokes: (json['gradientStrokes'] as List<dynamic>)
          .map((e) => GradientStroke.fromJson(e))
          .toList(),
      musicConfig: MusicConfiguration.fromJson(
        json['musicConfig'] as Map<String, dynamic>,
      ),
      drawingModeIndex: json['drawingModeIndex'] as int? ?? 0,
    );
  }
}
