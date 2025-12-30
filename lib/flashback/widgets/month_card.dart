import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../flashback_scene.dart';
import 'calendar_widget.dart';

/// Month card widget displaying event image, calendar, and text overlay
class MonthCard extends StatelessWidget {
  const MonthCard({
    super.key,
    required this.month,
    required this.calendarPulse,
    required this.textOpacity,
    this.onImageError,
  });

  final FlashbackMonth month;
  final double calendarPulse; // 0-1 for calendar highlight animation
  final double textOpacity; // 0-1 for text fade in
  final VoidCallback? onImageError;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;

    // Reserve space for bottom navigation (approx 120px)
    final bottomNavHeight = 130.0;
    // Safe area for content
    final safeTop = MediaQuery.of(context).padding.top + 16;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main content area (above bottom nav)
        Positioned(
          top: safeTop,
          left: 0,
          right: 0,
          bottom: bottomNavHeight,
          child: isPortrait
              ? _buildPortraitLayout(context)
              : _buildLandscapeLayout(context),
        ),

        // Attribution (above bottom nav)
        if (month.imageAttribution != null)
          Positioned(
            bottom: bottomNavHeight + 4,
            right: 16,
            child: AnimatedOpacity(
              opacity: textOpacity * 0.6,
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  month.imageAttribution!,
                  style: const TextStyle(fontSize: 9, color: Colors.white70),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar at top-right
          Align(
            alignment: Alignment.topRight,
            child: AnimatedOpacity(
              opacity: textOpacity,
              duration: const Duration(milliseconds: 300),
              child: TornCalendarWidget(
                month: month.month,
                year: 2025,
                highlightDay: month.highlightDay,
                primaryColor: month.primaryColor,
                highlightPulse: calendarPulse,
                width: 150,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Event image (flexible height)
          Expanded(
            flex: 3,
            child: AnimatedOpacity(
              opacity: textOpacity,
              duration: const Duration(milliseconds: 400),
              child: _buildImageContainer(),
            ),
          ),

          const SizedBox(height: 20),

          // Text overlay (flexible, takes remaining space)
          Expanded(
            flex: 2,
            child: AnimatedOpacity(
              opacity: textOpacity,
              duration: const Duration(milliseconds: 500),
              child: _buildTextOverlay(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: Image and text
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event image
                Expanded(
                  flex: 2,
                  child: AnimatedOpacity(
                    opacity: textOpacity,
                    duration: const Duration(milliseconds: 400),
                    child: _buildImageContainer(),
                  ),
                ),

                const SizedBox(height: 16),

                // Text overlay
                Expanded(
                  flex: 1,
                  child: AnimatedOpacity(
                    opacity: textOpacity,
                    duration: const Duration(milliseconds: 500),
                    child: _buildTextOverlay(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Right side: Calendar
          AnimatedOpacity(
            opacity: textOpacity,
            duration: const Duration(milliseconds: 300),
            child: TornCalendarWidget(
              month: month.month,
              year: 2025,
              highlightDay: month.highlightDay,
              primaryColor: month.primaryColor,
              highlightPulse: calendarPulse,
              width: 180,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContainer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: month.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) {
            onImageError?.call();
            return _buildErrorPlaceholder();
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: month.primaryColor.withValues(alpha: 0.3),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(month.primaryColor),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            month.primaryColor.withValues(alpha: 0.5),
            month.secondaryColor.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getMoodIcon(),
              size: 48,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 8),
            Text(
              month.monthName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMoodIcon() {
    return switch (month.mood) {
      FlashbackMood.positive => Icons.celebration,
      FlashbackMood.negative => Icons.cloud,
      FlashbackMood.neutral => Icons.balance,
    };
  }

  Widget _buildTextOverlay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Event title
          Text(
            month.eventTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: month.primaryColor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Event description - use Expanded in flexible context
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                month.eventDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
