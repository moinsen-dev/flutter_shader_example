# Flutter Shader Reference Guide

Complete API documentation, troubleshooting, and advanced patterns for Flutter fragment shaders.

## API Reference

### FragmentProgram

```dart
/// Loads a compiled shader from assets
static Future<FragmentProgram> fromAsset(String assetKey)

/// Creates a new FragmentShader instance
FragmentShader fragmentShader()
```

### FragmentShader

```dart
/// Sets a float uniform at the given index
void setFloat(int index, double value)

/// Sets an image sampler at the given index (separate index space from floats)
void setImageSampler(int index, Image image)
```

### Paint Integration

```dart
final paint = Paint()..shader = fragmentShader;
canvas.drawRect(rect, paint);
```

### ImageFilter (Impeller-only)

```dart
// Creates an ImageFilter from a fragment shader
// WARNING: Only supported on Impeller backend!
ImageFilter.shader(FragmentShader shader, {
  FilterQuality filterQuality = FilterQuality.low,
})
```

## Uniform Type Mapping

| GLSL Type | Float Slots | Set Pattern |
|-----------|-------------|-------------|
| `float` | 1 | `setFloat(i, v)` |
| `vec2` | 2 | `setFloat(i, x); setFloat(i+1, y)` |
| `vec3` | 3 | `setFloat(i..i+2, x,y,z)` |
| `vec4` | 4 | `setFloat(i..i+3, x,y,z,w)` |
| `mat2` | 4 | Column-major order |
| `mat3` | 9 | Column-major order |
| `mat4` | 16 | Column-major order |
| `sampler2D` | 0 (separate) | `setImageSampler(j, image)` |

## Common Patterns

### AnimatedShaderWidget Pattern

```dart
class ShaderAnimation extends StatefulWidget {
  const ShaderAnimation({super.key});

  @override
  State<ShaderAnimation> createState() => _ShaderAnimationState();
}

class _ShaderAnimationState extends State<ShaderAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  FragmentProgram? _program;
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
    _program = await FragmentProgram.fromAsset('shaders/effect.frag');
    _shader = _program!.fragmentShader();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ShaderPainter(
            shader: _shader!,
            time: _controller.value * 10,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class ShaderPainter extends CustomPainter {
  ShaderPainter({required this.shader, required this.time});

  final FragmentShader shader;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(ShaderPainter oldDelegate) => true;
}
```

### ShaderMask Pattern

```dart
ShaderMask(
  shaderCallback: (Rect bounds) {
    shader.setFloat(0, bounds.width);
    shader.setFloat(1, bounds.height);
    return shader;
  },
  blendMode: BlendMode.srcATop,
  child: Text('Masked Text'),
)
```

### BackdropFilter Pattern (Impeller-only)

```dart
ClipRect(
  child: BackdropFilter(
    filter: ImageFilter.shader(shader),
    child: Container(
      color: Colors.transparent,
      width: 200,
      height: 200,
    ),
  ),
)
```

### Precaching for Performance

```dart
class ShaderCache {
  static final Map<String, FragmentProgram> _cache = {};

  static Future<void> warmUp(List<String> shaderPaths) async {
    await Future.wait(
      shaderPaths.map((path) async {
        _cache[path] = await FragmentProgram.fromAsset(path);
      }),
    );
  }

  static FragmentProgram get(String path) {
    final program = _cache[path];
    if (program == null) {
      throw StateError('Shader not cached: $path. Call warmUp first.');
    }
    return program;
  }
}

// In main.dart or app initialization:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ShaderCache.warmUp([
    'shaders/effect1.frag',
    'shaders/effect2.frag',
  ]);
  runApp(const MyApp());
}
```

## Troubleshooting

### Black Screen / Nothing Renders

| Symptom | Cause | Solution |
|---------|-------|----------|
| Completely black | `fragColor` never written | Ensure main() writes to `fragColor` |
| Black with occasional flicker | Wrong coordinates | Use `FlutterFragCoord()` not `gl_FragCoord` |
| Partial black regions | Normalization error | Divide coordinates by size: `pos / u_size` |
| Works on iOS, black on Android | Y-flip issue | Add OpenGLES Y-flip correction |

### Uniform Mismatch Errors

| Symptom | Cause | Solution |
|---------|-------|----------|
| Wrong colors/positions | Index mismatch | Audit uniform order vs setFloat indices |
| Texture not showing | Wrong sampler index | Remember samplers have separate index space |
| Partial uniforms work | Skipped vec component | Count all components: vec4 = 4 floats |

### Compilation Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Unknown identifier" | Using gl_FragCoord | Use `FlutterFragCoord()` |
| "Unsupported type" | Using bool/uint | Convert to float: `float flag = 1.0;` |
| Include error | Missing runtime include | Add `#include <flutter/runtime_effect.glsl>` |

### Performance Issues

| Symptom | Cause | Solution |
|---------|-------|----------|
| First-frame jank | Shader compilation | Precache FragmentProgram at app start |
| Ongoing stutters | New shader instances | Reuse FragmentShader, only update uniforms |
| High GPU usage | Complex shader math | Simplify calculations, reduce iterations |

### Platform-Specific Issues

| Platform | Common Issue | Solution |
|----------|--------------|----------|
| Android OpenGLES | Y-flip on textures | Use `#ifdef IMPELLER_TARGET_OPENGLES` |
| iOS Metal | None typical | Generally works well |
| Web CanvasKit | Performance varies | Test with both CanvasKit and skwasm |
| Desktop | Backend differences | Check which renderer is active |

## Debugging Tools

### Inspect Uniform Layout
```bash
# Generate reflection data (requires Flutter SDK tools)
impellerc --sl shader.frag --spirv shader.spirv
flatc --raw-binary -o . path/to/shader.fbs shader.spirv
```

### Visual Debugging in Shader
```glsl
// Output UV coordinates as colors
fragColor = vec4(uv, 0.0, 1.0);

// Output normalized position
fragColor = vec4(FlutterFragCoord().xy / u_size, 0.0, 1.0);

// Output single uniform as grayscale
fragColor = vec4(vec3(u_time * 0.1), 1.0);
```

### Check Backend at Runtime
```dart
// Impeller detection (approximate)
import 'dart:io';

bool get isLikelyImpeller {
  if (Platform.isIOS) return true; // iOS defaults to Impeller
  // Android: depends on build configuration
  return false;
}
```

## External Resources

- [Flutter Shader Guide](https://docs.flutter.dev/ui/design/graphics/fragment-shaders)
- [FragmentProgram API](https://api.flutter.dev/flutter/dart-ui/FragmentProgram-class.html)
- [Impeller Overview](https://docs.flutter.dev/perf/impeller)
- [SkSL Warm-up](https://docs.flutter.dev/perf/rendering-performance#shader-compilation-jank)
- [flutter_shaders package](https://pub.dev/packages/flutter_shaders)
