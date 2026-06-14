import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/session/app_session_scope.dart';
import '../../shared/widgets/info_card.dart';
import 'data/ambulance_request_item.dart';
import 'data/emergency_contact.dart';
import 'logic/ambulance_requests_controller.dart';
import 'logic/ambulance_submit_controller.dart';
import 'logic/emergency_contacts_controller.dart';

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  final EmergencyContactsController _contactsController =
      EmergencyContactsController();
  final AmbulanceRequestsController _requestsController =
      AmbulanceRequestsController();
  final AmbulanceSubmitController _submitController =
      AmbulanceSubmitController();

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _lastToken;
  bool _loadedContacts = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadIfNeeded() {
    final session = AppSessionScope.of(context);
    if (!_loadedContacts) {
      _loadedContacts = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _contactsController.loadContacts();
        }
      });
    }

    if (_lastToken != session.accessToken) {
      _lastToken = session.accessToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _requestsController.loadRequests(session);
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    final session = AppSessionScope.of(context);
    final pickup = _pickupController.text.trim();
    final destination = _destinationController.text.trim();
    final contact = _contactController.text.trim();
    final notes = _notesController.text.trim();

    if (pickup.isEmpty || contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup address and contact number are required.'),
        ),
      );
      return;
    }

    final created = await _submitController.submit(
      session: session,
      pickupAddress: pickup,
      destinationAddress: destination,
      contactNumber: contact,
      notes: notes,
    );

    if (!mounted || !created) return;

    _pickupController.clear();
    _destinationController.clear();
    _contactController.clear();
    _notesController.clear();
    await _requestsController.loadRequests(session);
  }

  @override
  Widget build(BuildContext context) {
    _loadIfNeeded();
    final session = AppSessionScope.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _contactsController,
        _requestsController,
        _submitController,
      ]),
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const InfoCard(
              title: 'Urgent transport support',
              subtitle:
                  'Use this screen to request an ambulance, review recent requests, and see emergency numbers from the backend.',
              icon: Icons.emergency_outlined,
              wide: true,
            ),
            const SizedBox(height: 16),
            if (_submitController.message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _submitController.message!,
                  style: const TextStyle(color: AppColors.success),
                ),
              ),
            if (_submitController.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _submitController.errorMessage!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            _EmergencyWarningCard(
              isSignedIn: session.isAuthenticated,
              contactCount: _contactsController.contacts.length,
            ),
            const SizedBox(height: 16),
            _EmergencyContactsSection(controller: _contactsController),
            const SizedBox(height: 16),
            _AmbulanceRequestForm(
              pickupController: _pickupController,
              destinationController: _destinationController,
              contactController: _contactController,
              notesController: _notesController,
              isSubmitting: _submitController.isSubmitting,
              onSubmit: _submitRequest,
            ),
            const SizedBox(height: 16),
            _RequestsSection(
              controller: _requestsController,
              onRetry: () => _requestsController.loadRequests(session),
            ),
          ],
        );
      },
    );
  }
}

class _EmergencyWarningCard extends StatelessWidget {
  const _EmergencyWarningCard({
    required this.isSignedIn,
    required this.contactCount,
  });

  final bool isSignedIn;
  final int contactCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF4F4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'For severe emergencies, call emergency services immediately.',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isSignedIn
                  ? 'You are signed in, so you can submit an ambulance request from this screen.'
                  : 'Sign in first to submit a request. Emergency contacts remain visible even without login.',
            ),
            const SizedBox(height: 8),
            Text(
              contactCount == 0
                  ? 'No emergency contacts have been loaded yet.'
                  : '$contactCount emergency contact(s) available below.',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyContactsSection extends StatelessWidget {
  const _EmergencyContactsSection({required this.controller});

  final EmergencyContactsController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency contacts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'These numbers are public and come from `/api/v1/emergency-contact/`.',
            ),
            const SizedBox(height: 16),
            if (controller.isLoading)
              const Center(child: CircularProgressIndicator()),
            if (!controller.isLoading && controller.errorMessage != null)
              _InlineError(
                message: controller.errorMessage!,
                onRetry: controller.loadContacts,
              ),
            if (!controller.isLoading &&
                controller.errorMessage == null &&
                controller.contacts.isEmpty)
              const Text(
                'No emergency contacts are currently available.',
                style: TextStyle(color: AppColors.muted),
              ),
            if (controller.contacts.isNotEmpty) ...[
              for (final contact in controller.contacts) ...[
                _EmergencyContactTile(contact: contact),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _EmergencyContactTile extends StatelessWidget {
  const _EmergencyContactTile({required this.contact});

  final EmergencyContact contact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE8E6)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F4F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.call_outlined, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  contact.phoneNumber,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbulanceRequestForm extends StatelessWidget {
  const _AmbulanceRequestForm({
    required this.pickupController,
    required this.destinationController,
    required this.contactController,
    required this.notesController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final TextEditingController contactController;
  final TextEditingController notesController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request an ambulance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Required by backend: pickup address and contact number.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pickupController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Pickup address *',
                hintText: 'House, road, area, landmark',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: destinationController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Destination address',
                hintText: 'Hospital, clinic, or other destination',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: contactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact number *',
                hintText: '+88017XXXXXXXX',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesController,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Emergency notes',
                hintText: 'Chest pain, breathing difficulty, elderly patient, etc.',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.local_hospital_outlined),
              label: Text(
                isSubmitting ? 'Submitting request' : 'Submit ambulance request',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsSection extends StatelessWidget {
  const _RequestsSection({required this.controller, required this.onRetry});

  final AmbulanceRequestsController controller;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your recent ambulance requests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'This list uses the protected `/api/v1/ambulance/requests/` endpoint.',
            ),
            const SizedBox(height: 16),
            if (controller.isLoading)
              const Center(child: CircularProgressIndicator()),
            if (!controller.isLoading && controller.errorMessage != null)
              _InlineError(message: controller.errorMessage!, onRetry: onRetry),
            if (!controller.isLoading &&
                controller.errorMessage == null &&
                controller.requests.isEmpty)
              const Text(
                'No ambulance requests yet.',
                style: TextStyle(color: AppColors.muted),
              ),
            if (controller.requests.isNotEmpty) ...[
              for (final request in controller.requests) ...[
                _AmbulanceRequestTile(request: request),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _AmbulanceRequestTile extends StatelessWidget {
  const _AmbulanceRequestTile({required this.request});

  final AmbulanceRequestItem request;

  Color _statusColor() {
    switch (request.status) {
      case 'ACCEPTED':
        return AppColors.primaryDark;
      case 'ON_THE_WAY':
        return AppColors.warning;
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE8E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Request #${request.id}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor().withAlpha(31),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  request.statusDisplay,
                  style: TextStyle(
                    color: _statusColor(),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailLine(label: 'Pickup', value: request.pickupAddress),
          const SizedBox(height: 8),
          _DetailLine(label: 'Destination', value: request.destinationAddress),
          const SizedBox(height: 8),
          _DetailLine(label: 'Contact', value: request.contactNumber),
          const SizedBox(height: 8),
          _DetailLine(label: 'Notes', value: request.notes),
          const SizedBox(height: 8),
          Text(
            request.createdAtLabel,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

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

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: AppColors.danger)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
