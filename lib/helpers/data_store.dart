// lib/helpers/capture_store.dart

import 'dart:convert';
import '../models/models.dart';

class CaptureStore {
  // Singleton
  static final CaptureStore _instance = CaptureStore._internal();
  factory CaptureStore() => _instance;
  CaptureStore._internal();

  // Storage lists
  final List<KeyPressEvent> _keyEvents = [];
  final List<SwipeEvent> _swipeEvents = [];
  final List<TapEvent> _tapEvents = [];

  // Add events
  void addKey(KeyPressEvent e)    => _keyEvents.add(e);
  void addSwipe(SwipeEvent e)     => _swipeEvents.add(e);
  void addTap(TapEvent e)         => _tapEvents.add(e);

  // Export to JSON
  Map<String, dynamic> toJson() => {
    'keypress_events': _keyEvents.map((e) => e.toMap()).toList(),
    'swipe_events':    _swipeEvents.map((e) => e.toMap()).toList(),
    'tap_events':      _tapEvents.map((e) => e.toMap()).toList(),
  };

  // Get encoded JSON string
  String toJsonString() => jsonEncode(toJson());

  // Clear all stored data
  void clear() {
    _keyEvents.clear();
    _swipeEvents.clear();
    _tapEvents.clear();
  }

  // Accessors
  List<KeyPressEvent> get keyEvents   => List.unmodifiable(_keyEvents);
  List<SwipeEvent>   get swipeEvents  => List.unmodifiable(_swipeEvents);
  List<TapEvent>     get tapEvents    => List.unmodifiable(_tapEvents);
}
