import 'package:flutter/material.dart';

class SplitLayout extends StatelessWidget {
  final Widget content;
  final Widget? pane;
  final double paneWidth;
  final bool paneAtStart;

  const SplitLayout({
    super.key,
    required this.content,
    this.pane,
    this.paneWidth = 300.0,
    this.paneAtStart = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: content),
        if (pane != null)
          Positioned(
            top: 0,
            bottom: 0,
            left: paneAtStart ? 0 : null,
            right: paneAtStart ? null : 0,
            width: paneWidth,
            child: Material(elevation: 4, child: pane!),
          ),
      ],
    );
  }
}
