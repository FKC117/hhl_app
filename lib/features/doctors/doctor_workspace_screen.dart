import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/session/app_session.dart';
import '../../core/session/app_session_scope.dart';
import '../prescriptions/data/doctor_prescription_models.dart';
import '../prescriptions/data/prescriptions_repository.dart';
import '../prescriptions/doctor_prescription_screen.dart';
import '../profile/profile_screen.dart';
import 'doctor_schedule_screen.dart';

class DoctorWorkspaceScreen extends StatefulWidget {
  const DoctorWorkspaceScreen({super.key});

  @override
  State<DoctorWorkspaceScreen> createState() => _DoctorWorkspaceScreenState();
}

class _DoctorWorkspaceScreenState extends State<DoctorWorkspaceScreen> {
  final PrescriptionsRepository _repository = PrescriptionsRepository();

  int _currentIndex = 0;
  int? _selectedAppointmentId;
  String _queueFilter = 'Pending';
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastToken;
  List<DoctorPrescriptionAppointmentItem> _appointments = const [];

  static const _filters = ['Pending', 'Completed', 'All'];

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    if (_lastToken != session.accessToken) {
      _lastToken = session.accessToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAppointments();
        }
      });
    }

    final wide = MediaQuery.of(context).size.width >= 1120;
    final sections = _sections;
    final title = sections[_currentIndex].title;
    final subtitle = sections[_currentIndex].subtitle;
    final body = _buildSection(session);

    if (wide) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F7F6),
        body: SafeArea(
          child: Row(
            children: [
              _DoctorSidebar(
                sections: sections,
                currentIndex: _currentIndex,
                doctorName: session.currentUser?.fullName ?? 'Doctor',
                doctorEmail: session.currentUser?.email ?? '',
                onSelect: (index) => setState(() => _currentIndex = index),
                onLogout: () async {
                  await session.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 24, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DoctorHeader(title: title, subtitle: subtitle),
                      const SizedBox(height: 18),
                      Expanded(child: body),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F7F6),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await session.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: body,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule_rounded), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check_rounded), label: 'Queue'),
          NavigationDestination(icon: Icon(Icons.edit_note_outlined), selectedIcon: Icon(Icons.edit_note_rounded), label: 'Prescribe'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  List<_DoctorSection> get _sections => const [
    _DoctorSection(title: 'Doctor Overview', subtitle: 'Today\'s queue and fast actions'),
    _DoctorSection(title: 'Schedule Setup', subtitle: 'Consultation slots and availability'),
    _DoctorSection(title: 'Appointment Queue', subtitle: 'Pending and completed visits'),
    _DoctorSection(title: 'Prescription Desk', subtitle: 'Consult and prescribe per appointment'),
    _DoctorSection(title: 'Profile', subtitle: 'Doctor account details'),
  ];

  Widget _buildSection(AppSession session) {
    switch (_currentIndex) {
      case 0:
        return _buildOverview();
      case 1:
        return DoctorScheduleScreen(session: session);
      case 2:
        return _buildQueue();
      case 3:
        return DoctorPrescriptionScreen(
          session: session,
          initialAppointmentId: _selectedAppointmentId,
        );
      case 4:
        return const ProfileScreen();
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    final pending = _appointments.where((item) { final status = item.status.toUpperCase(); return status == 'BOOKED' || status == 'CONFIRMED'; }).toList();
    final completed = _appointments.where((item) => item.status.toUpperCase() == 'COMPLETED').toList();
    final next = pending.isNotEmpty ? pending.first : null;

    return ListView(
      children: [
        if (_errorMessage != null) _statusBanner(_errorMessage!, AppColors.danger),
        if (_isLoading) const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(child: CircularProgressIndicator()),
        ),
        SizedBox(
          height: 174,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _metricCard('Pending', '${pending.length}', Icons.hourglass_top_rounded, const Color(0xFFFFF3DE)),
              const SizedBox(width: 14),
              _metricCard('Completed', '${completed.length}', Icons.task_alt_rounded, const Color(0xFFE5F6EE)),
              const SizedBox(width: 14),
              _metricCard('All visits', '${_appointments.length}', Icons.calendar_month_rounded, const Color(0xFFE5EEF9)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Consultation flow', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 10),
                const Text('Review the next paid patient, start consultation, write prescription, then move to the next appointment.'),
                const SizedBox(height: 18),
                if (next == null)
                  const Text('No paid appointments are waiting right now.', style: TextStyle(color: AppColors.muted))
                else ...[
                  Text(next.patientName, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(next.subtitle),
                  if (next.patientNote.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(next.patientNote, style: const TextStyle(color: AppColors.muted)),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _openPrescription(next.id),
                        icon: const Icon(Icons.play_circle_fill_rounded),
                        label: const Text('Start consultation'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _currentIndex = 2),
                        icon: const Icon(Icons.list_alt_rounded),
                        label: const Text('Open queue'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSetup() {
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Clinic schedule designer', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 10),
                const Text('This is now separated for doctors. The next backend hookup is schedule creation and slot publishing.'),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: const [
                    _ScheduleCard(title: 'In-clinic chamber', subtitle: 'Mon, Tue, Thu', hours: '5:00 PM - 9:00 PM', fee: 'BDT 800'),
                    _ScheduleCard(title: 'Online consultation', subtitle: 'Sat, Sun', hours: '8:00 PM - 10:00 PM', fee: 'BDT 600'),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(18)),
                  child: const Text('Schedule save/publish is intentionally left unbound until we wire the doctor schedule backend API.'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueue() {
    final items = _filteredAppointments();
    return ListView(
      children: [
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = _filters[index];
              return ChoiceChip(
                label: Text(item),
                selected: _queueFilter == item,
                onSelected: (_) => setState(() => _queueFilter = item),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading) const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
        if (!_isLoading && _errorMessage != null) _statusBanner(_errorMessage!, AppColors.danger),
        if (!_isLoading && _errorMessage == null && items.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No appointments in this queue right now.', style: TextStyle(color: AppColors.muted)))),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.patientName, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 18))),
                      _statusChip(item),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item.subtitle),
                  if (item.patientPhone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Phone: ${item.patientPhone}', style: const TextStyle(color: AppColors.muted)),
                  ],
                  if (item.patientNote.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(item.patientNote, style: const TextStyle(color: AppColors.muted)),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _openPrescription(item.id),
                        icon: Icon(item.status.toUpperCase() == 'COMPLETED' ? Icons.description_rounded : Icons.play_circle_fill_rounded),
                        label: Text(item.status.toUpperCase() == 'COMPLETED' ? 'Open prescription' : 'Start consultation'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _selectedAppointmentId = item.id),
                        icon: const Icon(Icons.push_pin_outlined),
                        label: const Text('Pin for prescription'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  List<DoctorPrescriptionAppointmentItem> _filteredAppointments() {
    switch (_queueFilter) {
      case 'Completed':
        return _appointments.where((item) => item.status.toUpperCase() == 'COMPLETED').toList();
      case 'All':
        return _appointments;
      case 'Pending':
      default:
        return _appointments.where((item) { final status = item.status.toUpperCase(); return status == 'BOOKED' || status == 'CONFIRMED'; }).toList();
    }
  }

  Future<void> _loadAppointments() async {
    final session = AppSessionScope.of(context);
    if (!session.isAuthenticated) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final appointments = await session.withFreshToken(
        (accessToken) => _repository.fetchDoctorAppointments(accessToken: accessToken),
      );
      if (!mounted) return;
      setState(() => _appointments = appointments);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.statusCode == 404 ? 'Doctor appointment queue endpoint is not available yet.' : 'Could not load the doctor queue right now.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openPrescription(int appointmentId) {
    setState(() {
      _selectedAppointmentId = appointmentId;
      _currentIndex = 3;
    });
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 172,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: color, foregroundColor: AppColors.ink, child: Icon(icon)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 24)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _statusChip(DoctorPrescriptionAppointmentItem item) {
    final done = item.status.toUpperCase() == 'COMPLETED';
    final color = done ? AppColors.success : AppColors.primaryDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withAlpha(24), borderRadius: BorderRadius.circular(999)),
      child: Text(item.statusDisplay, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _statusBanner(String message, Color color) {
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
}

class _DoctorSection {
  const _DoctorSection({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class _DoctorHeader extends StatelessWidget {
  const _DoctorHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D8B82), Color(0xFF164A61)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Color(0xFFD7F3EE), fontSize: 14)),
        ],
      ),
    );
  }
}

class _DoctorSidebar extends StatelessWidget {
  const _DoctorSidebar({required this.sections, required this.currentIndex, required this.doctorName, required this.doctorEmail, required this.onSelect, required this.onLogout});

  final List<_DoctorSection> sections;
  final int currentIndex;
  final String doctorName;
  final String doctorEmail;
  final ValueChanged<int> onSelect;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: const BoxDecoration(color: Color(0xFF123C48)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(radius: 22, backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark, child: Icon(Icons.medical_services_rounded)),
                const SizedBox(height: 12),
                Text(doctorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 4),
                Text(doctorEmail, style: const TextStyle(color: Color(0xFFBED5D9))),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < sections.length; i++) ...[
            _SidebarButton(
              title: sections[i].title,
              selected: i == currentIndex,
              onTap: () => onSelect(i),
            ),
            const SizedBox(height: 8),
          ],
          const Spacer(),
          FilledButton.icon(
            onPressed: onLogout,
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({required this.title, required this.selected, required this.onTap});

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white.withAlpha(16),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(title, style: TextStyle(color: selected ? AppColors.primaryDark : Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.title, required this.subtitle, required this.hours, required this.fee});

  final String title;
  final String subtitle;
  final String hours;
  final String fee;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(color: const Color(0xFFF5FBFA), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFD7E7E4))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 10),
            Text(hours, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(fee, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}





