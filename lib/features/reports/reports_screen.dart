import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/session/app_session_scope.dart';
import 'data/report_item.dart';
import 'logic/report_download_controller.dart';
import 'logic/reports_controller.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsController _controller = ReportsController();
  final ReportDownloadController _downloadController =
      ReportDownloadController();
  String? _lastToken;

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    if (_lastToken != session.accessToken) {
      _lastToken = session.accessToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.loadReports(session);
        }
      });
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _downloadController]),
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _controller.isLoading
                    ? null
                    : () => _controller.loadReports(session),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reload reports'),
              ),
            ),
            const SizedBox(height: 16),
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
              _ReportsErrorCard(
                message: _controller.errorMessage!,
                onRetry: () => _controller.loadReports(session),
              ),
            if (!_controller.isLoading &&
                _controller.errorMessage == null &&
                _controller.reports.isEmpty)
              const _ReportsEmptyCard(),
            if (_controller.reports.isNotEmpty) ...[
              Text(
                '${_controller.reports.length} reports found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final report in _controller.reports) ...[
                _ReportTile(
                  report: report,
                  isDownloading:
                      _downloadController.activeReportId == report.id,
                  onDownload: () {
                    _downloadController.download(
                      session: session,
                      report: report,
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

class _ReportsErrorCard extends StatelessWidget {
  const _ReportsErrorCard({required this.message, required this.onRetry});

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
              'Reports unavailable',
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

class _ReportsEmptyCard extends StatelessWidget {
  const _ReportsEmptyCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No reports yet',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'When the backend returns report documents for this patient, they will appear here.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.report,
    required this.isDownloading,
    required this.onDownload,
  });

  final ReportItem report;
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
                  Icons.description_outlined,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    report.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F4F1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    report.status,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(report.subtitle),
            const SizedBox(height: 10),
            Text(
              report.labName,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View details'),
                ),
                const SizedBox(width: 12),
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
          ],
        ),
      ),
    );
  }
}
