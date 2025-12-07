import 'package:flutter/material.dart';
import '../../instrument/domain/instrument_preset.dart';
import '../../canvas/domain/canvas_model.dart';
import 'package:intl/intl.dart';

class LibraryPane extends StatefulWidget {
  // Instrument Callbacks
  final List<InstrumentPreset> instrumentPresets;
  final Function(String) onSaveInstrument;
  final Function(InstrumentPreset) onLoadInstrument;
  final Function(InstrumentPreset) onDeleteInstrument;

  // Canvas Callbacks
  final List<CanvasModel> canvasPresets;
  final Function(String) onSaveCanvas;
  final Function(CanvasModel) onLoadCanvas;
  final Function(CanvasModel) onDeleteCanvas;

  const LibraryPane({
    super.key,
    required this.instrumentPresets,
    required this.onSaveInstrument,
    required this.onLoadInstrument,
    required this.onDeleteInstrument,
    required this.canvasPresets,
    required this.onSaveCanvas,
    required this.onLoadCanvas,
    required this.onDeleteCanvas,
  });

  @override
  State<LibraryPane> createState() => _LibraryPaneState();
}

class _LibraryPaneState extends State<LibraryPane>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSaveDialog(bool isCanvas) {
    final TextEditingController _nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isCanvas ? 'Save Canvas' : 'Save Instrument Preset'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = _nameController.text.trim();
                if (name.isNotEmpty) {
                  if (isCanvas) {
                    widget.onSaveCanvas(name);
                  } else {
                    widget.onSaveInstrument(name);
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Instruments', icon: Icon(Icons.piano)),
              Tab(text: 'Canvases', icon: Icon(Icons.brush)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildInstrumentList(), _buildCanvasList()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstrumentList() {
    return _GeneralList<InstrumentPreset>(
      items: widget.instrumentPresets,
      emptyText: 'No saved instruments.',
      onSave: () => _showSaveDialog(false),
      itemBuilder: (context, preset) {
        return ListTile(
          title: Text(preset.name),
          subtitle: Text(
            '${preset.soundFont.split('.').first} - Color: ${preset.colorValue}',
          ),
          onTap: () => widget.onLoadInstrument(preset),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => widget.onDeleteInstrument(preset),
          ),
        );
      },
    );
  }

  Widget _buildCanvasList() {
    final dateFormat = DateFormat('MMM d, y H:m');
    return _GeneralList<CanvasModel>(
      items: widget.canvasPresets,
      emptyText: 'No saved canvases.',
      onSave: () => _showSaveDialog(true),
      itemBuilder: (context, canvas) {
        return ListTile(
          title: Text(canvas.name),
          subtitle: Text(
            'Created: ${dateFormat.format(canvas.createdAt)}\nLines: ${canvas.lines.length}',
          ),
          isThreeLine: true,
          onTap: () => widget.onLoadCanvas(canvas),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => widget.onDeleteCanvas(canvas),
          ),
        );
      },
    );
  }
}

class _GeneralList<T> extends StatelessWidget {
  final List<T> items;
  final String emptyText;
  final VoidCallback onSave;
  final Widget Function(BuildContext, T) itemBuilder;

  const _GeneralList({
    required this.items,
    required this.emptyText,
    required this.onSave,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save),
              label: const Text('Save Current'),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text(emptyText))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      Card(child: itemBuilder(context, items[index])),
                ),
        ),
      ],
    );
  }
}
