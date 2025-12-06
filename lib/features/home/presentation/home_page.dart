import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:soundpool/soundpool.dart';
import '../../../core/presentation/layout/split_layout.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import '../../transport/presentation/transport_bar.dart';
import '../../canvas/presentation/canvas_widget.dart';
import '../../drawing/presentation/drawing_tools_pane.dart';
import '../../midi/presentation/midi_settings_pane.dart';
import '../../instrument/presentation/instrument_settings_pane.dart';
import '../../settings/presentation/app_settings_pane.dart';
import '../../toolbar/presentation/toolbar_widget.dart';
import '../../drawing/domain/drawing_mode.dart';
import '../../drawing/domain/drawn_line.dart';
import '../../midi/domain/music_configuration.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _selectedPaneIndex;
  DrawingMode _currentMode = DrawingMode.line;
  MusicConfiguration _musicConfig = MusicConfiguration();
  bool _showNoteLines = true;

  // Drawing State
  double _segmentLength = 100.0;
  double _minPixels = 1.0;
  List<DrawnLine> _lines = [];
  DrawnLine? _currentLine;

  // Clock State
  bool _isPlaying = false;
  bool _isMetronomeOn = false;
  int _currentTick = 0; // 0-15
  Timer? _clockTimer;

  // Audio State
  Soundpool? _pool;
  int? _soundIdDown;
  int? _soundIdUp;

  // MIDI State
  final _midi = MidiPro();
  bool _isMidiInitialized = false;
  String _selectedSoundFont = 'Dystopian Terra.sf2'; // Default
  int _selectedInstrumentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _initMidi();
  }

  Future<void> _initAudio() async {
    try {
      _pool = Soundpool.fromOptions(
        options: const SoundpoolOptions(streamType: StreamType.music),
      );
      _soundIdDown = await rootBundle
          .load("assets/metronome/Zoom ST Down .wav")
          .then((ByteData soundData) {
            return _pool!.load(soundData);
          });
      _soundIdUp = await rootBundle
          .load("assets/metronome/Zoom ST UP.wav")
          .then((ByteData soundData) {
            return _pool!.load(soundData);
          });
    } catch (e) {
      debugPrint("Error loading metronome sounds: $e");
    }
  }

  Future<void> _initMidi() async {
    await _loadSoundFont(_selectedSoundFont);
    setState(() {
      _isMidiInitialized = true;
    });
  }

  int _sfId = 0;

  Future<void> _loadSoundFont(String fileName) async {
    try {
      final path = 'assets/sounds_fonts/$fileName';
      _sfId = await _midi.loadSoundfontAsset(assetPath: path);
      debugPrint("Loaded SoundFont: $path (ID: $_sfId)");
    } catch (e) {
      debugPrint("Error loading SoundFont: $e");
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pool?.dispose();
    super.dispose();
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
    });
  }

  void _toggleMetronome() {
    setState(() {
      _isMetronomeOn = !_isMetronomeOn;
    });
  }

  void _startTimer() {
    _clockTimer?.cancel();
    if (!_isPlaying) return;

    // Tempo = Beats Per Minute (Quarter notes)
    // We want 1 Dot = 1 Beat (Quarter Note)
    // Ticks per minute = Tempo.
    // Interval (ms) = 60000 / Tempo
    final double msPerTick = 60000 / _musicConfig.tempo;

    _clockTimer = Timer.periodic(Duration(milliseconds: msPerTick.round()), (
      timer,
    ) {
      setState(() {
        _currentTick = (_currentTick + 1) % 16;

        // Metronome logic: Tick every beat (quarter note)
        if (_isMetronomeOn && _pool != null) {
          if (_currentTick % 4 == 0) {
            if (_soundIdDown != null) _pool!.play(_soundIdDown!);
          } else {
            if (_soundIdUp != null) _pool!.play(_soundIdUp!);
          }
        }
      });
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
    switch (index) {
      case 0:
        return DrawingToolsPane(
          currentMode: _currentMode,
          onModeChanged: (mode) => setState(() => _currentMode = mode),
          segmentLength: _segmentLength,
          onSegmentLengthChanged: (val) => setState(() => _segmentLength = val),
          minPixels: _minPixels,
          onMinPixelsChanged: (val) => setState(() => _minPixels = val),
          onClearAll: () => setState(() {
            _lines.clear();
            _currentLine = null;
          }),
        );
      case 1:
        return MidiSettingsPane(
          config: _musicConfig,
          onConfigChanged: _updateConfig, // Use encapsulated updater
        );
      case 2:
        return InstrumentSettingsPane(
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
                          onCurrentLineUpdated: (line) =>
                              setState(() => _currentLine = line),
                          onLineCompleted: (line) => setState(() {
                            _lines.add(line);
                            _currentLine = null;
                          }),
                          onLineDeleted: (line) => setState(() {
                            _lines.remove(line);
                          }),
                          onNoteTriggered: (noteIndex) {
                            if (!_isMidiInitialized) return;

                            final notes = _musicConfig.getAllMidiNotes();
                            if (noteIndex >= 0 && noteIndex < notes.length) {
                              final midiNote = notes[noteIndex];
                              // Trying named arguments based on others being named
                              _midi.playNote(note: midiNote, velocity: 127, channel: 0);
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
