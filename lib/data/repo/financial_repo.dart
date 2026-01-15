import 'package:flutter/foundation.dart';
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/services/database_serv.dart';

// =============================================================================
// FINANCE REPOSITORY INTERFACE
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

// =============================================================================
// POWERSYNC IMPLEMENTATION
// =============================================================================
class PowerSyncFinanceRepository implements FinanceRepository {
  
  @override
  Future<List<Invoice>> getStudentInvoices(String studentId) async {
    try {
      // FIX: Calculate 'total_amount' via subquery
      final result = await db.getAll(
        '''
        SELECT 
          i.*,
          COALESCE((SELECT SUM(amount) FROM invoice_items WHERE invoice_id = i.id), 0.0) as total_amount
        FROM invoices i
        WHERE i.student_id = ? 
        ORDER BY i.due_date DESC
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
          s.first_name || ' ' || s.last_name as student_name
        FROM ledger l
        LEFT JOIN students s ON l.student_id = s.id
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

        return {
          'name': row['student_name'] ?? 'Unknown',
          'desc': desc,
          'amount': type == 'INCOME' ? amount : -amount,
          'time': _formatTime(DateTime.parse(row['occurred_at'])),
          'type': type,
          'targetId': row['student_id'] as String?,
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching recent activity: $e");
      return [];
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
      // 1. Total Revenue
      final revenueResult = await db.getOptional(
        "SELECT SUM(amount) as total FROM ledger WHERE school_id = ? AND type = 'CREDIT'",
        [schoolId],
      );
      final totalRevenue = (revenueResult?['total'] as num?)?.toDouble() ?? 0.0;

      // 2. Pending Amount (Fixed SQL)
      final pendingResult = await db.getOptional(
        '''
        SELECT SUM(ii.amount) as total 
        FROM invoices i
        JOIN invoice_items ii ON i.id = ii.invoice_id
        WHERE i.school_id = ? AND i.status != 'PAID'
        ''',
        [schoolId],
      );
      final pendingAmount = (pendingResult?['total'] as num?)?.toDouble() ?? 0.0;

      // 3. Unpaid Count
      final countResult = await db.getOptional(
        "SELECT COUNT(*) as count FROM invoices WHERE school_id = ? AND status != 'PAID'",
        [schoolId],
      );
      final unpaidInvoiceCount = (countResult?['count'] as int?) ?? 0;

      // 4. Monthly Collections
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

        final denominator = totalRevenue > 0 ? totalRevenue : 1.0;
        monthlyData.add(monthTotal / denominator);
        monthLabels.add(_getMonthLabel(monthStart));
      }

      return {
        'totalRevenue': totalRevenue,
        'pendingAmount': pendingAmount,
        'unpaidInvoiceCount': unpaidInvoiceCount,
        'percentGrowth': 0.0, 
        'monthlyCollections': monthlyData,
        'monthLabels': monthLabels,
      };
    } catch (e) {
      debugPrint("Error fetching finance stats: $e");
      rethrow;
    }
  }

  String _getMonthLabel(DateTime date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[date.month - 1];
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}';
  }
}