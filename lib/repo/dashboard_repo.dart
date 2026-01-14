import 'package:flutter/cupertino.dart';
import 'package:legend/models/all_models.dart';
import 'package:legend/services/database_serv.dart'; // Access to global 'db'

class DashboardRepository {
  // ===========================================================================
  // 1. DASHBOARD HOME (Metrics & Feeds)
  // ===========================================================================

  /// Fetches the 4 key numbers for the Dashboard Header
  Future<DashboardStats> getDashboardStats(String schoolId) async {
    try {
      // 1. Total Students (Active)
      final studentsRes = await db.get(
        "SELECT count(*) as count FROM students WHERE school_id = ? AND status = 'ACTIVE'",
        [schoolId],
      );

      // 2. Pending Invoices (Posted but not paid)
      final invoiceRes = await db.get(
        "SELECT count(*) as count FROM invoices WHERE school_id = ? AND status = 'POSTED'",
        [schoolId],
      );

      // 3. Collected Today (Payments received since midnight)
      // SQLite: date('now') returns YYYY-MM-DD. We check if received_at starts with today's date.
      final todayRes = await db.get(
        "SELECT sum(amount) as total FROM payments WHERE school_id = ? AND date(received_at) = date('now')",
        [schoolId],
      );

      // 4. Total Owed (Sum of fees_owed column in students table)
      // This assumes you run a background job or trigger to keep student.fees_owed updated
      final owedRes = await db.get(
        "SELECT sum(fees_owed) as total FROM students WHERE school_id = ?",
        [schoolId],
      );

      return DashboardStats(
        totalStudents: (studentsRes['count'] as num?)?.toInt() ?? 0,
        pendingInvoices: (invoiceRes['count'] as num?)?.toInt() ?? 0,
        collectedToday: (todayRes['total'] as num?)?.toDouble() ?? 0.0,
        totalOwed: (owedRes['total'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      // PowerSync tables might not be ready yet
      debugPrint('Error fetching dashboard stats from PowerSync: $e');
      return DashboardStats(
        totalStudents: 0,
        pendingInvoices: 0,
        collectedToday: 0.0,
        totalOwed: 0.0,
      );
    }
  }

  /// Fetches recent payments and enrollments for the "Recent Activity" list.
  /// Formats them directly for the UI.
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

      // Format for UI (Calculates "2 mins ago" etc.)
      return rows.map((row) {
        final date = DateTime.parse(
          (row['date'] as String?) ?? DateTime.now().toIso8601String(),
        );
        final diff = DateTime.now().difference(date);
        String timeLabel;

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
      // PowerSync tables might not be ready yet
      debugPrint('Error fetching recent activity from PowerSync: $e');
      return [];
    }
  }

  // ===========================================================================
  // 2. STATISTICS SCREEN (Charts & Analysis)
  // ===========================================================================

  /// Fetches daily revenue for the last 7 days for the Line Chart.
  /// Returns a Map of { 'MM-DD': amount }
  Future<List<Map<String, dynamic>>> getRevenueTrend(String schoolId) async {
    const sql = """
      SELECT 
        date(received_at) as day, 
        sum(amount) as total 
      FROM payments 
      WHERE school_id = ? 
      AND received_at >= date('now', '-7 days')
      GROUP BY day
      ORDER BY day ASC
    """;

    return await db.getAll(sql, [schoolId]);
  }

  /// Aggregates Debt by Grade Level for the Bar Chart.
  Future<List<Map<String, dynamic>>> getDebtByGrade(String schoolId) async {
    // We join Students with Enrollments to get the grade_level
    const sql = """
      SELECT 
        e.grade_level as grade, 
        sum(s.fees_owed) as amount 
      FROM students s
      JOIN enrollments e ON s.id = e.student_id
      WHERE s.school_id = ? AND e.is_active = 1
      GROUP BY e.grade_level
      ORDER BY amount DESC
    """;

    return await db.getAll(sql, [schoolId]);
  }

  /// Payment Method Breakdown (Cash vs EcoCash vs Bank)
  Future<Map<String, double>> getPaymentMethodStats(String schoolId) async {
    final rows = await db.getAll(
      "SELECT method, count(*) as count FROM payments WHERE school_id = ? GROUP BY method",
      [schoolId],
    );

    final Map<String, double> result = {};
    for (var row in rows) {
      result[row['method'] as String] = (row['count'] as num).toDouble();
    }
    return result;
  }

  // ===========================================================================
  // 3. NOTIFICATIONS (Live Streams)
  // ===========================================================================

  /// WATCH: List of notifications (Real-time updates)
  Stream<List<LegendNotification>> watchNotifications(String schoolId) {
    return db
        .watch(
          "SELECT * FROM noti WHERE school_id = ? ORDER BY created_at DESC",
          parameters: [schoolId],
        )
        .map((rows) {
          return rows.map((row) => LegendNotification.fromRow(row)).toList();
        });
  }

  /// WATCH: Count of unread notifications (For Badge)
  Stream<int> watchUnreadCount(String schoolId) {
    return db
        .watch(
          "SELECT count(*) as count FROM noti WHERE school_id = ? AND is_read = 0",
          parameters: [schoolId],
        )
        .map((rows) => (rows.first['count'] as num).toInt());
  }

  /// WRITE: Mark specific notification as read
  Future<void> markAsRead(String notiId) async {
    await db.execute("UPDATE noti SET is_read = 1 WHERE id = ?", [notiId]);
  }

  /// WRITE: Mark ALL as read
  Future<void> markAllAsRead(String schoolId) async {
    await db.execute("UPDATE noti SET is_read = 1 WHERE school_id = ?", [
      schoolId,
    ]);
  }

  /// WRITE: Clear all notifications
  Future<void> clearAllNotifications(String schoolId) async {
    await db.execute("DELETE FROM noti WHERE school_id = ?", [schoolId]);
  }

  // In lib/repositories/dashboard_repo.dart
  Future<void> deleteNotification(String id) async {
    await db.execute("DELETE FROM noti WHERE id = ?", [id]);
  }

  /// Fetches user profile from the profiles table
  Future<LegendProfile?> getUserProfile(String userId) async {
    try {
      final result = await db.getOptional(
        "SELECT * FROM profiles WHERE id = ?",
        [userId],
      );

      if (result != null) {
        return LegendProfile.fromRow(result);
      }
      return null;
    } catch (e) {
      // PowerSync table might not exist yet or data is incomplete
      debugPrint('Error fetching user profile from PowerSync: $e');
      return null;
    }
  }
}
