class MyDoctorProfile {
  const MyDoctorProfile({
    required this.id,
    required this.consultationFeeOnline,
    required this.consultationFeeOffline,
  });

  final int id;
  final String consultationFeeOnline;
  final String consultationFeeOffline;

  factory MyDoctorProfile.fromJson(Map<String, dynamic> json) {
    return MyDoctorProfile(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      consultationFeeOnline: '${json['consultation_fee_online'] ?? ''}'.trim(),
      consultationFeeOffline: '${json['consultation_fee_offline'] ?? ''}'.trim(),
    );
  }
}

class MyDoctorSchedule {
  const MyDoctorSchedule({
    required this.id,
    required this.mode,
    required this.modeDisplay,
    required this.weekday,
    required this.weekdayDisplay,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMinutes,
    required this.maxPatients,
    required this.isActive,
  });

  final int id;
  final String mode;
  final String modeDisplay;
  final int weekday;
  final String weekdayDisplay;
  final String startTime;
  final String endTime;
  final int slotDurationMinutes;
  final int maxPatients;
  final bool isActive;

  String get title => '$weekdayDisplay | $modeDisplay';

  String get subtitle =>
      '${_shortTime(startTime)} - ${_shortTime(endTime)} | $slotDurationMinutes min | $maxPatients patients';

  factory MyDoctorSchedule.fromJson(Map<String, dynamic> json) {
    return MyDoctorSchedule(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      mode: '${json['mode'] ?? ''}'.trim(),
      modeDisplay: '${json['mode_display'] ?? json['mode'] ?? ''}'.trim(),
      weekday: json['weekday'] is int ? json['weekday'] as int : int.tryParse('${json['weekday']}') ?? 0,
      weekdayDisplay: '${json['weekday_display'] ?? json['weekday'] ?? ''}'.trim(),
      startTime: '${json['start_time'] ?? ''}'.trim(),
      endTime: '${json['end_time'] ?? ''}'.trim(),
      slotDurationMinutes: json['slot_duration_minutes'] is int
          ? json['slot_duration_minutes'] as int
          : int.tryParse('${json['slot_duration_minutes']}') ?? 0,
      maxPatients: json['max_patients'] is int
          ? json['max_patients'] as int
          : int.tryParse('${json['max_patients']}') ?? 0,
      isActive: json['is_active'] != false,
    );
  }

  static String _shortTime(String raw) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(raw.trim());
    if (match == null) return raw.trim();
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) return raw.trim();
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$normalizedHour:${minute.toString().padLeft(2, '0')} $suffix';
  }
}

