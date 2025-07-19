import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dio_controller/DioController.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../stats_collectors/sensor_collector.dart';
import '../../orchestrator/BBAOrchestrator.dart';
import 'SensorFeatureExtractor.dart';
import '../data_store.dart';

class DataSenderService {
  static final DataSenderService _instance = DataSenderService._internal();
  factory DataSenderService() => _instance;
  DataSenderService._internal();

  Timer? _timer;
  final Dio _dio = DioController().modelServer ;

  String? _uuid;
  bool _isEnrolled = false;

  String? get uuid => _uuid;
  bool get isEnrolled => _isEnrolled;

  static const String _windowCountKey = "sensor_window_count";
  static const String _startTimeKey = "sensor_start_time";
  static const String _enrolledKey = "sensor_enrolled_flag";


  int _windowCount = 0;
  DateTime? _startTime;
  static const int maxInitialWindows = 10;
  static const Duration maxInitialDuration = Duration(minutes: 5);


  void initialize(String uuid) async {
    _uuid = uuid;
    await _checkEnrollmentStatus();
    await _loadPersistentState();
  }

  Future<void> _loadPersistentState() async {
    final prefs = await SharedPreferences.getInstance();
    _windowCount = prefs.getInt(_windowCountKey) ?? 0;
    _isEnrolled = prefs.getBool(_enrolledKey) ?? false;


    final startTimestamp = prefs.getInt(_startTimeKey);
    if (startTimestamp != null) {
      _startTime = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
    } else {
      _startTime = DateTime.now();
      await prefs.setInt(_startTimeKey, _startTime!.millisecondsSinceEpoch);
    }

    LiveDataNotifier().update(
      uuid: _uuid,
      isEnrolled: _isEnrolled,
      windowCount: _windowCount,
      startTime: _startTime,
    );
  }

  Future<void> _checkEnrollmentStatus() async {
    try {
      final response = await _dio.get('/check_user/$_uuid');
      if (response.statusCode == 200) {
        _isEnrolled = response.data['exists'] ?? false;
        print('Enrollment status for $_uuid: $_isEnrolled');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_enrolledKey, _isEnrolled);
      }
    } catch (e) {
      print('Error checking enrollment: $e');
    }
  }


  void startForegroundSending() {
    if (_uuid == null) {
      print('❌ UUID not initialized. Call initialize(uuid) first.');
      return;
    }

    _startTime ??= DateTime.now();

    _timer ??= Timer.periodic(Duration(seconds: 30), (_) async {
      final store = CaptureStore();

      if (store.keyEvents.isEmpty &&
          store.swipeEvents.isEmpty &&
          store.tapEvents.isEmpty &&
          store.sensorEvents.isEmpty &&
          store.scrollEvents.isEmpty) {
        return;
      }

      final sensorEvents = List<SensorEvent>.from(store.sensorEvents);
      final tapEvents = List<TapEvent>.from(store.tapEvents);
      final swipeEvents = List<SwipeEvent>.from(store.swipeEvents);
      final keyEvents = List<KeyPressEvent>.from(store.keyEvents);

      final windows = extractSensorFeatureWindows(
        sensorEvents: sensorEvents,
        tapEvents: tapEvents,
        swipeEvents: swipeEvents,
        keyEvents: keyEvents,
        winSize: 10,
        stepSize: 5,
      );
      if (windows.isEmpty) return;

      _windowCount++;
      await SharedPreferences.getInstance()
          .then((p) => p.setInt(_windowCountKey, _windowCount));
      final elapsed = DateTime.now().difference(_startTime!);
      final inInitialPhase =
          _windowCount <= maxInitialWindows || elapsed < maxInitialDuration;
      final endpoint = inInitialPhase ? '/receive' : '/authenticate';

      final payload = {'id': _uuid, 'windows': windows};
      try {
        final response = await _dio.post(endpoint, data: payload);
        if (response.statusCode == 200) {
          final status = response.data['status'];
          final auth   = response.data['auth'] ?? false;
          final score  = (response.data['score'] ?? -1.0).toDouble();

          if (status == 'stored' || status == 'ok' || auth) {
            store.clear();
          }

          if (inInitialPhase && status == 'stored' && _windowCount >= maxInitialWindows) {
            _isEnrolled = true;
            await SharedPreferences.getInstance()
                .then((p) => p.setBool(_enrolledKey, true));
          }

          if(endpoint == '/authenticate') {
            LiveDataNotifier().update(
              windowCount: _windowCount,
              isEnrolled: _isEnrolled,
              isInInitialPhase: inInitialPhase,
              lastScore: score,
              lastMessage: status == 'anomaly' || !auth
                  ? "[SENSOR] Anomaly Detected! Score: $score"
                  : "[SENSOR] Authenticated. Score: $score",
            );

            BBAOrchestrator().updateSensorResult(score);
          }

          final ctx = navigatorKey.currentContext;
          if (ctx != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(LiveDataNotifier().lastMessage),
                backgroundColor:
                (status == 'anomaly' || !auth) ? Colors.red[600] : Colors.green[600],
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          print('Server rejected $endpoint: ${response.data}');
        }
      } catch (e) {
        print('Exception sending to $endpoint: $e');
      }
    });
  }


  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
