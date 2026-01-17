import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/financial_repo.dart';
import 'package:legend/data/repo/student_repo.dart';

class StudentListViewModel extends ChangeNotifier {
  final StudentRepository _repo;
  final String schoolId;

  bool _isLoading = false;
  List<Student> _students = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<Student> get students => _students;
  String? get error => _error;

  StudentListViewModel(this._repo, this.schoolId);

  Future<void> loadStudents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _students = await _repo.getStudents(schoolId);
    } catch (e) {
      _error = "Failed to load students: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadStudents();

  Future<void> deleteStudent(String id) async {
    try {
      await _repo.deleteStudent(id);
      _students.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      _error = "Failed to delete student: $e";
      notifyListeners();
    }
  }
}

class StudentDetailViewModel extends ChangeNotifier {
  final StudentRepository _repo;

  Student? _student;
  List<Enrollment> _enrollments = [];
  bool _isLoading = false;
  String? _error;

  Student? get student => _student;
  List<Enrollment> get enrollments => _enrollments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StudentDetailViewModel(this._repo);

  Future<void> loadStudent(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _student = await _repo.getStudentById(id);
      _enrollments = _student != null ? await _repo.getEnrollments(id) : [];
    } catch (e) {
      _error = "Failed to load student: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveStudent(Student student) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (student.id.isEmpty) throw Exception("Cannot create here. Use registration flow.");
      await _repo.updateStudent(student);
      _student = student;
    } catch (e) {
      _error = "Failed to save student: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class StudentFinanceViewModel extends ChangeNotifier {
  final FinanceRepository _repo;
  final String studentId;

  List<Invoice> _invoices = [];
  List<Payment> _payments = [];
  List<LedgerEntry> _ledger = [];
  bool _isLoading = false;
  String? _error;

  List<Invoice> get invoices => _invoices;
  List<Payment> get payments => _payments;
  List<LedgerEntry> get ledger => _ledger;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StudentFinanceViewModel(this._repo, this.studentId, String schoolId);

  Future<void> loadFinanceData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.getStudentInvoices(studentId),
        _repo.getStudentPayments(studentId),
        _repo.getStudentLedger(studentId),
      ]);

      _invoices = results[0] as List<Invoice>;
      _payments = results[1] as List<Payment>;
      _ledger = results[2] as List<LedgerEntry>;
    } catch (e) {
      _error = "Failed to load finance data: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadFinanceData();

  Future<void> createInvoice(Invoice invoice, List<InvoiceItem> items) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.createInvoice(invoice, items);
      await loadFinanceData();
    } catch (e) {
      _error = "Failed to create invoice: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordPayment(Payment payment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.recordPayment(payment);
      await loadFinanceData();
    } catch (e) {
      _error = "Failed to record payment: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
