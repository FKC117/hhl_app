import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/session/app_session.dart';
import '../../core/session/app_session_scope.dart';
import '../../shared/widgets/info_card.dart';
import '../appointments/data/appointment_repository.dart';
import 'data/doctor.dart';
import 'data/doctor_repository.dart';
import 'logic/doctors_controller.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final DoctorsController _controller = DoctorsController();
  final TextEditingController _searchController = TextEditingController();
  AppointmentDraftSuccess? _lastDraftSuccess;

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const _DoctorsIntro(),
            const SizedBox(height: 14),
            _DoctorFilters(
              controller: _searchController,
              departments: _controller.departments,
              selectedDepartment: _controller.selectedDepartment,
              onDepartmentSelected: _controller.updateDepartment,
              onSearchSubmitted: _controller.updateSearch,
            ),
            const SizedBox(height: 16),
            if (_lastDraftSuccess != null) ...[
              _AppointmentDraftSuccessCard(
                success: _lastDraftSuccess!,
                onDismiss: () {
                  setState(() {
                    _lastDraftSuccess = null;
                  });
                },
              ),
              const SizedBox(height: 18),
            ],
            if (_controller.isLoading) const _LoadingState(),
            if (!_controller.isLoading && _controller.errorMessage != null)
              _ErrorState(
                message: _controller.errorMessage!,
                onRetry: _controller.retry,
              ),
            if (!_controller.isLoading &&
                _controller.errorMessage == null &&
                _controller.doctors.isEmpty)
              const _EmptyState(),
            if (!_controller.isLoading &&
                _controller.errorMessage == null &&
                _controller.doctors.isNotEmpty) ...[
              Text(
                '${_controller.doctors.length} doctors available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final doctor in _controller.doctors) ...[
                _DoctorCard(
                  doctor: doctor,
                  onViewProfile: () =>
                      _openDoctorSheet(context, doctor, session),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ],
        );
      },
    );
  }

  Future<void> _openDoctorSheet(
    BuildContext context,
    Doctor doctor,
    AppSession session,
  ) async {
    final draftSuccess = await showModalBottomSheet<AppointmentDraftSuccess>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _DoctorDetailsSheet(doctor: doctor, session: session),
    );

    if (!mounted || draftSuccess == null) return;

    final finalResult = await Navigator.of(context).push<AppointmentDraftSuccess>(
      MaterialPageRoute(
        builder: (_) => _AppointmentPaymentScreen(
          draft: draftSuccess,
          session: session,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      _lastDraftSuccess = finalResult ?? draftSuccess;
    });
  }
}

