import 'package:flutter/material.dart';
import 'package:tonic/tonic.dart';

class MidiSettingsPane extends StatefulWidget {
  const MidiSettingsPane({super.key});

  @override
  State<MidiSettingsPane> createState() => _MidiSettingsPaneState();
}

class _MidiSettingsPaneState extends State<MidiSettingsPane> {
  double _octaves = 4;
  double _tempo = 92.0;

  // Music Theory State
  String _selectedKey = 'C';
  String _selectedScale = 'Major'; // Display name
  List<String> _selectedDegrees = [];

  final List<String> _keys = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  // Map Display Name -> Tonic Pattern Name
  final Map<String, String> _scaleNameMap = {
    'Major': 'Diatonic Major',
    'Minor': 'Natural Minor',
    'Dorian': 'Dorian',
    'Phrygian': 'Phrygian',
    'Lydian': 'Lydian',
    'Mixolydian': 'Mixolydian',
    'Locrian': 'Locrian',
    'Pentatonic Major': 'Major Pentatonic',
    'Pentatonic Minor': 'Minor Pentatonic',
    'Chromatic':
        'Chromatic', // Handled manually or need to check if exists as '12-Tone' etc
  };

  @override
  void initState() {
    super.initState();
    _updateSelectedDegrees();
  }

  void _updateSelectedDegrees() {
    if (_selectedDegrees.isEmpty) {
      _selectedDegrees = _getDegreesInScale();
    }
  }

  List<String> _getDegreesInScale() {
    // Special case for Chromatic if Tonic doesn't have it
    if (_selectedScale == 'Chromatic') {
      final root = Pitch.parse(_selectedKey);
      // Return all 12 notes starting from root is unnecessary for just a list of degrees,
      // usually we just want the list of notes.
      // For chromatic, it's just all notes.
      return _keys;
    }

    try {
      final tonicName = _scaleNameMap[_selectedScale] ?? _selectedScale;
      final scalePattern = ScalePattern.findByName(tonicName);

      if (scalePattern == null) return [];

      final root = Pitch.parse(_selectedKey);
      final scale = scalePattern.at(root.pitchClass);

      return scale.intervals.map((interval) {
        return (root + interval).toString();
      }).toList();
    } catch (e) {
      debugPrint('Error calculating degrees: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableDegrees = _getDegreesInScale();

    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text('Midi Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          // --- Pixel Settings moved to DrawingToolsPane ---

          // --- Music Settings ---
          Text('Music Theory', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Text('Tempo: ${_tempo.toInt()} BPM'),
          Slider(
            value: _tempo,
            min: 40,
            max: 240,
            divisions: 200,
            label: _tempo.round().toString(),
            onChanged: (value) => setState(() => _tempo = value),
          ),
          const SizedBox(height: 10),

          Text('Octaves: ${_octaves.toInt()}'),
          Slider(
            value: _octaves,
            min: 1,
            max: 8,
            divisions: 7,
            label: _octaves.round().toString(),
            onChanged: (value) => setState(() => _octaves = value),
          ),

          const SizedBox(height: 10),
          // Changed from Row to Column to avoid overflow
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Key'),
            value: _selectedKey,
            items: _keys
                .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedKey = val;
                  _selectedDegrees = [];
                  _updateSelectedDegrees();
                });
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Scale'),
            value: _selectedScale,
            items: _scaleNameMap.keys
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedScale = val;
                  _selectedDegrees = [];
                  _updateSelectedDegrees();
                });
              }
            },
          ),

          const SizedBox(height: 20),
          const Text('Included Scale Degrees:'),
          Wrap(
            spacing: 8.0,
            children: availableDegrees.map((degree) {
              final isSelected = _selectedDegrees.contains(degree);
              return FilterChip(
                label: Text(degree),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedDegrees.add(degree);
                    } else {
                      _selectedDegrees.remove(degree);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
