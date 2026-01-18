import 'package:flutter_test/flutter_test.dart';
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/services/billing/billing_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const schoolId = 'school-1';

  group('BillingEngine monthly simulation (mocked)', () {
    late FakeBillingDataSource source;
    late BillingEngine engine;

    setUp(() {
      source = FakeBillingDataSource(
        activeTerm: Term(
          id: 'term-1',
          schoolId: schoolId,
          academicYearId: 'year-1',
          name: 'Term 1',
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 3, 31),
          isActive: true,
        ),
        activeYear: BillingAcademicYear(
          id: 'year-1',
          schoolId: schoolId,
          name: '2025',
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 12, 31),
        ),
        students: [
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
    });

    test('creates invoices as months pass', () async {
      await engine.runForSchoolAt(schoolId, DateTime(2025, 2, 6));

      expect(source.invoiceCountForStudent('student-fixed'), 2);
      expect(source.invoiceCountForStudent('student-custom'), 1);

      await engine.runForSchoolAt(schoolId, DateTime(2025, 3, 20));

      expect(source.invoiceCountForStudent('student-fixed'), 3);
      expect(source.invoiceCountForStudent('student-custom'), 3);
    });
  });
}

class FakeBillingDataSource implements BillingDataSource {
  FakeBillingDataSource({
    required this.activeTerm,
    required this.activeYear,
    required this.students,
  });

  final Term? activeTerm;
  final BillingAcademicYear? activeYear;
  final List<BillingStudentRow> students;
  final Map<String, Invoice> invoicesById = {};
  final Map<String, List<InvoiceItem>> itemsByInvoiceId = {};
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
    invoiceIdByKey[_invoiceKey(invoice.schoolId, invoice.studentId, invoice.title!)] = invoice.id;
  }

  int invoiceCountForStudent(String studentId) {
    return invoicesById.values.where((invoice) => invoice.studentId == studentId).length;
  }

  String _invoiceKey(String schoolId, String studentId, String title) {
    return '$schoolId|$studentId|$title';
  }
}
