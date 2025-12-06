import 'package:flutter/material.dart';

class InstrumentSettingsPane extends StatefulWidget {
  final String selectedSoundFont;
  final ValueChanged<String> onSoundFontChanged;
  final int selectedInstrumentIndex;
  final ValueChanged<int> onInstrumentChanged;

  const InstrumentSettingsPane({
    super.key,
    required this.selectedSoundFont,
    required this.onSoundFontChanged,
    required this.selectedInstrumentIndex,
    required this.onInstrumentChanged,
  });

  @override
  State<InstrumentSettingsPane> createState() => _InstrumentSettingsPaneState();
}

class _InstrumentSettingsPaneState extends State<InstrumentSettingsPane> {
  bool _useInternalAudio = true;

  // Hardcoded list for now, as we can't easily read assets folder at runtime without manifest
  final List<String> _availableSoundFonts = [
    'Dystopian Terra.sf2',
    'VocalsPapel.sf2',
    'White Grand Piano I.sf2',
    'White Grand Piano II.sf2',
    'White Grand Piano III.sf2',
    'White Grand Piano IV.sf2',
    'White Grand Piano V.sf2',
    'casio sk-200 gm sf2.sf2',
    'mick_gordon_string_efx.sf2',
  ];

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
            items: _availableSoundFonts.map<DropdownMenuItem<String>>((
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
        ],
      ),
    );
  }
}
