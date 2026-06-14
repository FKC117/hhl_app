import 'package:flutter/foundation.dart';

import '../../../core/session/app_session.dart';
import '../data/report_item.dart';
import '../data/reports_repository.dart';

class ReportsController extends ChangeNotifier {
  ReportsController({ReportsRepository? repository})
    : _repository = repository ?? ReportsRepository();

  final ReportsRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  List<ReportItem> reports = const [];

  Future<void> loadReports(AppSession session) async {
    if (!session.isAuthenticated) {
      reports = const [];
      errorMessage = 'Please sign in with the backend before loading reports.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      reports = await session.withFreshToken(
        (accessToken) => _repository.fetchReports(accessToken: accessToken),
      );
    } catch (_) {
      reports = const [];
      errorMessage =
          'Could not load reports. Check auth and make sure the Django backend is running.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
