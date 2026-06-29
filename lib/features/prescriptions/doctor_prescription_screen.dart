import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/session/app_session.dart';
import 'data/doctor_prescription_models.dart';
import 'data/prescriptions_repository.dart';

class DoctorPrescriptionScreen extends StatefulWidget {
  const DoctorPrescriptionScreen({super.key, required this.session, this.initialAppointmentId});

  final AppSession session;
  final int? initialAppointmentId;

  @override
  State<DoctorPrescriptionScreen> createState() =>
      _DoctorPrescriptionScreenState();
}

class _DoctorPrescriptionScreenState extends State<DoctorPrescriptionScreen> {
  final PrescriptionsRepository _repository = PrescriptionsRepository();
  final Map<String, TextEditingController> _f = {
    for (final key in const [
      'title',
      'history',
      'chief_complaints',
      'observation',
      'age',
      'gender',
      'height_cm',
      'weight_kg',
      'temperature_c',
      'blood_pressure_systolic',
      'blood_pressure_diastolic',
      'pulse_bpm',
      'respiratory_rate',
      'oxygen_saturation',
      'diagnosis',
      'advice',
      'notes',
    ])
      key: TextEditingController(),
  };
  final List<Map<String, TextEditingController>> _tests = [];
  final List<Map<String, TextEditingController>> _meds = [];

  String? _lastToken;
  int? _lastRequestedAppointmentId;
  bool _loadingAppointments = false;
  bool _loadingContext = false;
  bool _saving = false;
  bool _visibleToPatient = true;
  String? _error;
  String? _message;
  int? _selectedAppointmentId;
  List<DoctorPrescriptionAppointmentItem> _appointments = const [];
  DoctorPrescriptionDraftContext? _context;

