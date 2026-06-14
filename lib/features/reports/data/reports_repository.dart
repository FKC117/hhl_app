import '../../../core/api/api_client.dart';
import '../../../core/config/api_config.dart';
import 'report_item.dart';

class ReportsRepository {
  ReportsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ReportItem>> fetchReports({required String accessToken}) async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/reports/',
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final dynamic raw = json['results'] ?? json['data'] ?? json;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(ReportItem.fromJson)
          .toList();
    }

    return const [];
  }
}
