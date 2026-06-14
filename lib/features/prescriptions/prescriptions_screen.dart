import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/session/app_session_scope.dart';
import 'data/prescription_item.dart';
import 'logic/prescription_download_controller.dart';
import 'logic/prescriptions_controller.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final PrescriptionsController _controller = PrescriptionsController();
  final PrescriptionDownloadController _downloadController =
      PrescriptionDownloadController();
  String? _lastToken;

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    if (_lastToken != session.accessToken) {
      _lastToken = session.accessToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.loadPrescriptions(session);
        }
      });
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _downloadController]),
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_downloadController.message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _downloadController.message!,
                  style: const TextStyle(color: AppColors.success),
                ),
              ),
            if (_downloadController.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _downloadController.errorMessage!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            if (_controller.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_controller.isLoading && _controller.errorMessage != null)
              _PrescriptionErrorCard(
                message: _controller.errorMessage!,
                onRetry: () => _controller.loadPrescriptions(session),
              ),
            if (!_controller.isLoading &&
                _controller.errorMessage == null &&
                _controller.prescriptions.isEmpty)
              const _PrescriptionEmptyCard(),
            if (_controller.prescriptions.isNotEmpty) ...[
              Text(
                '${_controller.prescriptions.length} prescriptions found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final prescription in _controller.prescriptions) ...[
                _PrescriptionTile(
                  prescription: prescription,
                  isDownloading:
                      _downloadController.activePrescriptionId ==
                      prescription.id,
                  onDownload: () {
                    _downloadController.download(
                      session: session,
                      prescription: prescription,
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _PrescriptionErrorCard extends StatelessWidget {
  const _PrescriptionErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prescriptions unavailable',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(message),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionEmptyCard extends StatelessWidget {
  const _PrescriptionEmptyCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No prescriptions yet',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Prescription documents will appear here when the backend returns them for the patient.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionTile extends StatelessWidget {
  const _PrescriptionTile({
    required this.prescription,
    required this.isDownloading,
    required this.onDownload,
  });

  final PrescriptionItem prescription;
  final bool isDownloading;
  final VoidCallback onDownload;

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
                const Icon(
                  Icons.medication_outlined,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    prescription.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(prescription.subtitle),
            const SizedBox(height: 10),
            Text(
              prescription.appointmentLabel,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isDownloading ? null : onDownload,
              icon: isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(isDownloading ? 'Downloading' : 'Download'),
            ),
          ],
        ),
      ),
    );
  }
}
