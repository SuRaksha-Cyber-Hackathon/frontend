// import 'dart:async';
// import 'package:dio/dio.dart';
// import 'data_store.dart';
//
// class DataSenderService {
//   static final DataSenderService _instance = DataSenderService._internal();
//   factory DataSenderService() => _instance;
//   DataSenderService._internal();
//
//   Timer? _timer;
//   final Dio _dio = Dio();
//   final String endpointUrl = 'http://0.0.0.0:8000/receive';
//
//   void startForegroundSending() {
//     _timer ??= Timer.periodic(Duration(seconds: 30), (_) async {
//       final store = CaptureStore();
//       final data = store.toJson();
//
//       if (store.keyEvents.isEmpty && store.swipeEvents.isEmpty) return;
//
//       try {
//         final response = await _dio.post(
//           endpointUrl,
//           data: data,
//           options: Options(headers: {'Content-Type': 'application/json'}),
//         );
//
//         if (response.statusCode == 200) {
//           store.clear();
//           print('✅ Foreground: Data sent and cleared');
//         } else {
//           print('❌ Foreground send failed: ${response.statusCode}');
//         }
//       } catch (e) {
//         print('❌ Foreground exception: $e');
//       }
//     });
//   }
//
//   void stop() {
//     _timer?.cancel();
//     _timer = null;
//   }
// }
