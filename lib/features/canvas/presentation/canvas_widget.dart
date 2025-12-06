import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui' as ui;
import '../../midi/domain/music_configuration.dart';
import '../../drawing/domain/drawn_line.dart';
import '../../drawing/domain/gradient_stroke.dart';
import 'dart:math';
import '../../canvas/presentation/background_gradient_painter.dart';

import '../../drawing/domain/drawing_mode.dart';
import 'line_painter_utils.dart';

class CanvasWidget extends StatefulWidget {
  final MusicConfiguration musicConfig;
  final bool showNoteLines;
  final double segmentLength;
  final double minPixels;
  final List<DrawnLine> lines;
  final DrawnLine? currentLine;
  final DrawingMode drawingMode;
  final Color selectedColor;
  final bool triggerOnBoundary;

  // Brush Props
  final double currentBrushSpread;
  final double currentBrushOpacity;
  final int currentBristleCount;
  final bool currentUseNeonGlow;

  // Gradient Props
  final ui.FragmentShader? backgroundShader;
  final List<GradientStroke> gradientStrokes;
  final ValueChanged<GradientStroke>? onGradientStrokeAdded;
  final bool showGradientOverlays;

  final ValueChanged<DrawnLine?> onCurrentLineUpdated;
  final ValueChanged<DrawnLine> onLineCompleted;
  final ValueChanged<DrawnLine> onLineDeleted;
  final Function(int, DrawnLine) onNoteTriggered;

  const CanvasWidget({
    super.key,
    required this.musicConfig,
    required this.showNoteLines,
    required this.segmentLength,
    required this.minPixels,
    required this.lines,
    this.currentLine,
    required this.drawingMode,
    this.selectedColor = Colors.black,
    this.triggerOnBoundary = false,
    this.currentBrushSpread = 2.0,
    this.currentBrushOpacity = 0.5,
    this.currentBristleCount = 8,
    this.currentUseNeonGlow = true,
    this.backgroundShader,
    this.gradientStrokes = const [],
    this.onGradientStrokeAdded,
    this.showGradientOverlays = false,
    required this.onCurrentLineUpdated,
    required this.onLineCompleted,
    required this.onLineDeleted,
    required this.onNoteTriggered,
  });

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  Offset? _lastTriggerPoint;
  int? _lastTriggerNoteIndex;
  DateTime? _lastDirectionTriggerTime;
  bool _isRightClick = false;

  void _handlePanStart(DragStartDetails details, BoxConstraints constraints) {
    if (_isRightClick) return;

    if (widget.drawingMode == DrawingMode.erase) {
      _handleErase(details.localPosition);
      return;
    }

    if (widget.drawingMode == DrawingMode.gradient) {
      // Start a gradient stroke logic?
      // Actually gradient stroke is defined by P0 -> P1.
      // On PanStart we set P0. On PanEnd we set P1 and finalize.
      // OR we visualize the line being drawn.
      // For simplicity, let's treat it like DrawingMode.line but finalizer creates GradientStroke.
    }

    final point = DrawingPoint(point: details.localPosition);
    final newLine = DrawnLine(
      id: DateTime.now().toIso8601String(), // Simple unique ID
      path: [point],
      width: 2.0,
      color: widget.selectedColor,
      // Apply correct brush settings from widget props
      spread: widget.currentBrushSpread,
      opacity: widget.currentBrushOpacity,
      bristleCount: widget.currentBristleCount,
      useNeonGlow: widget.currentUseNeonGlow,
    );

    // Trigger initial note logic ONLY for LINE mode?
    // User spec says: "The user draws multiple 'gradient strokes'... They are visual-only"
    if (widget.drawingMode == DrawingMode.line) {
      // Trigger initial note
      _processTriggerLogic(
        details.localPosition,
        constraints.maxHeight,
        newLine,
        forceTrigger: true,
      );
    }

    // For now, we use standard line drawing visuals for Feedback,
    // then convert to GradientStroke on End if mode is gradient.

    widget.onCurrentLineUpdated(newLine);
  }

