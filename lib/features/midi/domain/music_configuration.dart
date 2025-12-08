import 'package:tonic/tonic.dart';

enum DroneMapping { tonal, modal, chromatic }

class InstrumentSlot {
  final String? name; // Optional, e.g. "Lead", "Bass"
  final String soundFont;
  final int program; // 0-127

  InstrumentSlot({this.name, required this.soundFont, required this.program});

  Map<String, dynamic> toJson() => {
    'name': name,
    'soundFont': soundFont,
    'program': program,
  };

  factory InstrumentSlot.fromJson(Map<String, dynamic> json) {
    return InstrumentSlot(
      name: json['name'] as String?,
      soundFont: json['soundFont'] as String,
      program: json['program'] as int,
    );
  }

  InstrumentSlot copyWith({String? name, String? soundFont, int? program}) {
    return InstrumentSlot(
      name: name ?? this.name,
      soundFont: soundFont ?? this.soundFont,
      program: program ?? this.program,
    );
  }
}

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

  // Instrument Palette (Slots)
  final List<InstrumentSlot> instrumentSlots;
  final int selectedInstrumentSlot; // 0-7

  // Drone
  final bool droneEnabled;
  final int droneUpdateIntervalBars;
  final int droneDensity;
  final DroneMapping droneMapping;
  final int droneInstrument; // MIDI Program Number
  final String droneSoundFont;
  final double droneVolume; // 0.0 - 1.0

  // Line Instrument
  final double lineVolume; // 0.0 - 1.0

  InstrumentSlot get currentSlot => instrumentSlots[selectedInstrumentSlot];

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
    this.directionChangeThreshold = 90.0,
    this.gridBars = 8,
    this.showPlayLine = true,
    this.droneEnabled = true,
    this.droneUpdateIntervalBars = 1,
    this.droneDensity = 3,
    this.droneMapping = DroneMapping.tonal,
    this.droneInstrument = 49, // Strings Ensemble 2
    this.droneSoundFont = 'casio_sk_200_gm.sf2',
    this.droneVolume = 0.8,
    this.lineVolume = 0.8,
    List<InstrumentSlot>? instrumentSlots,
    this.selectedInstrumentSlot = 0,
  }) : selectedDegrees = selectedDegrees ?? _getDefaultDegrees(),
       instrumentSlots = instrumentSlots ?? _getDefaultSlots();

  static List<InstrumentSlot> _getDefaultSlots() {
    return List.generate(8, (index) {
      // Default to some variety if possible, or just standard piano for now
      return InstrumentSlot(
        name: 'Instrument ${index + 1}',
        soundFont: 'Dystopian Terra.sf2', // Default SF
        program: 0, // Grand Piano
      );
    });
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
    String? droneSoundFont,
    double? droneVolume,
    double? lineVolume,
    List<InstrumentSlot>? instrumentSlots,
    int? selectedInstrumentSlot,
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
      droneSoundFont: droneSoundFont ?? this.droneSoundFont,
      droneVolume: droneVolume ?? this.droneVolume,
      lineVolume: lineVolume ?? this.lineVolume,
      instrumentSlots: instrumentSlots ?? this.instrumentSlots,
      selectedInstrumentSlot:
          selectedInstrumentSlot ?? this.selectedInstrumentSlot,
    );
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
      'droneSoundFont': droneSoundFont,
      'droneVolume': droneVolume,
      'lineVolume': lineVolume,
      'instrumentSlots': instrumentSlots.map((e) => e.toJson()).toList(),
      'selectedInstrumentSlot': selectedInstrumentSlot,
    };
  }

  factory MusicConfiguration.fromJson(Map<String, dynamic> json) {
    // Sanitize directionChangeThreshold
    double threshold =
        (json['directionChangeThreshold'] as num?)?.toDouble() ?? 90.0;
    if (threshold < 10.0 || threshold > 180.0) {
      threshold = 90.0;
    }

    return MusicConfiguration(
      octaves: (json['octaves'] as num?)?.toDouble() ?? 3.0,
      tempo: (json['tempo'] as num?)?.toDouble() ?? 92.0,
      selectedKey: json['selectedKey'] as String? ?? 'A',
      selectedScale: json['selectedScale'] as String? ?? 'Minor',
      selectedDegrees: (json['selectedDegrees'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      directionChangeThreshold: threshold,
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
      droneSoundFont:
          json['droneSoundFont'] as String? ?? 'casio_sk_200_gm.sf2',
      droneVolume: (json['droneVolume'] as num?)?.toDouble() ?? 0.8,
      lineVolume: (json['lineVolume'] as num?)?.toDouble() ?? 0.8,
      instrumentSlots: (json['instrumentSlots'] as List<dynamic>?)
          ?.map((e) => InstrumentSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedInstrumentSlot: json['selectedInstrumentSlot'] as int? ?? 0,
    );
  }

  static List<String> _getDefaultDegrees() {
    return ['1', '3', '5'];
  }

  List<int> getActiveOctaves() {
    List<int> octs = [];
    int start = 3;
    for (int i = 0; i < octaves; i++) {
      octs.add(start + i);
    }
    return octs;
  }

  static List<String> getDegreesInScale(String keyName, String scaleName) {
    // Helper to get degree names like "1", "b2" etc from the selected scale
    // note: keyName is unused for relative degrees, but kept for signature compatibility
    final actualScaleName = scaleNameMap[scaleName] ?? 'Natural Minor';

    try {
      final pattern = ScalePattern.findByName(actualScaleName);
      return pattern.intervals.map((i) => _intervalToString(i)).toList();
    } catch (e) {
      return ['1', '2', '3', '4', '5', '6', '7'];
    }
  }

  static String _intervalToString(Interval interval) {
    int semitones = interval.semitones;
    // Map semitones to degree name relative to Major scale steps
    const names = [
      '1',
      'b2',
      '2',
      'b3',
      '3',
      '4',
      'b5',
      '5',
      'b6',
      '6',
      'b7',
      '7',
    ];
    // Handle intervals > Octave if necessary, though scales usually fit in octave
    int index = semitones % 12;

    // Special case for semitones=12 (Octave) -> '1' or '8'? Usually implied.
    // But standard Interval map: 0->1.

    if (index >= 0 && index < 12) return names[index];
    return interval.number.toString();
  }

  static const Map<String, int> _degreeToSemitonesMap = {
    '1': 0,
    'b2': 1,
    '2': 2,
    'b3': 3,
    '3': 4,
    '4': 5,
    'b5': 6,
    '5': 7,
    'b6': 8,
    '6': 9,
    'b7': 10,
    '7': 11,
  };

  /// Returns a sorted list of MIDI note numbers for the current configuration.
  List<int> getAllMidiNotes() {
    final activeOctaves = getActiveOctaves();
    final Set<int> notes = {};

    // Get Root Pitch Class from Key (0-11)
    // Tonic's Pitch.parse handles "C", "C#", "Db" etc.
    int rootPitch = 0;
    try {
      rootPitch = Pitch.parse(selectedKey).pitchClass.integer;
    } catch (e) {
      // Fallback to A=9 if parse fails
      rootPitch = 9;
    }

    for (final octave in activeOctaves) {
      for (final degree in selectedDegrees) {
        try {
          final semitones = _degreeToSemitonesMap[degree];
          if (semitones != null) {
            // MIDI Note = (Octave + 1) * 12 + Root + Semitones
            // Octave 3 usually starts at MIDI 48 (C3) or 60 (C4)?
            // Standard: C4 = MIDI 60. Octave 4.
            // Logic used before: (octave + 1) * 12 + pitchClass.
            // If octave=3, 4 * 12 = 48 (C3).
            // Let's stick to that convention.

            final midi = (octave + 1) * 12 + rootPitch + semitones;
            if (midi >= 0 && midi <= 127) {
              notes.add(midi);
            }
          }
        } catch (e) {
          // Ignore
        }
      }
    }

    final sorted = notes.toList()..sort();
    return sorted;
  }
}
