import 'package:flutter/material.dart';
import '../flashback_scene.dart';

/// All 12 months of events for Flashback 2025
/// Images from Unsplash (free for commercial use, no attribution required)
const List<FlashbackMonth> flashback2025Events = [
  // January - Los Angeles Wildfires
  FlashbackMonth(
    month: 1,
    monthName: 'January',
    highlightDay: 7,
    eventTitle: 'Los Angeles Wildfires',
    eventDescription:
        'Catastrophic wildfires devastated Pacific Palisades, becoming the costliest natural disaster in US history. Hurricane-force winds fueled the inferno, claiming 29 lives and destroying over 18,000 structures.',
    mood: FlashbackMood.negative,
    imageUrl:
        'https://images.unsplash.com/photo-1602980360498-a64b89cb4be8?w=1280&q=80',
    imageAttribution: 'Unsplash / Malachi Brooks',
    shaderAsset: 'shaders/flashback_fire.frag',
    primaryColor: Color(0xFFFF4500), // Orange-red
    secondaryColor: Color(0xFF8B0000), // Dark red
    displayDuration: Duration(seconds: 16),
  ),

  // February - German Federal Election
  FlashbackMonth(
    month: 2,
    monthName: 'February',
    highlightDay: 23,
    eventTitle: 'German Federal Election',
    eventDescription:
        'Germany held its snap federal election with record 82.5% turnout - the highest since 1987. CDU/CSU won with 28.6%, while the far-right AfD made historic gains at 20%, reshaping the political landscape.',
    mood: FlashbackMood.neutral,
    imageUrl:
        'https://images.unsplash.com/photo-1551871812-10ecc21ffa2f?w=1280&q=80',
    imageAttribution: 'Unsplash / Claudio Schwarz',
    shaderAsset: 'shaders/flashback_tension.frag',
    primaryColor: Color(0xFF1A1A2E), // Dark blue
    secondaryColor: Color(0xFFDDDDDD), // Light gray
    displayDuration: Duration(seconds: 14),
  ),

  // March - Myanmar Earthquake
  FlashbackMonth(
    month: 3,
    monthName: 'March',
    highlightDay: 28,
    eventTitle: 'Myanmar Earthquake',
    eventDescription:
        'A devastating 7.7 magnitude earthquake struck Myanmar near Sagaing and Mandalay, killing approximately 4,500 people. It became one of the deadliest natural disasters of 2025, causing massive humanitarian crisis.',
    mood: FlashbackMood.negative,
    imageUrl:
        'https://images.unsplash.com/photo-1547683905-f686c993aae5?w=1280&q=80',
    imageAttribution: 'Unsplash / NOAA',
    shaderAsset: 'shaders/flashback_earthquake.frag',
    primaryColor: Color(0xFF8B4513), // Saddle brown
    secondaryColor: Color(0xFF696969), // Dim gray
    displayDuration: Duration(seconds: 14),
  ),

  // April - Pope Francis Dies
  FlashbackMonth(
    month: 4,
    monthName: 'April',
    highlightDay: 21,
    eventTitle: 'Pope Francis Dies',
    eventDescription:
        'Pope Francis died at age 88 on Easter Monday at the Vatican. Over 250,000 people viewed his body at St. Peter\'s Basilica. His 12-year pontificate ended, setting the stage for a historic conclave.',
    mood: FlashbackMood.negative,
    imageUrl:
        'https://images.unsplash.com/photo-1531572753322-ad063cecc140?w=1280&q=80',
    imageAttribution: 'Unsplash / Simone Savoldi',
    shaderAsset: 'shaders/flashback_memorial.frag',
    primaryColor: Color(0xFFFFD700), // Gold
    secondaryColor: Color(0xFF2F2F2F), // Dark gray
    displayDuration: Duration(seconds: 16),
  ),

  // May - Merz Becomes Chancellor / Pope Leo XIV
  FlashbackMonth(
    month: 5,
    monthName: 'May',
    highlightDay: 6,
    eventTitle: 'New Beginnings',
    eventDescription:
        'Friedrich Merz became Germany\'s Chancellor after a historic second-round vote. Days later, Cardinal Robert Prevost was elected Pope Leo XIV - the first American pope ever - bringing hope after Pope Francis\'s death.',
    mood: FlashbackMood.positive,
    imageUrl:
        'https://images.unsplash.com/photo-1577717903315-1691ae25ab3f?w=1280&q=80',
    imageAttribution: 'Unsplash / Christian Lue',
    shaderAsset: 'shaders/celebration.frag',
    primaryColor: Color(0xFFFFD700), // Gold
    secondaryColor: Color(0xFFFFFFFF), // White
    displayDuration: Duration(seconds: 14),
  ),

  // June - Nations League Tragedy
  FlashbackMonth(
    month: 6,
    monthName: 'June',
    highlightDay: 8,
    eventTitle: 'Nations League Tragedy',
    eventDescription:
        'During the UEFA Nations League Final at Munich\'s Allianz Arena between Portugal and Spain, a spectator tragically died. The incident cast a shadow over what was meant to be a celebration of European football.',
    mood: FlashbackMood.negative,
    imageUrl:
        'https://images.unsplash.com/photo-1489944440615-453fc2b6a9a9?w=1280&q=80',
    imageAttribution: 'Unsplash / Saurav Rastogi',
    shaderAsset: 'shaders/flashback_tension.frag',
    primaryColor: Color(0xFF1E3A5F), // Dark stadium blue
    secondaryColor: Color(0xFF404040), // Dark gray
    displayDuration: Duration(seconds: 12),
  ),

  // July - Berlin Pride
  FlashbackMonth(
    month: 7,
    monthName: 'July',
    highlightDay: 25,
    eventTitle: 'Berlin Pride',
    eventDescription:
        'Berlin hosted one of Europe\'s largest LGBTQ+ celebrations with over 350,000 visitors. Christopher Street Day Parade brought color, joy, and unity to the streets, a moment of celebration amid a turbulent year.',
    mood: FlashbackMood.positive,
    imageUrl:
        'https://images.unsplash.com/photo-1561327926-3e21ca09a2f5?w=1280&q=80',
    imageAttribution: 'Unsplash / Mercedes Mehling',
    shaderAsset: 'shaders/flashback_rainbow.frag',
    primaryColor: Color(0xFFFF69B4), // Hot pink
    secondaryColor: Color(0xFF9400D3), // Purple
    displayDuration: Duration(seconds: 14),
  ),

  // August - Railway Closure
  FlashbackMonth(
    month: 8,
    monthName: 'August',
    highlightDay: 1,
    eventTitle: 'Railway Disruption',
    eventDescription:
        'Germany\'s main railway link between Berlin and Hamburg closed for major renovations until April 2026, adding 45 minutes to journeys and disrupting millions. Deutsche Bahn faced mounting criticism over infrastructure.',
    mood: FlashbackMood.negative,
    imageUrl:
        'https://images.unsplash.com/photo-1474487548417-781cb71495f3?w=1280&q=80',
    imageAttribution: 'Unsplash / Markus Winkler',
    shaderAsset: 'shaders/flashback_tension.frag',
    primaryColor: Color(0xFFDC143C), // Deutsche Bahn red
    secondaryColor: Color(0xFF2F2F2F), // Dark gray
    displayDuration: Duration(seconds: 12),
  ),

  // September - Oktoberfest
  FlashbackMonth(
    month: 9,
    monthName: 'September',
    highlightDay: 20,
    eventTitle: 'Oktoberfest Opens',
    eventDescription:
        'Despite earlier bomb threats, Munich\'s Oktoberfest opened to millions of visitors. Germany\'s basketball team won EuroBasket 2025, defeating Turkey 88-83 - a sporting triumph that lifted spirits.',
    mood: FlashbackMood.positive,
    imageUrl:
        'https://images.unsplash.com/photo-1505489435671-80b5c3b49241?w=1280&q=80',
    imageAttribution: 'Unsplash / Louis Hansel',
    shaderAsset: 'shaders/celebration.frag',
    primaryColor: Color(0xFF0066CC), // Bavarian blue
    secondaryColor: Color(0xFFFFD700), // Gold
    displayDuration: Duration(seconds: 14),
  ),

  // October - Munich Airport Chaos
  FlashbackMonth(
    month: 10,
    monthName: 'October',
    highlightDay: 3,
    eventTitle: 'German Unity Day Chaos',
    eventDescription:
        'On German Unity Day, thousands of passengers were stranded at Munich Airport due to drone sightings that forced flight disruptions. The chaos marked a challenging holiday for travelers across the country.',
    mood: FlashbackMood.negative,
    imageUrl:
        'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=1280&q=80',
    imageAttribution: 'Unsplash / Ashim D\'Silva',
    shaderAsset: 'shaders/flashback_tension.frag',
    primaryColor: Color(0xFFFF8C00), // Warning orange
    secondaryColor: Color(0xFF4A4A4A), // Gray
    displayDuration: Duration(seconds: 12),
  ),

  // November - Berlin Wall Anniversary / Floods
  FlashbackMonth(
    month: 11,
    monthName: 'November',
    highlightDay: 9,
    eventTitle: 'Remembrance & Floods',
    eventDescription:
        'Germany commemorated November 9th - the fall of the Berlin Wall and the Kristallnacht pogrom. Meanwhile, devastating floods killed over 1,800 across Southeast Asia, a sobering reminder of climate\'s toll.',
    mood: FlashbackMood.negative,
    imageUrl:
        'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=1280&q=80',
    imageAttribution: 'Unsplash / Adam Vradenburg',
    shaderAsset: 'shaders/flashback_rain.frag',
    primaryColor: Color(0xFF4682B4), // Steel blue
    secondaryColor: Color(0xFF2F4F4F), // Dark slate
    displayDuration: Duration(seconds: 16),
  ),

  // December - Ukraine Peace Talks
  FlashbackMonth(
    month: 12,
    monthName: 'December',
    highlightDay: 28,
    eventTitle: 'Hope for Peace',
    eventDescription:
        'As Christmas approached, Trump hosted Zelenskyy with both leaders claiming to be "closer than ever" to peace in Ukraine after nearly 4 years of war. A glimmer of hope emerged as the year drew to a close.',
    mood: FlashbackMood.negative, // Still somber overall
    imageUrl:
        'https://images.unsplash.com/photo-1512389142860-9c449e58a543?w=1280&q=80',
    imageAttribution: 'Unsplash / Markus Spiske',
    shaderAsset: 'shaders/snowfall.frag',
    primaryColor: Color(0xFFE8E8E8), // Snow white
    secondaryColor: Color(0xFF1E3A5F), // Winter blue
    displayDuration: Duration(seconds: 16),
  ),
];

/// Get a FlashbackMonth by its month number (1-12)
FlashbackMonth? getFlashbackMonth(int month) {
  if (month < 1 || month > 12) return null;
  return flashback2025Events[month - 1];
}

/// Get a FlashbackMonth by its scene
FlashbackMonth? getFlashbackMonthByScene(FlashbackScene scene) {
  final monthIndex = scene.monthIndex;
  if (monthIndex == null) return null;
  return getFlashbackMonth(monthIndex);
}
