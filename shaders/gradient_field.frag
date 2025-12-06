#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

// Reduce to ensure unrolling
const int MAX_STROKES = 8;
const int MAX_COLORS_PER_STROKE = 4;

uniform vec2 uResolution;
uniform float uStrokeCount; 

// Arrays
uniform vec2 uStrokeP0[MAX_STROKES];
uniform vec2 uStrokeP1[MAX_STROKES];
uniform float uStrokeIntensity[MAX_STROKES];

// Split into separate arrays to avoid `i*4` indexing which breaks SkSL on Metal
uniform vec4 uStrokeColors0[MAX_STROKES];
uniform vec4 uStrokeColors1[MAX_STROKES];
uniform vec4 uStrokeColors2[MAX_STROKES];
uniform vec4 uStrokeColors3[MAX_STROKES];

uniform float uStrokeStops0[MAX_STROKES];
uniform float uStrokeStops1[MAX_STROKES];
uniform float uStrokeStops2[MAX_STROKES];
uniform float uStrokeStops3[MAX_STROKES];

uniform float uStrokeColorCount[MAX_STROKES];

out vec4 fragColor;

// --- Colorspace Helpers ---

vec3 srgbToLinear(vec3 c) {
    // Approximation or exact logic
    // Using approx x^2.2 or standard sRGB curve
    // Standard sRGB logic as per spec
    
    vec3 linear;
    // Unrolled for performance consistency
    if (c.r <= 0.04045) linear.r = c.r / 12.92; else linear.r = pow((c.r + 0.055) / 1.055, 2.4);
    if (c.g <= 0.04045) linear.g = c.g / 12.92; else linear.g = pow((c.g + 0.055) / 1.055, 2.4);
    if (c.b <= 0.04045) linear.b = c.b / 12.92; else linear.b = pow((c.b + 0.055) / 1.055, 2.4);
    return linear;
}

vec3 linearToSrgb(vec3 c) {
    c = clamp(c, 0.0, 1.0);
    vec3 deep;
    
    if (c.r <= 0.0031308) deep.r = c.r * 12.92; else deep.r = 1.055 * pow(c.r, 1.0 / 2.4) - 0.055;
    if (c.g <= 0.0031308) deep.g = c.g * 12.92; else deep.g = 1.055 * pow(c.g, 1.0 / 2.4) - 0.055;
    if (c.b <= 0.0031308) deep.b = c.b * 12.92; else deep.b = 1.055 * pow(c.b, 1.0 / 2.4) - 0.055;
    return deep;
}

// --- Gradient Logic ---

void main() {
    vec2 pos = FlutterFragCoord().xy;
    
    vec3 accum = vec3(0.0);
    float wSum = 0.0;
    
    // Shader uniforms are strictly typed
    int count = int(uStrokeCount);
    
    // Explicitly unrollable loop by using constant bound
    for (int i = 0; i < MAX_STROKES; i++) {
        // Optimization: Break early via check, but compiler needs constant flow
        // so we just check active inside
        if (i < count) {
            vec2 p0 = uStrokeP0[i];
            vec2 p1 = uStrokeP1[i];
            float radius = uStrokeIntensity[i];
            
            vec2 v = p1 - p0;
            vec2 w = pos - p0;
            
            float denom = dot(v, v);
            float t = 0.0;
            if (denom > 0.0) {
               t = clamp(dot(w, v) / denom, 0.0, 1.0);
            }
            
            vec2 pClosest = p0 + v * t;
            float d = distance(pos, pClosest);
            
            if (d < radius && radius > 0.0) {
                float weight = 1.0 - (d / radius);
                
                // --- Inline Color Logic ---
                // Accessing arrays with 'i' (loop var) is usually safer for unrolling than function args
                
                int cCount = int(uStrokeColorCount[i]);
                
                // Fetch colors/stops directly via [i] which is proven safe
                vec3 col0 = uStrokeColors0[i].rgb;
                vec3 col1 = uStrokeColors1[i].rgb;
                vec3 col2 = uStrokeColors2[i].rgb;
                vec3 col3 = uStrokeColors3[i].rgb;
                
                float st0 = uStrokeStops0[i];
                float st1 = uStrokeStops1[i];
                float st2 = uStrokeStops2[i];
                float st3 = uStrokeStops3[i];

                vec3 rawCol = col0;
                
                if (cCount > 1) {
                    // Manual unroll for stops search (max 4 colors = 3 segments)
                    int idx = 0;
                    if (cCount > 1 && t > st1) idx = 1;
                    if (cCount > 2 && t > st2) idx = 2;
                    // Cap at last segment
                    if (idx >= cCount - 1) idx = cCount - 2;
                    
                    // Fetch stops/colors
                    // Note: accessing array with (base + const) is better
                    float s0 = 0.0;
                    float s1 = 1.0;
                    vec3 c0 = vec3(0.0);
                    vec3 c1 = vec3(0.0);
                    
                    // Branching on local scalar 'idx' is totally fine
                    if (idx == 0) {
                        s0 = st0; s1 = st1; c0 = col0; c1 = col1;
                    } else if (idx == 1) {
                        s0 = st1; s1 = st2; c0 = col1; c1 = col2;
                    } else { // idx == 2
                        s0 = st2; s1 = st3; c0 = col2; c1 = col3;
                    }
                    
                    float divisor = s1 - s0;
                    if (divisor < 0.0001) divisor = 1.0; // Avoid division by zero
                    float localT = clamp((t - s0) / divisor, 0.0, 1.0);
                    rawCol = mix(c0, c1, localT);
                }
                // --------------------------
                
                vec3 linCol = srgbToLinear(rawCol);
                
                accum += linCol * weight;
                wSum += weight;
            }
        }
    }
    
    vec3 outCol = vec3(0.0);
    if (wSum > 0.0) {
        outCol = accum / wSum;
    } 
    
    fragColor = vec4(linearToSrgb(outCol), 1.0);
}
