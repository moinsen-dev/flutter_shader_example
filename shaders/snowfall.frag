#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform float u_intensity;    // Snow density (0.5 - 2.0)
uniform float u_wind;         // Wind effect (-1.0 to 1.0)
uniform float u_mouse_x;      // Mouse X normalized (0-1)
uniform float u_mouse_y;      // Mouse Y normalized (0-1)

// Hash functions for randomness
float hash(float n) {
  return fract(sin(n) * 43758.5453123);
}

float hash2(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Snowflake layer
float snowLayer(vec2 uv, float scale, float speed, float t) {
  float w = 0.4;
  uv *= scale;

  // Add some horizontal drift
  uv.x += sin(uv.y * 0.5 + t * 0.5) * 0.3 + u_wind * t * 0.5;

  // Scroll down
  uv.y += t * speed;

  // Grid cells
  vec2 id = floor(uv);
  vec2 f = fract(uv);

  float flake = 0.0;

  // Check neighboring cells for smooth edges
  for (int i = -1; i <= 1; i++) {
    for (int j = -1; j <= 1; j++) {
      vec2 neighbor = vec2(float(i), float(j));
      vec2 cellId = id + neighbor;

      // Random position within cell
      float rnd = hash2(cellId);
      vec2 offset = vec2(hash(rnd * 100.0), hash(rnd * 200.0)) * 0.8 + 0.1;

      // Distance to snowflake center
      vec2 diff = neighbor + offset - f;
      float dist = length(diff);

      // Snowflake size varies
      float size = 0.03 + hash(rnd * 300.0) * 0.04;

      // Sparkle effect
      float sparkle = sin(t * 3.0 + rnd * 6.28) * 0.3 + 0.7;

      // Draw flake
      flake += smoothstep(size, size * 0.3, dist) * sparkle;
    }
  }

  return flake;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float aspect = u_size.x / u_size.y;
  uv.x *= aspect;

  float t = u_time;

  // Background gradient (night sky)
  vec3 bgTop = vec3(0.02, 0.05, 0.15);
  vec3 bgBottom = vec3(0.1, 0.15, 0.25);
  vec3 color = mix(bgBottom, bgTop, uv.y / aspect);

  // Add subtle aurora hint at top
  float aurora = sin(uv.x * 3.0 + t * 0.3) * 0.5 + 0.5;
  aurora *= smoothstep(0.7, 1.0, uv.y / aspect);
  color += vec3(0.0, 0.1, 0.15) * aurora * 0.3;

  // Multiple snow layers for depth
  float snow = 0.0;
  snow += snowLayer(uv, 8.0 * u_intensity, 0.3, t) * 0.5;   // Far, slow, dim
  snow += snowLayer(uv + 0.5, 12.0 * u_intensity, 0.5, t) * 0.7;  // Mid
  snow += snowLayer(uv + 0.3, 20.0 * u_intensity, 0.8, t) * 1.0;  // Close, fast, bright

  // Add snow to color
  color += vec3(0.9, 0.95, 1.0) * snow;

  // Mouse interaction - warm glow where cursor is
  vec2 mousePos = vec2(u_mouse_x * aspect, u_mouse_y);
  float mouseDist = length(uv - mousePos);
  float mouseGlow = smoothstep(0.3, 0.0, mouseDist);
  color += vec3(1.0, 0.8, 0.4) * mouseGlow * 0.15;

  // Ground snow accumulation
  float ground = smoothstep(0.15, 0.1, uv.y / aspect);
  ground += smoothstep(0.2, 0.15, uv.y / aspect) * (sin(uv.x * 20.0) * 0.02 + 0.5);
  color = mix(color, vec3(0.85, 0.9, 0.95), ground * 0.8);

  fragColor = vec4(color, 1.0);
}
