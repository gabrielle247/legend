import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/financial_repo.dart';
import 'package:legend/data/repo/student_repo.dart';

class ViewInvoiceViewModel extends ChangeNotifier {
  final FinanceRepository _financeRepo;
  final StudentRepository _studentRepo;
  final String invoiceId;

  bool isLoading = true;
  String? error;

  Invoice? invoice;
  List<InvoiceItem> items = [];
  Student? student;

  ViewInvoiceViewModel(this._financeRepo, this._studentRepo, this.invoiceId);

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      invoice = await _financeRepo.getInvoiceById(invoiceId);
      if (invoice == null) throw Exception("Invoice not found.");

      items = await _financeRepo.getInvoiceItems(invoiceId);
      student = await _studentRepo.getStudentById(invoice!.studentId);
    } catch (e) {
      error = e.toString();
      debugPrint("ViewInvoiceViewModel.load error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  double get total => items.fold<double>(
        0.0,
        (sum, it) => sum + (it.amount * (it.quantity <= 0 ? 1 : it.quantity)),
      );
}
