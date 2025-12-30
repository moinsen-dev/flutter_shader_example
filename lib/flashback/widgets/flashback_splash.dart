import 'package:flutter/material.dart';

/// Opening splash screen for Flashback 2025
/// Shows "Happy New Year from Moinsen Development - Ulrich Diedrichsen"
class FlashbackSplash extends StatelessWidget {
  const FlashbackSplash({
    super.key,
    required this.animation,
    required this.onComplete,
  });

  final Animation<double> animation;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onComplete,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0A1A),
              const Color(0xFF1A0A2A),
              const Color(0xFF0A1A1A),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final progress = animation.value;

            return Stack(
              children: [
                // Animated star field background
                ...List.generate(50, (i) {
                  final seed = i * 1.234;
                  final x = (seed * 17.37) % 1.0;
                  final y = (seed * 23.71) % 1.0;
                  final size = 1.0 + (seed * 3.14) % 2.0;
                  final twinklePhase = (seed * 7.89) % 6.28;
                  final twinkle =
                      (0.5 + 0.5 * _sin(progress * 6.28 + twinklePhase)).clamp(
                        0.3,
                        1.0,
                      );

                  return Positioned(
                    left: x * MediaQuery.of(context).size.width,
                    top: y * MediaQuery.of(context).size.height,
                    child: Opacity(
                      opacity: twinkle * progress.clamp(0.0, 0.3) / 0.3,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.5),
                              blurRadius: size * 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Main content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Year badge
                        _buildYearBadge(progress),

                        const SizedBox(height: 56),

                        // Main greeting
                        _buildMainGreeting(progress),

                        const SizedBox(height: 48),

                        // From line
                        _buildFromLine(progress),

                        const SizedBox(height: 24),

                        // Author name
                        _buildAuthorName(progress),

                        const SizedBox(height: 32),

                        // AI Generation badge
                        _buildAIBadge(progress),

                        const SizedBox(height: 48),

                        // Tap to continue
                        _buildTapPrompt(progress),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildYearBadge(double progress) {
    // Slower fade-in: starts at 0%, completes at 20%
    final opacity = Curves.easeOut.transform(
      ((progress - 0.0) / 0.2).clamp(0.0, 1.0),
    );

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.6),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'FLASHBACK 2025',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 14,
            letterSpacing: 8,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  Widget _buildMainGreeting(double progress) {
    // Slower fade-in: starts at 15%, completes at 40%
    final opacity = Curves.easeOut.transform(
      ((progress - 0.15) / 0.25).clamp(0.0, 1.0),
    );
    final scale = 0.85 + 0.15 * opacity;

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.amber.shade200,
                Colors.orange.shade300,
                Colors.deepOrange.shade300,
              ],
              stops: [0.0, 0.5 + progress * 0.2, 1.0],
            ).createShader(bounds);
          },
          child: const Text(
            'Happy New Year',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              height: 1.1,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFromLine(double progress) {
    // Slower fade-in: starts at 40%, completes at 55%
    final opacity = Curves.easeIn.transform(
      ((progress - 0.4) / 0.15).clamp(0.0, 1.0),
    );

    return Opacity(
      opacity: opacity,
      child: const Text(
        'from',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 16,
          fontStyle: FontStyle.italic,
          letterSpacing: 4,
        ),
      ),
    );
  }

  Widget _buildAuthorName(double progress) {
    // Slower fade-in: starts at 50%, completes at 70%
    final opacity = Curves.easeIn.transform(
      ((progress - 0.5) / 0.2).clamp(0.0, 1.0),
    );

    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          const Text(
            'MOINSEN DEVELOPMENT',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 14,
              letterSpacing: 6,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 1, color: Colors.white24),
              const SizedBox(width: 16),
              const Text(
                'Ulrich Diedrichsen',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 40, height: 1, color: Colors.white24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIBadge(double progress) {
    // Fade in after author name: starts at 65%, completes at 80%
    final opacity = Curves.easeIn.transform(
      ((progress - 0.65) / 0.15).clamp(0.0, 1.0),
    );

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple.shade300, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Completely generated from a simple idea',
                  style: TextStyle(
                    color: Colors.purple.shade200,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Powered by Conductor Auto Mode',
                  style: TextStyle(
                    color: Colors.purple.shade300,
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTapPrompt(double progress) {
    // Slower fade-in: starts at 75%, completes at 95%
    final opacity = Curves.easeIn.transform(
      ((progress - 0.75) / 0.2).clamp(0.0, 1.0),
    );

    // Slower, gentler pulsing effect
    final pulse = 0.8 + 0.2 * _sin(progress * 8.0);

    return Opacity(
      opacity: (opacity * pulse).clamp(0.0, 1.0),
      child: const Column(
        children: [
          Icon(Icons.touch_app_outlined, color: Colors.white38, size: 28),
          SizedBox(height: 8),
          Text(
            'Tap to begin the journey',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // Simple sine approximation for animation
  double _sin(double x) {
    // Normalize to 0-2π
    x = x % 6.283185307;
    // Taylor series approximation
    final x2 = x * x;
    final x3 = x2 * x;
    final x5 = x3 * x2;
    final x7 = x5 * x2;
    return x - x3 / 6.0 + x5 / 120.0 - x7 / 5040.0;
  }
}
