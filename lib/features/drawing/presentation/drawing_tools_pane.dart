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

  // Color Props
  final Color selectedColor;
  final ValueChanged<Color>? onColorChanged;

  // Trigger Props
  final bool triggerOnBoundary;
  final ValueChanged<bool>? onTriggerOnBoundaryChanged;

  // Brush Props
  final double brushSpread;
  final ValueChanged<double>? onBrushSpreadChanged;
  final double brushOpacity;
  final ValueChanged<double>? onBrushOpacityChanged;
  final int bristleCount;
  final ValueChanged<int>? onBristleCountChanged;
  final bool useNeonGlow;
  final ValueChanged<bool>? onNeonGlowChanged;

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
    this.selectedColor = Colors.black,
    this.onColorChanged,
    this.triggerOnBoundary = false,
    this.onTriggerOnBoundaryChanged,

    // Brush Defaults
    this.brushSpread = 1.0,
    this.onBrushSpreadChanged,
    this.brushOpacity = 0.5,
    this.onBrushOpacityChanged,
    this.bristleCount = 8,
    this.onBristleCountChanged,
    this.useNeonGlow = true,
    this.onNeonGlowChanged,
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Drawing Tools',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildToolSection(),

            // Divider removed (was possibly duplicate or unnecessary if section is hidden)
            if (widget.currentMode == DrawingMode.line) ...[
              const Divider(height: 30),
              const Text(
                'Line Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildColorSelector(),
              const Divider(height: 30),
            ],

            _buildSettingsSection(),

            if (widget.currentMode == DrawingMode.gradient) ...[
              const Divider(height: 30),
              const Text(
                'Gradient Fields',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                // Use SizedBox for fixed height content inside ScrollView if needed, or LayoutBuilder
                height:
                    300, // Give it a fixed height for now as Expanded won't work in ScrollView
                child: GradientToolsPane(
                  strokes: widget.gradientStrokes,
                  onStrokeUpdated: widget.onStrokeUpdated!,
                  onStrokeDeleted: widget.onStrokeDeleted!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        // Mode Buttons in a single row
        Row(
          children: [
            Expanded(
              child: _buildModeButton(DrawingMode.line, Icons.edit, 'Line'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModeButton(
                DrawingMode.gradient,
                Icons.gradient,
                'Gradient',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModeButton(
                DrawingMode.erase,
                Icons.cleaning_services,
                'Erase',
              ),
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
    if (widget.currentMode != DrawingMode.line) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Trigger Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Boundary-Crossing Notes"),
            Switch(
              value: widget.triggerOnBoundary,
              onChanged: widget.onTriggerOnBoundaryChanged,
            ),
          ],
        ),
        const Divider(),
        _buildSlider(
          'Segment Length (Collision)',
          widget.segmentLength,
          10.0,
          400.0,
          widget.onSegmentLengthChanged,
        ),
        const SizedBox(height: 10),
        _buildSlider(
          'Min Pixels (Drawing Precision)',
          widget.minPixels,
          1.0,
          10.0,
          widget.onMinPixelsChanged,
        ),
        const Divider(),
        const Text(
          "Brush Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SwitchListTile(
          title: const Text("Neon Glow"),
          value: widget.useNeonGlow,
          onChanged: widget.onNeonGlowChanged,
          contentPadding: EdgeInsets.zero,
        ),
        _buildSlider(
          "Spread (Jitter)",
          widget.brushSpread,
          0.0,
          20.0,
          widget.onBrushSpreadChanged!,
        ),
        _buildSlider(
          "Opacity",
          widget.brushOpacity,
          0.1,
          1.0,
          widget.onBrushOpacityChanged!,
        ),
        _buildSlider(
          "Bristles (Density)",
          widget.bristleCount.toDouble(),
          1.0,
          40.0,
          (val) => widget.onBristleCountChanged!(val.toInt()),
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
    return Tooltip(
      message: label,
      child: ElevatedButton(
        onPressed: () => widget.onModeChanged(mode),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
          foregroundColor: isSelected ? Colors.white : null,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Icon(icon),
      ),
    );
  }

  Widget _buildColorSelector() {
    final colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = widget.selectedColor == color;
        return GestureDetector(
          onTap: () => widget.onColorChanged?.call(color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.grey,
                width: isSelected ? 3.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.grey)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
