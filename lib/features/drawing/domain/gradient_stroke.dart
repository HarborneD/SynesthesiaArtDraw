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
}
