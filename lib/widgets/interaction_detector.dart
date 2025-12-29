import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Captures all user interactions for shader effects:
/// - Mouse/touch position
/// - Taps/clicks
/// - Device shake (via accelerometer simulation with keyboard)
/// - "Hiss" simulation (hold spacebar or long press)
///
/// For a real app, you'd integrate sensors_plus for accelerometer
/// and audio/microphone packages for actual hiss detection.
class InteractionData {
  final Offset mousePosition; // Normalized 0-1
  final bool isTapped;
  final double shakeIntensity; // 0-1
  final double hissLevel; // 0-1
  final double timeSinceLastTap; // seconds

  const InteractionData({
    this.mousePosition = const Offset(0.5, 0.5),
    this.isTapped = false,
    this.shakeIntensity = 0.0,
    this.hissLevel = 0.0,
    this.timeSinceLastTap = 999.0,
  });

  InteractionData copyWith({
    Offset? mousePosition,
    bool? isTapped,
    double? shakeIntensity,
    double? hissLevel,
    double? timeSinceLastTap,
  }) {
    return InteractionData(
      mousePosition: mousePosition ?? this.mousePosition,
      isTapped: isTapped ?? this.isTapped,
      shakeIntensity: shakeIntensity ?? this.shakeIntensity,
      hissLevel: hissLevel ?? this.hissLevel,
      timeSinceLastTap: timeSinceLastTap ?? this.timeSinceLastTap,
    );
  }
}

class InteractionDetector extends StatefulWidget {
  const InteractionDetector({
    super.key,
    required this.child,
    required this.onInteraction,
  });

  final Widget child;
  final ValueChanged<InteractionData> onInteraction;

  @override
  State<InteractionDetector> createState() => _InteractionDetectorState();
}

class _InteractionDetectorState extends State<InteractionDetector> {
  Offset _mousePos = const Offset(0.5, 0.5);
  bool _isTapped = false;
  double _shakeIntensity = 0.0;
  double _hissLevel = 0.0;
  DateTime? _lastTapTime;

  Timer? _decayTimer;
  final FocusNode _focusNode = FocusNode();

  // For simulating shake with arrow keys
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  @override
  void initState() {
    super.initState();
    _startDecayTimer();
  }

  void _startDecayTimer() {
    _decayTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      bool changed = false;

      // Decay shake intensity
      if (_shakeIntensity > 0) {
        _shakeIntensity = (_shakeIntensity - 0.05).clamp(0.0, 1.0);
        changed = true;
      }

      // Decay hiss level
      if (_hissLevel > 0 && !_pressedKeys.contains(LogicalKeyboardKey.space)) {
        _hissLevel = (_hissLevel - 0.03).clamp(0.0, 1.0);
        changed = true;
      }

      // Update tap state
      if (_isTapped) {
        _isTapped = false;
        changed = true;
      }

      if (changed) {
        _notifyInteraction();
      }
    });
  }

  void _notifyInteraction() {
    final timeSinceLastTap = _lastTapTime != null
        ? DateTime.now().difference(_lastTapTime!).inMilliseconds / 1000.0
        : 999.0;

    widget.onInteraction(InteractionData(
      mousePosition: _mousePos,
      isTapped: _isTapped,
      shakeIntensity: _shakeIntensity,
      hissLevel: _hissLevel,
      timeSinceLastTap: timeSinceLastTap,
    ));
  }

  void _handlePointerMove(PointerEvent event, Size size) {
    setState(() {
      _mousePos = Offset(
        (event.localPosition.dx / size.width).clamp(0.0, 1.0),
        (event.localPosition.dy / size.height).clamp(0.0, 1.0),
      );
    });
    _notifyInteraction();
  }

  void _handleTap() {
    setState(() {
      _isTapped = true;
      _lastTapTime = DateTime.now();
    });
    _notifyInteraction();
  }

  void _handleLongPressStart() {
    // Simulate hiss with long press
    setState(() {
      _hissLevel = 1.0;
    });
    _notifyInteraction();
  }

  void _handleLongPressEnd() {
    // Hiss will decay via timer
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);

      // Spacebar = hiss
      if (event.logicalKey == LogicalKeyboardKey.space) {
        setState(() {
          _hissLevel = math.min(_hissLevel + 0.2, 1.0);
        });
        _notifyInteraction();
        return KeyEventResult.handled;
      }

      // Arrow keys = shake
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() {
          _shakeIntensity = math.min(_shakeIntensity + 0.3, 1.0);
        });
        _notifyInteraction();
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _decayTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Listener(
            onPointerMove: (e) => _handlePointerMove(e, constraints.biggest),
            onPointerHover: (e) => _handlePointerMove(e, constraints.biggest),
            child: GestureDetector(
              onTap: _handleTap,
              onLongPressStart: (_) => _handleLongPressStart(),
              onLongPressEnd: (_) => _handleLongPressEnd(),
              behavior: HitTestBehavior.opaque,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Hint overlay that shows interaction controls
class InteractionHints extends StatelessWidget {
  const InteractionHints({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Move mouse | Tap | Hold Space | Arrow keys',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hintRow('🖱️', 'Move mouse/touch for effects'),
          _hintRow('👆', 'Tap/click to trigger events'),
          _hintRow('🔊', 'Hold SPACE for "hiss" effect'),
          _hintRow('📳', 'Arrow keys to "shake"'),
        ],
      ),
    );
  }

  Widget _hintRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
