class DoctorPrescriptionAppointmentItem {
  const DoctorPrescriptionAppointmentItem({
    required this.id,
    required this.patientName,
    required this.patientEmail,
    required this.patientPhone,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.mode,
    required this.status,
    required this.statusDisplay,
    required this.patientNote,
  });

  final int id;
  final String patientName;
  final String patientEmail;
  final String patientPhone;
  final String appointmentDate;
  final String appointmentTime;
  final String mode;
  final String status;
  final String statusDisplay;
  final String patientNote;

  bool get isPrescriptionReady {
    final normalized = status.toUpperCase();
    return normalized == 'BOOKED' || normalized == 'CONFIRMED' || normalized == 'COMPLETED';
  }

  String get subtitle {
    final parts = <String>[
      if (appointmentDate.isNotEmpty) appointmentDate,
      if (appointmentTime.isNotEmpty) _formatTime(appointmentTime),
      if (mode.isNotEmpty) mode,
    ];
    return parts.join(' | ');
  }

  factory DoctorPrescriptionAppointmentItem.fromJson(
    Map<String, dynamic> json,
  ) {
    final patient = json['patient'] is Map<String, dynamic>
        ? json['patient'] as Map<String, dynamic>
        : <String, dynamic>{};
    final user = patient['user'] is Map<String, dynamic>
        ? patient['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final first = '${user['first_name'] ?? ''}'.trim();
    final last = '${user['last_name'] ?? ''}'.trim();
    final fullName = '$first $last'.trim();

    return DoctorPrescriptionAppointmentItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      patientName: fullName.isEmpty
          ? '${user['email'] ?? 'Patient'}'.trim()
          : fullName,
      patientEmail: '${user['email'] ?? ''}'.trim(),
      patientPhone: '${user['phone'] ?? ''}'.trim(),
      appointmentDate: '${json['appointment_date'] ?? ''}'.trim(),
      appointmentTime: '${json['appointment_time'] ?? ''}'.trim(),
      mode: '${json['mode_display'] ?? json['mode'] ?? ''}'.trim(),
      status: '${json['status'] ?? ''}'.trim(),
      statusDisplay: '${json['status_display'] ?? json['status'] ?? ''}'.trim(),
      patientNote: '${json['patient_note'] ?? ''}'.trim(),
    );
  }
}

class DoctorPrescriptionPatientSummary {
  const DoctorPrescriptionPatientSummary({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.gender,
    required this.bloodGroup,
    required this.address,
    required this.emergencyContact,
  });

  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String dateOfBirth;
  final String gender;
  final String bloodGroup;
  final String address;
  final String emergencyContact;

  factory DoctorPrescriptionPatientSummary.fromJson(Map<String, dynamic> json) {
    return DoctorPrescriptionPatientSummary(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      fullName: '${json['full_name'] ?? ''}'.trim(),
      email: '${json['email'] ?? ''}'.trim(),
      phone: '${json['phone'] ?? ''}'.trim(),
      dateOfBirth: '${json['date_of_birth'] ?? ''}'.trim(),
      gender: '${json['gender'] ?? ''}'.trim(),
      bloodGroup: '${json['blood_group'] ?? ''}'.trim(),
      address: '${json['address'] ?? ''}'.trim(),
      emergencyContact: '${json['emergency_contact'] ?? ''}'.trim(),
    );
  }
}

class DoctorPrescriptionSummary {
  const DoctorPrescriptionSummary({
    required this.id,
    required this.title,
    required this.history,
    required this.chiefComplaints,
    required this.observation,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.temperatureC,
    required this.bloodPressureSystolic,
    required this.bloodPressureDiastolic,
    required this.pulseBpm,
    required this.respiratoryRate,
    required this.oxygenSaturation,
    required this.diagnosis,
    required this.advice,
    required this.notes,
    required this.isVisibleToPatient,
    required this.diagnosticTests,
    required this.medicines,
  });

  final int id;
  final String title;
  final String history;
  final String chiefComplaints;
  final String observation;
  final String age;
  final String gender;
  final String heightCm;
  final String weightKg;
  final String temperatureC;
  final String bloodPressureSystolic;
  final String bloodPressureDiastolic;
  final String pulseBpm;
  final String respiratoryRate;
  final String oxygenSaturation;
  final String diagnosis;
  final String advice;
  final String notes;
  final bool isVisibleToPatient;
  final List<DoctorPrescriptionDiagnosticTestItem> diagnosticTests;
  final List<DoctorPrescriptionMedicineItem> medicines;

  factory DoctorPrescriptionSummary.fromJson(Map<String, dynamic> json) {
    final rawTests = json['diagnostic_tests'] is List
        ? json['diagnostic_tests'] as List
        : const [];
    final rawMedicines = json['medicines'] is List
        ? json['medicines'] as List
        : const [];

    return DoctorPrescriptionSummary(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      title: '${json['title'] ?? ''}'.trim(),
      history: '${json['history'] ?? ''}'.trim(),
      chiefComplaints: '${json['chief_complaints'] ?? ''}'.trim(),
      observation: '${json['observation'] ?? ''}'.trim(),
      age: _normalizedValue(json['age']),
      gender: '${json['gender'] ?? ''}'.trim(),
      heightCm: _normalizedValue(json['height_cm']),
      weightKg: _normalizedValue(json['weight_kg']),
      temperatureC: _normalizedValue(json['temperature_c']),
      bloodPressureSystolic: _normalizedValue(json['blood_pressure_systolic']),
      bloodPressureDiastolic: _normalizedValue(
        json['blood_pressure_diastolic'],
      ),
      pulseBpm: _normalizedValue(json['pulse_bpm']),
      respiratoryRate: _normalizedValue(json['respiratory_rate']),
      oxygenSaturation: _normalizedValue(json['oxygen_saturation']),
      diagnosis: '${json['diagnosis'] ?? ''}'.trim(),
      advice: '${json['advice'] ?? ''}'.trim(),
      notes: '${json['notes'] ?? ''}'.trim(),
      isVisibleToPatient: json['is_visible_to_patient'] != false,
      diagnosticTests: rawTests
          .whereType<Map<String, dynamic>>()
          .map(DoctorPrescriptionDiagnosticTestItem.fromJson)
          .toList(),
      medicines: rawMedicines
          .whereType<Map<String, dynamic>>()
          .map(DoctorPrescriptionMedicineItem.fromJson)
          .toList(),
    );
  }
}

