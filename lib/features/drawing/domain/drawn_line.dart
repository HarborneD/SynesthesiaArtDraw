import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset point;
  final double pressure;

  DrawingPoint({required this.point, this.pressure = 1.0});
}

class DrawnLine {
  final List<DrawingPoint> path;
  final Color color;
  final double width;

  DrawnLine({required this.path, this.color = Colors.black, this.width = 2.0});
}
