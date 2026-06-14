import '../../../core/api/api_client.dart';
import '../../../core/config/api_config.dart';
import 'ambulance_request_item.dart';
import 'emergency_contact.dart';

class AmbulanceRepository {
  AmbulanceRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<EmergencyContact>> fetchEmergencyContacts() async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/emergency-contact/',
    );

    final dynamic raw = json['results'] ?? json['data'] ?? json;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(EmergencyContact.fromJson)
          .toList();
    }

    return const [];
  }

  Future<List<AmbulanceRequestItem>> fetchRequests({
    required String accessToken,
  }) async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/ambulance/requests/',
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final dynamic raw = json['results'] ?? json['data'] ?? json;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(AmbulanceRequestItem.fromJson)
          .toList();
    }

    return const [];
  }

  Future<AmbulanceRequestItem> submitRequest({
    required String accessToken,
    required String pickupAddress,
    required String destinationAddress,
    required String contactNumber,
    required String notes,
  }) async {
    final json = await _apiClient.postJson(
      ApiConfig.apiBaseUrl,
      '/ambulance/request/',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: {
        'pickup_address': pickupAddress,
        'destination_address': destinationAddress,
        'contact_number': contactNumber,
        'notes': notes,
      },
    );

    return AmbulanceRequestItem.fromJson(json);
  }
}
