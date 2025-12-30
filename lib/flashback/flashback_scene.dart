import 'package:flutter/material.dart';

/// Mood classification for shader selection
enum FlashbackMood {
  positive, // sparkles, celebration, rainbow
  negative, // fire, earthquake, thunder, rain, somber
  neutral, // tension/anticipation
}

/// Scene types in the flashback journey
enum FlashbackScene {
  splash,
  january,
  february,
  march,
  april,
  may,
  june,
  july,
  august,
  september,
  october,
  november,
  december,
  ending;

  /// Get the month index (1-12) for monthly scenes, null for splash/ending
  int? get monthIndex {
    return switch (this) {
      FlashbackScene.january => 1,
      FlashbackScene.february => 2,
      FlashbackScene.march => 3,
      FlashbackScene.april => 4,
      FlashbackScene.may => 5,
      FlashbackScene.june => 6,
      FlashbackScene.july => 7,
      FlashbackScene.august => 8,
      FlashbackScene.september => 9,
      FlashbackScene.october => 10,
      FlashbackScene.november => 11,
      FlashbackScene.december => 12,
      _ => null,
    };
  }

  /// Get the next scene in the journey
  FlashbackScene? get next {
    final values = FlashbackScene.values;
    final currentIndex = values.indexOf(this);
    if (currentIndex < values.length - 1) {
      return values[currentIndex + 1];
    }
    return null;
  }

  /// Get the previous scene in the journey
  FlashbackScene? get previous {
    final values = FlashbackScene.values;
    final currentIndex = values.indexOf(this);
    if (currentIndex > 0) {
      return values[currentIndex - 1];
    }
    return null;
  }

  /// Check if this scene is a month (not splash or ending)
  bool get isMonth => monthIndex != null;
}

/// Data model for a month's event
class FlashbackMonth {
  const FlashbackMonth({
    required this.month,
    required this.monthName,
    required this.highlightDay,
    required this.eventTitle,
    required this.eventDescription,
    required this.mood,
    required this.imageUrl,
    required this.shaderAsset,
    required this.primaryColor,
    required this.secondaryColor,
    this.imageAttribution,
    this.displayDuration = const Duration(seconds: 7),
  });

  /// Month number (1-12)
  final int month;

  /// Full month name
  final String monthName;

  /// Day to highlight on the calendar
  final int highlightDay;

  /// Short event title
  final String eventTitle;

  /// 2-3 sentence description for storytelling
  final String eventDescription;

  /// Mood determines shader selection
  final FlashbackMood mood;

  /// URL for event image (Wikimedia Commons)
  final String imageUrl;

  /// Path to the shader asset
  final String shaderAsset;

  /// Primary theme color for the month
  final Color primaryColor;

  /// Secondary/accent color
  final Color secondaryColor;

  /// Image attribution (for CC images)
  final String? imageAttribution;

  /// How long to display this month
  final Duration displayDuration;

  /// Get the FlashbackScene for this month
  FlashbackScene get scene {
    return switch (month) {
      1 => FlashbackScene.january,
      2 => FlashbackScene.february,
      3 => FlashbackScene.march,
      4 => FlashbackScene.april,
      5 => FlashbackScene.may,
      6 => FlashbackScene.june,
      7 => FlashbackScene.july,
      8 => FlashbackScene.august,
      9 => FlashbackScene.september,
      10 => FlashbackScene.october,
      11 => FlashbackScene.november,
      12 => FlashbackScene.december,
      _ => throw ArgumentError('Invalid month: $month'),
    };
  }
}
