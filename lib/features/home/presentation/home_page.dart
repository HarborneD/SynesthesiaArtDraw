import 'dart:async';
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
import '../../midi/presentation/midi_settings_pane.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:synesthesia_art_draw/features/instrument/presentation/preset_library_pane.dart';
import 'package:synesthesia_art_draw/features/instrument/domain/instrument_preset.dart';
import '../../instrument/presentation/instrument_settings_pane.dart';
import '../../sequencer/presentation/sequencer_settings_pane.dart';
import '../../settings/presentation/app_settings_pane.dart';
import '../../toolbar/presentation/toolbar_widget.dart';
import '../../drawing/domain/drawing_mode.dart';
import '../../drawing/domain/drawn_line.dart';
import '../../drawing/domain/gradient_stroke.dart';
import '../../midi/domain/music_configuration.dart';

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
  double _brushSpread = 8.0;
  double _brushOpacity = 0.5;
  int _bristleCount = 20;
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
  bool _isReverbOn = true; // Default ON
  double _reverbDelay = 500.0; // Default 500ms
  double _reverbDecay = 0.6; // Default 60% decay
  String _selectedSoundFont = 'White Grand Piano II.sf2'; // Default
  int _selectedInstrumentIndex = 0;
  int _sfId = 0;
  List<InstrumentPreset> _presets = [];

  // Sustain State
  bool _isSustainOn = true;
  int _currentMidiNote = -1;
  int _currentMidiNoteSfId = -1; // Track which SF triggered the note

  // Optimization: Track last instrument set on Channel 0
  int? _lastChannel0SfId;
  int? _lastChannel0Program;

  final List<String> _soundFonts = [
    'Dystopian Terra.sf2',
    'VocalsPapel.sf2',
    'White Grand Piano I.sf2',
    'White Grand Piano II.sf2',
    'White Grand Piano III.sf2',
    'White Grand Piano V.sf2',
    'casio sk-200 gm sf2.sf2',
    'mick_gordon_string_efx.sf2',
  ];

  // Audio State
  final AudioPlayer _playerDown = AudioPlayer();
  final AudioPlayer _playerUp = AudioPlayer();

  // Track loaded SoundFonts to get their IDs
  // Filename -> ID
  final Map<String, int> _loadedSoundFonts = {};

  // ...

  @override
  void initState() {
    super.initState();
    _initMidi();
    _loadSoundFont(_selectedSoundFont);
    _loadShader();
    _loadPresets();
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

    await _loadSoundFont(_selectedSoundFont);
    setState(() {
      _isMidiInitialized = true;
    });
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
        program: _selectedInstrumentIndex,
        channel: 0,
      );
    } catch (e) {
      debugPrint("Error loading SoundFont: $e");
    }
  }

  void _cycleSoundFont(int direction) {
    int currentIndex = _soundFonts.indexOf(_selectedSoundFont);
    if (currentIndex == -1) currentIndex = 0;

    int newIndex = (currentIndex + direction) % _soundFonts.length;
    if (newIndex < 0) newIndex = _soundFonts.length - 1;

    final newFont = _soundFonts[newIndex];
    setState(() => _selectedSoundFont = newFont);
    _loadSoundFont(newFont);
  }

  void _cycleInstrument(int direction) {
    setState(() {
      int newProgram = (_selectedInstrumentIndex + direction) % 128;
      if (newProgram < 0) newProgram = 127;
      _selectedInstrumentIndex = newProgram;
      _midi.selectInstrument(
        sfId: _sfId,
        program: _selectedInstrumentIndex,
        channel: 0,
      );
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

  void _toggleReverb() {
    setState(() {
      _isReverbOn = !_isReverbOn;
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _playLineController.dispose();
    _playerDown.dispose();
    _playerUp.dispose();
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

    // Check for line triggers
    _checkLineTriggers();
  }

  void _checkLineTriggers() {
    // TODO: Implement Play Line collision logic here
    // For now, this is a placeholder to fix the build
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

    if (_isReverbOn) {
      _triggerReverb(note, velocity, durationMs, sfId);
    }
  }

  void _triggerReverb(int note, int velocity, int durationMs, int sfId) {
    // Dynamic Echo Logic
    int delayMs = _reverbDelay.toInt();

    // Echo 1
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      _midi.playNote(
        key: note,
        velocity: (velocity * _reverbDecay).toInt(),
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
        velocity: (velocity * _reverbDecay * _reverbDecay).toInt(),
        channel: 0,
        sfId: sfId,
      );
      Future.delayed(Duration(milliseconds: durationMs), () {
        _midi.stopNote(key: note, channel: 0, sfId: sfId);
      });
    });
  }

  // When Tempo changes, we need to restart timer if playing
  void _updateConfig(MusicConfiguration config) {
    final bool tempoChanged = config.tempo != _musicConfig.tempo;
    final bool barsChanged = config.gridBars != _musicConfig.gridBars;
    setState(() {
      _musicConfig = config;
    });
    if ((tempoChanged || barsChanged) && _isPlaying) {
      _startTimer();
    }
  }

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
      case 1:
        return MidiSettingsPane(
          config: _musicConfig,
          onConfigChanged: _updateConfig,
        );
      case 2:
        return InstrumentSettingsPane(
          availableSoundFonts: _soundFonts,
          isReverbOn: _isReverbOn,
          onReverbChanged: (val) => setState(() => _isReverbOn = val),
          reverbDelay: _reverbDelay,
          onReverbDelayChanged: (val) => setState(() => _reverbDelay = val),
          reverbDecay: _reverbDecay,
          onReverbDecayChanged: (val) => setState(() => _reverbDecay = val),
          isSustainOn: _isSustainOn,
          onSustainChanged: (val) => setState(() => _isSustainOn = val),
          directionChangeThreshold: _musicConfig.directionChangeThreshold,
          onDirectionChangeThresholdChanged: (val) => _updateConfig(
            _musicConfig.copyWith(directionChangeThreshold: val),
          ),
          selectedSoundFont: _selectedSoundFont,
          onSoundFontChanged: (val) async {
            if (val != _selectedSoundFont) {
              setState(() => _selectedSoundFont = val);
              await _loadSoundFont(val);
            }
          },
          selectedInstrumentIndex: _selectedInstrumentIndex,
          onInstrumentChanged: (val) {
            setState(() => _selectedInstrumentIndex = val);
            _midi.selectInstrument(sfId: _sfId, program: val);
          },
        );
      case 3:
        return PresetLibraryPane(
          presets: _presets,
          onSaveCurrent: _saveCurrentPreset,
          onLoad: _loadPreset,
          onDelete: _deletePreset,
        );
      case 4:
        return SequencerSettingsPane(
          config: _musicConfig,
          onConfigChanged: _updateConfig,
        );
      case 5:
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
        _toggleReverb();
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
    final String? presetsJson = prefs.getString('instrument_presets');
    if (presetsJson != null) {
      final List<dynamic> decoded = jsonDecode(presetsJson);
      setState(() {
        _presets = decoded.map((e) => InstrumentPreset.fromJson(e)).toList();
      });
    }
  }

  Future<void> _savePresets() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_presets.map((e) => e.toJson()).toList());
    await prefs.setString('instrument_presets', encoded);
  }

  void _saveCurrentPreset(String name) {
    final newPreset = InstrumentPreset(
      name: name,
      brushSpread: _brushSpread,
      brushOpacity: _brushOpacity,
      bristleCount: _bristleCount,
      useNeonGlow: _useNeonGlow,
      colorValue: _selectedLineColor.value,
      triggerOnBoundary: _triggerOnBoundary,
      minPixelsForTrigger: _minPixels,
      soundFont: _selectedSoundFont,
      programIndex: _selectedInstrumentIndex,
      isReverbOn: _isReverbOn,
      reverbDelay: _reverbDelay,
      reverbDecay: _reverbDecay,
      isSustainOn: _isSustainOn,
      directionChangeThreshold: _musicConfig.directionChangeThreshold,
    );

    setState(() {
      _presets.add(newPreset);
    });
    _savePresets();
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

      // Instrument
      if (_soundFonts.contains(preset.soundFont)) {
        // Check if the soundfont is in our available list
        if (_selectedSoundFont != preset.soundFont) {
          _selectedSoundFont = preset.soundFont;
          // Trigger load soundfont if needed, but for now just setting state
          _loadSoundFont(preset.soundFont);
        }
      }
      _selectedInstrumentIndex = preset.programIndex;
      _midi.selectInstrument(sfId: _sfId, program: _selectedInstrumentIndex);

      _isReverbOn = preset.isReverbOn;
      _reverbDelay = preset.reverbDelay;
      _reverbDecay = preset.reverbDecay;
      _isSustainOn = preset.isSustainOn;

      _updateConfig(
        _musicConfig.copyWith(
          directionChangeThreshold: preset.directionChangeThreshold,
        ),
      );
    });
  }

  void _deletePreset(InstrumentPreset preset) {
    setState(() {
      _presets.remove(preset);
    });
    _savePresets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: _handleKeyEvent,
        child: Listener(
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

                            final stampedLine = DrawnLine(
                              id: line.id,
                              path: line.path,
                              color: line.color,
                              width: line.width,
                              soundFont: _selectedSoundFont,
                              program: _selectedInstrumentIndex,
                              sfId: _sfId,

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
                              // If triggeredLine has stored sound data, use it.
                              // If it's the 'currentLine' (being drawn), it might be null if not yet stamped.
                              // If null, use global state.

                              int targetSfId = triggeredLine.sfId ?? _sfId;
                              // If stored sfId is not valid/loaded (e.g. restart), fallback to lookup
                              if (triggeredLine.soundFont != null &&
                                  _loadedSoundFonts.containsKey(
                                    triggeredLine.soundFont,
                                  )) {
                                targetSfId =
                                    _loadedSoundFonts[triggeredLine.soundFont]!;
                              }

                              // We might need to ensure the program is set for this playback event.
                              // Since we might be sharing Channel 0, this is tricky.
                              // WE WILL SET IT JUST IN CASE.
                              // NOTE: This might glitch current playback if polyphony is high.
                              int targetProgram =
                                  triggeredLine.program ??
                                  _selectedInstrumentIndex;

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

                                if (_isReverbOn) {
                                  // For sustain mode, we just trigger the echoes as "one shots"
                                  // They will fade out naturally via envelope or we stop them?
                                  // Standard piano doesn't sustain infinite, but let's give echoes a duration.
                                  _triggerReverb(
                                    midiNote,
                                    127,
                                    400,
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
}
