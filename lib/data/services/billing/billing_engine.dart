import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:legend/data/constants/app_strings.dart';
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/financial_repo.dart';
import 'package:legend/data/services/database_serv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class BillingEngine {
  static final BillingEngine _instance = BillingEngine._internal(_DbBillingDataSource());
  factory BillingEngine() => _instance;
  BillingEngine._internal(this._source);
  @visibleForTesting
  BillingEngine.withDataSource(this._source);

  final _uuid = const Uuid();
  final BillingDataSource _source;

  Future<bool> enableAutoBilling(String schoolId) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await _getOrCreateDeviceId(prefs);
    final lockKey = _lockKey(schoolId);
    final currentLock = prefs.getString(lockKey);

    if (currentLock != null && currentLock != deviceId) {
      await _recordError(
        schoolId,
        AppStrings.autoBillingLockHeld,
        context: {'lock': currentLock, 'device': deviceId},
      );
      return false;
    }

    await prefs.setString(lockKey, deviceId);
    await prefs.setBool(_enabledKey(schoolId), true);
    return true;
  }

  Future<void> disableAutoBilling(String schoolId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey(schoolId), false);
    await prefs.remove(_lockKey(schoolId));
  }

  Future<bool> isAutoBillingEnabled(String schoolId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey(schoolId)) ?? false;
  }

  Future<bool> takeOverAutoBilling(String schoolId) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await _getOrCreateDeviceId(prefs);
    await prefs.setString(_lockKey(schoolId), deviceId);
    await prefs.setBool(_enabledKey(schoolId), true);
    return true;
  }

  Future<void> runDaily(String schoolId) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await _canRun(prefs, schoolId)) return;

    final today = DateTime.now();
    if (_isSameDay(today, _lastRunDate(prefs, schoolId))) return;

    try {
      await _runForSchool(schoolId, today);
      await prefs.setString(_lastRunKey(schoolId), _dateKey(today));
    } catch (e) {
      await _recordError(schoolId, "${AppStrings.autoBillingFailedPrefix}$e");
    }
  }

  @visibleForTesting
  Future<void> runForSchoolAt(String schoolId, DateTime now) async {
    await _runForSchool(schoolId, now);
  }

  // ---------------------------------------------------------------------------
  // CORE RUN
  // ---------------------------------------------------------------------------

  Future<void> _runForSchool(String schoolId, DateTime now) async {
    final term = await _source.getActiveTerm(schoolId);
    final year = await _source.getActiveYear(schoolId);
    final students = await _source.loadActiveStudents(schoolId);

    for (final row in students) {
      final tuitionAmount = row.tuitionAmount;
      if (tuitionAmount <= 0) {
        await _recordError(
          schoolId,
          AppStrings.autoBillingErrMissingTuition,
          context: {'studentId': row.studentId, 'enrollmentId': row.enrollmentId},
        );
        continue;
      }

      switch (row.billingCycle) {
        case 'MONTHLY_FIXED':
          if (term == null) {
            await _recordError(schoolId, AppStrings.autoBillingErrNoActiveTermMonthlyFixed);
            break;
          }
          await _runMonthlyFixed(row, term, now);
          break;
        case 'MONTHLY_CUSTOM':
          await _runMonthlyCustom(row, now);
          break;
        case 'TERMLY':
          if (term == null) {
            await _recordError(schoolId, AppStrings.autoBillingErrNoActiveTermTermly);
            break;
          }
          await _runTermly(row, term, now);
          break;
        case 'YEARLY':
          if (year == null) {
            await _recordError(schoolId, AppStrings.autoBillingErrNoActiveYearYearly);
            break;
          }
          await _runYearly(row, year, now);
          break;
        case 'CUSTOM':
        default:
          break;
      }
    }
  }

  Future<void> _runMonthlyFixed(BillingStudentRow row, Term term, DateTime now) async {
    final months = _monthsInRange(term.startDate, term.endDate);
    for (final m in months) {
      // FIX: Changed from 5 to 1. "Fixed" implies start of month.
      // Maximum Impact: Get paid sooner.
      final due = DateTime(m.year, m.month, 1); 
      
      if (due.isBefore(term.startDate)) continue;
      if (due.isAfter(term.endDate)) continue;
      // FIX: Use !isAfter to ensure we bill ON the due date, not the day after.
      if (due.isAfter(now)) continue; 

      final periodKey = "${m.year}-${m.month.toString().padLeft(2, '0')}";
      final title = "Tuition - $periodKey";
      await _ensureInvoice(row, due, title, termId: term.id, periodLabel: periodKey);
    }
  }

  Future<void> _runMonthlyCustom(BillingStudentRow row, DateTime now) async {
    final start = row.enrollmentDate;
    if (start == null) {
      await _recordError(
        row.schoolId,
        AppStrings.autoBillingErrMissingEnrollmentDate,
        context: {'studentId': row.studentId, 'enrollmentId': row.enrollmentId},
      );
      return;
    }

    final months = _monthsInRange(start, now);
    for (final m in months) {
      final dueDay = _clampDay(m.year, m.month, start.day);
      final due = DateTime(m.year, m.month, dueDay);
      // FIX: Ensure we bill ON the due date.
      if (due.isAfter(now)) continue;

      final periodKey = "${m.year}-${m.month.toString().padLeft(2, '0')}";
      final title = "Tuition - $periodKey";
      await _ensureInvoice(row, due, title, periodLabel: periodKey);
    }
  }

  Future<void> _runTermly(BillingStudentRow row, Term term, DateTime now) async {
    if (term.startDate.isAfter(now)) return;
    final title = "Tuition - ${term.name}";
    await _ensureInvoice(row, term.startDate, title, termId: term.id, periodLabel: term.name);
  }

  Future<void> _runYearly(BillingStudentRow row, BillingAcademicYear year, DateTime now) async {
    if (year.startDate.isAfter(now)) return;
    final title = "Tuition - ${year.name}";
    await _ensureInvoice(row, year.startDate, title, periodLabel: year.name);
  }

  Future<void> _ensureInvoice(
    BillingStudentRow row,
    DateTime dueDate,
    String title, {
    String? termId,
    required String periodLabel,
  }) async {
    final invoiceId = await _source.findInvoiceId(row.schoolId, row.studentId, title);
    final itemDescription = "Tuition - $periodLabel";

    if (invoiceId != null) {
      final hasItem = await _source.invoiceHasItem(invoiceId, itemDescription);
      if (!hasItem) {
        final item = InvoiceItem(
          id: _uuid.v4(),
          schoolId: row.schoolId,
          invoiceId: invoiceId,
          description: itemDescription,
          amount: row.tuitionAmount,
          quantity: 1,
        );
        await _source.addInvoiceItem(item);
      }
      return;
    }

    final inv = Invoice(
      id: _uuid.v4(),
      schoolId: row.schoolId,
      studentId: row.studentId,
      invoiceNumber: _invoiceNumber(row.studentId, periodLabel),
      dueDate: dueDate,
      status: InvoiceStatus.pending,
      snapshotGrade: row.gradeLevel,
      totalAmount: row.tuitionAmount,
      paidAmount: 0.0,
      title: title,
      termId: termId,
    );

    final item = InvoiceItem(
      id: _uuid.v4(),
      schoolId: row.schoolId,
      invoiceId: inv.id,
      description: itemDescription,
      amount: row.tuitionAmount,
      quantity: 1,
    );

    await _source.createInvoice(inv, [item]);
  }

  // ---------------------------------------------------------------------------
  // DEVICE LOCK + ERROR LOGGING
  // ---------------------------------------------------------------------------

  Future<bool> _canRun(SharedPreferences prefs, String schoolId) async {
    final enabled = prefs.getBool(_enabledKey(schoolId)) ?? false;
    if (!enabled) return false;

    final deviceId = await _getOrCreateDeviceId(prefs);
    final lock = prefs.getString(_lockKey(schoolId));
    if (lock != null && lock != deviceId) return false;
    return true;
  }

  DateTime? _lastRunDate(SharedPreferences prefs, String schoolId) {
    final val = prefs.getString(_lastRunKey(schoolId));
    if (val == null || val.trim().isEmpty) return null;
    return DateTime.tryParse(val);
  }

  Future<String> _getOrCreateDeviceId(SharedPreferences prefs) async {
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.trim().isNotEmpty) return existing;
    final id = _uuid.v4();
    await prefs.setString(_deviceIdKey, id);
    return id;
  }

  Future<void> _recordError(String schoolId, String message, {Map<String, dynamic>? context}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _errorKey(schoolId);
    final raw = prefs.getString(key);
    final list = <Map<String, dynamic>>[];
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              list.add(item.map((k, v) => MapEntry(k.toString(), v)));
            }
          }
        }
      } catch (_) {}
    }

    list.add({
      'ts': DateTime.now().toIso8601String(),
      'message': message,
      'context': context ?? const {},
    });

    if (list.length > 50) {
      list.removeRange(0, list.length - 50);
    }

    await prefs.setString(key, jsonEncode(list));
  }

  Future<List<Map<String, dynamic>>> getErrorLog(String schoolId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_errorKey(schoolId));
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearErrorLog(String schoolId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_errorKey(schoolId));
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _invoiceNumber(String studentId, String periodLabel) {
    final tail = studentId.length > 6 ? studentId.substring(0, 6) : studentId;
    final clean = periodLabel.replaceAll(RegExp(r'\\s+'), '-');
    return "INV-TUI-$clean-$tail";
  }

  List<DateTime> _monthsInRange(DateTime start, DateTime end) {
    final normalizedStart = DateTime(start.year, start.month, 1);
    final normalizedEnd = DateTime(end.year, end.month, 1);
    final months = <DateTime>[];
    var cursor = normalizedStart;
    while (!cursor.isAfter(normalizedEnd)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return months;
  }

  int _clampDay(int year, int month, int day) {
    final last = DateTime(year, month + 1, 0).day;
    return day > last ? last : day;
  }

  String _dateKey(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  bool _isSameDay(DateTime a, DateTime? b) {
    if (b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _enabledKey(String schoolId) => "billing_enabled_$schoolId";
  String _lockKey(String schoolId) => "billing_lock_$schoolId";
  String _lastRunKey(String schoolId) => "billing_last_run_$schoolId";
  String _errorKey(String schoolId) => "billing_error_log_$schoolId";

  static const String _deviceIdKey = "billing_device_id";
}

class BillingStudentRow {
  final String studentId;
  final String schoolId;
  final String billingCycle;
  final String enrollmentId;
  final DateTime? enrollmentDate;
  final double tuitionAmount;
  final String gradeLevel;

  BillingStudentRow({
    required this.studentId,
    required this.schoolId,
    required this.billingCycle,
    required this.enrollmentId,
    required this.enrollmentDate,
    required this.tuitionAmount,
    required this.gradeLevel,
  });
}

class BillingAcademicYear {
  final String id;
  final String schoolId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  BillingAcademicYear({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.startDate,
    required this.endDate,
  });
}

abstract class BillingDataSource {
  Future<Term?> getActiveTerm(String schoolId);
  Future<BillingAcademicYear?> getActiveYear(String schoolId);
  Future<List<BillingStudentRow>> loadActiveStudents(String schoolId);
  Future<String?> findInvoiceId(String schoolId, String studentId, String title);
  Future<bool> invoiceHasItem(String invoiceId, String description);
  Future<void> addInvoiceItem(InvoiceItem item);
  Future<void> createInvoice(Invoice invoice, List<InvoiceItem> items);
}

class _DbBillingDataSource implements BillingDataSource {
  final PowerSyncFinanceRepository _financeRepo = PowerSyncFinanceRepository();

  @override
  Future<Term?> getActiveTerm(String schoolId) async {
    final row = await db.getOptional(
      "SELECT * FROM terms WHERE school_id = ? AND is_active = 1 LIMIT 1",
      [schoolId],
    );
    return row == null ? null : Term.fromRow(row);
  }

  @override
  Future<BillingAcademicYear?> getActiveYear(String schoolId) async {
    final row = await db.getOptional(
      "SELECT * FROM academic_years WHERE school_id = ? AND is_active = 1 LIMIT 1",
      [schoolId],
    );
    if (row == null) return null;
    return BillingAcademicYear(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      name: (row['name'] as String?) ?? 'Year',
      startDate: _parseDate(row['start_date']) ?? DateTime.now(),
      endDate: _parseDate(row['end_date']) ?? DateTime.now(),
    );
  }

  @override
  Future<List<BillingStudentRow>> loadActiveStudents(String schoolId) async {
    final rows = await db.getAll(
      '''
      SELECT
        s.id as student_id,
        s.school_id,
        s.billing_cycle,
        s.status,
        e.id as enrollment_id,
        e.enrollment_date,
        e.created_at as enrollment_created_at,
        e.tuition_amount,
        e.grade_level
      FROM students s
      JOIN enrollments e ON e.student_id = s.id AND e.is_active = 1
      WHERE s.school_id = ? AND s.status = 'ACTIVE'
      ''',
      [schoolId],
    );

    return rows.map((r) {
      final enrollDate = _parseDate(r['enrollment_date']) ?? _parseDate(r['enrollment_created_at']);
      return BillingStudentRow(
        studentId: r['student_id'] as String,
        schoolId: r['school_id'] as String,
        billingCycle: (r['billing_cycle'] as String?)?.toUpperCase() ?? 'TERMLY',
        enrollmentId: r['enrollment_id'] as String,
        enrollmentDate: enrollDate,
        tuitionAmount: (r['tuition_amount'] as num?)?.toDouble() ?? 0.0,
        gradeLevel: (r['grade_level'] as String?) ?? 'Unknown',
      );
    }).toList();
  }

  @override
  Future<String?> findInvoiceId(String schoolId, String studentId, String title) async {
    final row = await db.getOptional(
      "SELECT id FROM invoices WHERE school_id = ? AND student_id = ? AND title = ? LIMIT 1",
      [schoolId, studentId, title],
    );
    return row?['id'] as String?;
  }

  @override
  Future<bool> invoiceHasItem(String invoiceId, String description) async {
    final row = await db.getOptional(
      "SELECT count(*) as count FROM invoice_items WHERE invoice_id = ? AND description = ?",
      [invoiceId, description],
    );
    return ((row?['count'] as num?)?.toInt() ?? 0) > 0;
  }

  @override
  Future<void> addInvoiceItem(InvoiceItem item) async {
    await _financeRepo.addInvoiceItem(item.invoiceId, item);
  }

  @override
  Future<void> createInvoice(Invoice invoice, List<InvoiceItem> items) async {
    await _financeRepo.createInvoice(invoice, items);
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  return DateTime.tryParse(raw.toString());
}