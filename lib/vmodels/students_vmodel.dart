import 'package:flutter/foundation.dart';
import 'package:legend/models/all_models.dart';
import 'package:legend/services/database_serv.dart';

// =============================================================================
// STUDENT REPOSITORY (PowerSync Implementation)
// =============================================================================
abstract class StudentRepository {
  Future<List<Student>> getStudents(String schoolId);
  Future<Student?> getStudentById(String id);
  Future<void> addStudent(Student student);
  Future<void> updateStudent(Student student);
  Future<void> deleteStudent(String id);
  Future<List<Enrollment>> getEnrollments(String studentId);
}

class PowerSyncStudentRepository implements StudentRepository {
  @override
  Future<List<Student>> getStudents(String schoolId) async {
    try {
      final result = await db.getAll(
        '''
        SELECT * FROM students 
        WHERE school_id = ? AND status != 'ARCHIVED'
        ORDER BY last_name, first_name
        ''',
        [schoolId],
      );

      return result.map((row) => Student.fromRow(row)).toList();
    } catch (e) {
      debugPrint("Error fetching students: $e");
      rethrow;
    }
  }

  @override
  Future<Student?> getStudentById(String id) async {
    try {
      final result = await db.getOptional(
        'SELECT * FROM students WHERE id = ?',
        [id],
      );

      return result != null ? Student.fromRow(result) : null;
    } catch (e) {
      debugPrint("Error fetching student: $e");
      rethrow;
    }
  }

  @override
  Future<void> addStudent(Student student) async {
    try {
      await db.execute(
        '''
        INSERT INTO students (
          id, school_id, first_name, last_name, admission_number, 
          status, student_type, guardian_name, guardian_phone, 
          guardian_email, guardian_relationship, gender, dob, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          student.id,
          student.schoolId,
          student.firstName,
          student.lastName,
          student.admissionNumber,
          student.status.name.toUpperCase(),
          student.type.name.toUpperCase(),
          student.guardianName,
          student.guardianPhone,
          student.guardianEmail,
          student.guardianRelationship,
          student.gender,
          student.dob?.toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );
    } catch (e) {
      debugPrint("Error adding student: $e");
      rethrow;
    }
  }

  @override
  Future<void> updateStudent(Student student) async {
    try {
      await db.execute(
        '''
        UPDATE students SET
          first_name = ?, last_name = ?, admission_number = ?,
          status = ?, student_type = ?, guardian_name = ?, guardian_phone = ?,
          guardian_email = ?, guardian_relationship = ?, gender = ?, dob = ?
        WHERE id = ? AND school_id = ?
        ''',
        [
          student.firstName,
          student.lastName,
          student.admissionNumber,
          student.status.name.toUpperCase(),
          student.type.name.toUpperCase(),
          student.guardianName,
          student.guardianPhone,
          student.guardianEmail,
          student.guardianRelationship,
          student.gender,
          student.dob?.toIso8601String(),
          student.id,
          student.schoolId,
        ],
      );
    } catch (e) {
      debugPrint("Error updating student: $e");
      rethrow;
    }
  }

  @override
  Future<void> deleteStudent(String id) async {
    try {
      // Soft delete by setting status to ARCHIVED
      final row = await db.getOptional(
        'SELECT school_id FROM students WHERE id = ?',
        [id],
      );
      await db.execute(
        '''
        UPDATE students SET status = 'ARCHIVED' 
        WHERE id = ? AND school_id = ?
        ''',
        [id, row!['school_id']],
      );
    } catch (e) {
      debugPrint("Error deleting student: $e");
      rethrow;
    }
  }

  @override
  Future<List<Enrollment>> getEnrollments(String studentId) async {
    try {
      final result = await db.getAll(
        '''
        SELECT * FROM enrollments 
        WHERE student_id = ? AND is_active = 1
        ORDER BY created_at DESC
        ''',
        [studentId],
      );

      return result.map((row) => Enrollment.fromRow(row)).toList();
    } catch (e) {
      debugPrint("Error fetching enrollments: $e");
      rethrow;
    }
  }
}

// =============================================================================
// FINANCE REPOSITORY (PowerSync Implementation)
// =============================================================================
abstract class FinanceRepository {
  Future<List<Invoice>> getStudentInvoices(String studentId);
  Future<List<Payment>> getStudentPayments(String studentId);
  Future<List<LedgerEntry>> getStudentLedger(String studentId);
  Future<void> createInvoice(Invoice invoice, List<InvoiceItem> items);
  Future<void> recordPayment(Payment payment);
  Future<List<Map<String, dynamic>>> getRecentActivity(String schoolId);
  Future<Invoice?> getInvoiceById(String invoiceId);
  Future<List<InvoiceItem>> getInvoiceItems(String invoiceId);
  Future<Map<String, dynamic>> getFinanceStats(String schoolId);
}

class PowerSyncFinanceRepository implements FinanceRepository {
  @override
  Future<List<Invoice>> getStudentInvoices(String studentId) async {
    try {
      final result = await db.getAll(
        '''
        SELECT * FROM invoices 
        WHERE student_id = ? 
        ORDER BY due_date DESC
        ''',
        [studentId],
      );

      return result.map((row) => Invoice.fromRow(row)).toList();
    } catch (e) {
      debugPrint("Error fetching invoices: $e");
      rethrow;
    }
  }

  @override
  Future<List<Payment>> getStudentPayments(String studentId) async {
    try {
      final result = await db.getAll(
        '''
        SELECT * FROM payments 
        WHERE student_id = ? 
        ORDER BY received_at DESC
        ''',
        [studentId],
      );

      return result.map((row) => Payment.fromRow(row)).toList();
    } catch (e) {
      debugPrint("Error fetching payments: $e");
      rethrow;
    }
  }

  @override
  Future<List<LedgerEntry>> getStudentLedger(String studentId) async {
    try {
      final result = await db.getAll(
        '''
        SELECT * FROM ledger 
        WHERE student_id = ? 
        ORDER BY occurred_at DESC
        ''',
        [studentId],
      );

      return result.map((row) => LedgerEntry.fromRow(row)).toList();
    } catch (e) {
      debugPrint("Error fetching ledger: $e");
      rethrow;
    }
  }

  @override
  Future<void> createInvoice(Invoice invoice, List<InvoiceItem> items) async {
    try {
      // Create invoice header
      await db.execute(
        '''
        INSERT INTO invoices (
          id, school_id, student_id, invoice_number, due_date, 
          status, snapshot_grade, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          invoice.id,
          invoice.schoolId,
          invoice.studentId,
          invoice.invoiceNumber,
          invoice.dueDate.toIso8601String(),
          invoice.status.name.toUpperCase(),
          invoice.snapshotGrade,
          DateTime.now().toIso8601String(),
        ],
      );

      // Create invoice items
      for (final item in items) {
        await db.execute(
          '''
          INSERT INTO invoice_items (
            id, school_id, invoice_id, description, amount, created_at
          ) VALUES (?, ?, ?, ?, ?, ?)
          ''',
          [
            item.id,
            item.schoolId,
            item.invoiceId,
            item.description,
            item.amount,
            DateTime.now().toIso8601String(),
          ],
        );
      }

      // Update student fees owed
      await db.execute(
        '''
        UPDATE students 
        SET fees_owed = fees_owed + ?
        WHERE id = ? AND school_id = ?
        ''',
        [invoice.totalAmount, invoice.studentId, invoice.schoolId],
      );
    } catch (e) {
      debugPrint("Error creating invoice: $e");
      rethrow;
    }
  }

