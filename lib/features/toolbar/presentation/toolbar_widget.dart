import 'package:flutter/material.dart';

class ToolbarWidget extends StatelessWidget {
  final ValueChanged<int?> onPaneSelected;
  final int? selectedPaneIndex;

  // New: Channel Selection
  final int selectedChannelIndex;
  final ValueChanged<int> onChannelSelected;

  // New: Gradient Tool Props
  final bool isGradientToolActive;
  final VoidCallback onGradientToolSelected;

  const ToolbarWidget({
    super.key,
    required this.onPaneSelected,
    required this.selectedPaneIndex,
    required this.selectedChannelIndex,
    required this.onChannelSelected,
    required this.isGradientToolActive,
    required this.onGradientToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70, // Slightly wider for channel numbers
      color: Colors.blueGrey[900],
      child: Column(
        children: [
          const SizedBox(height: 16),
          // 1. Music Settings
          _buildToolbarButton(
            context,
            icon: Icons.tune,
            label: 'Music Settings',
            index: 0,
          ),
          // 2. Sequencer
          _buildToolbarButton(
            context,
            icon: Icons.grid_4x4,
            label: 'Sequencer',
            index: 1,
          ),
          const SizedBox(height: 10),

          // 3. Background (Gradient + Drone)
          _buildToolbarButton(
            context,
            icon: Icons.landscape, // or layers
            label: 'Background',
            index: 2,
          ),
          // 4. Foreground / Channel Data
          _buildToolbarButton(
            context,
            icon: Icons.brush,
            label: 'Channel Settings',
            index: 3,
          ),

          const Divider(color: Colors.white24, height: 20),

          // Channel Selector (1-8)
          Expanded(
            child: ListView.builder(
              itemCount: 8,
              padding: EdgeInsets.zero,
              itemBuilder: (context, idx) {
                return _buildChannelButton(idx);
              },
            ),
          ),

          // Gradient Tool Icon (Now below Channel 8 in the flow)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
            child: IconButton(
              icon: const Icon(Icons.gradient),
              color: isGradientToolActive
                  ? Colors.tealAccent
                  : Colors.white54, // Highlight active state
              onPressed: onGradientToolSelected,
              tooltip: 'Gradient Tool (0)',
            ),
          ),

          const Divider(color: Colors.white24, height: 20),

          const Divider(color: Colors.white24, height: 20),

          // 5. Library (moved down)
          _buildToolbarButton(
            context,
            icon: Icons.folder_open,
            label: 'Library',
            index: 4,
          ),

          // 6. Global Settings
          _buildToolbarButton(
            context,
            icon: Icons.settings,
            label: 'App Settings',
            index: 5,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChannelButton(int index) {
    final isSelected = selectedChannelIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: GestureDetector(
        onTap: () => onChannelSelected(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.tealAccent : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey,
              width: 1,
            ),
          ),
          child: Text(
            (index + 1).toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.white70,
            ),
          ),
        ),
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
