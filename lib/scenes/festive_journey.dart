import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shaders/shader_cache.dart';
import '../widgets/interaction_detector.dart';
import 'scene_painter.dart';

/// The different scenes in our festive journey
enum FestiveScene {
  snowfall('Snowfall', '❄️ A peaceful winter night...'),
  aurora('Aurora', '✨ Northern lights dance across the sky...'),
  matrix('Matrix', '💻 Meanwhile, in a developer\'s terminal...'),
  countdown('Countdown', '🎉 The final countdown begins!'),
  fireworks('Fireworks', '🎆 Happy New Year!'),
  celebration('Celebration', '🥳 Welcome to 2026!'),
  cyberpunkEnding('Finale', '🚀 Happy Coding 2026!');

  const FestiveScene(this.title, this.subtitle);
  final String title;
  final String subtitle;
}

/// Main widget that orchestrates the festive shader journey
class FestiveJourney extends StatefulWidget {
  const FestiveJourney({super.key});

  @override
  State<FestiveJourney> createState() => _FestiveJourneyState();
}

class _FestiveJourneyState extends State<FestiveJourney>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _timeController;
  late AnimationController _transitionController;
  late AnimationController _countdownController;
  late AnimationController _fireworkTriggerController;

  // Scene management
  FestiveScene _currentScene = FestiveScene.snowfall;
  FestiveScene? _nextScene;
  bool _autoPlay = true;
  Timer? _sceneTimer;

  // Interaction state
  InteractionData _interaction = const InteractionData();

  // Scene-specific state
  double _countdown = 10.0;
  double _fireworkX = 0.5;
  double _fireworkY = 0.7;
  double _hueShift = 0.0;
  double _matrixReveal = 0.0;

  @override
  void initState() {
    super.initState();

    // Main time controller - runs forever
    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1000),
    )..repeat();

    // Scene transition controller
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Countdown controller (10 seconds)
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_updateCountdown);

    // Firework trigger controller
    _fireworkTriggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Start auto-play timer
    _startAutoPlay();
  }

  void _updateCountdown() {
    setState(() {
      _countdown = 10.0 * (1.0 - _countdownController.value);
    });

    // When countdown reaches zero, go to fireworks
    if (_countdownController.isCompleted &&
        _currentScene == FestiveScene.countdown) {
      _goToScene(FestiveScene.fireworks);
      _fireworkTriggerController.forward(from: 0.0);
    }
  }

  void _startAutoPlay() {
    _sceneTimer?.cancel();
    if (!_autoPlay) return;

    // Different durations for different scenes
    final duration = switch (_currentScene) {
      FestiveScene.snowfall => const Duration(seconds: 8),
      FestiveScene.aurora => const Duration(seconds: 10),
      FestiveScene.matrix => const Duration(seconds: 8),
      FestiveScene.countdown => const Duration(
        seconds: 12,
      ), // Includes countdown
      FestiveScene.fireworks => const Duration(seconds: 8),
      FestiveScene.celebration => const Duration(seconds: 12),
      FestiveScene.cyberpunkEnding => const Duration(
        seconds: 15,
      ), // Grand finale
    };

    _sceneTimer = Timer(duration, () {
      if (!_autoPlay) return;

      final scenes = FestiveScene.values;
      final nextIndex = (scenes.indexOf(_currentScene) + 1) % scenes.length;
      _goToScene(scenes[nextIndex]);
    });
  }

  void _goToScene(FestiveScene scene) {
    if (scene == _currentScene) return;

    setState(() {
      _nextScene = scene;
    });

    _transitionController.forward(from: 0.0).then((_) {
      setState(() {
        _currentScene = scene;
        _nextScene = null;
      });
      _transitionController.reset();

      // Scene-specific setup
      if (scene == FestiveScene.countdown) {
        _countdownController.forward(from: 0.0);
      } else if (scene == FestiveScene.fireworks) {
        _fireworkTriggerController.forward(from: 0.0);
      } else if (scene == FestiveScene.matrix) {
        // Gradually reveal the message
        Future.delayed(const Duration(seconds: 3), () {
          if (_currentScene == FestiveScene.matrix && mounted) {
            _animateMatrixReveal();
          }
        });
      }

      _startAutoPlay();
    });
  }

  void _animateMatrixReveal() {
    const steps = 50;
    for (int i = 0; i <= steps; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted && _currentScene == FestiveScene.matrix) {
          setState(() {
            _matrixReveal = i / steps;
          });
        }
      });
    }
  }

  void _handleInteraction(InteractionData data) {
    setState(() {
      _interaction = data;
    });

    // Tap triggers scene-specific actions
    if (data.isTapped) {
      _handleTap();
    }
  }

  void _handleTap() {
    switch (_currentScene) {
      case FestiveScene.fireworks:
        // Trigger new firework at random/mouse position
        setState(() {
          _fireworkX = _interaction.mousePosition.dx;
          _fireworkY = 1.0 - _interaction.mousePosition.dy;
          _hueShift = (_hueShift + 0.2) % 1.0;
        });
        _fireworkTriggerController.forward(from: 0.0);
        break;
      case FestiveScene.matrix:
        // Reveal the message faster
        setState(() {
          _matrixReveal = math.min(_matrixReveal + 0.3, 1.0);
        });
        break;
      default:
        // Other scenes - maybe add sparkle effects later
        break;
    }
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

  @override
  void dispose() {
    _timeController.dispose();
    _transitionController.dispose();
    _countdownController.dispose();
    _fireworkTriggerController.dispose();
    _sceneTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cache = ShaderCache.instance;

    if (!cache.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading shaders...',
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
            // Main shader canvas
            AnimatedBuilder(
              animation: Listenable.merge([
                _timeController,
                _transitionController,
                _fireworkTriggerController,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _buildPainter(cache),
                  size: Size.infinite,
                );
              },
            ),

            // Transition overlay
            if (_nextScene != null)
              AnimatedBuilder(
                animation: _transitionController,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withValues(
                      alpha:
                          Curves.easeInOut.transform(
                            _transitionController.value,
                          ) *
                          0.8,
                    ),
                  );
                },
              ),

            // UI Overlay
            SafeArea(
              child: Column(
                children: [
                  // Top bar with scene info
                  _buildTopBar(),

                  const Spacer(),

                  // Bottom controls
                  _buildBottomControls(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  CustomPainter? _buildPainter(ShaderCache cache) {
    final time = _timeController.value * 1000.0; // Convert to seconds-ish

    final shader = switch (_currentScene) {
      FestiveScene.snowfall => cache.getShader('shaders/snowfall.frag'),
      FestiveScene.aurora => cache.getShader('shaders/aurora.frag'),
      FestiveScene.matrix => cache.getShader('shaders/matrix.frag'),
      FestiveScene.countdown => cache.getShader('shaders/countdown.frag'),
      FestiveScene.fireworks => cache.getShader('shaders/fireworks.frag'),
      FestiveScene.celebration => cache.getShader('shaders/celebration.frag'),
      FestiveScene.cyberpunkEnding => cache.getShader(
        'shaders/cyberpunk_ending.frag',
      ),
    };

    if (shader == null) return null;

    return switch (_currentScene) {
      FestiveScene.snowfall => SnowfallPainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        wind: math.sin(time * 0.1) * 0.3,
      ),
      FestiveScene.aurora => AuroraPainter(
        shader: shader,
        time: time,
        interaction: _interaction,
      ),
      FestiveScene.matrix => MatrixPainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        revealProgress: _matrixReveal,
      ),
      FestiveScene.countdown => CountdownPainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        countdown: _countdown,
        glowPulse: math.sin(time * 3.0) * 0.3,
      ),
      FestiveScene.fireworks => FireworksPainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        triggerProgress: _fireworkTriggerController.value,
        explosionX: _fireworkX,
        explosionY: _fireworkY,
        hueShift: _hueShift,
      ),
      FestiveScene.celebration => CelebrationPainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        confettiAmount: 1.0,
      ),
      FestiveScene.cyberpunkEnding => CyberpunkEndingPainter(
        shader: shader,
        time: time,
        interaction: _interaction,
        glitchIntensity: 0.2 + math.sin(time * 0.5) * 0.1,
        neonPulse: 1.0,
      ),
    };
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentScene.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _currentScene.subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Scene selector
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: FestiveScene.values.length,
            itemBuilder: (context, index) {
              final scene = FestiveScene.values[index];
              final isActive = scene == _currentScene;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(scene.title),
                  selected: isActive,
                  onSelected: (_) => _goToScene(scene),
                  selectedColor: Colors.white24,
                  backgroundColor: Colors.black38,
                  labelStyle: TextStyle(
                    color: isActive ? Colors.white : Colors.white60,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isActive ? Colors.white38 : Colors.white12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Auto-play toggle and hints
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _autoPlay ? Colors.green : Colors.white24,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _autoPlay ? Icons.play_arrow : Icons.pause,
                        color: _autoPlay ? Colors.green : Colors.white60,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _autoPlay ? 'Auto' : 'Manual',
                        style: TextStyle(
                          color: _autoPlay ? Colors.green : Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Interaction hints
              const InteractionHints(compact: true),
            ],
          ),
        ),
      ],
    );
  }
}
