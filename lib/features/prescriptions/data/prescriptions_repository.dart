import '../../../core/api/api_client.dart';
import '../../../core/config/api_config.dart';
import 'doctor_prescription_models.dart';
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

  Future<List<DoctorPrescriptionAppointmentItem>> fetchDoctorAppointments({
    required String accessToken,
  }) async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/appointments/doctor/',
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final dynamic raw = json['results'] ?? json['data'] ?? json;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(DoctorPrescriptionAppointmentItem.fromJson)
          .where((item) => item.id > 0)
          .toList();
    }

    return const [];
  }

  Future<DoctorPrescriptionDraftContext> fetchDoctorDraftContext({
    required int appointmentId,
    required String accessToken,
  }) async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/prescriptions/doctor/appointments/$appointmentId/draft-context/',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return DoctorPrescriptionDraftContext.fromJson(json);
  }

  Future<DoctorPrescriptionSummary> createDoctorPrescription({
    required Map<String, dynamic> payload,
    required String accessToken,
  }) async {
    final json = await _apiClient.postJson(
      ApiConfig.apiBaseUrl,
      '/prescriptions/doctor/generate/',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: payload,
    );
    return DoctorPrescriptionSummary.fromJson(json);
  }

  Future<DoctorPrescriptionSummary> updateDoctorPrescription({
    required int prescriptionId,
    required Map<String, dynamic> payload,
    required String accessToken,
  }) async {
    final json = await _apiClient.patchJson(
      ApiConfig.apiBaseUrl,
      '/prescriptions/doctor/$prescriptionId/',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: payload,
    );
    return DoctorPrescriptionSummary.fromJson(json);
  }
}
