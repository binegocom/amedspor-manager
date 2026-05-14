import 'package:shared_preferences/shared_preferences.dart';

class AppStateService {
  static const _onboardingCompletedKey = 'onboardingCompleted';
  static const _notificationPermissionAskedKey = 'notificationPermissionAsked';
  static const _darkModeKey = 'darkMode';
  
  // In-memory cache to reduce SharedPreferences reads
  static final Map<String, dynamic> _cache = {};
  static bool _cacheInitialized = false;
  static Future<void> _initCache() async {
    if (_cacheInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    _cache[_onboardingCompletedKey] = prefs.getBool(_onboardingCompletedKey) ?? false;
    _cache[_darkModeKey] = prefs.getBool(_darkModeKey) ?? true;
    _cacheInitialized = true;
  }

  Future<bool> isOnboardingCompleted() async {
    await _initCache();
    return _cache[_onboardingCompletedKey] as bool? ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
    _cache[_onboardingCompletedKey] = true;
  }

  Future<bool> wasNotificationPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationPermissionAskedKey) ?? false;
  }

  Future<void> setNotificationPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationPermissionAskedKey, true);
  }

  Future<bool> isDarkMode() async {
    await _initCache();
    return _cache[_darkModeKey] as bool? ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
    _cache[_darkModeKey] = value;
  }
}
