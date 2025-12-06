import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../../../core/presentation/layout/split_layout.dart';
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
          onConfigChanged: (config) => setState(() => _musicConfig = config),
        );
      case 2:
        return const InstrumentSettingsPane();
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

      setState(() {
        _musicConfig = _musicConfig.copyWith(tempo: newTempo);
      });
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
                      debugPrint('MIDI TRIGGER: Note Index $noteIndex');
                      // TODO: Hook up actual MIDI playing here
                    },
                  ),
                  pane: _getPane(_selectedPaneIndex),
                  paneAtStart: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
