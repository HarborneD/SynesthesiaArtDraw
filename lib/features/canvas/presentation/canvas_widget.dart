import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui' as ui;
import '../../midi/domain/music_configuration.dart';
import '../../drawing/domain/drawn_line.dart';
import '../../drawing/domain/gradient_stroke.dart';
import 'dart:math';
import '../../canvas/presentation/background_gradient_painter.dart';

import '../../drawing/domain/drawing_mode.dart';

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
  final int selectedChannelIndex; // New Prop

  // Play Line Props
  final bool showPlayLine;
  final Animation<double>? playLineAnimation;

  // Callbacks
  final void Function(int, DrawnLine) onNoteTriggered;

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
    required this.selectedChannelIndex, // Require this
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
    this.showPlayLine = false,
    this.playLineAnimation,
  });

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  // ... (Keep existing State vars)
  Offset? _lastTriggerPoint;
  int? _lastTriggerNoteIndex;
  // DateTime? _lastDirectionTriggerTime; // Removed in favor of Hysteresis
  bool _isTurning = false;

  bool _isRightClick = false;

  // Raster Cache
  ui.Image? _backingStore;
  int _lastBakedLineCount = 0;
  Size? _lastCanvasSize;

  @override
  void didUpdateWidget(CanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Logic to update backing store if lines changed
    // We defer the actual update to the build/layout phase where we have Size,
    // OR we do it here if we stored the size.
    // Actually, safer to check in build or a specific method called after build?
    // But we need safe access to 'lines'.

    // If we have a size, we can try to update.
    if (_lastCanvasSize != null) {
      _checkAndUpdateBackingStore(widget.lines, _lastCanvasSize!);
    }
  }

  @override
  void dispose() {
    _backingStore?.dispose();
    super.dispose();
  }

  // ... (Keep _checkAndUpdateBackingStore, _rebakeAll, _bakeNewLines)
  Future<void> _checkAndUpdateBackingStore(
    List<DrawnLine> lines,
    Size size,
  ) async {
    // 1. Check for Resize
    if (_backingStore == null ||
        _lastCanvasSize == null ||
        size != _lastCanvasSize) {
      _lastCanvasSize = size;
      await _rebakeAll(lines, size);
      return;
    }

    // 2. Check for Additions (Optimization)
    if (lines.length > _lastBakedLineCount) {
      // Bake ONLY the new lines
      final newLines = lines.sublist(_lastBakedLineCount);
      await _bakeNewLines(newLines, size);
      _lastBakedLineCount = lines.length;
      if (mounted) setState(() {}); // Trigger repaint with new image
      return;
    }

    // 3. Check for Deletions/Modifications (Full Redraw)
    if (lines.length < _lastBakedLineCount) {
      // Undo/Erase happened
      await _rebakeAll(lines, size);
      return;
    }

    // 4. Check for mutations (same length but content changed)?
    // We assume immutability for performance, except maybe last line modification?
    // If strictly appending, the above is enough.
    // If lines can be modified in place (unlikely in this arch), we'd need hash checks.
    // For now, assume length check is sufficient for Append/Undo.
  }

  Future<void> _rebakeAll(List<DrawnLine> lines, Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    // Draw all lines
    final painter = _CompletedLinesPainter(lines: lines);
    // We need to exposing the draw method or just use it?
    // _CompletedLinesPainter encapsulates the draw logic.
    // Let's refactor _CompletedLinesPainter to be a static helper or expose a regular method.
    // OR just instantiate it and call generic paint?
    // CustomPainter.paint takes a Canvas and Size.
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final newImage = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    if (mounted) {
      setState(() {
        _backingStore?.dispose(); // Dispose old
        _backingStore = newImage;
        _lastBakedLineCount = lines.length;
      });
    } else {
      newImage.dispose();
    }
  }

  Future<void> _bakeNewLines(List<DrawnLine> newLines, Size size) async {
    if (_backingStore == null)
      return _rebakeAll(newLines, size); // Should not happen if logic matches

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    // 1. Draw existing image
    canvas.drawImage(_backingStore!, Offset.zero, Paint());

    // 2. Draw new lines
    final painter = _CompletedLinesPainter(lines: newLines);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final newImage = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    if (mounted) {
      setState(() {
        _backingStore?.dispose();
        _backingStore = newImage;
        // _lastBakedLineCount is updated by caller
      });
    } else {
      newImage.dispose();
    }
  }

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
      channelIndex:
          widget.selectedChannelIndex, // Set correct channel instantly
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
      _isTurning = false;
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

            // Hysteresis Logic:
            // Trigger only if we are NOT currently in a "turning" state.
            // Reset the state when the angle drops significantly (e.g. below 50% of threshold).

            if (!_isTurning) {
              if (diffDegrees > widget.musicConfig.directionChangeThreshold) {
                shouldTrigger = true;
                _isTurning = true;
                // debugPrint("Direction Trigger! Angle: ${diffDegrees.toStringAsFixed(1)}");
              }
            } else {
              // We are already in a turn. Check if we have straightened out enough to reset.
              // Using 50% hysteresis factor.
              if (diffDegrees <
                  (widget.musicConfig.directionChangeThreshold * 0.5)) {
                _isTurning = false;
                // debugPrint("Turn Reset. Angle: ${diffDegrees.toStringAsFixed(1)}");
              }
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
        // Ensure backing store is initialized for this size
        // We can't do async work here easily without flickering.
        // But we can trigger it.
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (_backingStore == null || size != _lastCanvasSize) {
          // First frame or resize: Schedule bake
          // Using addPostFrameCallback to avoid build-phase setState
          if (_lastCanvasSize != size) {
            _lastCanvasSize = size;
            _lastBakedLineCount = 0; // Force full rebake
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAndUpdateBackingStore(widget.lines, size);
            });
          }
        }

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
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Background Layer (Cached)
                RepaintBoundary(
                  child: CustomPaint(
                    painter: BackgroundGradientPainter(
                      shader: widget.backgroundShader,
                      strokes: widget.gradientStrokes,
                    ),
                  ),
                ),

                // 2. Completed Lines Layer (Rasterized)
                // Draw the backed image
                if (_backingStore != null)
                  CustomPaint(
                    painter: _RasterImagePainter(image: _backingStore!),
                  )
                else
                  // Fallback while baking? Or just transparent?
                  // Transparent is fine, it will flash briefly.
                  const SizedBox.shrink(),

                // 3. Active Line Layer (Not Cached - Dynamic)
                CustomPaint(
                  painter: _ActiveLinePainter(currentLine: widget.currentLine),
                ),

                // 4. Overlay/Grid Layer (Cached)
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _OverlayPainter(
                      musicConfig: widget.musicConfig,
                      showNoteLines: widget.showNoteLines,
                      gradientStrokes: widget.showGradientOverlays
                          ? widget.gradientStrokes
                          : [],
                      showPlayLine: widget.showPlayLine,
                      playLineAnimation: widget.playLineAnimation,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompletedLinesPainter extends CustomPainter {
  final List<DrawnLine> lines;

  _CompletedLinesPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      if (line.path.isEmpty) continue;
      _drawLine(canvas, line);
    }
  }

  void _drawLine(Canvas canvas, DrawnLine line) {
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

      canvas.drawPath(line.smoothPath, glowPaint);
    }

    // 2. Draw Bristles (Paint Brush Effect)
    // Use cached offsets and opacities
    final baseWidth = line.width;

    // Safety check in case cache length mismatch (shouldn't happen with correct logic)
    final count = min(line.bristleOffsets.length, line.bristleOpacities.length);

    for (int i = 0; i < count; i++) {
      final offset = line.bristleOffsets[i];
      final opacity = line.bristleOpacities[i];

      // Scale opacity by line's opacity setting
      final finalOpacity = (opacity * line.opacity).clamp(0.0, 1.0);

      final bristlePaint = Paint()
        ..color = line.color.withOpacity(finalOpacity)
        ..strokeWidth = max(1.0, baseWidth / 3)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.drawPath(line.smoothPath, bristlePaint);
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

      canvas.drawPath(line.smoothPath, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompletedLinesPainter oldDelegate) {
    // Only repaint if the lines list changes (reference or length)
    // Deep comparison is expensive, so we rely on reference + length + immutability convention.
    // Ideally we should use a stronger check, but for now length check helps.
    // Also check if any property of last line changed?
    // Since we add lines immutably, reference check on list might be false if list is mutated.
    // The parent passes `widget.lines`. If it changes, we repaint.
    return oldDelegate.lines != lines ||
        oldDelegate.lines.length != lines.length;
  }
}

