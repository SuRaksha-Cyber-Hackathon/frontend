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
  final String endpointUrl = 'https://zhmx7x9x-8000.inc1.devtunnels.ms/receive';

  String? _uuid;

  String? get uuid => _uuid;

  void initialize(String uuid) {
    _uuid = uuid;
  }

  void startForegroundSending() {
    if (_uuid == null) {
      print('❌ UUID not initialized. Call initialize(uuid) first.');
      return;
    }

    _timer ??= Timer.periodic(Duration(seconds: 30), (_) async {
      final store = CaptureStore();

      // Early exit if there's no data
      if (store.keyEvents.isEmpty &&
          store.swipeEvents.isEmpty &&
          store.tapEvents.isEmpty &&
          store.sensorEvents.isEmpty &&
          store.scrollEvents.isEmpty) {
        return;
      }

      final data = store.toJson(_uuid!);

      try {
        final response = await _dio.post(
          endpointUrl,
          data: data,
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        if (response.statusCode == 200) {
          store.clear();
          print('✅ Foreground: Data sent and cleared');

          final ctx = navigatorKey.currentContext;

          if (ctx != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text("✅ Data sent successfully"),
                backgroundColor: Colors.green[600],
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        else {
          print('❌ Foreground send failed: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Foreground exception: $e');
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
