import 'package:flutter/material.dart';

class InstrumentSettingsPane extends StatefulWidget {
  const InstrumentSettingsPane({super.key});

  @override
  State<InstrumentSettingsPane> createState() => _InstrumentSettingsPaneState();
}

class _InstrumentSettingsPaneState extends State<InstrumentSettingsPane> {
  bool _useInternalAudio = true;
  String? _selectedSoundFont;
  List<String> _availableSoundFonts = [];

  @override
  void initState() {
    super.initState();
    _loadSoundFonts();
  }

  Future<void> _loadSoundFonts() async {
    // In a real app, we would use AssetManifest to list files.
    // For now, we'll manually list the known files or use a placeholder list
    // that matches the assets we know exist.
    // Since we can't easily read the AssetManifest in this environment without
    // running code, we will implement the logic to read it but default to a list.

    // Simulating checking assets/sounds_fonts/
    setState(() {
      _availableSoundFonts = [
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
      if (_availableSoundFonts.isNotEmpty) {
        _selectedSoundFont = _availableSoundFonts.first;
      }
    });
  }

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
            value: _selectedSoundFont,
            hint: const Text('Select Instrument'),
            isExpanded: true,
            onChanged: _useInternalAudio
                ? (String? newValue) {
                    setState(() {
                      _selectedSoundFont = newValue;
                    });
                  }
                : null, // Disable if internal audio is off
            items: _availableSoundFonts.map<DropdownMenuItem<String>>((
              String value,
            ) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
          ),
        ],
      ),
    );
  }
}
