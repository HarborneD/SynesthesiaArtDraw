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
import '../../drawing/presentation/gradient_tools_pane.dart';
import '../../midi/presentation/midi_settings_pane.dart';
import '../../instrument/presentation/instrument_settings_pane.dart';
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

class _HomePageState extends State<HomePage> {
  int? _selectedPaneIndex;
  MusicConfiguration _musicConfig = MusicConfiguration();
  bool _showNoteLines = true;

  // Drawing State
  double _segmentLength = 100.0;
  double _minPixels = 1.0;
  List<DrawnLine> _lines = [];
  DrawnLine? _currentLine;
  Color _selectedLineColor = Colors.black; // Default line color
  bool _triggerOnBoundary = false; // Default off

  // Gradient State
  List<GradientStroke> _gradientStrokes = [];
  ui.FragmentShader? _backgroundShader;

  DrawingMode _currentMode = DrawingMode.line;

  // Clock State
  bool _isPlaying = false;
  bool _isMetronomeOn = false;
  int _currentTick = 0; // 0-15
  Timer? _clockTimer;

  // MIDI State
  final _midi = MidiPro();
  bool _isMidiInitialized = false;
  String _selectedSoundFont = 'White Grand Piano II.sf2'; // Default
  int _selectedInstrumentIndex = 0;
  int _sfId = 0;

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
    'White Grand Piano IV.sf2',
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
    try {
      await _playerDown.setSource(AssetSource('metronome/Zoom ST Down .wav'));
      await _playerDown.setPlayerMode(PlayerMode.lowLatency);

      await _playerUp.setSource(AssetSource('metronome/Zoom ST UP.wav'));
      await _playerUp.setPlayerMode(PlayerMode.lowLatency);
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }

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
      }
    });
  }

  void _stop() {
    setState(() {
      _isPlaying = false;
      _currentTick = 0;
      _clockTimer?.cancel();

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

  @override
  void dispose() {
    _clockTimer?.cancel();
    _playerDown.dispose();
    _playerUp.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _lines.clear();
      _currentLine = null;
      _gradientStrokes.clear();
    });
  }

  void _startTimer() {
    _clockTimer?.cancel();
    if (!_isPlaying) return;

    final double msPerTick = 60000 / _musicConfig.tempo;

    _clockTimer = Timer.periodic(Duration(milliseconds: msPerTick.round()), (
      timer,
    ) {
      setState(() {
        _currentTick = (_currentTick + 1) % 16;

        if (_isMetronomeOn) {
          // Fix: Re-trigger play from source every time to ensure consistent firing
          // "Fire and Forget" strategy
          final player = (_currentTick % 4 == 0) ? _playerDown : _playerUp;
          final source = (_currentTick % 4 == 0)
              ? AssetSource('metronome/Zoom ST Down .wav')
              : AssetSource('metronome/Zoom ST UP.wav');

          player.stop().then((_) {
            player.play(source, mode: PlayerMode.lowLatency);
          });
        }
      });
    });
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
  }

  // When Tempo changes, we need to restart timer if playing
  void _updateConfig(MusicConfiguration config) {
    final bool tempoChanged = config.tempo != _musicConfig.tempo;
    setState(() {
      _musicConfig = config;
    });
    if (tempoChanged && _isPlaying) {
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
        );
      case 1:
        return MidiSettingsPane(
          config: _musicConfig,
          onConfigChanged: _updateConfig,
          isSustainOn: _isSustainOn,
          onSustainChanged: (val) => setState(() => _isSustainOn = val),
        );
      case 2:
        return InstrumentSettingsPane(
          availableSoundFonts: _soundFonts,
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
      } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
        setState(() => _currentMode = DrawingMode.gradient);
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
                              path: line.path,
                              color: line.color,
                              width: line.width,
                              soundFont: _selectedSoundFont,
                              program: _selectedInstrumentIndex,
                              sfId: _sfId,
                            );

                            _lines.add(stampedLine);
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
                            _lines.remove(line);
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
