# Flutter Shader Templates

Copy-paste starter kits for common shader patterns.

## Template A: Procedural Full-Rect Shader

A simple wave effect drawn to a full rectangle.

### shaders/wave.frag

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2  u_size;   // Canvas size (width, height)
uniform float u_time;   // Time in seconds
uniform float u_amp;    // Wave amplitude (0.0 - 0.5)
uniform float u_freq;   // Wave frequency (1.0 - 10.0)

void main() {
  vec2 p = FlutterFragCoord().xy / u_size; // Normalize to 0..1
  float y = sin((p.x * u_freq + u_time) * 6.28318) * u_amp;
  float v = smoothstep(0.02, 0.0, abs(p.y - (0.5 + y)));
  fragColor = vec4(vec3(v), 1.0);
}
```

### lib/shaders/wave_painter.dart

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

class WaveShaderPainter extends CustomPainter {
  WaveShaderPainter({
    required this.shader,
    required this.time,
    this.amplitude = 0.1,
    this.frequency = 3.0,
  });

  final FragmentShader shader;
  final double time;
  final double amplitude;
  final double frequency;

  @override
  void paint(Canvas canvas, Size size) {
    // Uniform indices (matching declaration order):
    // 0: u_size.x, 1: u_size.y, 2: u_time, 3: u_amp, 4: u_freq
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, amplitude);
    shader.setFloat(4, frequency);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant WaveShaderPainter old) => true;
}
```

### lib/widgets/wave_effect.dart

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../shaders/wave_painter.dart';

class WaveEffect extends StatefulWidget {
  const WaveEffect({super.key});

  @override
  State<WaveEffect> createState() => _WaveEffectState();
}

class _WaveEffectState extends State<WaveEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _loadShader();
  }

  Future<void> _loadShader() async {
    final program = await FragmentProgram.fromAsset('shaders/wave.frag');
    setState(() => _shader = program.fragmentShader());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WaveShaderPainter(
            shader: _shader!,
            time: _controller.value * 10,
            amplitude: 0.15,
            frequency: 4.0,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
```

---

## Template B: Gradient Background

Smooth animated gradient effect.

### shaders/gradient.frag

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform vec4 u_color1;  // Start color (RGBA)
uniform vec4 u_color2;  // End color (RGBA)

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;

  // Animated gradient angle
  float angle = u_time * 0.5;
  float gradient = uv.x * cos(angle) + uv.y * sin(angle);
  gradient = gradient * 0.5 + 0.5; // Normalize to 0..1

  fragColor = mix(u_color1, u_color2, gradient);
}
```

### Dart usage

```dart
// Uniform layout:
// 0-1: u_size (vec2)
// 2: u_time (float)
// 3-6: u_color1 (vec4)
// 7-10: u_color2 (vec4)

shader.setFloat(0, size.width);
shader.setFloat(1, size.height);
shader.setFloat(2, time);
// Color 1: Purple
shader.setFloat(3, 0.5);  // R
shader.setFloat(4, 0.0);  // G
shader.setFloat(5, 0.8);  // B
shader.setFloat(6, 1.0);  // A
// Color 2: Cyan
shader.setFloat(7, 0.0);  // R
shader.setFloat(8, 0.8);  // G
shader.setFloat(9, 0.8);  // B
shader.setFloat(10, 1.0); // A
```

---

## Template C: Texture Sampling

Sample and modify an image texture.

### shaders/texture_effect.frag

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform sampler2D u_texture;  // Sampler index 0 (separate from floats!)

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;

  // Handle OpenGLES Y-flip if needed
  #ifdef IMPELLER_TARGET_OPENGLES
    uv.y = 1.0 - uv.y;
  #endif

  // Add subtle wave distortion
  uv.x += sin(uv.y * 10.0 + u_time) * 0.01;

  vec4 color = texture(u_texture, uv);
  fragColor = color;
}
```

### Dart usage with image

```dart
import 'dart:ui' as ui;

class TextureShaderPainter extends CustomPainter {
  TextureShaderPainter({
    required this.shader,
    required this.image,
    required this.time,
  });

  final FragmentShader shader;
  final ui.Image image;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    // Float uniforms
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);

    // Sampler (separate index space!)
    shader.setImageSampler(0, image);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant TextureShaderPainter old) => true;
}
```

---

## Template D: Noise/Procedural Pattern

Classic simplex-style noise for procedural effects.

### shaders/noise.frag

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform float u_scale;    // Noise scale (1.0 - 20.0)
uniform float u_speed;    // Animation speed

// Simple hash function
vec2 hash(vec2 p) {
  p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
  return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// Gradient noise
float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);

  return mix(
    mix(dot(hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
        dot(hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
    mix(dot(hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
        dot(hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
    u.y
  );
}

// Fractal Brownian Motion
float fbm(vec2 p) {
  float value = 0.0;
  float amplitude = 0.5;
  for (int i = 0; i < 5; i++) {
    value += amplitude * noise(p);
    p *= 2.0;
    amplitude *= 0.5;
  }
  return value;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;

  float n = fbm(uv * u_scale + u_time * u_speed);
  n = n * 0.5 + 0.5; // Map to 0..1

  // Color mapping
  vec3 color = mix(
    vec3(0.1, 0.2, 0.4),  // Dark blue
    vec3(0.8, 0.9, 1.0),  // Light blue
    n
  );

  fragColor = vec4(color, 1.0);
}
```

