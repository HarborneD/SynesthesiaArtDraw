import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import '../../canvas/presentation/line_painter_utils.dart';

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
  final int? instrumentSlotIndex;

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
    this.instrumentSlotIndex,
    this.spread = 1.0,
    this.opacity = 0.5,
    this.bristleCount = 8,
    this.useNeonGlow = true,
  });

  // Caching Optimization
  late final Path smoothPath = LinePainterUtils.generateSmoothPath(
    path.map((e) => e.point).toList(),
  );

  late final List<Offset> bristleOffsets = _generateBristleOffsets();
  late final List<double> bristleOpacities = _generateBristleOpacities();

  List<Offset> _generateBristleOffsets() {
    final random = Random(id.hashCode);
    final List<Offset> offsets = [];
    for (int i = 0; i < bristleCount; i++) {
      final offsetX = (random.nextDouble() - 0.5) * width * spread;
      final offsetY = (random.nextDouble() - 0.5) * width * spread;
      offsets.add(Offset(offsetX, offsetY));
    }
    return offsets;
  }

  List<double> _generateBristleOpacities() {
    final random = Random(id.hashCode);
    // Burn some randoms to sync with offsets generation just in case order matters,
    // though using separate loops or same loop logic in separate call is safer.
    // Ideally we'd generate tuple, but separate lists is fine.
    // TO ENSURE STABILITY: We need to use the exact same sequence or seed.
    // Random(id.hashCode) resets the sequence.
    // _generateOffsets pulls (nextDouble, nextDouble) * count.
    // We must SKIP those to get to the opacity ones if we want them to match previous logic?
    // Actually, previous logic was:
    // loop {
    //   offsetX = rand...;
    //   offsetY = rand...;
    //   opacity = rand...;
    // }
    // So to reproduce that EXACT sequence with two methods:
    // Method 1 (Offsets): loop { rand; rand; skip(1); }
    // Method 2 (Opacities): loop { skip(2); rand; }
    // OR just generate them all in one go and store in a private class or just list of tuples?
    // Let's keep it simple. The exact visual doesn't need to match pixel-perfectly with old version,
    // just needs to be deterministic per ID.
    // So distinct sequences are fine.
    final List<double> opacities = [];
    // We intentionally use a different sequence (fresh Random) or same?
    // Different loop = different random calls.
    // It's deterministic based on seed.
    for (int i = 0; i < bristleCount; i++) {
      opacities.add(0.3 + (random.nextDouble() * 0.5));
    }
    return opacities;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path.map((p) => p.toJson()).toList(),
      'color': color.value,
      'width': width,
      'soundFont': soundFont,
      'program': program,
      'sfId': sfId,
      'instrumentSlotIndex': instrumentSlotIndex,
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
      instrumentSlotIndex: json['instrumentSlotIndex'] as int?,
      spread: (json['spread'] as num?)?.toDouble() ?? 1.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.5,
      bristleCount: json['bristleCount'] as int? ?? 8,
      useNeonGlow: json['useNeonGlow'] as bool? ?? true,
    );
  }
}