class DoctorPrescriptionDraftContext {
  const DoctorPrescriptionDraftContext({
    required this.appointmentId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.mode,
    required this.status,
    required this.fee,
    required this.patientNote,
    required this.patient,
    required this.doctorName,
    required this.doctorDepartment,
    required this.doctorDesignation,
    required this.defaults,
    required this.existingPrescription,
    required this.canCreate,
    required this.createEndpoint,
    required this.updateEndpoint,
  });

  final int appointmentId;
  final String appointmentDate;
  final String appointmentTime;
  final String mode;
  final String status;
  final String fee;
  final String patientNote;
  final DoctorPrescriptionPatientSummary patient;
  final String doctorName;
  final String doctorDepartment;
  final String doctorDesignation;
  final DoctorPrescriptionSummary defaults;
  final DoctorPrescriptionSummary? existingPrescription;
  final bool canCreate;
  final String createEndpoint;
  final String? updateEndpoint;

  bool get isEditMode => existingPrescription != null && !canCreate;

  factory DoctorPrescriptionDraftContext.fromJson(Map<String, dynamic> json) {
    final appointment = json['appointment'] is Map<String, dynamic>
        ? json['appointment'] as Map<String, dynamic>
        : <String, dynamic>{};
    final patient = json['patient'] is Map<String, dynamic>
        ? json['patient'] as Map<String, dynamic>
        : <String, dynamic>{};
    final doctor = json['doctor'] is Map<String, dynamic>
        ? json['doctor'] as Map<String, dynamic>
        : <String, dynamic>{};
    final defaults = json['defaults'] is Map<String, dynamic>
        ? json['defaults'] as Map<String, dynamic>
        : <String, dynamic>{};
    final existing = json['existing_prescription'] is Map<String, dynamic>
        ? json['existing_prescription'] as Map<String, dynamic>
        : null;

    return DoctorPrescriptionDraftContext(
      appointmentId: appointment['id'] is int
          ? appointment['id'] as int
          : int.tryParse('${appointment['id']}') ?? 0,
      appointmentDate: '${appointment['appointment_date'] ?? ''}'.trim(),
      appointmentTime: '${appointment['appointment_time'] ?? ''}'.trim(),
      mode: '${appointment['mode'] ?? ''}'.trim(),
      status: '${appointment['status'] ?? ''}'.trim(),
      fee: _normalizedValue(appointment['fee']),
      patientNote: '${appointment['patient_note'] ?? ''}'.trim(),
      patient: DoctorPrescriptionPatientSummary.fromJson(patient),
      doctorName: '${doctor['full_name'] ?? ''}'.trim(),
      doctorDepartment: '${doctor['department'] ?? ''}'.trim(),
      doctorDesignation: '${doctor['designation'] ?? ''}'.trim(),
      defaults: DoctorPrescriptionSummary.fromJson(defaults),
      existingPrescription: existing == null
          ? null
          : DoctorPrescriptionSummary.fromJson(existing),
      canCreate: json['can_create'] == true,
      createEndpoint: '${json['create_endpoint'] ?? ''}'.trim(),
      updateEndpoint: _nullableString(json['update_endpoint']),
    );
  }
}

class DoctorPrescriptionDiagnosticTestItem {
  const DoctorPrescriptionDiagnosticTestItem({
    required this.testName,
    required this.instructions,
  });

  final String testName;
  final String instructions;

  factory DoctorPrescriptionDiagnosticTestItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return DoctorPrescriptionDiagnosticTestItem(
      testName: '${json['test_name'] ?? ''}'.trim(),
      instructions: '${json['instructions'] ?? ''}'.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'test_name': testName,
    'instructions': instructions,
  };
}

class DoctorPrescriptionMedicineItem {
  const DoctorPrescriptionMedicineItem({
    required this.brandName,
    required this.strength,
    required this.timing,
    required this.duration,
    required this.notes,
  });

  final String brandName;
  final String strength;
  final String timing;
  final String duration;
  final String notes;

  factory DoctorPrescriptionMedicineItem.fromJson(Map<String, dynamic> json) {
    return DoctorPrescriptionMedicineItem(
      brandName: '${json['brand_name'] ?? ''}'.trim(),
      strength: '${json['strength'] ?? ''}'.trim(),
      timing: '${json['timing'] ?? ''}'.trim(),
      duration: '${json['duration'] ?? ''}'.trim(),
      notes: '${json['notes'] ?? ''}'.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'brand_name': brandName,
    'strength': strength,
    'timing': timing,
    'duration': duration,
    'notes': notes,
  };
}

String _normalizedValue(dynamic value) {
  final text = '${value ?? ''}'.trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

String? _nullableString(dynamic value) {
  final text = '${value ?? ''}'.trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}

String _formatTime(String raw) {
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})(?::\d{2})?$',
  ).firstMatch(raw.trim());
  if (match == null) return raw.trim();
  final hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null) return raw.trim();
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$normalizedHour:${minute.toString().padLeft(2, '0')} $suffix';
}