  void _handlePanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_isRightClick) return;

    if (widget.drawingMode == DrawingMode.erase) {
      _handleErase(details.localPosition);
      return;
    }

    if (widget.currentLine == null) {
      return;
    }

    final point = DrawingPoint(point: details.localPosition);
    final updatedList = List<DrawingPoint>.from(widget.currentLine!.path)
      ..add(point);

    // Create updated line, preserving style from widget.currentLine (which got it from HomePage on creation)
    // Actually, on creation in PanStart we need to populate these.
    // .. Wait, `widget.currentLine` is passed from parent.
    // In PanStart we create a NEW line.
    final updatedLine = DrawnLine(
      id: widget.currentLine!.id, // Propagate ID
      path: updatedList,
      color: widget.currentLine!.color,
      width: widget.currentLine!.width,
      spread: widget.currentLine!.spread,
      opacity: widget.currentLine!.opacity,
      bristleCount: widget.currentLine!.bristleCount,
      useNeonGlow: widget.currentLine!.useNeonGlow,
    );

    _processTriggerLogic(
      details.localPosition,
      constraints.maxHeight,
      updatedLine,
    );

    widget.onCurrentLineUpdated(updatedLine);
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isRightClick) return;
    if (widget.drawingMode == DrawingMode.erase) return;

    if (widget.currentLine != null) {
      if (widget.drawingMode == DrawingMode.gradient) {
        // Convert DrawnLine to GradientStroke
        final path = widget.currentLine!.path;
        if (path.length >= 2) {
          final p0 = path.first.point;
          final p1 = path.last.point;

          // Define default gradient for now (e.g. 3 colors)
          // We could randomize or cycle these.
          final stroke = GradientStroke(
            p0: p0,
            p1: p1,
            colors: [Colors.purple, Colors.blue, Colors.cyan],
            stops: [0.0, 0.5, 1.0],
            intensity: 800.0,
          );
          widget.onGradientStrokeAdded?.call(stroke);
          widget.onCurrentLineUpdated(null); // Clear the temporary line
        }
      } else {
        widget.onLineCompleted(widget.currentLine!);
      }
      _lastTriggerPoint = null;
      _lastTriggerNoteIndex = null;
    }
  }

  void _handleErase(Offset position) {
    const double eraseThreshold = 20.0;

    for (final line in widget.lines) {
      if (line.path.length < 2) continue;

      bool hit = false;
      for (int i = 0; i < line.path.length - 1; i++) {
        final p1 = line.path[i].point;
        final p2 = line.path[i + 1].point;
        final dist = _distanceFromPointToLineSegment(position, p1, p2);
        if (dist <= eraseThreshold) {
          hit = true;
          break;
        }
      }

      if (hit) {
        widget.onLineDeleted(line);
        return;
      }
    }
  }

  double _distanceFromPointToLineSegment(Offset p, Offset v, Offset w) {
    final double l2 =
        (w.dx - v.dx) * (w.dx - v.dx) + (w.dy - v.dy) * (w.dy - v.dy);
    if (l2 == 0) return (p - v).distance;

    final double t =
        ((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2;

    if (t < 0) return (p - v).distance;
    if (t > 1) return (p - w).distance;

    final Offset projection = Offset(
      v.dx + t * (w.dx - v.dx),
      v.dy + t * (w.dy - v.dy),
    );
    return (p - projection).distance;
  }

  // Helper to start searching backwards from index [startIdx]
  // Returns index of point >= minDistance away, or -1 if not found.
  int _findPointAtMinDist(
    List<DrawingPoint> path,
    int startIdx,
    double minDistance,
  ) {
    if (startIdx < 0 || startIdx >= path.length) return -1;

    final startP = path[startIdx].point;
    for (int i = startIdx - 1; i >= 0; i--) {
      if ((path[i].point - startP).distance >= minDistance) {
        return i;
      }
    }
    return -1;
  }

  void _processTriggerLogic(
    Offset currentPoint,
    double height,
    DrawnLine activeLine, {
    bool forceTrigger = false,
  }) {
    if (widget.drawingMode != DrawingMode.line)
      return; // Only process notes for Line mode

    final activeOctaves = widget.musicConfig.getActiveOctaves();
    if (activeOctaves.isEmpty) return;

    final degreesCount = widget.musicConfig.selectedDegrees.length;
    final activeOctavesCount =
        activeOctaves.length; // renamed to avoid conflict
    final totalNotes = activeOctavesCount * degreesCount;
    if (totalNotes == 0) return;

    final noteHeight = height / totalNotes;

    // Inverted Y: 0 at bottom.
    // detail.localPosition.dy is 0 at top.
    // So visualBottomY = height - localPosition.dy
    final visualYFromBottom = height - currentPoint.dy;

    // Calculate Note Index (0 is lowest pitch)
    // index = floor(visualYFromBottom / noteHeight)
    int noteIndex = (visualYFromBottom / noteHeight).floor();

    // Clamp index
    noteIndex = noteIndex.clamp(0, totalNotes - 1);

    bool shouldTrigger = forceTrigger;

    // 2. Note Boundary Crossing
    // Only check if toggle is ON
    if (widget.triggerOnBoundary &&
        _lastTriggerNoteIndex != null &&
        _lastTriggerNoteIndex != noteIndex) {
      if (noteIndex != -1) {
        shouldTrigger = true;
      }
    }

    // 3. Check Segment Length
    if (_lastTriggerPoint != null) {
      final distance = (currentPoint - _lastTriggerPoint!).distance;
      if (distance >= widget.segmentLength) {
        shouldTrigger = true;
      }
    }

    // 4. Direction Change Trigger
    // We utilize a "lookback" strategy to smooth out small jitters.
    // Instead of adjacent points, we look for points separated by at least X pixels.
    final double lookbackDist =
        15.0; // Minimum vector length to be considered a stable direction

    if (activeLine.path.length >= 3) {
      final idxC = activeLine.path.length - 1;
      final idxB = _findPointAtMinDist(activeLine.path, idxC, lookbackDist);

      if (idxB != -1) {
        final idxA = _findPointAtMinDist(activeLine.path, idxB, lookbackDist);

        if (idxA != -1) {
          final pA = activeLine.path[idxA].point;
          final pB = activeLine.path[idxB].point;
          final pC = activeLine.path[idxC].point;

          // Vector 1: Incoming (A -> B)
          final v1 = pB - pA;
          // Vector 2: Outgoing (B -> C)
          final v2 = pC - pB;

          if (v1.distance > 0 && v2.distance > 0) {
            final angle1 = v1.direction;
            final angle2 = v2.direction;

            double diff = (angle1 - angle2).abs();
            if (diff > pi) diff = 2 * pi - diff;

            final diffDegrees = diff * 180 / pi;

            // Debounce check (e.g. 200ms) to prevent multiple triggers for the same corner
            final now = DateTime.now();
            bool inDebounce =
                _lastDirectionTriggerTime != null &&
                now.difference(_lastDirectionTriggerTime!).inMilliseconds < 200;

            if (!inDebounce &&
                diffDegrees > widget.musicConfig.directionChangeThreshold) {
              shouldTrigger = true;
              _lastDirectionTriggerTime = now;
              // debugPrint("Direction Trigger! Angle: ${diffDegrees.toStringAsFixed(1)}");
            }
          }
        }
      }
    }

    if (shouldTrigger) {
      // Check if we already triggered this note for this line recently?
      // For now, stateless trigger is fine. State is managed by HomePage.

      // Callback with index AND line source
      widget.onNoteTriggered(noteIndex, activeLine);

      // Debug
      // debugPrint("Triggered Note Index: $noteIndex from line length ${activeLine.path.length}");
      _lastTriggerPoint = currentPoint;
      _lastTriggerNoteIndex = noteIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _handlePanStart(details, constraints);
          },
          onPanUpdate: (details) => _handlePanUpdate(details, constraints),
          onPanEnd: _handlePanEnd,
          child: Container(
            color: Colors.white,
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: BackgroundGradientPainter(
                shader: widget.backgroundShader,
                strokes: widget.gradientStrokes,
              ),
              foregroundPainter: _OverlayPainter(
                musicConfig: widget.musicConfig,
                showNoteLines: widget.showNoteLines,
                gradientStrokes: widget.showGradientOverlays
                    ? widget.gradientStrokes
                    : [],
              ),
              child: CustomPaint(
                painter: _LinesPainter(
                  lines: widget.lines,
                  currentLine: widget.currentLine,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LinesPainter extends CustomPainter {
  final List<DrawnLine> lines;
  final DrawnLine? currentLine;

  _LinesPainter({required this.lines, required this.currentLine});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      if (line.path.isEmpty) continue;

      // Generate smooth path
      final points = line.path.map((p) => p.point).toList();
      final path = LinePainterUtils.generateSmoothPath(points);

      // 1. Draw Glow (Behind) - Optional
      if (line.useNeonGlow) {
        final glowPaint = Paint()
          ..color = line.color.withOpacity(0.6)
          ..strokeWidth =
              line.width *
              4 // Wider for glow
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            8.0,
          ); // Blur effect

        canvas.drawPath(path, glowPaint);
      }

      // 2. Draw Bristles (Paint Brush Effect)
      // Use the line's ID hash as a seed for stable randomness
      final random = Random(line.id.hashCode);
      final bristleCount = line.bristleCount; // Use line's count
      final baseWidth = line.width;
      final spread = line.spread;

      // Draw multiple passes with varying offsets and opacity
      for (int i = 0; i < bristleCount; i++) {
        final offsetX = (random.nextDouble() - 0.5) * baseWidth * spread;
        final offsetY = (random.nextDouble() - 0.5) * baseWidth * spread;
        final opacity = 0.3 + (random.nextDouble() * 0.5); // 0.3 to 0.8

        // Scale opacity by line's opacity setting
        final finalOpacity = (opacity * line.opacity).clamp(0.0, 1.0);

        final bristlePaint = Paint()
          ..color = line.color.withOpacity(finalOpacity)
          ..strokeWidth = max(1.0, baseWidth / 3)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        canvas.save();
        canvas.translate(offsetX, offsetY);
        canvas.drawPath(path, bristlePaint);
        canvas.restore();
      }

      // Optional: Draw a thin core?
      // Only draw core if opacity is high enough, else it ruins "dry" look.
      if (line.opacity > 0.8) {
        final corePaint = Paint()
          ..color = line.color.withOpacity(0.3)
          ..strokeWidth = line.width
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        canvas.drawPath(path, corePaint);
      }
    }

    // Draw active line
    if (currentLine != null) {
      if (currentLine!.path.isEmpty) return;
      // Active line: Draw simpler for performance, or full effect?
      // Detailed effect is fine for one line.
      final path = LinePainterUtils.generateSmoothPath(
        currentLine!.path.map((p) => p.point).toList(),
      );

      // Glow - Optional
      if (currentLine!.useNeonGlow) {
        final glowPaint = Paint()
          ..color = currentLine!.color.withOpacity(0.6)
          ..strokeWidth = currentLine!.width * 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

        canvas.drawPath(path, glowPaint);
      }

      final random = Random(currentLine!.id.hashCode);
      final bristleCount = currentLine!.bristleCount;
      final baseWidth = currentLine!.width;
      final spread = currentLine!.spread;

      for (int i = 0; i < bristleCount; i++) {
        final offsetX = (random.nextDouble() - 0.5) * baseWidth * spread;
        final offsetY = (random.nextDouble() - 0.5) * baseWidth * spread;
        final opacity = 0.3 + (random.nextDouble() * 0.5);

        final finalOpacity = (opacity * currentLine!.opacity).clamp(0.0, 1.0);

        final bristlePaint = Paint()
          ..color = currentLine!.color.withOpacity(finalOpacity)
          ..strokeWidth = max(1.0, baseWidth / 3)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        canvas.save();
        canvas.translate(offsetX, offsetY);
        canvas.drawPath(path, bristlePaint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter oldDelegate) {
    return true; // Optimize later
  }
}

class _OverlayPainter extends CustomPainter {
  final MusicConfiguration musicConfig;
  final bool showNoteLines;
  final List<GradientStroke> gradientStrokes;

  _OverlayPainter({
    required this.musicConfig,
    required this.showNoteLines,
    required this.gradientStrokes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Grid
    if (showNoteLines && musicConfig.selectedDegrees.isNotEmpty) {
      final activeOctaves = musicConfig.getActiveOctaves();
      if (activeOctaves.isNotEmpty) {
        final degreesCount = musicConfig.selectedDegrees.length;
        final totalNotes = activeOctaves.length * degreesCount;

        if (totalNotes > 0) {
          final noteHeight = size.height / totalNotes;

          // Standard Line Paint
          final standardPaint = Paint()
            ..color = Colors.grey.withOpacity(0.5)
            ..strokeWidth = 2.0;

          // Bold Line Paint (for Root/Octave division)
          final boldPaint = Paint()
            ..color = Colors.black.withOpacity(0.8)
            ..strokeWidth = 4.0;

          for (int i = 0; i <= totalNotes; i++) {
            final y = size.height - (i * noteHeight);

            // Logic to highlight root notes?
            // Assuming simplest grid for now to avoid logic errors without viewing source.
            // But let's try to preserve the bold logic if possible.
            // "i % degreesCount == 0" means a C-equivalent if C scale?
            // Let's stick to standard lines for safety unless I'm sure.
            // Reviewing previous diff... it had "isRootBoundary" logic.
            // I'll reimplement specific logic:

            bool isRootBoundary = (i % degreesCount == 0);

            canvas.drawLine(
              Offset(0, y),
              Offset(size.width, y),
              isRootBoundary ? boldPaint : standardPaint,
            );
          }
        }
      }
    }

    // 2. Draw Gradient Overlays
    if (gradientStrokes.isNotEmpty) {
      final skelPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      final handlePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final radiusPaint = Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.stroke;

      for (final stroke in gradientStrokes) {
        // Draw Line
        canvas.drawLine(stroke.p0, stroke.p1, skelPaint);
        // Draw Handles
        canvas.drawCircle(stroke.p0, 4.0, handlePaint);
        canvas.drawCircle(stroke.p1, 4.0, handlePaint);

        // Draw Intesity Radius (approximate visual feedback)
        final center = Offset(
          (stroke.p0.dx + stroke.p1.dx) / 2,
          (stroke.p0.dy + stroke.p1.dy) / 2,
        );
        canvas.drawCircle(center, stroke.intensity, radiusPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.musicConfig != musicConfig ||
        oldDelegate.showNoteLines != showNoteLines ||
        oldDelegate.gradientStrokes != gradientStrokes;
  }
}
