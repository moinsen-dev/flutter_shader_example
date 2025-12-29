#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform float u_trigger;      // Explosion trigger (0-1, animated on tap)
uniform float u_explosion_x;  // Explosion center X (0-1)
uniform float u_explosion_y;  // Explosion center Y (0-1)
uniform float u_hue_shift;    // Color variation (0-1)
uniform float u_shake;        // Device shake intensity (0-1)

#define PI 3.14159265359
#define NUM_PARTICLES 80.0
#define NUM_SPARKS 40.0

// Hash for randomness
float hash(float n) {
  return fract(sin(n) * 43758.5453123);
}

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Single firework explosion
vec3 firework(vec2 uv, vec2 center, float t, float seed, float hue) {
  vec3 col = vec3(0.0);

  if (t < 0.0 || t > 2.0) return col;

  // Explosion phase
  float explodeT = clamp(t, 0.0, 1.0);
  float fadeT = clamp(t - 0.5, 0.0, 1.5) / 1.5;

  // Main particles
  for (float i = 0.0; i < NUM_PARTICLES; i++) {
    float angle = (i / NUM_PARTICLES) * PI * 2.0 + hash(seed + i) * 0.5;
    float speed = 0.3 + hash(seed + i * 2.0) * 0.4;

    // Particle position with gravity
    vec2 vel = vec2(cos(angle), sin(angle)) * speed;
    vec2 pos = center + vel * explodeT - vec2(0.0, 0.15) * explodeT * explodeT;

    // Trail
    for (float j = 0.0; j < 5.0; j++) {
      float trailT = explodeT - j * 0.02;
      if (trailT < 0.0) continue;

      vec2 trailPos = center + vel * trailT - vec2(0.0, 0.15) * trailT * trailT;
      float dist = length(uv - trailPos);

      // Particle glow - increased size for better visibility
      float size = 0.012 * (1.0 - j * 0.12) * (1.0 - fadeT);
      float glow = smoothstep(size, size * 0.15, dist);

      // Color with variation per particle
      float particleHue = hue + hash(seed + i * 3.0) * 0.1;
      vec3 particleCol = hsv2rgb(vec3(particleHue, 0.8, 1.0));

      col += particleCol * glow * (1.0 - j * 0.2) * (1.0 - fadeT * 0.8);
    }
  }

  // Sparkle particles (smaller, random movement)
  for (float i = 0.0; i < NUM_SPARKS; i++) {
    float angle = hash(seed + i * 10.0) * PI * 2.0;
    float speed = 0.1 + hash(seed + i * 11.0) * 0.2;

    vec2 vel = vec2(cos(angle), sin(angle)) * speed;
    // Add some wobble
    vel += vec2(sin(t * 10.0 + i), cos(t * 8.0 + i)) * 0.02;

    vec2 pos = center + vel * explodeT - vec2(0.0, 0.2) * explodeT * explodeT;
    float dist = length(uv - pos);

    // Sparkle
    float sparkle = sin(t * 20.0 + i * 5.0) * 0.5 + 0.5;
    float size = 0.003 * sparkle * (1.0 - fadeT);
    float glow = smoothstep(size, 0.0, dist);

    col += vec3(1.0, 0.95, 0.8) * glow * (1.0 - fadeT);
  }

  // Central flash at explosion moment
  float flash = exp(-t * 8.0) * 0.5;
  float flashDist = length(uv - center);
  col += vec3(1.0, 0.95, 0.9) * flash * smoothstep(0.1, 0.0, flashDist);

  return col;
}

// Rising trail before explosion
vec3 rocketTrail(vec2 uv, vec2 start, vec2 end, float progress) {
  if (progress >= 1.0 || progress <= 0.0) return vec3(0.0);

  vec2 pos = mix(start, end, progress);

  // Trail
  vec3 col = vec3(0.0);
  for (float i = 0.0; i < 10.0; i++) {
    float trailP = progress - i * 0.03;
    if (trailP < 0.0) continue;

    vec2 trailPos = mix(start, end, trailP);
    float dist = length(uv - trailPos);

    float size = 0.01 * (1.0 - i * 0.08);
    col += vec3(1.0, 0.7, 0.3) * smoothstep(size, 0.0, dist) * (1.0 - i * 0.1);
  }

  return col;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float aspect = u_size.x / u_size.y;
  uv.x *= aspect;

  // Apply shake effect
  uv += vec2(sin(u_time * 50.0), cos(u_time * 47.0)) * u_shake * 0.02;

  // Dark sky background with gradient
  vec3 col = mix(vec3(0.02, 0.02, 0.05), vec3(0.05, 0.02, 0.1), uv.y);

  // Stars - brighter and more visible
  for (float i = 0.0; i < 60.0; i++) {
    vec2 starPos = vec2(hash(i * 1.234) * aspect, hash(i * 2.345));
    float twinkle = sin(u_time * (2.0 + hash(i * 3.456) * 3.0) + i) * 0.4 + 0.6;
    float starDist = length(uv - starPos);
    col += vec3(0.9, 0.95, 1.0) * smoothstep(0.004, 0.0, starDist) * twinkle * 0.7;
  }

  // Main triggered explosion
  vec2 explosionCenter = vec2(u_explosion_x * aspect, u_explosion_y);
  float explosionTime = u_trigger * 2.5;

  // Rocket rising phase
  if (explosionTime < 1.0) {
    vec2 start = vec2(explosionCenter.x, 0.0);
    col += rocketTrail(uv, start, explosionCenter, explosionTime);
  }

  // Explosion phase
  float hue = u_hue_shift;
  col += firework(uv, explosionCenter, explosionTime - 1.0, 42.0, hue);

  // Background fireworks (auto-playing) - more frequent and brighter
  float autoTime = u_time * 1.0;  // Faster animation
  for (float i = 0.0; i < 5.0; i++) {  // More fireworks
    float offset = i * 1.8;  // Closer timing
    float cycle = mod(autoTime + offset, 4.0);  // Shorter cycle
    vec2 center = vec2(
      (hash(i * 123.0) * 0.7 + 0.15) * aspect,
      hash(i * 456.0) * 0.35 + 0.45
    );
    float bgHue = mod(u_hue_shift + i * 0.2, 1.0);

    if (cycle < 1.0) {
      col += rocketTrail(uv, vec2(center.x, 0.0), center, cycle) * 0.7;
    }
    col += firework(uv, center, cycle - 1.0, i * 100.0, bgHue) * 0.85;
  }

  // City silhouette at bottom
  float city = 0.0;
  for (float i = 0.0; i < 20.0; i++) {
    float x = i / 20.0 * aspect;
    float h = hash(i * 789.0) * 0.1 + 0.02;
    float w = 0.02 + hash(i * 890.0) * 0.02;

    if (abs(uv.x - x) < w && uv.y < h) {
      city = 1.0;
    }
  }
  col = mix(col, vec3(0.01, 0.01, 0.02), city);

  // Some lit windows
  if (city > 0.5) {
    float windowLight = hash(floor(uv.x * 100.0) + floor(uv.y * 50.0));
    if (windowLight > 0.7) {
      col += vec3(1.0, 0.9, 0.5) * 0.3;
    }
  }

  fragColor = vec4(col, 1.0);
}
