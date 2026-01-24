import 'package:legend/app_libs.dart';
import 'package:powersync/powersync.dart';

class AcademicPeriodRepository {
  PowerSyncDatabase get _db => DatabaseService().db;
  final _uuid = const Uuid();

  Future<List<AcademicYear>> getYears(String schoolId) async {
    final rows = await _db.getAll(
      "SELECT * FROM academic_years WHERE school_id = ? ORDER BY start_date DESC",
      [schoolId],
    );
    return rows.map((r) => AcademicYear.fromRow(r)).toList();
  }

  Future<List<Term>> getTermsForYear(String schoolId, String yearId) async {
    final rows = await _db.getAll(
      """
      SELECT * FROM terms
      WHERE school_id = ? AND academic_year_id = ?
      ORDER BY start_date ASC
      """,
      [schoolId, yearId],
    );
    return rows.map((r) => Term.fromRow(r)).toList();
  }

  Future<void> createAcademicYear({
    required String schoolId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    bool setActive = false,
  }) async {
    final id = _uuid.v4();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await _db.writeTransaction((tx) async {
      if (setActive) {
        await tx.execute(
          "UPDATE academic_years SET is_active = 0 WHERE school_id = ?",
          [schoolId],
        );
      }

      await tx.execute(
        """
        INSERT INTO academic_years (
          id, school_id, name, start_date, end_date, is_active, is_locked, created_at
        )
        VALUES (?, ?, ?, ?, ?, ?, 0, ?)
        """,
        [
          id,
          schoolId,
          name.trim(),
          startDate.toIso8601String(),
          endDate.toIso8601String(),
          setActive ? 1 : 0,
          nowIso,
        ],
      );
    });
  }

  Future<void> createTerm({
    required String schoolId,
    required String academicYearId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    bool setActive = false,
  }) async {
    final id = _uuid.v4();

    await _db.writeTransaction((tx) async {
      if (setActive) {
        await tx.execute(
          "UPDATE terms SET is_active = 0 WHERE school_id = ?",
          [schoolId],
        );
      }

      await tx.execute(
        """
        INSERT INTO terms (
          id, school_id, academic_year_id, name, start_date, end_date, is_active
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        [
          id,
          schoolId,
          academicYearId,
          name.trim(),
          startDate.toIso8601String(),
          endDate.toIso8601String(),
          setActive ? 1 : 0,
        ],
      );
    });
  }

  Future<void> setActiveYear(String schoolId, String yearId) async {
    await _db.writeTransaction((tx) async {
      await tx.execute(
        "UPDATE academic_years SET is_active = 0 WHERE school_id = ?",
        [schoolId],
      );
      await tx.execute(
        "UPDATE academic_years SET is_active = 1 WHERE id = ?",
        [yearId],
      );
    });
  }

  Future<void> setActiveTerm(String schoolId, String termId) async {
    await _db.writeTransaction((tx) async {
      await tx.execute(
        "UPDATE terms SET is_active = 0 WHERE school_id = ?",
        [schoolId],
      );
      await tx.execute(
        "UPDATE terms SET is_active = 1 WHERE id = ?",
        [termId],
      );
    });
  }
}
