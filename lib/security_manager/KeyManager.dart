import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionKeyManager {
  static const _keyStorageKey = '121czdgfb4342';
  static final _secureStorage = FlutterSecureStorage();

  static String _generateRandomKey() {
    final rand = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static Future<String> getOrCreateKey() async {
    String? key = await _secureStorage.read(key: _keyStorageKey);
    if (key == null) {
      key = _generateRandomKey();
      await _secureStorage.write(key: _keyStorageKey, value: key);
      print("🔐 New embedding key generated and stored securely.");
    }
    return key;
  }

  static Future<void> resetKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
  }
}
