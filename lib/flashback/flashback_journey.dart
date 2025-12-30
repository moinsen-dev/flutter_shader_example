import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../shaders/shader_cache.dart';
import '../widgets/interaction_detector.dart';
import 'flashback_scene.dart';
import 'flashback_painters.dart';
import 'data/flashback_events.dart';
import 'widgets/flashback_splash.dart';
import 'widgets/flashback_ending.dart';
import 'widgets/month_card.dart';

// Convenience alias for events list
List<FlashbackMonth> get flashbackEvents => flashback2025Events;

/// Main orchestrator for the Flashback 2025 experience
/// Shows 12 months of 2025 events with mood-appropriate shader effects
class FlashbackJourney extends StatefulWidget {
  const FlashbackJourney({super.key});

  @override
  State<FlashbackJourney> createState() => _FlashbackJourneyState();
}

class _FlashbackJourneyState extends State<FlashbackJourney>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _timeController;
  late AnimationController _transitionController;
  late AnimationController _calendarPulseController;
  late AnimationController _contentFadeController;

  // Scene management
  FlashbackScene _currentScene = FlashbackScene.splash;
  FlashbackScene? _nextScene;
  bool _autoPlay = true;
  Timer? _sceneTimer;

  // Interaction state
  InteractionData _interaction = const InteractionData();

  // Shader cache check
  bool _shadersLoaded = false;

  @override
  void initState() {
    super.initState();

    // Main time controller - runs continuously for shader animations
    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1000),
    )..repeat();

    // Scene transition controller (cross-fade) - slower for elegance
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Calendar day highlight pulse
    _calendarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Content fade-in for text and images (slower for more elegant feel)
    _contentFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Load flashback shaders
    _loadShaders();
  }

  Future<void> _loadShaders() async {
    // Ensure flashback shaders are loaded
    await FlashbackShaderCache.instance.warmUp();
    setState(() {
      _shadersLoaded = true;
    });

    // Start content fade for splash
    _contentFadeController.forward();

    // Auto-advance from splash after 6 seconds (slower pace)
    if (_autoPlay) {
      _sceneTimer = Timer(const Duration(seconds: 6), () {
        if (mounted && _currentScene == FlashbackScene.splash) {
          _goToScene(FlashbackScene.january);
        }
      });
    }
  }

  void _startAutoPlay() {
    _sceneTimer?.cancel();
    if (!_autoPlay) return;

    // Get duration for current scene
    final duration = _currentScene.isMonth
        ? flashbackEvents[_currentScene.monthIndex! - 1].displayDuration
        : const Duration(seconds: 8);

    _sceneTimer = Timer(duration, () {
      if (!_autoPlay || !mounted) return;

      final nextScene = _currentScene.next;
      if (nextScene != null) {
        _goToScene(nextScene);
      }
    });
  }

  void _goToScene(FlashbackScene scene) {
    if (scene == _currentScene) return;

    setState(() {
      _nextScene = scene;
    });

    // Reset content fade
    _contentFadeController.reset();

    _transitionController.forward(from: 0.0).then((_) {
      setState(() {
        _currentScene = scene;
        _nextScene = null;
      });
      _transitionController.reset();

      // Fade in new content
      _contentFadeController.forward();

      // Continue auto-play
      _startAutoPlay();
    });
  }

  void _handleInteraction(InteractionData data) {
    setState(() {
      _interaction = data;
    });
  }

  void _toggleAutoPlay() {
    setState(() {
      _autoPlay = !_autoPlay;
    });
    if (_autoPlay) {
      _startAutoPlay();
    } else {
      _sceneTimer?.cancel();
    }
  }

  void _handleReplay() {
    _goToScene(FlashbackScene.splash);
  }

  void _handleExit() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _transitionController.dispose();
    _calendarPulseController.dispose();
    _contentFadeController.dispose();
    _sceneTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shadersLoaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.amber),
              SizedBox(height: 16),
              Text(
                'Loading Flashback 2025...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: InteractionDetector(
        onInteraction: _handleInteraction,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Shader background
            AnimatedBuilder(
              animation: _timeController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _buildShaderPainter(),
                  size: Size.infinite,
                );
              },
            ),

            // Content layer
            _buildContentLayer(),

            // Transition overlay
            if (_nextScene != null)
              AnimatedBuilder(
                animation: _transitionController,
                builder: (context, child) {
                  final progress = _transitionController.value;
                  // Fade to black in first half, fade from black in second half
                  final opacity = progress < 0.5
                      ? progress * 2
                      : (1.0 - progress) * 2;
                  return Container(
                    color: Colors.black.withValues(
                      alpha: opacity.clamp(0.0, 1.0),
                    ),
                  );
                },
              ),

            // Navigation controls (not on splash or ending)
            if (_currentScene.isMonth)
              SafeArea(
                child: Column(
                  children: [const Spacer(), _buildBottomControls()],
                ),
              ),
          ],
        ),
      ),
    );
  }

  CustomPainter? _buildShaderPainter() {
    final time = _timeController.value * 1000.0;
    final cache = FlashbackShaderCache.instance;

    // Special handling for splash and ending
    if (_currentScene == FlashbackScene.splash) {
      // Use aurora for splash background
      final shader = ShaderCache.instance.getShader('shaders/aurora.frag');
      if (shader == null) return null;
      return _SplashBackgroundPainter(
        shader: shader,
        time: time,
        intensity: 0.5,
      );
    }

    if (_currentScene == FlashbackScene.ending) {
      // Use fireworks for ending
      final shader = ShaderCache.instance.getShader('shaders/fireworks.frag');
      if (shader == null) return null;
      // Painter handled in FlashbackEnding widget
      return null;
    }

    // Month scenes - get the event and its shader
    if (_currentScene.isMonth) {
      final event = flashbackEvents[_currentScene.monthIndex! - 1];
      final shader = cache.getShader(event.shaderAsset);
      if (shader == null) return null;

      return _buildMonthPainter(event, shader, time);
    }

    return null;
  }

  CustomPainter _buildMonthPainter(
    FlashbackMonth event,
    dynamic shader,
    double time,
  ) {
    final pulse = _calendarPulseController.value;

    return switch (event.shaderAsset) {
      'shaders/flashback_fire.frag' => FlashbackFirePainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        intensity: 1.0,
        transition: 1.0,
        smokeAmount: 0.6,
      ),
      'shaders/flashback_earthquake.frag' => FlashbackEarthquakePainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        intensity: 1.0,
        transition: 1.0,
        shakeStrength: 0.5 + pulse * 0.2,
      ),
      'shaders/flashback_memorial.frag' => FlashbackMemorialPainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        intensity: 1.0,
        transition: 1.0,
        candleFlicker: 0.3 + pulse * 0.2,
      ),
      'shaders/flashback_rainbow.frag' => FlashbackRainbowPainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        intensity: 1.0,
        transition: 1.0,
        confettiDensity: 1.0,
      ),
      'shaders/flashback_rain.frag' => FlashbackRainPainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        intensity: 1.0,
        transition: 1.0,
        rainDensity: 1.0,
      ),
      'shaders/flashback_tension.frag' => FlashbackTensionPainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        intensity: 1.0,
        transition: 1.0,
        pulseSpeed: 1.0,
        darkness: 0.5,
      ),
      'shaders/snowfall.frag' => FlashbackSnowfallPainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        intensity: 0.8,
        transition: 1.0,
        wind: math.sin(time * 0.1) * 0.2,
      ),
      'shaders/celebration.frag' => FlashbackCelebrationPainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        intensity: 1.0,
        transition: 1.0,
        confettiAmount: 0.8,
      ),
      _ => FlashbackTensionPainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        intensity: 1.0,
        transition: 1.0,
      ),
    };
  }

  Widget _buildContentLayer() {
    return switch (_currentScene) {
      FlashbackScene.splash => FlashbackSplash(
        animation: _contentFadeController,
        onComplete: () => _goToScene(FlashbackScene.january),
      ),
      FlashbackScene.ending => FlashbackEnding(
        fireworksShader: ShaderCache.instance.getShader(
          'shaders/fireworks.frag',
        )!,
        time: _timeController.value * 1000.0,
        animation: _contentFadeController,
        onReplay: _handleReplay,
        onExit: _handleExit,
      ),
      _ when _currentScene.isMonth => AnimatedBuilder(
        animation: _contentFadeController,
        builder: (context, child) {
          final event = flashbackEvents[_currentScene.monthIndex! - 1];
          return Opacity(
            opacity: _contentFadeController.value,
            child: MonthCard(
              month: event,
              calendarPulse: _calendarPulseController.value,
              textOpacity: _contentFadeController.value,
            ),
          );
        },
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildBottomControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month selector chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 12,
              itemBuilder: (context, index) {
                final scene = FlashbackScene.values[index + 1]; // Skip splash
                final isActive = scene == _currentScene;
                final event = flashbackEvents[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => _goToScene(scene),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? event.primaryColor.withValues(alpha: 0.3)
                            : Colors.black38,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? event.primaryColor : Colors.white24,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        event.monthName.substring(0, 3).toUpperCase(),
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white60,
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Auto-play toggle and navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Auto-play toggle
              GestureDetector(
                onTap: _toggleAutoPlay,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _autoPlay ? Colors.amber : Colors.white24,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _autoPlay ? Icons.pause : Icons.play_arrow,
                        color: _autoPlay ? Colors.amber : Colors.white60,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _autoPlay ? 'Auto' : 'Manual',
                        style: TextStyle(
                          color: _autoPlay ? Colors.amber : Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation arrows
              Row(
                children: [
                  IconButton(
                    onPressed: _currentScene.previous != null
                        ? () => _goToScene(_currentScene.previous!)
                        : null,
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    color: Colors.white70,
                    disabledColor: Colors.white24,
                  ),
                  IconButton(
                    onPressed: _currentScene.next != null
                        ? () => _goToScene(_currentScene.next!)
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    color: Colors.white70,
                    disabledColor: Colors.white24,
                  ),
                ],
              ),

              // Skip to ending
              TextButton(
                onPressed: () => _goToScene(FlashbackScene.ending),
                child: const Text(
                  'SKIP →',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Simple aurora-style background painter for splash
class _SplashBackgroundPainter extends CustomPainter {
  _SplashBackgroundPainter({
    required this.shader,
    required this.time,
    required this.intensity,
  });

  final dynamic shader;
  final double time;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    // Aurora shader uniforms
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time * 0.3); // Slower for splash
    shader.setFloat(3, intensity);
    shader.setFloat(4, 0.5); // mouseX
    shader.setFloat(5, 0.5); // mouseY

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _SplashBackgroundPainter oldDelegate) {
    return time != oldDelegate.time;
  }
}

/// Cache for flashback-specific shaders
class FlashbackShaderCache {
  FlashbackShaderCache._();

  static final FlashbackShaderCache instance = FlashbackShaderCache._();

  final Map<String, dynamic> _shaders = {};
  bool _initialized = false;

  static const List<String> flashbackShaderAssets = [
    'shaders/flashback_fire.frag',
    'shaders/flashback_earthquake.frag',
    'shaders/flashback_memorial.frag',
    'shaders/flashback_rainbow.frag',
    'shaders/flashback_rain.frag',
    'shaders/flashback_tension.frag',
  ];

  Future<void> warmUp() async {
    if (_initialized) return;

    // Import dart:ui for FragmentProgram
    await Future.wait(
      flashbackShaderAssets.map((path) async {
        try {
          final program = await _loadProgram(path);
          if (program != null) {
            _shaders[path] = program.fragmentShader();
          }
        } catch (e) {
          debugPrint('Failed to load shader $path: $e');
        }
      }),
    );

    _initialized = true;
  }

  Future<ui.FragmentProgram?> _loadProgram(String path) async {
    return await ui.FragmentProgram.fromAsset(path);
  }

  dynamic getShader(String path) {
    // First check flashback shaders
    if (_shaders.containsKey(path)) {
      return _shaders[path];
    }
    // Fall back to main shader cache for reused shaders
    return ShaderCache.instance.getShader(path);
  }

  bool get isInitialized => _initialized;
}
