import 'package:flutter/foundation.dart';

import '../data/doctor.dart';
import '../data/doctor_repository.dart';

class DoctorsController extends ChangeNotifier {
  DoctorsController({DoctorRepository? repository})
    : _repository = repository ?? DoctorRepository();

  final DoctorRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  String selectedDepartment = 'All';
  String searchTerm = '';
  List<String> departments = const ['All'];
  List<Doctor> doctors = const [];

  Future<void> initialize() async {
    if (departments.length > 1 || isLoading) return;
    await Future.wait([loadDepartments(), loadDoctors()]);
  }

  Future<void> loadDepartments() async {
    try {
      final loaded = await _repository.fetchDepartments();
      departments = loaded.isEmpty ? const ['All'] : loaded;
      notifyListeners();
    } catch (_) {
      departments = const ['All'];
      notifyListeners();
    }
  }

  Future<void> loadDoctors() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      doctors = await _repository.fetchDoctors(
        department: selectedDepartment,
        search: searchTerm,
      );
    } catch (error) {
      errorMessage =
          'Could not load doctors from the backend. Make sure the Django server is running on port 8000 and try again.';
      doctors = const [];
      debugPrint('Doctors load failed: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() => loadDoctors();

  Future<void> updateDepartment(String value) async {
    selectedDepartment = value;
    await loadDoctors();
  }

  Future<void> updateSearch(String value) async {
    searchTerm = value;
    await loadDoctors();
  }
}