  @override
  void didUpdateWidget(covariant DoctorPrescriptionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAppointmentId != oldWidget.initialAppointmentId && widget.initialAppointmentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureRequestedAppointmentLoaded();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _f.values) {
      controller.dispose();
    }
    _disposeRows(_tests);
    _disposeRows(_meds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lastToken != widget.session.accessToken) {
      _lastToken = widget.session.accessToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAppointments();
      });
    }

    if (widget.initialAppointmentId != null && widget.initialAppointmentId != _lastRequestedAppointmentId) {
      _lastRequestedAppointmentId = widget.initialAppointmentId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureRequestedAppointmentLoaded();
      });
    }

    final wide = MediaQuery.of(context).size.width >= 1080;
    final left = _buildAppointmentsPane(context);
    final right = _buildEditorPane(context);
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 340, child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [left, const SizedBox(height: 16), right],
    );
  }

  Widget _buildAppointmentsPane(BuildContext context) {
    final items = _appointments
        .where((item) => item.isPrescriptionReady)
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prescription-ready visits',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a paid appointment to preload patient context and start prescribing.',
            ),
            const SizedBox(height: 16),
            if (_loadingAppointments)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (items.isEmpty)
              const Text(
                'No paid appointments are available for prescription right now.',
                style: TextStyle(color: AppColors.muted),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: item.id == _selectedAppointmentId
                        ? const Color(0xFFDDF2EE)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => _loadDraftContext(item.id),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: item.id == _selectedAppointmentId
                                ? AppColors.primary
                                : const Color(0xFFDDE8E6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.patientName,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(item.subtitle),
                            if (item.patientNote.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                item.patientNote,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              item.statusDisplay,
                              style: TextStyle(
                                color: item.status.toUpperCase() == 'COMPLETED'
                                    ? AppColors.success
                                    : AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorPane(BuildContext context) {
    final c = _context;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c?.isEditMode == true
                  ? 'Edit prescription'
                  : 'Create prescription',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              c == null
                  ? 'Select an appointment first.'
                  : 'Patient: ${c.patient.fullName} | Doctor: ${c.doctorName}',
            ),
            if (c != null) ...[
              const SizedBox(height: 12),
              _profileFacts(c),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _chip('Date ${c.appointmentDate}'),
                  _chip('Time ${_displayTime(c.appointmentTime)}'),
                  _chip(c.mode.isEmpty ? 'Mode N/A' : c.mode),
                  _chip(c.status.isEmpty ? 'Status N/A' : c.status),
                ],
              ),
              if (c.patientNote.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('Patient note: ${c.patientNote}'),
                ),
              ],
            ],
            if (_loadingContext) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(_message!, style: const TextStyle(color: AppColors.success)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 18),
            if (c == null)
              const Text(
                'The structured prescription editor appears after appointment selection.',
                style: TextStyle(color: AppColors.muted),
              )
            else
              _buildForm(context, c),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, DoctorPrescriptionDraftContext c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field('title', 'Title'),
        const SizedBox(height: 12),
        _field('history', 'History', lines: 3),
        const SizedBox(height: 12),
        _field('chief_complaints', 'Chief complaints', lines: 3),
        const SizedBox(height: 12),
        _field('observation', 'Observation', lines: 3),
        const SizedBox(height: 18),
        Text(
          'Vitals and biometrics',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _smallField('height_cm', 'Height cm'),
            _smallField('weight_kg', 'Weight kg'),
            _smallField('temperature_c', 'Temp C'),
            _smallField('blood_pressure_systolic', 'BP systolic'),
            _smallField('blood_pressure_diastolic', 'BP diastolic'),
            _smallField('pulse_bpm', 'Pulse bpm'),
            _smallField('respiratory_rate', 'Resp rate'),
            _smallField('oxygen_saturation', 'SpO2'),
          ],
        ),
        const SizedBox(height: 18),
        _field('diagnosis', 'Diagnosis', lines: 2),
        const SizedBox(height: 12),
        _field('advice', 'Advice', lines: 3),
        const SizedBox(height: 12),
        _field('notes', 'Notes', lines: 3),
        const SizedBox(height: 18),
        _rowsHeader(
          context,
          'Diagnostic tests advice',
          'Add test',
          _addTestRow,
        ),
        if (_tests.isEmpty)
          const Text(
            'No diagnostic tests added yet.',
            style: TextStyle(color: AppColors.muted),
          )
        else
          ..._tests.asMap().entries.map(
            (entry) => _testCard(entry.key, entry.value),
          ),
        const SizedBox(height: 18),
        _rowsHeader(context, 'Medicines', 'Add medicine', _addMedicineRow),
        if (_meds.isEmpty)
          const Text(
            'Add at least one medicine row before saving.',
            style: TextStyle(color: AppColors.muted),
          )
        else
          ..._meds.asMap().entries.map(
            (entry) => _medicineCard(entry.key, entry.value),
          ),
        const SizedBox(height: 18),
        SwitchListTile(
          value: _visibleToPatient,
          onChanged: (value) => setState(() => _visibleToPatient = value),
          contentPadding: EdgeInsets.zero,
          title: const Text('Visible to patient'),
          subtitle: const Text(
            'Turn this off if the prescription should stay hidden for now.',
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded),
          label: Text(
            _saving
                ? 'Saving'
                : c.isEditMode
                ? 'Update prescription'
                : 'Create prescription',
          ),
        ),
      ],
    );
  }

  Future<void> _loadAppointments() async {
    if (!widget.session.isAuthenticated) return;
    setState(() {
      _loadingAppointments = true;
      _error = null;
      _message = null;
    });
    try {
      final appointments = await widget.session.withFreshToken(
        (accessToken) =>
            _repository.fetchDoctorAppointments(accessToken: accessToken),
      );
      if (!mounted) return;
      setState(() => _appointments = appointments);
      _ensureRequestedAppointmentLoaded();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendly(error));
    } finally {
      if (mounted) setState(() => _loadingAppointments = false);
    }
  }

  void _ensureRequestedAppointmentLoaded() {
    final requestedId = widget.initialAppointmentId;
    if (requestedId == null) return;
    if (!_appointments.any((item) => item.id == requestedId)) return;
    if (_selectedAppointmentId == requestedId && _context != null) return;
    _loadDraftContext(requestedId);
  }

  Future<void> _loadDraftContext(int appointmentId) async {
    setState(() {
      _selectedAppointmentId = appointmentId;
      _loadingContext = true;
      _error = null;
      _message = null;
    });
    try {
      final contextData = await widget.session.withFreshToken(
        (accessToken) => _repository.fetchDoctorDraftContext(
          appointmentId: appointmentId,
          accessToken: accessToken,
        ),
      );
      if (!mounted) return;
      _applyContext(contextData);
      setState(() => _context = contextData);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _context = null;
        _error = _friendly(error);
      });
    } finally {
      if (mounted) setState(() => _loadingContext = false);
    }
  }

  void _applyContext(DoctorPrescriptionDraftContext contextData) {
    final source = contextData.existingPrescription ?? contextData.defaults;
    for (final entry in _f.entries) {
      final map = {
        'title': source.title,
        'history': source.history,
        'chief_complaints': source.chiefComplaints,
        'observation': source.observation,
        'age': source.age,
        'gender': source.gender,
        'height_cm': source.heightCm,
        'weight_kg': source.weightKg,
        'temperature_c': source.temperatureC,
        'blood_pressure_systolic': source.bloodPressureSystolic,
        'blood_pressure_diastolic': source.bloodPressureDiastolic,
        'pulse_bpm': source.pulseBpm,
        'respiratory_rate': source.respiratoryRate,
        'oxygen_saturation': source.oxygenSaturation,
        'diagnosis': source.diagnosis,
        'advice': source.advice,
        'notes': source.notes,
      };
      entry.value.text = map[entry.key] ?? '';
    }
    _visibleToPatient = source.isVisibleToPatient;
    _resetRows(
      _tests,
      source.diagnosticTests
          .map((e) => {'test_name': e.testName, 'instructions': e.instructions})
          .toList(),
      testMode: true,
    );
    _resetRows(
      _meds,
      source.medicines
          .map(
            (e) => {
              'brand_name': e.brandName,
              'strength': e.strength,
              'timing': e.timing,
              'duration': e.duration,
              'notes': e.notes,
            },
          )
          .toList(),
    );
  }

  Future<void> _save() async {
    final c = _context;
    if (c == null) return;
    final medicines = _meds
        .map(_medicineItem)
        .where((item) => item.brandName.isNotEmpty)
        .toList();
    if (medicines.isEmpty) {
      setState(() => _error = 'Add at least one medicine row before saving.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });
    final payload = <String, dynamic>{
      'appointment': c.appointmentId,
      'title': _text('title'),
      'history': _text('history'),
      'chief_complaints': _text('chief_complaints'),
      'observation': _text('observation'),
      'diagnosis': _text('diagnosis'),
      'advice': _text('advice'),
      'notes': _text('notes'),
      'is_visible_to_patient': _visibleToPatient,
      'diagnostic_tests': _tests
          .map(_testItem)
          .where((item) => item.testName.isNotEmpty)
          .map((item) => item.toJson())
          .toList(),
      'medicines': medicines.map((item) => item.toJson()).toList(),
    };
    _putIf(payload, 'age', int.tryParse(_text('age')));
    _putIf(payload, 'gender', _normalizeGender(_text('gender')));
    _putIf(payload, 'height_cm', _blankToNull(_text('height_cm')));
    _putIf(payload, 'weight_kg', _blankToNull(_text('weight_kg')));
    _putIf(payload, 'temperature_c', _blankToNull(_text('temperature_c')));
    _putIf(
      payload,
      'blood_pressure_systolic',
      int.tryParse(_text('blood_pressure_systolic')),
    );
    _putIf(
      payload,
      'blood_pressure_diastolic',
      int.tryParse(_text('blood_pressure_diastolic')),
    );
    _putIf(payload, 'pulse_bpm', int.tryParse(_text('pulse_bpm')));
    _putIf(
      payload,
      'respiratory_rate',
      int.tryParse(_text('respiratory_rate')),
    );
    _putIf(
      payload,
      'oxygen_saturation',
      int.tryParse(_text('oxygen_saturation')),
    );
    try {
      await widget.session.withFreshToken((accessToken) {
        if (c.isEditMode && c.existingPrescription != null) {
          return _repository.updateDoctorPrescription(
            prescriptionId: c.existingPrescription!.id,
            payload: Map<String, dynamic>.from(payload)..remove('appointment'),
            accessToken: accessToken,
          );
        }
        return _repository.createDoctorPrescription(
          payload: payload,
          accessToken: accessToken,
        );
      });
      if (!mounted) return;
      await _advanceToNextPatient(c.appointmentId, wasEdit: c.isEditMode);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendly(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _advanceToNextPatient(int currentAppointmentId, {required bool wasEdit}) async {
    await _loadAppointments();
    if (!mounted) return;
    final nextId = _nextAppointmentIdAfter(currentAppointmentId);
    if (nextId == null) {
      setState(() {
        _context = null;
        _selectedAppointmentId = null;
        _message = wasEdit
            ? 'Prescription updated. No more patients are waiting.'
            : 'Prescription saved. No more patients are waiting.';
      });
      return;
    }
    await _loadDraftContext(nextId);
    if (!mounted) return;
    setState(() {
      _message = wasEdit
          ? 'Prescription updated. Moved to the next patient.'
          : 'Prescription saved. Moved to the next patient.';
    });
  }

  int? _nextAppointmentIdAfter(int currentAppointmentId) {
    final ready = _appointments.where((item) => item.isPrescriptionReady).toList();
    if (ready.isEmpty) return null;
    final currentIndex = ready.indexWhere((item) => item.id == currentAppointmentId);
    if (currentIndex >= 0 && currentIndex + 1 < ready.length) {
      return ready[currentIndex + 1].id;
    }
    final fallback = ready.where((item) => item.id != currentAppointmentId).toList();
    return fallback.isEmpty ? null : fallback.first.id;
  }

  Widget _profileFacts(DoctorPrescriptionDraftContext c) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F8F7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFDDE8E6)),
    ),
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _chip('DOB ${c.patient.dateOfBirth.isEmpty ? 'Not set' : c.patient.dateOfBirth}'),
        _chip('Age ${_text('age').isEmpty ? 'Not set' : _text('age')}'),
        _chip('Gender ${_displayGender(_text('gender'))}'),
      ],
    ),
  );

  String _displayGender(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Not set';
    final normalized = value.toLowerCase().replaceAll('_', ' ');
    return normalized.split(' ').where((part) => part.isNotEmpty).map((part) => '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
  }
  Widget _field(String key, String label, {int lines = 1}) => TextField(
    controller: _f[key],
    minLines: lines,
    maxLines: lines == 1 ? 1 : lines + 1,
    decoration: InputDecoration(labelText: label),
  );
  Widget _smallField(String key, String label) => SizedBox(
    width: 170,
    child: TextField(
      controller: _f[key],
      decoration: InputDecoration(labelText: label),
    ),
  );
  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFE7F4F1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
  Widget _rowsHeader(
    BuildContext context,
    String title,
    String action,
    VoidCallback onTap,
  ) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded),
        label: Text(action),
      ),
    ],
  );
  Widget _testCard(int index, Map<String, TextEditingController> row) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Test ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeRow(_tests, row),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: row['test_name'],
                  decoration: const InputDecoration(labelText: 'Test name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: row['instructions'],
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Instructions'),
                ),
              ],
            ),
          ),
        ),
      );
  Widget _medicineCard(
    int index,
    Map<String, TextEditingController> row,
  ) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Medicine ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeRow(_meds, row),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: row['brand_name'],
              decoration: const InputDecoration(labelText: 'Brand name'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: row['strength'],
                    decoration: const InputDecoration(labelText: 'Strength'),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: row['timing'],
                    decoration: const InputDecoration(labelText: 'Timing'),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: row['duration'],
                    decoration: const InputDecoration(labelText: 'Duration'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: row['notes'],
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
    ),
  );

  void _addTestRow() => setState(
    () => _tests.add({
      'test_name': TextEditingController(),
      'instructions': TextEditingController(),
    }),
  );
  void _addMedicineRow() => setState(
    () => _meds.add({
      'brand_name': TextEditingController(),
      'strength': TextEditingController(),
      'timing': TextEditingController(),
      'duration': TextEditingController(),
      'notes': TextEditingController(),
    }),
  );
  void _removeRow(
    List<Map<String, TextEditingController>> rows,
    Map<String, TextEditingController> row,
  ) {
    for (final controller in row.values) {
      controller.dispose();
    }
    setState(() => rows.remove(row));
  }

  void _resetRows(
    List<Map<String, TextEditingController>> rows,
    List<Map<String, String>> values, {
    bool testMode = false,
  }) {
    _disposeRows(rows);
    rows.clear();
    if (values.isEmpty) {
      rows.add(
        testMode
            ? {
                'test_name': TextEditingController(),
                'instructions': TextEditingController(),
              }
            : {
                'brand_name': TextEditingController(),
                'strength': TextEditingController(),
                'timing': TextEditingController(),
                'duration': TextEditingController(),
                'notes': TextEditingController(),
              },
      );
      return;
    }
    for (final value in values) {
      rows.add({
        for (final entry in value.entries)
          entry.key: TextEditingController(text: entry.value),
      });
    }
  }

  void _disposeRows(List<Map<String, TextEditingController>> rows) {
    for (final row in rows) {
      for (final controller in row.values) {
        controller.dispose();
      }
    }
  }

  DoctorPrescriptionDiagnosticTestItem _testItem(
    Map<String, TextEditingController> row,
  ) => DoctorPrescriptionDiagnosticTestItem(
    testName: row['test_name']!.text.trim(),
    instructions: row['instructions']!.text.trim(),
  );
  DoctorPrescriptionMedicineItem _medicineItem(
    Map<String, TextEditingController> row,
  ) => DoctorPrescriptionMedicineItem(
    brandName: row['brand_name']!.text.trim(),
    strength: row['strength']!.text.trim(),
    timing: row['timing']!.text.trim(),
    duration: row['duration']!.text.trim(),
    notes: row['notes']!.text.trim(),
  );
  String _text(String key) => _f[key]!.text.trim();
  String? _blankToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();
  String? _normalizeGender(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    final upper = normalized.toUpperCase().replaceAll(' ', '_');
    switch (upper) {
      case 'MALE':
      case 'FEMALE':
      case 'OTHER':
      case 'PREFER_NOT_TO_SAY':
        return upper;
      default:
        return normalized;
    }
  }
  void _putIf(Map<String, dynamic> payload, String key, dynamic value) {
    if (value != null && (!(value is String) || value.trim().isNotEmpty))
      payload[key] = value;
  }

  String _friendly(ApiException error) {
    if (error.statusCode == 401)
      return 'Your session expired. Please sign in again.';
    if (error.statusCode == 404)
      return 'This appointment is not prescription-ready yet, or the doctor prescription endpoint is not available on this backend yet.';
    if (error.statusCode == 400)
      return error.message.trim().isEmpty
          ? 'The backend rejected this prescription data. Please review the fields and try again.'
          : error.message;
    return 'Could not complete the prescription request right now.';
  }

  String _displayTime(String raw) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(raw.trim());
    if (m == null) return raw.trim();
    final hour = int.tryParse(m.group(1) ?? '');
    final minute = int.tryParse(m.group(2) ?? '');
    if (hour == null || minute == null) return raw.trim();
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$normalizedHour:${minute.toString().padLeft(2, '0')} $suffix';
  }
}










