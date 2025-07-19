import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../../dio_controller/DioController.dart';
import '../../orchestrator/BBAOrchestrator.dart';
import '../../stats_collectors/keypress_collector.dart';
import '../data_store.dart';

class KeypressAuthManager {
  static const int requiredEnrollments = 10;
  static const int _maxRetries = 1;

  final String userId;
  final Dio _dio = DioController().modelServer;

  static final Future<SharedPreferences> _prefsFuture = SharedPreferences.getInstance();

  KeypressAuthManager({required this.userId});

  Future<int> _getEnrollmentCount() async {
    final prefs = await _prefsFuture;
    return prefs.getInt('keypress_enroll_count_$userId') ?? 0;
  }

  Future<bool> _isEnrolled() async {
    final prefs = await _prefsFuture;
    return prefs.getBool('keypress_enrolled_$userId') ?? false;
  }

  Future<void> resetKeypressEnrollmentPrefs() async {
    final prefs = await _prefsFuture;
    await prefs.remove('keypress_enrolled_$userId');
    await prefs.remove('keypress_enroll_count_$userId');
    print("Reset keypress prefs for user: $userId");

    try {
      await _dio.post("/reset/$userId");
      print("Reset server enrollment for user: $userId");
    } catch (e) {
      print("Failed to reset server enrollment: $e");
    }
  }

  Future<bool> sendKeyPressData({
    required String uuid,
    required BuildContext context,
    int retryCount = 0,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      final store = CaptureStore();
      final data = store.toKeypressJson(uuid);
      final prefs = await _prefsFuture;
      final initialEnrolled = await _isEnrolled();

      final endpoint = initialEnrolled ? "/verify/$userId" : "/enroll/$userId";

      print("[KEYPRESS] Sending keypress data to $endpoint (Retry #$retryCount)");

      final response = await _dio
          .post(
        endpoint,
        data: data,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
        ),
      )
          .timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException("Keypress request timed out"),
      );

      print("[KEYPRESS] Response received in ${stopwatch.elapsedMilliseconds} ms");

      if (response.statusCode != 200) {
        final Map<String, dynamic> payload = response.data is Map
            ? response.data as Map<String, dynamic>
            : {};
        final detail = payload['detail'] is Map
            ? payload['detail'] as Map<String, dynamic>
            : payload;
        final errStatus = detail['status'] as String? ?? 'error';
        final errMsg = detail['message'] as String? ?? 'Unknown error';

        if ((errStatus == 'user_not_found' || errStatus == 'enrollment_incomplete') &&
            retryCount < _maxRetries) {
          final delay = Duration(milliseconds: 500 * (1 << retryCount));
          await Future.delayed(delay);
          return await sendKeyPressData(
            uuid: uuid,
            context: context,
            retryCount: retryCount + 1,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.orange),
        );
        return false;
      }

      final Map<String, dynamic> resp = response.data as Map<String, dynamic>;
      String status = resp['status'] as String? ?? '';
      if (status.isEmpty && resp['detail'] is Map) {
        status = (resp['detail'] as Map<String, dynamic>)['status'] as String? ?? '';
      }

      if (status == 'success') {
        if (!initialEnrolled) {
          final serverCount = resp['sample_count'] as int? ?? await _getEnrollmentCount();
          await prefs.setInt('keypress_enroll_count_$userId', serverCount);

          final enrolledNow = serverCount >= requiredEnrollments;
          if (enrolledNow) {
            await prefs.setBool('keypress_enrolled_$userId', true);
          }

          final msg = enrolledNow
              ? "[KEYPRESS] Enrollment complete! Ready for verification."
              : "[KEYPRESS] Enrolled sample $serverCount/$requiredEnrollments";

          LiveKeypressNotifier().update(
            userId: userId,
            enrollmentCount: serverCount,
            requiredEnrollments: requiredEnrollments,
            isEnrolled: enrolledNow,
            lastMessage: msg,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: enrolledNow ? Colors.green : Colors.blue,
            ),
          );
          return true;
        } else {
          final similarity = (resp['average_similarity'] as num?)?.toDouble() ?? 0.0;
          final verified = resp['verified'] as bool? ?? false;

          BBAOrchestrator().updateKeypressResult(similarity);

          if (verified) {
            store.clearKeyPressEvents();
          }

          final msg = verified
              ? "[KEYPRESS] Verified! Similarity: ${similarity.toStringAsFixed(3)}"
              : "[KEYPRESS] Verification failed. Similarity: ${similarity.toStringAsFixed(3)}";

          LiveKeypressNotifier().update(
            userId: userId,
            lastSimilarity: similarity,
            lastVerified: verified,
            lastMessage: msg,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: verified ? Colors.green : Colors.red,
            ),
          );
          return verified;
        }
      }

      final detailMsg = resp['message'] as String? ?? 'Unexpected response';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(detailMsg), backgroundColor: Colors.red),
      );
      return false;

    } on TimeoutException catch (e) {
      print("⏱ Timeout: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Timeout: ${e.message}"), backgroundColor: Colors.red),
      );

      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * (1 << retryCount)));
        return await sendKeyPressData(
          uuid: uuid,
          context: context,
          retryCount: retryCount + 1,
        );
      }
      return false;

    } on DioException catch (e) {
      String errorMessage = "Network error: ";
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage += "Connection timeout";
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage += "Server response timeout";
          break;
        case DioExceptionType.connectionError:
          errorMessage += "Cannot connect to server";
          break;
        default:
          errorMessage += e.message ?? "Unknown error";
      }

      print("⚠️ DioException: $errorMessage");

      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * (1 << retryCount)));
        return await sendKeyPressData(
          uuid: uuid,
          context: context,
          retryCount: retryCount + 1,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      return false;

    } catch (e) {
      print("❌ Unexpected Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send BBA data: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    } finally {
      stopwatch.stop();
      print("📊 Total request time: ${stopwatch.elapsedMilliseconds} ms");
    }
  }

  Future<Map<String, dynamic>> getEnrollmentStatus() async {
    final enrolled = await _isEnrolled();
    final count = await _getEnrollmentCount();
    return {
      'isEnrolled': enrolled,
      'enrollmentCount': count,
      'requiredEnrollments': requiredEnrollments,
      'userId': userId,
    };
  }
}
