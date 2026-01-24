import 'dart:convert';
import 'dart:async';
import 'package:legend/data/constants/app_routes.dart';
import 'package:legend/data/services/database_serv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class NotificationEngine {
  static final NotificationEngine _instance = NotificationEngine._internal();
  factory NotificationEngine() => _instance;
  NotificationEngine._internal();

  final _uuid = const Uuid();

  /// Call this whenever a major action happens (Payment received, Student added)
  /// or run it on a Timer every 5-10 minutes.
  Future<void> runChecks(String schoolId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Run checks in parallel for efficiency
    await Future.wait([
      _checkStudentGrowth(schoolId, userId, prefs),
      _checkIncomeMomentum(schoolId, userId, prefs),
      _checkCollectionHealth(schoolId, userId, prefs),
      _checkMonthlySummary(schoolId, userId, prefs),
    ]);
  }

  // ---------------------------------------------------------------------------
  // 1. GROWTH & MILESTONES (The Cheerleader)
  // ---------------------------------------------------------------------------
  Future<void> _checkStudentGrowth(
    String schoolId, 
    String userId, 
    SharedPreferences prefs
  ) async {
    final key = 'noti_last_student_count_$schoolId';
    final lastCount = prefs.getInt(key) ?? 0;

    final res = await db.getOptional(
      "SELECT count(*) as count FROM students WHERE school_id = ? AND status = 'ACTIVE'",
      [schoolId],
    );
    final currentCount = (res?['count'] as num?)?.toInt() ?? 0;

    // Only notify on significant growth (increments of 10, 50, 100)
    // Adjust logic: If we crossed a "ten" boundary we haven't seen before
    if (currentCount > lastCount) {
      bool milestone = false;
      String message = "";

      if (lastCount < 50 && currentCount >= 50) {
        milestone = true;
        message = "Fifty active students! The campus is coming to life.";
      } else if (lastCount < 100 && currentCount >= 100) {
        milestone = true;
        message = "Triple digits! You've reached 100 active students. Serious growth.";
      } else if ((currentCount ~/ 50) > (lastCount ~/ 50)) {
        // Every 50 students after 100
        milestone = true;
        message = "Another 50 students joined. Your reach is expanding.";
      }

      if (milestone) {
        await _createNotification(
          schoolId: schoolId,
          userId: userId,
          title: "Growth Milestone 🚀",
          message: message,
          type: 'INSIGHT',
          metadata: {'route': AppRoutes.students, 'value': currentCount},
        );
      }
      
      // Update state
      await prefs.setInt(key, currentCount);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. INCOME MOMENTUM (The CFO)
  // ---------------------------------------------------------------------------
  Future<void> _checkIncomeMomentum(
    String schoolId, 
    String userId, 
    SharedPreferences prefs
  ) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'noti_income_check_$schoolId';
    final lastCheckDate = prefs.getString(key);

    // Don't spam: Only run this check once per day in the evening (e.g., after 4 PM)
    // or if we haven't checked today.
    if (lastCheckDate == todayStr) return; // Already checked today

    final now = DateTime.now();
    if (now.hour < 16) return; // Wait until end of day for the summary

    // Compare Today vs Yesterday
    final todayRes = await db.getOptional(
      "SELECT SUM(amount) as total FROM payments WHERE school_id = ? AND substr(received_at, 1, 10) = ?",
      [schoolId, todayStr],
    );
    final yesterdayStr = now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final yesterdayRes = await db.getOptional(
      "SELECT SUM(amount) as total FROM payments WHERE school_id = ? AND substr(received_at, 1, 10) = ?",
      [schoolId, yesterdayStr],
    );

    final todayTotal = (todayRes?['total'] as num?)?.toDouble() ?? 0.0;
    final yesterdayTotal = (yesterdayRes?['total'] as num?)?.toDouble() ?? 0.0;

    if (todayTotal > 0) {
      if (todayTotal > (yesterdayTotal * 1.5) && yesterdayTotal > 0) {
        // 50% increase over yesterday
        await _createNotification(
          schoolId: schoolId,
          userId: userId,
          title: "Revenue Spike 📈",
          message: "Strong performance today! Collections are up 50% compared to yesterday.",
          type: 'SUCCESS',
          metadata: {'route': AppRoutes.finance, 'amount': todayTotal},
        );
      } else if (todayTotal > 1000) { 
        // Arbitrary "Good Day" threshold - customize this based on config currency later
        await _createNotification(
          schoolId: schoolId,
          userId: userId,
          title: "Solid Collection Day",
          message: "You've collected ${_formatCurrency(todayTotal)} today. Keep the momentum going.",
          type: 'INSIGHT',
          metadata: {'route': AppRoutes.finance, 'amount': todayTotal},
        );
      }
      // Mark as checked for today
      await prefs.setString(key, todayStr);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. COLLECTION HEALTH (The Risk Analyst)
  // ---------------------------------------------------------------------------
  Future<void> _checkCollectionHealth(
    String schoolId, 
    String userId, 
    SharedPreferences prefs
  ) async {
    // Run this weekly (e.g., every Friday)
    final key = 'noti_health_check_week_$schoolId';
    final currentWeek = "${DateTime.now().year}-${_getWeekOfYear(DateTime.now())}";
    
    if (prefs.getString(key) == currentWeek) return;

    final stats = await db.getOptional(
      """
      SELECT 
        (SELECT count(*) FROM invoices WHERE school_id = ? AND status = 'PAID') as paid_count,
        (SELECT count(*) FROM invoices WHERE school_id = ? AND status != 'PAID') as pending_count
      """,
      [schoolId, schoolId],
    );

    final paid = (stats?['paid_count'] as num?)?.toInt() ?? 0;
    final pending = (stats?['pending_count'] as num?)?.toInt() ?? 0;
    final total = paid + pending;

    if (total > 10) { // Only analyse if we have data
      final pendingRate = pending / total;
      
      if (pendingRate > 0.6) {
        await _createNotification(
          schoolId: schoolId,
          userId: userId,
          title: "Cash Flow Alert ⚠️",
          message: "Action required: Over 60% of invoices are still pending. Consider sending a bulk reminder.",
          type: 'WARNING',
          metadata: {'route': AppRoutes.finance, 'pending_rate': pendingRate},
        );
      }
    }

    await prefs.setString(key, currentWeek);
  }

  // ---------------------------------------------------------------------------
  // 4. MONTHLY REPORTS (The Secretary)
  // ---------------------------------------------------------------------------
  Future<void> _checkMonthlySummary(
    String schoolId, 
    String userId, 
    SharedPreferences prefs
  ) async {
    final now = DateTime.now();
    // Only run on the 1st of the month
    if (now.day != 1) return;

    final lastMonth = DateTime(now.year, now.month - 1);
    final monthKey = "${lastMonth.year}-${lastMonth.month}";
    final key = 'noti_month_report_$schoolId';

    if (prefs.getString(key) == monthKey) return; // Already generated

    // Calculate last month's total
    final startStr = "${lastMonth.year}-${lastMonth.month.toString().padLeft(2,'0')}-01";
    final endStr = "${lastMonth.year}-${lastMonth.month.toString().padLeft(2,'0')}-31";

    final res = await db.getOptional(
      """
      SELECT SUM(amount) as total 
      FROM payments 
      WHERE school_id = ? 
      AND date(received_at) >= date(?) 
      AND date(received_at) <= date(?)
      """,
      [schoolId, startStr, endStr],
    );

    final total = (res?['total'] as num?)?.toDouble() ?? 0.0;

    await _createNotification(
      schoolId: schoolId,
      userId: userId,
      title: "Monthly Report Ready 📊",
      message: "Last month closed with ${_formatCurrency(total)} in collections. Tap to see the breakdown.",
      type: 'INFO',
      metadata: {'route': '${AppRoutes.dashboard}/${AppRoutes.statistics}', 'month': monthKey},
    );

    await prefs.setString(key, monthKey);
  }

  // ---------------------------------------------------------------------------
  // INTERNAL HELPERS
  // ---------------------------------------------------------------------------

  Future<void> _createNotification({
    required String schoolId,
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    await db.execute(
      """
      INSERT INTO noti (id, school_id, user_id, title, message, type, is_read, metadata, created_at)
      VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?)
      """,
      [
        _uuid.v4(),
        schoolId,
        userId,
        title,
        message,
        type,
        jsonEncode(metadata ?? {}),
        DateTime.now().toIso8601String(),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return "\$${amount.toStringAsFixed(2)}";
  }

  int _getWeekOfYear(DateTime date) {
    final dayOfYear = int.parse("${date.difference(DateTime(date.year, 1, 1, 0, 0)).inDays}");
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}
