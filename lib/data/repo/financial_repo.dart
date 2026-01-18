// ==========================================
// FILE: ./financial_repo.dart
// ==========================================

import 'package:legend/app_libs.dart';

// =============================================================================
// FINANCE REPOSITORY INTERFACE
// =============================================================================
abstract class FinanceRepository {
  Future<List<Invoice>> getStudentInvoices(String studentId);
  Future<List<Invoice>> getOpenInvoicesForStudent(String studentId);
  Future<List<Payment>> getStudentPayments(String studentId);
  Future<List<LedgerEntry>> getStudentLedger(String studentId);
  Future<void> createInvoice(Invoice invoice, List<InvoiceItem> items);
  Future<void> recordPayment(Payment payment);
  Future<List<Map<String, dynamic>>> getRecentActivity(String schoolId, {int limit = 10});
  Future<List<Map<String, dynamic>>> getOutstandingStudents(String schoolId, {int limit = 10});
  Future<List<Map<String, dynamic>>> getRecentPayments(
    String schoolId, {
    int limit = 10,
    DateTime? onDate,
  });
  Future<Invoice?> getInvoiceById(String invoiceId);
  Future<List<InvoiceItem>> getInvoiceItems(String invoiceId);
  Future<Map<String, dynamic>> getFinanceStats(String schoolId, {DateTime? startDate, DateTime? endDate});
  Future<void> addInvoiceItem(String invoiceId, InvoiceItem item);
}

// =============================================================================
// POWERSYNC/LOCAL SQLITE IMPLEMENTATION
// =============================================================================
class PowerSyncFinanceRepository implements FinanceRepository {
  final Uuid _uuid = const Uuid();

  static const _openStatuses = "'PENDING','PARTIAL','OVERDUE'";

