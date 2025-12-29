---
name: flutter-shader
description: Develop Flutter fragment shaders (GLSL) end-to-end. Use when creating, debugging, or integrating custom shaders in Flutter apps. Triggers on shader, GLSL, fragment shader, CustomPainter with shader, ShaderMask, visual effects, procedural graphics, or GPU rendering in Flutter.
---

# Flutter Fragment Shader Development

Comprehensive guide for building, integrating, debugging, and shipping Flutter fragment shaders using Flutter's `FragmentProgram` / `FragmentShader` APIs.

## Scope and Capabilities

### What Flutter Supports
- **Fragment shaders** (pixel shaders) only - vertex shaders are NOT supported
- Core runtime objects:
  - `FragmentProgram`: compiled shader asset that creates shader instances
  - `FragmentShader`: instance with uniforms bound to `Paint.shader`

### Backend Awareness
Flutter runs with **Skia** or **Impeller** backends:
- Both support custom shaders
- `ImageFilter.shader` is **Impeller-only**
- Performance characteristics differ between backends

## Project Setup Checklist

### 1. File Structure
```
/shaders/
  my_effect.frag
/lib/
  shaders/
  widgets/
```

### 2. Declare in pubspec.yaml
```yaml
flutter:
  shaders:
    - shaders/my_effect.frag
```

### 3. Hot Reload
In debug mode, shader edits trigger recompilation on hot reload/restart.

## GLSL Authoring Rules

### Required Header
```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;
```

### Coordinate Access
Use `FlutterFragCoord()` instead of `gl_FragCoord`:
```glsl
vec2 p = FlutterFragCoord().xy / u_size;
```

### Key Limitations
- Only `sampler2D` (no samplerCube, etc.)
- Only `texture(sampler, uv)` two-argument form
- No extra varying inputs
- No UBO/SSBO
- No unsigned ints or booleans

### OpenGLES Y-Flip Fix
When sampling engine textures on OpenGLES:
```glsl
vec2 uv = FlutterFragCoord().xy / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
```

## Uniform Indexing Rules

### Rule 1: Float uniforms use declaration order
`float`, `vec2`, `vec3`, `vec4` set via `setFloat(index, value)` in declaration order.

### Rule 2: Samplers have separate index space
`sampler2D` set via `setImageSampler(samplerIndex, image)` - does NOT consume float indices.

### Example
```glsl
uniform float uScale;      // setFloat(0, ...)
uniform sampler2D uTexture; // setImageSampler(0, ...) - separate!
uniform vec2 uMagnitude;   // setFloat(1, x), setFloat(2, y)
uniform vec4 uColor;       // setFloat(3..6, r,g,b,a)
```

```dart
shader.setFloat(0, 23);           // uScale
shader.setFloat(1, 114);          // uMagnitude.x
shader.setFloat(2, 83);           // uMagnitude.y
shader.setFloat(3, r);            // uColor.r
shader.setFloat(4, g);            // uColor.g
shader.setFloat(5, b);            // uColor.b
shader.setFloat(6, a);            // uColor.a
shader.setImageSampler(0, image); // uTexture
```

## Loading and Using Shaders

### Load Program
```dart
final program = await FragmentProgram.fromAsset('shaders/my_effect.frag');
```

### Create and Bind Uniforms
```dart
final shader = program.fragmentShader();
shader.setFloat(0, timeSeconds);
shader.setFloat(1, width);
shader.setFloat(2, height);
```

### Draw with Shader
```dart
canvas.drawRect(rect, Paint()..shader = shader);
```

### ImageFilter (Impeller-only)
```dart
ImageFilter.shader(shader) // Only works on Impeller!
```

## Development Workflow

### Step 1: Write Shader Spec
Define before coding:
- Inputs (uniforms): `u_time`, `u_size`, effect parameters
- Texture sampling requirements
- Application context: full-screen, mask, backdrop

### Step 2: Establish Uniform Contract
Consistent ordering convention:
1. `uniform vec2 u_size;`
2. `uniform float u_time;`
3. Effect parameters...

Mirror in Dart with constants for indices.

### Step 3: Create Integration Wrapper
Choose pattern:
- `CustomPainter` - drawing into Canvas
- `ShaderMask` - masking child content
- `BackdropFilter` / `ImageFiltered` - post-processing (Impeller-only)

### Step 4: Performance Optimization
- **Reuse `FragmentShader` instances** - don't recreate each frame
- **Precache `FragmentProgram`** before animations start
- **SkSL warm-up** for Skia backend jank mitigation
- **Use Impeller** where available (precompiles at build-time)

### Step 5: Cross-Platform Testing
Test on:
- Android (OpenGLES/Vulkan)
- iOS (Metal)
- Web (CanvasKit/skwasm)

## Debugging Guide

### Black Screen Diagnosis
1. Check `fragColor` is written
2. Verify coordinate normalization (divide by size)
3. Audit uniform index mapping

### Uniform Layout Inspection
Use `impellerc` + `flatc` for reflection data on uniform offsets.

### Backend Errors
`ImageFilter.shader` throws on non-Impeller backends.

## Additional Resources

- [TEMPLATES.md](TEMPLATES.md) - Copy-paste shader starter kits
- [REFERENCE.md](REFERENCE.md) - Complete API and troubleshooting guide

## Quick Reference

| Task | Tool/Pattern |
|------|--------------|
| Load shader | `FragmentProgram.fromAsset()` |
| Create instance | `program.fragmentShader()` |
| Set float uniform | `shader.setFloat(index, value)` |
| Set texture | `shader.setImageSampler(index, image)` |
| Draw to canvas | `Paint()..shader = shader` |
| Post-process | `ImageFilter.shader()` (Impeller) |
