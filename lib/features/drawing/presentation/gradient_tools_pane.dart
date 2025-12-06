import 'package:flutter/material.dart';
import '../../drawing/domain/gradient_stroke.dart';

class GradientToolsPane extends StatelessWidget {
  final List<GradientStroke> strokes;
  final Function(int index, GradientStroke newStroke) onStrokeUpdated;
  final Function(int index) onStrokeDeleted;

  const GradientToolsPane({
    super.key,
    required this.strokes,
    required this.onStrokeUpdated,
    required this.onStrokeDeleted,
  });

  @override
  Widget build(BuildContext context) {
    if (strokes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Draw a line on the canvas in 'Gradient Mode' (B) to create a field.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: strokes.length,
      itemBuilder: (context, index) {
        final stroke = strokes[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            title: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: stroke.colors,
                      stops: stroke.stops,
                    ),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                Text("Field #${index + 1}"),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onStrokeDeleted(index),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intensity Slider
                    const Text("Intensity (Radius)"),
                    Slider(
                      value: stroke.intensity.clamp(10.0, 1600.0),
                      min: 10.0,
                      max: 1600.0,
                      label: stroke.intensity.toStringAsFixed(0),
                      onChanged: (val) {
                        onStrokeUpdated(index, stroke.copyWith(intensity: val));
                      },
                    ),

                    const SizedBox(height: 16),
                    const Text("Colors"),
                    // Simple Color Chips Row
                    Wrap(
                      spacing: 8,
                      children: List.generate(stroke.colors.length, (
                        colorIndex,
                      ) {
                        Color c = stroke.colors[colorIndex];
                        return InkWell(
                          onTap: () {
                            // Cycle primitive colors for MVP or open a dialog
                            // Let's implement a simple cycle: R -> G -> B -> C -> M -> Y -> K -> W
                            final palette = [
                              Colors.red,
                              Colors.green,
                              Colors.blue,
                              Colors.cyan,
                              Colors.purpleAccent,
                              Colors.yellow,
                              Colors.black,
                              Colors.white,
                              Colors.purple,
                              Colors.orange,
                            ];
                            int currentIdx = palette.indexWhere(
                              (pc) => pc.value == c.value,
                            );
                            int nextIdx = (currentIdx + 1) % palette.length;

                            List<Color> newColors = List.from(stroke.colors);
                            newColors[colorIndex] = palette[nextIdx];

                            onStrokeUpdated(
                              index,
                              stroke.copyWith(colors: newColors),
                            );
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              border: Border.all(color: Colors.black26),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),
                    const Text("Stops"),
                    // Sliders for stops (except 0 and 1 usually, but let's allow moving middle one)
                    Column(
                      children: List.generate(stroke.stops.length, (stopIndex) {
                        // Don't edit first/last if we want to pin them?
                        // Or allow fully free. Let's allow fully free but clamped to neighbors.
                        // Simplified: Just slider 0..1
                        return Row(
                          children: [
                            Text("S$stopIndex"),
                            Expanded(
                              child: Slider(
                                value: stroke.stops[stopIndex],
                                min: 0.0,
                                max: 1.0,
                                onChanged: (val) {
                                  // Sort? usually stops must be sorted.
                                  // For MVP just set.
                                  List<double> newStops = List.from(
                                    stroke.stops,
                                  );
                                  newStops[stopIndex] = val;
                                  // Sort
                                  newStops.sort();
                                  onStrokeUpdated(
                                    index,
                                    stroke.copyWith(stops: newStops),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
