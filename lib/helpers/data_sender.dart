import 'dart:async';
import 'package:dio/dio.dart';
import 'data_store.dart';

class DataSenderService {
  static final DataSenderService _instance = DataSenderService._internal();
  factory DataSenderService() => _instance;
  DataSenderService._internal();

  Timer? _timer;
  final Dio _dio = Dio();
  final String endpointUrl = 'https://0053f9a7-2c80-4361-bea3-022f5947ded2-00-2ul5vqqzvvafq.sisko.replit.dev/receive';

  String? _uuid;

  /// Call this once with the assigned persistent UUID
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
        } else {
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
