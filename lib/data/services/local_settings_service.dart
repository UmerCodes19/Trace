import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalSettingsService {
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyAccentColor = 'accent_color';
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyFatherName = 'profile_father_name';
  static const String _keyRegNo = 'profile_reg_no';
  static const String _keyCurrentAddress = 'profile_cur_addr';
  static const String _keyPermanentAddress = 'profile_perm_addr';
  static const String _keyIntakeSemester = 'profile_intake';
  static const String _keySavedCMSAccounts = 'saved_cms_accounts';

  final SharedPreferences _prefs;
  static const _secureStorage = FlutterSecureStorage();

  LocalSettingsService(this._prefs);

  bool get isDarkMode => _prefs.getBool(_keyDarkMode) ?? true;
  Future<void> setDarkMode(bool value) => _prefs.setBool(_keyDarkMode, value);

  int get accentColor => _prefs.getInt(_keyAccentColor) ?? 0xFF10B981; // Default Jade
  Future<void> setAccentColor(int value) => _prefs.setInt(_keyAccentColor, value);

  bool get notificationsEnabled => _prefs.getBool(_keyNotifications) ?? true;
  Future<void> setNotificationsEnabled(bool value) => _prefs.setBool(_keyNotifications, value);

  String? get fatherName => _prefs.getString(_keyFatherName);
  Future<void> setFatherName(String? value) => value != null ? _prefs.setString(_keyFatherName, value) : _prefs.remove(_keyFatherName);

  String? get registrationNo => _prefs.getString(_keyRegNo);
  Future<void> setRegistrationNo(String? value) => value != null ? _prefs.setString(_keyRegNo, value) : _prefs.remove(_keyRegNo);

  String? get currentAddress => _prefs.getString(_keyCurrentAddress);
  Future<void> setCurrentAddress(String? value) => value != null ? _prefs.setString(_keyCurrentAddress, value) : _prefs.remove(_keyCurrentAddress);

  String? get permanentAddress => _prefs.getString(_keyPermanentAddress);
  Future<void> setPermanentAddress(String? value) => value != null ? _prefs.setString(_keyPermanentAddress, value) : _prefs.remove(_keyPermanentAddress);

  String? get intakeSemester => _prefs.getString(_keyIntakeSemester);
  Future<void> setIntakeSemester(String? value) => value != null ? _prefs.setString(_keyIntakeSemester, value) : _prefs.remove(_keyIntakeSemester);

  /// SECURE: Retreives, and automatically transparently migrates, plaintext credentials
  /// from the legacy preferences into Hardware-backed Secure Storage on first access.
  Future<List<Map<String, String>>> getSavedCMSAccounts() async {
    try {
      // 1. Check Encrypted Storage first
      final securedValue = await _secureStorage.read(key: _keySavedCMSAccounts);
      if (securedValue != null) {
        final List<dynamic> decodedList = jsonDecode(securedValue);
        return decodedList.map((item) => Map<String, String>.from(item)).toList();
      }

      // 2. AUTO-MIGRATION CHECK: Lookup insecure legacy location for background-migration
      final legacyList = _prefs.getStringList(_keySavedCMSAccounts) ?? [];
      if (legacyList.isNotEmpty) {
        debugPrint('🔐 SECURITY: Found legacy plaintext accounts. Commencing secure vault migration...');
        final List<Map<String, String>> migrated = [];
        for (var item in legacyList) {
          try {
            final decoded = jsonDecode(item) as Map<String, dynamic>;
            migrated.add({
              'enrollment': decoded['enrollment']?.toString() ?? '',
              'password': decoded['password']?.toString() ?? '',
            });
          } catch (_) {}
        }

        if (migrated.isNotEmpty) {
          // Encrypt to Secure Storage immediately
          await _secureStorage.write(key: _keySavedCMSAccounts, value: jsonEncode(migrated));
          // WIPE non-encrypted evidence forever
          await _prefs.remove(_keySavedCMSAccounts);
          debugPrint('🔐 SECURITY: Successfully hardened credential vault. Unencrypted trace purged.');
          return migrated;
        }
      }
    } catch (e) {
      debugPrint('🔐 STORAGE ERROR: Failed loading secure accounts: $e');
    }
    return [];
  }

  Future<void> saveCMSAccount(String enrollment, String password) async {
    final list = await getSavedCMSAccounts();
    list.removeWhere((acc) => acc['enrollment'] == enrollment);
    list.insert(0, {'enrollment': enrollment, 'password': password});
    
    // Encrypt to secure vault
    await _secureStorage.write(key: _keySavedCMSAccounts, value: jsonEncode(list));
    
    // Redundant sanity wipe of legacy prefs in case it existed
    await _prefs.remove(_keySavedCMSAccounts);
  }

  Future<void> deleteCMSAccount(String enrollment) async {
    final list = await getSavedCMSAccounts();
    list.removeWhere((acc) => acc['enrollment'] == enrollment);
    await _secureStorage.write(key: _keySavedCMSAccounts, value: jsonEncode(list));
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final localSettingsProvider = Provider<LocalSettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalSettingsService(prefs);
});

final themeProvider = StateProvider<bool>((ref) {
  final settings = ref.watch(localSettingsProvider);
  return settings.isDarkMode;
});

final accentColorProvider = StateProvider<int>((ref) {
  final settings = ref.watch(localSettingsProvider);
  return settings.accentColor;
});

final performanceOverlayProvider = StateProvider<bool>((ref) => false);
