#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform float u_mouse_x;
uniform float u_mouse_y;
uniform float u_reveal;       // 0-1: reveals "Happy New Year" message

// Nerdy Matrix-style rain with hidden message

float hash(float n) { return fract(sin(n) * 43758.5453123); }
float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

// Character set simulation (returns brightness for a "character")
float character(vec2 p, float seed) {
  // Fake character grid
  p = fract(p * vec2(1.0, 2.0));

  // Random pattern based on seed
  float r1 = step(0.5, hash(seed));
  float r2 = step(0.5, hash(seed + 1.0));
  float r3 = step(0.5, hash(seed + 2.0));
  float r4 = step(0.5, hash(seed + 3.0));

  float c = 0.0;
  // Create blocky character patterns
  if (p.x < 0.3) c += r1;
  if (p.x > 0.7) c += r2;
  if (p.y < 0.3) c += r3;
  if (p.y > 0.7) c += r4;

  // Border
  float border = step(0.1, p.x) * step(p.x, 0.9) * step(0.1, p.y) * step(p.y, 0.9);

  return c * border * 0.5;
}

// Simple letter shapes for hidden message
float letterH(vec2 p) {
  p = clamp(p, 0.0, 1.0);
  float l = step(0.9, 1.0 - abs(p.x - 0.2));
  l += step(0.9, 1.0 - abs(p.x - 0.8));
  l += step(0.9, 1.0 - abs(p.y - 0.5)) * step(0.2, p.x) * step(p.x, 0.8);
  return min(l, 1.0);
}

float letterA(vec2 p) {
  p = clamp(p, 0.0, 1.0);
  float l = 0.0;
  // Left diagonal
  l += step(0.85, 1.0 - abs(p.x - p.y * 0.4 - 0.1));
  // Right diagonal
  l += step(0.85, 1.0 - abs(p.x - (1.0 - p.y) * 0.4 - 0.5));
  // Middle bar
  l += step(0.9, 1.0 - abs(p.y - 0.4)) * step(0.3, p.x) * step(p.x, 0.7);
  return min(l, 1.0);
}

float letterP(vec2 p) {
  p = clamp(p, 0.0, 1.0);
  float l = step(0.9, 1.0 - abs(p.x - 0.2));
  // Top curve approximation
  l += step(0.9, 1.0 - abs(p.y - 0.85)) * step(0.2, p.x) * step(p.x, 0.7);
  l += step(0.9, 1.0 - abs(p.y - 0.55)) * step(0.2, p.x) * step(p.x, 0.7);
  l += step(0.9, 1.0 - abs(p.x - 0.7)) * step(0.55, p.y) * step(p.y, 0.85);
  return min(l, 1.0);
}

float letterY(vec2 p) {
  p = clamp(p, 0.0, 1.0);
  float l = 0.0;
  // Upper left diagonal
  if (p.y > 0.5) {
    l += step(0.85, 1.0 - abs(p.x - (1.0 - p.y) + 0.3));
    l += step(0.85, 1.0 - abs(p.x - p.y + 0.3));
  }
  // Stem
  l += step(0.9, 1.0 - abs(p.x - 0.5)) * step(p.y, 0.5);
  return min(l, 1.0);
}

float letterN(vec2 p) {
  p = clamp(p, 0.0, 1.0);
  float l = step(0.9, 1.0 - abs(p.x - 0.2));
  l += step(0.9, 1.0 - abs(p.x - 0.8));
  // Diagonal
  l += step(0.85, 1.0 - abs(p.x - p.y * 0.6 - 0.2));
  return min(l, 1.0);
}

float letterE(vec2 p) {
  p = clamp(p, 0.0, 1.0);
  float l = step(0.9, 1.0 - abs(p.x - 0.2));
  l += step(0.9, 1.0 - abs(p.y - 0.9)) * step(0.2, p.x);
  l += step(0.9, 1.0 - abs(p.y - 0.5)) * step(0.2, p.x) * step(p.x, 0.7);
  l += step(0.9, 1.0 - abs(p.y - 0.1)) * step(0.2, p.x);
  return min(l, 1.0);
}

