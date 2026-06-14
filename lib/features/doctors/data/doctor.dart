class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.mode,
    required this.fee,
    required this.experience,
    required this.hospital,
    required this.about,
    required this.schedules,
  });

  final int id;
  final String name;
  final String specialty;
  final String mode;
  final String fee;
  final String experience;
  final String hospital;
  final String about;
  final List<DoctorSchedule> schedules;

  factory Doctor.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final firstName = _string(json['first_name']);
    final lastName = _string(json['last_name']);
    final nestedFirstName = _nestedString(user, ['first_name']);
    final nestedLastName = _nestedString(user, ['last_name']);
    final combinedName = '$firstName $lastName'.trim();
    final nestedCombinedName = '$nestedFirstName $nestedLastName'.trim();

    return Doctor(
      id: _int(json['id']),
      name: _firstNonEmpty([
        _string(json['name']),
        _string(json['full_name']),
        _nestedString(user, ['full_name']),
        nestedCombinedName,
        combinedName,
        _nestedString(user, ['email']),
      ], fallback: 'Doctor'),
      specialty: _firstNonEmpty([
        _string(json['specialty']),
        _string(json['department_name']),
        _nestedString(json['department'], ['name', 'title']),
        _nestedString(json['department_detail'], ['name', 'title']),
      ], fallback: 'General'),
      mode: _firstNonEmpty([
        _string(json['mode']),
        _string(json['consultation_mode']),
        _string(json['visit_mode']),
      ], fallback: 'Available'),
      fee: _formatFee(
        json['fee'] ??
            json['consultation_fee'] ??
            json['appointment_fee'] ??
            json['consultation_fee_online'] ??
            json['consultation_fee_offline'],
      ),
      experience: _firstNonEmpty([
        _string(json['experience']),
        _string(json['experience_years']).isEmpty
            ? ''
            : '${_string(json['experience_years'])} years',
      ], fallback: 'Experience not listed'),
      hospital: _firstNonEmpty([
        _string(json['hospital']),
        _string(json['clinic_name']),
        _string(json['designation']),
        _nestedString(json['facility'], ['name', 'title']),
        _nestedString(json['chamber'], ['name', 'title']),
      ], fallback: 'HHL Network'),
      about: _firstNonEmpty(
        [
          _string(json['about']),
          _string(json['bio']),
          _string(json['summary']),
          _string(json['qualification']),
        ],
        fallback: 'Profile details will appear here when the API returns them.',
      ),
      schedules: _extractSchedules(json),
    );
  }

  static String _formatFee(dynamic value) {
    final raw = _string(value);
    if (raw.isEmpty) return 'Fee not listed';
    if (raw.toLowerCase().contains('bdt')) return raw;
    return 'BDT $raw';
  }

  static List<DoctorSchedule> _extractSchedules(Map<String, dynamic> json) {
    final dynamic raw =
        json['schedules'] ??
        json['schedule_list'] ??
        json['available_schedules'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(DoctorSchedule.fromJson)
        .where((schedule) => schedule.id != 0)
        .toList();
  }
}

class DoctorSchedule {
  const DoctorSchedule({
    required this.id,
    required this.label,
    required this.mode,
  });

  final int id;
  final String label;
  final String mode;

  factory DoctorSchedule.fromJson(Map<String, dynamic> json) {
    return DoctorSchedule(
      id: _int(json['id'] ?? json['schedule_id']),
      label: _firstNonEmpty([
        _string(json['label']),
        _string(json['weekday_display']),
        _string(json['day_display']),
        _string(json['day']),
        _string(json['weekday']),
      ], fallback: 'Schedule'),
      mode: _firstNonEmpty([
        _string(json['mode_display']),
        _string(json['mode']),
        _string(json['visit_mode']),
      ], fallback: 'Available'),
    );
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}

String _string(dynamic value) {
  if (value == null) return '';
  return '$value'.trim();
}

String _nestedString(dynamic value, List<String> keys) {
  if (value is! Map<String, dynamic>) return '';
  for (final key in keys) {
    final resolved = _string(value[key]);
    if (resolved.isNotEmpty) return resolved;
  }
  return '';
}

String _firstNonEmpty(List<String> values, {required String fallback}) {
  for (final value in values) {
    if (value.trim().isNotEmpty) return value.trim();
  }
  return fallback;
}