  @override
  Future<void> recordPayment(Payment payment) async {
    try {
      // Record payment
      await db.execute(
        '''
        INSERT INTO payments (
          id, school_id, student_id, amount, method, 
          reference_code, received_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          payment.id,
          payment.schoolId,
          payment.studentId,
          payment.amount,
          payment.method,
          payment.reference,
          payment.receivedAt.toIso8601String(),
        ],
      );

      // Create ledger entry (credit)
      await db.execute(
        '''
        INSERT INTO ledger (
          id, school_id, student_id, type, amount, 
          description, occurred_at
        ) VALUES (?, ?, ?, 'CREDIT', ?, ?, ?)
        ''',
        [
          'ledger_${DateTime.now().millisecondsSinceEpoch}',
          payment.schoolId,
          payment.studentId,
          payment.amount,
          'Payment received: ${payment.method}',
          DateTime.now().toIso8601String(),
        ],
      );

      // Update student fees owed
      await db.execute(
        '''
        UPDATE students 
        SET fees_owed = MAX(0, fees_owed - ?)
        WHERE id = ? AND school_id = ?
        ''',
        [payment.amount, payment.studentId, payment.schoolId],
      );
    } catch (e) {
      debugPrint("Error recording payment: $e");
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentActivity(String schoolId) async {
    try {
      final result = await db.getAll(
        '''
        SELECT 
          l.*,
          s.first_name || ' ' || s.last_name as student_name,
          s.grade as grade
        FROM ledger l
        JOIN students s ON l.student_id = s.id
        WHERE l.school_id = ?
        ORDER BY l.occurred_at DESC
        LIMIT 10
        ''',
        [schoolId],
      );

      return result.map((row) {
        final type = row['type'] == 'CREDIT' ? 'INCOME' : 'EXPENSE';
        final amount = (row['amount'] as num).toDouble();
        final desc = row['description'] as String;
        final grade = row['grade'] as String? ?? '';

        return {
          'name': row['student_name'] as String,
          'desc': '$desc • $grade',
          'amount': type == 'INCOME' ? amount : -amount,
          'time': _formatTime(DateTime.parse(row['occurred_at'])),
          'type': type,
          'targetId': row['student_id'] as String,
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching recent activity: $e");
      rethrow;
    }
  }

  @override
  Future<Invoice?> getInvoiceById(String invoiceId) async {
    try {
      final result = await db.getOptional(
        'SELECT * FROM invoices WHERE id = ?',
        [invoiceId],
      );

      return result != null ? Invoice.fromRow(result) : null;
    } catch (e) {
      debugPrint("Error fetching invoice: $e");
      rethrow;
    }
  }

  @override
  Future<List<InvoiceItem>> getInvoiceItems(String invoiceId) async {
    try {
      final result = await db.getAll(
        'SELECT * FROM invoice_items WHERE invoice_id = ?',
        [invoiceId],
      );

      return result.map((row) => InvoiceItem.fromRow(row)).toList();
    } catch (e) {
      debugPrint("Error fetching invoice items: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getFinanceStats(String schoolId) async {
    try {
      // Total revenue (sum of all CREDIT ledger entries)
      final revenueResult = await db.getOptional(
        "SELECT SUM(amount) as total FROM ledger WHERE school_id = ? AND type = 'CREDIT'",
        [schoolId],
      );
      final totalRevenue = (revenueResult?['total'] as num?)?.toDouble() ?? 0.0;

      // Pending amount (sum of unpaid invoices)
      final pendingResult = await db.getOptional(
        "SELECT SUM(total_amount) as total FROM invoices WHERE school_id = ? AND status != 'PAID'",
        [schoolId],
      );
      final pendingAmount =
          (pendingResult?['total'] as num?)?.toDouble() ?? 0.0;

      // Unpaid invoice count
      final countResult = await db.getOptional(
        "SELECT COUNT(*) as count FROM invoices WHERE school_id = ? AND status != 'PAID'",
        [schoolId],
      );
      final unpaidInvoiceCount = (countResult?['count'] as int?) ?? 0;

      // Monthly collections for last 6 months
      final now = DateTime.now();
      final monthlyData = <double>[];
      final monthLabels = <String>[];

      for (int i = 5; i >= 0; i--) {
        final monthStart = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 1);

        final monthResult = await db.getOptional(
          "SELECT SUM(amount) as total FROM ledger WHERE school_id = ? AND type = 'CREDIT' AND occurred_at >= ? AND occurred_at < ?",
          [schoolId, monthStart.toIso8601String(), monthEnd.toIso8601String()],
        );
        final monthTotal = (monthResult?['total'] as num?)?.toDouble() ?? 0.0;

        // Normalize to 0-1 for chart (relative to max revenue)
        monthlyData.add(monthTotal / (totalRevenue > 0 ? totalRevenue : 1.0));

        monthLabels.add(_getMonthLabel(monthStart));
      }

      // Percent growth (current month vs previous month)
      double percentGrowth = 0.0;
      if (monthlyData.length >= 2) {
        final current = monthlyData.last * totalRevenue;
        final previous = monthlyData[monthlyData.length - 2] * totalRevenue;
        if (previous > 0) {
          percentGrowth = ((current - previous) / previous) * 100;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'pendingAmount': pendingAmount,
        'unpaidInvoiceCount': unpaidInvoiceCount,
        'percentGrowth': percentGrowth,
        'monthlyCollections': monthlyData,
        'monthLabels': monthLabels,
      };
    } catch (e) {
      debugPrint("Error fetching finance stats: $e");
      rethrow;
    }
  }

  String _getMonthLabel(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[date.month - 1];
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
    } else if (diff.inDays == 1) {
      return 'Yesterday, ${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

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
// STUDENT DETAIL VIEW MODEL
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
        // New student
        student = Student(
          id: 'stu_${DateTime.now().millisecondsSinceEpoch}',
          schoolId: schoolId,
          firstName: student.firstName,
          lastName: student.lastName,
          admissionNumber: student.admissionNumber,
          status: student.status,
          type: student.type,
          guardianName: student.guardianName,
          guardianPhone: student.guardianPhone,
          guardianEmail: student.guardianEmail,
          guardianRelationship: student.guardianRelationship,
          gender: student.gender,
          dob: student.dob,
          feesOwed: 0.0,
          createdAt: DateTime.now(),
        );
        await _repo.addStudent(student);
      } else {
        // Existing student
        await _repo.updateStudent(student);
      }

      _student = student;
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
      final invoicesFuture = _repo.getStudentInvoices(studentId);
      final paymentsFuture = _repo.getStudentPayments(studentId);
      final ledgerFuture = _repo.getStudentLedger(studentId);

      final results = await Future.wait([
        invoicesFuture,
        paymentsFuture,
        ledgerFuture,
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
      await loadFinanceData(); // Refresh data
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
      await loadFinanceData(); // Refresh data
    } catch (e) {
      _error = "Failed to record payment: ${e.toString()}";
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }
}
