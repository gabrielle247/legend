import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/financial_repo.dart';
import 'package:legend/data/repo/student_repo.dart';
import 'package:legend/data/services/auth/auth.dart';

class PaymentViewModel extends ChangeNotifier {
  final FinanceRepository _financeRepo;
  final StudentRepository _studentRepo;
  final AuthService _authService;

  /// Nullable to support bulk/selector flow later.
  String? studentId;

  bool isLoading = true;
  String? error;

  Student? student;
  List<Enrollment> enrollments = [];

  double amount = 0.0;
  String method = "Cash";
  String reference = "";

  PaymentViewModel(
    this._financeRepo,
    this._studentRepo,
    this._authService, {
    required this.studentId,
  });

  // -----------------------------
  // Derived getters for UI
  // -----------------------------
  double get currentDebt => student?.feesOwed ?? 0.0;

  String get studentName {
    final s = student;
    if (s == null) return "";
    return "${s.firstName} ${s.lastName}".trim();
  }

  String get receiptNumber {
    // simple offline receipt format; repository can override if needed
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final tail = now.millisecondsSinceEpoch.toString().substring(
          (now.millisecondsSinceEpoch.toString().length - 6).clamp(0, 999),
        );
    return "RCPT-$y$m$d-$tail";
  }

  DateTime get date => DateTime.now();

  String get allocationPreview {
    if (amount <= 0) return "Pending input...";
    if (currentDebt <= 0) return "No outstanding balance";
    if (amount >= currentDebt) return "Clears Full Balance";
    return "Partially covers Outstanding Balance";
  }

  // -----------------------------
  // Lifecycle
  // -----------------------------
  Future<void> init() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final school = _authService.activeSchool;
      if (school == null) throw Exception("No active school.");

      final sid = studentId;
      if (sid == null || sid.isEmpty) {
        // Bulk/search flow not implemented yet, but UI must not crash.
        student = null;
        enrollments = [];
        return;
      }

      student = await _studentRepo.getStudentById(sid);
      enrollments = await _studentRepo.getEnrollments(sid);
    } catch (e) {
      error = e.toString();
      debugPrint("PaymentViewModel.init error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // -----------------------------
  // Persist (offline-first)
  // -----------------------------
  Future<void> submitPayment() async {
    try {
      final school = _authService.activeSchool;
      if (school == null) throw Exception("No active school.");

      final sid = studentId;
      if (sid == null || sid.isEmpty) throw Exception("No student selected.");

      await _financeRepo.recordPayment(
        Payment(
          id: "",
          schoolId: school.id,
          studentId: sid,
          amount: amount,
          method: method,
          reference: reference.isEmpty ? null : reference,
          receivedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
