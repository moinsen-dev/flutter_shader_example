#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform float u_glitch;       // Glitch intensity (0-1)
uniform float u_neon_pulse;   // Neon brightness pulse (0-1)

#define PI 3.14159265359

float hash(float n) { return fract(sin(n) * 43758.5453123); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

// Noise function for effects
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

// Glitch displacement
vec2 glitchOffset(vec2 uv, float t, float intensity) {
  float glitchLine = step(0.99, hash(floor(uv.y * 50.0) + floor(t * 20.0)));
  float offset = (hash(floor(t * 30.0) + floor(uv.y * 30.0)) - 0.5) * 0.1 * intensity * glitchLine;
  return vec2(offset, 0.0);
}

// Neon glow effect
vec3 neonGlow(float d, vec3 color, float intensity) {
  float glow = exp(-d * 8.0) * intensity;
  float core = smoothstep(0.02, 0.0, d);
  return color * glow + vec3(1.0) * core * 0.5;
}

// Letter rendering functions using distance fields
float segmentH(vec2 p, vec2 a, vec2 b, float w) {
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h) - w;
}

// Seven-segment style letters
float letterH_cyber(vec2 p) {
  float d = 1.0;
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.0, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.5, 0.0), vec2(0.5, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 0.5), vec2(0.5, 0.5), 0.06));
  return d;
}

float letterA_cyber(vec2 p) {
  float d = 1.0;
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.25, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.5, 0.0), vec2(0.25, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.1, 0.4), vec2(0.4, 0.4), 0.06));
  return d;
}

float letterP_cyber(vec2 p) {
  float d = 1.0;
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.0, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 1.0), vec2(0.4, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.4, 1.0), vec2(0.4, 0.5), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 0.5), vec2(0.4, 0.5), 0.06));
  return d;
}

float letterY_cyber(vec2 p) {
  float d = 1.0;
  d = min(d, segmentH(p, vec2(0.0, 1.0), vec2(0.25, 0.5), 0.06));
  d = min(d, segmentH(p, vec2(0.5, 1.0), vec2(0.25, 0.5), 0.06));
  d = min(d, segmentH(p, vec2(0.25, 0.5), vec2(0.25, 0.0), 0.06));
  return d;
}

float letterC_cyber(vec2 p) {
  float d = 1.0;
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.0, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 1.0), vec2(0.4, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.4, 0.0), 0.06));
  return d;
}

float letterO_cyber(vec2 p) {
  float d = 1.0;
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.0, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.4, 0.0), vec2(0.4, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 1.0), vec2(0.4, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.4, 0.0), 0.06));
  return d;
}

float letterD_cyber(vec2 p) {
  float d = 1.0;
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.0, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 1.0), vec2(0.3, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.3, 1.0), vec2(0.4, 0.8), 0.06));
  d = min(d, segmentH(p, vec2(0.4, 0.8), vec2(0.4, 0.2), 0.06));
  d = min(d, segmentH(p, vec2(0.4, 0.2), vec2(0.3, 0.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.3, 0.0), 0.06));
  return d;
}

float letterI_cyber(vec2 p) {
  float d = 1.0;
  d = min(d, segmentH(p, vec2(0.2, 0.0), vec2(0.2, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 1.0), vec2(0.4, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.4, 0.0), 0.06));
  return d;
}

float letterN_cyber(vec2 p) {
  float d = 1.0;
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.0, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.5, 0.0), vec2(0.5, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 1.0), vec2(0.5, 0.0), 0.06));
  return d;
}

float letterG_cyber(vec2 p) {
  float d = 1.0;
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.0, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 1.0), vec2(0.4, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.4, 0.0), 0.06));
  d = min(d, segmentH(p, vec2(0.4, 0.0), vec2(0.4, 0.5), 0.06));
  d = min(d, segmentH(p, vec2(0.2, 0.5), vec2(0.4, 0.5), 0.06));
  return d;
}

float digit2_cyber(vec2 p) {
  float d = 1.0;
  d = min(d, segmentH(p, vec2(0.0, 1.0), vec2(0.4, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.4, 1.0), vec2(0.4, 0.5), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 0.5), vec2(0.4, 0.5), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 0.5), vec2(0.0, 0.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.4, 0.0), 0.06));
  return d;
}

float digit0_cyber(vec2 p) {
  return letterO_cyber(p);
}

float digit6_cyber(vec2 p) {
  float d = 1.0;
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.0, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 1.0), vec2(0.4, 1.0), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 0.5), vec2(0.4, 0.5), 0.06));
  d = min(d, segmentH(p, vec2(0.0, 0.0), vec2(0.4, 0.0), 0.06));
  d = min(d, segmentH(p, vec2(0.4, 0.0), vec2(0.4, 0.5), 0.06));
  return d;
}

// Binary rain effect
float binaryRain(vec2 uv, float t) {
  float cols = 30.0;
  vec2 cell = floor(uv * vec2(cols, cols * 2.0));
  float speed = hash(cell.x * 123.456) * 2.0 + 1.0;
  float offset = hash(cell.x * 789.012) * 100.0;
  float scroll = mod(uv.y + t * speed * 0.5 + offset, 1.0);
  float binary = step(0.5, hash(cell.x * 111.0 + floor((uv.y + t * speed * 0.5 + offset) * cols * 2.0)));
  float fade = smoothstep(0.0, 0.3, scroll) * smoothstep(1.0, 0.7, scroll);
  return binary * fade * 0.3;
}

