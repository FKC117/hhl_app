import 'package:flutter/foundation.dart';

import '../../../core/documents/document_file_service.dart';
import '../../../core/session/app_session.dart';
import '../../documents/data/document_repository.dart';
import '../data/invoice_item.dart';

class InvoiceDownloadController extends ChangeNotifier {
  InvoiceDownloadController({
    DocumentRepository? repository,
    DocumentFileService? fileService,
  }) : _repository = repository ?? DocumentRepository(),
       _fileService = fileService ?? DocumentFileService();

  final DocumentRepository _repository;
  final DocumentFileService _fileService;

  int? activeInvoiceId;
  String? message;
  String? errorMessage;

  Future<void> download({
    required AppSession session,
    required InvoiceItem invoice,
  }) async {
    if (!session.isAuthenticated) {
      errorMessage = 'Please sign in before downloading protected invoices.';
      notifyListeners();
      return;
    }

    activeInvoiceId = invoice.id;
    message = null;
    errorMessage = null;
    notifyListeners();

    try {
      final bytes = await session.withFreshToken(
        (accessToken) => _repository.downloadProtectedDocument(
          accessToken: accessToken,
          path: invoice.downloadPath,
        ),
      );
      final saved = await _fileService.saveBytes(
        bytes: bytes,
        fileName: invoice.fileName,
      );
      message = 'Saved ${saved.fileName} to ${saved.savedPath}';
    } catch (_) {
      errorMessage =
          'Could not download the invoice. Check auth and backend download behavior.';
    } finally {
      activeInvoiceId = null;
      notifyListeners();
    }
  }
}
