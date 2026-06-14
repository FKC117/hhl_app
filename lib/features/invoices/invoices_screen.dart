import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/session/app_session_scope.dart';
import 'data/invoice_item.dart';
import 'logic/invoice_download_controller.dart';
import 'logic/invoices_controller.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final InvoicesController _controller = InvoicesController();
  final InvoiceDownloadController _downloadController =
      InvoiceDownloadController();
  String? _lastToken;

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    if (_lastToken != session.accessToken) {
      _lastToken = session.accessToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.loadInvoices(session);
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
                    : () => _controller.loadInvoices(session),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reload invoices'),
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
              _InvoiceErrorCard(
                message: _controller.errorMessage!,
                onRetry: () => _controller.loadInvoices(session),
              ),
            if (!_controller.isLoading &&
                _controller.errorMessage == null &&
                _controller.invoices.isEmpty)
              const _InvoiceEmptyCard(),
            if (_controller.invoices.isNotEmpty) ...[
              Text(
                '${_controller.invoices.length} invoices found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final invoice in _controller.invoices) ...[
                _InvoiceTile(
                  invoice: invoice,
                  isDownloading:
                      _downloadController.activeInvoiceId == invoice.id,
                  onDownload: () {
                    _downloadController.download(
                      session: session,
                      invoice: invoice,
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

class _InvoiceErrorCard extends StatelessWidget {
  const _InvoiceErrorCard({required this.message, required this.onRetry});

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
              'Invoices unavailable',
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

class _InvoiceEmptyCard extends StatelessWidget {
  const _InvoiceEmptyCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No invoices yet',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Invoice documents will appear here when the backend returns them for the patient.',
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({
    required this.invoice,
    required this.isDownloading,
    required this.onDownload,
  });

  final InvoiceItem invoice;
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
                  Icons.receipt_long_outlined,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    invoice.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(invoice.subtitle),
            const SizedBox(height: 10),
            Text(
              invoice.invoiceType,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              invoice.amount,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
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
