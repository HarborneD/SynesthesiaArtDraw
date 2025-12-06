import 'package:tonic/tonic.dart';

void main() {
  print('Available Scale Patterns:');
  // ScalePattern.data is usually a list or map of patterns if accessible,
  // or we can try to find common names.

  // Note: Since I don't have the source code of Tonic cached in my brain,
  // I will try to inspect what I can or just try standard names.
  // Documentation says: ScalePattern.findByName('Major') works.
  // Let's test a few.

  final testScales = [
    'Major',
    'Minor',
    'Diatonic Major',
    'Natural Minor',
    'Dorian',
    'Chromatic',
  ];

  for (final name in testScales) {
    try {
      final pattern = ScalePattern.findByName(name);
      print('Found "$name": ${pattern != null}');
    } catch (e) {
      print('Error finding "$name": $e');
    }
  }
}
