import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/interaction_detector.dart';

/// Base class for all shader scene painters
abstract class ShaderScenePainter extends CustomPainter {
  ShaderScenePainter({
    required this.shader,
    required this.time,
    required this.interaction,
  });

  final FragmentShader shader;
  final double time;
  final InteractionData interaction;

  @override
  void paint(Canvas canvas, Size size) {
    setUniforms(size);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  /// Override to set shader-specific uniforms
  void setUniforms(Size size);

  @override
  bool shouldRepaint(covariant ShaderScenePainter oldDelegate) {
    return time != oldDelegate.time || interaction != oldDelegate.interaction;
  }
}

/// Snowfall scene - Christmas vibes
class SnowfallPainter extends ShaderScenePainter {
  SnowfallPainter({
    required super.shader,
    required super.time,
    required super.interaction,
    this.intensity = 1.0,
    this.wind = 0.0,
  });

  final double intensity;
  final double wind;

  @override
  void setUniforms(Size size) {
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_intensity;
    shader.setFloat(3, intensity);
    // uniform float u_wind;
    shader.setFloat(4, wind + interaction.shakeIntensity * 2.0 - 1.0);
    // uniform float u_mouse_x;
    shader.setFloat(5, interaction.mousePosition.dx);
    // uniform float u_mouse_y; (inverted for shader coordinates)
    shader.setFloat(6, 1.0 - interaction.mousePosition.dy);
  }
}

/// Fireworks scene - New Year celebration
class FireworksPainter extends ShaderScenePainter {
  FireworksPainter({
    required super.shader,
    required super.time,
    required super.interaction,
    this.triggerProgress = 0.0,
    this.explosionX = 0.5,
    this.explosionY = 0.7,
    this.hueShift = 0.0,
  });

  final double triggerProgress;
  final double explosionX;
  final double explosionY;
  final double hueShift;

  @override
  void setUniforms(Size size) {
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_trigger;
    shader.setFloat(3, triggerProgress);
    // uniform float u_explosion_x;
    shader.setFloat(4, explosionX);
    // uniform float u_explosion_y;
    shader.setFloat(5, explosionY);
    // uniform float u_hue_shift;
    shader.setFloat(6, hueShift);
    // uniform float u_shake;
    shader.setFloat(7, interaction.shakeIntensity);
  }
}

/// Countdown scene - building tension
class CountdownPainter extends ShaderScenePainter {
  CountdownPainter({
    required super.shader,
    required super.time,
    required super.interaction,
    this.countdown = 10.0,
    this.glowPulse = 0.0,
  });

  final double countdown;
  final double glowPulse;

  @override
  void setUniforms(Size size) {
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_countdown;
    shader.setFloat(3, countdown);
    // uniform float u_glow;
    shader.setFloat(4, glowPulse + interaction.hissLevel * 0.5);
    // uniform float u_mouse_x;
    shader.setFloat(5, interaction.mousePosition.dx);
    // uniform float u_mouse_y; (inverted for shader coordinates)
    shader.setFloat(6, 1.0 - interaction.mousePosition.dy);
  }
}

/// Aurora scene - magical Northern Lights
class AuroraPainter extends ShaderScenePainter {
  AuroraPainter({
    required super.shader,
    required super.time,
    required super.interaction,
    this.intensity = 1.0,
    this.speed = 1.0,
  });

  final double intensity;
  final double speed;

  @override
  void setUniforms(Size size) {
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_intensity;
    shader.setFloat(3, intensity + interaction.hissLevel * 0.5);
    // uniform float u_speed;
    shader.setFloat(4, speed);
    // uniform float u_hiss;
    shader.setFloat(5, interaction.hissLevel);
  }
}

/// Celebration scene - 2025 party!
class CelebrationPainter extends ShaderScenePainter {
  CelebrationPainter({
    required super.shader,
    required super.time,
    required super.interaction,
    this.intensity = 1.0,
    this.confettiAmount = 1.0,
  });

  final double intensity;
  final double confettiAmount;

  @override
  void setUniforms(Size size) {
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_intensity;
    shader.setFloat(3, intensity);
    // uniform float u_confetti;
    shader.setFloat(4, confettiAmount);
    // uniform float u_bass;
    shader.setFloat(5, interaction.shakeIntensity + interaction.hissLevel * 0.5);
  }
}

/// Matrix scene - nerdy developer style
class MatrixPainter extends ShaderScenePainter {
  MatrixPainter({
    required super.shader,
    required super.time,
    required super.interaction,
    this.revealProgress = 0.0,
  });

  final double revealProgress;

  @override
  void setUniforms(Size size) {
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_mouse_x;
    shader.setFloat(3, interaction.mousePosition.dx);
    // uniform float u_mouse_y; (inverted for shader coordinates)
    shader.setFloat(4, 1.0 - interaction.mousePosition.dy);
    // uniform float u_reveal;
    shader.setFloat(5, revealProgress);
  }
}

/// Cyberpunk ending scene - "Happy Coding 2026" finale
class CyberpunkEndingPainter extends ShaderScenePainter {
  CyberpunkEndingPainter({
    required super.shader,
    required super.time,
    required super.interaction,
    this.glitchIntensity = 0.3,
    this.neonPulse = 1.0,
  });

  final double glitchIntensity;
  final double neonPulse;

  @override
  void setUniforms(Size size) {
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_glitch;
    shader.setFloat(3, glitchIntensity + interaction.shakeIntensity * 0.5);
    // uniform float u_neon_pulse;
    shader.setFloat(4, neonPulse);
  }
}
