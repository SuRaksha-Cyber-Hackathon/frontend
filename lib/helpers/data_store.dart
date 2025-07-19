import 'dart:convert';
import '../models/models.dart';

class CaptureStore {
  static final CaptureStore _instance = CaptureStore._internal();
  factory CaptureStore() => _instance;
  CaptureStore._internal();

  final List<KeyPressEvent> _keyEvents = [];
  final List<SwipeEvent> _swipeEvents = [];
  final List<TapEvent> _tapEvents = [];
  final List<SensorEvent> _sensorEvents = [];
  final List<ScrollEvent> _scrollEvents = [];

  void addKey(KeyPressEvent e)     => _keyEvents.add(e);
  void addSwipe(SwipeEvent e)      => _swipeEvents.add(e);
  void addTap(TapEvent e)          => _tapEvents.add(e);
  void addSensor(SensorEvent e)    => _sensorEvents.add(e);
  void addScroll(ScrollEvent e)    => _scrollEvents.add(e);

  Map<String, dynamic> toJson(String uuid) => {
    'id': uuid,
    'events': {
      'keypress_events': _keyEvents.map((e) => e.toMap()).toList(),
      'swipe_events': _swipeEvents.map((e) => e.toMap()).toList(),
      'tap_events': _tapEvents.map((e) => e.toMap()).toList(),
      'sensor_events': _sensorEvents.map((e) => e.toMap()).toList(),
      'scroll_events': _scrollEvents.map((e) => e.toMap()).toList(),
      }
    };

  Map<String, dynamic> toKeypressJson(String uuid) => {
    'id': uuid,
    'events': {
      'keypress_events': _keyEvents.map((e) => e.toMap()).toList(),
    },
  };

  String toKeypressJsonString(String uuid) => jsonEncode(toKeypressJson(uuid));

  String toJsonString(String uuid) => jsonEncode(toJson(uuid));

  void clear() {
    _keyEvents.clear();
    _swipeEvents.clear();
    _tapEvents.clear();
    _sensorEvents.clear();
    _scrollEvents.clear();
  }

  void clearKeyPressEvents() {
    _keyEvents.clear();
  }

  List<KeyPressEvent> get keyEvents    => List.unmodifiable(_keyEvents);
  List<SwipeEvent>    get swipeEvents  => List.unmodifiable(_swipeEvents);
  List<TapEvent>      get tapEvents    => List.unmodifiable(_tapEvents);
  List<SensorEvent>   get sensorEvents => List.unmodifiable(_sensorEvents);
  List<ScrollEvent>   get scrollEvents => List.unmodifiable(_scrollEvents);
}
