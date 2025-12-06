import 'package:flutter/material.dart';

import '../domain/music_configuration.dart';

class MidiSettingsPane extends StatefulWidget {
  final MusicConfiguration config;
  final ValueChanged<MusicConfiguration> onConfigChanged;
  final bool isSustainOn;
  final ValueChanged<bool> onSustainChanged;

  const MidiSettingsPane({
    super.key,
    required this.config,
    required this.onConfigChanged,
    required this.isSustainOn,
    required this.onSustainChanged,
  });

  @override
  State<MidiSettingsPane> createState() => _MidiSettingsPaneState();
}

class _MidiSettingsPaneState extends State<MidiSettingsPane> {
  @override
  void initState() {
    super.initState();
    // Initialization is now handled by MusicConfiguration default constructor,
    // but if we somehow got an empty list, we could update it.
    // Generally, the parent (HomePage) holds the config.
  }

  void _updateSelectedDegrees(String key, String scaleName) {
    final degrees = MusicConfiguration.getDegreesInScale(key, scaleName);
    widget.onConfigChanged(
      widget.config.copyWith(
        selectedKey: key,
        selectedScale: scaleName,
        selectedDegrees: degrees,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate available degrees for the CURRENT config to display in the list
    final availableDegrees = MusicConfiguration.getDegreesInScale(
      widget.config.selectedKey,
      widget.config.selectedScale,
    );

    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text('Midi Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          SwitchListTile(
            title: const Text('Sustain Notes'),
            subtitle: const Text('Hold notes until next trigger or line end'),
            value: widget.isSustainOn,
            onChanged: widget.onSustainChanged,
          ),
          const Divider(),

          // --- Music Settings ---
          Text('Music Theory', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Text('Tempo: ${widget.config.tempo.toInt()} BPM'),
          Slider(
            value: widget.config.tempo,
            min: 40,
            max: 240,
            divisions: 200,
            label: widget.config.tempo.round().toString(),
            onChanged: (value) =>
                widget.onConfigChanged(widget.config.copyWith(tempo: value)),
          ),
          const SizedBox(height: 10),

          Text('Octaves: ${widget.config.octaves.toInt()}'),
          Slider(
            value: widget.config.octaves,
            min: 1,
            max: 8,
            divisions: 7,
            label: widget.config.octaves.round().toString(),
            onChanged: (value) =>
                widget.onConfigChanged(widget.config.copyWith(octaves: value)),
          ),

          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Key'),
            value: widget.config.selectedKey,
            items: MusicConfiguration.keys
                .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                .toList(),
            onChanged: (val) {
              if (val != null && val != widget.config.selectedKey) {
                _updateSelectedDegrees(val, widget.config.selectedScale);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Scale'),
            value: widget.config.selectedScale,
            items: MusicConfiguration.scaleNameMap.keys
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) {
              if (val != null && val != widget.config.selectedScale) {
                _updateSelectedDegrees(widget.config.selectedKey, val);
              }
            },
          ),

          const SizedBox(height: 20),
          const Text('Included Scale Degrees:'),
          Wrap(
            spacing: 8.0,
            children: availableDegrees.map((degree) {
              final isSelected = widget.config.selectedDegrees.contains(degree);
              return FilterChip(
                label: Text(degree),
                selected: isSelected,
                onSelected: (bool selected) {
                  final newDegrees = List<String>.from(
                    widget.config.selectedDegrees,
                  );
                  if (selected) {
                    newDegrees.add(degree);
                  } else {
                    newDegrees.remove(degree);
                  }
                  widget.onConfigChanged(
                    widget.config.copyWith(selectedDegrees: newDegrees),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
