#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform float u_intensity;    // 0-1
uniform float u_transition;   // Fade in/out (0-1)
uniform float u_confetti;     // Confetti density (0-1)

#define PI 3.14159265359

// Hash functions
float hash(float n) {
  return fract(sin(n) * 43758.5453123);
}

float hash2(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// HSV to RGB conversion
vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Rainbow gradient based on position
vec3 rainbow(float t) {
  // Pride flag colors: red, orange, yellow, green, blue, purple
  t = fract(t);
  if (t < 0.167) return vec3(0.9, 0.1, 0.1);       // Red
  if (t < 0.333) return vec3(1.0, 0.5, 0.0);       // Orange
  if (t < 0.5)   return vec3(1.0, 0.9, 0.0);       // Yellow
  if (t < 0.667) return vec3(0.0, 0.7, 0.2);       // Green
  if (t < 0.833) return vec3(0.0, 0.3, 0.9);       // Blue
  return vec3(0.5, 0.0, 0.7);                       // Purple
}

// Smooth rainbow with blending
vec3 smoothRainbow(float t) {
  float hue = fract(t);
  return hsv2rgb(vec3(hue, 0.9, 1.0));
}

// Confetti piece
vec3 confetti(vec2 uv, vec2 pos, float size, float rotation, vec3 color, float alpha) {
  vec2 diff = uv - pos;

  // Rotate
  float c = cos(rotation);
  float s = sin(rotation);
  diff = vec2(diff.x * c - diff.y * s, diff.x * s + diff.y * c);

  // Rectangle shape (confetti piece)
  float dx = abs(diff.x);
  float dy = abs(diff.y);

  float shape = 0.0;
  if (dx < size && dy < size * 0.5) {
    shape = 1.0;
  }

  return color * shape * alpha;
}

// Sparkle/glitter
vec3 sparkle(vec2 uv, vec2 pos, float seed) {
  float dist = length(uv - pos);

  // Twinkling
  float twinkle = sin(u_time * 10.0 + seed * 20.0) * 0.5 + 0.5;
  twinkle = pow(twinkle, 3.0); // Sharp twinkle

  float glow = smoothstep(0.01, 0.0, dist) * twinkle;

  // White-ish sparkle with slight color
  vec3 col = mix(vec3(1.0), smoothRainbow(seed + u_time * 0.1), 0.3);

  return col * glow;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float aspect = u_size.x / u_size.y;
  uv.x *= aspect;

  // Animated rainbow gradient background
  float waveOffset = sin(uv.y * 3.0 + u_time * 0.5) * 0.1;
  float rainbowT = (uv.x / aspect + waveOffset + u_time * 0.1);

  // Create bands
  vec3 col = vec3(0.0);

  // Rainbow stripes (diagonal, animated)
  float stripeWidth = 0.15;
  float diag = uv.x + uv.y * 0.5 + u_time * 0.2;
  float stripe = mod(diag, stripeWidth * 6.0) / (stripeWidth * 6.0);
  vec3 bgRainbow = rainbow(stripe);

  // Soften and brighten
  col = bgRainbow * 0.4 + 0.1;

  // Add animated wave overlay
  float wave = sin(uv.x * 8.0 - u_time * 2.0) * 0.5 + 0.5;
  wave *= sin(uv.y * 6.0 + u_time * 1.5) * 0.5 + 0.5;
  col += smoothRainbow(uv.x / aspect + u_time * 0.05) * wave * 0.3;

  // Falling confetti
  for (float i = 0.0; i < 60.0; i++) {
    float seed = i * 0.123;

    // Fall parameters
    float fallSpeed = 0.15 + hash(seed) * 0.2;
    float xStart = hash(seed + 1.0) * aspect;
    float yStart = 1.3;

    // Sine wave horizontal drift
    float t = mod(u_time * fallSpeed + hash(seed + 2.0) * 15.0, 3.5);
    float x = xStart + sin(t * 3.0 + seed * 5.0) * 0.1;
    float y = yStart - t * 0.5;

    // Tumbling rotation
    float rotation = t * 5.0 + seed * PI * 2.0;

    if (y > -0.1 && y < 1.3) {
      float size = 0.008 + hash(seed + 3.0) * 0.008;
      float alpha = 0.6 + hash(seed + 4.0) * 0.4;

      // Rainbow colored confetti
      vec3 confettiCol = rainbow(hash(seed + 5.0) + u_time * 0.1);

      col += confetti(uv, vec2(x, y), size, rotation, confettiCol, alpha * u_confetti * u_intensity);
    }
  }

  // Rising bubbles/circles
  for (float i = 0.0; i < 20.0; i++) {
    float seed = i * 0.456;

    float riseSpeed = 0.1 + hash(seed) * 0.1;
    float xPos = hash(seed + 1.0) * aspect;

    float t = mod(u_time * riseSpeed + hash(seed + 2.0) * 10.0, 4.0);
    float x = xPos + sin(t * 2.0 + seed) * 0.05;
    float y = -0.1 + t * 0.35;

    if (y > 0.0 && y < 1.2) {
      float dist = length(uv - vec2(x, y));
      float size = 0.02 + hash(seed + 3.0) * 0.02;

      // Bubble edge
      float bubble = smoothstep(size, size - 0.003, dist) - smoothstep(size - 0.003, size - 0.006, dist);

      // Rainbow bubble
      vec3 bubbleCol = smoothRainbow(seed + t * 0.5);
      col += bubbleCol * bubble * 0.5 * u_intensity;

      // Bubble highlight
      vec2 highlightOffset = vec2(-0.003, 0.003);
      float highlight = smoothstep(0.005, 0.0, length(uv - vec2(x, y) + highlightOffset));
      col += vec3(1.0) * highlight * 0.3;
    }
  }

  // Sparkles everywhere
  for (float i = 0.0; i < 40.0; i++) {
    float seed = i * 0.789;
    vec2 pos = vec2(
      hash(seed) * aspect,
      hash(seed + 1.0)
    );

    // Move sparkles slightly
    pos += vec2(sin(u_time + seed * 5.0), cos(u_time * 0.7 + seed * 3.0)) * 0.02;

    col += sparkle(uv, pos, seed) * u_intensity;
  }

  // Bright, joyful overall tone
  col = pow(col, vec3(0.9)); // Slight gamma for vibrancy

  // Light vignette (much lighter than other shaders)
  vec2 vigUV = (uv / vec2(aspect, 1.0)) - vec2(0.5);
  float vig = 1.0 - dot(vigUV, vigUV) * 0.3;
  col *= vig;

  // Apply transition
  col *= u_transition;

  fragColor = vec4(col, 1.0);
}
