import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/session/app_session_scope.dart';
import 'data/appointment_repository.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final AppointmentRepository _repository = AppointmentRepository();
  bool _isLoading = false;
  String? _errorMessage;
  List<AppointmentListItem> _appointments = const [];
  String _filter = 'Upcoming';
  String? _lastToken;

  static const _filters = ['Upcoming', 'Missed', 'Completed', 'Cancelled', 'All'];

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

    final filtered = _filteredAppointments();

    return ListView(
      padding: const EdgeInsets.all(20),
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
                selected: _filter == item,
                onSelected: (_) {
                  setState(() {
                    _filter = item;
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!_isLoading && _errorMessage != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appointments unavailable',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadAppointments,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        if (!_isLoading && _errorMessage == null && filtered.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No $_filter appointments found yet.',
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          ),
        if (filtered.isNotEmpty) ...[
          Text(
            '${filtered.length} $_filter appointment(s)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final appointment in filtered) ...[
            _AppointmentTile(appointment: appointment),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  List<AppointmentListItem> _filteredAppointments() {
    switch (_filter) {
      case 'Missed':
        return _appointments.where((item) => item.isMissed).toList();
      case 'Completed':
        return _appointments.where((item) => item.isCompleted).toList();
      case 'Cancelled':
        return _appointments.where((item) => item.isCancelled).toList();
      case 'All':
        return _appointments;
      case 'Upcoming':
      default:
        return _appointments.where((item) => item.isUpcoming).toList();
    }
  }

  Future<void> _loadAppointments() async {
    final session = AppSessionScope.of(context);
    if (!session.isAuthenticated) {
      setState(() {
        _appointments = const [];
        _errorMessage = 'Please sign in with the backend before loading appointments.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appointments = await session.withFreshToken(
        (accessToken) => _repository.fetchAppointments(accessToken: accessToken),
      );
      if (!mounted) return;
      setState(() {
        _appointments = appointments;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _appointments = const [];
        _errorMessage =
            'Could not load appointments. Check auth and backend availability.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appointment});

  final AppointmentListItem appointment;

  Color _statusColor() {
    if (appointment.isCompleted) return AppColors.success;
    if (appointment.isCancelled) return AppColors.danger;
    if (appointment.isMissed) return AppColors.warning;
    return AppColors.primaryDark;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    appointment.doctorName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor().withAlpha(28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    appointment.statusDisplay.isEmpty
                        ? appointment.status
                        : appointment.statusDisplay,
                    style: TextStyle(
                      color: _statusColor(),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(appointment.specialty),
            const SizedBox(height: 12),
            Text(
              '${appointment.dateLabel} • ${appointment.timeLabel}',
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${appointment.mode} • ${appointment.fee}',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
