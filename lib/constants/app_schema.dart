import 'package:powersync/powersync.dart';

/// The Official Offline-First Schema for KwaLegend
/// Matches the 'legend' schema in Supabase exactly.
final schema = Schema([
  // ---------------------------------------------------------------------------
  // 1. CORE ACADEMIC CONFIGURATION
  // ---------------------------------------------------------------------------
  Table('academic_years', [
    Column.text('name'),
    Column.text('start_date'),
    Column.text('end_date'),
    Column.integer('is_active'), // 0 or 1
    Column.integer('is_locked'), // 0 or 1
    Column.text('school_id'),
    Column.text('created_at'),
  ]),

  Table('terms', [
    Column.text('academic_year_id'),
    Column.text('name'),
    Column.text('start_date'),
    Column.text('end_date'),
    Column.integer('is_active'),
    Column.text('school_id'),
  ]),

  Table('grades', [
    Column.text('name'),
    Column.integer('level_index'),
    Column.text('school_id'),
    Column.text('created_at'),
  ]),

  Table('classes', [
    Column.text('school_id'),
    Column.text('grade_id'),
    Column.text('name'),
    Column.text('teacher_id'), // Link to profiles
    Column.text('created_at'),
  ]),

  Table('fee_categories', [
    Column.text('name'),
    Column.integer('is_taxable'),
    Column.text('school_id'),
    Column.text('created_at'),
  ]),

  Table('fee_structures', [
    Column.text('academic_year_id'),
    Column.text('category_id'),
    Column.text('name'),
    Column.real('amount'),
    Column.text('billing_type'), // tuition, exam, etc.
    Column.text('recurrence'),   // termly, monthly
    Column.text('billable_months'), // stored as JSON string or comma-separated
    Column.text('target_grade'),
    Column.text('school_id'),
    Column.text('created_at'),
  ]),

  // ---------------------------------------------------------------------------
  // 2. PEOPLE (Students & Staff)
  // ---------------------------------------------------------------------------
  Table('profiles', [
    Column.text('full_name'),
    Column.text('role'),
    Column.integer('is_banned'),
    Column.text('school_id'),
    Column.text('created_at'),
  ]),

  Table('students', [
    Column.text('first_name'),
    Column.text('last_name'),
    Column.text('admission_number'),
    Column.text('gender'),
    Column.text('status'),       // ACTIVE, ARREARS
    Column.text('student_type'), // ACADEMY, PRIVATE
    Column.text('guardian_name'),
    Column.text('guardian_phone'),
    Column.text('guardian_email'),
    Column.text('guardian_relationship'),
    Column.real('fees_owed'),
    Column.text('school_id'),
    Column.text('created_at'),
  ]),

  Table('enrollments', [
    Column.text('student_id'),
    Column.text('academic_year_id'),
    Column.text('grade_level'),
    Column.text('class_stream'),
    Column.integer('is_active'),
    Column.text('school_id'),
    Column.text('created_at'),
  ]),

  // ---------------------------------------------------------------------------
  // 3. FINANCE & BILLING
  // ---------------------------------------------------------------------------
  Table('invoices', [
    Column.text('student_id'),
    Column.text('invoice_number'),
    Column.text('term_id'),
    Column.text('due_date'),
    Column.text('status'), // DRAFT, POSTED, PAID, VOID
    Column.text('snapshot_grade'),
    Column.text('school_id'),
    Column.text('created_at'),
  ]),

  Table('invoice_items', [
    Column.text('invoice_id'),
    Column.text('fee_structure_id'),
    Column.text('description'),
    Column.real('amount'),
    Column.integer('quantity'),
    Column.text('school_id'),
    Column.text('created_at'),
  ]),

  Table('payments', [
    Column.text('student_id'),
    Column.real('amount'),
    Column.text('method'),
    Column.text('reference_code'),
    Column.text('received_at'),
    Column.text('school_id'),
  ]),

  Table('payment_allocations', [
    Column.text('payment_id'),
    Column.text('invoice_item_id'),
    Column.real('amount_allocated'),
    Column.text('school_id'),
    Column.text('created_at'),
  ]),

  Table('ledger', [
    Column.text('student_id'),
    Column.text('type'), // DEBIT, CREDIT
    Column.text('category'),
    Column.real('amount'),
    Column.text('invoice_id'),
    Column.text('payment_id'),
    Column.text('description'),
    Column.text('occurred_at'),
    Column.text('school_id'),
  ]),

  // ---------------------------------------------------------------------------
  // 4. SYSTEM & UTILITY
  // ---------------------------------------------------------------------------
  Table('config', [
    Column.text('school_name'),
    Column.text('address'),
    Column.text('currency'),
    Column.text('logo_url'),
    Column.text('owner_id'),
    Column.text('created_at'),
  ]),

  Table('noti', [
    Column.text('school_id'),
    Column.text('user_id'),
    Column.text('title'),
    Column.text('message'),
    Column.text('type'),
    Column.integer('is_read'),
    Column.text('metadata'), // JSON String
    Column.text('created_at'),
  ]),
  
  // Dev table excluded for safety unless explicitly requested
]);