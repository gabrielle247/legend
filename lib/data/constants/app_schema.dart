import 'package:powersync/powersync.dart';

final schema = Schema([
  // ---------------------------------------------------------------------------
  // 1. SYSTEM & CONFIGURATION
  // ---------------------------------------------------------------------------
  Table('config', [
    Column.text('school_name'),
    Column.text('address'),
    Column.text('currency'),
    Column.text('logo_url'),
    Column.text('owner_id'),
    Column.text('created_at'),
  ]),

  Table('dev', [
    Column.text('school_id'),
    Column.text('section'),
    Column.text('content'),
    Column.text('payload'),
    Column.integer('is_secret'),
    Column.text('created_at'),
  ], indexes: [
    Index('idx_dev_school', [IndexedColumn('school_id')]),
  ]),

  Table('noti', [
    Column.text('school_id'),
    Column.text('user_id'),
    Column.text('title'),
    Column.text('message'),
    Column.text('type'),
    Column.integer('is_read'),
    Column.text('metadata'),
    Column.text('created_at'),
  ], indexes: [
    Index('idx_noti_school', [IndexedColumn('school_id')]),
    Index('idx_noti_user', [IndexedColumn('user_id')]),
  ]),

  // ---------------------------------------------------------------------------
  // 2. CORE ACADEMIC STRUCTURE
  // ---------------------------------------------------------------------------
  Table('academic_years', [
    Column.text('school_id'),
    Column.text('name'),
    Column.text('start_date'),
    Column.text('end_date'),
    Column.integer('is_active'),
    Column.integer('is_locked'),
    Column.text('created_at'),
  ], indexes: [
    Index('idx_years_school', [IndexedColumn('school_id')]),
  ]),

  Table('terms', [
    Column.text('school_id'),
    Column.text('academic_year_id'),
    Column.text('name'),
    Column.text('start_date'),
    Column.text('end_date'),
    Column.integer('is_active'),
  ], indexes: [
    Index('idx_terms_school', [IndexedColumn('school_id')]),
    Index('idx_terms_year', [IndexedColumn('academic_year_id')]),
  ]),

  Table('grades', [
    Column.text('school_id'),
    Column.text('name'),
    Column.integer('level_index'),
    Column.text('created_at'),
  ], indexes: [
    Index('idx_grades_school', [IndexedColumn('school_id')]),
  ]),

  Table('classes', [
    Column.text('school_id'),
    Column.text('grade_id'),
    Column.text('name'),
    Column.text('teacher_id'),
    Column.text('created_at'),
  ], indexes: [
    Index('idx_classes_school', [IndexedColumn('school_id')]),
    Index('idx_classes_grade', [IndexedColumn('grade_id')]),
  ]),

  // ---------------------------------------------------------------------------
  // 3. FINANCE CONFIGURATION
  // ---------------------------------------------------------------------------
  Table('fee_categories', [
    Column.text('school_id'),
    Column.text('name'),
    Column.integer('is_taxable'),
    Column.text('created_at'),
  ], indexes: [
    Index('idx_feecat_school', [IndexedColumn('school_id')]),
  ]),

  Table('fee_structures', [
    Column.text('school_id'),
    Column.text('academic_year_id'),
    Column.text('category_id'),
    Column.text('name'),
    Column.real('amount'),
    Column.text('billing_type'),
    Column.text('recurrence'),
    Column.text('billable_months'),
    Column.text('target_grade'),
    Column.text('created_at'),
  ], indexes: [
    Index('idx_feestruct_school', [IndexedColumn('school_id')]),
    Index('idx_feestruct_year', [IndexedColumn('academic_year_id')]),
  ]),

  // ---------------------------------------------------------------------------
  // 4. PEOPLE (Students & Staff)
  // ---------------------------------------------------------------------------
  Table('profiles', [
    Column.text('school_id'),
    Column.text('full_name'),
    Column.text('role'),
    Column.integer('is_banned'),
    Column.text('created_at'),
  ], indexes: [
    Index('idx_profiles_school', [IndexedColumn('school_id')]),
  ]),

  Table('students', [
    Column.text('school_id'),
    Column.text('first_name'),
    Column.text('last_name'),
    Column.text('admission_number'),
    Column.text('gender'),
    Column.text('status'),
    Column.text('student_type'),
    
    // ✅ ADDED: This was missing and caused the mismatch!
    Column.text('billing_cycle'), 
    
    Column.text('guardian_name'),
    Column.text('guardian_phone'),
    Column.text('guardian_email'),
    Column.text('guardian_relationship'),
    Column.real('fees_owed'),
    Column.text('created_at'),
  ], indexes: [
    Index('idx_students_school', [IndexedColumn('school_id')]),
    Index('idx_students_admnum', [IndexedColumn('admission_number')]),
  ]),

  Table('enrollments', [
    Column.text('school_id'),
    Column.text('student_id'),
    Column.text('academic_year_id'),
    Column.text('grade_level'), 
    Column.text('class_stream'),
    Column.text('class_id'),
    Column.text('enrollment_date'),
    Column.text('subjects'),    // JSON String
    Column.integer('is_active'),
    Column.text('created_at'),
  ], indexes: [
    Index('idx_enroll_school', [IndexedColumn('school_id')]),
    Index('idx_enroll_student', [IndexedColumn('student_id')]),
    Index('idx_enroll_class', [IndexedColumn('class_id')]),
  ]),

  // ---------------------------------------------------------------------------
  // 5. BILLING & TRANSACTIONS
  // ---------------------------------------------------------------------------
  Table('invoices', [
    Column.text('school_id'),
    Column.text('student_id'),
    Column.text('invoice_number'),
    Column.text('term_id'),
    Column.text('due_date'),
    Column.text('status'),
    Column.text('snapshot_grade'),
    Column.real('total_amount'), 
    Column.real('paid_amount'),
    Column.text('title'), 
    Column.text('created_at'),
  ], indexes: [
    Index('idx_invoices_school', [IndexedColumn('school_id')]),
    Index('idx_invoices_student', [IndexedColumn('student_id')]),
    Index('idx_invoices_status', [IndexedColumn('status')]),
  ]),

  Table('invoice_items', [
    Column.text('school_id'),
    Column.text('invoice_id'),
    Column.text('fee_structure_id'),
    Column.text('description'),
    Column.real('amount'),
    Column.integer('quantity'),
    Column.text('created_at'),
  ], indexes: [
    Index('idx_invitems_invoice', [IndexedColumn('invoice_id')]),
  ]),

  Table('payments', [
    Column.text('school_id'),
    Column.text('student_id'),
    Column.real('amount'),
    Column.text('method'),
    Column.text('reference_code'),
    Column.text('received_at'),
  ], indexes: [
    Index('idx_payments_school', [IndexedColumn('school_id')]),
    Index('idx_payments_student', [IndexedColumn('student_id')]),
  ]),

  Table('payment_allocations', [
    Column.text('school_id'),
    Column.text('payment_id'),
    Column.text('invoice_item_id'),
    Column.real('amount_allocated'),
    Column.text('created_at'),
  ], indexes: [
    Index('idx_payalloc_payment', [IndexedColumn('payment_id')]),
    Index('idx_payalloc_invitem', [IndexedColumn('invoice_item_id')]),
  ]),

  Table('ledger', [
    Column.text('school_id'),
    Column.text('student_id'),
    Column.text('type'),
    Column.text('category'),
    Column.real('amount'),
    Column.text('invoice_id'),
    Column.text('payment_id'),
    Column.text('description'),
    Column.text('occurred_at'),
  ], indexes: [
    Index('idx_ledger_school', [IndexedColumn('school_id')]),
    Index('idx_ledger_student', [IndexedColumn('student_id')]),
  ]),
]);