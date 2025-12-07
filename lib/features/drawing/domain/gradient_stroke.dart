import 'dart:ui';

class GradientStroke {
  final Offset p0;
  final Offset p1;
  final List<Color> colors;
  final List<double> stops;
  final double intensity;

  GradientStroke({
    required this.p0,
    required this.p1,
    required this.colors,
    required this.stops,
    required this.intensity,
  });

  GradientStroke copyWith({
    Offset? p0,
    Offset? p1,
    List<Color>? colors,
    List<double>? stops,
    double? intensity,
  }) {
    return GradientStroke(
      p0: p0 ?? this.p0,
      p1: p1 ?? this.p1,
      colors: colors ?? this.colors,
      stops: stops ?? this.stops,
      intensity: intensity ?? this.intensity,
    );
  }
      intensity: intensity ?? this.intensity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'p0x': p0.dx,
      'p0y': p0.dy,
      'p1x': p1.dx,
      'p1y': p1.dy,
      'colors': colors.map((c) => c.value).toList(),
      'stops': stops,
      'intensity': intensity,
    };
  }

  factory GradientStroke.fromJson(Map<String, dynamic> json) {
    return GradientStroke(
      p0: Offset(
          (json['p0x'] as num).toDouble(), (json['p0y'] as num).toDouble()),
      p1: Offset(
          (json['p1x'] as num).toDouble(), (json['p1y'] as num).toDouble()),
      colors: (json['colors'] as List<dynamic>)
          .map((e) => Color(e as int))
          .toList(),
      stops:
          (json['stops'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      intensity: (json['intensity'] as num).toDouble(),
    );
  }
}
