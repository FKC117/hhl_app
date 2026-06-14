import '../../../core/api/api_client.dart';
import '../../../core/config/api_config.dart';

class AppointmentRepository {
  AppointmentRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AppointmentSlot>> fetchSlots({
    required int scheduleId,
    required String date,
  }) async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/appointments/slots/',
      queryParameters: {'schedule': '$scheduleId', 'date': date},
    );

    final dynamic raw =
        json['results'] ?? json['slots'] ?? json['data'] ?? json;
    if (raw is List) {
      return raw
          .map(AppointmentSlot.fromDynamic)
          .where((slot) => slot.time.isNotEmpty)
          .toList();
    }

    return const [];
  }

  Future<AppointmentDraftResult> createDraft({
    required int scheduleId,
    required String appointmentDate,
    required String appointmentTime,
    required String patientNote,
    String? accessToken,
  }) async {
    final json = await _apiClient.postJson(
      ApiConfig.apiBaseUrl,
      '/appointments/draft/',
      headers: {
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
      body: {
        'schedule': scheduleId,
        'appointment_date': appointmentDate,
        'appointment_time': appointmentTime,
        'patient_note': patientNote,
      },
    );

    return AppointmentDraftResult.fromJson(json);
  }

  Future<PaymentRecord> initiatePayment({
    required int appointmentId,
    required String accessToken,
  }) async {
    final json = await _apiClient.postJson(
      ApiConfig.apiBaseUrl,
      '/payments/initiate/',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: {
        'source_type': 'APPOINTMENT',
        'source_id': appointmentId,
        'gateway': 'manual',
      },
    );

    return PaymentRecord.fromJson(json);
  }

  Future<PaymentRecord> completeManualPayment({
    required int paymentId,
    required String accessToken,
  }) async {
    final json = await _apiClient.postJson(
      ApiConfig.apiBaseUrl,
      '/payments/$paymentId/complete/',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: const {},
    );

    return PaymentRecord.fromJson(json);
  }

  Future<AppointmentDraftResult> confirmAppointment({
    required int appointmentId,
    required int paymentId,
    required String accessToken,
  }) async {
    final json = await _apiClient.postJson(
      ApiConfig.apiBaseUrl,
      '/appointments/$appointmentId/confirm/',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: {'payment_id': paymentId},
    );

    return AppointmentDraftResult.fromJson(json);
  }

  Future<List<AppointmentListItem>> fetchAppointments({
    required String accessToken,
  }) async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/appointments/',
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final dynamic raw = json['results'] ?? json['data'] ?? json;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(AppointmentListItem.fromJson)
          .toList();
    }

    return const [];
  }
}

class AppointmentSlot {
  const AppointmentSlot({
    required this.time,
    required this.label,
    required this.isAvailable,
  });

  final String time;
  final String label;
  final bool isAvailable;

  factory AppointmentSlot.fromDynamic(dynamic raw) {
    if (raw is String) {
      final time = raw.trim();
      return AppointmentSlot(
        time: time,
        label: _formatSlotLabel(time),
        isAvailable: time.isNotEmpty,
      );
    }

    if (raw is Map<String, dynamic>) {
      return AppointmentSlot.fromJson(raw);
    }

    return const AppointmentSlot(time: '', label: '', isAvailable: false);
  }

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    final time =
        '${json['time'] ?? json['slot_time'] ?? json['appointment_time'] ?? ''}'
            .trim();
    final label = '${json['label'] ?? json['display'] ?? ''}'.trim();
    final status = '${json['status'] ?? ''}'.trim().toLowerCase();

    return AppointmentSlot(
      time: time,
      label: label.isEmpty ? _formatSlotLabel(time) : label,
      isAvailable:
          json['is_available'] == true ||
          json['available'] == true ||
          status.isEmpty ||
          status == 'available',
    );
  }
}

class AppointmentDraftResult {
  const AppointmentDraftResult({
    required this.id,
    required this.status,
    this.statusDisplay = '',
    this.mode = '',
    this.appointmentDate = '',
    this.appointmentTime = '',
    this.fee = '',
  });

  final int id;
  final String status;
  final String statusDisplay;
  final String mode;
  final String appointmentDate;
  final String appointmentTime;
  final String fee;

