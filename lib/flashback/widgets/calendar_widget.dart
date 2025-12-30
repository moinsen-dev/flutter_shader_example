import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A torn calendar page widget for the Flashback 2025 feature
/// Displays a month with a highlighted day in a paper-like aesthetic
class TornCalendarWidget extends StatelessWidget {
  const TornCalendarWidget({
    super.key,
    required this.month,
    required this.year,
    required this.highlightDay,
    required this.primaryColor,
    this.highlightPulse = 0.0,
    this.width = 200,
  });

  final int month;
  final int year;
  final int highlightDay;
  final Color primaryColor;
  final double highlightPulse; // 0-1 for pulsing animation
  final double width;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _dayAbbreviations = [
    'Su',
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
  ];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TornEdgePainter(primaryColor: primaryColor),
      child: Container(
        width: width,
        padding: const EdgeInsets.only(
          left: 12,
          right: 12,
          top: 16,
          bottom: 24, // Extra space for torn edge
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFFBE6), // Cream paper
              const Color(0xFFF5F0DC), // Slightly darker
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildDayHeaders(),
            const SizedBox(height: 4),
            _buildDaysGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      '${_monthNames[month - 1]} $year',
      style: TextStyle(
        fontFamily: 'serif',
        fontSize: width * 0.09,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2C2C2C),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildDayHeaders() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _dayAbbreviations.map((day) {
        return Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: width * 0.045,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF666666),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysGrid() {
    final daysInMonth = _getDaysInMonth(year, month);
    final firstDayOfWeek = DateTime(year, month, 1).weekday % 7;

    final List<Widget> rows = [];
    List<Widget> currentRow = [];

    // Empty cells before first day
    for (int i = 0; i < firstDayOfWeek; i++) {
      currentRow.add(_buildDayCell(null));
    }

    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      currentRow.add(_buildDayCell(day));

      if (currentRow.length == 7) {
        rows.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: currentRow,
          ),
        );
        currentRow = [];
      }
    }

    // Fill remaining cells
    while (currentRow.length < 7 && currentRow.isNotEmpty) {
      currentRow.add(_buildDayCell(null));
    }
    if (currentRow.isNotEmpty) {
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: currentRow,
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildDayCell(int? day) {
    final isHighlighted = day == highlightDay;
    final cellSize = width / 9; // Slightly smaller to prevent overflow

    if (day == null) {
      return Expanded(child: SizedBox(height: cellSize));
    }

    // Animated highlight effect
    final glowIntensity = isHighlighted ? 0.5 + highlightPulse * 0.5 : 0.0;
    final scale = isHighlighted ? 1.0 + highlightPulse * 0.1 : 1.0;

    return Expanded(
      child: SizedBox(
        height: cellSize,
        child: Center(
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: cellSize * 0.85,
              height: cellSize * 0.85,
              decoration: isHighlighted
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: 0.15),
                      border: Border.all(
                        color: primaryColor,
                        width: 2 + highlightPulse,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: glowIntensity),
                          blurRadius: 8 * glowIntensity,
                          spreadRadius: 2 * glowIntensity,
                        ),
                      ],
                    )
                  : null,
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: width * 0.055,
                  fontWeight: isHighlighted
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isHighlighted ? primaryColor : const Color(0xFF333333),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _getDaysInMonth(int year, int month) {
    if (month == 12) {
      return DateTime(year + 1, 1, 0).day;
    }
    return DateTime(year, month + 1, 0).day;
  }
}

/// Custom painter for torn paper edge effect
class _TornEdgePainter extends CustomPainter {
  _TornEdgePainter({required this.primaryColor});

  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw torn bottom edge
    final path = Path();
    path.moveTo(0, size.height);

    // Create jagged torn edge
    final random = math.Random(42); // Fixed seed for consistency
    double x = 0;
    const segments = 20;
    final segmentWidth = size.width / segments;

    while (x < size.width) {
      final tearHeight = 5 + random.nextDouble() * 10;
      final midX = x + segmentWidth / 2;

      path.lineTo(x, size.height - tearHeight * 0.3);
      path.quadraticBezierTo(
        midX,
        size.height - tearHeight,
        x + segmentWidth,
        size.height - tearHeight * 0.5,
      );

      x += segmentWidth;
    }

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    // Draw shadow for depth
    canvas.drawShadow(path, Colors.black, 4, true);
  }

  @override
  bool shouldRepaint(covariant _TornEdgePainter oldDelegate) {
    return primaryColor != oldDelegate.primaryColor;
  }
}
