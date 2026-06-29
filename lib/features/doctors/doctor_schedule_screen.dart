
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/session/app_session.dart';
import 'data/doctor_repository.dart';
import 'data/doctor_schedule_management.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key, required this.session});

  final AppSession session;

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  final DoctorRepository _repository = DoctorRepository();
  final TextEditingController _onlineFeeController = TextEditingController();
  final TextEditingController _offlineFeeController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _slotDurationController = TextEditingController(text: '30');
  final TextEditingController _maxPatientsController = TextEditingController(text: '10');

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isActive = true;
  bool _hasLoadedOnce = false;
  int? _editingScheduleId;
  String _selectedMode = 'ONLINE';
  int _selectedWeekday = 0;
  String? _errorMessage;
  String? _successMessage;
  String? _lastToken;
  List<MyDoctorSchedule> _schedules = const [];
  MyDoctorProfile? _profile;

  static const _weekdays = <MapEntry<int, String>>[
    MapEntry(0, 'Monday'),
    MapEntry(1, 'Tuesday'),
    MapEntry(2, 'Wednesday'),
    MapEntry(3, 'Thursday'),
    MapEntry(4, 'Friday'),
    MapEntry(5, 'Saturday'),
    MapEntry(6, 'Sunday'),
  ];

  @override
  void dispose() {
    _onlineFeeController.dispose();
    _offlineFeeController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _slotDurationController.dispose();
    _maxPatientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lastToken != widget.session.accessToken) {
      _lastToken = widget.session.accessToken;
      _hasLoadedOnce = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadData();
      });
    } else if (!_hasLoadedOnce && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadData();
      });
    }

    return ListView(
      children: [
        if (_successMessage != null) _banner(_successMessage!, AppColors.success),
        if (_errorMessage != null) _banner(_errorMessage!, AppColors.danger),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chamber time and consultation fees',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isSaving ? null : _startNewSchedule,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New slot'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap an existing chamber time to edit it, or create a new one if none exists yet.',
                ),
                const SizedBox(height: 18),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  SizedBox(
                    height: 132,
                    child: _schedules.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5FBFA),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFD7E7E4)),
                            ),
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'No existing chamber time found. Create your first slot below.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _schedules.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final item = _schedules[index];
                              return _ScheduleCard(
                                schedule: item,
                                selected: item.id == _editingScheduleId,
                                onTap: () => _loadScheduleIntoForm(item),
                              );
                            },
                          ),
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _onlineFeeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Online fee'),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _offlineFeeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Offline fee'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedMode,
                        items: const [
                          DropdownMenuItem(value: 'ONLINE', child: Text('Online consultation')),
                          DropdownMenuItem(value: 'OFFLINE', child: Text('In-clinic chamber')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedMode = value);
                        },
                        decoration: const InputDecoration(labelText: 'Mode'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedWeekday,
                        items: _weekdays.map((item) => DropdownMenuItem<int>(value: item.key, child: Text(item.value))).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedWeekday = value);
                        },
                        decoration: const InputDecoration(labelText: 'Weekday'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _startTimeController,
                        decoration: const InputDecoration(labelText: 'Start time', hintText: '09:00'),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _endTimeController,
                        decoration: const InputDecoration(labelText: 'End time', hintText: '13:00'),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _slotDurationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Slot minutes'),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _maxPatientsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max patients'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Schedule active'),
                  subtitle: const Text('Inactive schedules stay saved but are not bookable.'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'Saving' : _editingScheduleId == null ? 'Create chamber time' : 'Update chamber time'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadData() async {
    if (!widget.session.isAuthenticated) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final profile = await widget.session.withFreshToken(
        (accessToken) => _repository.fetchMyDoctorProfile(accessToken: accessToken),
      );
      final schedules = await widget.session.withFreshToken(
        (accessToken) => _repository.fetchMySchedules(accessToken: accessToken),
      );
      if (!mounted) return;
      _hasLoadedOnce = true;
      _profile = profile;
      _onlineFeeController.text = profile.consultationFeeOnline;
      _offlineFeeController.text = profile.consultationFeeOffline;
      _schedules = schedules;
      if (_editingScheduleId == null) {
        if (schedules.isNotEmpty) {
          _loadScheduleIntoForm(schedules.first, announce: false);
        } else {
          _editingScheduleId = null;
          _selectedMode = 'ONLINE';
          _selectedWeekday = 0;
          _startTimeController.text = '';
          _endTimeController.text = '';
          _slotDurationController.text = '30';
          _maxPatientsController.text = '10';
          _isActive = true;
        }
      }
      setState(() {});
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.statusCode == 404
            ? 'Doctor schedule endpoints are not available on this backend yet.'
            : 'Could not load your chamber schedule right now.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final onlineFee = _onlineFeeController.text.trim();
    final offlineFee = _offlineFeeController.text.trim();
    final startTime = _normalizeTime(_startTimeController.text);
    final endTime = _normalizeTime(_endTimeController.text);
    final slotDuration = int.tryParse(_slotDurationController.text.trim());
    final maxPatients = int.tryParse(_maxPatientsController.text.trim());

    if (onlineFee.isEmpty || offlineFee.isEmpty) {
      setState(() => _errorMessage = 'Enter both online and offline consultation fees.');
      return;
    }
    if (startTime == null || endTime == null) {
      setState(() => _errorMessage = 'Enter valid times like 09:00 and 13:00.');
      return;
    }
    if (slotDuration == null || slotDuration <= 0 || maxPatients == null || maxPatients <= 0) {
      setState(() => _errorMessage = 'Slot duration and max patients must be positive numbers.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final profilePayload = {
      'consultation_fee_online': onlineFee,
      'consultation_fee_offline': offlineFee,
    };
    final schedulePayload = {
      'mode': _selectedMode,
      'weekday': _selectedWeekday,
      'start_time': startTime,
      'end_time': endTime,
      'slot_duration_minutes': slotDuration,
      'max_patients': maxPatients,
      'is_active': _isActive,
    };
    try {
      await widget.session.withFreshToken(
        (accessToken) => _repository.updateMyDoctorProfile(payload: profilePayload, accessToken: accessToken),
      );
      if (_editingScheduleId == null) {
        await widget.session.withFreshToken(
          (accessToken) => _repository.createMySchedule(payload: schedulePayload, accessToken: accessToken),
        );
      } else {
        await widget.session.withFreshToken(
          (accessToken) => _repository.updateMySchedule(scheduleId: _editingScheduleId!, payload: schedulePayload, accessToken: accessToken),
        );
      }
      if (!mounted) return;
      await _loadData();
      setState(() {
        _successMessage = _editingScheduleId == null
            ? 'Chamber time created successfully.'
            : 'Chamber time updated successfully.';
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.statusCode == 400
            ? 'The backend rejected this schedule. Check overlap, time range, or required fields.'
            : error.statusCode == 404
                ? 'Doctor schedule save endpoint is not available yet.'
                : 'Could not save your chamber schedule right now.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _startNewSchedule() {
    setState(() {
      _editingScheduleId = null;
      _selectedMode = 'ONLINE';
      _selectedWeekday = 0;
      _startTimeController.text = '';
      _endTimeController.text = '';
      _slotDurationController.text = '30';
      _maxPatientsController.text = '10';
      _isActive = true;
      _errorMessage = null;
      _successMessage = 'Creating a new chamber time.';
    });
  }

  void _loadScheduleIntoForm(MyDoctorSchedule schedule, {bool announce = true}) {
    setState(() {
      _editingScheduleId = schedule.id;
      _selectedMode = schedule.mode.isEmpty ? 'ONLINE' : schedule.mode;
      _selectedWeekday = schedule.weekday;
      _startTimeController.text = _displayTimeInput(schedule.startTime);
      _endTimeController.text = _displayTimeInput(schedule.endTime);
      _slotDurationController.text = '${schedule.slotDurationMinutes}';
      _maxPatientsController.text = '${schedule.maxPatients}';
      _isActive = schedule.isActive;
      _errorMessage = null;
      if (announce) {
        _successMessage = 'Editing ${schedule.title}.';
      }
    });
  }

  Widget _banner(String message, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(18)),
        child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }

  String? _normalizeTime(String raw) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$').firstMatch(raw.trim());
    if (match == null) return null;
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final second = int.tryParse(match.group(3) ?? '0');
    if (hour == null || minute == null || second == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59) return null;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }

  String _displayTimeInput(String raw) {
    final normalized = _normalizeTime(raw);
    if (normalized == null) return raw.trim();
    return normalized.substring(0, 5);
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule, required this.selected, required this.onTap});

  final MyDoctorSchedule schedule;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE8F6F3) : const Color(0xFFF5FBFA),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.primary : const Color(0xFFD7E7E4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(schedule.title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(schedule.subtitle),
              const Spacer(),
              Text(schedule.isActive ? 'Active' : 'Inactive', style: TextStyle(color: schedule.isActive ? AppColors.success : AppColors.muted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
