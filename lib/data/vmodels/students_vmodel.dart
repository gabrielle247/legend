import 'package:flutter/foundation.dart';
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/financial_repo.dart'; 
import 'package:legend/data/repo/student_repo.dart';   

// =============================================================================
// STUDENT LIST VIEW MODEL
// =============================================================================
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
      _error = "Failed to load students: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _repo.deleteStudent(id);
      _students.removeWhere((student) => student.id == id);
      notifyListeners();
    } catch (e) {
      _error = "Failed to delete student: ${e.toString()}";
      notifyListeners();
    }
  }
}

// =============================================================================
// STUDENT DETAIL VIEW MODEL (Edit & View Only)
// =============================================================================
class StudentDetailViewModel extends ChangeNotifier {
  final StudentRepository _repo;
  final String schoolId;

  Student? _student;
  List<Enrollment> _enrollments = [];
  bool _isLoading = false;
  String? _error;

  Student? get student => _student;
  List<Enrollment> get enrollments => _enrollments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StudentDetailViewModel(this._repo, this.schoolId);

  Future<void> loadStudent(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _student = await _repo.getStudentById(id);
      if (_student != null) {
        _enrollments = await _repo.getEnrollments(id);
      }
    } catch (e) {
      _error = "Failed to load student: ${e.toString()}";
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
      if (student.id.isEmpty) {
        throw Exception("Cannot create student here. Use the Registration flow.");
      } else {
        await _repo.updateStudent(student);
        _student = student; 
      }
    } catch (e) {
      _error = "Failed to save student: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// =============================================================================
// STUDENT FINANCE VIEW MODEL
// =============================================================================
class StudentFinanceViewModel extends ChangeNotifier {
  final FinanceRepository _repo;
  final String studentId;
  final String schoolId;

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

  StudentFinanceViewModel(this._repo, this.studentId, this.schoolId);

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

      _invoices = (results[0] as List<Invoice>);
      _payments = (results[1] as List<Payment>);
      _ledger = (results[2] as List<LedgerEntry>);
    } catch (e) {
      _error = "Failed to load finance data: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createInvoice(Invoice invoice, List<InvoiceItem> items) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.createInvoice(invoice, items);
      await loadFinanceData();
    } catch (e) {
      _error = "Failed to create invoice: ${e.toString()}";
      notifyListeners();
    } finally {
      _isLoading = false;
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
      _error = "Failed to record payment: ${e.toString()}";
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }
}