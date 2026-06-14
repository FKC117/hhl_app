import 'package:flutter/foundation.dart';

import '../../../core/session/app_session.dart';
import '../data/prescription_item.dart';
import '../data/prescriptions_repository.dart';

class PrescriptionsController extends ChangeNotifier {
  PrescriptionsController({PrescriptionsRepository? repository})
    : _repository = repository ?? PrescriptionsRepository();

  final PrescriptionsRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  List<PrescriptionItem> prescriptions = const [];

  Future<void> loadPrescriptions(AppSession session) async {
    if (!session.isAuthenticated) {
      prescriptions = const [];
      errorMessage =
          'Please sign in with the backend before loading prescriptions.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      prescriptions = await session.withFreshToken(
        (accessToken) =>
            _repository.fetchPrescriptions(accessToken: accessToken),
      );
    } catch (_) {
      prescriptions = const [];
      errorMessage =
          'Could not load prescriptions. Check auth and backend availability.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
