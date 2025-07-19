import 'package:flutter/material.dart';

class LiveKeypressNotifier extends ChangeNotifier {
  static final LiveKeypressNotifier _instance = LiveKeypressNotifier._internal();
  factory LiveKeypressNotifier() => _instance;
  LiveKeypressNotifier._internal();

  String userId = "";
  int enrollmentCount = 0;
  int requiredEnrollments = 10;
  bool isEnrolled = false;
  bool? lastVerified;
  double lastSimilarity = -1.0;
  String lastMessage = "Waiting...";
  final List<String> _log = [];

  List<String> get log => List.unmodifiable(_log);

  void update({
    String? userId,
    int? enrollmentCount,
    int? requiredEnrollments,
    bool? isEnrolled,
    bool? lastVerified,
    double? lastSimilarity,
    String? lastMessage,
  }) {
    if (userId != null) this.userId = userId;
    if (enrollmentCount != null) this.enrollmentCount = enrollmentCount;
    if (requiredEnrollments != null) this.requiredEnrollments = requiredEnrollments;
    if (isEnrolled != null) this.isEnrolled = isEnrolled;
    if (lastVerified != null) this.lastVerified = lastVerified;
    if (lastSimilarity != null) this.lastSimilarity = lastSimilarity;
    if (lastMessage != null) {
      this.lastMessage = lastMessage;
      final timestamp = DateTime.now().toIso8601String().substring(11, 19); // HH:mm:ss
      _log.insert(0, "[$timestamp] $lastMessage");
      if (_log.length > 100) _log.removeLast();
    }

    notifyListeners();
  }
}
