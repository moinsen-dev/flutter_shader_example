#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform float u_intensity;    // 0-1
uniform float u_transition;   // Fade in/out (0-1)
uniform float u_shake;        // Shake strength (0-1)

#define PI 3.14159265359

// Hash function
float hash(float n) {
  return fract(sin(n) * 43758.5453123);
}

float hash2(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Noise
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

// Dust particle
vec3 dustParticle(vec2 uv, vec2 pos, float size, float alpha) {
  float dist = length(uv - pos);
  float glow = smoothstep(size, size * 0.3, dist);
  return vec3(0.6, 0.5, 0.4) * glow * alpha;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float aspect = u_size.x / u_size.y;

  // Apply screen shake
  float shakeAmount = u_shake * u_intensity * 0.03;
  float shakeX = sin(u_time * 47.0) * shakeAmount;
  float shakeY = cos(u_time * 53.0) * shakeAmount;
  uv += vec2(shakeX, shakeY);

  uv.x *= aspect;

  // Cracked earth background - brown/gray tones
  vec3 groundCol = mix(
    vec3(0.25, 0.18, 0.12),  // Brown
    vec3(0.35, 0.28, 0.22),  // Lighter brown
    noise(uv * 5.0)
  );

  // Dark, ominous sky
  vec3 skyCol = mix(
    vec3(0.15, 0.12, 0.1),   // Dark brown-gray
    vec3(0.25, 0.2, 0.18),   // Lighter at horizon
    1.0 - uv.y
  );

  // Mix ground and sky
  float horizon = 0.35 + sin(uv.x * 3.0) * 0.02;
  vec3 col = mix(groundCol, skyCol, smoothstep(horizon - 0.02, horizon + 0.02, uv.y));

  // Cracks in the ground
  if (uv.y < horizon) {
    float crackNoise = noise(uv * 20.0 + vec2(0.0, u_time * 0.2));
    float crack = smoothstep(0.45, 0.5, crackNoise);

    // Dark crack lines
    if (crack > 0.5) {
      col = mix(col, vec3(0.05, 0.03, 0.02), 0.8);
    }

    // Glowing from beneath (molten look)
    float glowCrack = smoothstep(0.42, 0.45, crackNoise);
    if (glowCrack > 0.5 && crack < 0.5) {
      col += vec3(0.8, 0.3, 0.0) * 0.3 * u_intensity;
    }
  }

  // Debris/rubble particles
  for (float i = 0.0; i < 30.0; i++) {
    float seed = i * 1.234;

    // Random position with slight movement
    float baseX = hash(seed) * aspect;
    float baseY = hash(seed + 1.0) * 0.4;

    // Shake movement
    float moveX = sin(u_time * 10.0 + seed * 5.0) * u_shake * 0.02;
    float moveY = cos(u_time * 12.0 + seed * 7.0) * u_shake * 0.015;

    vec2 pos = vec2(baseX + moveX, baseY + moveY);

    float size = 0.005 + hash(seed + 2.0) * 0.01;
    float alpha = 0.5 + hash(seed + 3.0) * 0.5;

    col += dustParticle(uv, pos, size, alpha * u_intensity);
  }

  // Rising dust clouds
  for (float i = 0.0; i < 5.0; i++) {
    float seed = i * 3.456;
    float xPos = hash(seed) * aspect;

    // Dust column
    float dustX = abs(uv.x - xPos);
    if (dustX < 0.1) {
      float dustHeight = hash(seed + 1.0) * 0.4 + 0.3;
      if (uv.y < dustHeight) {
        float dustDensity = 1.0 - dustX / 0.1;
        dustDensity *= 1.0 - uv.y / dustHeight;

        // Animate dust rising
        float dustMove = sin(u_time * 2.0 + seed * 2.0) * 0.1;
        dustDensity *= noise(vec2(uv.x * 10.0, uv.y * 8.0 - u_time * 0.5)) * 0.5 + 0.5;

        col = mix(col, vec3(0.5, 0.45, 0.4), dustDensity * 0.4 * u_intensity);
      }
    }
  }

  // Falling debris in the sky
  for (float i = 0.0; i < 20.0; i++) {
    float seed = i * 2.345;

    // Falling motion
    float fallSpeed = 0.3 + hash(seed) * 0.4;
    float xStart = hash(seed + 1.0) * aspect;
    float yStart = 1.0 + hash(seed + 2.0) * 0.5;

    float t = mod(u_time * fallSpeed + hash(seed + 3.0) * 10.0, 2.0);
    float x = xStart + sin(t * 3.0 + seed) * 0.05;
    float y = yStart - t * 0.6;

    if (y > horizon && y < 1.0) {
      float dist = length(uv - vec2(x, y));
      float size = 0.003 + hash(seed + 4.0) * 0.005;
      float glow = smoothstep(size, 0.0, dist);

      col += vec3(0.4, 0.35, 0.3) * glow * u_intensity;
    }
  }

  // Screen edge darkening for drama
  vec2 vigUV = (uv / vec2(aspect, 1.0)) - vec2(0.5);
  float vig = 1.0 - dot(vigUV, vigUV) * 0.8;
  col *= vig;

  // Overall dark, somber tone
  col *= 0.8;

  // Apply transition
  col *= u_transition;

  fragColor = vec4(col, 1.0);
}
