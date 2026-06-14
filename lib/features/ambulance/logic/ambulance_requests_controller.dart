import 'package:flutter/foundation.dart';

import '../../../core/session/app_session.dart';
import '../data/ambulance_repository.dart';
import '../data/ambulance_request_item.dart';

class AmbulanceRequestsController extends ChangeNotifier {
  AmbulanceRequestsController({AmbulanceRepository? repository})
    : _repository = repository ?? AmbulanceRepository();

  final AmbulanceRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  List<AmbulanceRequestItem> requests = const [];

  Future<void> loadRequests(AppSession session) async {
    if (!session.isAuthenticated) {
      requests = const [];
      errorMessage =
          'Please sign in with the backend before loading ambulance requests.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      requests = await session.withFreshToken(
        (accessToken) => _repository.fetchRequests(accessToken: accessToken),
      );
    } catch (_) {
      requests = const [];
      errorMessage =
          'Could not load ambulance requests. Check auth and backend availability.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
