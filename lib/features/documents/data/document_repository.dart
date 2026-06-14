import '../../../core/api/api_client.dart';
import '../../../core/config/api_config.dart';

class DocumentRepository {
  DocumentRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<int>> downloadProtectedDocument({
    required String accessToken,
    required String path,
  }) async {
    final response = await _apiClient.getBinary(
      ApiConfig.apiBaseUrl,
      path,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    return response.bodyBytes;
  }
}
