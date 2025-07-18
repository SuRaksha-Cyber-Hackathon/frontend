import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
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

  StreamStats({this.alpha = 0.05, this.maxWindowSize = 20}); // Slower adaptation

  void update(double d) {
    _window.add(d);
    if (_window.length > maxWindowSize) {
      _window.removeAt(0);
    }
    if (_window.length >= 3) {
      mu = _window.reduce((a, b) => a + b) / _window.length;
      final varianceSum = _window.map((x) => pow(x - mu, 2)).reduce((a, b) => a + b);
      variance = varianceSum / _window.length;
    } else {
      mu = alpha * d + (1 - alpha) * mu;
      variance = alpha * pow(d - mu, 2) + (1 - alpha) * variance;
    }
    print('[StreamStats] Updated stats: mu=${mu.toStringAsFixed(3)}, var=${variance.toStringAsFixed(3)}');
  }

  double z(double d) {
    final zVal = (d - mu) / sqrt(variance + 1e-6);
    print('[StreamStats] Computed z-score: raw=${d.toStringAsFixed(3)}, z=${zVal.toStringAsFixed(3)}');
    return zVal;
  }
  bool get hasEnoughData => _window.length >= 3;
}

class BBAOrchestrator {

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
  BBAResult? _sensorResult;
  BBAResult? _keypressResult;
  BBAResult? _tapResult;

  final StreamStats _sensorStats;
  final StreamStats _keypressStats;
  final StreamStats _tapStats;

  final double zThresh;
  final double rawThresh;
  final double wS, wK, wT;

  final Duration maxDataAge = Duration(minutes: 3);
  bool _keypressTriggered = false;
  ThreatLevel _currentThreat = ThreatLevel.none;
  DateTime? _lockoutUntil;

  // Batch accumulation
  final List<double> _batchScores = [];
  late final Timer _batchTimer;

  BBAOrchestrator({
    double alpha = 0.05,
    this.zThresh = 1.0,
    this.rawThresh = 0.8,
    this.wS = 0.4,
    this.wK = 0.3,
    this.wT = 0.3,
  })  : _sensorStats = StreamStats(alpha: alpha),
        _keypressStats = StreamStats(alpha: alpha),
        _tapStats = StreamStats(alpha: alpha) {
    _batchTimer = Timer.periodic(Duration(seconds: 30), (_) => _processBatch());
    print('[BBAOrchestrator] Initialized with batching every 30s');
  }

  void _evaluateIfReady() {
    final now = DateTime.now();
    print('[BBA] _evaluateIfReady called at $now');

    if (_lockoutUntil != null && now.isBefore(_lockoutUntil!)) {
      print('[BBA] Currently locked out until ${_lockoutUntil}');
      return;
    }

    final validSensor = _sensorResult != null && now.difference(_sensorResult!.timestamp) < maxDataAge;
    final validKeypress = _keypressResult != null && now.difference(_keypressResult!.timestamp) < maxDataAge;
    final validTap = _tapResult != null && now.difference(_tapResult!.timestamp) < maxDataAge;
    print('[BBA] Data validity: sensor=$validSensor, keypress=$validKeypress, tap=$validTap');

    if (!validSensor && !validKeypress && !validTap) return;

    if (validSensor) {
      print('[BBA] Updating sensor stats with score=${_sensorResult!.score}');
      _sensorStats.update(_sensorResult!.score);
    }
    if (validKeypress) {
      print('[BBA] Updating keypress stats with score=${_keypressResult!.score}');
      _keypressStats.update(_keypressResult!.score);
    }
    if (validTap) {
      print('[BBA] Updating tap stats with score=${_tapResult!.score}');
      _tapStats.update(_tapResult!.score);
    }

    final rawS = validSensor ? _sensorResult!.score : 0.0;
    final rawK = validKeypress ? _keypressResult!.score : 0.0;
    final rawT = validTap ? _tapResult!.score : 0.0;
    print('[BBA] Raw scores: sensor=${rawS.toStringAsFixed(3)}, keypress=${rawK.toStringAsFixed(3)}, tap=${rawT.toStringAsFixed(3)}');

    final zS = validSensor && _sensorStats.hasEnoughData ? _sensorStats.z(_sensorResult!.score) : 0.0;
    final zK = validKeypress && _keypressStats.hasEnoughData ? _keypressStats.z(_keypressResult!.score) : 0.0;
    final zT = validTap && _tapStats.hasEnoughData ? _tapStats.z(_tapResult!.score) : 0.0;

    final int zVotes = [zS, zK, zT].where((z) => z >= zThresh).length;
    final int rawVotes = [rawS, rawK, rawT].where((r) => r >= rawThresh).length;
    final double zSum = wS * zS + wK * zK + wT * zT;
    final double rawSum = wS * rawS + wK * rawK + wT * rawT;
    final double score = max(max(zSum, rawSum), max(zVotes.toDouble(), rawVotes.toDouble()));
    print('[BBA] Computed components: zVotes=$zVotes, rawVotes=$rawVotes, zSum=${zSum.toStringAsFixed(3)}, rawSum=${rawSum.toStringAsFixed(3)}, combined score=${score.toStringAsFixed(3)}');

    _batchScores.add(score);
    print('[BBA] Added to batchScores (size=${_batchScores.length})');
    _keypressTriggered = false;
  }

