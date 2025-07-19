import 'dart:async';
import 'dart:math';
import 'package:crazy_bankers/dio_controller/DioController.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../login_screens/LoginPage.dart';
import '../models/BBAResult.dart';
import '../main.dart';

enum ThreatLevel { none, level1, level2, level3 }

class StreamStats {
  double mu = 0.0;
  double variance = 1.0;
  final double alpha;
  final List<double> _window = [];
  final int maxWindowSize;
  final int minWindowSize;

  StreamStats({
    this.alpha = 0.05,
    this.maxWindowSize = 30,  // Slightly larger window
    this.minWindowSize = 5    // Minimum samples needed
  });

  void update(double d) {
    _window.add(d);
    if (_window.length > maxWindowSize) {
      _window.removeAt(0);
    }

    // Use window-based stats when we have enough data
    if (_window.length >= minWindowSize) {
      mu = _window.reduce((a, b) => a + b) / _window.length;
      final varianceSum = _window.map((x) => pow(x - mu, 2)).reduce((a, b) => a + b);
      variance = max(varianceSum / _window.length, 0.01); // Prevent division by zero
    } else {
      // Fallback to exponential moving average
      mu = alpha * d + (1 - alpha) * mu;
      variance = alpha * pow(d - mu, 2) + (1 - alpha) * variance;
      variance = max(variance, 0.01); // Prevent division by zero
    }
  }

  double z(double d) {
    return (d - mu) / sqrt(variance);
  }

  bool get hasEnoughData => _window.length >= minWindowSize;
}

class BBAOrchestrator {
  // --- SINGLETON PATTERN SETUP ---
  // This ensures only one instance of the orchestrator ever exists.
  static final BBAOrchestrator _instance = BBAOrchestrator._internal();
  factory BBAOrchestrator() {
    return _instance;
  }

  // --- PRIVATE CONSTRUCTOR & DEBOUNCE TIMER ---
  // This constructor is called only once when the singleton instance is created.
  BBAOrchestrator._internal() {
    print('[BBAOrchestrator] Singleton instance created with a ${_evaluationDebounceDuration.inMilliseconds}ms debounce window.');
  }

  DateTime? _lastLoginTime;

  void onLoginSuccess() {
    _lastLoginTime = DateTime.now();
  }

  bool _inCooldownPeriod() {
    if (_lastLoginTime == null) return false;
    return DateTime.now().difference(_lastLoginTime!) < Duration(seconds: 30);
  }

  // --- INSTANCE VARIABLES ---
  BBAResult? _sensorResult;
  BBAResult? _keypressResult;
  BBAResult? _tapResult;

  // Models for tracking statistics over time
  final double zThresh = 2.0;  // Z-score threshold (was 1.0)
  final double rawThresh = 1.5; // Raw score threshold (was 0.8)
  final double rawThreshTap = 2.0 ;
  final double wS = 0.4, wK = 0.3, wT = 0.3; // Keep your weights

  // Replace your StreamStats with ImprovedStreamStats
  final StreamStats _sensorStats = StreamStats(alpha: 0.05);
  final StreamStats _keypressStats = StreamStats(alpha: 0.05);
  final StreamStats _tapStats = StreamStats(alpha: 0.05);

  // State variables
  final Duration maxDataAge = const Duration(minutes: 3);
  ThreatLevel _currentThreat = ThreatLevel.none;
  DateTime? _lockoutUntil;

  DateTime? _lastWarningTime;       // when the first warning was shown
  bool _warningShown = false;       // ensures banner is shown only once
  static const Duration warningGrace = Duration(seconds: 30);

  // Debounce timer to group events
  Timer? _evaluationTimer;
  final Duration _evaluationDebounceDuration = const Duration(milliseconds: 1000);

  // --- PUBLIC METHODS ---

  /// Schedules a consolidated evaluation to run after a short delay.
  /// Resets the delay if new data arrives.
  void _scheduleEvaluation() {
    _evaluationTimer?.cancel();
    _evaluationTimer = Timer(_evaluationDebounceDuration, _evaluateAndAct);
  }

