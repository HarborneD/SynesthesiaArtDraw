import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui; // For FragmentProgram
import 'package:flutter/gestures.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/presentation/layout/split_layout.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import '../../transport/presentation/transport_bar.dart';
import '../../canvas/presentation/canvas_widget.dart';
import '../../canvas/presentation/background_gradient_painter.dart';
import '../../drawing/presentation/drawing_tools_pane.dart';
import '../../drone/presentation/drone_settings_pane.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:synesthesia_art_draw/features/instrument/domain/instrument_preset.dart';
import '../../instrument/presentation/instrument_settings_pane.dart';
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
import 'package:uuid/uuid.dart';

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
  Color _selectedLineColor = Colors.teal; // Default line color (9th)
  bool _triggerOnBoundary = true; // Default ON

  // Brush Customization
  double _brushSpread = 7.0;
  double _brushOpacity = 0.5;
  int _bristleCount = 40;
  bool _useNeonGlow = true;

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
  bool _isDelayOn = true; // Renamed from Reverb
  double _delayTime = 500.0; // Renamed from reverbDelay
  double _delayFeedback = 0.6; // Renamed from reverbDecay

  double _reverbLevel = 0.3; // True Reverb (CC91)
  int _sfId = 0;
  int _droneSfId = 0;
  List<InstrumentPreset> _presets = [];

  // Canvas Library State
  List<CanvasModel> _savedCanvases = [];
  final _canvasRepo = CanvasRepository();
  final _uuid = const Uuid();

  // Sustain State
  bool _isSustainOn = true;
  int _currentMidiNote = -1;
  int _currentMidiNoteSfId = -1; // Track which SF triggered the note

  // Optimization: Track last instrument set on Channel 0
  int? _lastChannel0SfId;
  int? _lastChannel0Program;

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
    _initMidi(); // This handles loading the initial SoundFont
    _loadShader();
    _loadShader();
    _loadPresets();
    _loadCanvases();
    _playLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Initial default
    );
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
    // Preload sounds for lower latency
    /*
  try {
    await _playerDown.setSource(AssetSource('metronome/Zoom ST Down .wav'));
    await _playerDown.setPlayerMode(PlayerMode.lowLatency);

    await _playerUp.setSource(AssetSource('metronome/Zoom ST UP.wav'));
    await _playerUp.setPlayerMode(PlayerMode.lowLatency);
  } catch (e) {
    debugPrint("Error loading audio: $e");
  }
  */

    // Load Drawing SoundFont
    await _loadSoundFont(_musicConfig.currentSlot.soundFont);

    // Load Drone SoundFont
    await _loadDroneSoundFont(_musicConfig.droneSoundFont);

    // Initialize Drone Channel (1)
    /*
    try {
      await _midi.selectInstrument(
        sfId: _droneSfId,
        program: _musicConfig.droneInstrument,
        channel: 1,
      );
    } catch (e) {
      debugPrint("Failed to init Drone instrument: $e");
    }
    */

    setState(() {
      _isMidiInitialized = true;
    });
  }

  Future<void> _loadDroneSoundFont(String fileName) async {
    try {
      if (_loadedSoundFonts.containsKey(fileName)) {
        _droneSfId = _loadedSoundFonts[fileName]!;
      } else {
        final path = 'assets/sounds_fonts/$fileName';
        _droneSfId = await _midi.loadSoundfontAsset(assetPath: path);
        _loadedSoundFonts[fileName] = _droneSfId;
        debugPrint("Loaded Drone SoundFont: $path (ID: $_droneSfId)");
      }
    } catch (e) {
      debugPrint("Error loading Drone SoundFont: $e");
    }
  }

  Future<void> _updateDroneInstrument() async {
    try {
      await _midi.selectInstrument(
        sfId: _droneSfId,
        program: _musicConfig.droneInstrument,
        channel: 1,
      );
    } catch (e) {
      debugPrint("Failed to update Drone instrument: $e");
    }
  }

  Future<void> _loadSoundFont(String fileName) async {
    try {
      if (_loadedSoundFonts.containsKey(fileName)) {
        _sfId = _loadedSoundFonts[fileName]!;
      } else {
        final path = 'assets/sounds_fonts/$fileName';
        _sfId = await _midi.loadSoundfontAsset(assetPath: path);
        _loadedSoundFonts[fileName] = _sfId;
        debugPrint("Loaded SoundFont: $path (ID: $_sfId)");
      }

      // Fix: Ensure we select the instrument on the new SoundFont for Channel 0
      // This helps prevent "layering" or stuck instruments from previous SFs
      // NOTE: This now only affects the 'active' drawing instrument
      _midi.selectInstrument(
        sfId: _sfId,
        program: _musicConfig.currentSlot.program,
        channel: 0,
      );
    } catch (e) {
      debugPrint("Error loading SoundFont: $e");
    }
  }

  void _cycleSoundFont(int direction) {
    int currentIndex = _soundFonts.indexOf(_musicConfig.currentSlot.soundFont);
    if (currentIndex == -1) currentIndex = 0;

    int newIndex = (currentIndex + direction) % _soundFonts.length;
    if (newIndex < 0) newIndex = _soundFonts.length - 1;

    final newFont = _soundFonts[newIndex];
    // Update Config
    final updatedSlots = List<InstrumentSlot>.from(
      _musicConfig.instrumentSlots,
    );
    updatedSlots[_musicConfig.selectedInstrumentSlot] = _musicConfig.currentSlot
        .copyWith(soundFont: newFont);

    final newConfig = _musicConfig.copyWith(instrumentSlots: updatedSlots);
    _updateConfig(newConfig);

    _loadSoundFont(newFont);
  }

  void _cycleInstrument(int direction) {
    int newProgram = (_musicConfig.currentSlot.program + direction) % 128;
    if (newProgram < 0) newProgram = 127;

    // Update Config
    final updatedSlots = List<InstrumentSlot>.from(
      _musicConfig.instrumentSlots,
    );
    updatedSlots[_musicConfig.selectedInstrumentSlot] = _musicConfig.currentSlot
        .copyWith(program: newProgram);

    final newConfig = _musicConfig.copyWith(instrumentSlots: updatedSlots);
    _updateConfig(newConfig);

    _midi.selectInstrument(sfId: _sfId, program: newProgram, channel: 0);
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
        // Pause: Silence Drone notes
        _updateDroneNotes([]);
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

      // Stop Audio
      _playerDown.stop();
      _playerUp.stop();

      // Stop Drone Notes
      _updateDroneNotes([]);

      // Stop MIDI (Best effort)
      // flutter_midi_pro doesn't have a global "stop all", but we can rely on our duration logic
      // to eventually clean up. If we need immediate silence, we'd need to track active notes.
    });
  }

  void _toggleMetronome() {
    setState(() {
      _isMetronomeOn = !_isMetronomeOn;
    });
  }

  void _toggleDelay() {
    setState(() {
      _isDelayOn = !_isDelayOn;
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

  void _clearAll() {
    setState(() {
      _lines = []; // Assign new list to trigger RepaintBoundary
      _currentLine = null;
      _gradientStrokes.clear();
    });
  }

  void _startTimer() {
    _clockTimer?.cancel();
    if (!_isPlaying) return;

    final double msPerTick = 60000 / _musicConfig.tempo;

    // Sync Animation Controller
    // Loop length = gridBars * 4 beats * (60000/tempo)
    // Actually msPerTick is 1/4 of a beat (16th note)? No, usually metronome is quarter notes?
    // Let's assume Config Tempo is BPM (Quarter notes).
    // Tick is... handled every "tick".
    // Code says: `_currentTick = (_currentTick + 1) % gridBeats`.
    // If gridBeats=16 (4 bars), and timer fires every `msPerTick`.
    // If standard 4/4, 16 ticks = 4 bars means each tick is a beat?
    // "dots representing 4 bars of 4... 16 beats total." -> Yes, 1 tick = 1 beat.

    final totalBeats = _musicConfig.totalBeats;
    final loopDurationMs = (msPerTick * totalBeats).round();

    // Start the loop
    _playLineController.duration = Duration(milliseconds: loopDurationMs);
    _playLineController.repeat();

    // Execute first tick actions immediately
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
      // Use standard play() - more reliable for one-shots
      player.play(source);
    }

    // Check for Drone Updates
    // We want to update every N bars.
    // 1 Bar = 4 beats (standard assumption for this grid).
    final beatsPerInterval = _musicConfig.droneUpdateIntervalBars * 4;

    if (_musicConfig.droneEnabled && (_currentTick % beatsPerInterval == 0)) {
      _processDroneLogic();
    }

    // Check for line triggers
    _checkLineTriggers();

    // REMOVED: Duplicate setState increment.
    // The increment happens in the Timer callback in _startTimer.
  }

  void _processDroneLogic() {
    // 1. Get Scan Line Color
    final scanX = _playLineController.value; // 0.0 to 1.0
    final color = _getScanLineColor(scanX);
    _currentDroneColor = color;

    // 2. Determine Harmonic Function
    final hsl = HSLColor.fromColor(color);
    final hue = hsl.hue;

    // 3. Map Hue to Scale Degrees
    // Red/Orange (330-30) -> Tonic (I) -> Degrees 1, 3, 5, 7
    // Green/Yellow (60-180) -> Subdominant (IV) -> Degrees 4, 6, 1, 3 (relative to tonic)
    // Blue/Violet (180-300) -> Dominant (V) -> Degrees 5, 7, 2, 4

    List<int> targetDegrees = [];

    // Simplified mapping based on diatonic steps (1-based index in selectedDegrees)
    // NOTE: selectedDegrees are Strings "1", "b3", etc.
    // We need to map Function -> abstract degrees -> find in available scale degrees.
    // Let's assume standard index logic: Tonic=0,2,4; Sub=3,5,0; Dom=4,6,1.

    if (hue >= 330 || hue <= 30) {
      // Tonic (1, 3, 5) => Indices 0, 2, 4
      targetDegrees = [0, 2, 4];
    } else if (hue >= 60 && hue <= 180) {
      // Subdominant (4, 6, 1) => Indices 3, 5, 0
      targetDegrees = [3, 5, 0];
    } else if (hue > 180 && hue < 300) {
      // Dominant (5, 7, 2) => Indices 4, 6, 1
      targetDegrees = [4, 6, 1];
    } else {
      // Transition/Other -> Tonic
      targetDegrees = [0, 2, 4];
    }

    // 4. Generate Notes
    // Convert abstract indices to actual MIDI notes based on Key/Scale
    // Filter by what is actually enabled in `_musicConfig.selectedDegrees`?
    // Usually a drone uses the underlying scale.
    // Let's use `MidiPro` helper if available or manual calculation.

    // 4. Generate Notes
    // Convert abstract indices to actual MIDI notes based on Key/Scale

    final rootNote = _noteNameToMidi(_musicConfig.selectedKey);
    final scaleOffsets = _getScaleOffsets(_musicConfig.selectedScale);

    List<int> newNotes = [];
    int baseOctave = 3; // Low drone

    // Generate notes for the configured density
    for (int i = 0; i < _musicConfig.droneDensity; i++) {
      // Wrap around available degrees
      final degreeIndex = targetDegrees[i % targetDegrees.length];

      // Safety check
      if (degreeIndex < scaleOffsets.length) {
        int offset = scaleOffsets[degreeIndex];
        int note = rootNote + offset + (baseOctave * 12);

        // Spread high notes up an octave
        if (i >= 3) note += 12;

        newNotes.add(note);
      }
    }

    // 5. Playback Update
    _updateDroneNotes(newNotes);
  }

  void _updateDroneNotes(List<int> newNotes) {
    // Basic diffing to avoid re-triggering held notes?
    // For now, kill all -> start new (Legato-ish?)
    // Or sustain if same?

    // Stop old notes that are NOT in new set
    for (final note in _activeDroneNotes) {
      if (!newNotes.contains(note)) {
        _midi.stopNote(
          key: note,
          channel: 1, // Drone Channel
          sfId: _droneSfId,
        );
      }
    }

    // Start new notes that were NOT in old set
    for (final note in newNotes) {
      if (!_activeDroneNotes.contains(note)) {
        int velocity = (80 * _musicConfig.droneVolume).round().clamp(0, 127);
        _midi.playNote(
          key: note,
          velocity: velocity,
          channel: 1, // Drone Channel
          sfId: _droneSfId, // Use Drone SF
        );
      }
    }
    _activeDroneNotes = newNotes;
  }

  // When volume changes, we might need to re-trigger drone notes?
  // Or just wait for next update?
  // Let's force update if volume changes in _updateConfig?
  // Actually, Velocity is set on Note On. To change volume of sustained notes,
  // we would need to stop and restart them.
  // For now, let's accept that volume change works on *next* note trigger.
  // Or: In `_updateConfig`, if volume changed, we can call `_updateDroneNotes(_activeDroneNotes)`?
  // Implemented in future step if needed.

  Color _getScanLineColor(double xPercent) {
    // 1. Check Drawn Lines (Priority)
    // We check lines first because they are "on top" usually.
    final xPos = xPercent * MediaQuery.of(context).size.width;

    int lineCount = 0;
    double r = 0, g = 0, b = 0;

    for (final line in _lines) {
      if (line.path.length < 2) continue;
      // Optimization: Check bounds of entire line first?
      // For now, segment check is robust.
      for (int i = 0; i < line.path.length - 1; i++) {
        final p1 = line.path[i].point;
        final p2 = line.path[i + 1].point;

        // Check if the scan line (vertical at xPos) intersects this segment
        // Simple X-range check.
        if ((p1.dx <= xPos && p2.dx >= xPos) ||
            (p1.dx >= xPos && p2.dx <= xPos)) {
          // Found intersection.
          // Color might be solid or dependent on segment?
          // `line.color` is the base.
          final c = line.color;
          r += c.red;
          g += c.green;
          b += c.blue;
          lineCount++;
          break; // Count line once per scan to avoid double-weighting zig-zags
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

    // 2. Check Background Gradients (Fallback)
    // If no lines, we sample the background.
    // We need to approximate the color at xPercent.
    if (_gradientStrokes.isNotEmpty) {
      // Find the most recent stroke that covers this area, or blend them?
      // Shader blends them.
      // Let's iterate in reverse (topmost first) or blend all.
      // Since it's a "field", blending all might be safer.

      double wSum = 0.0;
      double accR = 0.0;
      double accG = 0.0;
      double accB = 0.0;

      // Helper: sRGB to Linear (Approx Gamma 2.2)
      double toLinear(double c) => pow(c / 255.0, 2.2).toDouble();
      // Helper: Linear to sRGB
      int toSrgb(double c) => (pow(c, 1.0 / 2.2) * 255.0).round().clamp(0, 255);

      for (final stroke in _gradientStrokes) {
        final p0 = stroke.p0;
        final p1 = stroke.p1;
        final radius = stroke.intensity;

        // Find closest point on segment (p0 -> p1) to vertical line (x = xPos)
        // Segment parameter t. Point P(t) = p0 + t*(p1-p0).
        // We want to minimize distance to xPos.
        // Actually, simpler:
        // If xPos is between p0.dx and p1.dx, distance is 0 (it crosses).
        // If xPos is outside, closest is endpoints.

        double dist = 0.0;
        double t = 0.0; // Where on the segment we are sampling

        // Sorting X to find range
        final minX = min(p0.dx, p1.dx);
        final maxX = max(p0.dx, p1.dx);

        if (xPos >= minX && xPos <= maxX) {
          // Intersection! Dist is 0 (as far as X is concerned).
          // But wait, the Shader is 2D Radial.
          // If the stroke is horizontal at y=0, and we are looking at the vertical line x=50.
          // And we want the "Visual Color of the Line".
          // The line passes through the stroke. At intersection, D=0. Weight=1.
          // So we should capture that Peak Identity.
          dist = 0.0;

          // Calculate t at intersection X
          final vdx = p1.dx - p0.dx;
          if (vdx.abs() > 0.001) {
            t = (xPos - p0.dx) / vdx;
          } else {
            t = 0.5; // Vertical line stroke?
          }
        } else {
          // Outside range. Closest point is endpoint.
          final d0 = (p0.dx - xPos).abs();
          final d1 = (p1.dx - xPos).abs();
          if (d0 < d1) {
            dist = d0;
            t = 0.0;
          } else {
            dist = d1;
            t = 1.0;
          }
          // Note: Does vertical Y distance matter here here?
          // If stroke is far away in Y, but "closest in X"?
          // If we conceptually "Scan" the vertical line, we find the stroke eventually if X matches.
          // If X mismatches, we are looking at the distance to the "Column".
          // Shader uses radial falloff from segment.
          // If we are at X, and stroke is at X but Y=1000 away?
          // "Intersection" implies distance 0?
          // If the user's intent is "What color is this X column?", then yes, intersection counts as 100%.
          // But if the stroke has finite length?
          // GradientStroke has p0, p1. The segment defines it.
          // So yes, if xPos intersects the segment's X-range, it visually crosses the stroke.
        }

        t = t.clamp(0.0, 1.0);

        if (dist < radius) {
          final weight = 1.0 - (dist / radius);

          // Interpolate Color
          final c1 = stroke.colors.first;
          final c2 = stroke.colors.last;

          // Linear Interpolation of raw sRGB values (standard simple lerp)
          final mixedR = c1.red + (c2.red - c1.red) * t;
          final mixedG = c1.green + (c2.green - c1.green) * t;
          final mixedB = c1.blue + (c2.blue - c1.blue) * t;

          // Accumulate in Linear Space
          accR += toLinear(mixedR) * weight;
          accG += toLinear(mixedG) * weight;
          accB += toLinear(mixedB) * weight;
          wSum += weight;
        }
      }

      if (wSum > 0.0) {
        // Average and convert back to sRGB
        return Color.fromARGB(
          255,
          toSrgb(accR / wSum),
          toSrgb(accG / wSum),
          toSrgb(accB / wSum),
        );
      }
    }

    return Colors.black; // Fallback
  }

  // Track lines currently intersecting the scanline to avoid re-triggering
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

        // Check intersection with vertical line at xPos
        if ((p1.dx <= xPos && p2.dx >= xPos) ||
            (p1.dx >= xPos && p2.dx <= xPos)) {
          // Calculate Y at intersection
          if ((p1.dx - p2.dx).abs() < 0.001) {
            intersectY = p1.dy; // Vertical segment
          } else {
            final t = (xPos - p1.dx) / (p2.dx - p1.dx);
            intersectY = p1.dy + t * (p2.dy - p1.dy);
          }

          intersects = true;
          break; // Found one intersection point for this line
        }
      }

      if (intersects) {
        currentIntersections.add(line);
        if (!_intersectingLines.contains(line)) {
          // New intersection - Trigger!
          _triggerLineSound(line, intersectY, screenHeight);
          _intersectingLines.add(line);
        }
      }
    }

    // Remove lines that are no longer intersecting
    _intersectingLines.removeWhere(
      (line) => !currentIntersections.contains(line),
    );
  }

  void _triggerLineSound(DrawnLine line, double yPos, double screenHeight) {
    // Map Y to Pitch
    // 1.0 (Bottom) -> Low Pitch, 0.0 (Top) -> High Pitch?
    // Usually Canvas Y=0 is Top.
    // Let's invert: Top=High, Bottom=Low.
    // normalized Y 0..1
    double yNorm = (yPos / screenHeight).clamp(0.0, 1.0);

    // Invert so high Y (bottom) is low pitch, low Y (top) is high pitch
    yNorm = 1.0 - yNorm;

    final allNotes = _musicConfig.getAllMidiNotes();
    if (allNotes.isEmpty) return;

    int noteIndex = (yNorm * (allNotes.length - 1)).round();
    int note = allNotes[noteIndex];

    // Velocity based on something? Line width?
    // Scale by Volume
    int baseVelocity = 100;
    int velocity = (baseVelocity * _musicConfig.lineVolume).round().clamp(
      0,
      127,
    );

    // Duration?
    int duration = 200; // ms

    _playNoteWithDuration(
      note,
      velocity,
      duration,
      sfId: _sfId, // Use Drawing SF
    );
    debugPrint("Triggered Line Sound: Note $note, SF ID: $_sfId");
  }

  // Helper to play note with duration (prevents infinite sustain)
  void _playNoteWithDuration(
    int note,
    int velocity,
    int durationMs, {
    required int sfId,
  }) {
    if (!_isMidiInitialized) return;

    _midi.playNote(key: note, velocity: velocity, channel: 0, sfId: sfId);

    Future.delayed(Duration(milliseconds: durationMs), () {
      _midi.stopNote(key: note, channel: 0, sfId: sfId);
    });

    if (_isDelayOn) {
      _triggerDelay(note, velocity, durationMs, sfId);
    }
  }

  void _triggerDelay(int note, int velocity, int durationMs, int sfId) {
    // Dynamic Echo Logic (Tape Delay Simulation)
    int delayMs = _delayTime.toInt();

    // Echo 1
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      _midi.playNote(
        key: note,
        velocity: (velocity * _delayFeedback).toInt(),
        channel: 0,
        sfId: sfId,
      );
      Future.delayed(Duration(milliseconds: durationMs), () {
        _midi.stopNote(key: note, channel: 0, sfId: sfId);
      });
    });

    // Echo 2 (2x delay, decay^2)
    Future.delayed(Duration(milliseconds: delayMs * 2), () {
      if (!mounted) return;
      _midi.playNote(
        key: note,
        velocity: (velocity * _delayFeedback * _delayFeedback).toInt(),
        channel: 0,
        sfId: sfId,
      );
      Future.delayed(Duration(milliseconds: durationMs), () {
        _midi.stopNote(key: note, channel: 0, sfId: sfId);
      });
    });
  }

  // Send MIDI CC 91 (Effects 1 Depth - usually Reverb)
  void _setReverb(double level) {
    // Level 0.0 to 1.0 -> 0 to 127
    final val = (level.clamp(0.0, 1.0) * 127).toInt();
    // _midi.sendControlChange(channel: 0, controller: 91, value: val);
    debugPrint("Reverb CC 91: $val (Not supported by flutter_midi_pro yet)");
    // Also send to Drone channel just in case? Or separate knob?
    // Let's assume global reverb for now or just instrument.
    // User requested separate reverb, likely for the instrument.
  }

  // When Tempo changes, we need to restart timer if playing
  void _updateConfig(MusicConfiguration newConfig) {
    if (newConfig == _musicConfig) return;

    // Detect Changes
    final droneSfChanged =
        newConfig.droneSoundFont != _musicConfig.droneSoundFont;
    final droneInstChanged =
        newConfig.droneInstrument != _musicConfig.droneInstrument;
    final tempoChanged = newConfig.tempo != _musicConfig.tempo;
    final barsChanged = newConfig.gridBars != _musicConfig.gridBars;

    // Detect Volume Changes

    setState(() {
      _musicConfig = newConfig;
    });

    if (droneSfChanged) {
      _loadDroneSoundFont(newConfig.droneSoundFont).then((_) {
        _updateDroneInstrument();
      });
    } else if (droneInstChanged) {
      _updateDroneInstrument();
    }

    if ((tempoChanged || barsChanged) && _isPlaying) {
      _startTimer();
    }
  }

  /*
  void _setChannelVolume(int channel, double volume) {
    // MIDI CC 7 is Volume (0-127)
    // flutter_midi_pro does not support CC yet.
    // We will use velocity scaling instead.
  }
  */

  Widget? _getPane(int? index) {
    if (index == null) return null;

    switch (index) {
      case 0:
        return DrawingToolsPane(
          currentMode: _currentMode,
          onModeChanged: (mode) => setState(() => _currentMode = mode),
          segmentLength: _segmentLength,
          onSegmentLengthChanged: (val) => setState(() => _segmentLength = val),
          minPixels: _minPixels,
          onMinPixelsChanged: (val) => setState(() => _minPixels = val),
          onClearAll: _clearAll,

          triggerOnBoundary: _triggerOnBoundary,
          onTriggerOnBoundaryChanged: (val) =>
              setState(() => _triggerOnBoundary = val),

          // Color Props
          selectedColor: _selectedLineColor,
          onColorChanged: (color) => setState(() => _selectedLineColor = color),

          gradientStrokes: _gradientStrokes,
          onStrokeUpdated: (idx, newStroke) => setState(() {
            _gradientStrokes[idx] = newStroke;
          }),
          onStrokeDeleted: (idx) => setState(() {
            _gradientStrokes.removeAt(idx);
          }),

          // Brush Props
          brushSpread: _brushSpread,
          onBrushSpreadChanged: (val) => setState(() => _brushSpread = val),
          brushOpacity: _brushOpacity,
          onBrushOpacityChanged: (val) => setState(() => _brushOpacity = val),
          bristleCount: _bristleCount,
          onBristleCountChanged: (val) => setState(() => _bristleCount = val),
          useNeonGlow: _useNeonGlow,
          onNeonGlowChanged: (val) => setState(() => _useNeonGlow = val),
        );
      case 1: // Midi Settings Pane
        return MidiSettingsPane(
          config: _musicConfig,
          onConfigChanged: _updateConfig,
        );
      case 2: // Instrument Pane
        return InstrumentSettingsPane(
          availableSoundFonts: _soundFonts,
          isDelayOn: _isDelayOn,
          onDelayChanged: (val) => _toggleDelay(),
          delayTime: _delayTime,
          onDelayTimeChanged: (val) => setState(() => _delayTime = val),
          delayFeedback: _delayFeedback,
          onDelayFeedbackChanged: (val) => setState(() => _delayFeedback = val),
          reverbLevel: _reverbLevel,
          onReverbLevelChanged: (val) => setState(() {
            _reverbLevel = val;
            _setReverb(val);
          }),
          isSustainOn: _isSustainOn,
          onSustainChanged: (val) => setState(() => _isSustainOn = val),
          directionChangeThreshold: _musicConfig.directionChangeThreshold,
          onDirectionChangeThresholdChanged: (val) => _updateConfig(
            _musicConfig.copyWith(directionChangeThreshold: val),
          ),
          selectedSoundFont: _musicConfig.currentSlot.soundFont,
          onSoundFontChanged: (val) async {
            // Update SoundFont for CURRENT SLOT
            if (val != _musicConfig.currentSlot.soundFont) {
              // Update Config Logic
              final updatedSlots = List<InstrumentSlot>.from(
                _musicConfig.instrumentSlots,
              );
              updatedSlots[_musicConfig.selectedInstrumentSlot] = _musicConfig
                  .currentSlot
                  .copyWith(soundFont: val);

              final newConfig = _musicConfig.copyWith(
                instrumentSlots: updatedSlots,
              );
              _updateConfig(newConfig);

              // Trigger Load
              await _loadSoundFont(val);
            }
          },
          selectedInstrumentIndex: _musicConfig.selectedInstrumentSlot,
          onInstrumentChanged: (val) {
            // Change Selected Slot
            _updateConfig(_musicConfig.copyWith(selectedInstrumentSlot: val));
            // Ensure we load/select the sound font for this new slot
            final newSlot = _musicConfig.instrumentSlots[val];
            _loadSoundFont(newSlot.soundFont).then((_) {
              _midi.selectInstrument(
                sfId: _loadedSoundFonts[newSlot.soundFont] ?? _sfId,
                program: newSlot.program,
              );
            });
          },
          selectedProgram: _musicConfig.currentSlot.program,
          onProgramChanged: (val) {
            // Update Program for CURRENT SLOT
            final updatedSlots = List<InstrumentSlot>.from(
              _musicConfig.instrumentSlots,
            );
            updatedSlots[_musicConfig.selectedInstrumentSlot] = _musicConfig
                .currentSlot
                .copyWith(program: val);

            final newConfig = _musicConfig.copyWith(
              instrumentSlots: updatedSlots,
            );
            _updateConfig(newConfig);

            // Send immediate MIDI change if active
            _midi.selectInstrument(sfId: _sfId, program: val);
          },
          lineVolume: _musicConfig.lineVolume,
          onLineVolumeChanged: (val) =>
              _updateConfig(_musicConfig.copyWith(lineVolume: val)),
        );
      case 3:
        return LibraryPane(
          instrumentPresets: _presets,
          onSaveInstrument: _savePreset,
          onLoadInstrument: _loadPreset,
          onDeleteInstrument: _deletePreset,
          canvasPresets: _savedCanvases,
          onSaveCanvas: _saveCanvas,
          onLoadCanvas: _loadCanvas,
          onDeleteCanvas: _deleteCanvas,
        );
      case 4:
        return SequencerSettingsPane(
          config: _musicConfig,
          onConfigChanged: _updateConfig,
        );
      case 5:
        return DroneSettingsPane(
          config: _musicConfig,
          onConfigChanged: _updateConfig,
          currentDetectedColor: _currentDroneColor,
          availableSoundFonts: _soundFonts,
        );
      case 6:
        return AppSettingsPane(
          showNoteLines: _showNoteLines,
          onShowNoteLinesChanged: (value) {
            setState(() {
              _showNoteLines = value;
            });
          },
        );
      default:
        return null;
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyL) {
        setState(() => _currentMode = DrawingMode.line);
      } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
        setState(
          () => _musicConfig = _musicConfig.copyWith(
            showPlayLine: !_musicConfig.showPlayLine,
          ),
        );
      } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
        setState(() => _currentMode = DrawingMode.gradient);
      } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
        _toggleDelay();
      } else if (event.logicalKey == LogicalKeyboardKey.keyE) {
        setState(() => _currentMode = DrawingMode.erase);
      } else if (event.logicalKey == LogicalKeyboardKey.keyG) {
        setState(() => _showNoteLines = !_showNoteLines);
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        _togglePlay();
      } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
        _toggleMetronome();
      } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
        setState(() => _isSustainOn = !_isSustainOn);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _cycleSoundFont(-1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _cycleSoundFont(1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _cycleInstrument(-1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _cycleInstrument(1);
      } else if (event.logicalKey == LogicalKeyboardKey.digit1) {
        _toggleScaleDegree(0);
      } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
        _toggleScaleDegree(1);
      } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
        _toggleScaleDegree(2);
      } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
        _toggleScaleDegree(3);
      } else if (event.logicalKey == LogicalKeyboardKey.digit5) {
        _toggleScaleDegree(4);
      } else if (event.logicalKey == LogicalKeyboardKey.digit6) {
        _toggleScaleDegree(5);
      } else if (event.logicalKey == LogicalKeyboardKey.digit7) {
        _toggleScaleDegree(6);
      }
    }
  }

  void _toggleScaleDegree(int index) {
    // Need meaningful degrees to toggle.
    // MusicConfiguration.getDegreesInScale returns the full list for the key/scale.
    // selectedDegrees contains the active ones.

    // Let's get the full list for current key/scale
    final allDegrees = MusicConfiguration.getDegreesInScale(
      _musicConfig.selectedKey,
      _musicConfig.selectedScale,
    );

    if (index >= allDegrees.length) return;

    final degree = allDegrees[index];
    final currentSelected = List<String>.from(_musicConfig.selectedDegrees);

    if (currentSelected.contains(degree)) {
      currentSelected.remove(degree);
    } else {
      currentSelected.add(degree);
    }

    setState(() {
      _musicConfig = _musicConfig.copyWith(selectedDegrees: currentSelected);
    });
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Scroll up (negative dy) -> Tempo Up
      // Scroll down (positive dy) -> Tempo Down
      double delta = event.scrollDelta.dy;
      double newTempo = _musicConfig.tempo;

      if (delta < 0) {
        newTempo += 1;
      } else {
        newTempo -= 1;
      }

      newTempo = newTempo.clamp(40.0, 240.0);

      // Use _updateConfig to handle tempo change and timer restart
      _updateConfig(_musicConfig.copyWith(tempo: newTempo));
    }
  }

  Future<void> _loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? presetsJson = prefs.getString('saved_presets');
    if (presetsJson != null) {
      final List<dynamic> decoded = jsonDecode(presetsJson);
      setState(() {
        _presets = decoded
            .map((json) => InstrumentPreset.fromJson(json))
            .toList();
      });
    }
  }

  Future<void> _loadCanvases() async {
    final canvases = await _canvasRepo.getAllCanvases();
    setState(() {
      _savedCanvases = canvases;
    });
  }

  Future<void> _saveCanvas(String name) async {
    final canvas = CanvasModel(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lines: _lines,
      gradientStrokes: _gradientStrokes,
      musicConfig: _musicConfig,
    );

    await _canvasRepo.saveCanvas(canvas);
    await _loadCanvases();
  }

  void _loadCanvas(CanvasModel canvas) {
    setState(() {
      _lines = canvas.lines; // These are distinct objects from JSON
      _gradientStrokes = canvas.gradientStrokes;
      _updateConfig(canvas.musicConfig);
      // Ensure we clear current line if any?
      _currentLine = null;
    });
  }

  Future<void> _deleteCanvas(CanvasModel canvas) async {
    await _canvasRepo.deleteCanvas(canvas.id);
    await _loadCanvases();
  }

  Future<void> _savePresetsToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_presets.map((e) => e.toJson()).toList());
    await prefs.setString('saved_presets', encoded);
  }

  void _savePreset(String name) {
    if (_presets.any((p) => p.name == name)) {
      // Logic to overwrite?
      _presets.removeWhere((p) => p.name == name);
    }

    final newPreset = InstrumentPreset(
      name: name,
      brushSpread: _brushSpread,
      brushOpacity: _brushOpacity,
      bristleCount: _bristleCount,
      useNeonGlow: _useNeonGlow,
      colorValue: _selectedLineColor.value,
      triggerOnBoundary: _triggerOnBoundary,
      minPixelsForTrigger: _minPixels,
      soundFont: _musicConfig.currentSlot.soundFont,
      programIndex: _musicConfig.currentSlot.program,
      isDelayOn: _isDelayOn,
      delayTime: _delayTime,
      delayFeedback: _delayFeedback,
      reverbLevel: _reverbLevel,
      isSustainOn: _isSustainOn,
      directionChangeThreshold: _musicConfig.directionChangeThreshold,
    );

    setState(() {
      _presets.add(newPreset);
    });
    _savePresetsToDisk();
  }

  void _loadPreset(InstrumentPreset preset) {
    setState(() {
      _brushSpread = preset.brushSpread;
      _brushOpacity = preset.brushOpacity;
      _bristleCount = preset.bristleCount;
      _useNeonGlow = preset.useNeonGlow;
      _selectedLineColor = Color(preset.colorValue);
      _triggerOnBoundary = preset.triggerOnBoundary;
      _minPixels = preset.minPixelsForTrigger;

      _isDelayOn = preset.isDelayOn;
      _delayTime = preset.delayTime;
      _delayFeedback = preset.delayFeedback;
      _reverbLevel = preset.reverbLevel;
      _isSustainOn = preset.isSustainOn;

      // Update Config Logic for Slot
      final updatedSlots = List<InstrumentSlot>.from(
        _musicConfig.instrumentSlots,
      );
      updatedSlots[_musicConfig.selectedInstrumentSlot] = _musicConfig
          .currentSlot
          .copyWith(soundFont: preset.soundFont, program: preset.programIndex);

      _updateConfig(
        _musicConfig.copyWith(
          instrumentSlots: updatedSlots,
          directionChangeThreshold: preset.directionChangeThreshold,
        ),
      );

      _loadSoundFont(preset.soundFont);
    });
  }

  void _deletePreset(InstrumentPreset preset) {
    setState(() {
      _presets.remove(preset);
    });
    _savePresetsToDisk();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: _handleKeyEvent,
        child: Listener(
          onPointerDown: (_) {
            if (!_focusNode.hasFocus) {
              FocusScope.of(context).requestFocus(_focusNode);
            }
          },
          onPointerSignal: _handleScroll,
          child: Column(
            children: [
              TransportBar(
                isPlaying: _isPlaying,
                isMetronomeOn: _isMetronomeOn,
                currentTick: _currentTick,
                onPlayPause: _togglePlay,
                onStop: _stop,
                onMetronomeToggle: _toggleMetronome,
                gridBeats: _musicConfig.totalBeats,
              ),
              Expanded(
                child: Row(
                  children: [
                    ToolbarWidget(
                      selectedPaneIndex: _selectedPaneIndex,
                      onPaneSelected: (index) {
                        setState(() {
                          _selectedPaneIndex = index;
                        });
                      },
                    ),
                    Expanded(
                      child: SplitLayout(
                        content: CanvasWidget(
                          musicConfig: _musicConfig,
                          showNoteLines: _showNoteLines,
                          segmentLength: _segmentLength,
                          minPixels: _minPixels,
                          lines: _lines,
                          currentLine: _currentLine,
                          drawingMode: _currentMode,
                          selectedColor: _selectedLineColor,
                          triggerOnBoundary: _triggerOnBoundary,

                          // Play Line Props
                          showPlayLine: _musicConfig.showPlayLine,
                          playLineAnimation: _playLineController,

                          // Brush Style Props
                          currentBrushSpread: _brushSpread,
                          currentBrushOpacity: _brushOpacity,
                          currentBristleCount: _bristleCount,

                          // Gradient Props
                          backgroundShader: _backgroundShader,
                          gradientStrokes: _gradientStrokes,
                          showGradientOverlays:
                              _currentMode ==
                              DrawingMode.gradient, // Visibility Logic
                          onGradientStrokeAdded: (stroke) => setState(() {
                            _gradientStrokes.add(stroke);
                            // Keep max 8
                            if (_gradientStrokes.length >
                                BackgroundGradientPainter.MAX_STROKES) {
                              _gradientStrokes.removeAt(0);
                            }
                          }),

                          onCurrentLineUpdated: (line) =>
                              setState(() => _currentLine = line),
                          onLineCompleted: (line) => setState(() {
                            // Update the completed line with CURRENT instrument settings
                            // This effectively "stamps" the line with the sound it was drawn with

                            // NEW: Stamp with Slot Index
                            final stampedLine = DrawnLine(
                              id: line.id,
                              path: line.path,
                              color: line.color,
                              width: line.width,

                              // Legacy/Fallback (optional, but good for robust standalone lines)
                              soundFont: _musicConfig.currentSlot.soundFont,
                              program: _musicConfig.currentSlot.program,
                              sfId:
                                  _loadedSoundFonts[_musicConfig
                                      .currentSlot
                                      .soundFont] ??
                                  _sfId,

                              // NEW PALETTE REFERENCE
                              instrumentSlotIndex:
                                  _musicConfig.selectedInstrumentSlot,

                              // Capture current brush style
                              spread: _brushSpread,
                              opacity: _brushOpacity,
                              bristleCount: _bristleCount,
                              useNeonGlow: _useNeonGlow,
                            );

                            // Create NEW list instance to trigger RepaintBoundary in CanvasWidget
                            _lines = List.from(_lines)..add(stampedLine);
                            _currentLine = null;
                            if (_isSustainOn && _currentMidiNote != -1) {
                              // Stop active note
                              int stopSfId = (_currentMidiNoteSfId != -1)
                                  ? _currentMidiNoteSfId
                                  : _sfId;
                              _midi.stopNote(
                                key: _currentMidiNote,
                                channel: 0,
                                sfId: stopSfId,
                              );
                              _currentMidiNote = -1;
                              _currentMidiNoteSfId = -1;
                            }
                          }),
                          onLineDeleted: (line) => setState(() {
                            // Create NEW list instance to trigger RepaintBoundary
                            _lines = List.from(_lines)..remove(line);
                            // Stop if it was the triggering note (logic assumption)
                            if (_isSustainOn && _currentMidiNote != -1) {
                              int stopSfId = (_currentMidiNoteSfId != -1)
                                  ? _currentMidiNoteSfId
                                  : _sfId;
                              _midi.stopNote(
                                key: _currentMidiNote,
                                channel: 0,
                                sfId: stopSfId,
                              );
                              _currentMidiNote = -1;
                              _currentMidiNoteSfId = -1;
                            }
                          }),
                          onNoteTriggered: (noteIndex, triggeredLine) {
                            if (!_isMidiInitialized) return;

                            final notes = _musicConfig.getAllMidiNotes();
                            if (noteIndex >= 0 && noteIndex < notes.length) {
                              final midiNote = notes[noteIndex];

                              // DETERMINE SOUND FOR THIS TRIGGER
                              int targetSfId = _sfId;
                              int targetProgram =
                                  _musicConfig.currentSlot.program;

                              // Check Instrument Slot
                              if (triggeredLine.instrumentSlotIndex != null) {
                                final slot =
                                    _musicConfig.instrumentSlots[triggeredLine
                                        .instrumentSlotIndex!];
                                targetProgram = slot.program;
                                if (_loadedSoundFonts.containsKey(
                                  slot.soundFont,
                                )) {
                                  targetSfId =
                                      _loadedSoundFonts[slot.soundFont]!;
                                }
                              } else {
                                // Fallback to Legacy Stored Data
                                if (triggeredLine.sfId != null) {
                                  targetSfId = triggeredLine.sfId!;
                                } else if (triggeredLine.soundFont != null &&
                                    _loadedSoundFonts.containsKey(
                                      triggeredLine.soundFont,
                                    )) {
                                  targetSfId =
                                      _loadedSoundFonts[triggeredLine
                                          .soundFont]!;
                                }
                                if (triggeredLine.program != null) {
                                  targetProgram = triggeredLine.program!;
                                }
                              }

                              // Optimization: Only switch instrument if needed
                              if (_lastChannel0SfId != targetSfId ||
                                  _lastChannel0Program != targetProgram) {
                                _midi.selectInstrument(
                                  sfId: targetSfId,
                                  program: targetProgram,
                                  channel: 0,
                                );
                                _lastChannel0SfId = targetSfId;
                                _lastChannel0Program = targetProgram;
                                // debugPrint("Switched Channel 0 to SF: $targetSfId, Prog: $targetProgram");
                              }

                              if (_isSustainOn) {
                                // Stop previous note if held
                                if (_currentMidiNote != -1) {
                                  // Use the SFID that started the note, or fallback to current target
                                  int stopSfId = (_currentMidiNoteSfId != -1)
                                      ? _currentMidiNoteSfId
                                      : targetSfId;
                                  _midi.stopNote(
                                    key: _currentMidiNote,
                                    channel: 0,
                                    sfId: stopSfId,
                                  );
                                }
                                // Play new note (indefinite)
                                _midi.playNote(
                                  key: midiNote,
                                  velocity: 127,
                                  channel: 0,
                                  sfId: targetSfId,
                                );
                                _currentMidiNote = midiNote;
                                _currentMidiNoteSfId = targetSfId;

                                if (_isDelayOn) {
                                  // For sustain mode, we just trigger the echoes as "one shots"
                                  // They will fade out naturally via envelope or we stop them?
                                  // Standard piano doesn't sustain infinite, but let's give echoes a duration.
                                  _triggerDelay(
                                    midiNote,
                                    127, // velocity
                                    400, // duration
                                    targetSfId,
                                  );
                                }
                              } else {
                                // Use helper for duration to prevent infinite sustain
                                _playNoteWithDuration(
                                  midiNote,
                                  127,
                                  300,
                                  sfId: targetSfId,
                                );
                              }
                            }
                          },
                        ),
                        pane: _getPane(_selectedPaneIndex),
                        paneAtStart: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Methods for MIDI Logic
  static int _noteNameToMidi(String noteName) {
    const notes = [
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
    final index = notes.indexOf(noteName);
    return index != -1 ? index : 0;
  }

  static List<int> _getScaleOffsets(String scaleName) {
    // Basic offsets for common scales
    switch (scaleName) {
      case 'Major':
        return [0, 2, 4, 5, 7, 9, 11, 12];
      case 'Minor':
        return [0, 2, 3, 5, 7, 8, 10, 12];
      case 'Pentatonic Major':
        return [0, 2, 4, 7, 9, 12];
      case 'Pentatonic Minor':
        return [0, 3, 5, 7, 10, 12];
      case 'Blues':
        return [0, 3, 5, 6, 7, 10, 12];
      case 'Chromatic':
        return [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
      default:
        return [0, 2, 4, 5, 7, 9, 11, 12]; // Default to Major
    }
  }
}
