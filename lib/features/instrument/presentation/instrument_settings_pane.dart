import 'package:flutter/material.dart';

class InstrumentSettingsPane extends StatefulWidget {
  final String selectedSoundFont;
  final ValueChanged<String> onSoundFontChanged;
  final int selectedInstrumentIndex;
  final ValueChanged<int> onInstrumentChanged;
  final List<String> availableSoundFonts;
  final bool isDelayOn;
  final ValueChanged<bool> onDelayChanged;
  final double delayTime;
  final ValueChanged<double> onDelayTimeChanged;
  final double delayFeedback;
  final ValueChanged<double> onDelayFeedbackChanged;

  final double reverbLevel;
  final ValueChanged<double> onReverbLevelChanged;

  final bool isSustainOn;
  final ValueChanged<bool> onSustainChanged;
  final double directionChangeThreshold;
  final ValueChanged<double> onDirectionChangeThresholdChanged;

  const InstrumentSettingsPane({
    super.key,
    required this.selectedSoundFont,
    required this.onSoundFontChanged,
    required this.selectedInstrumentIndex,
    required this.onInstrumentChanged,
    required this.availableSoundFonts,
    required this.isDelayOn,
    required this.onDelayChanged,
    required this.delayTime,
    required this.onDelayTimeChanged,
    required this.delayFeedback,
    required this.onDelayFeedbackChanged,
    required this.reverbLevel,
    required this.onReverbLevelChanged,
    required this.isSustainOn,
    required this.onSustainChanged,
    required this.directionChangeThreshold,
    required this.onDirectionChangeThresholdChanged,
  });

  @override
  State<InstrumentSettingsPane> createState() => _InstrumentSettingsPaneState();
}

class _InstrumentSettingsPaneState extends State<InstrumentSettingsPane> {
  bool _useInternalAudio = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instrument Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Internal Audio'),
            subtitle: const Text('Use built-in synthesizer'),
            value: _useInternalAudio,
            onChanged: (bool value) {
              setState(() {
                _useInternalAudio = value;
              });
            },
          ),
          const SizedBox(height: 20),
          const Text('Sound Font'),
          DropdownButton<String>(
            value: widget.selectedSoundFont,
            hint: const Text('Select Sound Font'),
            isExpanded: true,
            onChanged: _useInternalAudio
                ? (String? newValue) {
                    if (newValue != null) {
                      widget.onSoundFontChanged(newValue);
                    }
                  }
                : null,
            items: widget.availableSoundFonts.map<DropdownMenuItem<String>>((
              String value,
            ) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Instrument (Program)'),
          // Dropdown 0-127
          DropdownButton<int>(
            value: widget.selectedInstrumentIndex,
            hint: const Text('Select Instrument'),
            isExpanded: true,
            onChanged: _useInternalAudio
                ? (int? newValue) {
                    if (newValue != null) {
                      widget.onInstrumentChanged(newValue);
                    }
                  }
                : null,
            items: List.generate(128, (index) {
              return DropdownMenuItem<int>(
                value: index,
                child: Text('Instrument $index'),
              );
            }),
          ),
          const SizedBox(height: 20),
          const Divider(),
          // Delay Section
          SwitchListTile(
            title: const Text('Tape Delay'),
            subtitle: const Text('Echo effect'),
            value: widget.isDelayOn,
            onChanged: widget.onDelayChanged,
          ),
          if (widget.isDelayOn) ...[
            const SizedBox(height: 10),
            Text('Time: ${widget.delayTime.toInt()} ms'),
            Slider(
              value: widget.delayTime,
              min: 50,
              max: 2000,
              divisions: 40,
              label: '${widget.delayTime.toInt()} ms',
              onChanged: widget.onDelayTimeChanged,
            ),
            const SizedBox(height: 10),
            Text('Feedback: ${(widget.delayFeedback * 100).toInt()}%'),
            Slider(
              value: widget.delayFeedback,
              min: 0.1,
              max: 0.9,
              divisions: 8,
              label: '${(widget.delayFeedback * 100).toInt()}%',
              onChanged: widget.onDelayFeedbackChanged,
            ),
          ],

          const Divider(),
          // Reverb Section
          const Text('Room Reverb'),
          Slider(
            value: widget.reverbLevel,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: '${(widget.reverbLevel * 100).toInt()}%',
            onChanged: widget.onReverbLevelChanged,
          ),
          const SizedBox(height: 20),
          const Divider(),
          SwitchListTile(
            title: const Text('Sustain Notes'),
            subtitle: const Text('Hold notes until next trigger or line end'),
            value: widget.isSustainOn,
            onChanged: widget.onSustainChanged,
          ),
          const SizedBox(height: 10),
          Text(
            'Direction Trigger Threshold: ${widget.directionChangeThreshold.toInt()}°',
          ),
          Slider(
            value: widget.directionChangeThreshold,
            min: 10,
            max: 180,
            divisions: 170,
            label: widget.directionChangeThreshold.round().toString(),
            onChanged: widget.onDirectionChangeThresholdChanged,
          ),
        ],
      ),
    );
  }
}