  @override
  Future<List<Invoice>> getStudentInvoices(String studentId) async {
    try {
      final result = await db.getAll(
        '''
      SELECT
        i.id,
        i.school_id,
        i.student_id,
        i.invoice_number,
        i.term_id,
        i.due_date,
        i.status,
        i.snapshot_grade,
        -- Total = sum(items) else fall back to stored invoice total_amount
        COALESCE(
          (SELECT SUM(COALESCE(ii.amount,0) * COALESCE(ii.quantity,1))
           FROM invoice_items ii
           WHERE ii.invoice_id = i.id),
          i.total_amount,
          0
        ) AS total_amount,
        COALESCE(i.paid_amount, 0) AS paid_amount,
        i.title,
        i.created_at
      FROM invoices i
      WHERE i.student_id = ?
      ORDER BY datetime(i.due_date) DESC
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
  Future<List<Invoice>> getOpenInvoicesForStudent(String studentId) async {
    try {
      final result = await db.getAll(
        '''
      SELECT *
      FROM invoices
      WHERE student_id = ?
        AND UPPER(status) IN ($_openStatuses)
      ORDER BY datetime(due_date) ASC
      ''',
        [studentId],
      );
      return result.map((row) => Invoice.fromRow(row)).toList();
    } catch (e) {
      debugPrint("Error fetching open invoices: $e");
      rethrow;
    }
  }

  @override
  Future<List<Payment>> getStudentPayments(String studentId) async {
    try {
      final result = await db.getAll(
        '''
      SELECT *
      FROM payments
      WHERE student_id = ?
      ORDER BY datetime(received_at) DESC
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
      SELECT *
      FROM ledger
      WHERE student_id = ?
      ORDER BY datetime(occurred_at) DESC
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
    final now = DateTime.now().toIso8601String();

    // Source of truth: items (quantity-aware)
    final computedTotal = items.fold<double>(
      0.0,
      (sum, it) => sum + (it.amount * (it.quantity <= 0 ? 1 : it.quantity)),
    );

    try {
      await db.execute('BEGIN');

      // 1) Insert invoice (offline-first: write key fields)
      await db.execute(
        '''
      INSERT INTO invoices (
        id, school_id, student_id, invoice_number,
        due_date, status, snapshot_grade,
        created_at, total_amount, paid_amount, title, term_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
        [
          invoice.id,
          invoice.schoolId,
          invoice.studentId,
          invoice.invoiceNumber,
          invoice.dueDate.toIso8601String(),
          invoice.status.name.toUpperCase(),
          invoice.snapshotGrade,
          now,
          computedTotal, // reconciled: do NOT trust invoice.totalAmount
          invoice.paidAmount, // usually 0.0 at creation
          invoice.title,
          invoice.termId, // nullable OK
        ],
      );

      // 2) Insert items (include fee_structure_id + quantity)
      for (final item in items) {
        final qty = item.quantity <= 0 ? 1 : item.quantity;

        await db.execute(
          '''
        INSERT INTO invoice_items (
          id, school_id, invoice_id, fee_structure_id,
          description, amount, quantity, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
          [
            item.id,
            item.schoolId,
            item.invoiceId,
            item.feeStructureId, // nullable OK
            item.description,
            item.amount,
            qty,
            now,
          ],
        );
      }

      // 3) Update student fees_owed using computedTotal
      await db.execute(
        '''
      UPDATE students
      SET fees_owed = COALESCE(fees_owed, 0) + ?
      WHERE id = ? AND school_id = ?
      ''',
        [computedTotal, invoice.studentId, invoice.schoolId],
      );

      // 4) Ledger debit for the invoice (student balance increases)
      await db.execute(
        '''
      INSERT INTO ledger (
        id, school_id, student_id,
        type, category, amount,
        invoice_id, payment_id, description, occurred_at
      ) VALUES (?, ?, ?, 'DEBIT', 'INVOICE', ?, ?, NULL, ?, ?)
      ''',
        [
          _uuid.v4(),
          invoice.schoolId,
          invoice.studentId,
          computedTotal,
          invoice.id,
          'Invoice ${invoice.invoiceNumber}',
          now,
        ],
      );

      await db.execute('COMMIT');
    } catch (e) {
      try {
        await db.execute('ROLLBACK');
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<void> recordPayment(Payment payment) async {
    // Use the payment's receivedAt as the single time source (UTC)
    final occurredAt = payment.receivedAt.toUtc();
    final occurredAtIso = occurredAt.toIso8601String();

    final paymentId = (payment.id.isNotEmpty) ? payment.id : _uuid.v4();

    // Guard rails (no UI trust)
    final amount = payment.amount.isFinite ? payment.amount : 0.0;
    if (amount <= 0) {
      throw Exception("Payment amount must be greater than 0.");
    }

    try {
      await db.writeTransaction((tx) async {
        // 1) Insert payment row
        await tx.execute(
          '''
      INSERT INTO payments (
        id, school_id, student_id, amount, method, reference_code, received_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
          [
            paymentId,
            payment.schoolId,
            payment.studentId,
            amount,
            payment.method, // optionally normalize to uppercase here
            payment.reference, // maps to reference_code
            occurredAtIso,
          ],
        );

        // 2) If invoices exist for this student, treat invoices as the truth.
        final invCountRow = await tx.get(
          '''
      SELECT count(*) as c
      FROM invoices
      WHERE school_id = ? AND student_id = ?
      ''',
          [payment.schoolId, payment.studentId],
        );
        final int invoiceCount = (invCountRow['c'] as num?)?.toInt() ?? 0;

        double remaining = amount;

        if (invoiceCount > 0) {
          // 2a) Fetch open invoices (oldest due first)
          final openInvoices = await tx.getAll(
          '''
        SELECT id, invoice_number, total_amount, paid_amount, status, due_date, created_at
        FROM invoices
        WHERE school_id = ?
          AND student_id = ?
          AND status IN ('PENDING', 'PARTIAL', 'OVERDUE')
        ORDER BY datetime(due_date) ASC, datetime(created_at) ASC
        ''',
            [payment.schoolId, payment.studentId],
          );

          // 2b) Allocate payment across invoices
          for (final inv in openInvoices) {
            if (remaining <= 0) break;

            final String invoiceId = inv['id'] as String;
            final String invoiceNumber =
                (inv['invoice_number'] as String?) ?? invoiceId;

            final double total = (inv['total_amount'] as num?)?.toDouble() ?? 0.0;
            final double paid = (inv['paid_amount'] as num?)?.toDouble() ?? 0.0;

            final double outstanding = (total - paid) <= 0 ? 0.0 : (total - paid);
            if (outstanding <= 0) continue;

            final double apply = remaining < outstanding
                ? remaining
                : outstanding;
            final double newPaid = paid + apply;

            final String newStatus = (newPaid >= total && total > 0)
                ? 'PAID'
                : 'PARTIAL';

            // Update invoice
            await tx.execute(
            '''
          UPDATE invoices
          SET paid_amount = ?, status = ?
          WHERE id = ? AND school_id = ?
          ''',
              [newPaid, newStatus, invoiceId, payment.schoolId],
            );

            // Ledger row (linked to invoice + payment)
            await tx.execute(
            '''
          INSERT INTO ledger (
            id, school_id, student_id,
            type, category, amount,
            invoice_id, payment_id,
            description, occurred_at
          ) VALUES (?, ?, ?, 'CREDIT', 'PAYMENT', ?, ?, ?, ?, ?)
          ''',
              [
                _uuid.v4(),
                payment.schoolId,
                payment.studentId,
                apply,
                invoiceId,
                paymentId,
                'Payment via ${payment.method} -> $invoiceNumber',
                occurredAtIso,
              ],
            );

            remaining -= apply;
          }

          // 2c) If payment exceeds open invoices, keep it as unallocated credit in ledger
          // (No schema for "credit_balance" yet, but at least we do not lose the audit trail)
          if (remaining > 0) {
            await tx.execute(
            '''
          INSERT INTO ledger (
            id, school_id, student_id,
            type, category, amount,
            invoice_id, payment_id,
            description, occurred_at
          ) VALUES (?, ?, ?, 'CREDIT', 'PAYMENT', ?, NULL, ?, ?, ?)
          ''',
              [
                _uuid.v4(),
                payment.schoolId,
                payment.studentId,
                remaining,
                paymentId,
                'Unallocated overpayment via ${payment.method} (advance credit)',
                occurredAtIso,
              ],
            );
          }

          // 2d) Reconcile student.fees_owed from invoices (single source of truth)
          final owedRow = await tx.get(
          '''
        SELECT COALESCE(SUM(
          CASE
            WHEN COALESCE(total_amount,0) - COALESCE(paid_amount,0) < 0 THEN 0
            ELSE COALESCE(total_amount,0) - COALESCE(paid_amount,0)
          END
        ), 0) as owed
        FROM invoices
        WHERE school_id = ?
          AND student_id = ?
          AND status IN ('PENDING', 'PARTIAL', 'OVERDUE')
        ''',
            [payment.schoolId, payment.studentId],
          );

          final double newOwed = (owedRow['owed'] as num?)?.toDouble() ?? 0.0;

          await tx.execute(
          '''
        UPDATE students
        SET fees_owed = ?
        WHERE id = ? AND school_id = ?
        ''',
            [newOwed, payment.studentId, payment.schoolId],
          );
        } else {
          // Legacy fallback: no invoices exist, so we only adjust fees_owed and ledger without invoice_id.

          await tx.execute(
          '''
        INSERT INTO ledger (
          id, school_id, student_id,
          type, category, amount,
          payment_id, description, occurred_at
        ) VALUES (?, ?, ?, 'CREDIT', 'PAYMENT', ?, ?, ?, ?)
        ''',
            [
              _uuid.v4(),
              payment.schoolId,
              payment.studentId,
              amount,
              paymentId,
              'Payment via ${payment.method}',
              occurredAtIso,
            ],
          );

          await tx.execute(
          '''
        UPDATE students
        SET fees_owed = CASE
          WHEN COALESCE(fees_owed, 0) - ? < 0 THEN 0
          ELSE COALESCE(fees_owed, 0) - ?
        END
        WHERE id = ? AND school_id = ?
        ''',
            [amount, amount, payment.studentId, payment.schoolId],
          );
        }
      });
    } catch (e) {
      debugPrint("Error recording payment: $e");
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentActivity(String schoolId, {int limit = 10}) async {
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
        LIMIT ?
        ''',
        [schoolId, limit],
      );

      return result.map((row) {
        final type = (row['type'] as String?) ?? '';
        final isIncome = type.toUpperCase() == 'CREDIT';
        final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
        final desc = (row['description'] as String?) ?? '';

        return {
          'name': row['student_name'] ?? 'Unknown',
          'desc': desc,
          'amount': isIncome ? amount : -amount,
          'time': _formatTime(DateTime.parse(row['occurred_at'] as String)),
          'type': isIncome ? 'INCOME' : 'EXPENSE',
          'targetId': row['student_id'] as String?,
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching recent activity: $e");
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getOutstandingStudents(String schoolId, {int limit = 10}) async {
    try {
      final result = await db.getAll(
        '''
        SELECT
          s.id,
          s.first_name || ' ' || s.last_name as name,
          COALESCE(s.fees_owed, 0) as fees_owed,
          e.grade_level as grade
        FROM students s
        LEFT JOIN enrollments e ON e.student_id = s.id AND e.is_active = 1
        WHERE s.school_id = ?
          AND COALESCE(s.fees_owed, 0) > 0
        ORDER BY COALESCE(s.fees_owed, 0) DESC
        LIMIT ?
        ''',
        [schoolId, limit],
      );

      return result.map((row) {
        return {
          'id': row['id']?.toString() ?? '',
          'name': (row['name'] ?? 'Unknown').toString(),
          'grade': row['grade']?.toString() ?? '—',
          'amount': (row['fees_owed'] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching outstanding students: $e");
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentPayments(
    String schoolId, {
    int limit = 10,
    DateTime? onDate,
  }) async {
    try {
      final dateFilter = onDate != null ? "AND substr(p.received_at, 1, 10) = ?" : "";
      final params = <Object?>[schoolId];
      if (onDate != null) {
        final dateStr = onDate.toIso8601String().substring(0, 10);
        params.add(dateStr);
      }
      params.add(limit);

      final result = await db.getAll(
        '''
        SELECT
          p.id,
          p.student_id,
          p.amount,
          p.method,
          p.received_at,
          s.first_name || ' ' || s.last_name as name
        FROM payments p
        LEFT JOIN students s ON p.student_id = s.id
        WHERE p.school_id = ?
        $dateFilter
        ORDER BY datetime(p.received_at) DESC
        LIMIT ?
        ''',
        params,
      );

      return result.map((row) {
        final receivedAt = DateTime.tryParse((row['received_at'] as String?) ?? '') ?? DateTime.now();
        return {
          'id': row['id']?.toString() ?? '',
          'studentId': row['student_id']?.toString() ?? '',
          'name': (row['name'] ?? 'Unknown').toString(),
          'amount': (row['amount'] as num?)?.toDouble() ?? 0.0,
          'method': (row['method'] ?? '—').toString(),
          'time': _formatTime(receivedAt),
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching recent payments: $e");
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
  Future<Map<String, dynamic>> getFinanceStats(String schoolId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final hasRange = startDate != null && endDate != null;
      final revenueSql = hasRange
          ? """
            SELECT SUM(amount) as total
            FROM ledger
            WHERE school_id = ?
              AND type = 'CREDIT'
              AND datetime(occurred_at) >= datetime(?)
              AND datetime(occurred_at) <= datetime(?)
          """
          : "SELECT SUM(amount) as total FROM ledger WHERE school_id = ? AND type = 'CREDIT'";
      final revenueParams = hasRange
          ? [
              schoolId,
              startDate.toUtc().toIso8601String(),
              endDate.toUtc().toIso8601String(),
            ]
          : [schoolId];

      final revenueResult = await db.getOptional(revenueSql, revenueParams);
      final totalRevenue = (revenueResult?['total'] as num?)?.toDouble() ?? 0.0;

      final pendingResult = await db.getOptional(
        '''
        SELECT SUM(ii.amount * COALESCE(ii.quantity, 1)) as total 
        FROM invoices i
        JOIN invoice_items ii ON i.id = ii.invoice_id
        WHERE i.school_id = ? AND i.status != 'PAID'
        ''',
        [schoolId],
      );
      final pendingAmount =
          (pendingResult?['total'] as num?)?.toDouble() ?? 0.0;

      final countResult = await db.getOptional(
        "SELECT COUNT(*) as count FROM invoices WHERE school_id = ? AND status != 'PAID'",
        [schoolId],
      );
      final unpaidInvoiceCount = (countResult?['count'] as int?) ?? 0;

      return {
        'totalRevenue': totalRevenue,
        'pendingAmount': pendingAmount,
        'unpaidInvoiceCount': unpaidInvoiceCount,
      };
    } catch (e) {
      debugPrint("Error fetching finance stats: $e");
      rethrow;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}';
  }

  @override
  Future<void> addInvoiceItem(String invoiceId, InvoiceItem item) async {
    try {
      await db.execute('BEGIN');

      final invoiceRow = await db.getOptional(
        '''
        SELECT id, school_id, student_id, total_amount
        FROM invoices
        WHERE id = ?
        ''',
        [invoiceId],
      );
      if (invoiceRow == null) {
        throw Exception("Invoice not found for item insert.");
      }

      final qty = item.quantity <= 0 ? 1 : item.quantity;
      final lineTotal = item.amount * qty;

      await db.execute(
        '''
        INSERT INTO invoice_items (
          id, school_id, invoice_id, fee_structure_id,
          description, amount, quantity, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          item.id,
          item.schoolId,
          item.invoiceId,
          item.feeStructureId,
          item.description,
          item.amount,
          qty,
          DateTime.now().toIso8601String(),
        ],
      );

      await db.execute(
        '''
        UPDATE invoices
        SET total_amount = COALESCE(total_amount, 0) + ?
        WHERE id = ?
        ''',
        [lineTotal, invoiceId],
      );

      await db.execute(
        '''
        UPDATE students
        SET fees_owed = COALESCE(fees_owed, 0) + ?
        WHERE id = ? AND school_id = ?
        ''',
        [lineTotal, invoiceRow['student_id'], invoiceRow['school_id']],
      );

      await db.execute('COMMIT');
    } catch (e) {
      try {
        await db.execute('ROLLBACK');
      } catch (_) {}
      rethrow;
    }
  }
}
