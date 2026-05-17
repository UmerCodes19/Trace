import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class OfflineCacheService {
  OfflineCacheService._();
  static final instance = OfflineCacheService._();

  static const _storage = FlutterSecureStorage();
  static const _keyName = 'offline_crypto_key';

  String? _cachedKey;

  Future<String> _getOrGenerateKey() async {
    if (_cachedKey != null) return _cachedKey!;
    try {
      String? key = await _storage.read(key: _keyName);
      if (key == null) {
        key = '${DateTime.now().microsecondsSinceEpoch}_trace_secure_key';
        await _storage.write(key: _keyName, value: key);
      }
      _cachedKey = key;
      return key;
    } catch (e) {
      debugPrint('OfflineCacheService: Keystore error when getting/generating key: $e');
      // If keystore is corrupted or throws, try deleting the old key and generating a fresh one
      try {
        await _storage.delete(key: _keyName);
        final key = '${DateTime.now().microsecondsSinceEpoch}_trace_secure_key_recovered';
        await _storage.write(key: _keyName, value: key);
        _cachedKey = key;
        return key;
      } catch (innerError) {
        debugPrint('OfflineCacheService: Critical Keystore error, using non-persistent in-memory fallback key: $innerError');
        // Absolute fallback to prevent app crashes/hangs: in-memory key
        final key = 'in_memory_fallback_${DateTime.now().microsecondsSinceEpoch}';
        _cachedKey = key;
        return key;
      }
    }
  }

  /// Optimized lightweight key-based XOR cryptography with zero library overhead.
  String _crypt(String input, String key) {
    final keyCodes = key.codeUnits;
    final inputCodes = utf8.encode(input);
    final result = List<int>.filled(inputCodes.length, 0);
    for (int i = 0; i < inputCodes.length; i++) {
      result[i] = inputCodes[i] ^ keyCodes[i % keyCodes.length];
    }
    return base64Url.encode(result);
  }

  String _decrypt(String base64Input, String key) {
    final keyCodes = key.codeUnits;
    final inputCodes = base64Url.decode(base64Input);
    final result = List<int>.filled(inputCodes.length, 0);
    for (int i = 0; i < inputCodes.length; i++) {
      result[i] = inputCodes[i] ^ keyCodes[i % keyCodes.length];
    }
    return utf8.decode(result);
  }

  Future<File> _getCacheFile(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$filename.cache');
  }

  Future<void> saveEncryptedString(String filename, String content) async {
    try {
      final key = await _getOrGenerateKey();
      final encrypted = _crypt(content, key);
      final file = await _getCacheFile(filename);
      await file.writeAsString(encrypted, flush: true);
    } catch (_) {}
  }

  Future<String?> readDecryptedString(String filename) async {
    try {
      final file = await _getCacheFile(filename);
      if (!await file.exists()) return null;
      final encrypted = await file.readAsString();
      final key = await _getOrGenerateKey();
      return _decrypt(encrypted, key);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache(String filename) async {
    try {
      final file = await _getCacheFile(filename);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
