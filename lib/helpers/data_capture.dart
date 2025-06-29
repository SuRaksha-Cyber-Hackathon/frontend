import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import 'data_store.dart';

/// Manages key press, swipe, and tap event capture.
class DataCapture {
  // ---------- KEY PRESS ----------
  static final Map<LogicalKeyboardKey, DateTime> _keyDownTimes = {};
  static LogicalKeyboardKey? _lastKey;
  static DateTime? _lastRelease;
  static const List<MapEntry<String, String>> _commonDigrams = [
    MapEntry('t', 'h'), MapEntry('h', 'e'), MapEntry('i', 'n'),
    MapEntry('e', 'r'), MapEntry('a', 'n'), MapEntry('r', 'e'),
    MapEntry('e', 'd'), MapEntry('o', 'n'), MapEntry('e', 's'),
    MapEntry('s', 't'), MapEntry('e', 'n'), MapEntry('a', 't'),
    MapEntry('y', ' '), MapEntry('h', ' '), MapEntry('d', ' ')
  ];

  /// Call on RawKeyEvent in your UI.
  static void handleKeyEvent(
      RawKeyEvent event,
      String contextScreen,
      void Function(KeyPressEvent) callback, {
        String? fieldName,
      }) {
    if (event.logicalKey.keyLabel.isEmpty) return;
    final label = event.logicalKey.keyLabel.toLowerCase();
    final code = event.logicalKey.keyId.toString();

    if (event is RawKeyDownEvent) {
      _keyDownTimes[event.logicalKey] = DateTime.now();
    } else if (event is RawKeyUpEvent) {
      final down = _keyDownTimes.remove(event.logicalKey);
      final up = DateTime.now();
      if (down != null) {
        final durationMs = up.difference(down).inMilliseconds;
        final kp = KeyPressEvent(
          keyCode: code,
          keyLabel: label,
          eventType: 'individual',
          durationMs: durationMs,
          timestamp: up,
          contextScreen: contextScreen,
          fieldName: fieldName,
        );
        callback(kp);
        CaptureStore().addKey(kp);
        print("KeyPressEvent captured: ${kp.toMap()}");

        if (_lastKey != null && _lastRelease != null) {
          final lastLabel = _lastKey!.keyLabel.toLowerCase();
          final digramDur = up.difference(_lastRelease!).inMilliseconds;
          for (var d in _commonDigrams) {
            if (lastLabel == d.key && label == d.value) {
              final dg = KeyPressEvent(
                keyCode: '${_lastKey!.keyId}-${event.logicalKey.keyId}',
                keyLabel: lastLabel + label,
                eventType: 'digram',
                durationMs: digramDur,
                timestamp: up,
                contextScreen: contextScreen,
                fieldName: fieldName,
                digramKey1: lastLabel,
                digramKey2: label,
              );
              callback(dg);
              CaptureStore().addKey(dg);
              print('Digram captured: ${dg.toMap()}');
              break;
            }
          }
        }
        _lastKey = event.logicalKey;
        _lastRelease = up;
      }
    }
  }

  // ---------- SWIPE ----------
  static Offset? _startPos;
  static DateTime? _startTime;

  static Offset? _currentPos;

  /// Call on drag start.
  static void onSwipeStart(DragStartDetails details) {
    _startPos = details.globalPosition;
    _currentPos = _startPos; // Set initial current pos
    _startTime = DateTime.now();
  }

  /// Call on drag update.
  static void onSwipeUpdate(DragUpdateDetails details) {
    _currentPos = details.globalPosition;
  }

  /// Call on drag end.
  static void onSwipeEnd(
      DragEndDetails details,
      String contextScreen,
      void Function(SwipeEvent) callback,
      ) {
    if (_startPos == null || _startTime == null || _currentPos == null) return;

    final endTime = DateTime.now();
    final durationMs = endTime.difference(_startTime!).inMilliseconds;
    final dx = _currentPos!.dx - _startPos!.dx;
    final dy = _currentPos!.dy - _startPos!.dy;
    final distance = sqrt(dx * dx + dy * dy);

    String direction = 'none';
    if (distance > 10) { // threshold to filter accidental small movements
      final angle = (atan2(dy, dx) * 180 / pi) % 360;

      if ((angle >= 315 || angle < 45)) direction = 'right';
      else if (angle >= 45 && angle < 135) direction = 'down';
      else if (angle >= 135 && angle < 225) direction = 'left';
      else if (angle >= 225 && angle < 315) direction = 'up';
    }

    final sw = SwipeEvent(
      startX: _startPos!.dx,
      startY: _startPos!.dy,
      endX: _currentPos!.dx,
      endY: _currentPos!.dy,
      distance: distance,
      durationMs: durationMs,
      timestamp: endTime,
      contextScreen: contextScreen,
      direction: direction,
    );

    callback(sw);
    CaptureStore().addSwipe(sw);
    print('SwipeEvent captured: ${sw.toMap()}');

    _startPos = null;
    _startTime = null;
    _currentPos = null;
  }


  // ---------- TAP ----------
  static Offset? _tapStart;
  static DateTime? _tapStartTime;

  /// Call on tap down (e.g. in GestureDetector).
  static void onTapDown(TapDownDetails details) {
    _tapStart = details.globalPosition;
    _tapStartTime = DateTime.now();
  }

  /// Call on tap up (e.g. in GestureDetector).
  static void onTapUp(
      TapUpDetails details,
      String contextScreen,
      void Function(TapEvent) callback,
      ) {
    if (_tapStart == null || _tapStartTime == null) return;
    final tapEnd = DateTime.now();
    final durationMs = tapEnd.difference(_tapStartTime!).inMilliseconds;

    final te = TapEvent(
      x: _tapStart!.dx,
      y: _tapStart!.dy,
      durationMs: durationMs,
      timestamp: tapEnd,
      contextScreen: contextScreen,
    );
    callback(te);
    CaptureStore().addTap(te);
    print('TapEvent captured: ${te.toMap()}');
    _tapStart = null;
    _tapStartTime = null;
  }
}
