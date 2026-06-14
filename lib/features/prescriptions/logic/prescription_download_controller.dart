import 'package:flutter/foundation.dart';

import '../../../core/documents/document_file_service.dart';
import '../../../core/session/app_session.dart';
import '../../documents/data/document_repository.dart';
import '../data/prescription_item.dart';

class PrescriptionDownloadController extends ChangeNotifier {
  PrescriptionDownloadController({
    DocumentRepository? repository,
    DocumentFileService? fileService,
  }) : _repository = repository ?? DocumentRepository(),
       _fileService = fileService ?? DocumentFileService();

  final DocumentRepository _repository;
  final DocumentFileService _fileService;

  int? activePrescriptionId;
  String? message;
  String? errorMessage;

  Future<void> download({
    required AppSession session,
    required PrescriptionItem prescription,
  }) async {
    if (!session.isAuthenticated) {
      errorMessage =
          'Please sign in before downloading protected prescriptions.';
      notifyListeners();
      return;
    }

    activePrescriptionId = prescription.id;
    message = null;
    errorMessage = null;
    notifyListeners();

    try {
      final bytes = await session.withFreshToken(
        (accessToken) => _repository.downloadProtectedDocument(
          accessToken: accessToken,
          path: prescription.downloadPath,
        ),
      );
      final saved = await _fileService.saveBytes(
        bytes: bytes,
        fileName: 'prescription_${prescription.id}.pdf',
      );
      message = 'Saved ${saved.fileName} to ${saved.savedPath}';
    } catch (_) {
      errorMessage =
          'Could not download the prescription. Check auth and backend download behavior.';
    } finally {
      activePrescriptionId = null;
      notifyListeners();
    }
  }
}
