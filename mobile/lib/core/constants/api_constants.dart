class ApiConstants {
  // 127.0.0.1 for iOS Simulator & macOS, or configured LAN IP for physical device
  static const String defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';

  static const String health = '/health';
  static const String sessions = '/sessions';
  static const String dashboard = '/dashboard';
  static const String achievements = '/achievements';
  static const String difficulty = '/difficulty/recommendation';
}
