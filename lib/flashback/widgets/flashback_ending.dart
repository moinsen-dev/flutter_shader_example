import 'dart:ui';

import 'package:flutter/material.dart';

/// Ending screen for Flashback 2025
/// Shows farewell message with massive auto-playing fireworks celebration
class FlashbackEnding extends StatelessWidget {
  const FlashbackEnding({
    super.key,
    required this.fireworksShader,
    required this.time,
    required this.animation,
    required this.onReplay,
    required this.onExit,
  });

  final FragmentShader fireworksShader;
  final double time;
  final Animation<double> animation;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Massive fireworks shader background - auto-playing
            CustomPaint(
              painter: _FireworksEndingPainter(
                shader: fireworksShader,
                time: time,
                intensity: progress.clamp(0.3, 1.0),
              ),
            ),

            // Lighter overlay for better fireworks visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Farewell 2025
                    _buildFarewellSection(progress),

                    const SizedBox(height: 48),

                    // Welcome 2026
                    _buildWelcomeSection(progress),

                    const Spacer(flex: 2),

                    // Action buttons
                    _buildActionButtons(context, progress),

                    const SizedBox(height: 24),

                    // Credits with statement
                    _buildCredits(progress),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFarewellSection(double progress) {
    final opacity = Curves.easeOut.transform(
      ((progress - 0.0) / 0.3).clamp(0.0, 1.0),
    );

    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          Text(
            'Farewell 2025',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 32,
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'this was not very nice',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(double progress) {
    final opacity = Curves.easeOut.transform(
      ((progress - 0.25) / 0.35).clamp(0.0, 1.0),
    );
    final scale = 0.85 + 0.15 * opacity;

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    Colors.amber.shade300,
                    Colors.orange.shade400,
                    Colors.deepOrange.shade400,
                    Colors.amber.shade300,
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ).createShader(bounds);
              },
              child: const Text(
                'HAPPY NEW YEAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [
                    Colors.cyan.shade300,
                    Colors.blue.shade400,
                    Colors.purple.shade300,
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                '2026',
                style: TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'this will be MY year!',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, double progress) {
    final opacity = Curves.easeIn.transform(
      ((progress - 0.6) / 0.3).clamp(0.0, 1.0),
    );

    return Opacity(
      opacity: opacity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Replay button
          OutlinedButton.icon(
            onPressed: onReplay,
            icon: const Icon(Icons.replay, size: 20),
            label: const Text('REPLAY'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white38),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Exit button
          ElevatedButton.icon(
            onPressed: onExit,
            icon: const Icon(Icons.home, size: 20),
            label: const Text('HOME'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredits(double progress) {
    final opacity = Curves.easeIn.transform(
      ((progress - 0.75) / 0.25).clamp(0.0, 1.0),
    );

    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          // Statement about virtual fireworks
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco, color: Colors.green.shade400, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Virtual fireworks are great. Real ones suck.',
                  style: TextStyle(
                    color: Colors.green.shade300,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'A Year in Review Experience',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Built with Flutter Fragment Shaders',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '© 2025 Moinsen Development',
            style: TextStyle(
              color: Colors.white10,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for massive auto-playing fireworks
class _FireworksEndingPainter extends CustomPainter {
  _FireworksEndingPainter({
    required this.shader,
    required this.time,
    required this.intensity,
  });

  final FragmentShader shader;
  final double time;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    // Set uniforms matching fireworks.frag
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_trigger; - cycle 0->1 every ~3 seconds for continuous main fireworks
    // The shader uses: explosionTime = u_trigger * 2.5
    // So trigger cycling 0-1 gives nice paced explosions
    final triggerCycle = (time * 0.35) % 1.0;
    shader.setFloat(3, triggerCycle);
    // uniform float u_explosion_x; - animate across screen with varied positions
    shader.setFloat(4, 0.3 + 0.4 * _sin(time * 0.5));
    // uniform float u_explosion_y; - animate vertically
    shader.setFloat(5, 0.4 + 0.3 * _sin(time * 0.7 + 1.0));
    // uniform float u_hue_shift; - animate through colors
    shader.setFloat(6, (time * 0.15) % 1.0);
    // uniform float u_shake; - subtle celebration shake
    shader.setFloat(7, 0.02 * intensity);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  // Simple sine for animation
  double _sin(double x) {
    x = x % 6.283185307;
    final x2 = x * x;
    final x3 = x2 * x;
    final x5 = x3 * x2;
    final x7 = x5 * x2;
    return x - x3 / 6.0 + x5 / 120.0 - x7 / 5040.0;
  }

  @override
  bool shouldRepaint(covariant _FireworksEndingPainter oldDelegate) {
    return time != oldDelegate.time || intensity != oldDelegate.intensity;
  }
}
