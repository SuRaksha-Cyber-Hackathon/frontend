import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../helpers/data_transmitters/offline_data_sender.dart';
import '../helpers/database/sqflite_helper.dart';

const double MAX_X = 1920.0;
const double MAX_Y = 1080.0;
const double MAX_DURATION_MS = 1000.0;

const Map<String, int> screenEncodingMap = {
  'RegisterPage': 0,
  'add_funds': 1,
  'dashboard': 2,
  'pay_bills': 3,
  'profile': 4,
  'statements': 5,
  'transfer_page': 6,
  'LoginPage': 7,
};

List<double> preprocessTapEvent({
  required double x,
  required double y,
  required int durationMs,
  required String contextScreen,
}) {
  final normX = (x / MAX_X).clamp(0.0, 1.0);
  final normY = (y / MAX_Y).clamp(0.0, 1.0);
  final normDuration = (durationMs / MAX_DURATION_MS).clamp(0.0, 1.0);

  final screenEnc = screenEncodingMap[contextScreen] ?? -1;
  if (screenEnc == -1) {
    throw Exception("Unknown context screen: $contextScreen. Please update the screenEncodingMap.");
  }

  return [normX, normY, normDuration, screenEnc.toDouble()];
}

class SiameseModelService {
  static final SiameseModelService _instance = SiameseModelService._internal();
  late Interpreter _interpreter;
  late List<int> _inputShape;
  late List<int> _outputShape;

  factory SiameseModelService() => _instance;

  SiameseModelService._internal();

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset("assets/siamese_model_new.tflite");
    _inputShape = _interpreter.getInputTensor(0).shape;
    _outputShape = _interpreter.getOutputTensor(0).shape;
    print("Siamese model loaded with input shape $_inputShape and output shape $_outputShape.");
  }

  Future<List<double>> runEmbedding(List<double> input) async {
    if (input.length != 4) {
      throw Exception("Expected 4 input features, got ${input.length}");
    }

    final inputTensor = [input.map((e) => e.toDouble()).toList()];
    final outputTensor = List.filled(_outputShape[1], 0.0).reshape(_outputShape);

    _interpreter.run(inputTensor, outputTensor);
    return outputTensor[0].cast<double>();
  }
}

class UserEmbeddingStore {
  static final UserEmbeddingStore _instance = UserEmbeddingStore._internal();
  factory UserEmbeddingStore() => _instance;
  UserEmbeddingStore._internal();

  final EmbeddingDatabase _db = EmbeddingDatabase();

  Future<void> appendUserEmbedding(String userId, List<double> embedding) async {
    await _db.insertEmbedding(userId, embedding);
    print("Added embedding for user $userId.");
  }

  Future<List<double>?> loadAverageEmbedding(String userId) async {
    final embeddings = await _db.getUserEmbeddings(userId);
    if (embeddings.isEmpty) return null;

    final int dim = embeddings[0].length;
    final avg = List.filled(dim, 0.0);
    for (final emb in embeddings) {
      for (int i = 0; i < dim; i++) {
        avg[i] += emb[i];
      }
    }
    for (int i = 0; i < dim; i++) {
      avg[i] /= embeddings.length;
    }
    return avg;
  }

  Future<void> updateProfileWithNewEmbedding(String userId, List<double> newEmbedding) async {
    await appendUserEmbedding(userId, newEmbedding);
    await _db.deleteOldEmbeddings(userId, 70); // Keep last 70 embeddings
    print("Updated profile for user $userId.");
  }

  Future<void> clearUserEmbeddings(String userId) async {
    await _db.deleteEmbeddingsForUser(userId);
    print("Cleared embeddings for user $userId");
  }
}


double euclideanDistance(List<double> a, List<double> b) {
  if (a.length != b.length) {
    throw Exception("Vectors must be of same length.");
  }
  double sum = 0.0;
  for (int i = 0; i < a.length; i++) {
    sum += pow(a[i] - b[i], 2);
  }
  return sqrt(sum);
}

class TapAuthenticator {
  final SiameseModelService _modelService = SiameseModelService();
  final UserEmbeddingStore _embeddingStore = UserEmbeddingStore();

  Future<void> enrollUser(String userId, List<List<double>> tapEvents) async {
    for (var tap in tapEvents) {
      final embedding = await _modelService.runEmbedding(tap);
      await _embeddingStore.appendUserEmbedding(userId, embedding);
    }
    print("Enrollment complete for user $userId");
  }

  Future<double?> getAuthScore(String userId, List<double> tapEvent) async {
    final currentEmbedding = await _modelService.runEmbedding(tapEvent);
    final referenceEmbedding = await _embeddingStore.loadAverageEmbedding(userId);
    if (referenceEmbedding == null) {
      print("No enrollment data found for user $userId — resetting enrollment.");
      TapAuthenticationManager().resetEnrollment(userId);
      return null;
    }

    final score = euclideanDistance(referenceEmbedding, currentEmbedding);
    print("Authentication score for $userId: $score");

    if(score < 1.5) {
      await _embeddingStore.updateProfileWithNewEmbedding(userId, currentEmbedding) ;
    }
    return score;
  }

  Future<bool> authenticateUser(String userId, List<double> tapEvent, {double threshold = 1.5}) async {
    final score = await getAuthScore(userId, tapEvent);
    if(score == null) return false;
    return score < threshold;
  }
}