  factory AppointmentDraftResult.fromJson(Map<String, dynamic> json) {
    return AppointmentDraftResult(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      status: '${json['status'] ?? 'draft'}'.trim(),
      statusDisplay: '${json['status_display'] ?? ''}'.trim(),
      mode: '${json['mode_display'] ?? json['mode'] ?? ''}'.trim(),
      appointmentDate: '${json['appointment_date'] ?? ''}'.trim(),
      appointmentTime: '${json['appointment_time'] ?? ''}'.trim(),
      fee: _formatMoney('${json['fee'] ?? ''}'.trim()),
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.gateway,
    required this.status,
    required this.transactionId,
  });

  final int id;
  final String amount;
  final String gateway;
  final String status;
  final String transactionId;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      amount: _formatMoney('${json['amount'] ?? ''}'.trim()),
      gateway: '${json['gateway'] ?? ''}'.trim(),
      status: '${json['status'] ?? ''}'.trim(),
      transactionId: '${json['transaction_id'] ?? ''}'.trim(),
    );
  }
}

class AppointmentListItem {
  const AppointmentListItem({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.status,
    required this.statusDisplay,
    required this.mode,
    required this.dateRaw,
    required this.timeRaw,
    required this.fee,
  });

  final int id;
  final String doctorName;
  final String specialty;
  final String status;
  final String statusDisplay;
  final String mode;
  final String dateRaw;
  final String timeRaw;
  final String fee;

  factory AppointmentListItem.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'];
    return AppointmentListItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      doctorName: _doctorName(doctor),
      specialty: _doctorSpecialty(doctor),
      status: '${json['status'] ?? ''}'.trim(),
      statusDisplay: '${json['status_display'] ?? ''}'.trim(),
      mode: '${json['mode_display'] ?? json['mode'] ?? ''}'.trim(),
      dateRaw: '${json['appointment_date'] ?? ''}'.trim(),
      timeRaw: '${json['appointment_time'] ?? ''}'.trim(),
      fee: _formatMoney('${json['fee'] ?? ''}'.trim()),
    );
  }

  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';

  bool get isMissed {
    if (isCompleted || isCancelled) return false;
    final date = DateTime.tryParse(dateRaw);
    if (date == null) return false;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return date.isBefore(todayDate);
  }

  bool get isUpcoming => !isCompleted && !isCancelled && !isMissed;

  String get dateLabel => _formatHumanDate(dateRaw);
  String get timeLabel => _formatSlotLabel(timeRaw);
}

String _formatSlotLabel(String time) {
  final parsed = _normalizeTime(time);
  if (parsed == null) return time;

  final hour24 = parsed.hour;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final suffix = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 == 0 || hour24 == 12
      ? 12
      : hour24 > 12
      ? hour24 - 12
      : hour24;
  return '$hour12:$minute $suffix';
}

DateTime? _normalizeTime(String time) {
  final normalized = time.trim();
  if (normalized.isEmpty) return null;

  final parts = normalized.split(':');
  if (parts.length < 2) return null;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;

  return DateTime(2000, 1, 1, hour, minute);
}

String _formatMoney(String raw) {
  if (raw.isEmpty) return 'Fee not listed';
  if (raw.toLowerCase().contains('bdt')) return raw;
  return 'BDT $raw';
}

String _doctorName(dynamic doctor) {
  if (doctor is! Map<String, dynamic>) return 'Doctor';
  final user = doctor['user'];
  if (user is Map<String, dynamic>) {
    final first = '${user['first_name'] ?? ''}'.trim();
    final last = '${user['last_name'] ?? ''}'.trim();
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    final email = '${user['email'] ?? ''}'.trim();
    if (email.isNotEmpty) return email;
  }
  return 'Doctor';
}

String _doctorSpecialty(dynamic doctor) {
  if (doctor is! Map<String, dynamic>) return 'General';
  final department = doctor['department'];
  if (department is Map<String, dynamic>) {
    final name = '${department['name'] ?? ''}'.trim();
    if (name.isNotEmpty) return name;
  }
  return 'General';
}

String _formatHumanDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[parsed.month - 1];
  return '$month ${parsed.day}, ${parsed.year}';
}