---

## Template E: Post-Processing (Impeller-only)

Blur/glow effect using BackdropFilter.

### shaders/glow.frag

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_intensity;  // Glow intensity (0.0 - 2.0)
uniform sampler2D u_backdrop;  // Backdrop texture (from ImageFilter)

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;

  #ifdef IMPELLER_TARGET_OPENGLES
    uv.y = 1.0 - uv.y;
  #endif

  // Simple box blur approximation
  vec4 color = vec4(0.0);
  float total = 0.0;
  float blurSize = 0.005;

  for (float x = -2.0; x <= 2.0; x += 1.0) {
    for (float y = -2.0; y <= 2.0; y += 1.0) {
      vec2 offset = vec2(x, y) * blurSize;
      color += texture(u_backdrop, uv + offset);
      total += 1.0;
    }
  }
  color /= total;

  // Add glow
  color.rgb *= u_intensity;

  fragColor = color;
}
```

### Dart usage (Impeller-only!)

```dart
// WARNING: ImageFilter.shader only works on Impeller!
ClipRect(
  child: BackdropFilter(
    filter: ImageFilter.shader(shader),
    child: Container(
      color: Colors.transparent,
      width: double.infinity,
      height: double.infinity,
    ),
  ),
)
```

---

## Template F: Ripple/Touch Effect

Interactive ripple responding to touch position.

### shaders/ripple.frag

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 u_size;
uniform float u_time;
uniform vec2 u_touch;     // Touch position (normalized 0..1)
uniform float u_radius;   // Current ripple radius
uniform vec4 u_color;     // Ripple color

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;

  // Distance from touch point
  float dist = distance(uv, u_touch);

  // Ripple ring
  float ring = abs(dist - u_radius);
  float ripple = smoothstep(0.05, 0.0, ring);

  // Fade out over distance
  ripple *= 1.0 - smoothstep(0.0, 0.5, u_radius);

  fragColor = u_color * ripple;
}
```

### Dart usage with gesture

```dart
class RippleEffect extends StatefulWidget {
  const RippleEffect({super.key, required this.child});
  final Widget child;

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  FragmentShader? _shader;
  Offset _touchPoint = Offset.zero;
  double _radius = 0.0;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        setState(() => _radius = _controller.value);
      });
    _loadShader();
  }

  Future<void> _loadShader() async {
    final program = await FragmentProgram.fromAsset('shaders/ripple.frag');
    setState(() => _shader = program.fragmentShader());
  }

  void _onTapDown(TapDownDetails details, Size size) {
    _touchPoint = Offset(
      details.localPosition.dx / size.width,
      details.localPosition.dy / size.height,
    );
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (d) => _onTapDown(d, constraints.biggest),
          child: Stack(
            children: [
              widget.child,
              if (_shader != null && _radius > 0)
                CustomPaint(
                  painter: RipplePainter(
                    shader: _shader!,
                    touch: _touchPoint,
                    radius: _radius,
                  ),
                  child: const SizedBox.expand(),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class RipplePainter extends CustomPainter {
  RipplePainter({
    required this.shader,
    required this.touch,
    required this.radius,
  });

  final FragmentShader shader;
  final Offset touch;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, 0.0); // time (unused in this version)
    shader.setFloat(3, touch.dx);
    shader.setFloat(4, touch.dy);
    shader.setFloat(5, radius * 0.5);
    // Ripple color (white with transparency)
    shader.setFloat(6, 1.0);
    shader.setFloat(7, 1.0);
    shader.setFloat(8, 1.0);
    shader.setFloat(9, 0.3);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.srcOver,
    );
  }

  @override
  bool shouldRepaint(covariant RipplePainter old) =>
      touch != old.touch || radius != old.radius;
}
```

---

## pubspec.yaml Configuration

Remember to declare all shaders:

```yaml
flutter:
  shaders:
    - shaders/wave.frag
    - shaders/gradient.frag
    - shaders/texture_effect.frag
    - shaders/noise.frag
    - shaders/glow.frag
    - shaders/ripple.frag
```
