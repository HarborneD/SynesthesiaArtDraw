import 'package:flutter/material.dart';

class DrawingToolsPane extends StatelessWidget {
  const DrawingToolsPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Drawing Tools', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          const Text('Tool selection will go here.'),
        ],
      ),
    );
  }
}
