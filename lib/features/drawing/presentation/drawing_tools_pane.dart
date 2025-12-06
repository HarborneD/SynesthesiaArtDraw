import 'package:flutter/material.dart';
import '../domain/drawing_mode.dart';
import '../domain/gradient_stroke.dart';
import 'gradient_tools_pane.dart';

class DrawingToolsPane extends StatefulWidget {
  final DrawingMode currentMode;
  final ValueChanged<DrawingMode> onModeChanged;
  final double segmentLength;
  final ValueChanged<double> onSegmentLengthChanged;
  final double minPixels;
  final ValueChanged<double> onMinPixelsChanged;
  final VoidCallback onClearAll;

  // Gradient Props
  final List<GradientStroke> gradientStrokes;
  final Function(int index, GradientStroke newStroke)? onStrokeUpdated;
  final Function(int index)? onStrokeDeleted;

  const DrawingToolsPane({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.segmentLength,
    required this.onSegmentLengthChanged,
    required this.minPixels,
    required this.onMinPixelsChanged,
    required this.onClearAll,
    this.gradientStrokes = const [],
    this.onStrokeUpdated,
    this.onStrokeDeleted,
  });

  @override
  State<DrawingToolsPane> createState() => _DrawingToolsPaneState();
}

class _DrawingToolsPaneState extends State<DrawingToolsPane> {
  // Removed internal state for segmentLength and minPixels

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Drawing Tools',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildToolSection(),
          const Divider(height: 30),
          const Divider(height: 30),
          _buildSettingsSection(),

          if (widget.currentMode == DrawingMode.gradient) ...[
            const Divider(height: 30),
            const Text(
              'Gradient Fields',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GradientToolsPane(
                strokes: widget.gradientStrokes,
                onStrokeUpdated: widget.onStrokeUpdated!,
                onStrokeDeleted: widget.onStrokeDeleted!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildModeButton(DrawingMode.line, Icons.edit, 'Line'),
            _buildModeButton(DrawingMode.gradient, Icons.gradient, 'Gradient'),
            _buildModeButton(
              DrawingMode.erase,
              Icons.cleaning_services,
              'Erase',
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onClearAll,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Clear All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red.shade900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildSlider(
          'Segment Length',
          widget.segmentLength,
          10,
          500,
          widget.onSegmentLengthChanged,
        ),
        _buildSlider(
          'Min Pixels',
          widget.minPixels,
          1,
          50,
          widget.onMinPixelsChanged,
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}'),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }

  Widget _buildModeButton(DrawingMode mode, IconData icon, String label) {
    final isSelected = widget.currentMode == mode;
    return ElevatedButton.icon(
      onPressed: () => widget.onModeChanged(mode),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
        foregroundColor: isSelected ? Colors.white : null,
      ),
    );
  }
}
