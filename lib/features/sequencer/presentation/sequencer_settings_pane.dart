import 'package:flutter/material.dart';
import '../../midi/domain/music_configuration.dart';

class SequencerSettingsPane extends StatelessWidget {
  final MusicConfiguration config;
  final ValueChanged<MusicConfiguration> onConfigChanged;

  const SequencerSettingsPane({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sequencer Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Show Play Line'),
            subtitle: const Text('Show visual scan line'),
            value: config.showPlayLine,
            onChanged: (val) {
              onConfigChanged(config.copyWith(showPlayLine: val));
            },
          ),
          const Divider(),
          const SizedBox(height: 10),
          Text('Grid Bars: ${config.gridBars} (${config.gridBars * 4} beats)'),
          Slider(
            value: config.gridBars.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            label: config.gridBars.toString(),
            onChanged: (val) {
              onConfigChanged(config.copyWith(gridBars: val.round()));
            },
          ),
          const Text(
            'Controls the loop length (1-8 bars of 4/4).',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
