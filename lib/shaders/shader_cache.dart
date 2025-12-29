import 'dart:ui';

/// Preloads and caches all shader programs for instant access.
///
/// Why caching matters:
/// - FragmentProgram compilation can cause jank on first use
/// - Reusing FragmentShader instances is more efficient than recreating
/// - Preloading at app start ensures smooth animations
class ShaderCache {
  ShaderCache._();

  static final ShaderCache instance = ShaderCache._();

  final Map<String, FragmentProgram> _programs = {};
  final Map<String, FragmentShader> _shaders = {};

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// All shader asset paths
  static const List<String> shaderAssets = [
    'shaders/snowfall.frag',
    'shaders/fireworks.frag',
    'shaders/countdown.frag',
    'shaders/aurora.frag',
    'shaders/celebration.frag',
    'shaders/matrix.frag',
    'shaders/cyberpunk_ending.frag',
  ];

  /// Preload all shaders at app startup
  Future<void> warmUp() async {
    if (_initialized) return;

    await Future.wait(
      shaderAssets.map((path) async {
        try {
          final program = await FragmentProgram.fromAsset(path);
          _programs[path] = program;
          // Pre-create one shader instance
          _shaders[path] = program.fragmentShader();
        } catch (_) {
          // Shader might not exist yet during development - silently skip
        }
      }),
    );

    _initialized = true;
  }

  /// Get a cached FragmentProgram
  FragmentProgram? getProgram(String assetPath) {
    return _programs[assetPath];
  }

  /// Get a reusable FragmentShader instance
  ///
  /// Note: This returns a shared instance. If you need multiple
  /// simultaneous shaders with different uniforms, create new ones
  /// from the program.
  FragmentShader? getShader(String assetPath) {
    return _shaders[assetPath];
  }

  /// Create a fresh FragmentShader instance (for cases where you need
  /// multiple instances with different uniform states)
  FragmentShader? createShader(String assetPath) {
    return _programs[assetPath]?.fragmentShader();
  }

  /// Check if a specific shader is available
  bool hasShader(String assetPath) {
    return _programs.containsKey(assetPath);
  }
}

/// Convenience extension for shader asset paths
extension ShaderAssets on String {
  static const snowfall = 'shaders/snowfall.frag';
  static const fireworks = 'shaders/fireworks.frag';
  static const countdown = 'shaders/countdown.frag';
  static const aurora = 'shaders/aurora.frag';
  static const celebration = 'shaders/celebration.frag';
  static const matrix = 'shaders/matrix.frag';
  static const cyberpunkEnding = 'shaders/cyberpunk_ending.frag';
}
