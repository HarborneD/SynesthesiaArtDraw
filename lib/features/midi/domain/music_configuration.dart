import 'package:tonic/tonic.dart';

enum DroneMapping { tonal, modal, chromatic }

class MusicConfiguration {
  final double octaves;
  final double tempo;
  final String selectedKey;
  final String selectedScale;
  final List<String> selectedDegrees;

  // Trigger Logic
  final double directionChangeThreshold; // degrees

  // Grid / Sequencer
  final int gridBars;
  final bool showPlayLine;

  // Drone
  final bool droneEnabled;
  final int droneUpdateIntervalBars;
  final int droneDensity;
  final DroneMapping droneMapping;
  final int droneInstrument; // MIDI Program Number

  int get totalBeats => gridBars * 4;

  static const Map<String, String> scaleNameMap = {
    'Major': 'Diatonic Major',
    'Minor': 'Natural Minor',
    'Dorian': 'Dorian',
    'Phrygian': 'Phrygian',
    'Lydian': 'Lydian',
    'Mixolydian': 'Mixolydian',
    'Locrian': 'Locrian',
    'Pentatonic Major': 'Major Pentatonic',
    'Pentatonic Minor': 'Minor Pentatonic',
    'Chromatic': 'Chromatic',
  };

  static const List<String> keys = [
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

  MusicConfiguration({
    this.octaves = 3,
    this.tempo = 92.0,
    this.selectedKey = 'A',
    this.selectedScale = 'Minor',
    List<String>? selectedDegrees,
    this.directionChangeThreshold = 0.5, // Sensitivity
    this.gridBars = 8,
    this.showPlayLine = true,
    this.droneEnabled = true,
    this.droneUpdateIntervalBars = 1,
    this.droneDensity = 3,
    this.droneMapping = DroneMapping.tonal,
    this.droneInstrument = 49, // Strings Ensemble 2
  }) : selectedDegrees = selectedDegrees ?? _getDefaultDegrees();

  static List<String> _getDefaultDegrees() {
    final fullScale = getDegreesInScale('A', 'Minor');
    // Default Filter: Remove 2nd (index 1), 6th (index 5), 7th (index 6)
    // Degrees: 1, 2, 3, 4, 5, 6, 7
    // Indices: 0, 1, 2, 3, 4, 5, 6
    // Keep: 0, 2, 3, 4
    if (fullScale.length >= 7) {
      return [fullScale[0], fullScale[2], fullScale[3], fullScale[4]];
    }
    return fullScale;
  }

  MusicConfiguration copyWith({
    double? octaves,
    double? tempo,
    String? selectedKey,
    String? selectedScale,
    List<String>? selectedDegrees,
    double? directionChangeThreshold,
    int? gridBars,
    bool? showPlayLine,
    bool? droneEnabled,
    int? droneUpdateIntervalBars,
    int? droneDensity,
    DroneMapping? droneMapping,
    int? droneInstrument,
  }) {
    return MusicConfiguration(
      octaves: octaves ?? this.octaves,
      tempo: tempo ?? this.tempo,
      selectedKey: selectedKey ?? this.selectedKey,
      selectedScale: selectedScale ?? this.selectedScale,
      selectedDegrees: selectedDegrees ?? this.selectedDegrees,
      directionChangeThreshold:
          directionChangeThreshold ?? this.directionChangeThreshold,
      gridBars: gridBars ?? this.gridBars,
      showPlayLine: showPlayLine ?? this.showPlayLine,
      droneEnabled: droneEnabled ?? this.droneEnabled,
      droneUpdateIntervalBars:
          droneUpdateIntervalBars ?? this.droneUpdateIntervalBars,
      droneDensity: droneDensity ?? this.droneDensity,
      droneMapping: droneMapping ?? this.droneMapping,
      droneInstrument: droneInstrument ?? this.droneInstrument,
    );
  }

  static List<String> getDegreesInScale(String key, String scaleName) {
    if (scaleName == 'Chromatic') {
      return keys;
    }

    try {
      final tonicName = scaleNameMap[scaleName] ?? scaleName;
      final scalePattern = ScalePattern.findByName(tonicName);
      if (scalePattern == null) return [];

      final root = Pitch.parse(key);
      final scale = scalePattern.at(root.pitchClass);

      return scale.intervals.map((interval) {
        return (root + interval).toString();
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Logic to return active octave indices
  // 1 octave: [4]
  // 2 octaves: [4, 5]
  // 3 octaves: [3, 4, 5]
  // 4 octaves: [3, 4, 5, 6]
  // etc.
  // Alternating adding above then below starting from 4.
  List<int> getActiveOctaves() {
    final int count = octaves.round();
    if (count <= 0) return [];

    List<int> result = [4];
    if (count == 1) return result;

    for (int i = 1; i < count; i++) {
      if (i % 2 != 0) {
        // Add above
        result.add(result.last + 1);
      } else {
        // Add below
        result.insert(0, result.first - 1);
      }
    }
    result.sort();
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'octaves': octaves,
      'tempo': tempo,
      'selectedKey': selectedKey,
      'selectedScale': selectedScale,
      'selectedDegrees': selectedDegrees,
      'directionChangeThreshold': directionChangeThreshold,
      'gridBars': gridBars,
      'showPlayLine': showPlayLine,
      'droneEnabled': droneEnabled,
      'droneUpdateIntervalBars': droneUpdateIntervalBars,
      'droneDensity': droneDensity,
      'droneMapping': droneMapping.name,
      'droneInstrument': droneInstrument,
    };
  }

  factory MusicConfiguration.fromJson(Map<String, dynamic> json) {
    return MusicConfiguration(
      octaves: (json['octaves'] as num?)?.toDouble() ?? 3.0,
      tempo: (json['tempo'] as num?)?.toDouble() ?? 92.0,
      selectedKey: json['selectedKey'] as String? ?? 'A',
      selectedScale: json['selectedScale'] as String? ?? 'Minor',
      selectedDegrees: (json['selectedDegrees'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      directionChangeThreshold:
          (json['directionChangeThreshold'] as num?)?.toDouble() ?? 0.5,
      gridBars: json['gridBars'] as int? ?? 8,
      showPlayLine: json['showPlayLine'] as bool? ?? true,
      droneEnabled: json['droneEnabled'] as bool? ?? true,
      droneUpdateIntervalBars: json['droneUpdateIntervalBars'] as int? ?? 1,
      droneDensity: json['droneDensity'] as int? ?? 3,
      droneMapping: DroneMapping.values.firstWhere(
        (e) => e.name == (json['droneMapping'] as String?),
        orElse: () => DroneMapping.tonal,
      ),
      droneInstrument: json['droneInstrument'] as int? ?? 49,
    );
  }

  /// Returns a sorted list of MIDI note numbers for the current configuration.
  List<int> getAllMidiNotes() {
    final activeOctaves = getActiveOctaves();
    final Set<int> notes = {};

    for (final octave in activeOctaves) {
      for (final degree in selectedDegrees) {
        try {
          final pitchClass = Pitch.parse(degree).pitchClass.integer;
          // MIDI Note = (Octave + 1) * 12 + PitchClass
          final midi = (octave + 1) * 12 + pitchClass;
          if (midi >= 0 && midi <= 127) {
            notes.add(midi);
          }
        } catch (e) {
          // Ignore parse errors
        }
      }
    }

    final sorted = notes.toList()..sort();
    return sorted;
  }
}
