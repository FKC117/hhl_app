import '../../../core/api/api_client.dart';
import '../../../core/config/api_config.dart';
import 'doctor.dart';
import 'doctor_schedule_management.dart';

class DoctorRepository {
  DoctorRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<String>> fetchDepartments() async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/doctors/departments/',
    );

    final items = _extractList(json);
    final departments =
        items
            .map((item) => _departmentLabel(item))
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return ['All', ...departments];
  }

  Future<List<Doctor>> fetchDoctors({
    String? department,
    String? search,
  }) async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/doctors/',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final doctors = _extractList(
      json,
    ).whereType<Map<String, dynamic>>().map(Doctor.fromJson).toList();

    if (department == null || department == 'All') {
      return doctors;
    }

    final normalizedDepartment = department.trim().toLowerCase();
    return doctors.where((doctor) {
      final specialty = doctor.specialty.trim().toLowerCase();
      return specialty == normalizedDepartment ||
          specialty.contains(normalizedDepartment);
    }).toList();
  }

  Future<Doctor> fetchDoctorDetail(int doctorId) async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/doctors/$doctorId/',
    );
    return Doctor.fromJson(json);
  }

  Future<MyDoctorProfile> fetchMyDoctorProfile({
    required String accessToken,
  }) async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/doctors/me/',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return MyDoctorProfile.fromJson(json);
  }

  Future<List<MyDoctorSchedule>> fetchMySchedules({
    required String accessToken,
  }) async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/doctors/me/schedules/',
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final dynamic raw = json['results'] ?? json['data'] ?? json;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(MyDoctorSchedule.fromJson)
          .where((item) => item.id > 0)
          .toList();
    }

    return const [];
  }

  Future<MyDoctorProfile> updateMyDoctorProfile({
    required Map<String, dynamic> payload,
    required String accessToken,
  }) async {
    final json = await _apiClient.patchJson(
      ApiConfig.apiBaseUrl,
      '/doctors/me/',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: payload,
    );
    return MyDoctorProfile.fromJson(json);
  }

  Future<MyDoctorSchedule> createMySchedule({
    required Map<String, dynamic> payload,
    required String accessToken,
  }) async {
    final json = await _apiClient.postJson(
      ApiConfig.apiBaseUrl,
      '/doctors/me/schedules/',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: payload,
    );
    return MyDoctorSchedule.fromJson(json);
  }

  Future<MyDoctorSchedule> updateMySchedule({
    required int scheduleId,
    required Map<String, dynamic> payload,
    required String accessToken,
  }) async {
    final json = await _apiClient.patchJson(
      ApiConfig.apiBaseUrl,
      '/doctors/me/schedules/$scheduleId/',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: payload,
    );
    return MyDoctorSchedule.fromJson(json);
  }

  List<dynamic> _extractList(Map<String, dynamic> json) {
    final results = json['results'];
    if (results is List<dynamic>) return results;
    return const <dynamic>[];
  }

  String _departmentLabel(dynamic item) {
    if (item is String) return item.trim();
    if (item is Map<String, dynamic>) {
      return [item['name'], item['title'], item['department']]
          .map((value) => '$value'.trim())
          .firstWhere(
            (value) => value.isNotEmpty && value != 'null',
            orElse: () => '',
          );
    }
    return '';
  }
}
