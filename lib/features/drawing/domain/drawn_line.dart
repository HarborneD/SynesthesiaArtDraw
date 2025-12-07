import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset point;
  final double pressure;

  DrawingPoint({required this.point, this.pressure = 1.0});

  Map<String, dynamic> toJson() => {
    'x': point.dx,
    'y': point.dy,
    'p': pressure,
  };

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      point: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      pressure: (json['p'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class DrawnLine {
  final String id;
  final List<DrawingPoint> path;
  final Color color;
  final double width;
  final String? soundFont;
  final int? program;
  final int? sfId;

  // Brush Style
  final double spread;
  final double opacity;
  final int bristleCount;
  final bool useNeonGlow;

  DrawnLine({
    required this.id,
    required this.path,
    this.color = Colors.black,
    this.width = 2.0,
    this.soundFont,
    this.program,
    this.sfId,
    this.spread = 1.0,
    this.opacity = 0.5,
    this.bristleCount = 8,
    this.useNeonGlow = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path.map((p) => p.toJson()).toList(),
      'color': color.value,
      'width': width,
      'soundFont': soundFont,
      'program': program,
      'sfId': sfId,
      'spread': spread,
      'opacity': opacity,
      'bristleCount': bristleCount,
      'useNeonGlow': useNeonGlow,
    };
  }

  factory DrawnLine.fromJson(Map<String, dynamic> json) {
    return DrawnLine(
      id: json['id'] as String,
      path: (json['path'] as List<dynamic>)
          .map((e) => DrawingPoint.fromJson(e))
          .toList(),
      color: Color(json['color'] as int),
      width: (json['width'] as num?)?.toDouble() ?? 2.0,
      soundFont: json['soundFont'] as String?,
      program: json['program'] as int?,
      sfId: json['sfId'] as int?,
      spread: (json['spread'] as num?)?.toDouble() ?? 1.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.5,
      bristleCount: json['bristleCount'] as int? ?? 8,
      useNeonGlow: json['useNeonGlow'] as bool? ?? true,
    );
  }
}
