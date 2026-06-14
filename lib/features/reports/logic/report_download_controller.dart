import 'package:flutter/foundation.dart';

import '../../../core/documents/document_file_service.dart';
import '../../../core/session/app_session.dart';
import '../../documents/data/document_repository.dart';
import '../data/report_item.dart';

class ReportDownloadController extends ChangeNotifier {
  ReportDownloadController({
    DocumentRepository? repository,
    DocumentFileService? fileService,
  }) : _repository = repository ?? DocumentRepository(),
       _fileService = fileService ?? DocumentFileService();

  final DocumentRepository _repository;
  final DocumentFileService _fileService;

  int? activeReportId;
  String? message;
  String? errorMessage;

  bool get isDownloading => activeReportId != null;

  Future<void> download({
    required AppSession session,
    required ReportItem report,
  }) async {
    if (!session.isAuthenticated) {
      errorMessage = 'Please sign in before downloading protected reports.';
      notifyListeners();
      return;
    }

    activeReportId = report.id;
    message = null;
    errorMessage = null;
    notifyListeners();

    try {
      final bytes = await session.withFreshToken(
        (accessToken) => _repository.downloadProtectedDocument(
          accessToken: accessToken,
          path: report.downloadPath,
        ),
      );
      final saved = await _fileService.saveBytes(
        bytes: bytes,
        fileName: 'report_${report.id}.pdf',
      );
      message = 'Saved ${saved.fileName} to ${saved.savedPath}';
    } catch (_) {
      errorMessage =
          'Could not download the report. Check auth, backend availability, and download endpoint behavior.';
    } finally {
      activeReportId = null;
      notifyListeners();
    }
  }
}
