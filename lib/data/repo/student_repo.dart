import 'package:legend/app_libs.dart';
import 'package:powersync/powersync.dart';

class StudentException implements Exception {
  final String message;
  StudentException(this.message);
  @override
  String toString() => message;
}

class StudentRepository {
  PowerSyncDatabase get _db => DatabaseService().db;
  final _uuid = const Uuid();

  // ---------------------------------------------------------------------------
  // 1) READINESS & CONFIG
  // ---------------------------------------------------------------------------

  Future<String?> checkSchoolReadiness(String schoolId) async {
    try {
      final yearResult = await _db.get(
        "SELECT count(*) as count FROM academic_years WHERE school_id = ? AND is_active = 1",
        [schoolId],
      );
      if (((yearResult['count'] as num?)?.toInt() ?? 0) == 0) {
        return "No Active Academic Year found. Please go to Settings > Academic Year.";
      }

      final classResult = await _db.get(
        "SELECT count(*) as count FROM classes WHERE school_id = ?",
        [schoolId],
      );
      if (((classResult['count'] as num?)?.toInt() ?? 0) == 0) {
        return "No Classes defined. Please go to Settings > Classes.";
      }

      return null;
    } catch (e) {
      return "System Error checking readiness: $e";
    }
  }

  Future<List<SchoolClass>> getClasses(String schoolId) async {
    final rows = await _db.getAll(
      "SELECT * FROM classes WHERE school_id = ? ORDER BY name ASC",
      [schoolId],
    );
    return rows.map((r) => SchoolClass.fromRow(r)).toList();
  }

  Future<List<String>> getBillingCycles() async {
    // UI labels. DB values are MONTHLY/TERMLY/YEARLY.
    return ['Monthly', 'Termly', 'Yearly'];
  }

  // ---------------------------------------------------------------------------
  // 2) STANDARD CRUD
  // ---------------------------------------------------------------------------

