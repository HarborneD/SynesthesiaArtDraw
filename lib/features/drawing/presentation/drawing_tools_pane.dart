import 'package:flutter/material.dart';
import '../domain/drawing_mode.dart';

class DrawingToolsPane extends StatefulWidget {
  final DrawingMode currentMode;
  final ValueChanged<DrawingMode> onModeChanged;
  final double segmentLength;
  final ValueChanged<double> onSegmentLengthChanged;
  final double minPixels;
  final ValueChanged<double> onMinPixelsChanged;

  const DrawingToolsPane({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.segmentLength,
    required this.onSegmentLengthChanged,
    required this.minPixels,
    required this.onMinPixelsChanged,
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
          _buildSettingsSection(),
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
        Row(
          children: [
            _buildModeButton(DrawingMode.line, Icons.edit, 'Line'),
            const SizedBox(width: 10),
            _buildModeButton(DrawingMode.gradient, Icons.gradient, 'Gradient'),
          ],
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