class _ActiveLinePainter extends CustomPainter {
  final DrawnLine? currentLine;

  _ActiveLinePainter({required this.currentLine});

  @override
  void paint(Canvas canvas, Size size) {
    if (currentLine != null && currentLine!.path.isNotEmpty) {
      _drawLine(canvas, currentLine!);
    }
  }

  void _drawLine(Canvas canvas, DrawnLine line) {
    // Duplicated logic for now to keep isolated. Could refactor to Mixin.
    // Use cached values

    if (line.useNeonGlow) {
      final glowPaint = Paint()
        ..color = line.color.withOpacity(0.6)
        ..strokeWidth = line.width * 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawPath(line.smoothPath, glowPaint);
    }

    final baseWidth = line.width;
    final count = min(line.bristleOffsets.length, line.bristleOpacities.length);

    for (int i = 0; i < count; i++) {
      final offset = line.bristleOffsets[i];
      final opacity = line.bristleOpacities[i];
      final finalOpacity = (opacity * line.opacity).clamp(0.0, 1.0);

      final bristlePaint = Paint()
        ..color = line.color.withOpacity(finalOpacity)
        ..strokeWidth = max(1.0, baseWidth / 3)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.drawPath(line.smoothPath, bristlePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ActiveLinePainter oldDelegate) {
    return true; // Always repaint active line
  }
}

class _OverlayPainter extends CustomPainter {
  final MusicConfiguration musicConfig;
  final bool showNoteLines;
  final List<GradientStroke> gradientStrokes;
  final bool showPlayLine;
  final Animation<double>? playLineAnimation;

  _OverlayPainter({
    required this.musicConfig,
    required this.showNoteLines,
    required this.gradientStrokes,
    required this.showPlayLine,
    this.playLineAnimation,
  }) : super(repaint: playLineAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    // 0. Draw Play Line
    if (showPlayLine && playLineAnimation != null) {
      final x = playLineAnimation!.value * size.width;
      final linePaint = Paint()
        ..color = Colors.lightGreenAccent
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Draw Grid
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
        oldDelegate.gradientStrokes != gradientStrokes ||
        oldDelegate.showPlayLine != showPlayLine ||
        oldDelegate.playLineAnimation != playLineAnimation;
  }
}

class _RasterImagePainter extends CustomPainter {
  final ui.Image image;
  _RasterImagePainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant _RasterImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
