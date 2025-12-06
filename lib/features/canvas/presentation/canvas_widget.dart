import 'package:flutter/material.dart';

class CanvasWidget extends StatelessWidget {
  const CanvasWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          'Canvas Area',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
