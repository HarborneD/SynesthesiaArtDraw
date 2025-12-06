import 'package:flutter/material.dart';

class TransportBar extends StatelessWidget {
  final bool isPlaying;
  final bool isMetronomeOn;
  final int currentTick;
  final int gridBeats;
  // Requirement: "dots representing 4 bars of 4 with the 1st being bigger."
  // Usually this means 4 bars * 4 beats/bar = 16 beats total.

  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onMetronomeToggle;

  const TransportBar({
    super.key,
    required this.isPlaying,
    required this.isMetronomeOn,
    required this.currentTick,
    required this.onPlayPause,
    required this.onStop,
    required this.onMetronomeToggle,
    required this.gridBeats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: onPlayPause,
            tooltip: isPlaying ? 'Pause' : 'Play',
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: onStop,
            tooltip: 'Stop',
          ),
          const SizedBox(width: 16),

          // Eraser/etc are in toolbar, this is transport.
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(gridBeats, (index) {
                final isCurrent = index == currentTick;
                final isBarStart = index % 4 == 0;

                return Container(
                  width: isBarStart ? 12 : 8,
                  height: isBarStart ? 12 : 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? Colors.blue
                        : (isBarStart ? Colors.grey[800] : Colors.grey[400]),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(width: 16),
          IconButton(
            icon: Icon(
              isMetronomeOn ? Icons.alarm_on : Icons.alarm_off,
            ), // Using alarm icon for metronome for now
            onPressed: onMetronomeToggle,
            color: isMetronomeOn ? Colors.blue : null,
            tooltip: 'Metronome',
          ),
        ],
      ),
    );
  }
}
