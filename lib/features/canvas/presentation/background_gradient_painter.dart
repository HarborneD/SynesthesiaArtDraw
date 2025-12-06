import 'dart:ui';
import 'package:flutter/material.dart';
import '../../drawing/domain/gradient_stroke.dart';

class BackgroundGradientPainter extends CustomPainter {
  final FragmentShader? shader;
  final List<GradientStroke> strokes;
  final double time; // Could be used for animation later

  // Shader Constants
  static const int MAX_STROKES = 8;
  static const int MAX_COLORS_PER_STROKE = 4;

  BackgroundGradientPainter({
    required this.shader,
    required this.strokes,
    this.time = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shader == null) {
      // Fallback or empty background
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
      return;
    }

    // --- Set Uniforms ---
    // Uniform Map:
    // 0: uResolution (vec2)
    // 1: uStrokeCount (float)
    // Arrays follow. Flutter FragmentShader API uses explicit indices.
    // However, for arrays, we just increment the index (floats).

    // Index 0: Resolution Width
    shader!.setFloat(0, size.width);
    // Index 1: Resolution Height
    shader!.setFloat(1, size.height);
    // Index 2: Stroke Count
    shader!.setFloat(2, strokes.length.toDouble());

    int uIndex = 3;

    // We must fill up to MAX_STROKES even if not used, or just handle strict layout.
    // The shader declares:
    // uniform vec2 uStrokeP0[MAX_STROKES];
    // uniform vec2 uStrokeP1[MAX_STROKES];
    // uniform float uStrokeIntensity[MAX_STROKES];
    // uniform vec4 uStrokeColors[MAX_STROKES * 4];
    // uniform float uStrokeStops[MAX_STROKES * 4];
    // uniform float uStrokeColorCount[MAX_STROKES];

    // Helper to safety check bounds
    int strokeCount = strokes.length;
    if (strokeCount > MAX_STROKES) strokeCount = MAX_STROKES;

    // 1. P0 Array (vec2 * 16) = 32 floats
    for (int i = 0; i < MAX_STROKES; i++) {
      if (i < strokeCount) {
        shader!.setFloat(uIndex++, strokes[i].p0.dx);
        shader!.setFloat(uIndex++, strokes[i].p0.dy);
      } else {
        shader!.setFloat(uIndex++, 0);
        shader!.setFloat(uIndex++, 0);
      }
    }

    // 2. P1 Array (vec2 * 16) = 32 floats
    for (int i = 0; i < MAX_STROKES; i++) {
      if (i < strokeCount) {
        shader!.setFloat(uIndex++, strokes[i].p1.dx);
        shader!.setFloat(uIndex++, strokes[i].p1.dy);
      } else {
        shader!.setFloat(uIndex++, 0);
        shader!.setFloat(uIndex++, 0);
      }
    }

    // 3. Intensity Array (float * 16)
    for (int i = 0; i < MAX_STROKES; i++) {
      if (i < strokeCount) {
        shader!.setFloat(uIndex++, strokes[i].intensity);
      } else {
        shader!.setFloat(uIndex++, 0);
      }
    }

    // 4. Split Colors Arrays (vec4 * 8 each)
    // uStrokeColors0, 1, 2, 3
    // We loop for each slot (0..3) then for each stroke (0..MAX) to fill that array

    // Slot 0 (Colors 0)
    for (int i = 0; i < MAX_STROKES; i++) {
      if (i < strokeCount && strokes[i].colors.isNotEmpty) {
        Color c = strokes[i].colors[0];
        shader!.setFloat(uIndex++, c.red / 255.0);
        shader!.setFloat(uIndex++, c.green / 255.0);
        shader!.setFloat(uIndex++, c.blue / 255.0);
        shader!.setFloat(uIndex++, c.alpha / 255.0);
      } else {
        shader!.setFloat(uIndex++, 0);
        shader!.setFloat(uIndex++, 0);
        shader!.setFloat(uIndex++, 0);
        shader!.setFloat(uIndex++, 0);
      }
    }
    // Slot 1 (Colors 1)
    for (int i = 0; i < MAX_STROKES; i++) {
      if (i < strokeCount && strokes[i].colors.length > 1) {
        Color c = strokes[i].colors[1];
        shader!.setFloat(uIndex++, c.red / 255.0);
        shader!.setFloat(uIndex++, c.green / 255.0);
        shader!.setFloat(uIndex++, c.blue / 255.0);
        shader!.setFloat(uIndex++, c.alpha / 255.0);
      } else {
        shader!.setFloat(uIndex++, 0);
        shader!.setFloat(uIndex++, 0);
        shader!.setFloat(uIndex++, 0);
        shader!.setFloat(uIndex++, 0);
      }
    }
    // Slot 2
    for (int i = 0; i < MAX_STROKES; i++) {
      if (i < strokeCount && strokes[i].colors.length > 2) {
        Color c = strokes[i].colors[2];
        shader!.setFloat(uIndex++, c.red / 255.0);
        shader!.setFloat(uIndex++, c.green / 255.0);
        shader!.setFloat(uIndex++, c.blue / 255.0);
        shader!.setFloat(uIndex++, c.alpha / 255.0);
      } else {
        shader!.setFloat(uIndex++, 0);
        shader!.setFloat(uIndex++, 0);
        shader!.setFloat(uIndex++, 0);
        shader!.setFloat(uIndex++, 0);
      }
    }
    // Slot 3
    for (int i = 0; i < MAX_STROKES; i++) {
      if (i < strokeCount && strokes[i].colors.length > 3) {
        Color c = strokes[i].colors[3];
        shader!.setFloat(uIndex++, c.red / 255.0);
        shader!.setFloat(uIndex++, c.green / 255.0);
        shader!.setFloat(uIndex++, c.blue / 255.0);
        shader!.setFloat(uIndex++, c.alpha / 255.0);
      } else {
        shader!.setFloat(uIndex++, 0);
        shader!.setFloat(uIndex++, 0);
        shader!.setFloat(uIndex++, 0);
        shader!.setFloat(uIndex++, 0);
      }
    }

    // 5. Split Stops Arrays (float * 8 each)
    // Slot 0
    for (int i = 0; i < MAX_STROKES; i++) {
      if (i < strokeCount && strokes[i].stops.isNotEmpty)
        shader!.setFloat(uIndex++, strokes[i].stops[0]);
      else
        shader!.setFloat(uIndex++, 0);
    }
    // Slot 1
    for (int i = 0; i < MAX_STROKES; i++) {
      if (i < strokeCount && strokes[i].stops.length > 1)
        shader!.setFloat(uIndex++, strokes[i].stops[1]);
      else
        shader!.setFloat(uIndex++, 0);
    }
    // Slot 2
    for (int i = 0; i < MAX_STROKES; i++) {
      if (i < strokeCount && strokes[i].stops.length > 2)
        shader!.setFloat(uIndex++, strokes[i].stops[2]);
      else
        shader!.setFloat(uIndex++, 0);
    }
    // Slot 3
    for (int i = 0; i < MAX_STROKES; i++) {
      if (i < strokeCount && strokes[i].stops.length > 3)
        shader!.setFloat(uIndex++, strokes[i].stops[3]);
      else
        shader!.setFloat(uIndex++, 0);
    }

    // 6. Color Counts (float * 16)
    for (int i = 0; i < MAX_STROKES; i++) {
      if (i < strokeCount) {
        shader!.setFloat(uIndex++, strokes[i].colors.length.toDouble());
      } else {
        shader!.setFloat(uIndex++, 0);
      }
    }

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant BackgroundGradientPainter oldDelegate) {
    if (oldDelegate.shader != shader) return true;
    if (oldDelegate.strokes.length != strokes.length) return true;
    // Deep check if needed, or assum immutable update
    // For performance, assuming ref change or length change triggers.
    // But internal change to last stroke needs repaint.
    return true;
  }
}
