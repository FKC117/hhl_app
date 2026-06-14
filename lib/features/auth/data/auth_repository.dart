import '../../../core/api/api_client.dart';
import '../../../core/config/api_config.dart';
import 'auth_result.dart';

class AuthRepository {
  AuthRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.postJson(
      ApiConfig.apiBaseUrl,
      '/auth/login/',
      body: {'email': email, 'password': password},
    );
    return AuthResult.fromJson(response);
  }

  Future<String> refreshAccessToken({required String refreshToken}) async {
    final response = await _apiClient.postJson(
      ApiConfig.apiBaseUrl,
      '/auth/refresh/',
      body: {'refresh': refreshToken},
    );
    return '${response['access'] ?? ''}'.trim();
  }

  Future<void> logout({required String refreshToken}) async {
    await _apiClient.postJson(
      ApiConfig.apiBaseUrl,
      '/auth/logout/',
      body: {'refresh': refreshToken},
    );
  }
}
