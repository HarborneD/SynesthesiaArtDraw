import 'package:flutter/material.dart';
import '../domain/drawing_mode.dart';

class DrawingToolsPane extends StatefulWidget {
  final DrawingMode currentMode;
  final ValueChanged<DrawingMode> onModeChanged;

  const DrawingToolsPane({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  State<DrawingToolsPane> createState() => _DrawingToolsPaneState();
}

class _DrawingToolsPaneState extends State<DrawingToolsPane> {
  double _segmentLength = 100.0;
  double _minPixels = 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Drawing Tools', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          Text('Mode', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _buildModeButton(
            context,
            mode: DrawingMode.line,
            label: 'Draw Line',
            icon: Icons.timeline,
          ),
          const SizedBox(height: 10),
          _buildModeButton(
            context,
            mode: DrawingMode.gradient,
            label: 'Draw Gradient',
            icon: Icons.gradient,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          Text('Settings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Text('Segment Length: ${_segmentLength.toInt()}px'),
          Slider(
            value: _segmentLength,
            min: 10,
            max: 500,
            divisions: 49,
            label: _segmentLength.round().toString(),
            onChanged: (value) => setState(() => _segmentLength = value),
          ),
          const SizedBox(height: 10),
          Text('Min Pixels: ${_minPixels.toInt()}px'),
          Slider(
            value: _minPixels,
            min: 1,
            max: 50,
            divisions: 49,
            label: _minPixels.round().toString(),
            onChanged: (value) => setState(() => _minPixels = value),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required DrawingMode mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = widget.currentMode == mode;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: () => widget.onModeChanged(mode),
        style: FilledButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [Icon(icon), const SizedBox(width: 8), Text(label)],
          ),
        ),
      ),
    );
  }
}
