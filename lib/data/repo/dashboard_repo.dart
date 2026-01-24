import 'package:flutter/foundation.dart' show debugPrint;
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/services/database_serv.dart'; // provides global `db`

class DashboardRepository {
  // Canonical meaning of "pending/unsettled" across the app:
  // Anything not settled but issued.
  static const _openStatuses = "'PENDING','PARTIAL','OVERDUE'";

  // ===========================================================================
  // 1. DASHBOARD HOME (Metrics & Feeds)
  // ===========================================================================

  Future<DashboardStats> getDashboardStats(String schoolId) async {
    try {
      final studentsRes = await db.get(
        "SELECT count(*) as count FROM students WHERE school_id = ? AND status = 'ACTIVE'",
        [schoolId],
      );

      // IMPORTANT: Never use POSTED. Your enum set has no POSTED.
      // Open invoices = PENDING / PARTIAL / OVERDUE
      final invoiceRes = await db.get(
        """
        SELECT count(*) as count
        FROM invoices
        WHERE school_id = ?
          AND UPPER(status) IN ($_openStatuses)
        """,
        [schoolId],
      );

      // Safer than date(received_at) if received_at is ISO8601 text:
      // compare the YYYY-MM-DD prefix to today's local date.
      final todayRes = await db.get(
        """
        SELECT COALESCE(SUM(amount), 0) as total
        FROM payments
        WHERE school_id = ?
          AND substr(received_at, 1, 10) = date('now','localtime')
        """,
        [schoolId],
      );

      final owedRes = await db.get(
        "SELECT COALESCE(sum(fees_owed), 0) as total FROM students WHERE school_id = ?",
        [schoolId],
      );

      return DashboardStats(
        totalStudents: (studentsRes['count'] as num?)?.toInt() ?? 0,
        pendingInvoices: (invoiceRes['count'] as num?)?.toInt() ?? 0,
        collectedToday: (todayRes['total'] as num?)?.toDouble() ?? 0.0,
        totalOwed: (owedRes['total'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      return DashboardStats(
        totalStudents: 0,
        pendingInvoices: 0,
        collectedToday: 0.0,
        totalOwed: 0.0,
      );
    }
  }

  Stream<DashboardStats> watchDashboardStats(String schoolId) {
    return db
        .watch(
          """
          SELECT
            (SELECT count(*) FROM students WHERE school_id = ? AND status = 'ACTIVE') as total_students,
            (SELECT count(*) FROM invoices
              WHERE school_id = ? AND UPPER(status) IN ($_openStatuses)) as pending_invoices,
            (SELECT COALESCE(SUM(amount), 0) FROM payments
              WHERE school_id = ? AND substr(received_at, 1, 10) = date('now','localtime')) as collected_today,
            (SELECT COALESCE(SUM(fees_owed), 0) FROM students WHERE school_id = ?) as total_owed
          """,
          parameters: [schoolId, schoolId, schoolId, schoolId],
        )
        .map((rows) {
          final row = rows.isNotEmpty ? rows.first : const <String, Object?>{};
          return DashboardStats(
            totalStudents: (row['total_students'] as num?)?.toInt() ?? 0,
            pendingInvoices: (row['pending_invoices'] as num?)?.toInt() ?? 0,
            collectedToday: (row['collected_today'] as num?)?.toDouble() ?? 0.0,
            totalOwed: (row['total_owed'] as num?)?.toDouble() ?? 0.0,
          );
        });
  }

  Future<List<Map<String, dynamic>>> getRecentActivity(String schoolId) async {
    try {
      const sql = """
      SELECT
        p.id,
        'payment' as type,
        p.amount,
        s.first_name || ' ' || s.last_name as name,
        'Payment - ' || p.method as description,
        p.received_at as date
      FROM payments p
      LEFT JOIN students s ON p.student_id = s.id
      WHERE p.school_id = ?
      ORDER BY p.received_at DESC
      LIMIT 5
    """;

      final rows = await db.getAll(sql, [schoolId]);

      return rows.map((row) {
        final date = DateTime.tryParse((row['date'] as String?) ?? '') ?? DateTime.now();
        final diff = DateTime.now().difference(date);

        final String timeLabel;
        if (diff.inMinutes < 60) {
          timeLabel = '${diff.inMinutes} mins ago';
        } else if (diff.inHours < 24) {
          timeLabel = '${diff.inHours} hours ago';
        } else {
          timeLabel = '${diff.inDays} days ago';
        }

        return {
          'name': row['name'] ?? 'Unknown',
          'desc': row['description'] ?? 'No description',
          'time': timeLabel,
          'amount': ((row['amount'] as num?) ?? 0).toDouble(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching recent activity: $e');
      return [];
    }
  }

  // ===========================================================================
  // 2. STATISTICS SCREEN (Charts & Analysis)
  // ===========================================================================

  Future<List<Map<String, dynamic>>> getRevenueTrend(String schoolId) async {
    const sql = """
      SELECT
        date(received_at) as day,
        sum(amount) as total
      FROM payments
      WHERE school_id = ?
        AND datetime(received_at) >= datetime('now', '-7 days')
      GROUP BY day
      ORDER BY day ASC
    """;
    return db.getAll(sql, [schoolId]);
  }

  Future<List<Map<String, dynamic>>> getRevenueTrendForRange(
    String schoolId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    const sql = """
      SELECT
        date(received_at) as day,
        sum(amount) as total
      FROM payments
      WHERE school_id = ?
        AND datetime(received_at) >= datetime(?)
        AND datetime(received_at) <= datetime(?)
      GROUP BY day
      ORDER BY day ASC
    """;
    return db.getAll(
      sql,
      [
        schoolId,
        startDate.toUtc().toIso8601String(),
        endDate.toUtc().toIso8601String(),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getDebtByGrade(String schoolId) async {
    const sql = """
      SELECT
        e.grade_level as grade,
        sum(s.fees_owed) as amount
      FROM students s
      JOIN enrollments e ON s.id = e.student_id
      WHERE s.school_id = ?
        AND e.is_active = 1
      GROUP BY e.grade_level
      ORDER BY amount DESC
    """;
    return db.getAll(sql, [schoolId]);
  }

  Future<Map<String, double>> getPaymentMethodStats(String schoolId,
      {DateTime? startDate, DateTime? endDate}) async {
    final hasRange = startDate != null && endDate != null;
    final sql = hasRange
        ? """
          SELECT method, count(*) as count
          FROM payments
          WHERE school_id = ?
            AND datetime(received_at) >= datetime(?)
            AND datetime(received_at) <= datetime(?)
          GROUP BY method
        """
        : "SELECT method, count(*) as count FROM payments WHERE school_id = ? GROUP BY method";
    final params = hasRange
        ? [
            schoolId,
            startDate.toUtc().toIso8601String(),
            endDate.toUtc().toIso8601String(),
          ]
        : [schoolId];

    final rows = await db.getAll(sql, params);

    final Map<String, double> result = {};
    for (final row in rows) {
      final method = (row['method'] as String?) ?? 'UNKNOWN';
      result[method] = (row['count'] as num?)?.toDouble() ?? 0.0;
    }
    return result;
  }

  // ===========================================================================
  // 3. NOTIFICATIONS (Live Streams)
  // ===========================================================================

  Stream<List<LegendNotification>> watchNotifications(String schoolId) {
    return db
        .watch(
          "SELECT * FROM noti WHERE school_id = ? ORDER BY created_at DESC",
          parameters: [schoolId],
        )
        .map((rows) => rows.map((r) => LegendNotification.fromRow(r)).toList());
  }

  Stream<int> watchUnreadCount(String schoolId) {
    return db
        .watch(
          "SELECT count(*) as count FROM noti WHERE school_id = ? AND is_read = 0",
          parameters: [schoolId],
        )
        .map((rows) => (rows.isEmpty) ? 0 : ((rows.first['count'] as num?)?.toInt() ?? 0));
  }

  Future<void> markAsRead(String notiId) => db.execute("UPDATE noti SET is_read = 1 WHERE id = ?", [notiId]);
  Future<void> markAllAsRead(String schoolId) => db.execute("UPDATE noti SET is_read = 1 WHERE school_id = ?", [schoolId]);
  Future<void> clearAllNotifications(String schoolId) => db.execute("DELETE FROM noti WHERE school_id = ?", [schoolId]);
  Future<void> deleteNotification(String id) => db.execute("DELETE FROM noti WHERE id = ?", [id]);

  Future<LegendProfile?> getUserProfile(String userId) async {
    try {
      final result = await db.getOptional("SELECT * FROM profiles WHERE id = ?", [userId]);
      return result != null ? LegendProfile.fromRow(result) : null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<Term?> getActiveTerm(String schoolId) async {
    try {
      final row = await db.getOptional(
        "SELECT * FROM terms WHERE school_id = ? AND is_active = 1 LIMIT 1",
        [schoolId],
      );
      return row != null ? Term.fromRow(row) : null;
    } catch (e) {
      debugPrint('Error fetching active term: $e');
      return null;
    }
  }

  Future<Term?> getPreviousTerm(String schoolId, DateTime beforeDate) async {
    try {
      final row = await db.getOptional(
        """
        SELECT * FROM terms
        WHERE school_id = ?
          AND datetime(end_date) < datetime(?)
        ORDER BY datetime(end_date) DESC
        LIMIT 1
        """,
        [schoolId, beforeDate.toUtc().toIso8601String()],
      );
      return row != null ? Term.fromRow(row) : null;
    } catch (e) {
      debugPrint('Error fetching previous term: $e');
      return null;
    }
  }

  // ===========================================================================
  // 4. NUCLEAR RESET (Student + Finance Data)
  // ===========================================================================

  Future<void> deleteAllStudentData(String schoolId) async {
    await db.writeTransaction((tx) async {
      await tx.execute("DELETE FROM payment_allocations WHERE school_id = ?", [schoolId]);
      await tx.execute("DELETE FROM invoice_items WHERE school_id = ?", [schoolId]);
      await tx.execute("DELETE FROM payments WHERE school_id = ?", [schoolId]);
      await tx.execute("DELETE FROM invoices WHERE school_id = ?", [schoolId]);
      await tx.execute("DELETE FROM ledger WHERE school_id = ?", [schoolId]);
      await tx.execute("DELETE FROM enrollments WHERE school_id = ?", [schoolId]);
      await tx.execute("DELETE FROM students WHERE school_id = ?", [schoolId]);
    });
  }
}
