#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform float u_intensity;    // 0-1
uniform float u_transition;   // Fade in/out (0-1)
uniform float u_flicker;      // Candle flicker amount (0-1)

#define PI 3.14159265359

// Hash function
float hash(float n) {
  return fract(sin(n) * 43758.5453123);
}

// Noise for subtle variations
float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);

  float a = hash(dot(i, vec2(127.1, 311.7)));
  float b = hash(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7)));
  float c = hash(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7)));
  float d = hash(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7)));

  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Single candle flame
vec3 candleFlame(vec2 uv, vec2 pos, float seed) {
  vec2 diff = uv - pos;

  // Flame shape - taller than wide
  float flameWidth = 0.015;
  float flameHeight = 0.06;

  // Flicker animation
  float flicker = sin(u_time * 8.0 + seed * 10.0) * 0.3
                + sin(u_time * 12.0 + seed * 7.0) * 0.2
                + sin(u_time * 20.0 + seed * 3.0) * 0.1;
  flicker *= u_flicker;

  // Flame tip wobble
  diff.x += sin(u_time * 5.0 + seed * 5.0) * 0.003 * (1.0 + diff.y / flameHeight);

  // Distance from flame center
  float dx = abs(diff.x) / flameWidth;
  float dy = diff.y / flameHeight;

  // Flame shape
  float flame = 0.0;
  if (dy > 0.0 && dy < 1.0 && dx < 1.0) {
    // Tapered flame shape
    float taper = 1.0 - dy;
    if (dx < taper) {
      flame = (1.0 - dx / taper) * (1.0 - dy * 0.3);
    }
  }

  // Glow around flame
  float dist = length(diff * vec2(1.0, 0.5));
  float glow = smoothstep(0.08, 0.0, dist) * 0.5;

  // Color gradient: white core -> yellow -> orange
  vec3 flameCol = vec3(0.0);
  if (flame > 0.0) {
    float core = smoothstep(0.3, 0.8, flame);
    vec3 outerColor = vec3(1.0, 0.5, 0.1);  // Orange
    vec3 midColor = vec3(1.0, 0.8, 0.2);    // Yellow
    vec3 coreColor = vec3(1.0, 0.95, 0.8);  // White-yellow

    flameCol = mix(outerColor, midColor, flame);
    flameCol = mix(flameCol, coreColor, core);

    // Apply flicker to brightness
    flameCol *= (1.0 + flicker * 0.3);
  }

  // Add outer glow (golden)
  vec3 glowCol = vec3(1.0, 0.7, 0.3) * glow * (1.0 + flicker * 0.2);

  return flameCol + glowCol;
}

// Petal particle (falling gently)
vec3 petal(vec2 uv, vec2 pos, float size, float rotation, float alpha) {
  vec2 diff = uv - pos;

  // Rotate
  float c = cos(rotation);
  float s = sin(rotation);
  diff = vec2(diff.x * c - diff.y * s, diff.x * s + diff.y * c);

  // Oval petal shape
  float dist = length(diff * vec2(1.0, 2.0));
  float glow = smoothstep(size, size * 0.3, dist);

  // Soft pink/white color
  vec3 petalCol = mix(vec3(1.0, 0.85, 0.9), vec3(1.0, 0.95, 0.95), glow);

  return petalCol * glow * alpha;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float aspect = u_size.x / u_size.y;
  uv.x *= aspect;

  // Dark, solemn background with slight warmth
  vec3 bgTop = vec3(0.02, 0.02, 0.03);    // Almost black
  vec3 bgBottom = vec3(0.08, 0.05, 0.03); // Warm dark
  vec3 col = mix(bgBottom, bgTop, uv.y);

  // Subtle golden ambient light from below (candles)
  col += vec3(0.15, 0.08, 0.02) * (1.0 - uv.y) * 0.3 * u_intensity;

  // Array of candles at bottom
  float candleSpacing = aspect / 7.0;
  for (float i = 0.0; i < 7.0; i++) {
    float x = candleSpacing * (i + 0.5);
    float y = 0.08 + sin(i * 1.5) * 0.01; // Slight height variation

    vec3 flame = candleFlame(uv, vec2(x, y), i);
    col += flame * u_intensity;

    // Candle body (subtle)
    float candleDist = length(uv - vec2(x, y * 0.5));
    if (uv.y < y - 0.02 && abs(uv.x - x) < 0.008) {
      col = mix(col, vec3(0.9, 0.85, 0.7), 0.3); // Cream colored wax
    }
  }

  // Falling petals
  for (float i = 0.0; i < 25.0; i++) {
    float seed = i * 0.789;

    // Slow, gentle falling motion
    float fallSpeed = 0.1 + hash(seed) * 0.1;
    float xStart = hash(seed + 1.0) * aspect;
    float yStart = 1.2;

    float t = mod(u_time * fallSpeed + hash(seed + 2.0) * 20.0, 3.0);
    float x = xStart + sin(t * 2.0 + seed * 3.0) * 0.15; // Gentle drift
    float y = yStart - t * 0.5;

    // Rotation over time
    float rotation = t * 2.0 + seed * PI;

    if (y > -0.1 && y < 1.1) {
      float size = 0.01 + hash(seed + 3.0) * 0.01;
      float alpha = 0.3 + hash(seed + 4.0) * 0.4;
      alpha *= smoothstep(0.0, 0.2, y) * smoothstep(1.2, 0.8, y); // Fade in/out

      col += petal(uv, vec2(x, y), size, rotation, alpha * u_intensity);
    }
  }

  // Subtle light rays from above (divine light)
  float rayAngle = atan(uv.y - 0.3, uv.x - aspect * 0.5);
  float ray = sin(rayAngle * 8.0 + u_time * 0.2) * 0.5 + 0.5;
  ray *= smoothstep(0.5, 1.0, uv.y);
  col += vec3(1.0, 0.95, 0.8) * ray * 0.03 * u_intensity;

  // Vignette for somber mood
  vec2 vigUV = (uv / vec2(aspect, 1.0)) - vec2(0.5);
  float vig = 1.0 - dot(vigUV, vigUV) * 1.2;
  vig = clamp(vig, 0.0, 1.0);
  col *= vig;

  // Apply transition (fading to gold/black)
  col *= u_transition;

  fragColor = vec4(col, 1.0);
}
