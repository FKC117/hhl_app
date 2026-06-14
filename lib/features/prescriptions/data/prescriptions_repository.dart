import '../../../core/api/api_client.dart';
import '../../../core/config/api_config.dart';
import 'prescription_item.dart';

class PrescriptionsRepository {
  PrescriptionsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<PrescriptionItem>> fetchPrescriptions({
    required String accessToken,
  }) async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/prescriptions/',
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final dynamic raw = json['results'] ?? json['data'] ?? json;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(PrescriptionItem.fromJson)
          .toList();
    }

    return const [];
  }
}