  Future<List<Student>> getStudents(String schoolId) async {
    try {
      final result = await _db.getAll(
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

  Future<Student?> getStudentById(String id) async {
    try {
      final result = await _db.getOptional(
        'SELECT * FROM students WHERE id = ?',
        [id],
      );
      return result != null ? Student.fromRow(result) : null;
    } catch (e) {
      debugPrint("Error fetching student: $e");
      rethrow;
    }
  }

  Future<List<Enrollment>> getEnrollments(
    String studentId, {
    bool includeInactive = true,
  }) async {
    try {
      final sql = includeInactive
          ? '''
          SELECT *
          FROM enrollments
          WHERE student_id = ?
          ORDER BY is_active DESC, created_at DESC
        '''
          : '''
          SELECT *
          FROM enrollments
          WHERE student_id = ? AND is_active = 1
          ORDER BY created_at DESC
        ''';

      final result = await _db.getAll(sql, [studentId]);
      return result.map((row) => Enrollment.fromRow(row)).toList();
    } catch (e) {
      debugPrint("Error fetching enrollments: $e");
      rethrow;
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _db.execute(
        "UPDATE students SET status = 'ARCHIVED' WHERE id = ?",
        [id],
      );
    } catch (e) {
      debugPrint("Error deleting student: $e");
      rethrow;
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      await _db.execute(
        '''
        UPDATE students SET
          first_name = ?, last_name = ?, gender = ?, 
          guardian_name = ?, guardian_phone = ?, guardian_email = ?, student_type = ?
        WHERE id = ?
        ''',
        [
          student.firstName,
          student.lastName,
          student.gender,
          student.guardianName,
          student.guardianPhone,
          student.guardianEmail,
          student.type.name.toUpperCase(), // ACADEMY/PRIVATE
          student.id,
        ],
      );
    } catch (e) {
      debugPrint("Error updating student: $e");
      rethrow;
    }
  }

  Future<void> registerStudent({
    required String schoolId,
    required String firstName,
    required String lastName,
    required String gender,
    required String type,
    required String billingCycle,
    required String guardianName,
    required String guardianPhone,
    String? guardianEmail,
    required String classId,
    required double openingBalance,
    String? debtDescription,
    required List<String> subjects,
    required double initialPayment,
    required String paymentMethod,
  }) async {
    debugPrint("🚀 Starting Atomic Registration & Billing...");

    // Hard guards (no UI trust)
    final ob = openingBalance.isFinite ? openingBalance : 0.0;
    final ip = initialPayment.isFinite ? initialPayment : 0.0;

    if (ob < 0) {
      throw StudentException("Opening Balance cannot be negative.");
    }
    if (ip < 0) {
      throw StudentException("Initial Payment cannot be negative.");
    }
    if (ob == 0 && ip > 0) {
      throw StudentException(
        "Initial Payment requires an Opening Balance invoice. Set Opening Balance > 0 or record payment later.",
      );
    }
    if (ob > 0 && ip > ob) {
      throw StudentException(
        "Initial Payment cannot exceed the Opening Balance.",
      );
    }
    if (subjects.isEmpty) {
      throw StudentException("At least one subject must be selected.");
    }

    await _db.writeTransaction((tx) async {
      // 1) DEPENDENCIES
      final activeYearRow = await tx.getOptional(
        "SELECT id FROM academic_years WHERE school_id = ? AND is_active = 1 LIMIT 1",
        [schoolId],
      );
      if (activeYearRow == null) {
        throw StudentException(
          "Cannot register: No Active Academic Year found.",
        );
      }
      final String activeYearId = activeYearRow['id'] as String;

      final activeTermRow = await tx.getOptional(
        "SELECT id FROM terms WHERE school_id = ? AND is_active = 1 LIMIT 1",
        [schoolId],
      );
      final String? activeTermId = activeTermRow?['id'] as String?;

      if (ob > 0 && activeTermId == null) {
        throw StudentException(
          "Cannot create opening balance: No Active Term found. Go to Settings > Terms.",
        );
      }

      final gradeRow = await tx.get(
        "SELECT g.name as grade_name FROM classes c JOIN grades g ON c.grade_id = g.id WHERE c.id = ?",
        [classId],
      );
      final String gradeLevel =
          (gradeRow['grade_name'] as String?) ?? 'Unknown';

      // 2) IDS
      final String studentId = _uuid.v4();
      final String enrollmentId = _uuid.v4();
      final String admissionNumber =
          "STU-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

      // Use UTC to avoid “date()” issues across devices
      final now = DateTime.now().toUtc();
      final nowIso = now.toIso8601String();

      // 3) NORMALIZE ENUM STRINGS (DB CHECK CONSTRAINT SAFE)
      final String studentTypeDb = _normStudentType(type);
      final String billingCycleDb = _normBillingCycle(billingCycle);
      final String genderDb = _normGender(gender);

      final String? guardianEmailDb = (guardianEmail ?? '').trim().isEmpty
          ? null
          : guardianEmail!.trim();

      // 4) INSERT STUDENT
      await tx.execute(
        """
      INSERT INTO students (
        id, school_id, first_name, last_name, gender, admission_number,
        guardian_name, guardian_phone, guardian_email, student_type,
        billing_cycle, status, fees_owed, created_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE', 0, ?)
      """,
        [
          studentId,
          schoolId,
          firstName.trim(),
          lastName.trim(),
          genderDb,
          admissionNumber,
          guardianName.trim(),
          guardianPhone.trim(),
          guardianEmailDb,
          studentTypeDb,
          billingCycleDb,
          nowIso,
        ],
      );

      // 5) INSERT ENROLLMENT (subjects JSON)
      final subjectsJson = jsonEncode(subjects);
      await tx.execute(
        """
      INSERT INTO enrollments (
        id, school_id, student_id, class_id, academic_year_id,
        enrollment_date, subjects, grade_level, is_active, created_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
      """,
        [
          enrollmentId,
          schoolId,
          studentId,
          classId,
          activeYearId,
          nowIso,
          subjectsJson,
          gradeLevel,
          nowIso,
        ],
      );

      String? openingInvoiceId;

      // 6) OPENING BALANCE (DEBIT -> INVOICE + LEDGER + STUDENT FEES_OWED)
      if (ob > 0) {
        openingInvoiceId = _uuid.v4();

        // IMPORTANT: must be in your enum universe
        const openingStatus = 'PENDING';

        final invoiceNum =
            'INV-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(9)}';

        await tx.execute(
          """
        INSERT INTO invoices (
          id, school_id, student_id, term_id, invoice_number,
          total_amount, paid_amount, status, due_date, title, created_at
        )
        VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?)
        """,
          [
            openingInvoiceId,
            schoolId,
            studentId,
            activeTermId,
            invoiceNum,
            ob,
            openingStatus,
            nowIso, // due_date (you can change later to policy-based due dates)
            "Opening Balance",
            nowIso,
          ],
        );

        await tx.execute(
          """
        INSERT INTO invoice_items (
          id, school_id, invoice_id, fee_structure_id,
          description, amount, quantity, created_at
        )
        VALUES (?, ?, ?, NULL, ?, ?, 1, ?)
        """,
          [
            _uuid.v4(),
            schoolId,
            openingInvoiceId,
            (debtDescription ?? '').trim().isEmpty
                ? "Previous Debt"
                : debtDescription!.trim(),
            ob,
            nowIso,
          ],
        );

        await tx.execute(
          """
        INSERT INTO ledger (
          id, school_id, student_id, type, category, amount,
          invoice_id, payment_id, description, occurred_at
        )
        VALUES (?, ?, ?, 'DEBIT', 'INVOICE', ?, ?, NULL, ?, ?)
        """,
          [
            _uuid.v4(),
            schoolId,
            studentId,
            ob,
            openingInvoiceId,
            "Opening Balance Raised",
            nowIso,
          ],
        );

        // fees_owed increases by opening balance
        await tx.execute(
          "UPDATE students SET fees_owed = COALESCE(fees_owed, 0) + ? WHERE id = ?",
          [ob, studentId],
        );
      }

      // 7) INITIAL PAYMENT (CREDIT -> PAYMENT + LEDGER + APPLY TO OPENING INVOICE)
      if (ip > 0) {
        final paymentId = _uuid.v4();
        final methodDb = _normPaymentMethod(paymentMethod);

        await tx.execute(
          """
        INSERT INTO payments (
          id, school_id, student_id, amount, method, reference_code, received_at
        )
        VALUES (?, ?, ?, ?, ?, 'INITIAL_DEPOSIT', ?)
        """,
          [paymentId, schoolId, studentId, ip, methodDb, nowIso],
        );

        // Link this credit to the opening invoice via ledger if we have one
        await tx.execute(
          """
        INSERT INTO ledger (
          id, school_id, student_id, type, category, amount,
          invoice_id, payment_id, description, occurred_at
        )
        VALUES (?, ?, ?, 'CREDIT', 'PAYMENT', ?, ?, ?, ?, ?)
        """,
          [
            _uuid.v4(),
            schoolId,
            studentId,
            ip,
            openingInvoiceId, // may be null (but we guard against ip>0 when ob==0)
            paymentId,
            "Initial Deposit via $methodDb",
            nowIso,
          ],
        );

        // Apply to invoice: paid_amount + status
        if (openingInvoiceId != null) {
          final newPaid = ip;
          final newStatus = (newPaid >= ob) ? 'PAID' : 'PARTIAL';

          await tx.execute(
            """
          UPDATE invoices
          SET paid_amount = COALESCE(paid_amount, 0) + ?,
              status = ?
          WHERE id = ?
          """,
            [ip, newStatus, openingInvoiceId],
          );
        }

        // Reduce fees_owed (never negative)
        await tx.execute(
          """
        UPDATE students
        SET fees_owed = CASE
          WHEN COALESCE(fees_owed, 0) - ? < 0 THEN 0
          ELSE COALESCE(fees_owed, 0) - ?
        END
        WHERE id = ?
        """,
          [ip, ip, studentId],
        );
      }
    });

    debugPrint("✅ Atomic Registration & Billing Complete!");
  }

  // Keep your existing normalizers; add this if you don’t have it yet:
  String _normPaymentMethod(String v) {
    final s = v.trim().toUpperCase();
    switch (s) {
      case 'CASH':
        return 'CASH';
      case 'ECOCASH':
        return 'ECOCASH';
      case 'BANK':
      case 'TRANSFER':
        return 'TRANSFER';
      case 'SWIPE':
        return 'SWIPE';
      default:
        return 'CASH';
    }
  }

  // ---------------------------------------------------------------------------
  // 4) LOGS (REAL IMPLEMENTATION: derived from ledger)
  // ---------------------------------------------------------------------------

  Future<List<LogEntry>> getStudentLogs(String studentId) async {
    try {
      final rows = await _db.getAll(
        """
        SELECT id, type, category, amount, description, occurred_at
        FROM ledger
        WHERE student_id = ?
        ORDER BY occurred_at DESC
        LIMIT 50
        """,
        [studentId],
      );

      return rows.map((r) {
        final occurredAt =
            DateTime.tryParse((r['occurred_at'] as String?) ?? '') ??
            DateTime.now();
        final category = (r['category'] as String?) ?? 'SYSTEM';
        final type = ((r['type'] as String?) ?? '').toUpperCase();
        final amount = (r['amount'] as num?)?.toDouble() ?? 0.0;

        final title = "$category ${type == 'CREDIT' ? 'Credit' : 'Debit'}";
        final desc = (r['description'] as String?) ?? '$category transaction';
        final logType = LogType.financial;

        return LogEntry(
          id: (r['id'] as String?) ?? _uuid.v4(),
          title: title,
          description: "$desc ($amount)",
          timestamp: occurredAt,
          type: logType,
          performedBy: "System",
        );
      }).toList();
    } catch (e) {
      debugPrint("Error fetching logs from ledger: $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS: normalize values to satisfy DB CHECK constraints
  // ---------------------------------------------------------------------------

  String _normBillingCycle(String raw) {
    final v = raw.trim().toUpperCase();
    if (v == 'MONTHLY') return 'MONTHLY';
    if (v == 'TERMLY' || v == 'TERM' || v == 'TERMly'.toUpperCase())
      return 'TERMLY';
    if (v == 'YEARLY' || v == 'ANNUAL' || v == 'ANNUALLY') return 'YEARLY';

    // UI labels support
    if (v.startsWith('MON')) return 'MONTHLY';
    if (v.startsWith('TER')) return 'TERMLY';
    if (v.startsWith('YEA') || v.startsWith('ANN')) return 'YEARLY';

    // Safe default (matches DB default too)
    return 'TERMLY';
  }

  String _normStudentType(String raw) {
    final v = raw.trim().toUpperCase();
    if (v == 'PRIVATE') return 'PRIVATE';
    if (v == 'ACADEMY') return 'ACADEMY';

    // UI labels support
    if (v.startsWith('PRI')) return 'PRIVATE';

    return 'ACADEMY';
  }

  String _normGender(String raw) {
    final v = raw.trim().toUpperCase();
    if (v == 'M' || v == 'MALE') return 'M';
    if (v == 'F' || v == 'FEMALE') return 'F';
    // DB allows Male/Female/M/F, but keep it strict to avoid surprises.
    return v.isNotEmpty ? v[0] : 'M';
  }
}
