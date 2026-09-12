import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../services/settings_service.dart';

class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  ApiResponse.success(this.data)
      : isSuccess = true,
        errorMessage = null;

  ApiResponse.failure(this.errorMessage)
      : isSuccess = false,
        data = null;
}

class ApiClient {
  final SettingsService settings;
  final http.Client _client;

  ApiClient(this.settings, [http.Client? client]) : _client = client ?? http.Client();

  String get baseUrl => settings.baseUrl;

  Future<bool> checkHealth() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl${ApiConstants.health}'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getDashboard() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl${ApiConstants.dashboard}'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return ApiResponse.success(jsonDecode(res.body) as Map<String, dynamic>);
      }
      return ApiResponse.failure('Server returned status ${res.statusCode}');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse<List<dynamic>>> getAchievements() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl${ApiConstants.achievements}'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return ApiResponse.success(jsonDecode(res.body) as List<dynamic>);
      }
      return ApiResponse.failure('Server returned status ${res.statusCode}');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getDifficultyRecommendation() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl${ApiConstants.difficulty}'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return ApiResponse.success(jsonDecode(res.body) as Map<String, dynamic>);
      }
      return ApiResponse.failure('Server returned status ${res.statusCode}');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createSession(Map<String, dynamic> body) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl${ApiConstants.sessions}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return ApiResponse.success(jsonDecode(res.body) as Map<String, dynamic>);
      }
      return ApiResponse.failure('Create session failed with ${res.statusCode}');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> completeSession(
      String sessionId, Map<String, dynamic> body) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl${ApiConstants.sessions}/$sessionId/complete'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 7));
      if (res.statusCode == 200) {
        return ApiResponse.success(jsonDecode(res.body) as Map<String, dynamic>);
      }
      return ApiResponse.failure('Complete session failed with ${res.statusCode}');
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }
}