class _DoctorsIntro extends StatelessWidget {
  const _DoctorsIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123D3A), Color(0xFF0D8B82)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.medical_services_rounded,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Find the right doctor and move to slot booking.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorFilters extends StatelessWidget {
  const _DoctorFilters({
    required this.controller,
    required this.departments,
    required this.selectedDepartment,
    required this.onDepartmentSelected,
    required this.onSearchSubmitted,
  });

  final TextEditingController controller;
  final List<String> departments;
  final String selectedDepartment;
  final ValueChanged<String> onDepartmentSelected;
  final ValueChanged<String> onSearchSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: onSearchSubmitted,
          decoration: InputDecoration(
            hintText: 'Search doctor, specialty, or keyword',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              onPressed: () => onSearchSubmitted(controller.text),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: departments.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = departments[index];
              return ChoiceChip(
                label: Text(item),
                selected: selectedDepartment == item,
                onSelected: (_) => onDepartmentSelected(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: AppColors.danger),
                SizedBox(width: 10),
                Text(
                  'Backend unavailable',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No doctors found',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Try another search term or department filter once your backend has matching data.',
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor, required this.onViewProfile});

  final Doctor doctor;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F4F1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primaryDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialty,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.hospital,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF4EF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    doctor.fee,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(doctor.mode)),
                Chip(label: Text(doctor.experience)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              doctor.about,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                height: 1.4,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onViewProfile,
                child: const Text('View profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorDetailsSheet extends StatefulWidget {
  const _DoctorDetailsSheet({required this.doctor, required this.session});

  final Doctor doctor;
  final AppSession session;

  @override
  State<_DoctorDetailsSheet> createState() => _DoctorDetailsSheetState();
}

class AppointmentDraftSuccess {
  const AppointmentDraftSuccess({
    required this.draftId,
    required this.status,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.slotLabel,
    required this.mode,
    required this.fee,
    required this.note,
  });

  final int draftId;
  final String status;
  final String doctorName;
  final String specialty;
  final String date;
  final String slotLabel;
  final String mode;
  final String fee;
  final String note;

  bool get isBooked => status.toUpperCase() == 'BOOKED';
}

class _DoctorDetailsSheetState extends State<_DoctorDetailsSheet> {
  final _doctorRepository = DoctorRepository();
  final _appointmentRepository = AppointmentRepository();
  final _noteController = TextEditingController();

  Doctor? _detail;
  bool _loadingDetail = true;
  bool _loadingSlots = false;
  bool _submittingDraft = false;
  String? _detailError;
  String? _bookingError;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  DoctorSchedule? _selectedSchedule;
  AppointmentSlot? _selectedSlot;
  List<AppointmentSlot> _slots = const [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loadingDetail = true;
      _detailError = null;
    });

    try {
      final detail = await _doctorRepository.fetchDoctorDetail(
        widget.doctor.id,
      );
      setState(() {
        _detail = detail;
        _selectedSchedule = detail.schedules.isNotEmpty
            ? detail.schedules.first
            : null;
        _loadingDetail = false;
      });

      if (_selectedSchedule != null) {
        await _loadSlots();
      }
    } catch (_) {
      setState(() {
        _loadingDetail = false;
        _detailError =
            'Could not load doctor details right now. The detail endpoint may not be ready yet.';
      });
    }
  }

  Future<void> _loadSlots() async {
    final schedule = _selectedSchedule;
    if (schedule == null) return;

    setState(() {
      _loadingSlots = true;
      _bookingError = null;
      _selectedSlot = null;
    });

    try {
      final slots = await _appointmentRepository.fetchSlots(
        scheduleId: schedule.id,
        date: _formatDate(_selectedDate),
      );
      setState(() {
        _slots = slots.where((slot) => slot.isAvailable).toList();
      });
    } catch (_) {
      setState(() {
        _slots = const [];
        _bookingError =
            'Could not load slots. Make sure the slot endpoint is available for this schedule.';
      });
    } finally {
      setState(() {
        _loadingSlots = false;
      });
    }
  }

  Future<void> _submitDraft() async {
    final schedule = _selectedSchedule;
    final slot = _selectedSlot;

    if (!widget.session.isAuthenticated) {
      setState(() {
        _bookingError =
            'Please sign in with the backend before creating an appointment draft.';
      });
      return;
    }

    if (schedule == null || slot == null) {
      setState(() {
        _bookingError = 'Choose a schedule and a slot first.';
      });
      return;
    }

    setState(() {
      _submittingDraft = true;
      _bookingError = null;
    });

    try {
      final doctor = _detail ?? widget.doctor;
      final draft = await widget.session.withFreshToken(
        (accessToken) => _appointmentRepository.createDraft(
          scheduleId: schedule.id,
          appointmentDate: _formatDate(_selectedDate),
          appointmentTime: slot.time,
          patientNote: _noteController.text.trim(),
          accessToken: accessToken,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(
        AppointmentDraftSuccess(
          draftId: draft.id,
          status: draft.status,
          doctorName: doctor.name,
          specialty: doctor.specialty,
          date: _formatHumanDate(_selectedDate),
          slotLabel: slot.label,
          mode: schedule.mode,
          fee: doctor.fee,
          note: _noteController.text.trim(),
        ),
      );
    } catch (_) {
      setState(() {
        _bookingError =
            'Could not create the appointment draft. Check auth and backend validation.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submittingDraft = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = _detail ?? widget.doctor;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9D9D6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4F4F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryDark,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(doctor.specialty),
                        const SizedBox(height: 4),
                        Text(
                          doctor.hospital,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(label: 'Fee', value: doctor.fee),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Experience',
                      value: doctor.experience,
                    ),
                  ),
                ],
              ),
              if (_loadingDetail) ...[
                const SizedBox(height: 18),
                const LinearProgressIndicator(),
              ],
              if (_detailError != null) ...[
                const SizedBox(height: 18),
                Text(
                  _detailError!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                'About doctor',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                doctor.about,
                style: const TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 22),
              Text(
                'Choose schedule',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (doctor.schedules.isEmpty)
                const Text(
                  'No schedules were found in the doctor detail response yet.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final schedule in doctor.schedules)
                      ChoiceChip(
                        label: Text('${schedule.label} • ${schedule.mode}'),
                        selected: _selectedSchedule?.id == schedule.id,
                        onSelected: (_) async {
                          setState(() {
                            _selectedSchedule = schedule;
                          });
                          await _loadSlots();
                        },
                      ),
                  ],
                ),
              const SizedBox(height: 18),
              Text(
                'Choose date',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                    await _loadSlots();
                  }
                },
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(_formatDate(_selectedDate)),
              ),
              const SizedBox(height: 18),
              Text(
                'Available slots',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (_loadingSlots)
                const LinearProgressIndicator()
              else if (_slots.isEmpty)
                const Text(
                  'No slots loaded yet for the current schedule and date.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final slot in _slots)
                      ChoiceChip(
                        label: Text(slot.label),
                        selected: _selectedSlot?.time == slot.time,
                        onSelected: (_) {
                          setState(() {
                            _selectedSlot = slot;
                          });
                        },
                      ),
                  ],
                ),
              const SizedBox(height: 18),
              TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Patient note',
                  hintText: 'Routine consultation or symptoms summary',
                ),
              ),
              if (_bookingError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _bookingError!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 22),
              const InfoCard(
                title: 'Next backend step',
                subtitle:
                    'This sheet now tries to use the real doctor detail, slot lookup, and appointment draft endpoints.',
                icon: Icons.api_rounded,
                wide: true,
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _submittingDraft ? null : _submitDraft,
                child: _submittingDraft
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create appointment draft'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentPaymentScreen extends StatefulWidget {
  const _AppointmentPaymentScreen({
    required this.draft,
    required this.session,
  });

  final AppointmentDraftSuccess draft;
  final AppSession session;

  @override
  State<_AppointmentPaymentScreen> createState() =>
      _AppointmentPaymentScreenState();
}

class _AppointmentPaymentScreenState extends State<_AppointmentPaymentScreen> {
  final AppointmentRepository _repository = AppointmentRepository();

  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _completePayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final payment = await widget.session.withFreshToken(
        (accessToken) => _repository.initiatePayment(
          appointmentId: widget.draft.draftId,
          accessToken: accessToken,
        ),
      );

      final completedPayment = await widget.session.withFreshToken(
        (accessToken) => _repository.completeManualPayment(
          paymentId: payment.id,
          accessToken: accessToken,
        ),
      );

      final confirmed = await widget.session.withFreshToken(
        (accessToken) => _repository.confirmAppointment(
          appointmentId: widget.draft.draftId,
          paymentId: completedPayment.id,
          accessToken: accessToken,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(
        AppointmentDraftSuccess(
          draftId: confirmed.id,
          status: confirmed.status,
          doctorName: widget.draft.doctorName,
          specialty: widget.draft.specialty,
          date: widget.draft.date,
          slotLabel: widget.draft.slotLabel,
          mode: confirmed.mode.isEmpty ? widget.draft.mode : confirmed.mode,
          fee: confirmed.fee.isEmpty ? widget.draft.fee : confirmed.fee,
          note: widget.draft.note,
        ),
      );
    } catch (_) {
      setState(() {
        _errorMessage =
            'Could not complete payment and confirm the appointment. Check the backend payment flow.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const InfoCard(
              title: 'Payment confirmation',
              subtitle:
                  'For the local prototype, completing payment will mark the payment successful and confirm the appointment immediately.',
              icon: Icons.payment_rounded,
              wide: true,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.draft.doctorName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(widget.draft.specialty),
                    const SizedBox(height: 16),
                    _SummaryLine(label: 'Date', value: widget.draft.date),
                    const SizedBox(height: 8),
                    _SummaryLine(label: 'Time', value: widget.draft.slotLabel),
                    const SizedBox(height: 8),
                    _SummaryLine(label: 'Mode', value: widget.draft.mode),
                    const SizedBox(height: 8),
                    _SummaryLine(label: 'Amount', value: widget.draft.fee),
                    if (widget.draft.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SummaryLine(label: 'Note', value: widget.draft.note),
                    ],
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isProcessing ? null : _completePayment,
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Complete payment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentDraftSuccessCard extends StatelessWidget {
  const _AppointmentDraftSuccessCard({
    required this.success,
    required this.onDismiss,
  });

  final AppointmentDraftSuccess success;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final headline = success.isBooked
        ? 'Appointment booked'
        : 'Appointment saved';
    final metaStatus = success.status.toUpperCase();

    return Card(
      color: const Color(0xFFF2FBF7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF4EF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Appointment ID: ${success.draftId == 0 ? 'saved' : success.draftId} - Status: $metaStatus',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Dismiss',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryLine(label: 'Doctor', value: success.doctorName),
            const SizedBox(height: 8),
            _SummaryLine(label: 'Specialty', value: success.specialty),
            const SizedBox(height: 8),
            _SummaryLine(label: 'Date', value: success.date),
            const SizedBox(height: 8),
            _SummaryLine(label: 'Time', value: success.slotLabel),
            const SizedBox(height: 8),
            _SummaryLine(label: 'Mode', value: success.mode),
            const SizedBox(height: 8),
            _SummaryLine(label: 'Fee', value: success.fee),
            if (success.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              _SummaryLine(label: 'Note', value: success.note),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(
          color: AppColors.muted,
          height: 1.45,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _formatHumanDate(DateTime date) {
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
  final month = months[date.month - 1];
  return '$month ${date.day}, ${date.year}';
}
