#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform float u_intensity;    // 0-1
uniform float u_transition;   // Fade in/out (0-1)
uniform float u_pulse_speed;  // Pulse speed (0.5-2.0)
uniform float u_darkness;     // Darkness level (0-1)

#define PI 3.14159265359

// Hash function
float hash(float n) {
  return fract(sin(n) * 43758.5453123);
}

float hash2(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Smooth noise
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

// Fractal noise
float fbm(vec2 p) {
  float f = 0.0;
  float w = 0.5;
  for (int i = 0; i < 4; i++) {
    f += w * noise(p);
    p *= 2.0;
    w *= 0.5;
  }
  return f;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float aspect = u_size.x / u_size.y;
  uv.x *= aspect;

  vec2 center = vec2(aspect * 0.5, 0.5);

  // Base dark colors
  vec3 darkColor = vec3(0.03, 0.03, 0.05);
  vec3 midColor = vec3(0.08, 0.06, 0.1);

  // Pulsing effect
  float pulse = sin(u_time * u_pulse_speed * 2.0) * 0.5 + 0.5;
  pulse = pow(pulse, 2.0); // Sharper pulse

  // Distance from center
  float dist = length(uv - center);
  float maxDist = length(vec2(aspect * 0.5, 0.5));

  // Radial gradient with pulse
  float radialGradient = dist / maxDist;
  radialGradient = pow(radialGradient, 1.5);

  // Base color - dark center, slightly lighter edges
  vec3 col = mix(midColor, darkColor, radialGradient);

  // Pulsing ring effect
  float ringRadius = 0.3 + pulse * 0.2;
  float ringDist = abs(dist - ringRadius);
  float ring = smoothstep(0.1, 0.0, ringDist);

  // Subtle red/amber warning pulse
  vec3 pulseColor = mix(vec3(0.3, 0.05, 0.05), vec3(0.4, 0.2, 0.0), pulse);
  col += pulseColor * ring * 0.3 * u_intensity;

  // Animated noise overlay (unsettling movement)
  vec2 noiseUV = uv * 3.0 + u_time * 0.1;
  float movement = fbm(noiseUV);
  movement = smoothstep(0.3, 0.7, movement);

  // Dark patches that slowly move
  col = mix(col, darkColor * 0.5, movement * 0.3 * u_darkness);

  // Subtle scan lines (tension/surveillance feel)
  float scanLine = sin(uv.y * 200.0 + u_time * 5.0) * 0.5 + 0.5;
  scanLine = pow(scanLine, 8.0);
  col += vec3(0.02) * scanLine * u_intensity;

  // Occasional flicker
  float flicker = hash(floor(u_time * 10.0));
  if (flicker > 0.95) {
    col *= 0.9;
  }

  // Edge glow (warning indicator)
  float edgeDist = min(min(uv.x, aspect - uv.x), min(uv.y, 1.0 - uv.y));
  float edgeGlow = smoothstep(0.1, 0.0, edgeDist);
  edgeGlow *= sin(u_time * 3.0 + uv.x * 10.0 + uv.y * 10.0) * 0.5 + 0.5;
  col += vec3(0.2, 0.05, 0.0) * edgeGlow * 0.3 * u_intensity;

  // Subtle particles floating in darkness
  for (float i = 0.0; i < 15.0; i++) {
    float seed = i * 0.567;
    vec2 particlePos = vec2(
      hash(seed) * aspect + sin(u_time * 0.3 + seed * 3.0) * 0.1,
      hash(seed + 1.0) + cos(u_time * 0.2 + seed * 2.0) * 0.05
    );

    float particleDist = length(uv - particlePos);
    float particle = smoothstep(0.01, 0.0, particleDist);

    // Dim, unsettling particles
    float particleAlpha = sin(u_time * 2.0 + seed * 5.0) * 0.3 + 0.5;
    col += vec3(0.15, 0.1, 0.12) * particle * particleAlpha * u_intensity;
  }

  // Heavy vignette for claustrophobic feel
  vec2 vigUV = (uv / vec2(aspect, 1.0)) - vec2(0.5);
  float vig = 1.0 - dot(vigUV, vigUV) * (1.0 + u_darkness);
  vig = clamp(vig, 0.0, 1.0);
  col *= vig;

  // Overall darkness adjustment
  col *= (1.0 - u_darkness * 0.3);

  // Apply transition
  col *= u_transition;

  fragColor = vec4(col, 1.0);
}