// Grid lines
float grid(vec2 uv, float spacing) {
  vec2 g = abs(fract(uv * spacing) - 0.5);
  return smoothstep(0.48, 0.5, max(g.x, g.y)) * 0.2;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float aspect = u_size.x / u_size.y;

  float t = u_time;

  // Apply glitch displacement
  vec2 glitchedUV = uv + glitchOffset(uv, t, u_glitch);

  // Dark cyberpunk background with grid
  vec3 bgColor = vec3(0.02, 0.02, 0.05);
  bgColor += vec3(0.0, 0.02, 0.04) * grid(uv * vec2(aspect, 1.0), 20.0);

  // Binary rain in background
  float rain = binaryRain(vec2(uv.x * aspect, uv.y), t);
  bgColor += vec3(0.0, 0.3, 0.2) * rain;

  // Horizontal scan line moving
  float scanY = mod(t * 0.3, 1.2) - 0.1;
  float scanLine = smoothstep(0.02, 0.0, abs(uv.y - scanY)) * 0.3;
  bgColor += vec3(0.0, 0.5, 0.5) * scanLine;

  vec3 col = bgColor;

  // === HAPPY text (top line) ===
  vec2 happyBase = vec2(aspect * 0.5 - 0.9, 0.7);
  float happyScale = 3.5;

  float dH = letterH_cyber((glitchedUV - happyBase) * happyScale);
  float dA1 = letterA_cyber((glitchedUV - happyBase - vec2(0.18, 0.0)) * happyScale);
  float dP1 = letterP_cyber((glitchedUV - happyBase - vec2(0.36, 0.0)) * happyScale);
  float dP2 = letterP_cyber((glitchedUV - happyBase - vec2(0.50, 0.0)) * happyScale);
  float dY = letterY_cyber((glitchedUV - happyBase - vec2(0.64, 0.0)) * happyScale);

  float happyDist = min(min(min(min(dH, dA1), dP1), dP2), dY);

  // Magenta neon for HAPPY
  vec3 magenta = vec3(1.0, 0.0, 0.6);
  float pulse1 = 0.7 + 0.3 * sin(t * 3.0) * u_neon_pulse;
  col += neonGlow(happyDist, magenta, pulse1);

  // === CODING text (middle line) ===
  vec2 codingBase = vec2(aspect * 0.5 - 1.1, 0.48);
  float codingScale = 3.5;

  float dC = letterC_cyber((glitchedUV - codingBase) * codingScale);
  float dO1 = letterO_cyber((glitchedUV - codingBase - vec2(0.15, 0.0)) * codingScale);
  float dD = letterD_cyber((glitchedUV - codingBase - vec2(0.30, 0.0)) * codingScale);
  float dI = letterI_cyber((glitchedUV - codingBase - vec2(0.45, 0.0)) * codingScale);
  float dN = letterN_cyber((glitchedUV - codingBase - vec2(0.58, 0.0)) * codingScale);
  float dG = letterG_cyber((glitchedUV - codingBase - vec2(0.76, 0.0)) * codingScale);

  float codingDist = min(min(min(min(min(dC, dO1), dD), dI), dN), dG);

  // Cyan neon for CODING
  vec3 cyan = vec3(0.0, 0.9, 1.0);
  float pulse2 = 0.7 + 0.3 * sin(t * 3.0 + 1.0) * u_neon_pulse;
  col += neonGlow(codingDist, cyan, pulse2);

  // === 2026 text (bottom line) ===
  vec2 yearBase = vec2(aspect * 0.5 - 0.55, 0.25);
  float yearScale = 4.0;

  float d2a = digit2_cyber((glitchedUV - yearBase) * yearScale);
  float d0 = digit0_cyber((glitchedUV - yearBase - vec2(0.14, 0.0)) * yearScale);
  float d2b = digit2_cyber((glitchedUV - yearBase - vec2(0.28, 0.0)) * yearScale);
  float d6 = digit6_cyber((glitchedUV - yearBase - vec2(0.42, 0.0)) * yearScale);

  float yearDist = min(min(min(d2a, d0), d2b), d6);

  // Yellow/gold neon for 2026
  vec3 yellow = vec3(1.0, 0.9, 0.0);
  float pulse3 = 0.7 + 0.3 * sin(t * 3.0 + 2.0) * u_neon_pulse;
  col += neonGlow(yearDist, yellow, pulse3);

  // Chromatic aberration on glitch
  if (u_glitch > 0.1) {
    vec2 aberration = vec2(0.003, 0.0) * u_glitch;
    float rShift = min(min(min(
      letterH_cyber((glitchedUV + aberration - happyBase) * happyScale),
      letterC_cyber((glitchedUV + aberration - codingBase) * codingScale)),
      digit2_cyber((glitchedUV + aberration - yearBase) * yearScale)),
      1.0);
    col.r += smoothstep(0.1, 0.0, rShift) * 0.3 * u_glitch;
  }

  // CRT scanlines
  float scanlines = sin(uv.y * u_size.y * 1.5) * 0.04;
  col *= 1.0 - scanlines;

  // Vignette
  float vignette = 1.0 - pow(length((uv - 0.5) * vec2(aspect, 1.0)) * 0.8, 2.0);
  col *= max(vignette, 0.3);

  // Random glitch blocks
  if (u_glitch > 0.3) {
    float blockNoise = step(0.97, hash2(floor(uv * 20.0) + floor(t * 15.0)));
    col = mix(col, vec3(0.0, 1.0, 0.8), blockNoise * u_glitch * 0.5);
  }

  // Flicker effect
  float flicker = 1.0 - step(0.995, hash(floor(t * 60.0))) * 0.3 * u_glitch;
  col *= flicker;

  fragColor = vec4(col, 1.0);
}
