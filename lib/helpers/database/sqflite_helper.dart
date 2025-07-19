import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class EmbeddingDatabase {
  static final EmbeddingDatabase _instance = EmbeddingDatabase._internal();
  factory EmbeddingDatabase() => _instance;
  EmbeddingDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "embeddings.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_embeddings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        embedding TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertEmbedding(String userId, List<double> embedding) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final embeddingJsonString = jsonEncode(embedding);

    return await db.insert(
      'user_embeddings',
      {
        'user_id': userId,
        'embedding': embeddingJsonString,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<List<double>>> getUserEmbeddings(String userId) async {
    final db = await database;
    final result = await db.query(
      'user_embeddings',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );

    return result.map((row) {
      try {
        List<dynamic> decoded = jsonDecode(row['embedding'] as String);
        return decoded.map((e) => (e as num).toDouble()).toList();
      } catch (e) {
        print("Error decoding embedding from DB: $e");
        return <double>[];
      }
    }).where((e) => e.isNotEmpty).toList();
  }

  Future<int> deleteEmbeddingsForUser(String userId) async {
    final db = await database;
    return await db.delete(
      'user_embeddings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteOldEmbeddings(String userId, int keepLastN) async {
    final db = await database;
    final countResult = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM user_embeddings WHERE user_id = ?', [userId]));

    if (countResult == null || countResult <= keepLastN) {
      return 0;
    }

    final toDelete = countResult - keepLastN;

    return await db.rawDelete('''
      DELETE FROM user_embeddings 
      WHERE id IN (
        SELECT id FROM user_embeddings 
        WHERE user_id = ? 
        ORDER BY created_at ASC 
        LIMIT ?
      )
    ''', [userId, toDelete]);
  }
}
