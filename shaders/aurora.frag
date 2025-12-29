#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform float u_intensity;    // Aurora brightness (0.5 - 2.0)
uniform float u_speed;        // Wave speed (0.5 - 2.0)
uniform float u_hiss;         // Audio/hiss input (0-1) - makes aurora react

#define PI 3.14159265359

// Simplex-ish noise for smooth aurora waves
float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);

  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));

  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  vec2 shift = vec2(100.0);
  for (int i = 0; i < 5; i++) {
    v += a * noise(p);
    p = p * 2.0 + shift;
    a *= 0.5;
  }
  return v;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float aspect = u_size.x / u_size.y;

  // Time with speed control
  float t = u_time * u_speed;

  // Night sky gradient
  vec3 skyTop = vec3(0.0, 0.02, 0.08);
  vec3 skyBottom = vec3(0.02, 0.05, 0.12);
  vec3 col = mix(skyBottom, skyTop, uv.y);

  // Stars
  for (float i = 0.0; i < 100.0; i++) {
    vec2 starPos = vec2(hash(vec2(i, 0.0)), hash(vec2(0.0, i)));
    float twinkle = sin(t * 3.0 + i * 0.5) * 0.3 + 0.7;
    float starSize = 0.001 + hash(vec2(i * 2.0, i)) * 0.002;
    float starBright = smoothstep(starSize, 0.0, length(uv - starPos)) * twinkle;
    col += vec3(0.8, 0.85, 1.0) * starBright * 0.8;
  }

  // Aurora layers
  float auroraY = uv.y;

  // Multiple aurora curtains
  for (float layer = 0.0; layer < 3.0; layer++) {
    float layerOffset = layer * 0.15;
    float layerSpeed = 1.0 + layer * 0.3;

    // Wavy base position
    float wave1 = sin(uv.x * 3.0 + t * layerSpeed + layer) * 0.1;
    float wave2 = sin(uv.x * 7.0 - t * 0.7 * layerSpeed + layer * 2.0) * 0.05;
    float wave3 = fbm(vec2(uv.x * 2.0 + t * 0.3, layer)) * 0.15;

    // Hiss makes aurora more energetic
    float hissWave = sin(uv.x * 20.0 + t * 5.0) * u_hiss * 0.1;

    float auroraBase = 0.5 + layerOffset + wave1 + wave2 + wave3 + hissWave;
    float auroraHeight = 0.3 + fbm(vec2(uv.x * 1.5 + t * 0.2, layer * 10.0)) * 0.2;
    auroraHeight += u_hiss * 0.15; // Hiss expands aurora

    // Aurora shape
    float aurora = smoothstep(auroraBase, auroraBase + auroraHeight, auroraY);
    aurora *= smoothstep(auroraBase + auroraHeight + 0.1, auroraBase + auroraHeight * 0.5, auroraY);

    // Curtain folds (vertical striations)
    float folds = sin(uv.x * 50.0 + wave1 * 20.0 + t * 2.0) * 0.5 + 0.5;
    folds = pow(folds, 0.5);
    aurora *= 0.5 + folds * 0.5;

    // Color varies by layer and position
    float hue = 0.45 + layer * 0.1 + sin(uv.x * 2.0 + t) * 0.1;
    vec3 auroraColor;
    if (layer < 1.0) {
      // Green dominant
      auroraColor = mix(vec3(0.1, 0.8, 0.3), vec3(0.2, 1.0, 0.5), folds);
    } else if (layer < 2.0) {
      // Blue-green
      auroraColor = mix(vec3(0.1, 0.6, 0.8), vec3(0.3, 0.9, 0.7), folds);
    } else {
      // Purple hints
      auroraColor = mix(vec3(0.5, 0.2, 0.8), vec3(0.3, 0.5, 0.9), folds);
    }

    // Add to scene
    float brightness = aurora * u_intensity * (0.3 + layer * 0.1);
    brightness *= 1.0 + u_hiss * 0.5; // Hiss brightens aurora
    col += auroraColor * brightness;

    // Bright spots
    float spots = pow(fbm(vec2(uv.x * 10.0 + t, auroraY * 5.0 + layer)), 3.0);
    col += auroraColor * spots * aurora * 0.5;
  }

  // Mountain silhouettes
  float mountain1 = 0.15 + sin(uv.x * 3.0 + 0.5) * 0.08 + sin(uv.x * 7.0) * 0.03;
  float mountain2 = 0.12 + sin(uv.x * 4.0 + 2.0) * 0.06 + sin(uv.x * 11.0) * 0.02;
  float mountain3 = 0.08 + sin(uv.x * 2.0 + 1.0) * 0.04;

  float mountains = 0.0;
  if (uv.y < mountain1) mountains = 1.0;
  if (uv.y < mountain2) mountains = max(mountains, 0.7);
  if (uv.y < mountain3) mountains = max(mountains, 0.4);

  // Snow caps
  float snowLine = mountain1 - 0.02 + sin(uv.x * 20.0) * 0.01;
  float snow = smoothstep(snowLine, snowLine + 0.01, uv.y) * step(uv.y, mountain1);

  col = mix(col, vec3(0.02, 0.03, 0.05), mountains * 0.9);
  col += vec3(0.6, 0.65, 0.7) * snow * 0.3;

  // Reflection on "water" at very bottom
  if (uv.y < 0.05) {
    float reflection = (0.05 - uv.y) / 0.05;
    vec2 reflectUV = vec2(uv.x, 0.1 - uv.y);
    // Simplified reflection of aurora
    float reflectWave = sin(reflectUV.x * 3.0 + t) * 0.1;
    float reflectAurora = smoothstep(0.5 + reflectWave, 0.8, reflectUV.y) * 0.3;
    col += vec3(0.1, 0.5, 0.3) * reflectAurora * reflection;

    // Water ripples
    float ripple = sin(uv.x * 100.0 + t * 2.0) * sin(uv.y * 200.0) * 0.02;
    col *= 1.0 + ripple;
  }

  fragColor = vec4(col, 1.0);
}
