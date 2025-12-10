import 'package:tonic/tonic.dart';

enum DroneMapping { tonal, modal, chromatic }

class SoundFontChannel {
  final String? name; // Optional, e.g. "Lead", "Bass"
  final String soundFont;
  final int program; // 0-127

  // Brush Settings
  final double brushSpread;
  final double brushOpacity;
  final int bristleCount;
  final bool useNeonGlow;
  final int colorValue;

  // Trigger Settings
  final bool triggerOnBoundary;
  final double minPixelsForTrigger;
  final double directionChangeThreshold;

  // Effects Settings
  final bool isDelayOn;
  final double delayTime;
  final double delayFeedback;
  final double reverbLevel;
  final bool isSustainOn;

  // Volume
  final double channelVolume; // Replaces lineVolume conceptually per channel

  SoundFontChannel({
    this.name,
    required this.soundFont,
    required this.program,
    this.brushSpread = 7.0,
    this.brushOpacity = 0.5,
    this.bristleCount = 40,
    this.useNeonGlow = true,
    this.colorValue = 0xFF009688, // Colors.teal
    this.triggerOnBoundary = true,
    this.minPixelsForTrigger = 10.0,
    this.directionChangeThreshold = 90.0,
    this.isDelayOn = true,
    this.delayTime = 500.0,
    this.delayFeedback = 0.6,
    this.reverbLevel = 0.3,
    this.isSustainOn = false,
    this.channelVolume = 0.8,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'soundFont': soundFont,
    'program': program,
    'brushSpread': brushSpread,
    'brushOpacity': brushOpacity,
    'bristleCount': bristleCount,
    'useNeonGlow': useNeonGlow,
    'colorValue': colorValue,
    'triggerOnBoundary': triggerOnBoundary,
    'minPixelsForTrigger': minPixelsForTrigger,
    'directionChangeThreshold': directionChangeThreshold,
    'isDelayOn': isDelayOn,
    'delayTime': delayTime,
    'delayFeedback': delayFeedback,
    'reverbLevel': reverbLevel,
    'isSustainOn': isSustainOn,
    'channelVolume': channelVolume,
  };

  factory SoundFontChannel.fromJson(Map<String, dynamic> json) {
    return SoundFontChannel(
      name: json['name'] as String?,
      soundFont: json['soundFont'] as String? ?? 'White Grand Piano II.sf2',
      program: (json['program'] as int?) ?? (json['programIndex'] as int?) ?? 0,
      brushSpread: (json['brushSpread'] as num?)?.toDouble() ?? 7.0,
      brushOpacity: (json['brushOpacity'] as num?)?.toDouble() ?? 0.5,
      bristleCount: (json['bristleCount'] as int?) ?? 40,
      useNeonGlow: json['useNeonGlow'] as bool? ?? true,
      colorValue: (json['colorValue'] as int?) ?? 0xFF009688,
      triggerOnBoundary: json['triggerOnBoundary'] as bool? ?? true,
      minPixelsForTrigger:
          (json['minPixelsForTrigger'] as num?)?.toDouble() ?? 10.0,
      directionChangeThreshold:
          (json['directionChangeThreshold'] as num?)?.toDouble() ?? 90.0,
      isDelayOn:
          json['isDelayOn'] as bool? ?? json['isReverbOn'] as bool? ?? true,
      delayTime:
          (json['delayTime'] as num?)?.toDouble() ??
          (json['reverbDelay'] as num?)?.toDouble() ??
          500.0,
      delayFeedback:
          (json['delayFeedback'] as num?)?.toDouble() ??
          (json['reverbDecay'] as num?)?.toDouble() ??
          0.6,
      reverbLevel: (json['reverbLevel'] as num?)?.toDouble() ?? 0.3,
      isSustainOn: json['isSustainOn'] as bool? ?? false,
      channelVolume:
          (json['channelVolume'] as num?)?.toDouble() ??
          (json['lineVolume'] as num?)?.toDouble() ??
          0.8,
    );
  }

  SoundFontChannel copyWith({
    String? name,
    String? soundFont,
    int? program,
    double? brushSpread,
    double? brushOpacity,
    int? bristleCount,
    bool? useNeonGlow,
    int? colorValue,
    bool? triggerOnBoundary,
    double? minPixelsForTrigger,
    double? directionChangeThreshold,
    bool? isDelayOn,
    double? delayTime,
    double? delayFeedback,
    double? reverbLevel,
    bool? isSustainOn,
    double? channelVolume,
  }) {
    return SoundFontChannel(
      name: name ?? this.name,
      soundFont: soundFont ?? this.soundFont,
      program: program ?? this.program,
      brushSpread: brushSpread ?? this.brushSpread,
      brushOpacity: brushOpacity ?? this.brushOpacity,
      bristleCount: bristleCount ?? this.bristleCount,
      useNeonGlow: useNeonGlow ?? this.useNeonGlow,
      colorValue: colorValue ?? this.colorValue,
      triggerOnBoundary: triggerOnBoundary ?? this.triggerOnBoundary,
      minPixelsForTrigger: minPixelsForTrigger ?? this.minPixelsForTrigger,
      directionChangeThreshold:
          directionChangeThreshold ?? this.directionChangeThreshold,
      isDelayOn: isDelayOn ?? this.isDelayOn,
      delayTime: delayTime ?? this.delayTime,
      delayFeedback: delayFeedback ?? this.delayFeedback,
      reverbLevel: reverbLevel ?? this.reverbLevel,
      isSustainOn: isSustainOn ?? this.isSustainOn,
      channelVolume: channelVolume ?? this.channelVolume,
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
  bool showPlayLine;

  // Instrument Palette (Channels)
  final List<SoundFontChannel> soundFontChannels;
  final int selectedChannelIndex; // 0-7

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

  SoundFontChannel get currentChannel =>
      soundFontChannels[selectedChannelIndex];

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
    this.showPlayLine = false,
    this.droneEnabled = true,
    this.droneUpdateIntervalBars = 1,
    this.droneDensity = 3,
    this.droneMapping = DroneMapping.tonal,
    this.droneInstrument = 49, // Strings Ensemble 2
    this.droneSoundFont = 'casio_sk_200_gm.sf2',
    this.droneVolume = 0.2, // Default 20%
    this.lineVolume = 0.8,
    List<SoundFontChannel>? soundFontChannels,
    this.selectedChannelIndex = 0,
  }) : selectedDegrees = selectedDegrees ?? _getDefaultDegrees(),
       soundFontChannels = soundFontChannels ?? _getDefaultChannels();

  static List<SoundFontChannel> _getDefaultChannels() {
    return [
      SoundFontChannel(
        name: 'Channel 1',
        soundFont: 'White Grand Piano II.sf2',
        program: 0,
      ),
      SoundFontChannel(
        name: 'Channel 2',
        soundFont: 'Dystopian Terra.sf2',
        program: 2,
      ),
      SoundFontChannel(
        name: 'Channel 3',
        soundFont: 'VocalsPapel.sf2',
        program: 3,
      ),
      SoundFontChannel(
        name: 'Channel 4',
        soundFont: 'casio_sk_200_gm.sf2',
        program: 54,
      ),
      SoundFontChannel(
        name: 'Channel 5',
        soundFont: 'casio_sk_200_gm.sf2',
        program: 68,
      ),
      SoundFontChannel(
        name: 'Channel 6',
        soundFont: 'casio_sk_200_gm.sf2',
        program: 93,
      ),
      SoundFontChannel(
        name: 'Channel 7',
        soundFont:
            'Authentic Shreddage X Soundfont MEGALO VERSION PRE AMPED STEREO EQ - That1Rand0mChannel.sf2',
        program: 0,
      ),
      SoundFontChannel(
        name: 'Channel 8',
        soundFont: 'Studio FG460s II Pro Guitar Pack.sf2',
        program: 0,
      ),
    ];
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
    List<SoundFontChannel>? soundFontChannels,
    int? selectedChannelIndex,
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
      soundFontChannels: soundFontChannels ?? this.soundFontChannels,
      selectedChannelIndex: selectedChannelIndex ?? this.selectedChannelIndex,
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
      'soundFontChannels': soundFontChannels.map((e) => e.toJson()).toList(),
      'selectedChannelIndex': selectedChannelIndex,
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
      soundFontChannels:
          (json['soundFontChannels'] as List<dynamic>?)
              ?.map((e) => SoundFontChannel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['instrumentSlots'] as List<dynamic>?)
              ?.map((e) => SoundFontChannel.fromJson(e as Map<String, dynamic>))
              .toList(), // Fallback for old save data
      selectedChannelIndex:
          json['selectedChannelIndex'] as int? ??
          json['selectedInstrumentSlot'] as int? ??
          0,
    );
  }

  static List<String> _getDefaultDegrees() {
    return ['1', '3', '5'];
  }

  List<int> getActiveOctaves() {
    List<int> octs = [];
    int start = 2;
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
