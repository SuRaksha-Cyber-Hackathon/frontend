import 'package:flutter/cupertino.dart';

class LiveDataNotifier extends ChangeNotifier {
  static final LiveDataNotifier _instance = LiveDataNotifier._internal();
  factory LiveDataNotifier() => _instance;
  LiveDataNotifier._internal();

  String? uuid;
  bool isEnrolled = false;
  int windowCount = 0;
  DateTime? startTime;
  String lastMessage = "Waiting...";
  double lastScore = -1.0;
  bool isInInitialPhase = true;
  final List<String> _log = [];

  List<String> get log => List.unmodifiable(_log); // Expose as read-only

  void update({
    String? uuid,
    bool? isEnrolled,
    int? windowCount,
    DateTime? startTime,
    String? lastMessage,
    double? lastScore,
    bool? isInInitialPhase,
  }) {
    this.uuid = uuid ?? this.uuid;
    this.isEnrolled = isEnrolled ?? this.isEnrolled;
    this.windowCount = windowCount ?? this.windowCount;
    this.startTime = startTime ?? this.startTime;

    if (lastMessage != null) {
      this.lastMessage = lastMessage;
      final timestamp = DateTime.now().toIso8601String().substring(11, 19); // HH:MM:SS
      _log.insert(0, "[$timestamp] $lastMessage");

      // Limit log size (e.g., 100 entries)
      if (_log.length > 100) _log.removeLast();
    }

    this.lastScore = lastScore ?? this.lastScore;
    this.isInInitialPhase = isInInitialPhase ?? this.isInInitialPhase;

    notifyListeners();
  }
}
