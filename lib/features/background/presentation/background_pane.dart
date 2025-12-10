import 'package:flutter/material.dart';
import 'package:synesthesia_art_draw/features/drawing/domain/gradient_stroke.dart';
import 'package:synesthesia_art_draw/features/drawing/presentation/gradient_tools_pane.dart';
import '../../drone/presentation/drone_settings_pane.dart';
import '../../midi/domain/music_configuration.dart';

class BackgroundPane extends StatelessWidget {
  final MusicConfiguration config;
  final ValueChanged<MusicConfiguration> onConfigChanged;

  // Drone specific
  final Color currentDetectedColor;
  final List<String> availableSoundFonts;

  // Gradient specific
  final List<GradientStroke> gradientStrokes;
  final Function(int, GradientStroke) onStrokeUpdated;
  final Function(int) onStrokeDeleted;

  const BackgroundPane({
    super.key,
    required this.config,
    required this.onConfigChanged,
    required this.currentDetectedColor,
    required this.availableSoundFonts,
    required this.gradientStrokes,
    required this.onStrokeUpdated,
    required this.onStrokeDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Background Environment',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // 1. Drone Settings (Ambient Sound)
          DroneSettingsPane(
            config: config,
            onConfigChanged: onConfigChanged,
            currentDetectedColor: currentDetectedColor,
            availableSoundFonts: availableSoundFonts,
          ),

          const Divider(height: 40),

          // 2. Gradient Tools (Background Visuals)
          const Text(
            'Gradient Fields',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 300,
            child: GradientToolsPane(
              strokes: gradientStrokes,
              onStrokeUpdated: onStrokeUpdated,
              onStrokeDeleted: onStrokeDeleted,
            ),
          ),
        ],
      ),
    );
  }
}