  /// Called by an event source (e.g., sensor) to provide a new score.
  void updateSensorResult(double score) {
    if (_inCooldownPeriod()) {
      print("[BBA] Skipping sensor check due to cooldown.");
      return;
    }
    _sensorResult = BBAResult(score);
    print('[BBA] Updated sensor result: $score. Scheduling evaluation.');
    _scheduleEvaluation();
  }

  /// Called by an event source (e.g., keypress) to provide a new score.
  void updateKeypressResult(double rawSimilarity) {
    if (_inCooldownPeriod()) {
      print("[BBA] Skipping keypress check due to cooldown.");
      return;
    }
    _keypressResult = BBAResult(rawSimilarity);
    print('[BBA] Updated keypress result: $rawSimilarity. Scheduling evaluation.');
    _scheduleEvaluation();
  }

  /// Called by an event source (e.g., tap) to provide a new score.
  void updateTapResult(double rawScore) {
    if (_inCooldownPeriod()) {
      print("[BBA] Skipping tap check due to cooldown.");
      return;
    }
    _tapResult = BBAResult(rawScore);
    print('[BBA] Updated tap result: $rawScore. Scheduling evaluation.');
    _scheduleEvaluation();
  }

  void reset() {
    _sensorResult = null;
    _keypressResult = null;
    _tapResult = null;
    _currentThreat = ThreatLevel.none;
    _lockoutUntil = null;
    _evaluationTimer?.cancel();
    print('[BBA] Orchestrator reset');
  }

  void dispose() {
    _evaluationTimer?.cancel();
  }


  // --- INTERNAL LOGIC ---

