import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/SiameseModel.dart';

class TapAuthenticationManager {
  static final TapAuthenticationManager _instance = TapAuthenticationManager._internal();
  factory TapAuthenticationManager() => _instance;
  TapAuthenticationManager._internal();

  final TapAuthenticator _authenticator = TapAuthenticator();

  static const int maxEnrollTaps = 50;
  static const int maxEnrollSeconds = 30;

  static const int rollingWindowSize = 25;
  static const String _scoresKey = "auth_score_buffer";

  final List<double> _lastScores = [];

  int _tapCount = 0;
  late DateTime _enrollStartTime;
  Timer? _enrollTimer;
  bool _isEnrolled = false;
  final List<List<double>> _enrollTapEvents = [];

  // Persisted key pattern
  String _enrollFlagKey(String userId) => "is_enrolled_$userId";

  Future<void> loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final storedScores = prefs.getStringList(_scoresKey);
    if (storedScores != null) {
      _lastScores.clear();
      for (var s in storedScores) {
        final val = double.tryParse(s);
        if (val != null) _lastScores.add(val);
      }
      print("Loaded ${_lastScores.length} auth scores from storage");
    }
  }

  Future<void> saveScores() async {
    final prefs = await SharedPreferences.getInstance();
    final strScores = _lastScores.map((e) => e.toString()).toList();
    await prefs.setStringList(_scoresKey, strScores);
    print("Saved ${_lastScores.length} auth scores to storage");
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
      return false;
    }

    final averageScore = _lastScores.reduce((a, b) => a + b) / _lastScores.length;
    final majorityCount = _lastScores.where((score) => score > threshold).length;
    final majorityIsAnomaly = majorityCount > (rollingWindowSize / 2);

    return averageScore > threshold && majorityIsAnomaly;
  }


  Future<void> initializeForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    _isEnrolled = prefs.getBool(_enrollFlagKey(userId)) ?? false;
  }

  void startEnrollment(String userId) {
    _tapCount = 0;
    _enrollTapEvents.clear();
    _enrollStartTime = DateTime.now();
    _isEnrolled = false;

    _enrollTimer?.cancel();
    _enrollTimer = Timer(Duration(seconds: maxEnrollSeconds), () async {
      await _completeEnrollment(userId);
    });
  }

  Future<bool> processTap(String userId, List<double> tapEvent) async {
    if (!_isEnrolled) {
      _tapCount++;
      _enrollTapEvents.add(tapEvent);

      if (_tapCount >= maxEnrollTaps) {
        _enrollTimer?.cancel();
        await _completeEnrollment(userId);
      }
      return true;
    } else {
      final score = await _authenticator.getAuthScore(userId, tapEvent);
      if (score != null) {
        addScore(score);
      }
      return false;
    }
  }


  Future<void> _completeEnrollment(String userId) async {
    if (_enrollTapEvents.isNotEmpty) {
      await _authenticator.enrollUser(userId, _enrollTapEvents);
      _isEnrolled = true;

      // Persist enrollment flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enrollFlagKey(userId), true);

      print("✅ User $userId enrolled with ${_enrollTapEvents.length} taps.");
      _enrollTapEvents.clear();
    }
  }

  void resetEnrollment(String userId) async {
    _enrollTimer?.cancel();
    _tapCount = 0;
    _enrollTapEvents.clear();
    _isEnrolled = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enrollFlagKey(userId), false);
  }

  bool get isEnrolled => _isEnrolled;
}
