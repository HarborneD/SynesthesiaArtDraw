import 'package:flutter/material.dart';
import '../../midi/domain/music_configuration.dart'; // Import for SoundFontChannel

class ToolbarWidget extends StatelessWidget {
  final ValueChanged<int?> onPaneSelected;
  final int? selectedPaneIndex;

  // New: Channel Selection
  final int selectedChannelIndex;
  final ValueChanged<int> onChannelSelected;
  final List<SoundFontChannel> channels; // New Prop

  // New: Gradient Tool Props
  final bool isGradientToolActive;
  final VoidCallback onGradientToolSelected;

  // New: Eraser Tool Props
  final bool isEraserToolActive;
  final VoidCallback onEraserToolSelected;

  const ToolbarWidget({
    super.key,
    required this.onPaneSelected,
    required this.selectedPaneIndex,
    required this.selectedChannelIndex,
    required this.onChannelSelected,
    required this.isGradientToolActive,
    required this.onGradientToolSelected,
    required this.isEraserToolActive,
    required this.onEraserToolSelected,
    required this.channels,
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

          const Divider(color: Colors.white24, height: 20),

          // Channel Selector (1-8) + Tools
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...List.generate(
                    channels.length,
                    (index) => _buildChannelButton(index),
                  ),

                  const SizedBox(height: 10),

                  // Gradient Tool
                  IconButton(
                    icon: const Icon(Icons.gradient),
                    color: isGradientToolActive
                        ? Colors.tealAccent
                        : Colors.white54,
                    onPressed: onGradientToolSelected,
                    tooltip: 'Gradient Tool (0 / G)',
                  ),

                  // Eraser Tool
                  IconButton(
                    icon: const Icon(Icons.auto_fix_normal), // or backspace?
                    color: isEraserToolActive
                        ? Colors.tealAccent
                        : Colors.white54,
                    onPressed: onEraserToolSelected,
                    tooltip: 'Eraser Tool (E)',
                  ),
                ],
              ),
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
    // Get Color from Channel
    Color channelColor = Colors.grey;
    if (index < channels.length) {
      channelColor = Color(channels[index].colorValue); // Use stored color
    }

    // Ensure visibility on dark background if color is too dark?
    // Usually user picks bright colors for neon, but let's trust the user.

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
            color: isSelected
                ? Colors.white24
                : Colors.transparent, // Highlight background if selected
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : channelColor, // Border matches brush color or White if selected
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Text(
            (index + 1).toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : channelColor, // Text matches brush color
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
