import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/SiameseModel.dart';
import '../../orchestrator/BBAOrchestrator.dart';

class TapAuthenticationManager {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
  GlobalKey<ScaffoldMessengerState>();

  static final TapAuthenticationManager _instance =
  TapAuthenticationManager._internal();
  factory TapAuthenticationManager() => _instance;
  TapAuthenticationManager._internal();

  final TapAuthenticator _authenticator = TapAuthenticator();

  static const int maxEnrollTaps = 50;
  static const int maxEnrollSeconds = 30;
  static const int progressInterval = 25; // show every 25 taps
  static const int rollingWindowSize = 40;
  static const String _scoresKey = "auth_score_buffer";

  final List<double> _lastScores = [];
  int _tapCount = 0;
  int _verifyCount = 0;
  double _lastMedianScore = 0.0;
  Timer? _enrollTimer;
  bool _isEnrolled = false;
  final List<List<double>> _enrollTapEvents = [];

  DateTime? _lastAnomalyTime;

  static const Duration anomalyCooldown = Duration(minutes: 2);

  String _enrollFlagKey(String userId) => "is_enrolled_$userId";

  Future<void> loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final storedScores = prefs.getStringList(_scoresKey);
    if (storedScores != null) {
      _lastScores
        ..clear()
        ..addAll(
            storedScores.map((s) => double.tryParse(s)).whereType<double>());
    }
  }

  Future<void> saveScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _scoresKey, _lastScores.map((e) => e.toString()).toList());
  }

  void addScore(double score) async {
    _lastScores.add(score);
    if (_lastScores.length > rollingWindowSize) {
      _lastScores.removeAt(0);
    }
    await saveScores();
  }

  bool isAnomalous(double threshold) {
    if (_lastScores.length < rollingWindowSize) {
      _lastMedianScore = 0.0;
      return false;
    }

    final now = DateTime.now();
    if (_lastAnomalyTime != null &&
        now.difference(_lastAnomalyTime!) < anomalyCooldown) {
      return false;
    }

    final sortedScores = List<double>.from(_lastScores)..sort();
    final median = sortedScores[sortedScores.length ~/ 2];
    _lastMedianScore = median;

    final highCount = _lastScores.where((s) => s > threshold).length;
    final highFraction = highCount / _lastScores.length;

    final detected = median > threshold && highFraction > 0.7;

    if (detected) {
      _lastAnomalyTime = now;
    }

    return detected;
  }

  Future<void> initializeForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    _isEnrolled = prefs.getBool(_enrollFlagKey(userId)) ?? false;
  }

  void startEnrollment(String userId) async {
    if (_isEnrolled) {
      debugPrint("[TAP] Enrollment already completed for $userId");
      return;
    }

    _tapCount = 0;
    _enrollTapEvents.clear();
    _enrollTimer?.cancel();

    _enrollTimer = Timer(Duration(seconds: maxEnrollSeconds), () async {
      await _completeEnrollment(userId);
    });

    debugPrint("[TAP] Started enrollment timer for $userId");
  }

  Future<bool> processTap(String userId, List<double> tapEvent) async {
    if (!_isEnrolled) {
      _tapCount++;
      _enrollTapEvents.add(tapEvent);

      if (_tapCount % progressInterval == 0 || _tapCount >= maxEnrollTaps) {
        final msg = _tapCount >= maxEnrollTaps
            ? " [TAP] Reached $maxEnrollTaps taps—completing enrollment..."
            : "[TAP] Enrollment: $_tapCount/$maxEnrollTaps taps";

        messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.blue),
        );
      }

      if (_tapCount >= maxEnrollTaps) {
        _enrollTimer?.cancel();
        await _completeEnrollment(userId);
      }

      return true;
    } else {
      _verifyCount++;
      final score = await _authenticator.getAuthScore(userId, tapEvent);
      if (score != null) addScore(score);

      if (_verifyCount % progressInterval == 0) {
        const threshold = 1.8;
        final sorted = List<double>.from(_lastScores)..sort();
        final medianScore = sorted.isNotEmpty
            ? sorted[sorted.length ~/ 2]
            : 0.0;

        final anomaly = isAnomalous(threshold); // still run detection logic


        print(
            "Verification #$_verifyCount → median score: ${medianScore.toStringAsFixed(3)}, threshold: $threshold");

        final msg = anomaly
            ? "[TAP SCORE] Median : ${medianScore.toStringAsFixed(3)}"
            : "[TAP SCORE] Median : ${medianScore.toStringAsFixed(3)}";

        TapAuthenticationManager.messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: anomaly ? Colors.red : Colors.green,
          ),
        );

        if (!anomaly) {
          await clearScores();
        }

        BBAOrchestrator().updateTapResult(medianScore);
      }
      return false;
    }
  }

  Future<void> _completeEnrollment(String userId) async {
    if (_isEnrolled) {
      debugPrint("[TAP] Enrollment already completed — skipping _completeEnrollment");
      return;
    }

    if (_enrollTapEvents.isNotEmpty) {
      await _authenticator.enrollUser(userId, _enrollTapEvents);
      _isEnrolled = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enrollFlagKey(userId), true);
      _enrollTapEvents.clear();

      messengerKey.currentState?.showSnackBar(
        SnackBar(
            content: Text("[TAP] Enrollment complete!"),
            backgroundColor: Colors.green),
      );

      debugPrint("[TAP] Enrollment completed and persisted for $userId");
    }
  }

  Future<void> clearScores() async {
    _lastScores.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scoresKey);
  }

  Future<void> resetEnrollment(String userId) async {
    _enrollTimer?.cancel();
    _tapCount = 0;
    _verifyCount = 0;
    _enrollTapEvents.clear();
    _isEnrolled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enrollFlagKey(userId), false);

    messengerKey.currentState?.showSnackBar(
      SnackBar(
          content: Text("[TAP] Enrollment reset."), backgroundColor: Colors.orange),
    );
  }

  bool get isEnrolled => _isEnrolled;
}
