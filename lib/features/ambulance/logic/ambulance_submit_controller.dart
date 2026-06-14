import 'package:flutter/foundation.dart';

import '../../../core/session/app_session.dart';
import '../data/ambulance_repository.dart';
import '../data/ambulance_request_item.dart';

class AmbulanceSubmitController extends ChangeNotifier {
  AmbulanceSubmitController({AmbulanceRepository? repository})
    : _repository = repository ?? AmbulanceRepository();

  final AmbulanceRepository _repository;

  bool isSubmitting = false;
  String? errorMessage;
  String? message;
  AmbulanceRequestItem? lastSubmittedRequest;

  Future<bool> submit({
    required AppSession session,
    required String pickupAddress,
    required String destinationAddress,
    required String contactNumber,
    required String notes,
  }) async {
    if (!session.isAuthenticated) {
      errorMessage = 'Please sign in before requesting an ambulance.';
      message = null;
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    errorMessage = null;
    message = null;
    notifyListeners();

    try {
      lastSubmittedRequest = await session.withFreshToken(
        (accessToken) => _repository.submitRequest(
          accessToken: accessToken,
          pickupAddress: pickupAddress,
          destinationAddress: destinationAddress,
          contactNumber: contactNumber,
          notes: notes,
        ),
      );
      message =
          'Ambulance request submitted. Current status: ${lastSubmittedRequest!.statusDisplay}.';
      return true;
    } catch (_) {
      errorMessage =
          'Could not submit the ambulance request. Please check the form and backend availability.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
