import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/session/app_session.dart';
import '../../core/session/app_session_scope.dart';
import '../../shared/widgets/info_card.dart';
import 'data/diagnostic_lab.dart';
import 'data/diagnostics_repository.dart';
import 'logic/diagnostics_controller.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final DiagnosticsController _controller = DiagnosticsController();
  bool _loaded = false;
  DiagnosticOrderSuccess? _lastOrderSuccess;

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);

    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.loadLabs();
        }
      });
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_lastOrderSuccess != null) ...[
              _DiagnosticOrderSuccessCard(
                success: _lastOrderSuccess!,
                onDismiss: () {
                  setState(() {
                    _lastOrderSuccess = null;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            if (_controller.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_controller.isLoading && _controller.errorMessage != null)
              _DiagnosticsErrorCard(
                message: _controller.errorMessage!,
                onRetry: _controller.loadLabs,
              ),
            if (!_controller.isLoading &&
                _controller.errorMessage == null &&
                _controller.labs.isEmpty)
              const _DiagnosticsEmptyCard(),
            if (_controller.labs.isNotEmpty) ...[
              Text(
                '${_controller.labs.length} labs available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final lab in _controller.labs) ...[
                _LabTile(
                  lab: lab,
                  onViewTests: () => _openLabSheet(context, lab, session),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        );
      },
    );
  }

  Future<void> _openLabSheet(
    BuildContext context,
    DiagnosticLab lab,
    AppSession session,
  ) async {
    final draftSuccess = await showModalBottomSheet<DiagnosticOrderSuccess>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LabDetailsSheet(lab: lab, session: session),
    );

    if (!mounted || draftSuccess == null) return;

    final finalResult = await Navigator.of(context).push<DiagnosticOrderSuccess>(
      MaterialPageRoute(
        builder: (_) => _DiagnosticPaymentScreen(
          draft: draftSuccess,
          session: session,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      _lastOrderSuccess = finalResult ?? draftSuccess;
    });
  }
}

class DiagnosticOrderSuccess {
  const DiagnosticOrderSuccess({
    required this.orderId,
    required this.status,
    required this.labName,
    required this.testCount,
    required this.totalAmount,
    required this.note,
  });

  final int orderId;
  final String status;
  final String labName;
  final int testCount;
  final String totalAmount;
  final String note;

  bool get isConfirmed => status.toUpperCase() != 'DRAFT';
}

class _DiagnosticsErrorCard extends StatelessWidget {
  const _DiagnosticsErrorCard({required this.message, required this.onRetry});

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
              'Diagnostics unavailable',
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

class _DiagnosticsEmptyCard extends StatelessWidget {
  const _DiagnosticsEmptyCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No labs found',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'When the diagnostics lab list is available in the backend, labs will appear here.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LabTile extends StatelessWidget {
  const _LabTile({required this.lab, required this.onViewTests});

  final DiagnosticLab lab;
  final VoidCallback onViewTests;

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
                  Icons.local_hospital_outlined,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lab.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(lab.about),
            const SizedBox(height: 10),
            Text(lab.address, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 6),
            Text(
              'Phone: ${lab.phone}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onViewTests,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('View tests'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabDetailsSheet extends StatefulWidget {
  const _LabDetailsSheet({required this.lab, required this.session});

  final DiagnosticLab lab;
  final AppSession session;

  @override
  State<_LabDetailsSheet> createState() => _LabDetailsSheetState();
}

class _LabDetailsSheetState extends State<_LabDetailsSheet> {
  final DiagnosticsRepository _repository = DiagnosticsRepository();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedTestIds = <int>{};

  DiagnosticLab? _labDetail;
  List<DiagnosticTest> _tests = const [];
  bool _loading = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLabData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLabData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final detail = await _repository.fetchLabDetail(widget.lab.id);
      final tests = await _repository.fetchLabTests(labId: widget.lab.id);
      setState(() {
        _labDetail = detail;
        _tests = tests;
      });
    } catch (_) {
      setState(() {
        _errorMessage =
            'Could not load lab details or tests. Make sure the diagnostics detail and tests endpoints are available.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _createDraftOrder() async {
    if (!widget.session.isAuthenticated) {
      setState(() {
        _errorMessage =
            'Please sign in with the backend before continuing to diagnostic payment.';
      });
      return;
    }

    if (_selectedTestIds.isEmpty) {
      setState(() {
        _errorMessage = 'Select at least one diagnostic test first.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final lab = _labDetail ?? widget.lab;
      final draft = await widget.session.withFreshToken(
        (accessToken) => _repository.createDraftOrder(
          labId: widget.lab.id,
          tests: _selectedTestIds.toList(),
          patientNote: _noteController.text.trim(),
          accessToken: accessToken,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(
        DiagnosticOrderSuccess(
          orderId: draft.id,
          status: draft.status,
          labName: lab.name,
          testCount: _selectedTestIds.length,
          totalAmount: draft.totalAmount,
          note: _noteController.text.trim(),
        ),
      );
    } catch (_) {
      setState(() {
        _errorMessage =
            'Could not prepare the diagnostic order for payment. Check auth and backend validation.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lab = _labDetail ?? widget.lab;
    final query = _searchController.text.trim().toLowerCase();
    final visibleTests = query.isEmpty
        ? _tests
        : _tests.where((test) {
            return test.name.toLowerCase().contains(query) ||
                test.department.toLowerCase().contains(query) ||
                test.description.toLowerCase().contains(query);
          }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.97,
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
              Text(lab.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(lab.address, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 18),
              if (_loading) const LinearProgressIndicator(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                'Select tests',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search test or department',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              if (_tests.isEmpty && !_loading)
                const Text(
                  'No tests found for this lab yet.',
                  style: TextStyle(color: AppColors.muted),
                )
              else if (visibleTests.isEmpty)
                const Text(
                  'No matching tests found.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                for (final test in visibleTests) ...[
                  _DiagnosticTestTile(
                    test: test,
                    selected: _selectedTestIds.contains(test.id),
                    onToggle: () {
                      setState(() {
                        if (_selectedTestIds.contains(test.id)) {
                          _selectedTestIds.remove(test.id);
                        } else {
                          _selectedTestIds.add(test.id);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 18),
              TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Patient note',
                  hintText: 'Morning collection preferred',
                ),
              ),
              const SizedBox(height: 18),
              InfoCard(
                title: 'Selected tests',
                subtitle:
                    '${_selectedTestIds.length} test(s) selected for payment.',
                icon: Icons.science_outlined,
                wide: true,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _submitting ? null : _createDraftOrder,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Continue to payment'),
              ),
            ],
          ),
        );
      },
    );
  }
}


class _DiagnosticTestTile extends StatelessWidget {
  const _DiagnosticTestTile({
    required this.test,
    required this.selected,
    required this.onToggle,
  });

  final DiagnosticTest test;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : const Color(0xFFE0EBE9),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${test.department} • ${test.price}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      test.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Checkbox(
                value: selected,
                onChanged: (_) => onToggle(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagnosticPaymentScreen extends StatefulWidget {
  const _DiagnosticPaymentScreen({
    required this.draft,
    required this.session,
  });

  final DiagnosticOrderSuccess draft;
  final AppSession session;

  @override
  State<_DiagnosticPaymentScreen> createState() =>
      _DiagnosticPaymentScreenState();
}

class _DiagnosticPaymentScreenState extends State<_DiagnosticPaymentScreen> {
  final DiagnosticsRepository _repository = DiagnosticsRepository();

  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _completeFlow(String gatewayLabel) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final payment = await widget.session.withFreshToken(
        (accessToken) => _repository.initiatePayment(
          orderId: widget.draft.orderId,
          accessToken: accessToken,
          gateway: 'manual',
        ),
      );

      final completedPayment = await widget.session.withFreshToken(
        (accessToken) => _repository.completeManualPayment(
          paymentId: payment.id,
          accessToken: accessToken,
        ),
      );

      final confirmed = await widget.session.withFreshToken(
        (accessToken) => _repository.confirmOrder(
          orderId: widget.draft.orderId,
          paymentId: completedPayment.id,
          accessToken: accessToken,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(
        DiagnosticOrderSuccess(
          orderId: confirmed.id,
          status: confirmed.status,
          labName: widget.draft.labName,
          testCount: widget.draft.testCount,
          totalAmount: confirmed.totalAmount.isEmpty
              ? widget.draft.totalAmount
              : confirmed.totalAmount,
          note: widget.draft.note,
        ),
      );
    } catch (_) {
      setState(() {
        _errorMessage =
            'Could not complete "$gatewayLabel" and confirm the diagnostic order.';
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
      appBar: AppBar(title: const Text('Diagnostic payment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const InfoCard(
              title: 'Choose payment option',
              subtitle:
                  'For the local prototype, either option completes payment immediately and confirms the diagnostic order.',
              icon: Icons.payments_outlined,
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
                      widget.draft.labName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _PaymentLine(
                      label: 'Selected tests',
                      value: '${widget.draft.testCount}',
                    ),
                    const SizedBox(height: 8),
                    _PaymentLine(
                      label: 'Amount',
                      value: widget.draft.totalAmount,
                    ),
                    if (widget.draft.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _PaymentLine(label: 'Note', value: widget.draft.note),
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
            FilledButton.icon(
              onPressed: _isProcessing ? null : () => _completeFlow('Pay online'),
              icon: const Icon(Icons.language_rounded),
              label: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Pay online'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _completeFlow('Pay during collection'),
              icon: const Icon(Icons.medical_information_outlined),
              label: const Text('Pay during collection'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticOrderSuccessCard extends StatelessWidget {
  const _DiagnosticOrderSuccessCard({
    required this.success,
    required this.onDismiss,
  });

  final DiagnosticOrderSuccess success;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final headline = success.isConfirmed
        ? 'Diagnostic order confirmed'
        : 'Diagnostic order saved';

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
                        'Order ID: ${success.orderId == 0 ? 'saved' : success.orderId} - Status: ${success.status.toUpperCase()}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PaymentLine(label: 'Lab', value: success.labName),
            const SizedBox(height: 8),
            _PaymentLine(
              label: 'Selected tests',
              value: '${success.testCount}',
            ),
            const SizedBox(height: 8),
            _PaymentLine(label: 'Total', value: success.totalAmount),
            if (success.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              _PaymentLine(label: 'Note', value: success.note),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentLine extends StatelessWidget {
  const _PaymentLine({required this.label, required this.value});

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
