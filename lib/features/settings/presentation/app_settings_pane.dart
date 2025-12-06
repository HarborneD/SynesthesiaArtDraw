import 'package:flutter/material.dart';

class AppSettingsPane extends StatefulWidget {
  const AppSettingsPane({super.key});

  @override
  State<AppSettingsPane> createState() => _AppSettingsPaneState();
}

class _AppSettingsPaneState extends State<AppSettingsPane> {
  // Octaves and Scale moved to MidiSettingsPane

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
          const Text('Global application settings.'),
          // Add other global settings here as needed
        ],
      ),
    );
  }
}