float letterW(vec2 p) {
  p = clamp(p, 0.0, 1.0);
  float l = 0.0;
  l += step(0.85, 1.0 - abs(p.x - p.y * 0.25 - 0.1));
  l += step(0.85, 1.0 - abs(p.x - (1.0 - p.y) * 0.25 - 0.25));
  l += step(0.85, 1.0 - abs(p.x - p.y * 0.25 - 0.5));
  l += step(0.85, 1.0 - abs(p.x - (1.0 - p.y) * 0.25 - 0.65));
  return min(l, 1.0);
}

float letterR(vec2 p) {
  float l = letterP(p);
  // Add leg
  l += step(0.85, 1.0 - abs(p.x - (0.3 + (1.0 - p.y) * 0.5))) * step(p.y, 0.55);
  return min(l, 1.0);
}

float letter2(vec2 p) {
  p = clamp(p, 0.0, 1.0);
  float l = 0.0;
  l += step(0.9, 1.0 - abs(p.y - 0.9)) * step(0.2, p.x) * step(p.x, 0.8);
  l += step(0.9, 1.0 - abs(p.x - 0.8)) * step(0.6, p.y);
  l += step(0.9, 1.0 - abs(p.y - 0.5)) * step(0.2, p.x) * step(p.x, 0.8);
  l += step(0.9, 1.0 - abs(p.x - 0.2)) * step(p.y, 0.5) * step(0.1, p.y);
  l += step(0.9, 1.0 - abs(p.y - 0.1)) * step(0.2, p.x) * step(p.x, 0.8);
  return min(l, 1.0);
}

float letter0(vec2 p) {
  p = clamp(p, 0.0, 1.0);
  float l = 0.0;
  l += step(0.9, 1.0 - abs(p.x - 0.2)) * step(0.2, p.y) * step(p.y, 0.8);
  l += step(0.9, 1.0 - abs(p.x - 0.8)) * step(0.2, p.y) * step(p.y, 0.8);
  l += step(0.9, 1.0 - abs(p.y - 0.9)) * step(0.2, p.x) * step(p.x, 0.8);
  l += step(0.9, 1.0 - abs(p.y - 0.1)) * step(0.2, p.x) * step(p.x, 0.8);
  return min(l, 1.0);
}

float letter5(vec2 p) {
  p = clamp(p, 0.0, 1.0);
  float l = 0.0;
  l += step(0.9, 1.0 - abs(p.y - 0.9)) * step(0.2, p.x);
  l += step(0.9, 1.0 - abs(p.x - 0.2)) * step(0.5, p.y);
  l += step(0.9, 1.0 - abs(p.y - 0.5)) * step(0.2, p.x) * step(p.x, 0.8);
  l += step(0.9, 1.0 - abs(p.x - 0.8)) * step(p.y, 0.5) * step(0.1, p.y);
  l += step(0.9, 1.0 - abs(p.y - 0.1)) * step(0.2, p.x) * step(p.x, 0.8);
  return min(l, 1.0);
}

