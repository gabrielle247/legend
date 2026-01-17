import 'package:legend/app_libs.dart';

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

  // Financial Controllers
  final openingBalanceCtrl = TextEditingController(text: '0.00');
  final initialPaymentCtrl = TextEditingController(text: '0.00');
  final debtDescriptionCtrl = TextEditingController();

  // ---------------------------------------------------------------------------
  // REACTIVE PROPERTIES
  // ---------------------------------------------------------------------------
  String? _selectedGender;
  String? _selectedStudentType;
  String? _selectedGradeName;

  // Default to TERMLY
  String _selectedBillingCycle = 'TERMLY';

  String _selectedPaymentMethod = 'Cash';
  DateTime? _customBillingDate;
  List<String> _selectedSubjects = [];
  bool _generateInvoiceNow = true;

  // Replace _gradeNames with _classNames to avoid lying to yourself/UI
  List<String> _classNames = [];
  List<String> get classes => _classNames;

  // Getters & Setters
  String? get selectedGender => _selectedGender;
  set selectedGender(String? val) {
    _selectedGender = val;
    notifyListeners();
  }

  String? get selectedStudentType => _selectedStudentType;
  set selectedStudentType(String? val) {
    _selectedStudentType = val;
    notifyListeners();
  }

  String? get selectedGradeName => _selectedGradeName;
  set selectedGradeName(String? val) {
    _selectedGradeName = val;
    notifyListeners();
  }

  String get selectedBillingCycle => _selectedBillingCycle;
  set selectedBillingCycle(String val) {
    _selectedBillingCycle = val;
    notifyListeners();
  }

  String get selectedPaymentMethod => _selectedPaymentMethod;
  set selectedPaymentMethod(String val) {
    _selectedPaymentMethod = val;
    notifyListeners();
  }

  DateTime? get customBillingDate => _customBillingDate;
  set customBillingDate(DateTime? val) {
    _customBillingDate = val;
    notifyListeners();
  }

  bool get generateInvoiceNow => _generateInvoiceNow;
  set generateInvoiceNow(bool val) {
    _generateInvoiceNow = val;
    notifyListeners();
  }

  List<String> get selectedSubjects => _selectedSubjects;

  void updateSubjects(List<String> newSubjects) {
    _selectedSubjects = newSubjects;
    notifyListeners();
  }

  void toggleSubject(String subject) {
    if (_selectedSubjects.contains(subject)) {
      _selectedSubjects.remove(subject);
    } else {
      _selectedSubjects.add(subject);
    }
    notifyListeners();
  }

  // Computed Financials for UI Feedback
  double get totalDebt => double.tryParse(openingBalanceCtrl.text) ?? 0.0;
  double get initialPay => double.tryParse(initialPaymentCtrl.text) ?? 0.0;
  double get netOutstanding => totalDebt - initialPay;

  // DATA SOURCES
  List<String> get grades => _gradeNames;

  // ✅ FIXED: Renamed to 'billingCycles' to match the UI View
  List<String> get billingCycles => ['MONTHLY', 'TERMLY', 'YEARLY'];

  List<String> get paymentMethods => ['Cash', 'EcoCash', 'Swipe', 'Transfer'];
  List<String> get availableSubjects => ZimsecSubject.allNames;

  // Context Helpers
  String get currentTermLabel {
    final now = DateTime.now();
    if (now.month <= 4) return "Term 1, ${now.year}";
    if (now.month <= 8) return "Term 2, ${now.year}";
    return "Term 3, ${now.year}";
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get blockingError => _blockingError;

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------
  AddStudentViewModel(this._repo, this._schoolId) {
    _init();
    // Listeners for Real-Time Math
    openingBalanceCtrl.addListener(notifyListeners);
    initialPaymentCtrl.addListener(notifyListeners);
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _classes = await _repo.getClasses(_schoolId);
    _classNames = _classes.map((c) => c.name).toList();

    if (_classNames.isEmpty) {
      _blockingError = "No Classes found. Please add classes in Settings.";
    }

    // Then update the selected variable names accordingly:
    // String? _selectedClassName; (instead of _selectedGradeName)
    // and in submit() resolve classId by class name.

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
            orElse: () => throw Exception("Selected Grade no longer exists."),
          )
          .id;

      await _repo.registerStudent(
        schoolId: _schoolId,
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        gender: _selectedGender ?? 'Male',
        type: _selectedStudentType ?? 'ACADEMY',

        // FINANCIAL CONFIGURATION
        billingCycle: _selectedBillingCycle,

        guardianName: guardianNameCtrl.text.trim(),
        guardianPhone: guardianPhoneCtrl.text.trim(),
        guardianEmail: guardianEmailCtrl.text.trim(),
        classId: classId,
        openingBalance: totalDebt,
        debtDescription: debtDescriptionCtrl.text.trim().isEmpty
            ? "Opening Balance ($currentTermLabel)"
            : debtDescriptionCtrl.text.trim(),
        subjects: _selectedSubjects,
        initialPayment: initialPay,
        paymentMethod: _selectedPaymentMethod,
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

  // ---------------------------------------------------------------------------
  // DEV HELPERS
  // ---------------------------------------------------------------------------
  void randomizeData() {
    final r = Random();
    final firstNames = [
      'Panashe',
      'Tinashe',
      'Farai',
      'Rutendo',
      'Kudzai',
      'Nyasha',
      'Thabo',
    ];
    final lastNames = [
      'Moyo',
      'Ncube',
      'Sibanda',
      'Chikara',
      'Gumbo',
      'Shumba',
    ];
    final guardians = ['Mr.', 'Mrs.', 'Dr.'];

    firstNameCtrl.text = firstNames[r.nextInt(firstNames.length)];
    lastNameCtrl.text = lastNames[r.nextInt(lastNames.length)];
    _selectedGender = r.nextBool() ? 'Male' : 'Female';
    _selectedStudentType = 'ACADEMY';

    // ✅ Updated to use billingCycles
    _selectedBillingCycle = billingCycles[r.nextInt(billingCycles.length)];

    if (_gradeNames.isNotEmpty) {
      _selectedGradeName = _gradeNames[r.nextInt(_gradeNames.length)];
    }
    _selectedSubjects = [
      'Mathematics',
      'English Language',
      'Combined Science',
      'Shona',
    ];
    if (r.nextBool()) _selectedSubjects.add('Computer Science');

    guardianNameCtrl.text =
        "${guardians[r.nextInt(guardians.length)]} ${lastNameCtrl.text}";
    guardianPhoneCtrl.text = "+263 77${r.nextInt(900000) + 100000}";

    openingBalanceCtrl.text = (r.nextInt(5) * 100 + 50).toString();
    if (r.nextBool()) {
      initialPaymentCtrl.text = (double.parse(openingBalanceCtrl.text) / 2)
          .toString();
    } else {
      initialPaymentCtrl.text = "0.00";
    }
    debtDescriptionCtrl.text = "Term 1 Balance b/f";

    notifyListeners();
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    guardianNameCtrl.dispose();
    guardianPhoneCtrl.dispose();
    guardianEmailCtrl.dispose();
    openingBalanceCtrl.dispose();
    initialPaymentCtrl.dispose();
    debtDescriptionCtrl.dispose();
    super.dispose();
  }
}
