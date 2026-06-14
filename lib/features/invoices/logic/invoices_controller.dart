import 'package:flutter/foundation.dart';

import '../../../core/session/app_session.dart';
import '../data/invoice_item.dart';
import '../data/invoices_repository.dart';

class InvoicesController extends ChangeNotifier {
  InvoicesController({InvoicesRepository? repository})
    : _repository = repository ?? InvoicesRepository();

  final InvoicesRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  List<InvoiceItem> invoices = const [];

  Future<void> loadInvoices(AppSession session) async {
    if (!session.isAuthenticated) {
      invoices = const [];
      errorMessage = 'Please sign in with the backend before loading invoices.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      invoices = await session.withFreshToken(
        (accessToken) => _repository.fetchInvoices(accessToken: accessToken),
      );
    } catch (_) {
      invoices = const [];
      errorMessage =
          'Could not load invoices. Check auth and backend availability.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
