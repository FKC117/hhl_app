import 'package:flutter/foundation.dart';

import '../data/diagnostic_lab.dart';
import '../data/diagnostics_repository.dart';

class DiagnosticsController extends ChangeNotifier {
  DiagnosticsController({DiagnosticsRepository? repository})
    : _repository = repository ?? DiagnosticsRepository();

  final DiagnosticsRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  List<DiagnosticLab> labs = const [];

  Future<void> loadLabs() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      labs = await _repository.fetchLabs();
    } catch (_) {
      labs = const [];
      errorMessage =
          'Could not load diagnostic labs. Make sure the backend is running and the diagnostics endpoint is available.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
