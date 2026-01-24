import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/financial_repo.dart';
import 'package:legend/data/services/auth/auth.dart';
import 'package:uuid/uuid.dart';

class FinanceViewModel extends ChangeNotifier {
  final FinanceRepository _financeRepo;
  final AuthService _authService;
  final Uuid _uuid = const Uuid();

  bool isLoading = true;
  String? error;

  double totalRevenue = 0.0;
  double pendingAmount = 0.0;
  int unpaidInvoiceCount = 0;
  double percentGrowth = 0.0;

  List<double> monthlyCollections = [];
  List<String> monthLabels = [];

  List<Map<String, dynamic>> recentActivity = [];
  List<Map<String, dynamic>> recentPayments = [];
  List<Map<String, dynamic>> outstandingStudents = [];

  bool isCreatingInvoice = false;
  String? invoiceCreationError;

  bool isRecordingPayment = false;
  String? paymentRecordingError;

  Invoice? currentInvoice;
  List<InvoiceItem> currentInvoiceItems = [];
  bool isLoadingInvoice = false;

  FinanceViewModel(this._financeRepo, this._authService);

  Future<void> init() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final school = _authService.activeSchool;
      if (school == null) {
        error = "No active school. Please log in again.";
        return;
      }

      await _loadOverviewStats(school.id);
      await _loadRecentActivity(school.id);
      await _loadRecentPayments(school.id);
      await _loadOutstandingStudents(school.id);
    } catch (e) {
      error = e.toString();
      debugPrint("FinanceViewModel.init error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadOverviewStats(String schoolId) async {
    final stats = await _financeRepo.getFinanceStats(schoolId);

    totalRevenue = (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    pendingAmount = (stats['pendingAmount'] as num?)?.toDouble() ?? 0.0;
    unpaidInvoiceCount = (stats['unpaidInvoiceCount'] as num?)?.toInt() ?? 0;

    final rawGrowth = (stats['percentGrowth'] as num?)?.toDouble() ?? 0.0;
    percentGrowth = rawGrowth.isFinite ? rawGrowth : 0.0;

    monthlyCollections = List<double>.from(stats['monthlyCollections'] ?? const <double>[]);
    monthLabels = List<String>.from(stats['monthLabels'] ?? const <String>[]);
  }

  Future<void> _loadRecentActivity(String schoolId) async {
    recentActivity = await _financeRepo.getRecentActivity(schoolId);
  }

  Future<void> _loadRecentPayments(String schoolId) async {
    recentPayments = await _financeRepo.getRecentPayments(schoolId, limit: 8);
  }

  Future<void> _loadOutstandingStudents(String schoolId) async {
    outstandingStudents = await _financeRepo.getOutstandingStudents(schoolId, limit: 8);
  }

  Future<void> createInvoice({
    required String studentId,
    required List<InvoiceItem> items,
    required DateTime dueDate,
    String? termId,
    String? title,
    String? snapshotGrade,
  }) async {
    isCreatingInvoice = true;
    invoiceCreationError = null;
    notifyListeners();

    try {
      final school = _authService.activeSchool;
      if (school == null) throw Exception("No active school found.");

      final invoiceId = _uuid.v4();

      final computedTotal = items.fold<double>(
        0.0,
        (sum, it) => sum + (it.amount * (it.quantity <= 0 ? 1 : it.quantity)),
      );

      final invoiceNumber =
          'INV-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}-${invoiceId.substring(0, 8)}';

      final normalizedItems = <InvoiceItem>[];
      for (final it in items) {
        normalizedItems.add(
          InvoiceItem(
            id: it.id.isNotEmpty ? it.id : _uuid.v4(),
            schoolId: school.id,
            invoiceId: invoiceId,
            feeStructureId: it.feeStructureId,
            description: it.description,
            amount: it.amount,
            quantity: it.quantity <= 0 ? 1 : it.quantity,
            createdAt: it.createdAt,
          ),
        );
      }

      await _financeRepo.createInvoice(
        Invoice(
          id: invoiceId,
          schoolId: school.id,
          studentId: studentId,
          invoiceNumber: invoiceNumber,
          termId: termId,
          dueDate: dueDate,
          status: InvoiceStatus.draft,
          snapshotGrade: snapshotGrade,
          totalAmount: computedTotal,
          paidAmount: 0.0,
          title: title,
          createdAt: DateTime.now(),
        ),
        normalizedItems,
      );

      await _loadOverviewStats(school.id);
      await _loadRecentActivity(school.id);
      await _loadRecentPayments(school.id);
      await _loadOutstandingStudents(school.id);
    } catch (e) {
      invoiceCreationError = e.toString();
      debugPrint("FinanceViewModel.createInvoice error: $e");
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
      currentInvoiceItems = currentInvoice != null
          ? await _financeRepo.getInvoiceItems(invoiceId)
          : <InvoiceItem>[];
    } catch (e) {
      debugPrint("FinanceViewModel.loadInvoice error: $e");
      currentInvoice = null;
      currentInvoiceItems = [];
    } finally {
      isLoadingInvoice = false;
      notifyListeners();
    }
  }

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
      if (school == null) throw Exception("No active school found.");

      await _financeRepo.recordPayment(
        Payment(
          id: _uuid.v4(),
          schoolId: school.id,
          studentId: studentId,
          amount: amount,
          method: method,
          reference: reference,
          receivedAt: DateTime.now(),
        ),
      );

      await _loadOverviewStats(school.id);
      await _loadRecentActivity(school.id);
      await _loadRecentPayments(school.id);
      await _loadOutstandingStudents(school.id);
    } catch (e) {
      paymentRecordingError = e.toString();
      debugPrint("FinanceViewModel.recordPayment error: $e");
    } finally {
      isRecordingPayment = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => init();
}
