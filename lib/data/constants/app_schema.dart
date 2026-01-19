import 'package:powersync/powersync.dart' as ps;

final schema = ps.Schema([
  // ---------------------------------------------------------------------------
  // 1. SYSTEM & CONFIGURATION
  // ---------------------------------------------------------------------------
  ps.Table('config', [
    ps.Column.text('school_name'),
    ps.Column.text('address'),
    ps.Column.text('currency'),
    ps.Column.text('logo_url'),
    ps.Column.text('owner_id'),
    ps.Column.text('created_at'),
  ]),

  ps.Table('dev', [
    ps.Column.text('school_id'),
    ps.Column.text('section'),
    ps.Column.text('content'),
    ps.Column.text('payload'),
    ps.Column.integer('is_secret'),
    ps.Column.text('created_at'),
  ], indexes: [
    ps.Index('idx_dev_school', [ps.IndexedColumn('school_id')]),
  ]),

  ps.Table('noti', [
    ps.Column.text('school_id'),
    ps.Column.text('user_id'),
    ps.Column.text('title'),
    ps.Column.text('message'),
    ps.Column.text('type'),
    ps.Column.integer('is_read'),
    ps.Column.text('metadata'),
    ps.Column.text('created_at'),
  ], indexes: [
    ps.Index('idx_noti_school', [ps.IndexedColumn('school_id')]),
    ps.Index('idx_noti_user', [ps.IndexedColumn('user_id')]),
  ]),

  // ---------------------------------------------------------------------------
  // 2. CORE ACADEMIC STRUCTURE
  // ---------------------------------------------------------------------------
  ps.Table('academic_years', [
    ps.Column.text('school_id'),
    ps.Column.text('name'),
    ps.Column.text('start_date'),
    ps.Column.text('end_date'),
    ps.Column.integer('is_active'),
    ps.Column.integer('is_locked'),
    ps.Column.text('created_at'),
  ], indexes: [
    ps.Index('idx_years_school', [ps.IndexedColumn('school_id')]),
  ]),

  ps.Table('terms', [
    ps.Column.text('school_id'),
    ps.Column.text('academic_year_id'),
    ps.Column.text('name'),
    ps.Column.text('start_date'),
    ps.Column.text('end_date'),
    ps.Column.integer('is_active'),
  ], indexes: [
    ps.Index('idx_terms_school', [ps.IndexedColumn('school_id')]),
    ps.Index('idx_terms_year', [ps.IndexedColumn('academic_year_id')]),
  ]),

  ps.Table('grades', [
    ps.Column.text('school_id'),
    ps.Column.text('name'),
    ps.Column.integer('level_index'),
    ps.Column.text('created_at'),
  ], indexes: [
    ps.Index('idx_grades_school', [ps.IndexedColumn('school_id')]),
  ]),

  ps.Table('classes', [
    ps.Column.text('school_id'),
    ps.Column.text('grade_id'),
    ps.Column.text('name'),
    ps.Column.text('teacher_id'),
    ps.Column.text('created_at'),
  ], indexes: [
    ps.Index('idx_classes_school', [ps.IndexedColumn('school_id')]),
    ps.Index('idx_classes_grade', [ps.IndexedColumn('grade_id')]),
  ]),

  // ---------------------------------------------------------------------------
  // 3. FINANCE CONFIGURATION
  // ---------------------------------------------------------------------------
  ps.Table('fee_categories', [
    ps.Column.text('school_id'),
    ps.Column.text('name'),
    ps.Column.integer('is_taxable'),
    ps.Column.text('created_at'),
  ], indexes: [
    ps.Index('idx_feecat_school', [ps.IndexedColumn('school_id')]),
  ]),

  ps.Table('fee_structures', [
    ps.Column.text('school_id'),
    ps.Column.text('academic_year_id'),
    ps.Column.text('category_id'),
    ps.Column.text('name'),
    ps.Column.real('amount'),
    ps.Column.text('billing_type'),
    ps.Column.text('recurrence'),
    ps.Column.text('billable_months'),
    ps.Column.text('target_grade'),
    ps.Column.text('created_at'),
  ], indexes: [
    ps.Index('idx_feestruct_school', [ps.IndexedColumn('school_id')]),
    ps.Index('idx_feestruct_year', [ps.IndexedColumn('academic_year_id')]),
  ]),

  // ---------------------------------------------------------------------------
  // 4. PEOPLE (Students & Staff)
  // ---------------------------------------------------------------------------
  ps.Table('profiles', [
    ps.Column.text('school_id'),
    ps.Column.text('full_name'),
    ps.Column.text('role'),
    ps.Column.integer('is_banned'),
    ps.Column.text('created_at'),
  ], indexes: [
    ps.Index('idx_profiles_school', [ps.IndexedColumn('school_id')]),
  ]),

  ps.Table('students', [
    ps.Column.text('school_id'),
    ps.Column.text('first_name'),
    ps.Column.text('last_name'),
    ps.Column.text('admission_number'),
    ps.Column.text('gender'),
    ps.Column.text('status'),
    ps.Column.text('student_type'),
    
    // ✅ ADDED: This was missing and caused the mismatch!
    ps.Column.text('billing_cycle'), 
    
    ps.Column.text('guardian_name'),
    ps.Column.text('guardian_phone'),
    ps.Column.text('guardian_email'),
    ps.Column.text('guardian_relationship'),
    ps.Column.real('fees_owed'),
    ps.Column.text('created_at'),
  ], indexes: [
    ps.Index('idx_students_school', [ps.IndexedColumn('school_id')]),
    ps.Index('idx_students_admnum', [ps.IndexedColumn('admission_number')]),
  ]),

  ps.Table('enrollments', [
    ps.Column.text('school_id'),
    ps.Column.text('student_id'),
    ps.Column.text('academic_year_id'),
    ps.Column.text('grade_level'), 
    ps.Column.text('class_stream'),
    ps.Column.text('class_id'),
    ps.Column.text('enrollment_date'),
    ps.Column.text('subjects'),    // JSON String
    ps.Column.real('tuition_amount'),
    ps.Column.integer('is_active'),
    ps.Column.text('created_at'),
  ], indexes: [
    ps.Index('idx_enroll_school', [ps.IndexedColumn('school_id')]),
    ps.Index('idx_enroll_student', [ps.IndexedColumn('student_id')]),
    ps.Index('idx_enroll_class', [ps.IndexedColumn('class_id')]),
  ]),

  // ---------------------------------------------------------------------------
  // 5. BILLING & TRANSACTIONS
  // ---------------------------------------------------------------------------
  ps.Table('invoices', [
    ps.Column.text('school_id'),
    ps.Column.text('student_id'),
    ps.Column.text('invoice_number'),
    ps.Column.text('term_id'),
    ps.Column.text('due_date'),
    ps.Column.text('status'),
    ps.Column.text('snapshot_grade'),
    ps.Column.real('total_amount'), 
    ps.Column.real('paid_amount'),
    ps.Column.text('title'), 
    ps.Column.text('created_at'),
  ], indexes: [
    ps.Index('idx_invoices_school', [ps.IndexedColumn('school_id')]),
    ps.Index('idx_invoices_student', [ps.IndexedColumn('student_id')]),
    ps.Index('idx_invoices_status', [ps.IndexedColumn('status')]),
  ]),

  ps.Table('invoice_items', [
    ps.Column.text('school_id'),
    ps.Column.text('invoice_id'),
    ps.Column.text('fee_structure_id'),
    ps.Column.text('description'),
    ps.Column.real('amount'),
    ps.Column.integer('quantity'),
    ps.Column.text('created_at'),
  ], indexes: [
    ps.Index('idx_invitems_invoice', [ps.IndexedColumn('invoice_id')]),
  ]),

  ps.Table('payments', [
    ps.Column.text('school_id'),
    ps.Column.text('student_id'),
    ps.Column.real('amount'),
    ps.Column.text('method'),
    ps.Column.text('reference_code'),
    ps.Column.text('received_at'),
  ], indexes: [
    ps.Index('idx_payments_school', [ps.IndexedColumn('school_id')]),
    ps.Index('idx_payments_student', [ps.IndexedColumn('student_id')]),
  ]),

  ps.Table('payment_allocations', [
    ps.Column.text('school_id'),
    ps.Column.text('payment_id'),
    ps.Column.text('invoice_item_id'),
    ps.Column.real('amount_allocated'),
    ps.Column.text('created_at'),
  ], indexes: [
    ps.Index('idx_payalloc_payment', [ps.IndexedColumn('payment_id')]),
    ps.Index('idx_payalloc_invitem', [ps.IndexedColumn('invoice_item_id')]),
  ]),

  ps.Table('ledger', [
    ps.Column.text('school_id'),
    ps.Column.text('student_id'),
    ps.Column.text('type'),
    ps.Column.text('category'),
    ps.Column.real('amount'),
    ps.Column.text('invoice_id'),
    ps.Column.text('payment_id'),
    ps.Column.text('description'),
    ps.Column.text('occurred_at'),
  ], indexes: [
    ps.Index('idx_ledger_school', [ps.IndexedColumn('school_id')]),
    ps.Index('idx_ledger_student', [ps.IndexedColumn('student_id')]),
  ]),
]);
