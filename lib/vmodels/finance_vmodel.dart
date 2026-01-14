import 'package:flutter/foundation.dart';
import 'package:legend/models/invoice.dart';
import 'package:legend/models/invoice_item.dart';
import 'package:legend/models/invoice_status.dart';
import 'package:legend/models/ledger_entry.dart';
import 'package:legend/models/payment.dart';
import 'package:legend/services/auth/auth.dart';
import 'package:legend/vmodels/students_vmodel.dart';

// =============================================================================
// FINANCE VIEW MODEL
// =============================================================================
class FinanceViewModel extends ChangeNotifier {
  final FinanceRepository _financeRepo;
  final AuthService _authService;

  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------
  bool isLoading = true;
  String? error;

  // Overview Stats
  double totalRevenue = 0.0;
  double pendingAmount = 0.0;
  int unpaidInvoiceCount = 0;
  double percentGrowth = 0.0;

  // Chart Data
  List<double> monthlyCollections = [];
  List<String> monthLabels = [];

  // Activity
  List<Map<String, dynamic>> recentActivity = [];

  // Invoice Creation State
  bool isCreatingInvoice = false;
  String? invoiceCreationError;

  // Payment Recording State
  bool isRecordingPayment = false;
  String? paymentRecordingError;

  // Invoice Viewing
  Invoice? currentInvoice;
  List<InvoiceItem> currentInvoiceItems = [];
  bool isLoadingInvoice = false;

  // ---------------------------------------------------------------------------
  // CONSTRUCTOR
  // ---------------------------------------------------------------------------
  FinanceViewModel(this._financeRepo, this._authService);

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------
  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    try {
      final school = _authService.activeSchool;
      if (school == null) {
        // Don't throw - just set error state and wait for user to log in
        error = "Please log in to view finance data";
        isLoading = false;
        notifyListeners();
        return;
      }

      // Load overview data
      await _loadOverviewStats(school.id);
      await _loadRecentActivity(school.id);

      error = null;
    } catch (e) {
      error = e.toString();
      debugPrint("Finance VM Init Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // OVERVIEW METHODS
  // ---------------------------------------------------------------------------
  Future<void> _loadOverviewStats(String schoolId) async {
    final stats = await _financeRepo.getFinanceStats(schoolId);

    totalRevenue = stats['totalRevenue'];
    pendingAmount = stats['pendingAmount'];
    unpaidInvoiceCount = stats['unpaidInvoiceCount'];
    percentGrowth = stats['percentGrowth'];
    monthlyCollections = List<double>.from(stats['monthlyCollections']);
    monthLabels = List<String>.from(stats['monthLabels']);
  }

  Future<void> _loadRecentActivity(String schoolId) async {
    recentActivity = await _financeRepo.getRecentActivity(schoolId);
  }

  // ---------------------------------------------------------------------------
  // INVOICE OPERATIONS
  // ---------------------------------------------------------------------------
  Future<void> createInvoice({
    required String studentId,
    required List<InvoiceItem> items,
    required DateTime dueDate,
  }) async {
    isCreatingInvoice = true;
    invoiceCreationError = null;
    notifyListeners();

    try {
      final school = _authService.activeSchool;
      if (school == null) {
        invoiceCreationError = "No active school found. Please log in again.";
        isCreatingInvoice = false;
        notifyListeners();
        return;
      }

      await _financeRepo.createInvoice(
        Invoice(
          id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
          schoolId: school.id,
          studentId: studentId,
          invoiceNumber:
              'INV-${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          dueDate: dueDate,
          status: InvoiceStatus.draft,
          totalAmount: items.fold(0.0, (sum, item) => sum + item.amount),
        ),
        items
            .map(
              (item) => InvoiceItem(
                id: 'inv_item_${DateTime.now().millisecondsSinceEpoch}_${items.indexOf(item)}',
                schoolId: school.id,
                invoiceId: '', // Will be set in repository
                description: item.description,
                amount: item.amount,
              ),
            )
            .toList(),
      );

      // Refresh overview after creation
      await _loadOverviewStats(school.id);
    } catch (e) {
      invoiceCreationError = e.toString();
      debugPrint("Create Invoice Error: $e");
    } finally {
      isCreatingInvoice = false;
      notifyListeners();
    }
  }

  Future<void> loadInvoice(String invoiceId) async {
    isLoadingInvoice = true;
    notifyListeners();

    try {
      currentInvoice = await _financeRepo.getInvoiceById(invoiceId);
      if (currentInvoice != null) {
        currentInvoiceItems = await _financeRepo.getInvoiceItems(invoiceId);
      } else {
        currentInvoiceItems = [];
      }
    } catch (e) {
      debugPrint("Load Invoice Error: $e");
    } finally {
      isLoadingInvoice = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // PAYMENT OPERATIONS
  // ---------------------------------------------------------------------------
  Future<void> recordPayment({
    required String studentId,
    required double amount,
    required String method,
    String? reference,
  }) async {
    isRecordingPayment = true;
    paymentRecordingError = null;
    notifyListeners();

    try {
      final school = _authService.activeSchool;
      if (school == null) {
        paymentRecordingError = "No active school found. Please log in again.";
        isRecordingPayment = false;
        notifyListeners();
        return;
      }

      await _financeRepo.recordPayment(
        Payment(
          id: '', // Will be generated
          schoolId: school.id,
          studentId: studentId,
          amount: amount,
          method: method,
          reference: reference,
          receivedAt: DateTime.now(),
        ),
      );

      // Refresh overview after payment
      await _loadOverviewStats(school.id);
    } catch (e) {
      paymentRecordingError = e.toString();
      debugPrint("Record Payment Error: $e");
    } finally {
      isRecordingPayment = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // STUDENT FINANCE DATA
  // ---------------------------------------------------------------------------
  Future<List<Invoice>> getStudentInvoices(String studentId) async {
    return await _financeRepo.getStudentInvoices(studentId);
  }

  Future<List<Payment>> getStudentPayments(String studentId) async {
    return await _financeRepo.getStudentPayments(studentId);
  }

  Future<List<LedgerEntry>> getStudentLedger(String studentId) async {
    return await _financeRepo.getStudentLedger(studentId);
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------
  Future<void> refresh() async {
    await init();
  }
}
