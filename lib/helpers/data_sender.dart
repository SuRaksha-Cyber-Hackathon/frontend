import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../orchestrator/BBAOrchestrator.dart';
import 'data_store.dart';

class DataSenderService {
  static final DataSenderService _instance = DataSenderService._internal();
  factory DataSenderService() => _instance;
  DataSenderService._internal();

  Timer? _timer;
  final Dio _dio = Dio();
  final String baseUrl = 'https://6qp6wdgn-8000.inc1.devtunnels.ms';

  String? _uuid;
  bool _isEnrolled = false; // Track enrollment state

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

    print("Restored windowCount=$_windowCount, startTime=$_startTime");
  }

  // Check with server if user embedding exists
  Future<void> _checkEnrollmentStatus() async {
    try {
      final response = await _dio.get('$baseUrl/check_user/$_uuid');
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

      final data = store.toJson(_uuid!);

      // Track input windows
      _windowCount++;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_windowCountKey, _windowCount);


      final Duration elapsed = DateTime.now().difference(_startTime!);
      final bool inInitialPhase =
          _windowCount <= maxInitialWindows || elapsed < maxInitialDuration;

      final endpoint = inInitialPhase ? '/receive' : '/authenticate';
      final url = '$baseUrl$endpoint';

      try {
        final response = await _dio.post(
          url,
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        print('Raw response: ${response.data}');

        if (response.statusCode == 200 && response.data['status'] == 'stored' || response.data['status'] == 'ok') {
          store.clear();
          print('Server accepted data for $endpoint');

          // Only increment window count if enrollment succeeded
          if (endpoint == '/receive' && response.data['status'] == 'stored') {
            _windowCount++;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(_windowCountKey, _windowCount);
          }

          // Set enrolled flag once initial phase ends and all windows are accepted
          if (inInitialPhase && endpoint == '/receive' && _windowCount >= maxInitialWindows) {
            _isEnrolled = true;
            print('Initial phase complete. Marking as enrolled.');

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_enrolledKey, true);
          }


          final ctx = navigatorKey.currentContext;
          String message = "Data sent successfully ($endpoint)";
          Color backgroundColor = Colors.green[600]!;

          if (endpoint == '/authenticate') {
            final bool isAuth = response.data['auth'] ?? false;
            final double score = response.data['score'] ?? -1.0;

            BBAOrchestrator().updateSensorResult(score);

            if (!isAuth) {
              message = "[SENSOR] Anomaly Detected! Score: $score";
              backgroundColor = Colors.red[600]!;
            } else {
              message = "[SENSOR] Authenticated. Score: $score";
              backgroundColor = Colors.green[600]!;
            }
          }

          if (ctx != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: backgroundColor,
                duration: Duration(seconds: 3),
              ),
            );
          }

        } else {
          print('❌ Server rejected $endpoint with message: ${response.data}');
        }
      } catch (e) {
        print('❌ Exception sending to $endpoint: $e');
      }
    });
  }


  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
