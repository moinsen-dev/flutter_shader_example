#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform float u_intensity;    // Party intensity (0-2)
uniform float u_confetti;     // Confetti amount (0-1)
uniform float u_bass;         // Bass/shake response (0-1)

#define PI 3.14159265359

float hash(float n) { return fract(sin(n) * 43758.5453); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Confetti piece
float confetti(vec2 uv, float id, float t) {
  // Random properties
  float speed = 0.3 + hash(id * 1.1) * 0.4;
  float startX = hash(id * 2.2);
  float wobble = sin(t * (3.0 + hash(id * 3.3) * 2.0) + id) * 0.1;
  float spin = t * (2.0 + hash(id * 4.4) * 4.0);

  // Position
  float y = 1.2 - mod(t * speed + hash(id * 5.5), 1.4);
  float x = startX + wobble;

  vec2 pos = vec2(x, y);
  vec2 diff = uv - pos;

  // Rotate
  float c = cos(spin);
  float s = sin(spin);
  diff = vec2(diff.x * c - diff.y * s, diff.x * s + diff.y * c);

  // Rectangle shape
  float size = 0.015 + hash(id * 6.6) * 0.01;
  float aspectR = 0.5 + hash(id * 7.7) * 0.5;

  float d = max(abs(diff.x) / size, abs(diff.y) / (size * aspectR));
  return smoothstep(1.0, 0.8, d);
}

// Sparkle burst
float sparkle(vec2 uv, vec2 center, float t, float seed) {
  float sparkles = 0.0;
  for (float i = 0.0; i < 12.0; i++) {
    float angle = i / 12.0 * PI * 2.0 + seed;
    float dist = t * (0.5 + hash(seed + i) * 0.3);
    vec2 pos = center + vec2(cos(angle), sin(angle)) * dist;

    float d = length(uv - pos);
    float twinkle = sin(t * 20.0 + i * 2.0) * 0.5 + 0.5;
    sparkles += smoothstep(0.01, 0.0, d) * twinkle * (1.0 - t);
  }
  return sparkles;
}

// "2026" text approximation using shapes
float text2026(vec2 p) {
  p *= 3.0;
  p.x += 1.5;

  float d = 1.0;
  float w = 0.15;  // segment width

  // === Digit "2" (first) at x: -1.5 to -1.0 ===
  // Shape:  ___
  //            |
  //         ___|
  //        |
  //        |___
  if (p.x > -1.5 && p.x < -1.0) {
    // Top horizontal
    if (p.y > 0.4 - w && p.y < 0.4 + w && p.x > -1.45 && p.x < -1.05) d = 0.0;
    // Top-right vertical
    if (p.x > -1.15 && p.x < -1.0 && p.y > 0.0 && p.y < 0.4 + w) d = 0.0;
    // Middle horizontal
    if (p.y > -w && p.y < w && p.x > -1.45 && p.x < -1.05) d = 0.0;
    // Bottom-left vertical
    if (p.x > -1.5 && p.x < -1.35 && p.y > -0.4 - w && p.y < 0.0) d = 0.0;
    // Bottom horizontal
    if (p.y > -0.4 - w && p.y < -0.4 + w && p.x > -1.45 && p.x < -1.05) d = 0.0;
  }

  // === Digit "0" at x: -0.8 to -0.3 ===
  if (p.x > -0.8 && p.x < -0.3) {
    float ring = abs(length(p - vec2(-0.55, 0.0)) - 0.2);
    if (ring < 0.08) d = 0.0;
  }

  // === Digit "2" (second) at x: 0.0 to 0.5 ===
  if (p.x > 0.0 && p.x < 0.5) {
    // Top horizontal
    if (p.y > 0.4 - w && p.y < 0.4 + w && p.x > 0.05 && p.x < 0.45) d = 0.0;
    // Top-right vertical
    if (p.x > 0.35 && p.x < 0.5 && p.y > 0.0 && p.y < 0.4 + w) d = 0.0;
    // Middle horizontal
    if (p.y > -w && p.y < w && p.x > 0.05 && p.x < 0.45) d = 0.0;
    // Bottom-left vertical
    if (p.x > 0.0 && p.x < 0.15 && p.y > -0.4 - w && p.y < 0.0) d = 0.0;
    // Bottom horizontal
    if (p.y > -0.4 - w && p.y < -0.4 + w && p.x > 0.05 && p.x < 0.45) d = 0.0;
  }

  // === Digit "6" at x: 0.7 to 1.2 ===
  // Shape:  ___
  //        |
  //        |___
  //        |   |
  //        |___|
  if (p.x > 0.7 && p.x < 1.2) {
    // Top horizontal
    if (p.y > 0.4 - w && p.y < 0.4 + w && p.x > 0.75 && p.x < 1.15) d = 0.0;
    // Left vertical (full height)
    if (p.x > 0.7 && p.x < 0.85 && p.y > -0.4 - w && p.y < 0.4 + w) d = 0.0;
    // Middle horizontal
    if (p.y > -w && p.y < w && p.x > 0.75 && p.x < 1.15) d = 0.0;
    // Bottom horizontal
    if (p.y > -0.4 - w && p.y < -0.4 + w && p.x > 0.75 && p.x < 1.15) d = 0.0;
    // Right vertical (bottom half only - from middle to bottom)
    if (p.x > 1.05 && p.x < 1.2 && p.y > -0.4 - w && p.y < w) d = 0.0;
  }

  return 1.0 - d;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float aspect = u_size.x / u_size.y;
  uv.x *= aspect;

  float t = u_time;

  // Bass shake
  vec2 shake = vec2(sin(t * 50.0), cos(t * 47.0)) * u_bass * 0.01;
  uv += shake;

  // Energetic background
  vec3 col = vec3(0.0);

  // Radial gradient pulse
  vec2 center = vec2(aspect * 0.5, 0.5);
  float dist = length(uv - center);
  float pulse = sin(t * 4.0) * 0.5 + 0.5;

  // Rainbow rings
  float rings = sin(dist * 30.0 - t * 5.0) * 0.5 + 0.5;
  float hue = mod(dist * 2.0 + t * 0.5, 1.0);
  vec3 ringColor = hsv2rgb(vec3(hue, 0.8, 0.6));
  col += ringColor * rings * 0.3 * u_intensity;

  // Dark center for text visibility
  col *= smoothstep(0.0, 0.5, dist);

  // Disco ball rays
  float rayAngle = atan(uv.y - 0.5, uv.x - center.x);
  float rays = pow(sin(rayAngle * 8.0 + t * 3.0) * 0.5 + 0.5, 4.0);
  vec3 rayColor = hsv2rgb(vec3(mod(rayAngle / PI + t * 0.2, 1.0), 0.7, 0.8));
  col += rayColor * rays * 0.2 * u_intensity;

  // "2026" text
  vec2 textUV = (uv - vec2(aspect * 0.5, 0.5)) * 2.0;
  float text = text2026(textUV);

  // Text with gradient
  vec3 textGrad = hsv2rgb(vec3(mod(t * 0.3 + textUV.x * 0.2, 1.0), 0.6, 1.0));
  col = mix(col, textGrad, text * 0.9);

  // Text glow
  float textGlow = text2026(textUV * 0.95);
  col += textGrad * 0.5 * textGlow * (1.0 - text);

  // Confetti!
  for (float i = 0.0; i < 50.0; i++) {
    float c = confetti(uv / vec2(aspect, 1.0), i, t);
    if (c > 0.0) {
      vec3 confettiColor = hsv2rgb(vec3(hash(i * 8.8), 0.8, 1.0));
      col = mix(col, confettiColor, c * u_confetti);
    }
  }

  // Sparkle bursts
  for (float i = 0.0; i < 5.0; i++) {
    float burstTime = mod(t + i * 1.3, 2.0);
    vec2 burstPos = vec2(
      (hash(i * 11.0) * 0.8 + 0.1) * aspect,
      hash(i * 22.0) * 0.8 + 0.1
    );
    float s = sparkle(uv, burstPos, burstTime, i * 33.0);
    col += vec3(1.0, 0.95, 0.8) * s * 0.5;
  }

  // Golden sparkles scattered
  for (float i = 0.0; i < 30.0; i++) {
    vec2 sparkPos = vec2(
      hash(i * 44.0) * aspect,
      hash(i * 55.0)
    );
    float twinkle = pow(sin(t * (3.0 + hash(i * 66.0) * 3.0) + i) * 0.5 + 0.5, 3.0);
    float sparkDist = length(uv - sparkPos);
    col += vec3(1.0, 0.9, 0.5) * smoothstep(0.01, 0.0, sparkDist) * twinkle;
  }

  // Vignette
  float vignette = 1.0 - pow(length(uv / vec2(aspect, 1.0) - vec2(0.5, 0.5)) * 1.2, 2.0);
  col *= max(vignette, 0.3);

  // Final intensity boost
  col *= 0.8 + u_intensity * 0.4;

  fragColor = vec4(col, 1.0);
}
