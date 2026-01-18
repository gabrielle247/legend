import 'package:flutter_test/flutter_test.dart';
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/services/billing/billing_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const schoolId = 'school-1';

  group('BillingEngine Comprehensive Simulation', () {
    late FakeBillingDataSource source;
    late BillingEngine engine;

    // Helper to quick-setup specific scenarios
    void setupEngine({
      DateTime? termEnd,
      List<BillingStudentRow>? customStudents,
    }) {
      source = FakeBillingDataSource(
        activeTerm: Term(
          id: 'term-1',
          schoolId: schoolId,
          academicYearId: 'year-1',
          name: 'Term 1',
          startDate: DateTime(2025, 1, 1),
          // Default to March 31st, allows override for boundary tests
          endDate: termEnd ?? DateTime(2025, 3, 31),
          isActive: true,
        ),
        activeYear: BillingAcademicYear(
          id: 'year-1',
          schoolId: schoolId,
          name: '2025',
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 12, 31),
        ),
        students: customStudents ??
            [
              BillingStudentRow(
                studentId: 'student-fixed',
                schoolId: schoolId,
                billingCycle: 'MONTHLY_FIXED',
                enrollmentId: 'enroll-fixed',
                enrollmentDate: DateTime(2025, 1, 1),
                tuitionAmount: 150.0,
                gradeLevel: 'Grade 1',
              ),
              BillingStudentRow(
                studentId: 'student-custom',
                schoolId: schoolId,
                billingCycle: 'MONTHLY_CUSTOM',
                enrollmentId: 'enroll-custom',
                enrollmentDate: DateTime(2025, 1, 15),
                tuitionAmount: 150.0,
                gradeLevel: 'Grade 2',
              ),
            ],
      );
      engine = BillingEngine.withDataSource(source);
    }

    setUp(() {
      setupEngine();
    });

    test('Standard Flow: Creates invoices incrementally as months pass', () async {
      // Run for Feb 6 -> Expect Jan & Feb invoices
      await engine.runForSchoolAt(schoolId, DateTime(2025, 2, 6));

      // Fixed: Jan 1, Feb 1
      expect(source.invoiceCountForStudent('student-fixed'), 2, reason: 'Fixed should have Jan & Feb');
      // Custom: Jan 15 (Feb 15 hasn't happened yet)
      expect(source.invoiceCountForStudent('student-custom'), 1, reason: 'Custom should only have Jan (Feb 15 pending)');

      // Fast forward to March 20
      await engine.runForSchoolAt(schoolId, DateTime(2025, 3, 20));

      // Fixed: Jan 1, Feb 1, Mar 1
      expect(source.invoiceCountForStudent('student-fixed'), 3);
      // Custom: Jan 15, Feb 15, Mar 15
      expect(source.invoiceCountForStudent('student-custom'), 3);
    });

    test('Idempotency: Running same day multiple times does NOT duplicate invoices', () async {
      final runDate = DateTime(2025, 2, 1);

      // First Run
      await engine.runForSchoolAt(schoolId, runDate);
      final countAfterFirstRun = source.invoiceCountForStudent('student-fixed');
      expect(countAfterFirstRun, 2); // Jan & Feb

      // Second Run (Same instant)
      await engine.runForSchoolAt(schoolId, runDate);
      expect(source.invoiceCountForStudent('student-fixed'), countAfterFirstRun,
          reason: 'Duplicate run should not create new invoices');
    });

    test('Catch-Up Logic: Engine handles long gaps (Server Down Scenario)', () async {
      // System was "down" for Jan and Feb. First run is March 10.
      // Should generate Jan, Feb, and March all at once.
      await engine.runForSchoolAt(schoolId, DateTime(2025, 3, 10));

      expect(source.invoiceCountForStudent('student-fixed'), 3,
          reason: 'Engine should back-fill Jan, Feb, and Mar invoices in one go');
    });

    test('Term Boundaries: Does NOT bill past the Term End Date', () async {
      // Setup a term that ends Feb 28th
      setupEngine(termEnd: DateTime(2025, 2, 28));

      // Attempt to run for April 15th
      await engine.runForSchoolAt(schoolId, DateTime(2025, 4, 15));

      // Should only have Jan and Feb. March and April are outside the active term.
      expect(source.invoiceCountForStudent('student-fixed'), 2,
          reason: 'Should stop billing when Term 1 ends (Feb 28)');
    });

    test('Mid-Month Enrollment (Fixed Cycle): Pro-rating or Full Charge check', () async {
      // Testing specific behavior for a student joining late in the month on a FIXED cycle
      setupEngine(customStudents: [
        BillingStudentRow(
          studentId: 'late-joiner',
          schoolId: schoolId,
          billingCycle: 'MONTHLY_FIXED', // Cycle is 1st of month
          enrollmentId: 'enroll-late',
          enrollmentDate: DateTime(2025, 1, 20), // Joins Jan 20
          tuitionAmount: 100.0,
          gradeLevel: 'Grade 1',
        )
      ]);

      // Run on Jan 25
      await engine.runForSchoolAt(schoolId, DateTime(2025, 1, 25));

      // Depending on business logic, this usually triggers the Jan invoice immediately
      expect(source.invoiceCountForStudent('late-joiner'), 1,
          reason: 'Should generate invoice for the month they joined in, even if joined late');
    });

    test('Billing Cycle Alignment: Custom Cycle respects enrollment day', () async {
      // Custom cycle student joined Jan 15.
      // Run on Feb 10.
      await engine.runForSchoolAt(schoolId, DateTime(2025, 2, 10));

      // Should have Jan 15 invoice.
      // Should NOT have Feb 15 invoice yet.
      expect(source.invoiceCountForStudent('student-custom'), 1);

      // Run on Feb 15
      await engine.runForSchoolAt(schoolId, DateTime(2025, 2, 15));
      expect(source.invoiceCountForStudent('student-custom'), 2,
          reason: 'Feb 15 is the trigger date for the second invoice');
    });
  });
}

