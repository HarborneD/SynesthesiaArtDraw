import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui; // For FragmentProgram
import 'package:audioplayers/audioplayers.dart';
import '../../../core/presentation/layout/split_layout.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import '../../transport/presentation/transport_bar.dart';
import '../../canvas/presentation/canvas_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:synesthesia_art_draw/features/instrument/domain/instrument_preset.dart';
import '../../midi/presentation/midi_settings_pane.dart';
import '../../sequencer/presentation/sequencer_settings_pane.dart';

import '../../settings/presentation/app_settings_pane.dart';
import '../../toolbar/presentation/toolbar_widget.dart';
import '../../drawing/domain/drawing_mode.dart';
import '../../drawing/domain/drawn_line.dart';
import '../../drawing/domain/gradient_stroke.dart';
import '../../midi/domain/music_configuration.dart';
import '../../library/presentation/library_pane.dart';
import '../../canvas/domain/canvas_model.dart';
import '../../canvas/data/canvas_repository.dart';

// Import New Panes
import '../../background/presentation/background_pane.dart';
import '../../channel/presentation/channel_settings_pane.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int? _selectedPaneIndex;
  MusicConfiguration _musicConfig = MusicConfiguration();
  bool _showNoteLines = true;

  // Drawing State
  double _segmentLength = 200.0;
  double _minPixels = 1.0;
  List<DrawnLine> _lines = [];
  DrawnLine? _currentLine;

  // Gradient State
  List<GradientStroke> _gradientStrokes = [];
  ui.FragmentShader? _backgroundShader;

  DrawingMode _currentMode = DrawingMode.line;

  // Clock State
  bool _isPlaying = false;
  bool _isMetronomeOn = false;
  int _currentTick = 0; // 0-15
  Timer? _clockTimer;
  late AnimationController _playLineController;

  // MIDI State
  final _midi = MidiPro();
  bool _isMidiInitialized = false;
  final _playerDown = AudioPlayer();
  final _playerUp = AudioPlayer();

  // Drone State
  Color _currentDroneColor = Colors.black;
  List<int> _activeDroneNotes = [];

  // Canvas Library State
  List<CanvasModel> _savedCanvases = [];
  final _canvasRepo = CanvasRepository();
  List<InstrumentPreset> _presets = [];

  int _sfId = 0; // Current Channel SF ID
  int _droneSfId = 0; // Drone Channel SF ID

  final List<String> _soundFonts = [
    'Authentic Shreddage X Soundfont MEGALO VERSION PRE AMPED STEREO EQ - That1Rand0mChannel.sf2',
    'Clean Stratocaster.sf2',
    'Dystopian Terra.sf2',
    'Emu Rockgtr.sf2',
    'Studio FG460s II Pro Guitar Pack.sf2',
    'VocalsPapel.sf2',
    'White Grand Piano I.sf2',
    'White Grand Piano II.sf2',
    'White Grand Piano III.sf2',
    'White Grand Piano IV.sf2',
    'White Grand Piano V.sf2',
    'casio_sk_200_gm.sf2',
    'mick_gordon_string_efx.sf2',
  ];

  // Track loaded SoundFonts to get their IDs
  // Filename -> ID
  final Map<String, int> _loadedSoundFonts = {};

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadDefaultChannels(); // Async load defaults
    _loadShader();
    _loadPresets();
    _loadCanvases();
    _playLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Initial default
    );
  }

  Future<void> _loadDefaultChannels() async {
    try {
      final List<SoundFontChannel> channels = [];
      for (int i = 1; i <= 8; i++) {
        final String jsonString = await rootBundle.loadString(
          'assets/default_channel_settings/channel_$i.json',
        );
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        channels.add(SoundFontChannel.fromJson(jsonMap));
      }
      setState(() {
        _musicConfig = _musicConfig.copyWith(soundFontChannels: channels);
      });
      _initMidi(); // Init MIDI after loading defaults
    } catch (e) {
      debugPrint("Error loading default channels: $e");
      _initMidi(); // Fallback setup
    }
  }

  Future<void> _loadShader() async {
    try {
      ui.FragmentProgram program = await ui.FragmentProgram.fromAsset(
        'shaders/gradient_field.frag',
      );
      setState(() {
        _backgroundShader = program.fragmentShader();
      });
    } catch (e) {
      debugPrint("Failed to load shader: $e");
    }
  }

  Future<void> _initMidi() async {
    // 1. Load Drone SF
    await _loadSoundFontAsset(_musicConfig.droneSoundFont, isDrone: true);

    // 2. Initialize Channels 0-7
    for (int i = 0; i < _musicConfig.soundFontChannels.length; i++) {
      final ch = _musicConfig.soundFontChannels[i];
      // Load (or get cached) SF Id
      // Note: We use isDrone=false which updates _sfId, but we'll use return value too.
      int id = await _loadSoundFontAsset(ch.soundFont, isDrone: false);

      if (id != -1) {
        _midi.selectInstrument(
          sfId: id,
          program: ch.program,
          channel: i, // Map 1:1
        );
      }
    }

    // Select Drone Instrument (Channel 8)
    _midi.selectInstrument(
      sfId: _droneSfId,
      program: _musicConfig.droneInstrument,
      channel: 8,
    );

    setState(() {
      _isMidiInitialized = true;
    });
  }

  Future<int> _loadSoundFontAsset(
    String fileName, {
    bool isDrone = false,
  }) async {
    try {
      int id;
      if (_loadedSoundFonts.containsKey(fileName)) {
        id = _loadedSoundFonts[fileName]!;
      } else {
        final path = 'assets/sounds_fonts/$fileName';
        id = await _midi.loadSoundfontAsset(assetPath: path);
        _loadedSoundFonts[fileName] = id;
        debugPrint("Loaded SoundFont: $path (ID: $id)");
      }

      if (isDrone) {
        _droneSfId = id;
      } else {
        _sfId = id;
      }
      return id;
    } catch (e) {
      debugPrint("Error loading SoundFont $fileName: $e");
      return -1;
    }
  }

  void _updateChannel(SoundFontChannel newChannel) async {
    // Async to handle potential SF loading if needed

    // 1. Check if SF changed
    int sfId = _sfId;
    if (newChannel.soundFont != _musicConfig.currentChannel.soundFont) {
      sfId = await _loadSoundFontAsset(newChannel.soundFont, isDrone: false);
    } else {
      // Get existing ID
      if (_loadedSoundFonts.containsKey(newChannel.soundFont)) {
        sfId = _loadedSoundFonts[newChannel.soundFont]!;
      }
    }

    // 2. Select Instrument (Always update to be safe, or check if program changed)
    // We use the currently selected index as the MIDI channel
    _midi.selectInstrument(
      sfId: sfId,
      program: newChannel.program,
      channel: _musicConfig.selectedChannelIndex,
    );

    final updatedChannels = List<SoundFontChannel>.from(
      _musicConfig.soundFontChannels,
    );
    updatedChannels[_musicConfig.selectedChannelIndex] = newChannel;

    _updateConfig(_musicConfig.copyWith(soundFontChannels: updatedChannels));
  }

  void _selectChannel(int index) async {
    if (index < 0 || index >= _musicConfig.soundFontChannels.length) return;

    final newConfig = _musicConfig.copyWith(selectedChannelIndex: index);
    // Wait for SF load if needed
    await _loadSoundFontAsset(
      newConfig.currentChannel.soundFont,
      isDrone: false,
    );

    // Select program
    _midi.selectInstrument(
      sfId: _sfId,
      program: newConfig.currentChannel.program,
      channel: 0,
    );

    _updateConfig(newConfig);

    // Ensure we go back to Line mode if coming from Gradient
    if (_currentMode != DrawingMode.line) {
      setState(() {
        _currentMode = DrawingMode.line;
        // Optionally switch to Channel Settings Pane if desired?
        // User didn't strictly say so, but it makes sense.
        // Let's open channel pane.
        _selectedPaneIndex = 3;
      });
    }
  }

  void _selectGradientTool() {
    setState(() {
      _currentMode = DrawingMode.gradient;
      _selectedPaneIndex = 2; // Auto-open Background pane
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startTimer();
      } else {
        _clockTimer?.cancel();
        _playLineController.stop();
        _playerDown.stop();
        _playerUp.stop();
        _updateDroneNotes([]);
        // Stop all active notes on all channels/sfs?
        // difficult without tracking every note.
      }
    });
  }

  void _stop() {
    setState(() {
      _isPlaying = false;
      _currentTick = 0;
      _clockTimer?.cancel();
      _playLineController.stop();
      _playLineController.value = 0.0;
      _playerDown.stop();
      _playerUp.stop();
      _updateDroneNotes([]);
    });
  }

  void _toggleMetronome() {
    setState(() {
      _isMetronomeOn = !_isMetronomeOn;
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _playLineController.dispose();
    _playerDown.dispose();
    _playerUp.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _clockTimer?.cancel();
    if (!_isPlaying) return;

    final double msPerTick = 60000 / _musicConfig.tempo;
    final totalBeats = _musicConfig.totalBeats;
    final loopDurationMs = (msPerTick * totalBeats).round();

    _playLineController.duration = Duration(milliseconds: loopDurationMs);
    _playLineController.repeat();

    _processTick();

    _clockTimer = Timer.periodic(Duration(milliseconds: msPerTick.round()), (
      timer,
    ) {
      if (!mounted) return;
      setState(() {
        _currentTick = (_currentTick + 1) % _musicConfig.totalBeats;
      });
      _processTick();
    });
  }

  void _processTick() {
    if (_isMetronomeOn) {
      final isDownbeat = _currentTick % 4 == 0;
      final player = isDownbeat ? _playerDown : _playerUp;
      final source = isDownbeat
          ? AssetSource('metronome/Zoom ST Down .wav')
          : AssetSource('metronome/Zoom ST UP.wav');
      player.play(source);
    }

    // Drone Update
    final beatsPerInterval = _musicConfig.droneUpdateIntervalBars * 4;
    // Fix: Check if drone is actually enabled
    if (_musicConfig.droneEnabled && (_currentTick % beatsPerInterval == 0)) {
      _processDroneLogic();
    } else if (!_musicConfig.droneEnabled && _activeDroneNotes.isNotEmpty) {
      _updateDroneNotes([]); // Silence drone if disabled
    }

    _checkLineTriggers();
  }

  void _processDroneLogic() {
    if (!_musicConfig.droneEnabled) return;

    final scanX = _playLineController.value;
    final color = _getScanLineColor(scanX);
    _currentDroneColor = color;

    final hsl = HSLColor.fromColor(color);
    final hue = hsl.hue;

    List<int> targetDegrees = [];

    // Mapping Strategy Logic (Simple Tonal for now as per previous code)
    if (hue >= 330 || hue <= 30) {
      targetDegrees = [0, 2, 4]; // Tonic
    } else if (hue >= 60 && hue <= 180) {
      targetDegrees = [3, 5, 0]; // Subdominant
    } else if (hue > 180 && hue < 300) {
      targetDegrees = [4, 6, 1]; // Dominant
    } else {
      targetDegrees = [0, 2, 4];
    }

    final rootNote = _noteNameToMidi(_musicConfig.selectedKey);
    final scaleOffsets = _getScaleOffsets(_musicConfig.selectedScale);

    List<int> newNotes = [];
    int baseOctave = 3;

    for (int i = 0; i < _musicConfig.droneDensity; i++) {
      final degreeIndex = targetDegrees[i % targetDegrees.length];
      if (degreeIndex < scaleOffsets.length) {
        int offset = scaleOffsets[degreeIndex];
        int note = rootNote + offset + (baseOctave * 12);
        if (i >= 3) note += 12;
        newNotes.add(note);
      }
    }

    _updateDroneNotes(newNotes);
  }

  void _updateDroneNotes(List<int> newNotes, {bool forceRetrigger = false}) {
    if (forceRetrigger) {
      for (final note in _activeDroneNotes) {
        _midi.stopNote(key: note, channel: 8, sfId: _droneSfId);
      }
      for (final note in newNotes) {
        int velocity = (127 * _musicConfig.droneVolume).round().clamp(0, 127);
        _midi.playNote(
          key: note,
          velocity: velocity,
          channel: 8,
          sfId: _droneSfId,
        );
      }
      _activeDroneNotes = newNotes;
      return;
    }

    for (final note in _activeDroneNotes) {
      if (!newNotes.contains(note)) {
        _midi.stopNote(key: note, channel: 8, sfId: _droneSfId);
      }
    }

    for (final note in newNotes) {
      if (!_activeDroneNotes.contains(note)) {
        int velocity = (127 * _musicConfig.droneVolume).round().clamp(
          0,
          127,
        ); // Fix Volume Scaling
        _midi.playNote(
          key: note,
          velocity: velocity,
          channel: 8,
          sfId: _droneSfId,
        );
      }
    }
    _activeDroneNotes = newNotes;
  }

  Color _getScanLineColor(double xPercent) {
    final xPos = xPercent * MediaQuery.of(context).size.width;

    // Check Lines
    int lineCount = 0;
    double r = 0, g = 0, b = 0;

    for (final line in _lines) {
      if (line.path.length < 2) continue;
      for (int i = 0; i < line.path.length - 1; i++) {
        final p1 = line.path[i].point;
        final p2 = line.path[i + 1].point;

        if ((p1.dx <= xPos && p2.dx >= xPos) ||
            (p1.dx >= xPos && p2.dx <= xPos)) {
          final c = line.color;
          r += c.red;
          g += c.green;
          b += c.blue;
          lineCount++;
          break;
        }
      }
    }

    if (lineCount > 0) {
      return Color.fromARGB(
        255,
        (r / lineCount).round(),
        (g / lineCount).round(),
        (b / lineCount).round(),
      );
    }

    // Check Background
    if (_gradientStrokes.isNotEmpty) {
      double wSum = 0.0;
      double accR = 0.0;
      double accG = 0.0;
      double accB = 0.0;

      double toLinear(double c) => pow(c / 255.0, 2.2).toDouble();
      int toSrgb(double c) => (pow(c, 1.0 / 2.2) * 255.0).round().clamp(0, 255);

      for (final stroke in _gradientStrokes) {
        final p0 = stroke.p0;
        final p1 = stroke.p1;
        final radius = stroke.intensity;
        double dist = 0.0;
        double t = 0.0;

        final minX = min(p0.dx, p1.dx);
        final maxX = max(p0.dx, p1.dx);

        if (xPos >= minX && xPos <= maxX) {
          dist = 0.0; // Intersection logic simplified
          final vdx = p1.dx - p0.dx;
          if (vdx.abs() > 0.001) {
            t = (xPos - p0.dx) / vdx;
          } else {
            t = 0.5;
          }
        } else {
          final d0 = (p0.dx - xPos).abs();
          final d1 = (p1.dx - xPos).abs();
          if (d0 < d1) {
            dist = d0;
            t = 0.0;
          } else {
            dist = d1;
            t = 1.0;
          }
        }

        t = t.clamp(0.0, 1.0);

        if (dist < radius) {
          final weight = 1.0 - (dist / radius);
          final c1 = stroke.colors.first;
          final c2 = stroke.colors.last;
          final mixedR = c1.red + (c2.red - c1.red) * t;
          final mixedG = c1.green + (c2.green - c1.green) * t;
          final mixedB = c1.blue + (c2.blue - c1.blue) * t;

          accR += toLinear(mixedR) * weight;
          accG += toLinear(mixedG) * weight;
          accB += toLinear(mixedB) * weight;
          wSum += weight;
        }
      }

      if (wSum > 0.0) {
        return Color.fromARGB(
          255,
          toSrgb(accR / wSum),
          toSrgb(accG / wSum),
          toSrgb(accB / wSum),
        );
      }
    }
    return Colors.black;
  }

  final Set<DrawnLine> _intersectingLines = {};

  void _checkLineTriggers() {
    if (!_isMidiInitialized) return;

    final xPercent = _playLineController.value;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final xPos = xPercent * screenWidth;

    final List<DrawnLine> currentIntersections = [];

    for (final line in _lines) {
      if (line.path.length < 2) continue;

      bool intersects = false;
      double intersectY = 0.0;

      for (int i = 0; i < line.path.length - 1; i++) {
        final p1 = line.path[i].point;
        final p2 = line.path[i + 1].point;

        if ((p1.dx <= xPos && p2.dx >= xPos) ||
            (p1.dx >= xPos && p2.dx <= xPos)) {
          if ((p1.dx - p2.dx).abs() < 0.001) {
            intersectY = p1.dy;
          } else {
            final t = (xPos - p1.dx) / (p2.dx - p1.dx);
            intersectY = p1.dy + t * (p2.dy - p1.dy);
          }
          intersects = true;
          break;
        }
      }

      if (intersects) {
        currentIntersections.add(line);
        if (!_intersectingLines.contains(line)) {
          // New trigger

          double yNorm = (intersectY / screenHeight).clamp(0.0, 1.0);
          yNorm = 1.0 - yNorm;

          final allNotes = _musicConfig.getAllMidiNotes();
          if (allNotes.isNotEmpty) {
            int noteIndex = (yNorm * (allNotes.length - 1)).round();
            _triggerLineSound(noteIndex, line); // Pass Line
          }

          _intersectingLines.add(line);
        }
      }
    }

    _intersectingLines.removeWhere(
      (line) => !currentIntersections.contains(line),
    );
  }

  // UPDATED: Accept line to get correct channel settings
  void _triggerLineSound(int noteIndex, [DrawnLine? line]) {
    final allNotes = _musicConfig.getAllMidiNotes();
    if (allNotes.isEmpty || noteIndex < 0 || noteIndex >= allNotes.length)
      return;

    final note = allNotes[noteIndex];

    // Get Channel Config based on Line
    SoundFontChannel channelConfig = _musicConfig.currentChannel;
    int sfIdToUse = _sfId;

    if (line != null) {
      // Use source channel
      if (line.channelIndex >= 0 &&
          line.channelIndex < _musicConfig.soundFontChannels.length) {
        channelConfig = _musicConfig.soundFontChannels[line.channelIndex];
      }
    }

    // VELOCITY
    int baseVelocity = 100;
    int velocity = (baseVelocity * channelConfig.channelVolume).round().clamp(
      0,
      127,
    );
    int duration = 200; // ms

    // PLAY
    // Use line.channelIndex as the MIDI channel
    int midiChannel = (line?.channelIndex ?? 0);

    _playNoteWithDuration(
      note,
      velocity,
      duration,
      sfIdToUse,
      midiChannel,
      channelConfig,
    );

    // DELAY LOGIC
    if (channelConfig.isDelayOn) {
      _triggerDelay(
        note,
        velocity,
        duration,
        sfIdToUse,
        midiChannel,
        channelConfig,
      );
    }
  }

  // Updated Play with Sustain Logic
  void _playNoteWithDuration(
    int note,
    int velocity,
    int durationMs,
    int sfId,
    int midiChannel,
    SoundFontChannel config,
  ) {
    _midi.playNote(
      key: note,
      velocity: velocity,
      channel: midiChannel,
      sfId: sfId,
    );

    // ALWAYS schedule a stop note to prevent infinite sustain on looping samples.
    // "Sustain" in this context (sequencer) usually implies full duration play,
    // but we must send NoteOff to end the note's lifecycle for the synth.
    // If user wants longer notes, they should increase duration (not implemented per line yet).
    // For now, we enforce the duration.
    // If config.isSustainOn is true, we could arguably extend it, but "Infinite" is a bug.
    // We will assume "Sustain On" means "Let it ring for a bit longer" or "Don't cut abruptly"?
    // The user report "sustains forever" confirms we MUST send stopNote.

    Future.delayed(Duration(milliseconds: durationMs), () {
      _midi.stopNote(key: note, channel: midiChannel, sfId: sfId);
    });
  }

  void _triggerDelay(
    int note,
    int velocity,
    int durationMs,
    int sfId,
    int midiChannel,
    SoundFontChannel config,
  ) {
    int delayMs = config.delayTime.toInt();
    double feedback = config.delayFeedback;

    // Echo 1
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      _midi.playNote(
        key: note,
        velocity: (velocity * feedback).toInt(),
        channel: midiChannel,
        sfId: sfId,
      );
      // Echo Stop
      Future.delayed(Duration(milliseconds: durationMs), () {
        _midi.stopNote(key: note, channel: midiChannel, sfId: sfId);
      });
    });

    // Echo 2
    Future.delayed(Duration(milliseconds: delayMs * 2), () {
      if (!mounted) return;
      _midi.playNote(
        key: note,
        velocity: (velocity * feedback * feedback).toInt(),
        channel: midiChannel,
        sfId: sfId,
      );
      Future.delayed(Duration(milliseconds: durationMs), () {
        _midi.stopNote(key: note, channel: midiChannel, sfId: sfId);
      });
    });
  }

  void _loadPreset(InstrumentPreset preset) {
    // Update current channel with preset values
    final newChannel = _musicConfig.currentChannel.copyWith(
      brushSpread: preset.brushSpread,
      brushOpacity: preset.brushOpacity,
      bristleCount: preset.bristleCount,
      useNeonGlow: preset.useNeonGlow,
      colorValue: preset.colorValue,
      triggerOnBoundary: preset.triggerOnBoundary,
      soundFont: preset.soundFont,
      program: preset.programIndex,
      isDelayOn: preset.isDelayOn,
      delayTime: preset.delayTime,
      delayFeedback: preset.delayFeedback,
      reverbLevel: preset.reverbLevel,
      isSustainOn: preset.isSustainOn,
      channelVolume: preset.lineVolume,
    );
    _updateChannel(newChannel);
  }

  int _noteNameToMidi(String noteName) {
    int noteIndex = MusicConfiguration.keys.indexOf(noteName);
    if (noteIndex == -1) noteIndex = 0;
    return noteIndex;
  }

  List<int> _getScaleOffsets(String scaleName) {
    // Basic simplified map, ideal would be to use MusicConfig static maps if accessible or re-declare
    switch (scaleName) {
      case 'Major':
        return [0, 2, 4, 5, 7, 9, 11];
      case 'Minor':
        return [0, 2, 3, 5, 7, 8, 10];
      case 'Dorian':
        return [0, 2, 3, 5, 7, 9, 10];
      case 'Phrygian':
        return [0, 1, 3, 5, 7, 8, 10];
      case 'Lydian':
        return [0, 2, 4, 6, 7, 9, 11];
      case 'Mixolydian':
        return [0, 2, 4, 5, 7, 9, 10];
      case 'Locrian':
        return [0, 1, 3, 5, 6, 8, 10];
      case 'Pentatonic Major':
        return [0, 2, 4, 7, 9];
      case 'Pentatonic Minor':
        return [0, 3, 5, 7, 10];
      case 'Chromatic':
        return [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
      default:
        return [0, 2, 4, 5, 7, 9, 11];
    }
  }

  void _updateConfig(MusicConfiguration config) {
    final bool droneVolumeChanged =
        config.droneVolume != _musicConfig.droneVolume;

    setState(() {
      _musicConfig = config;
    });

    if (droneVolumeChanged && _musicConfig.droneEnabled) {
      // Force re-trigger of current drone notes with new volume
      _updateDroneNotes(_activeDroneNotes, forceRetrigger: true);
    }
  }

  Future<void> _loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? presetsJson = prefs.getString('instrument_presets');
    if (presetsJson != null) {
      final List<dynamic> decoded = jsonDecode(presetsJson);
      setState(() {
        _presets = decoded.map((e) => InstrumentPreset.fromJson(e)).toList();
      });
    }
  }

  Future<void> _savePreset(String name) async {
    final currentCh = _musicConfig.currentChannel;

    // Check if overwrite
    int existingIndex = _presets.indexWhere((p) => p.name == name);
    List<InstrumentPreset> newPresets = List.from(_presets);

    final newPreset = InstrumentPreset(
      name: name,
      brushSpread: currentCh.brushSpread,
      brushOpacity: currentCh.brushOpacity,
      bristleCount: currentCh.bristleCount,
      useNeonGlow: currentCh.useNeonGlow,
      colorValue: currentCh.colorValue,
      triggerOnBoundary: currentCh.triggerOnBoundary,
      minPixelsForTrigger: 10.0,
      soundFont: currentCh.soundFont,
      programIndex: currentCh.program,
      isDelayOn: currentCh.isDelayOn,
      delayTime: currentCh.delayTime,
      delayFeedback: currentCh.delayFeedback,
      reverbLevel: currentCh.reverbLevel,
      isSustainOn: currentCh.isSustainOn,
      directionChangeThreshold: _musicConfig.directionChangeThreshold,
      lineVolume: currentCh.channelVolume,
    );

    if (existingIndex != -1) {
      newPresets[existingIndex] = newPreset;
    } else {
      newPresets.add(newPreset);
    }

    setState(() {
      _presets = newPresets;
    });

    // Save to Disk
    await _savePresetsToDisk();
  }

  Future<void> _savePresetsToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_presets.map((e) => e.toJson()).toList());
    await prefs.setString('instrument_presets', encoded);
  }

  Future<void> _loadCanvases() async {
    final canvases = await _canvasRepo.getAllCanvases();
    setState(() {
      _savedCanvases = canvases;
    });
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    Widget activePane;

    if (_selectedPaneIndex == null) {
      activePane = Container();
    } else {
      switch (_selectedPaneIndex) {
        case 0:
          activePane = MidiSettingsPane(
            config: _musicConfig,
            onConfigChanged: _updateConfig,
          );
          break;
        case 1:
          activePane = SequencerSettingsPane(
            config: _musicConfig,
            onConfigChanged: _updateConfig,
          );
          break;
        case 2:
          activePane = BackgroundPane(
            config: _musicConfig,
            onConfigChanged: _updateConfig,
            currentDetectedColor: _currentDroneColor,
            availableSoundFonts: _soundFonts,
            gradientStrokes: _gradientStrokes,
            onStrokeUpdated: (idx, stroke) => setState(() {
              if (idx >= _gradientStrokes.length) {
                _gradientStrokes.add(stroke);
              } else {
                _gradientStrokes[idx] = stroke;
              }
            }),
            onStrokeDeleted: (idx) =>
                setState(() => _gradientStrokes.removeAt(idx)),
          );
          break;
        case 3:
          activePane = ChannelSettingsPane(
            channel: _musicConfig.currentChannel,
            onChannelChanged: _updateChannel,
            availableSoundFonts: _soundFonts,
            channelIndex: _musicConfig.selectedChannelIndex, // Added Argument
          );
          break;
        case 4:
          activePane = LibraryPane(
            instrumentPresets: _presets,
            onSaveInstrument: _savePreset,
            onLoadInstrument: _loadPreset,
            onDeleteInstrument: (preset) {
              setState(() => _presets.remove(preset));
              _savePreset(preset.name);
            },
            canvasPresets: _savedCanvases,
            onSaveCanvas: (name) {},
            onLoadCanvas: (model) {},
            onDeleteCanvas: (model) async {
              await _canvasRepo.deleteCanvas(model.id);
              _loadCanvases();
            },
          );
          break;
        case 5:
          activePane = AppSettingsPane(
            showNoteLines: _showNoteLines,
            onShowNoteLinesChanged: (v) => setState(() => _showNoteLines = v),
          );
          break;
        default:
          activePane = Container();
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // Toolbar (Left, always visible)
          ToolbarWidget(
            selectedPaneIndex: _selectedPaneIndex,
            onPaneSelected: (index) {
              setState(() {
                if (_selectedPaneIndex == index) {
                  _selectedPaneIndex = null;
                } else {
                  _selectedPaneIndex = index;
                }
              });
            },
            selectedChannelIndex: _musicConfig.selectedChannelIndex,
            onChannelSelected: _selectChannel,
            isGradientToolActive: _currentMode == DrawingMode.gradient,
            onGradientToolSelected: _selectGradientTool,
          ),

          // Main Content Area (SplitLayout)
          Expanded(
            child: SplitLayout(
              pane: _selectedPaneIndex != null ? activePane : null,
              paneAtStart: true,
              content: Stack(
                children: [
                  // 1. Canvas
                  Positioned.fill(
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.space):
                            _togglePlay,
                        // Number Keys for Channels
                        const SingleActivator(LogicalKeyboardKey.digit1): () =>
                            _selectChannel(0),
                        const SingleActivator(LogicalKeyboardKey.digit2): () =>
                            _selectChannel(1),
                        const SingleActivator(LogicalKeyboardKey.digit3): () =>
                            _selectChannel(2),
                        const SingleActivator(LogicalKeyboardKey.digit4): () =>
                            _selectChannel(3),
                        const SingleActivator(LogicalKeyboardKey.digit5): () =>
                            _selectChannel(4),
                        const SingleActivator(LogicalKeyboardKey.digit6): () =>
                            _selectChannel(5),
                        const SingleActivator(LogicalKeyboardKey.digit7): () =>
                            _selectChannel(6),
                        const SingleActivator(LogicalKeyboardKey.digit8): () =>
                            _selectChannel(7),
                        // Tool Keys
                        const SingleActivator(LogicalKeyboardKey.digit0):
                            _selectGradientTool,
                      },
                      child: Focus(
                        focusNode: _focusNode,
                        autofocus: true,
                        child: CanvasWidget(
                          musicConfig: _musicConfig,
                          showNoteLines: _showNoteLines,
                          segmentLength: _segmentLength,
                          minPixels: _minPixels,
                          lines: _lines,
                          currentLine: _currentLine,
                          drawingMode: _currentMode,
                          selectedChannelIndex: _musicConfig
                              .selectedChannelIndex, // Added Property
                          // Channel Config Props
                          selectedColor: Color(
                            _musicConfig.currentChannel.colorValue,
                          ),
                          triggerOnBoundary:
                              _musicConfig.currentChannel.triggerOnBoundary,
                          currentBrushSpread:
                              _musicConfig.currentChannel.brushSpread,
                          currentBrushOpacity:
                              _musicConfig.currentChannel.brushOpacity,
                          currentBristleCount:
                              _musicConfig.currentChannel.bristleCount,
                          currentUseNeonGlow:
                              _musicConfig.currentChannel.useNeonGlow,

                          // Misc
                          showPlayLine: _musicConfig.showPlayLine,
                          playLineAnimation: _playLineController,
                          backgroundShader: _backgroundShader,
                          gradientStrokes: _gradientStrokes,
                          showGradientOverlays: _selectedPaneIndex == 2,
                          // Callbacks
                          onCurrentLineUpdated: (line) {
                            setState(() {
                              _currentLine = line;
                            });
                          },
                          onLineCompleted: (line) {
                            // NEW: Inject Channel Index into Line
                            final lineWithChannel = DrawnLine(
                              id: line.id,
                              path: line.path,
                              color: line.color,
                              width: line.width,
                              soundFont: line.soundFont,
                              program: line.program,
                              sfId: line.sfId,
                              instrumentSlotIndex: line.instrumentSlotIndex,
                              channelIndex: _musicConfig
                                  .selectedChannelIndex, // INJECT HERE
                              spread: line.spread,
                              opacity: line.opacity,
                              bristleCount: line.bristleCount,
                              useNeonGlow: line.useNeonGlow,
                            );

                            setState(() {
                              _lines = List.from(_lines)..add(lineWithChannel);
                              _currentLine = null;
                            });
                          },
                          onLineDeleted: (line) {
                            setState(() {
                              _lines = List.from(_lines)..remove(line);
                            });
                          },
                          onNoteTriggered: (noteIndex, line) {
                            _triggerLineSound(noteIndex, line);
                          },

                          onGradientStrokeAdded: (stroke) {
                            setState(() {
                              _gradientStrokes.add(stroke);
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  // 2. Transport Bar (Now Top)
                  Positioned(
                    left: 20,
                    right: 20,
                    top: 20, // Moved from bottom to top
                    child: TransportBar(
                      isPlaying: _isPlaying,
                      onPlayPause: _togglePlay,
                      onStop: _stop,
                      isMetronomeOn: _isMetronomeOn,
                      onMetronomeToggle: _toggleMetronome,
                      currentTick: _currentTick,
                      gridBeats: _musicConfig.totalBeats,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