  void _processBatch() {
    print('[BBA] _processBatch triggered, batch size=${_batchScores.length}');
    if (_batchScores.isEmpty) return;
    final avgScore = _batchScores.reduce((a, b) => a + b) / _batchScores.length;
    final isAnomalous = avgScore > 0.7;
    final msg = isAnomalous
        ? "⚠️ BATCH Anomaly! Avg Score: ${avgScore.toStringAsFixed(2)}"
        : "✅ BATCH Normal. Avg Score: ${avgScore.toStringAsFixed(2)}";
    print('[BBA] Batch result: $msg');

    _showInternalFeedback(msg, isAnomalous ? Colors.red : Colors.green);
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isAnomalous ? Colors.red : Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
    if (isAnomalous) {
      print('[BBA] Triggering threat level handling from batch');
      _handleThreatLevel(avgScore);
    }
    _batchScores.clear();
  }

  void _handleThreatLevel(double score) async {
    print('[BBA] _handleThreatLevel called with score=${score.toStringAsFixed(3)}');
    final context = navigatorKey.currentContext;
    if (context == null) {
      _showInternalFeedback("Context unavailable for navigation", Colors.orange);
      return;
    }

    final sensorScore = _sensorResult?.score ?? 0.0;
    final keypressScore = _keypressResult?.score ?? 0.0;
    final tapScore = _tapResult?.score ?? 0.0;

    print('[BBA] Handling threat level for score: $score');

    // Show detailed anomaly dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final size = MediaQuery.of(context).size;
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: Center(
            child: Text(
              "Behavioral Anomaly",
              style: GoogleFonts.ubuntu(
                fontSize: size.height * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
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
              Text(
                "Overall Score: ${score.toStringAsFixed(2)}",
                style: GoogleFonts.ubuntu(
                  fontSize: size.height * 0.026,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _threatExplanation(score),
                style: GoogleFonts.ubuntu(
                  fontSize: size.height * 0.022,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "OK",
                style: GoogleFonts.ubuntu(
                  fontSize: size.height * 0.022,
                  fontWeight: FontWeight.w500,
                  color: Colors.indigo,
                ),
              ),
            ),
          ],
        );
      },
    );

    // Apply threat-based handling with adjusted thresholds
    if (score >= 1.0) {
      _currentThreat = ThreatLevel.level3;
      _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
      _showInternalFeedback("🚫 Severe anomaly! Locked for 30s.", Colors.red);
      await _handleSevereAnomaly(context);
    } else if (score >= 0.8) {
      _currentThreat = ThreatLevel.level2;
      _showInternalFeedback("🔐 Anomaly detected. OTP required.", Colors.red);
      await _handleModerateAnomaly(context);
    } else if (score >= 0.6){
      _currentThreat = ThreatLevel.level1;
      _showInternalFeedback("❌ Anomaly! Please re-login.", Colors.red);
      await _handleMildAnomaly(context);
    }
  }

  Future<void> _handleSevereAnomaly(BuildContext context) async {
    await _showLoadingDialog(context);
    final otpSent = await _sendOtpToEmail();
    Navigator.of(context).pop();

    if (otpSent) {
      await _navigateToLoginPage(context, lockUntil: _lockoutUntil, otpRequired: true);
    }
  }

  Future<void> _handleModerateAnomaly(BuildContext context) async {
    await _showLoadingDialog(context);
    final otpSent = await _sendOtpToEmail();
    Navigator.of(context).pop();

    if (otpSent) {
      await _navigateToLoginPage(context, otpRequired: true);
    }
  }

  Future<void> _handleMildAnomaly(BuildContext context) async {
    await _navigateToLoginPage(context);
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

  Future<void> _navigateToLoginPage(BuildContext context, {DateTime? lockUntil, bool otpRequired = false}) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(
          builder: (_) => LoginPage(lockUntil: lockUntil, otpRequired: otpRequired),
        ),
            (route) => false,
      );
    });
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

  String _threatExplanation(double score) {
    if (score >= 1.5) return "Severe anomaly. Lockout + OTP verification required.";
    if (score >= 1.0) return "Moderate anomaly. OTP verification required.";
    return "Mild anomaly. Re-login required.";
  }

  Future<bool> _sendOtpToEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (email == null) {
        _showInternalFeedback("User email not found!", Colors.orange);
        return false;
      }

      final response = await Dio().post(
        "https://zhmx7x9x-5000.inc1.devtunnels.ms/send-otp",
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

  void updateSensorResult(double score) {
    _sensorResult = BBAResult(score);
    print('[BBA] Updated sensor result: $score');
    _evaluateIfReady();
  }

  void updateKeypressResult(double rawSimilarity) {
    _keypressResult = BBAResult(rawSimilarity);
    _keypressTriggered = true;
    print('[BBA] Updated keypress result: $rawSimilarity');
    _evaluateIfReady();
  }

  void updateTapResult(double rawScore) {
    _tapResult = BBAResult(rawScore);
    print('[BBA] Updated tap result: $rawScore');
    _evaluateIfReady();
  }

  void reset() {
    _sensorResult = null;
    _keypressResult = null;
    _tapResult = null;
    _keypressTriggered = false;
    _currentThreat = ThreatLevel.none;
    _lockoutUntil = null;
    print('[BBA] Orchestrator reset');
  }

  // Getters
  ThreatLevel get currentThreatLevel => _currentThreat;
  BBAResult? get sensorResult => _sensorResult;
  BBAResult? get keypressResult => _keypressResult;
  BBAResult? get tapResult => _tapResult;
  bool get keypressTriggered => _keypressTriggered;
  Duration get maxDataAgeValue => maxDataAge;
}