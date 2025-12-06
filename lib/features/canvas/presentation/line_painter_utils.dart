import 'dart:ui';

class LinePainterUtils {
  /// Generates a smooth Path from a list of points using Catmull-Rom splines.
  static Path generateSmoothPath(
    List<Offset> points, {
    bool closePath = false,
  }) {
    if (points.isEmpty) return Path();
    if (points.length < 2) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      path.lineTo(points.first.dx, points.first.dy);
      return path;
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = (i + 2 < points.length) ? points[i + 2] : p2;

      for (double t = 0.1; t <= 1.0; t += 0.1) {
        final pos = _catmullRom(p0, p1, p2, p3, t);
        path.lineTo(pos.dx, pos.dy);
      }
    }

    if (closePath) {
      path.close();
    }

    return path;
  }

  static Offset _catmullRom(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    double t,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;

    final double v0 = 0.5 * ((-t3) + (2 * t2) - t);
    final double v1 = 0.5 * ((3 * t3) - (5 * t2) + 2);
    final double v2 = 0.5 * ((-3 * t3) + (4 * t2) + t);
    final double v3 = 0.5 * (t3 - t2);

    return Offset(
      (p0.dx * v0) + (p1.dx * v1) + (p2.dx * v2) + (p3.dx * v3),
      (p0.dy * v0) + (p1.dy * v1) + (p2.dy * v2) + (p3.dy * v3),
    );
  }
}
