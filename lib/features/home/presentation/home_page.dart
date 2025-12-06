import 'package:flutter/material.dart';
import 'package:synesthesia_art_draw/core/presentation/layout/split_layout.dart';
import 'package:synesthesia_art_draw/features/canvas/presentation/canvas_widget.dart';
import 'package:synesthesia_art_draw/features/drawing/presentation/drawing_tools_pane.dart';
import 'package:synesthesia_art_draw/features/instrument/presentation/instrument_settings_pane.dart';
import 'package:synesthesia_art_draw/features/midi/presentation/midi_settings_pane.dart';
import 'package:synesthesia_art_draw/features/settings/presentation/app_settings_pane.dart';
import 'package:synesthesia_art_draw/features/toolbar/presentation/toolbar_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _selectedPaneIndex;

  Widget? _getPane(int? index) {
    switch (index) {
      case 0:
        return const DrawingToolsPane();
      case 1:
        return const MidiSettingsPane();
      case 2:
        return const InstrumentSettingsPane();
      case 3:
        return const AppSettingsPane();
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
              content: const CanvasWidget(),
              pane: _getPane(_selectedPaneIndex),
              paneAtStart: true,
            ),
          ),
        ],
      ),
    );
  }
}
