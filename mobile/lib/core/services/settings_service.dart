import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class SettingsService {
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyHapticsEnabled = 'haptics_enabled';
  static const String _keyReduceMotion = 'reduce_motion';
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyBaseUrl = 'api_base_url';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  bool get soundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  set soundEnabled(bool val) => _prefs.setBool(_keySoundEnabled, val);

  bool get hapticsEnabled => _prefs.getBool(_keyHapticsEnabled) ?? true;
  set hapticsEnabled(bool val) => _prefs.setBool(_keyHapticsEnabled, val);

  bool get reduceMotion => _prefs.getBool(_keyReduceMotion) ?? false;
  set reduceMotion(bool val) => _prefs.setBool(_keyReduceMotion, val);

  bool get onboardingCompleted => _prefs.getBool(_keyOnboardingDone) ?? false;
  set onboardingCompleted(bool val) => _prefs.setBool(_keyOnboardingDone, val);

  String get baseUrl {
    final saved = _prefs.getString(_keyBaseUrl);
    if (saved == null || saved.contains('127.0.0.1') || saved.contains('localhost')) {
      return ApiConstants.defaultBaseUrl;
    }
    return saved;
  }
  set baseUrl(String val) => _prefs.setString(_keyBaseUrl, val);
}
