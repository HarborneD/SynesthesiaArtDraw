import 'package:flutter/material.dart';
import '../domain/instrument_preset.dart';

class PresetLibraryPane extends StatefulWidget {
  final List<InstrumentPreset> presets;
  final Function(String) onSaveCurrent;
  final Function(InstrumentPreset) onLoad;
  final Function(InstrumentPreset) onDelete;

  const PresetLibraryPane({
    super.key,
    required this.presets,
    required this.onSaveCurrent,
    required this.onLoad,
    required this.onDelete,
  });

  @override
  State<PresetLibraryPane> createState() => _PresetLibraryPaneState();
}

class _PresetLibraryPaneState extends State<PresetLibraryPane> {
  void _showSaveDialog() {
    final TextEditingController _nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Instrument Preset'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Preset Name'),
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
                  widget.onSaveCurrent(name);
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Instruments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: _showSaveDialog,
                icon: const Icon(Icons.save),
                tooltip: 'Save Current',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: widget.presets.isEmpty
                ? Center(
                    child: Text(
                      'No saved presets. Save one to get started!',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.presets.length,
                    itemBuilder: (context, index) {
                      final preset = widget.presets[index];
                      return Card(
                        child: ListTile(
                          title: Text(preset.name),
                          subtitle: Text(
                            '${preset.soundFont.split('.').first} - ${preset.colorValue}',
                          ),
                          onTap: () => widget.onLoad(preset),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => widget.onDelete(preset),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
