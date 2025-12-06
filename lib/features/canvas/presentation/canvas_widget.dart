import 'package:flutter/material.dart';
import '../../midi/domain/music_configuration.dart';

class CanvasWidget extends StatelessWidget {
  final MusicConfiguration musicConfig;
  final bool showNoteLines;

  const CanvasWidget({
    super.key,
    required this.musicConfig,
    required this.showNoteLines,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _GridPainter(
        musicConfig: musicConfig,
        showNoteLines: showNoteLines,
      ),
      child: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
      ),
    );
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

      // Use a slightly adjusted Y for the bottom-most line to be visible if needed,
      // or just rely on standard drawing (it might clip exactly at height).
      // Since we want it 'bold', drawing closer to edge is fine.

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
