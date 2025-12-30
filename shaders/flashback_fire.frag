#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform float u_intensity;    // 0-1
uniform float u_transition;   // Fade in/out (0-1)
uniform float u_smoke;        // Smoke amount (0-1)

#define PI 3.14159265359

// Hash functions
float hash(float n) {
  return fract(sin(n) * 43758.5453123);
}

float hash2(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Noise function for smoke
float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);

  float a = hash2(i);
  float b = hash2(i + vec2(1.0, 0.0));
  float c = hash2(i + vec2(0.0, 1.0));
  float d = hash2(i + vec2(1.0, 1.0));

  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion for smoke
float fbm(vec2 p) {
  float f = 0.0;
  float w = 0.5;
  for (int i = 0; i < 5; i++) {
    f += w * noise(p);
    p *= 2.0;
    w *= 0.5;
  }
  return f;
}

// Ember particle
vec3 ember(vec2 uv, vec2 pos, float life, float seed) {
  float dist = length(uv - pos);

  // Ember glow - orange to red
  float glow = smoothstep(0.015, 0.0, dist) * life;

  // Flicker
  float flicker = sin(u_time * 20.0 + seed * 10.0) * 0.3 + 0.7;
  glow *= flicker;

  // Color: orange-red gradient
  vec3 col = mix(vec3(1.0, 0.2, 0.0), vec3(1.0, 0.6, 0.0), life);

  return col * glow;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float aspect = u_size.x / u_size.y;
  uv.x *= aspect;

  // Dark background with red/orange tinge
  vec3 col = mix(vec3(0.05, 0.02, 0.01), vec3(0.15, 0.05, 0.02), uv.y * 0.5);

  // Fire base at bottom
  float fireHeight = 0.3 + sin(uv.x * 10.0 + u_time * 3.0) * 0.05;
  fireHeight += sin(uv.x * 20.0 - u_time * 5.0) * 0.03;
  fireHeight *= u_intensity;

  if (uv.y < fireHeight) {
    // Fire gradient
    float fireT = uv.y / fireHeight;
    vec3 fireCol = mix(
      vec3(1.0, 0.9, 0.0),  // Yellow core
      vec3(1.0, 0.2, 0.0),  // Red outer
      fireT
    );

    // Fire flicker
    float flicker = noise(vec2(uv.x * 5.0, u_time * 10.0)) * 0.5 + 0.5;
    fireCol *= flicker * 0.5 + 0.5;

    col = mix(col, fireCol, 1.0 - fireT * 0.5);
  }

  // Glowing edges near fire
  float glowDist = abs(uv.y - fireHeight);
  if (uv.y > fireHeight && glowDist < 0.1) {
    float edgeGlow = 1.0 - glowDist / 0.1;
    edgeGlow *= edgeGlow;
    col += vec3(1.0, 0.3, 0.0) * edgeGlow * 0.5 * u_intensity;
  }

  // Rising embers
  for (float i = 0.0; i < 50.0; i++) {
    float seed = i * 0.789;

    // Position - rises over time
    float lifetime = mod(u_time * 0.5 + hash(seed) * 5.0, 5.0);
    float progress = lifetime / 5.0;

    float startX = hash(seed + 1.0) * aspect;
    float startY = 0.0;

    // Rise with some horizontal drift
    float x = startX + sin(lifetime * 2.0 + seed * 10.0) * 0.1;
    float y = startY + progress * 0.8;

    // Fade out as it rises
    float life = 1.0 - progress;
    life *= u_intensity;

    col += ember(uv, vec2(x, y), life, seed);
  }

  // Smoke layer
  if (u_smoke > 0.0) {
    vec2 smokeUV = uv;
    smokeUV.y -= u_time * 0.1; // Rising smoke
    smokeUV.x += sin(u_time * 0.5 + uv.y * 2.0) * 0.1; // Drift

    float smoke = fbm(smokeUV * 3.0);
    smoke = smoothstep(0.3, 0.7, smoke);

    // Only show smoke in upper portion
    float smokeMask = smoothstep(0.2, 0.6, uv.y);
    smoke *= smokeMask * u_smoke * 0.6;

    // Gray smoke
    col = mix(col, vec3(0.3, 0.3, 0.35), smoke);
  }

  // Vignette
  vec2 vigUV = (uv / vec2(aspect, 1.0)) - vec2(0.5);
  float vig = 1.0 - dot(vigUV, vigUV) * 0.5;
  col *= vig;

  // Apply transition
  col *= u_transition;

  fragColor = vec4(col, 1.0);
}
