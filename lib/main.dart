import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'flashback/flashback_journey.dart';
import 'scenes/festive_journey.dart';
import 'shaders/shader_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Go fullscreen for maximum shader glory
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Prefer landscape for better visuals
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  // Preload all shaders to avoid jank
  await ShaderCache.instance.warmUp();

  runApp(const FestiveShaderApp());
}

class FestiveShaderApp extends StatelessWidget {
  const FestiveShaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Festive Shader Journey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const SplashScreen(),
    );
  }
}

/// Fun splash screen before the journey begins
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showStart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showStart = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startJourney() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const FestiveJourney(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _startFlashback() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const FlashbackJourney(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = _controller.value;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Moinsen branding
                  Opacity(
                    opacity: Curves.easeOut.transform(
                      (progress / 0.4).clamp(0.0, 1.0),
                    ),
                    child: const Text(
                      'MOINSEN DEVELOPMENT',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 12,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'presents',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 11,
                      letterSpacing: 4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Animated title
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [
                          Colors.blue.shade200,
                          Colors.purple.shade300,
                          Colors.pink.shade200,
                        ],
                        stops: [0.0, 0.5 + progress * 0.3, 1.0],
                      ).createShader(bounds);
                    },
                    child: Text(
                      'FESTIVE\nSHADER\nJOURNEY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48 + progress * 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        height: 1.1,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Subtitle with typewriter effect
                  Opacity(
                    opacity: Curves.easeIn.transform(
                      ((progress - 0.3) / 0.7).clamp(0.0, 1.0),
                    ),
                    child: const Text(
                      'A GPU-powered celebration\nfrom Christmas to New Year 2026',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                        letterSpacing: 2,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Start buttons
                  AnimatedOpacity(
                    opacity: _showStart ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        // Festive Journey button
                        GestureDetector(
                          onTap: _startJourney,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white38),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'FESTIVE JOURNEY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    letterSpacing: 4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _PulsingArrow(),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Flashback 2025 button
                        GestureDetector(
                          onTap: _startFlashback,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.shade700.withValues(alpha: 0.3),
                                  Colors.orange.shade800.withValues(alpha: 0.3),
                                ],
                              ),
                              border: Border.all(color: Colors.amber.shade600),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  color: Colors.amber.shade300,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'FLASHBACK 2025',
                                  style: TextStyle(
                                    color: Colors.amber.shade200,
                                    fontSize: 12,
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Credits
                  AnimatedOpacity(
                    opacity: _showStart ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 800),
                    child: const Column(
                      children: [
                        Text(
                          'Built by Moinsen Development',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Powered by Flutter Fragment Shaders & Claude Code',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '// Happy Coding 2026!',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PulsingArrow extends StatefulWidget {
  @override
  State<_PulsingArrow> createState() => _PulsingArrowState();
}

class _PulsingArrowState extends State<_PulsingArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_controller.value * 8, 0),
          child: const Icon(
            Icons.arrow_forward,
            color: Colors.white70,
            size: 20,
          ),
        );
      },
    );
  }
}
