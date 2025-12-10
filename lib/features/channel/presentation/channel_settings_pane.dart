import 'package:flutter/material.dart';
import '../../midi/domain/music_configuration.dart';

class ChannelSettingsPane extends StatelessWidget {
  final SoundFontChannel channel;
  final ValueChanged<SoundFontChannel> onChannelChanged;
  final List<String> availableSoundFonts;

  const ChannelSettingsPane({
    super.key,
    required this.channel,
    required this.onChannelChanged,
    required this.availableSoundFonts,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Channel ${channel.program} Settings', // Simplified title for now
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Channel Volume
              SizedBox(
                width: 150,
                child: Column(
                  children: [
                    const Text("Vol", style: TextStyle(fontSize: 12)),
                    Slider(
                      value: channel.channelVolume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) => onChannelChanged(
                        channel.copyWith(channelVolume: val),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 1. Drawing / Brush Settings
          _buildSectionHeader(Icons.brush, "Brush & trigger"),
          _buildBrushSettings(context),

          const Divider(height: 30),

          // 2. Sound Settings
          _buildSectionHeader(Icons.music_note, "Sound Source"),
          _buildSoundSettings(context),

          const Divider(height: 30),

          // 3. Effects
          _buildSectionHeader(Icons.auto_fix_high, "Effects"),
          _buildEffectsSettings(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBrushSettings(BuildContext context) {
    return Column(
      children: [
        // Color Picker (Compact)
        const SizedBox(height: 10),
        _buildColorSelector(),
        const SizedBox(height: 10),

        // Trigger Config
        SwitchListTile(
          title: const Text("Trigger on Boundary"),
          subtitle: const Text("Play sound when line crosses play-line"),
          value: channel.triggerOnBoundary,
          onChanged: (val) =>
              onChannelChanged(channel.copyWith(triggerOnBoundary: val)),
          contentPadding: EdgeInsets.zero,
        ),

        // Sliders
        _buildSlider(
          "Brush Spread",
          channel.brushSpread,
          0.0,
          20.0,
          (val) => onChannelChanged(channel.copyWith(brushSpread: val)),
        ),
        _buildSlider(
          "Opacity",
          channel.brushOpacity,
          0.1,
          1.0,
          (val) => onChannelChanged(channel.copyWith(brushOpacity: val)),
        ),
        _buildSlider(
          "Bristle Count",
          channel.bristleCount.toDouble(),
          1.0,
          80.0,
          (val) =>
              onChannelChanged(channel.copyWith(bristleCount: val.toInt())),
        ),
        SwitchListTile(
          title: const Text("Neon Glow"),
          value: channel.useNeonGlow,
          onChanged: (val) =>
              onChannelChanged(channel.copyWith(useNeonGlow: val)),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildSoundSettings(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'SoundFont'),
          value: availableSoundFonts.contains(channel.soundFont)
              ? channel.soundFont
              : availableSoundFonts.firstOrNull,
          isExpanded: true,
          items: availableSoundFonts
              .map(
                (sf) => DropdownMenuItem(
                  value: sf,
                  child: Text(
                    sf.replaceAll('.sf2', ''),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              onChannelChanged(channel.copyWith(soundFont: val));
            }
          },
        ),
        const SizedBox(height: 10),
        // Simple Program Slider for now
        _buildSlider(
          "Program Index",
          channel.program.toDouble(),
          0.0,
          127.0,
          (val) => onChannelChanged(channel.copyWith(program: val.toInt())),
        ),
      ],
    );
  }

  Widget _buildEffectsSettings(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text("Sustain"),
          value: channel.isSustainOn,
          onChanged: (val) =>
              onChannelChanged(channel.copyWith(isSustainOn: val)),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text("Delay / Echo"),
          value: channel.isDelayOn,
          onChanged: (val) =>
              onChannelChanged(channel.copyWith(isDelayOn: val)),
          contentPadding: EdgeInsets.zero,
        ),
        if (channel.isDelayOn) ...[
          _buildSlider(
            "Delay Time",
            channel.delayTime,
            0.0,
            2000.0,
            (val) => onChannelChanged(channel.copyWith(delayTime: val)),
          ),
          _buildSlider(
            "Feedback",
            channel.delayFeedback,
            0.0,
            0.95,
            (val) => onChannelChanged(channel.copyWith(delayFeedback: val)),
          ),
        ],
        _buildSlider(
          "Reverb",
          channel.reverbLevel,
          0.0,
          1.0,
          (val) => onChannelChanged(channel.copyWith(reverbLevel: val)),
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
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label)),
        Expanded(
          flex: 4,
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
        SizedBox(width: 40, child: Text(value.toStringAsFixed(1))),
      ],
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
      Colors.cyan,
      Colors.lime,
      Colors.indigo,
      Colors.amber,
      Colors.brown,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = channel.colorValue == color.value;
        return GestureDetector(
          onTap: () =>
              onChannelChanged(channel.copyWith(colorValue: color.value)),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.grey,
                width: isSelected ? 3.0 : 1.0,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
