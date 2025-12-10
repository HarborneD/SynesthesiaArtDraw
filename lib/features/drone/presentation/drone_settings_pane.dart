import 'package:flutter/material.dart';
import '../../midi/domain/music_configuration.dart';

class DroneSettingsPane extends StatelessWidget {
  final MusicConfiguration config;
  final ValueChanged<MusicConfiguration> onConfigChanged;
  final Color currentDetectedColor;
  final List<String> availableSoundFonts;

  const DroneSettingsPane({
    super.key,
    required this.config,
    required this.onConfigChanged,
    required this.currentDetectedColor,
    required this.availableSoundFonts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            children: [
              Text(
                'Drone Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              // Toggle removed as per request (it did nothing visible or was confusing)
            ],
          ),
          const SizedBox(height: 20),

          Text('Update Interval: ${config.droneUpdateIntervalBars} Bars'),
          Slider(
            value: config.droneUpdateIntervalBars.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            label: '${config.droneUpdateIntervalBars} Bars',
            onChanged: (val) {
              // Snap to 1, 2, 4, 8? user asked for specific intervals but slider is easiest.
              // Let's stick to linear 1-8 for now as per plan.
              onConfigChanged(
                config.copyWith(droneUpdateIntervalBars: val.round()),
              );
            },
          ),

          const SizedBox(height: 10),
          Text('Chord Density: ${config.droneDensity} Notes'),
          Slider(
            value: config.droneDensity.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '${config.droneDensity}',
            onChanged: (val) {
              onConfigChanged(config.copyWith(droneDensity: val.round()));
            },
          ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mapping Strategy:'),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<DroneMapping>(
                  value: config.droneMapping,
                  isExpanded: true,
                  items: DroneMapping.values.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(m.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      onConfigChanged(config.copyWith(droneMapping: val));
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(),
          const Text('Drone Volume:'),
          Slider(
            value: config.droneVolume,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(config.droneVolume * 100).toInt()}%',
            onChanged: (val) {
              onConfigChanged(config.copyWith(droneVolume: val));
            },
          ),

          const SizedBox(height: 10),
          const Text('Drone Sound Font:'),
          DropdownButton<String>(
            value: config.droneSoundFont,
            isExpanded: true,
            hint: const Text('Select Sound Font'),
            items: availableSoundFonts.map((sf) {
              return DropdownMenuItem(value: sf, child: Text(sf));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                onConfigChanged(config.copyWith(droneSoundFont: val));
              }
            },
          ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Instrument (Program):'),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<int>(
                  value: config.droneInstrument,
                  isExpanded: true,
                  items: List.generate(128, (index) {
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(
                        'Instrument $index',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      onConfigChanged(config.copyWith(droneInstrument: val));
                    }
                  },
                ),
              ),
            ],
          ),
          Divider(),

          const Divider(),
          const SizedBox(height: 10),
          const Text('Scan Line Color Detection:'),
          const SizedBox(height: 10),
          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: currentDetectedColor,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              _getColorDescription(currentDetectedColor),
              style: TextStyle(
                color: currentDetectedColor.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getColorDescription(Color color) {
    final hsl = HSLColor.fromColor(color);
    final hue = hsl.hue;

    // Red/Orange (330-30) -> Tonic
    if (hue >= 330 || hue <= 30) return 'Tonic (I)';
    // Green/Yellow (60-180) -> Subdominant
    if (hue >= 60 && hue <= 180) return 'Subdominant (IV)';
    // Blue/Violet (180-300) -> Dominant
    if (hue > 180 && hue < 300) return 'Dominant (V)';

    return 'Transition';
  }
}
