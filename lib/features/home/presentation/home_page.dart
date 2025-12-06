import 'package:flutter/material.dart';
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
        );
      case 1:
        return MidiSettingsPane(
          config: _musicConfig,
          onConfigChanged: (config) {
            setState(() {
              _musicConfig = config;
            });
          },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
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
              ),
              pane: _getPane(_selectedPaneIndex),
              paneAtStart: true,
            ),
          ),
        ],
      ),
    );
  }
}
