import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/interaction_detector.dart';

/// Base class for all flashback shader painters
abstract class FlashbackPainter extends CustomPainter {
  FlashbackPainter({
    required this.shader,
    required this.time,
    required this.interaction,
    this.intensity = 1.0,
    this.transition = 1.0,
  });

  final FragmentShader shader;
  final double time;
  final InteractionData interaction;
  final double intensity;
  final double transition; // 0 = faded out, 1 = fully visible

  @override
  void paint(Canvas canvas, Size size) {
    setUniforms(size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  /// Override to set shader-specific uniforms
  void setUniforms(Size size);

  @override
  bool shouldRepaint(covariant FlashbackPainter oldDelegate) {
    return time != oldDelegate.time ||
        intensity != oldDelegate.intensity ||
        transition != oldDelegate.transition ||
        interaction != oldDelegate.interaction;
  }
}

/// Fire/ember effect for January (LA Wildfires)
/// Shader: flashback_fire.frag
class FlashbackFirePainter extends FlashbackPainter {
  FlashbackFirePainter({
    required super.shader,
    required super.time,
    required super.interaction,
    super.intensity,
    super.transition,
    this.smokeAmount = 0.5,
  });

  final double smokeAmount;

  @override
  void setUniforms(Size size) {
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_intensity;
    shader.setFloat(3, intensity);
    // uniform float u_transition;
    shader.setFloat(4, transition);
    // uniform float u_smoke;
    shader.setFloat(5, smokeAmount);
  }
}

/// Earthquake/shake effect for March (Myanmar Earthquake)
/// Shader: flashback_earthquake.frag
class FlashbackEarthquakePainter extends FlashbackPainter {
  FlashbackEarthquakePainter({
    required super.shader,
    required super.time,
    required super.interaction,
    super.intensity,
    super.transition,
    this.shakeStrength = 0.5,
  });

  final double shakeStrength;

  @override
  void setUniforms(Size size) {
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_intensity;
    shader.setFloat(3, intensity);
    // uniform float u_transition;
    shader.setFloat(4, transition);
    // uniform float u_shake;
    shader.setFloat(5, shakeStrength + interaction.shakeIntensity * 0.3);
  }
}

/// Memorial/candle glow effect for April (Pope Francis)
/// Shader: flashback_memorial.frag
class FlashbackMemorialPainter extends FlashbackPainter {
  FlashbackMemorialPainter({
    required super.shader,
    required super.time,
    required super.interaction,
    super.intensity,
    super.transition,
    this.candleFlicker = 0.3,
  });

  final double candleFlicker;

  @override
  void setUniforms(Size size) {
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_intensity;
    shader.setFloat(3, intensity);
    // uniform float u_transition;
    shader.setFloat(4, transition);
    // uniform float u_flicker;
    shader.setFloat(5, candleFlicker);
  }
}

/// Rainbow/pride effect for July (Berlin Pride)
/// Shader: flashback_rainbow.frag
class FlashbackRainbowPainter extends FlashbackPainter {
  FlashbackRainbowPainter({
    required super.shader,
    required super.time,
    required super.interaction,
    super.intensity,
    super.transition,
    this.confettiDensity = 1.0,
  });

  final double confettiDensity;

  @override
  void setUniforms(Size size) {
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_intensity;
    shader.setFloat(3, intensity);
    // uniform float u_transition;
    shader.setFloat(4, transition);
    // uniform float u_confetti;
    shader.setFloat(5, confettiDensity);
  }
}

/// Rain/flood effect for November (SE Asia Floods)
/// Shader: flashback_rain.frag
class FlashbackRainPainter extends FlashbackPainter {
  FlashbackRainPainter({
    required super.shader,
    required super.time,
    required super.interaction,
    super.intensity,
    super.transition,
    this.rainDensity = 1.0,
  });

  final double rainDensity;

  @override
  void setUniforms(Size size) {
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_intensity;
    shader.setFloat(3, intensity);
    // uniform float u_transition;
    shader.setFloat(4, transition);
    // uniform float u_rain_density;
    shader.setFloat(5, rainDensity);
  }
}

/// Tension/somber effect for neutral and negative events
/// Shader: flashback_tension.frag
/// Used for: February, June, August, October
class FlashbackTensionPainter extends FlashbackPainter {
  FlashbackTensionPainter({
    required super.shader,
    required super.time,
    required super.interaction,
    super.intensity,
    super.transition,
    this.pulseSpeed = 1.0,
    this.darkness = 0.5,
  });

  final double pulseSpeed;
  final double darkness;

  @override
  void setUniforms(Size size) {
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_intensity;
    shader.setFloat(3, intensity);
    // uniform float u_transition;
    shader.setFloat(4, transition);
    // uniform float u_pulse_speed;
    shader.setFloat(5, pulseSpeed);
    // uniform float u_darkness;
    shader.setFloat(6, darkness);
  }
}

/// Adapted Snowfall painter for December with somber tone
/// Uses existing snowfall.frag with adjusted parameters
class FlashbackSnowfallPainter extends FlashbackPainter {
  FlashbackSnowfallPainter({
    required super.shader,
    required super.time,
    required super.interaction,
    super.intensity,
    super.transition,
    this.wind = 0.0,
  });

  final double wind;

  @override
  void setUniforms(Size size) {
    // uniform vec2 u_size;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uniform float u_time;
    shader.setFloat(2, time);
    // uniform float u_intensity;
    shader.setFloat(3, intensity * 0.7); // Softer snow
    // uniform float u_wind;
    shader.setFloat(4, wind);
    // uniform float u_mouse_x;
    shader.setFloat(5, interaction.mousePosition.dx);
    // uniform float u_mouse_y; (inverted for shader coordinates)
    shader.setFloat(6, 1.0 - interaction.mousePosition.dy);
  }
}

/// Adapted Celebration painter for positive months (May, September)
/// Uses existing celebration.frag
class FlashbackCelebrationPainter extends FlashbackPainter {
  FlashbackCelebrationPainter({
    required super.shader,
    required super.time,
    required super.interaction,
    super.intensity,
    super.transition,
    this.confettiAmount = 1.0,
  });

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
    shader.setFloat(5, interaction.shakeIntensity);
  }
}
