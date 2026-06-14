import '../../../core/api/api_client.dart';
import '../../../core/config/api_config.dart';
import 'invoice_item.dart';

class InvoicesRepository {
  InvoicesRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<InvoiceItem>> fetchInvoices({required String accessToken}) async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/invoices/',
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final dynamic raw = json['results'] ?? json['data'] ?? json;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(InvoiceItem.fromJson)
          .toList();
    }

    return const [];
  }
}
