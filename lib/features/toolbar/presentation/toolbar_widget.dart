import 'package:flutter/material.dart';

class ToolbarWidget extends StatelessWidget {
  final ValueChanged<int?> onPaneSelected;
  final int? selectedPaneIndex;

  const ToolbarWidget({
    super.key,
    required this.onPaneSelected,
    required this.selectedPaneIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      color: Colors.blueGrey[900],
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildToolbarButton(
            context,
            icon: Icons.brush,
            label: 'Draw',
            index: 0,
          ),
          _buildToolbarButton(
            context,
            icon: Icons.piano,
            label: 'Midi',
            index: 1,
          ),
          _buildToolbarButton(
            context,
            icon: Icons.library_music,
            label: 'Instr',
            index: 2,
          ),
          _buildToolbarButton(
            context,
            icon: Icons.save,
            label: 'Library',
            index: 3,
          ),
          const Spacer(),
          _buildToolbarButton(
            context,
            icon: Icons.settings,
            label: 'Settings',
            index: 4,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = selectedPaneIndex == index;
    return IconButton(
      onPressed: () => onPaneSelected(isSelected ? null : index),
      icon: Icon(icon, color: isSelected ? Colors.white : Colors.white54),
      tooltip: label,
    );
  }
}
