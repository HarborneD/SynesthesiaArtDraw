import 'package:flutter/material.dart';

class InstrumentSettingsPane extends StatelessWidget {
  const InstrumentSettingsPane({super.key});

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
          const Text('Instrument selection and parameters will go here.'),
        ],
      ),
    );
  }
}