  /// This is the core logic that runs after the debounce timer finishes.
  /// It evaluates all recent data together.
  void _evaluateAndAct() {
    print('[BBA] Debounce timer fired. Evaluating collected data...');
    final now = DateTime.now();

    if(_inCooldownPeriod()) return;

    if (_lockoutUntil != null && now.isBefore(_lockoutUntil!)) {
      print('[BBA] Currently locked out. Evaluation skipped.');
      return;
    }

    // Check data validity (same as before)
    final validSensor = _sensorResult != null && now.difference(_sensorResult!.timestamp) < maxDataAge;
    final validKeypress = _keypressResult != null && now.difference(_keypressResult!.timestamp) < maxDataAge;
    final validTap = _tapResult != null && now.difference(_tapResult!.timestamp) < maxDataAge;

    if (!validSensor && !validKeypress && !validTap) {
      print('[BBA] No recent data to evaluate.');
      return;
    }

    // Update statistics (same as before)
    if (validSensor) _sensorStats.update(_sensorResult!.score);
    if (validKeypress) _keypressStats.update(_keypressResult!.score);
    if (validTap) _tapStats.update(_tapResult!.score);

    // NEW: Calculate normalized scores for each modality
    double sensorScore = _calculateNormalizedScore(validSensor, _sensorResult, _sensorStats);
    double keypressScore = _calculateNormalizedScore(validKeypress, _keypressResult, _keypressStats);
    double tapScore = _calculateNormalizedScore(validTap, _tapResult, _tapStats);

    // NEW: Calculate weighted average
    double totalWeight = 0.0;
    double weightedSum = 0.0;

    if (validSensor) {
      weightedSum += wS * sensorScore;
      totalWeight += wS;
    }
    if (validKeypress) {
      weightedSum += wK * keypressScore;
      totalWeight += wK;
    }
    if (validTap) {
      weightedSum += wT * tapScore;
      totalWeight += wT;
    }

    double weightedScore = totalWeight > 0 ? weightedSum / totalWeight : 0.0;

    double agreementBonus = _calculateAgreementBonus(sensorScore, keypressScore, tapScore);

    bool anyHigh =
        (sensorScore >= 1.5) ||
            (keypressScore >= 1.5) ||
            (tapScore >= 2.0);

    double combinedScore = weightedScore
        + (anyHigh ? agreementBonus : 0.0);

    print('[BBA] Final combinedScore: ${combinedScore.toStringAsFixed(3)}');

    bool sensorAnom  = (_sensorResult?.score ?? 0.0) >= rawThresh;
    bool keypressAnom = (_keypressResult?.score ?? 0.0) >= rawThresh;
    bool tapAnom     = (_tapResult?.score ?? 0.0) >= rawThreshTap;

    if (keypressAnom && !sensorAnom && !tapAnom) {
      _handleThreatLevel(combinedScore);

    } else if ((sensorAnom ^ tapAnom) && !keypressAnom) {
      final now = DateTime.now();

      if (!_warningShown) {
        _warningShown = true;
        _lastWarningTime = now;
        final which = sensorAnom ? 'Sensor' : 'Tap';
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          showWarningBanner(ctx, which);
        }
        print('[BBA] First single‑modality warning shown for $which.');
        return;                       // do not escalate yet
      }

      final inGrace =
          _lastWarningTime != null && now.difference(_lastWarningTime!) < warningGrace;

      if (inGrace) {
        print('[BBA] Single‑modality anomaly within grace period → ignored.');
        return;
      } else {
        print('[BBA] Grace expired → escalate single‑modality anomaly.');
        _handleThreatLevel(combinedScore);
      }

    } else if ((sensorAnom && tapAnom) ||
        (sensorAnom && keypressAnom) ||
        (tapAnom   && keypressAnom)) {
      _handleThreatLevel(combinedScore);

    } else {
      print('[BBA] Behavior appears normal or only mild deviations.');
    }

  }

  double _calculateNormalizedScore(bool isValid, BBAResult? result, StreamStats stats) {
    if (!isValid || result == null) return 0.0;

    double rawScore = result.score;
    double normalizedScore = 0.0;

    double rawNormalized = min(rawScore / rawThresh, 1.0);

    double zNormalized = 0.0;
    if (stats.hasEnoughData) {
      double zScore = stats.z(rawScore).abs(); // Take absolute value
      zNormalized = min(zScore / zThresh, 1.0);
    }

    if (stats.hasEnoughData) {
      normalizedScore = 0.3 * rawNormalized + 0.7 * zNormalized;
    } else {
      normalizedScore = rawNormalized;
    }

    return normalizedScore;
  }

  double _calculateAgreementBonus(double sensor, double keypress, double tap) {
    List<double> scores = [sensor, keypress, tap].where((s) => s > 0.1).toList();

    if (scores.length < 2) return 0.0;

    double mean = scores.reduce((a, b) => a + b) / scores.length;
    double variance = scores.map((s) => pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length;
    double stdDev = sqrt(variance);

    double agreementBonus = 0.0;
    if (mean > 0.5 && stdDev < 0.2) {
      agreementBonus = 0.3 * (1.0 - stdDev / 0.2);
    }

    return agreementBonus;
  }

  void _handleThreatLevel(double score) async {
    print('[BBA] Handling threat level for score: $score');
    final context = navigatorKey.currentContext;
    if (context == null) {
      _showInternalFeedback("Context unavailable for navigation", Colors.orange);
      return;
    }

    if (score >= 0.5) {
      await _showAnomalyDialog(context, score);
    } else {
      return;
    }

    if (score >= 1.2) {
      _currentThreat = ThreatLevel.level3;
      _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
      showWarningBanner(context, 'Highly Malicious Activity Detected');
      await _handleSevereAnomaly(context);
    } else if (score >= 0.8) {
      _currentThreat = ThreatLevel.level2;
      _showInternalFeedback("🔐 Moderate anomaly. OTP required.", Colors.red);
      await _handleModerateAnomaly(context);
    } else if (score >= 0.5) {
      _currentThreat = ThreatLevel.level1;
      _showInternalFeedback("❌ Mild anomaly! Please re-login.", Colors.red);
      await _handleMildAnomaly(context);
    }
  }

  String _threatExplanation(double score) {
    if (score >= 1.2) return "Severe anomaly. Lockout + OTP verification required.";
    if (score >= 0.8) return "Moderate anomaly. OTP verification required.";
    if (score >= 0.5) return "Mild anomaly. Re-login required.";
    return "Normal behavior detected.";
  }

  void _showInternalFeedback(String message, Color color) {
    print('[BBA Orchestrator] $message');
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    }
  }

  void showWarningBanner(BuildContext context, String message, {Duration duration = const Duration(seconds: 5)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '⚠️ WARNING: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.yellowAccent,
                ),
              ),
              TextSpan(
                text: '$message anomaly detected. ',
                style: TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: 'Further anomalies will result in app lockout.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.indigo,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }


  Future<void> _showAnomalyDialog(BuildContext context, double score) async {
    final sensorScore = _sensorResult?.score ?? 0.0;
    final keypressScore = _keypressResult?.score ?? 0.0;
    final tapScore = _tapResult?.score ?? 0.0;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final size = MediaQuery.of(context).size;
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Center(
            child: Text("Behavioral Anomaly", style: GoogleFonts.ubuntu(
              fontSize: size.height * 0.04,
              fontWeight: FontWeight.w600,
              color: Colors.indigo,
            )),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(color: Colors.indigo),
              _buildScoreRow("Sensor", sensorScore, size),
              _buildScoreRow("Keypress", keypressScore, size),
              _buildScoreRow("Tap", tapScore, size),
              const Divider(color: Colors.indigo),
              const SizedBox(height: 8),
              Text("Overall Score: ${score.toStringAsFixed(2)}", style: GoogleFonts.ubuntu(
                fontSize: size.height * 0.026,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              )),
              const SizedBox(height: 4),
              Text(_threatExplanation(score), style: GoogleFonts.ubuntu(
                fontSize: size.height * 0.022,
                color: Colors.black54,
              ), textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: GoogleFonts.ubuntu(
                fontSize: size.height * 0.022,
                fontWeight: FontWeight.w500,
                color: Colors.indigo,
              )),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSevereAnomaly(BuildContext context) async {
    await _showLoadingDialog(context);
    final otpSent = await _sendOtpToEmail();
    Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog

    if (otpSent) {
      await _navigateToLoginPage(context, lockUntil: _lockoutUntil, otpRequired: true);
    }
  }

  Future<void> _handleModerateAnomaly(BuildContext context) async {
    await _showLoadingDialog(context);
    final otpSent = await _sendOtpToEmail();
    Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog

    if (otpSent) {
      await _navigateToLoginPage(context, otpRequired: true);
    }
  }

  Future<void> _handleMildAnomaly(BuildContext context) async {
    await _navigateToLoginPage(context);
  }

  Future<void> _navigateToLoginPage(BuildContext context, {DateTime? lockUntil, bool otpRequired = false}) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(
          builder: (_) => LoginPage(lockUntil: lockUntil, otpRequired: otpRequired, anomalyCleared: true),
        ),
            (route) => false,
      );
    });
  }

  Future<void> _showLoadingDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.indigo, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                CircularProgressIndicator(color: Colors.indigo),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    "Sending OTP...",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "A server-side anomaly was detected.\n\nPlease log in again and enter the OTP sent to your email.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, double value, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: GoogleFonts.ubuntu(
              fontSize: size.height * 0.024,
              color: Colors.black87,
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: GoogleFonts.ubuntu(
              fontSize: size.height * 0.024,
              fontWeight: FontWeight.w600,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _sendOtpToEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (email == null) {
        _showInternalFeedback("User email not found!", Colors.orange);
        return false;
      }

      final dio = DioController().authServer;

      final response = await dio.post(
        "/send-otp",
        data: {"email": email},
      );

      if (response.statusCode == 200) {
        _showInternalFeedback("📧 OTP sent to $email", Colors.green);
        return true;
      } else {
        _showInternalFeedback("❌ Failed to send OTP", Colors.red);
        return false;
      }
    } catch (e) {
      _showInternalFeedback("❌ Error sending OTP: $e", Colors.red);
      return false;
    }
  }

  void _clearResults() {
    _sensorResult   = null;
    _keypressResult = null;
    _tapResult      = null;
  }

  // Getters
  ThreatLevel get currentThreatLevel => _currentThreat;
  BBAResult? get sensorResult => _sensorResult;
  BBAResult? get keypressResult => _keypressResult;
  BBAResult? get tapResult => _tapResult;
  Duration get maxDataAgeValue => maxDataAge;
}