float letter6(vec2 p) {
  p = clamp(p, 0.0, 1.0);
  float l = 0.0;
  // Top horizontal
  l += step(0.9, 1.0 - abs(p.y - 0.9)) * step(0.2, p.x) * step(p.x, 0.8);
  // Left vertical (full height)
  l += step(0.9, 1.0 - abs(p.x - 0.2)) * step(0.1, p.y) * step(p.y, 0.9);
  // Middle horizontal
  l += step(0.9, 1.0 - abs(p.y - 0.5)) * step(0.2, p.x) * step(p.x, 0.8);
  // Bottom horizontal
  l += step(0.9, 1.0 - abs(p.y - 0.1)) * step(0.2, p.x) * step(p.x, 0.8);
  // Right vertical (bottom half only)
  l += step(0.9, 1.0 - abs(p.x - 0.8)) * step(0.1, p.y) * step(p.y, 0.5);
  return min(l, 1.0);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float aspect = u_size.x / u_size.y;

  // Grid for matrix characters
  float cols = 40.0;
  float rows = cols / aspect;

  vec2 grid = vec2(cols, rows);
  vec2 cell = floor(uv * grid);
  vec2 cellUV = fract(uv * grid);

  float t = u_time;

  // Each column has different speed and offset
  float colSeed = hash(cell.x * 123.456);
  float speed = 1.0 + colSeed * 2.0;
  float offset = colSeed * 100.0;

  // Character position scrolls down
  float charPos = cell.y + t * speed * 5.0 + offset;
  float charSeed = hash(floor(charPos) * 789.0 + cell.x * 456.0);

  // Character changes over time
  float charChange = floor(t * 10.0 + charSeed * 10.0);
  float char = character(cellUV, charSeed + charChange);

  // Trail fade
  float headPos = mod(t * speed * 5.0 + offset, rows * 2.0);
  float distFromHead = mod(headPos - cell.y, rows * 2.0);
  float trail = exp(-distFromHead * 0.15);

  // Bright head
  float head = smoothstep(2.0, 0.0, distFromHead);

  // Dark background base
  vec3 bgDark = vec3(0.0, 0.02, 0.0);

  // Base color (green matrix)
  vec3 green = vec3(0.0, 0.9, 0.3);
  vec3 white = vec3(0.7, 1.0, 0.7);

  // Calculate matrix effect brightness
  float brightness = trail * 0.6 + char * 0.4 + head * 0.5;
  vec3 matrixColor = mix(green, white, head);

  // Combine dark background with matrix rain
  vec3 col = bgDark + matrixColor * brightness;

  // Mouse creates a "decode" ripple
  vec2 mousePos = vec2(u_mouse_x, u_mouse_y);
  float mouseDist = length(uv - mousePos);
  float mouseEffect = smoothstep(0.3, 0.0, mouseDist);
  col += vec3(0.2, 0.5, 0.3) * mouseEffect * 0.3;

  // Hidden message reveal
  if (u_reveal > 0.01) {
    vec2 msgUV = (uv - vec2(0.5, 0.5)) * vec2(aspect, 1.0);
    msgUV = msgUV * 3.0 + vec2(2.5, 0.5);

    // "HAPPY 2026" letters
    float msg = 0.0;
    // H
    msg += letterH((msgUV - vec2(0.0, 0.0)) * 2.0);
    // A
    msg += letterA((msgUV - vec2(0.6, 0.0)) * 2.0);
    // P
    msg += letterP((msgUV - vec2(1.2, 0.0)) * 2.0);
    // P
    msg += letterP((msgUV - vec2(1.8, 0.0)) * 2.0);
    // Y
    msg += letterY((msgUV - vec2(2.4, 0.0)) * 2.0);
    // 2
    msg += letter2((msgUV - vec2(3.2, 0.0)) * 2.0);
    // 0
    msg += letter0((msgUV - vec2(3.8, 0.0)) * 2.0);
    // 2
    msg += letter2((msgUV - vec2(4.4, 0.0)) * 2.0);
    // 6
    msg += letter6((msgUV - vec2(5.0, 0.0)) * 2.0);

    // Bright green/gold color for message (more Matrix-style)
    vec3 brightGreen = vec3(0.4, 1.0, 0.4);
    vec3 gold = vec3(1.0, 0.95, 0.5);
    vec3 msgColor = mix(brightGreen, gold, 0.5);
    float msgMask = min(msg, 1.0) * u_reveal;

    // Glitch effect on reveal
    float glitch = hash2(floor(uv * 50.0) + floor(t * 20.0)) * step(0.95, hash(t * 100.0));

    // Add message as bright overlay on existing matrix, don't fully replace
    col += msgColor * msgMask * (1.0 + glitch * 0.5);

    // Subtle glow around message
    col += msgColor * 0.15 * msgMask * (1.0 + sin(t * 10.0) * 0.2);
  }

  // Scanlines
  float scanline = sin(uv.y * u_size.y * 0.5) * 0.1;
  col *= 1.0 - scanline * 0.3;

  // Vignette
  float vignette = 1.0 - pow(length(uv - 0.5) * 1.3, 2.0);
  col *= max(vignette, 0.4);

  fragColor = vec4(col, 1.0);
}
