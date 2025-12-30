#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform float u_intensity;     // 0-1
uniform float u_transition;    // Fade in/out (0-1)
uniform float u_rain_density;  // Rain density (0-1)

#define PI 3.14159265359

// Hash functions
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

// Rain drop (streak)
float rainDrop(vec2 uv, vec2 start, float dropLen, float dropWidth) {
  vec2 end = start - vec2(0.02, dropLen); // Slight angle

  // Line segment distance
  vec2 pa = uv - start;
  vec2 ba = end - start;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  float dist = length(pa - ba * h);

  return smoothstep(dropWidth, 0.0, dist);
}

// Ripple on water surface
float ripple(vec2 uv, vec2 center, float time, float maxRadius) {
  float dist = length(uv - center);
  float radius = mod(time, 2.0) * maxRadius;

  float rippleWidth = 0.02;
  float rippleEdge = smoothstep(radius - rippleWidth, radius, dist)
                   - smoothstep(radius, radius + rippleWidth, dist);

  // Fade out as ripple expands
  float fade = 1.0 - radius / maxRadius;

  return rippleEdge * fade * fade;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float aspect = u_size.x / u_size.y;
  uv.x *= aspect;

  // Dark, stormy sky
  vec3 skyTop = vec3(0.08, 0.1, 0.15);     // Dark blue-gray
  vec3 skyBottom = vec3(0.15, 0.18, 0.22); // Lighter gray
  vec3 col = mix(skyBottom, skyTop, uv.y);

  // Storm clouds (noise-based)
  float cloudNoise = noise(vec2(uv.x * 2.0 + u_time * 0.05, uv.y * 1.5));
  cloudNoise += noise(vec2(uv.x * 4.0 - u_time * 0.03, uv.y * 3.0)) * 0.5;
  cloudNoise = smoothstep(0.4, 0.8, cloudNoise);

  vec3 cloudCol = vec3(0.2, 0.22, 0.25);
  col = mix(col, cloudCol, cloudNoise * 0.5 * (1.0 - uv.y * 0.5));

  // Occasional lightning flash
  float lightning = 0.0;
  float flashTime = mod(u_time, 8.0);
  if (flashTime < 0.1 || (flashTime > 3.0 && flashTime < 3.08)) {
    lightning = 1.0;
  }
  col += vec3(0.4, 0.45, 0.5) * lightning * u_intensity * 0.3;

  // Water surface at bottom
  float waterLevel = 0.25;
  if (uv.y < waterLevel) {
    // Dark water
    vec3 waterCol = vec3(0.05, 0.08, 0.12);

    // Reflection of sky (dimmed)
    vec2 reflectUV = vec2(uv.x, waterLevel - (uv.y));
    float reflectNoise = noise(reflectUV * 3.0 + u_time * 0.2);
    waterCol += col * 0.15 * reflectNoise;

    // Ripples from raindrops
    for (float i = 0.0; i < 15.0; i++) {
      float seed = i * 1.234;
      vec2 rippleCenter = vec2(
        hash(seed) * aspect,
        hash(seed + 1.0) * waterLevel * 0.8
      );

      float rippleTime = mod(u_time * 0.8 + hash(seed + 2.0) * 5.0, 2.0);
      float rip = ripple(uv, rippleCenter, rippleTime, 0.1);

      waterCol += vec3(0.15, 0.18, 0.22) * rip * u_intensity;
    }

    col = waterCol;
  }

  // Rain drops (vertical streaks) - Layer 0 (foreground, slow)
  for (float i = 0.0; i < 30.0; i++) {
    float seed = i * 0.456;
    float xPos = hash(seed) * aspect;
    float speed = 1.5 + hash(seed + 1.0) * 0.5;
    float t = mod(u_time * speed + hash(seed + 2.0) * 10.0, 2.0);
    float yPos = 1.2 - t * 0.8;

    if (yPos > waterLevel) {
      float dropLength = 0.03 + hash(seed + 3.0) * 0.02;
      float drop = rainDrop(uv, vec2(xPos, yPos), dropLength, 0.001);
      col += vec3(0.5, 0.55, 0.65) * drop * 0.4 * u_rain_density * u_intensity;
    }
  }

  // Layer 1 (mid, medium speed)
  for (float i = 0.0; i < 50.0; i++) {
    float seed = i * 0.456 + 100.0;
    float xPos = hash(seed) * aspect;
    float speed = 2.0 + hash(seed + 1.0) * 0.5;
    float t = mod(u_time * speed + hash(seed + 2.0) * 10.0, 2.0);
    float yPos = 1.2 - t * 0.8;

    if (yPos > waterLevel) {
      float dropLength = 0.03 + hash(seed + 3.0) * 0.02;
      float drop = rainDrop(uv, vec2(xPos, yPos), dropLength, 0.0015);
      col += vec3(0.5, 0.55, 0.65) * drop * 0.3 * u_rain_density * u_intensity;
    }
  }

  // Layer 2 (background, fast)
  for (float i = 0.0; i < 70.0; i++) {
    float seed = i * 0.456 + 200.0;
    float xPos = hash(seed) * aspect;
    float speed = 2.5 + hash(seed + 1.0) * 0.5;
    float t = mod(u_time * speed + hash(seed + 2.0) * 10.0, 2.0);
    float yPos = 1.2 - t * 0.8;

    if (yPos > waterLevel) {
      float dropLength = 0.03 + hash(seed + 3.0) * 0.02;
      float drop = rainDrop(uv, vec2(xPos, yPos), dropLength, 0.002);
      col += vec3(0.5, 0.55, 0.65) * drop * 0.2 * u_rain_density * u_intensity;
    }
  }

  // Splashes at water level
  for (float i = 0.0; i < 20.0; i++) {
    float seed = i * 0.789;
    float splashX = hash(seed) * aspect;
    float splashTime = mod(u_time * 2.0 + hash(seed + 1.0) * 5.0, 1.0);

    if (splashTime < 0.3) {
      vec2 splashPos = vec2(splashX, waterLevel);
      float splashHeight = (0.3 - splashTime) * 0.05;

      // Tiny droplets splashing up
      for (float j = 0.0; j < 3.0; j++) {
        float angle = (j / 3.0 - 0.5) * PI * 0.6;
        vec2 dropletPos = splashPos + vec2(cos(angle), sin(angle)) * splashHeight * (1.0 - splashTime);

        float dist = length(uv - dropletPos);
        float glow = smoothstep(0.003, 0.0, dist);
        col += vec3(0.6, 0.65, 0.7) * glow * (1.0 - splashTime * 3.0) * u_intensity;
      }
    }
  }

  // Fog/mist near water
  float mist = smoothstep(0.1, 0.4, uv.y) * smoothstep(0.5, 0.2, uv.y);
  col = mix(col, vec3(0.25, 0.28, 0.32), mist * 0.2);

  // Vignette - darker for somber mood
  vec2 vigUV = (uv / vec2(aspect, 1.0)) - vec2(0.5);
  float vig = 1.0 - dot(vigUV, vigUV) * 0.8;
  col *= vig;

  // Overall dark, melancholic tone
  col *= 0.85;

  // Apply transition
  col *= u_transition;

  fragColor = vec4(col, 1.0);
}
