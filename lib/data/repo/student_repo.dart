import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:legend/data/models/all_models.dart'; 
import 'package:legend/data/services/database_serv.dart'; 
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

class StudentException implements Exception {
  final String message;
  StudentException(this.message);
  @override
  String toString() => message;
}

class StudentRepository {
  // Access DB instance via Singleton
  PowerSyncDatabase get _db => DatabaseService().db;
  
  final _uuid = const Uuid();

  // ---------------------------------------------------------------------------
  // 1. READINESS & CONFIG (The Guardrails)
  // ---------------------------------------------------------------------------

  Future<String?> checkSchoolReadiness(String schoolId) async {
    try {
      // Check 1: Active Academic Year
      final yearResult = await _db.get(
        "SELECT count(*) as count FROM academic_years WHERE school_id = ? AND is_active = 1",
        [schoolId],
      );
      if ((yearResult['count'] as int) == 0) {
        return "No Active Academic Year found. Please go to Settings > Academic Year.";
      }

      // Check 2: Classes Exists (Using 'classes' table)
      final classResult = await _db.get(
        "SELECT count(*) as count FROM classes WHERE school_id = ?",
        [schoolId],
      );
      if ((classResult['count'] as int) == 0) {
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
    return ['Monthly', 'Termly', 'Yearly'];
  }

  // ---------------------------------------------------------------------------
  // 2. STANDARD CRUD
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

  Future<List<Enrollment>> getEnrollments(String studentId) async {
    try {
      final result = await _db.getAll(
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
          student.type.name.toUpperCase(),
          student.id,
        ],
      );
    } catch (e) {
      debugPrint("Error updating student: $e");
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 3. COMPLEX REGISTRATION
  // ---------------------------------------------------------------------------
  
  Future<void> registerStudent({
    required String schoolId,
    required String firstName,
    required String lastName,
    required String gender,
    required String type, 
    required String guardianName,
    required String guardianPhone,
    String? guardianEmail,
    required String classId,
    required double openingBalance,
    String? debtDescription,
    required List<String> subjects,
  }) async {
    debugPrint("🚀 Starting Registration for $firstName $lastName...");

    await _db.writeTransaction((tx) async {
      // A. GET ACTIVE YEAR
      final yearRow = await tx.get(
        "SELECT id FROM academic_years WHERE school_id = ? AND is_active = 1 LIMIT 1",
        [schoolId],
      );
      final String activeYearId = yearRow['id'] as String;

      // B. GET GRADE NAME (Critical for Supabase Sync)
      // This fetches the actual name (e.g. "Form 1") using the class ID
      final gradeRow = await tx.get(
        """
        SELECT g.name as grade_name 
        FROM classes c 
        JOIN grades g ON c.grade_id = g.id 
        WHERE c.id = ?
        """,
        [classId]
      );
      final String gradeLevel = gradeRow['grade_name'] as String;

      // C. GENERATE IDS
      final String studentId = _uuid.v4(); 
      final String admissionNumber = "ADM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

      // D. INSERT STUDENT
      await tx.execute(
        """
        INSERT INTO students (
          id, school_id, first_name, last_name, gender, admission_number, 
          guardian_name, guardian_phone, guardian_email, student_type, status, created_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE', ?)
        """,
        [
          studentId, schoolId, firstName, lastName, gender, admissionNumber, 
          guardianName, guardianPhone, guardianEmail, 
          type, DateTime.now().toIso8601String()
        ],
      );

      // E. INSERT ENROLLMENT (Includes grade_level string and subjects JSON)
      final enrollmentId = _uuid.v4();
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
          DateTime.now().toIso8601String(),
          subjectsJson, 
          gradeLevel, // ✅ Passing the required String
          DateTime.now().toIso8601String()
        ],
      );

      // F. HANDLE OPENING BALANCE
      if (openingBalance > 0) {
        debugPrint("💰 Processing Opening Balance: $openingBalance");
        
        final invoiceId = _uuid.v4();
        await tx.execute(
          """
          INSERT INTO invoices (id, school_id, student_id, term_id, total_amount, paid_amount, status, due_date, title, created_at)
          VALUES (?, ?, ?, ?, ?, 0, 'OVERDUE', ?, ?, ?)
          """,
          [
             invoiceId, 
             schoolId, 
             studentId, 
             activeYearId, 
             openingBalance,
             DateTime.now().toIso8601String(),
             "Opening Balance",
             DateTime.now().toIso8601String()
          ],
        );

        await tx.execute(
          """
          INSERT INTO invoice_items (id, invoice_id, description, amount)
          VALUES (?, ?, ?, ?)
          """,
          [_uuid.v4(), invoiceId, debtDescription ?? "Previous Debt", openingBalance],
        );
      }
    });
    
    debugPrint("✅ Registration Complete!");
  }

  Future<List<LogEntry>> getStudentLogs(String studentId) async {
    try {
      final rows = await _db.getAll(
        "SELECT * FROM student_logs WHERE student_id = ? ORDER BY created_at DESC",
        [studentId],
      );
      return rows.map((r) => LogEntry.fromRow(r)).toList();
    } catch (e) {
      debugPrint("Error fetching logs: $e");
      return []; 
    }
  }
}