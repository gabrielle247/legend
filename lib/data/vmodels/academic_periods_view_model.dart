import 'package:legend/app_libs.dart';

class AcademicPeriodsViewModel extends ChangeNotifier {
  final AcademicPeriodRepository _repo;
  final AuthService _auth;

  bool isLoading = true;
  String? error;
  List<AcademicYear> years = [];
  List<Term> terms = [];
  String? selectedYearId;

  AcademicPeriodsViewModel(this._repo, this._auth);

  Future<void> init() async {
    await reload();
  }

  AcademicYear? get activeYear {
    for (final year in years) {
      if (year.isActive) return year;
    }
    return null;
  }

  Term? get activeTerm {
    for (final term in terms) {
      if (term.isActive) return term;
    }
    return null;
  }

  Future<void> reload() async {
    isLoading = true;
    error = null;
    notifyListeners();

    final schoolId = _auth.activeSchool?.id;
    if (schoolId == null) {
      error = AppStrings.noActiveSchool;
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      years = await _repo.getYears(schoolId);
      if (years.isEmpty) {
        selectedYearId = null;
        terms = [];
      } else {
        selectedYearId ??= activeYear?.id ?? years.first.id;
        if (!years.any((y) => y.id == selectedYearId)) {
          selectedYearId = activeYear?.id ?? years.first.id;
        }
        terms = await _repo.getTermsForYear(schoolId, selectedYearId!);
      }
    } catch (e) {
      error = "Failed to load academic periods: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectYear(String? yearId) async {
    if (yearId == null) return;
    selectedYearId = yearId;

    final schoolId = _auth.activeSchool?.id;
    if (schoolId == null) return;

    isLoading = true;
    notifyListeners();
    try {
      terms = await _repo.getTermsForYear(schoolId, yearId);
    } catch (e) {
      error = "Failed to load terms: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addYear({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    bool setActive = false,
  }) async {
    final schoolId = _auth.activeSchool?.id;
    if (schoolId == null) return;

    await _repo.createAcademicYear(
      schoolId: schoolId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      setActive: setActive,
    );

    await reload();
  }

  Future<void> addTerm({
    required String academicYearId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    bool setActive = false,
  }) async {
    final schoolId = _auth.activeSchool?.id;
    if (schoolId == null) return;

    await _repo.createTerm(
      schoolId: schoolId,
      academicYearId: academicYearId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      setActive: setActive,
    );

    await reload();
  }

  Future<void> setYearActive(String yearId) async {
    final schoolId = _auth.activeSchool?.id;
    if (schoolId == null) return;
    await _repo.setActiveYear(schoolId, yearId);
    await reload();
  }

  Future<void> setTermActive(String termId) async {
    final schoolId = _auth.activeSchool?.id;
    if (schoolId == null) return;
    await _repo.setActiveTerm(schoolId, termId);
    await reload();
  }
}
