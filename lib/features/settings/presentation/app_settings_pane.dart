import 'package:flutter/material.dart';

class AppSettingsPane extends StatelessWidget {
  final bool showNoteLines;
  final ValueChanged<bool> onShowNoteLinesChanged;

  const AppSettingsPane({
    super.key,
    required this.showNoteLines,
    required this.onShowNoteLinesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('App Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Show Note Lines'),
            subtitle: const Text('Display horizontal lines for notes'),
            value: showNoteLines,
            onChanged: onShowNoteLinesChanged,
          ),
        ],
      ),
    );
  }
}
