import 'package:flutter/foundation.dart';

import '../data/ambulance_repository.dart';
import '../data/emergency_contact.dart';

class EmergencyContactsController extends ChangeNotifier {
  EmergencyContactsController({AmbulanceRepository? repository})
    : _repository = repository ?? AmbulanceRepository();

  final AmbulanceRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  List<EmergencyContact> contacts = const [];

  Future<void> loadContacts() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      contacts = await _repository.fetchEmergencyContacts();
    } catch (_) {
      contacts = const [];
      errorMessage =
          'Could not load emergency contacts. Make sure the backend is running.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
