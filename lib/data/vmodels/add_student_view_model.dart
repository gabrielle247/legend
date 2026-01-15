import 'package:flutter/material.dart';
import 'package:legend/data/constants/app_strings.dart';
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/student_repo.dart';

class AddStudentViewModel extends ChangeNotifier {
  final StudentRepository _repo;
  final String _schoolId;

  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------
  bool _isLoading = true;
  String? _error;
  String? _blockingError;

  List<SchoolClass> _classes = [];
  List<String> _gradeNames = [];

  // ---------------------------------------------------------------------------
  // CONTROLLERS
  // ---------------------------------------------------------------------------
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final guardianNameCtrl = TextEditingController();
  final guardianPhoneCtrl = TextEditingController();
  final guardianEmailCtrl = TextEditingController();
  final openingBalanceCtrl = TextEditingController(text: '0');
  final debtDescriptionCtrl = TextEditingController();

  // ---------------------------------------------------------------------------
  // REACTIVE PROPERTIES (With Setters)
  // ---------------------------------------------------------------------------
  String? _selectedGender;
  String? _selectedStudentType;
  String? _selectedGradeName;
  String? _selectedBillingCycle = AppStrings.defaultB;
  DateTime? _customBillingDate;
  List<String> _selectedSubjects = [];
  bool _generateInvoiceNow = true;

  // Getters
  String? get selectedGender => _selectedGender;
  String? get selectedStudentType => _selectedStudentType;
  String? get selectedGradeName => _selectedGradeName;
  String? get selectedBillingCycle => _selectedBillingCycle;
  DateTime? get customBillingDate => _customBillingDate;
  List<String> get selectedSubjects => _selectedSubjects;
  bool get generateInvoiceNow => _generateInvoiceNow;

  // Setters (The "Real" Logic)
  set selectedGender(String? val) {
    _selectedGender = val;
    notifyListeners();
  }

  set selectedStudentType(String? val) {
    _selectedStudentType = val;
    notifyListeners();
  }

  set selectedGradeName(String? val) {
    _selectedGradeName = val;
    notifyListeners();
  }

  set selectedBillingCycle(String? val) {
    _selectedBillingCycle = val;
    notifyListeners();
  }

  set customBillingDate(DateTime? val) {
    _customBillingDate = val;
    notifyListeners();
  }

  set generateInvoiceNow(bool val) {
    _generateInvoiceNow = val;
    notifyListeners();
  }

  void toggleSubject(String subject) {
    if (_selectedSubjects.contains(subject)) {
      _selectedSubjects.remove(subject);
    } else {
      _selectedSubjects.add(subject);
    }
    notifyListeners(); // Updates the UI instantly
  }

  // DATA SOURCES
  List<String> get grades => _gradeNames;
  List<String> get billingTypes => ['Monthly', 'Termly', 'Yearly'];
  List<String> get availableSubjects => ZimsecSubject.allNames; // Real Data

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get blockingError => _blockingError;

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------
  AddStudentViewModel(this._repo, this._schoolId) {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final configError = await _repo.checkSchoolReadiness(_schoolId);
      if (configError != null) {
        _blockingError = configError;
        return;
      }

      _classes = await _repo.getClasses(_schoolId);
      _gradeNames = _classes.map((c) => c.name).toList();

      if (_gradeNames.isEmpty) {
        _blockingError = "No Grades found. Please add classes in Settings.";
      }
    } catch (e) {
      _error = "Init Failed: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // SUBMIT
  // ---------------------------------------------------------------------------
  Future<bool> submit() async {
    if (_blockingError != null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final classId = _classes
          .firstWhere(
            (c) => c.name == _selectedGradeName,
            orElse: () => throw Exception("Invalid Grade Selected"),
          )
          .id;

      final balance = double.tryParse(openingBalanceCtrl.text) ?? 0.0;

      await _repo.registerStudent(
        schoolId: _schoolId,
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        gender: _selectedGender ?? 'Male',
        type: _selectedStudentType ?? 'ACADEMY',
        guardianName: guardianNameCtrl.text.trim(),
        guardianPhone: guardianPhoneCtrl.text.trim(),
        guardianEmail: guardianEmailCtrl.text.trim(),
        classId: classId,
        openingBalance: balance,
        debtDescription: debtDescriptionCtrl.text.trim(),
        subjects: _selectedSubjects,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    guardianNameCtrl.dispose();
    guardianPhoneCtrl.dispose();
    guardianEmailCtrl.dispose();
    openingBalanceCtrl.dispose();
    debtDescriptionCtrl.dispose();
    super.dispose();
  }

  // Add inside AddStudentViewModel class
  void updateSubjects(List<String> newSubjects) {
    _selectedSubjects = newSubjects;
    notifyListeners();
  }
}
