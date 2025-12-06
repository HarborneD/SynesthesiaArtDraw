import 'package:tonic/tonic.dart';

class MusicConfiguration {
  final double octaves;
  final double tempo;
  final String selectedKey;
  final String selectedScale;
  final List<String> selectedDegrees;

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
  }) : selectedDegrees = selectedDegrees ?? getDegreesInScale('A', 'Minor');

  MusicConfiguration copyWith({
    double? octaves,
    double? tempo,
    String? selectedKey,
    String? selectedScale,
    List<String>? selectedDegrees,
  }) {
    return MusicConfiguration(
      octaves: octaves ?? this.octaves,
      tempo: tempo ?? this.tempo,
      selectedKey: selectedKey ?? this.selectedKey,
      selectedScale: selectedScale ?? this.selectedScale,
      selectedDegrees: selectedDegrees ?? this.selectedDegrees,
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
}
