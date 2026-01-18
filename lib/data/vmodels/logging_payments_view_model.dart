import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/financial_repo.dart';
import 'package:legend/data/repo/student_repo.dart';
import 'package:legend/data/services/auth/auth.dart';

class LoggingPaymentsViewModel extends ChangeNotifier {
  final FinanceRepository _financeRepo;
  final StudentRepository _studentRepo;
  final AuthService _authService;

  final String studentId;

  bool isLoading = true;
  String? error;

  double amount = 0.0;
  String method = "Cash";
  String reference = "";

  Student? student;
  List<Invoice> unpaidInvoices = [];

  LoggingPaymentsViewModel(
    this._financeRepo,
    this._studentRepo,
    this._authService,
    this.studentId,
  );

  Future<void> init() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final school = _authService.activeSchool;
      if (school == null) throw Exception("No active school.");

      student = await _studentRepo.getStudentById(studentId);

      unpaidInvoices = await _financeRepo.getOpenInvoicesForStudent(studentId);

      // Ensure sorted: oldest/most urgent first
      unpaidInvoices.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } catch (e) {
      error = e.toString();
      debugPrint("LoggingPaymentsViewModel.init error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- UI state setters ---
  void updateAmount(double v) {
    amount = v.isFinite ? v : 0.0;
    notifyListeners();
  }

  void setMethod(String v) {
    method = v.trim().isEmpty ? "Cash" : v.trim();
    notifyListeners();
  }

  void setReference(String v) {
    reference = v;
    notifyListeners();
  }

  // --- Derived values ---
  double outstandingOf(Invoice inv) {
    final due = inv.totalAmount - inv.paidAmount;
    return due <= 0 ? 0.0 : due;
  }

  double get totalOutstandingDebt {
    return unpaidInvoices.fold<double>(
      0.0,
      (sum, inv) => sum + outstandingOf(inv),
    );
  }

  double get remainingCreditAfterDebt {
    final surplus = amount - totalOutstandingDebt;
    return surplus > 0 ? surplus : 0.0;
  }

  String getStatusLabel(Invoice inv) {
    final out = outstandingOf(inv);
    if (out <= 0) return "PAID";
    if (inv.paidAmount > 0) return "PARTIAL";
    if (inv.dueDate.isBefore(DateTime.now())) return "OVERDUE";
    return "UNPAID";
  }

  // --- Action ---
  Future<bool> logPayment() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final school = _authService.activeSchool;
      if (school == null) throw Exception("No active school.");

      if (amount <= 0) throw Exception("Amount must be greater than 0.");

      // Record payment (minimal, guaranteed path)
      await _financeRepo.recordPayment(
        Payment(
          id: "", // repo can generate UUID
          schoolId: school.id,
          studentId: studentId,
          amount: amount,
          method: method,
          reference: reference.trim().isEmpty ? null : reference.trim(),
          receivedAt: DateTime.now(),
        ),
      );

      // Note: allocation across invoices is UI-level here; persisting allocations
      // requires repo support (e.g. apply payment to invoices / ledger entries).
      // Your list will refresh on next load.

      return true;
    } catch (e) {
      error = e.toString();
      debugPrint("LoggingPaymentsViewModel.logPayment error: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

}
