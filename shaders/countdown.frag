#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform float u_countdown;    // 10.0 to 0.0
uniform float u_glow;         // Intensity pulse (0-1)
uniform float u_mouse_x;
uniform float u_mouse_y;

#define PI 3.14159265359

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 7-segment digit rendering
float segment(vec2 p, vec2 a, vec2 b, float w) {
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  float d = length(pa - ba * h);
  return smoothstep(w, w * 0.5, d);
}

// Draw a single digit
float digit(vec2 p, int n, float size) {
  // Scale and center the coordinate
  p = p / size + vec2(0.5, 0.5);

  // Check if we're inside the digit bounds
  if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0) return 0.0;

  float w = 0.1;
  float s = 0.0;

  // Segment positions (7-segment display layout)
  //  _a_
  // |   |
  // f   b
  // |_g_|
  // |   |
  // e   c
  // |_d_|

  vec2 a1 = vec2(0.15, 0.85), a2 = vec2(0.85, 0.85);  // top
  vec2 b1 = vec2(0.85, 0.85), b2 = vec2(0.85, 0.55);  // top-right
  vec2 c1 = vec2(0.85, 0.45), c2 = vec2(0.85, 0.15);  // bottom-right
  vec2 d1 = vec2(0.15, 0.15), d2 = vec2(0.85, 0.15);  // bottom
  vec2 e1 = vec2(0.15, 0.15), e2 = vec2(0.15, 0.45);  // bottom-left
  vec2 f1 = vec2(0.15, 0.55), f2 = vec2(0.15, 0.85);  // top-left
  vec2 g1 = vec2(0.15, 0.5), g2 = vec2(0.85, 0.5);    // middle

  // Digit patterns: 0-9
  //          a  b  c  d  e  f  g
  // 0:       1  1  1  1  1  1  0
  // 1:       0  1  1  0  0  0  0
  // 2:       1  1  0  1  1  0  1
  // 3:       1  1  1  1  0  0  1
  // 4:       0  1  1  0  0  1  1
  // 5:       1  0  1  1  0  1  1
  // 6:       1  0  1  1  1  1  1
  // 7:       1  1  1  0  0  0  0
  // 8:       1  1  1  1  1  1  1
  // 9:       1  1  1  1  0  1  1

  if (n == 0) { s += segment(p,a1,a2,w) + segment(p,b1,b2,w) + segment(p,c1,c2,w) + segment(p,d1,d2,w) + segment(p,e1,e2,w) + segment(p,f1,f2,w); }
  if (n == 1) { s += segment(p,b1,b2,w) + segment(p,c1,c2,w); }
  if (n == 2) { s += segment(p,a1,a2,w) + segment(p,b1,b2,w) + segment(p,g1,g2,w) + segment(p,e1,e2,w) + segment(p,d1,d2,w); }
  if (n == 3) { s += segment(p,a1,a2,w) + segment(p,b1,b2,w) + segment(p,g1,g2,w) + segment(p,c1,c2,w) + segment(p,d1,d2,w); }
  if (n == 4) { s += segment(p,f1,f2,w) + segment(p,g1,g2,w) + segment(p,b1,b2,w) + segment(p,c1,c2,w); }
  if (n == 5) { s += segment(p,a1,a2,w) + segment(p,f1,f2,w) + segment(p,g1,g2,w) + segment(p,c1,c2,w) + segment(p,d1,d2,w); }
  if (n == 6) { s += segment(p,a1,a2,w) + segment(p,f1,f2,w) + segment(p,g1,g2,w) + segment(p,c1,c2,w) + segment(p,d1,d2,w) + segment(p,e1,e2,w); }
  if (n == 7) { s += segment(p,a1,a2,w) + segment(p,b1,b2,w) + segment(p,c1,c2,w); }
  if (n == 8) { s += segment(p,a1,a2,w) + segment(p,b1,b2,w) + segment(p,c1,c2,w) + segment(p,d1,d2,w) + segment(p,e1,e2,w) + segment(p,f1,f2,w) + segment(p,g1,g2,w); }
  if (n == 9) { s += segment(p,a1,a2,w) + segment(p,b1,b2,w) + segment(p,c1,c2,w) + segment(p,d1,d2,w) + segment(p,f1,f2,w) + segment(p,g1,g2,w); }

  return clamp(s, 0.0, 1.0);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  float aspect = u_size.x / u_size.y;

  // Center coordinates
  vec2 p = (uv - 0.5) * vec2(aspect, 1.0);

  // Animated background - swirling energy
  float bgAngle = atan(p.y, p.x);
  float bgDist = length(p);
  float swirl = sin(bgAngle * 3.0 + u_time * 2.0 + bgDist * 5.0) * 0.5 + 0.5;

  // Color based on countdown urgency
  float urgency = 1.0 - u_countdown / 10.0;
  vec3 bgColor1 = mix(vec3(0.05, 0.1, 0.2), vec3(0.2, 0.05, 0.1), urgency);
  vec3 bgColor2 = mix(vec3(0.1, 0.15, 0.3), vec3(0.3, 0.1, 0.15), urgency);

  vec3 col = mix(bgColor1, bgColor2, swirl * 0.5 + 0.25);

  // Energy rings
  float ring1 = abs(bgDist - 0.4 - sin(u_time * 2.0) * 0.05);
  float ring2 = abs(bgDist - 0.5 - sin(u_time * 2.5 + 1.0) * 0.05);
  col += vec3(0.3, 0.5, 1.0) * smoothstep(0.02, 0.0, ring1) * (1.0 + u_glow);
  col += vec3(1.0, 0.3, 0.5) * smoothstep(0.02, 0.0, ring2) * urgency * (1.0 + u_glow);

  // Countdown number
  int number = int(ceil(u_countdown));
  if (number < 0) number = 0;
  if (number > 10) number = 10;

  // Size pulsing with countdown
  float pulse = 1.0 + sin(u_time * 10.0) * 0.05 * (1.0 + urgency);
  float digitSize = 0.35 * pulse;

  // Two digit display for 10
  float d = 0.0;
  if (number == 10) {
    // "1" on the left, "0" on the right
    d += digit(p + vec2(0.22, 0.0), 1, digitSize);
    d += digit(p - vec2(0.22, 0.0), 0, digitSize);
  } else {
    d += digit(p, number, digitSize);
  }

  // Number color - gold to red as countdown decreases
  vec3 numberColor = mix(vec3(1.0, 0.9, 0.3), vec3(1.0, 0.2, 0.1), urgency);

  // Add glow effect
  float glow = d * (1.0 + u_glow * 2.0);
  col += numberColor * glow;

  // Outer glow
  float glowRadius = 0.1 * (1.0 + u_glow);
  col += numberColor * 0.3 * smoothstep(glowRadius, 0.0, abs(bgDist - 0.25));

  // Particle burst effect when transitioning
  float fractPart = fract(u_countdown);
  if (fractPart > 0.9) {
    float burstT = (fractPart - 0.9) * 10.0;
    for (float i = 0.0; i < 20.0; i++) {
      float angle = i / 20.0 * PI * 2.0 + hash(vec2(i, number)) * 0.5;
      vec2 particleDir = vec2(cos(angle), sin(angle));
      vec2 particlePos = particleDir * burstT * 0.5;
      float particleDist = length(p - particlePos);
      col += numberColor * smoothstep(0.02, 0.0, particleDist) * (1.0 - burstT);
    }
  }

  // Mouse interaction - ripple effect
  vec2 mousePos = vec2((u_mouse_x - 0.5) * aspect, u_mouse_y - 0.5);
  float mouseDist = length(p - mousePos);
  float ripple = sin(mouseDist * 30.0 - u_time * 5.0) * 0.5 + 0.5;
  col += vec3(0.2, 0.3, 0.5) * ripple * smoothstep(0.3, 0.0, mouseDist) * 0.2;

  // Vignette
  float vignette = 1.0 - length(uv - 0.5) * 0.8;
  col *= vignette;

  fragColor = vec4(col, 1.0);
}
