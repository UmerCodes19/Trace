import 'package:shared_preferences/shared_preferences.dart';
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

  final SharedPreferences _prefs;

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