// -----------------------------------------------------------------------------
// MOCK DATA SOURCE
// -----------------------------------------------------------------------------

class FakeBillingDataSource implements BillingDataSource {
  FakeBillingDataSource({
    required this.activeTerm,
    required this.activeYear,
    required this.students,
  });

  final Term? activeTerm;
  final BillingAcademicYear? activeYear;
  final List<BillingStudentRow> students;

  // In-memory stores
  final Map<String, Invoice> invoicesById = {};
  final Map<String, List<InvoiceItem>> itemsByInvoiceId = {};
  
  // Key to prevent duplicates: schoolId|studentId|title
  final Map<String, String> invoiceIdByKey = {};

  @override
  Future<Term?> getActiveTerm(String schoolId) async => activeTerm;

  @override
  Future<BillingAcademicYear?> getActiveYear(String schoolId) async => activeYear;

  @override
  Future<List<BillingStudentRow>> loadActiveStudents(String schoolId) async => students;

  @override
  Future<String?> findInvoiceId(String schoolId, String studentId, String title) async {
    return invoiceIdByKey[_invoiceKey(schoolId, studentId, title)];
  }

  @override
  Future<bool> invoiceHasItem(String invoiceId, String description) async {
    final items = itemsByInvoiceId[invoiceId] ?? [];
    return items.any((item) => item.description == description);
  }

  @override
  Future<void> addInvoiceItem(InvoiceItem item) async {
    itemsByInvoiceId.putIfAbsent(item.invoiceId, () => []).add(item);
  }

  @override
  Future<void> createInvoice(Invoice invoice, List<InvoiceItem> items) async {
    invoicesById[invoice.id] = invoice;
    itemsByInvoiceId.putIfAbsent(invoice.id, () => []).addAll(items);
    
    // Store key mapping for idempotency checks
    invoiceIdByKey[_invoiceKey(invoice.schoolId, invoice.studentId, invoice.title!)] = invoice.id;
  }

  // --- Test Helpers ---

  int invoiceCountForStudent(String studentId) {
    return invoicesById.values.where((invoice) => invoice.studentId == studentId).length;
  }

  String _invoiceKey(String schoolId, String studentId, String title) {
    return '$schoolId|$studentId|$title';
  }
}