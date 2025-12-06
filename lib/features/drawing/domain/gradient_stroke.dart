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
}
