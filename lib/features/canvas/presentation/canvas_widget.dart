import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../midi/domain/music_configuration.dart';
import '../../drawing/domain/drawn_line.dart';

import '../../drawing/domain/drawing_mode.dart';

class CanvasWidget extends StatefulWidget {
  final MusicConfiguration musicConfig;
  final bool showNoteLines;
  final double segmentLength;
  final double minPixels;
  final List<DrawnLine> lines;
  final DrawnLine? currentLine;
  final DrawingMode drawingMode;
  final ValueChanged<DrawnLine> onCurrentLineUpdated;
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
  bool _isRightClick = false;

  void _handlePanStart(DragStartDetails details, BoxConstraints constraints) {
    if (_isRightClick) return;

    if (widget.drawingMode == DrawingMode.erase) {
      _handleErase(details.localPosition);
      return;
    }

    final point = DrawingPoint(point: details.localPosition);
    final newLine = DrawnLine(path: [point], width: 2.0, color: Colors.black);

    // Trigger initial note
    _processTriggerLogic(
      details.localPosition,
      constraints.maxHeight,
      forceTrigger: true,
    );

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
    final updatedLine = DrawnLine(
      path: updatedList,
      color: widget.currentLine!.color,
      width: widget.currentLine!.width,
    );

    _processTriggerLogic(details.localPosition, constraints.maxHeight);

    widget.onCurrentLineUpdated(updatedLine);
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isRightClick) return;
    if (widget.drawingMode == DrawingMode.erase) return;

    if (widget.currentLine != null) {
      widget.onLineCompleted(widget.currentLine!);
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

  void _processTriggerLogic(
    Offset currentPoint,
    double height, {
    bool forceTrigger = false,
  }) {
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

    // 1. Check Boundary Crossing
    if (_lastTriggerNoteIndex != null && _lastTriggerNoteIndex != noteIndex) {
      shouldTrigger = true;
    }

    // 2. Check Segment Length
    if (_lastTriggerPoint != null) {
      final distance = (currentPoint - _lastTriggerPoint!).distance;
      if (distance >= widget.segmentLength) {
        shouldTrigger = true;
      }
    }

    if (shouldTrigger) {
      // Check if we already triggered this note for this line recently?
      // For now, stateless trigger is fine. State is managed by HomePage.

      // Callback with index AND line source
      widget.onNoteTriggered(noteIndex, widget.currentLine!);

      // Debug
      // debugPrint("Triggered Note Index: $noteIndex from line length ${widget.currentLine!.path.length}");
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
              foregroundPainter: _GridPainter(
                musicConfig: widget.musicConfig,
                showNoteLines: widget.showNoteLines,
              ),
              painter: _LinesPainter(
                lines: widget.lines,
                currentLine: widget.currentLine,
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
      _drawLine(canvas, line);
    }
    if (currentLine != null) {
      _drawLine(canvas, currentLine!);
    }
  }

  void _drawLine(Canvas canvas, DrawnLine line) {
    if (line.path.isEmpty) return;

    final paint = Paint()
      ..color = line.color
      ..strokeWidth = line.width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(line.path.first.point.dx, line.path.first.point.dy);

    for (int i = 1; i < line.path.length; i++) {
      path.lineTo(line.path[i].point.dx, line.path[i].point.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LinesPainter oldDelegate) {
    return true; // Optimize later
  }
}

class _GridPainter extends CustomPainter {
  final MusicConfiguration musicConfig;
  final bool showNoteLines;

  _GridPainter({required this.musicConfig, required this.showNoteLines});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showNoteLines || musicConfig.selectedDegrees.isEmpty) return;

    final activeOctaves = musicConfig.getActiveOctaves();
    if (activeOctaves.isEmpty) return;

    final degreesCount = musicConfig.selectedDegrees.length;
    final totalNotes = activeOctaves.length * degreesCount;

    if (totalNotes == 0) return;

    final noteHeight = size.height / totalNotes;

    // Standard Line Paint
    final standardPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 2.0;

    // Bold Line Paint (for Root/Octave division)
    final boldPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..strokeWidth = 4.0;

    // Draw lines from bottom (lowest pitch) to top (highest pitch)
    // i represents the line index from the bottom (0 = bottom edge, totalNotes = top edge)
    for (int i = 0; i <= totalNotes; i++) {
      final y = size.height - (i * noteHeight);

      // Check if this line is a boundary for the root note (lowest degree)
      // Root note is at indices: 0, degreesCount, 2*degreesCount...
      // Note Index 0 (Lowest) is between Line 0 and Line 1.
      // Note Index 7 (Next Root) is between Line 7 and Line 8.

      // So Line i is bold if it is the bottom (i % count == 0) or top (i % count == 1) of a root note.
      final isRootBoundary = (i % degreesCount == 0) || (i % degreesCount == 1);

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isRootBoundary ? boldPaint : standardPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return showNoteLines != oldDelegate.showNoteLines ||
        musicConfig != oldDelegate.musicConfig;
  }
}
