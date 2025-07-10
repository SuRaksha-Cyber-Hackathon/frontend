import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'data_store.dart';

class DataSenderService {
  static final DataSenderService _instance = DataSenderService._internal();
  factory DataSenderService() => _instance;
  DataSenderService._internal();

  Timer? _timer;
  final Dio _dio = Dio();
  final String baseUrl = 'http://localhost:8000';

  String? _uuid;
  bool _isEnrolled = false; // Track enrollment state

  String? get uuid => _uuid;
  bool get isEnrolled => _isEnrolled;

  void initialize(String uuid) async {
    _uuid = uuid;
    await _checkEnrollmentStatus();
  }

  // Check with server if user embedding exists
  Future<void> _checkEnrollmentStatus() async {
    try {
      final response = await _dio.get('$baseUrl/check_user/$_uuid');
      if (response.statusCode == 200) {
        _isEnrolled = response.data['exists'] ?? false;
        print('Enrollment status for $_uuid: $_isEnrolled');
      }
    } catch (e) {
      print('Error checking enrollment: $e');
      _isEnrolled = false; // default to false if error
    }
  }

  void startForegroundSending() {
    if (_uuid == null) {
      print('❌ UUID not initialized. Call initialize(uuid) first.');
      return;
    }

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

      final endpoint = _isEnrolled ? '/authenticate' : '/receive';
      final url = '$baseUrl$endpoint';

      try {
        final response = await _dio.post(
          url,
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        print('🔁 Raw response: ${response.data}'); // <-- Debug print

        if (response.statusCode == 200) {
          store.clear();
          print('✅ Data sent to $endpoint and cleared');

          final ctx = navigatorKey.currentContext;

          String message = "✅ Data sent successfully ($endpoint)";
          Color backgroundColor = Colors.green[600]!;

          if (!_isEnrolled && endpoint == '/receive') {
            _isEnrolled = true;
            print('User is now enrolled.');
          }

          // ✅ Authentication result
          if (endpoint == '/authenticate') {
            final bool isAuth = response.data['auth'] ?? false;
            final double score = response.data['score'] ?? -1.0;

            if (!isAuth) {
              message = "🚨 Anomaly Detected! Score: $score";
              backgroundColor = Colors.red[600]!;
            } else {
              message = "✅ Authenticated. Score: $score";
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
          print('❌ Send to $endpoint failed: ${response.statusCode}');
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
