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

  Future<Map<String, double>> getPaymentMethodStats(String schoolId) async {
    final rows = await db.getAll(
      "SELECT method, count(*) as count FROM payments WHERE school_id = ? GROUP BY method",
      [schoolId],
    );

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
}
