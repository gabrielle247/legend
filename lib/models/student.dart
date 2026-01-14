// lib/models/student_models.dart

import 'package:legend/models/student_status.dart';
import 'package:legend/models/student_type.dart';

class Student {
  final String id;
  final String schoolId;
  final String firstName;
  final String lastName;
  final String? admissionNumber;
  final String? gender; // 'M' or 'F'
  final DateTime? dob;
  
  // Status & Type
  final StudentStatus status;
  final StudentType type;

  // Guardian Info (Denormalized for Pro Schema Efficiency)
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianEmail;
  final String? guardianRelationship;

  // Cached Financials (Quick access without joining ledger)
  final double feesOwed;

  // Audit
  final DateTime? createdAt;

  Student({
    required this.id,
    required this.schoolId,
    required this.firstName,
    required this.lastName,
    this.admissionNumber,
    this.gender,
    this.dob,
    this.status = StudentStatus.active,
    this.type = StudentType.academy,
    this.guardianName,
    this.guardianPhone,
    this.guardianEmail,
    this.guardianRelationship,
    this.feesOwed = 0.0,
    this.createdAt,
  });

  String get fullName => "$firstName $lastName";

  /// Factory to parse from PowerSync/SQLite Row
  factory Student.fromRow(Map<String, dynamic> row) {
    return Student(
      id: row['id'] as String,
      schoolId: row['school_id'] as String,
      firstName: row['first_name'] as String,
      lastName: row['last_name'] as String,
      admissionNumber: row['admission_number'] as String?,
      gender: row['gender'] as String?,
      dob: row['dob'] != null ? DateTime.tryParse(row['dob']) : null,
      status: _parseStatus(row['status']),
      type: _parseType(row['student_type']),
      guardianName: row['guardian_name'] as String?,
      guardianPhone: row['guardian_phone'] as String?,
      guardianEmail: row['guardian_email'] as String?,
      guardianRelationship: row['guardian_relationship'] as String?,
      feesOwed: (row['fees_owed'] as num?)?.toDouble() ?? 0.0,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at']) : null,
    );
  }

  /// Convert to Map for Saving
  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'school_id': schoolId,
      'first_name': firstName,
      'last_name': lastName,
      'admission_number': admissionNumber,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'status': status.name.toUpperCase(),
      'student_type': type.name.toUpperCase(),
      'guardian_name': guardianName,
      'guardian_phone': guardianPhone,
      'guardian_email': guardianEmail,
      'guardian_relationship': guardianRelationship,
      // 'fees_owed' is usually calculated or updated via triggers, not direct UI edit
    };
  }

  static StudentStatus _parseStatus(String? val) {
    switch (val?.toUpperCase()) {
      case 'SUSPENDED': return StudentStatus.suspended;
      case 'ALUMNI': return StudentStatus.alumni;
      case 'ARCHIVED': return StudentStatus.archived;
      default: return StudentStatus.active;
    }
  }

  static StudentType _parseType(String? val) {
    return val?.toUpperCase() == 'PRIVATE' ? StudentType.private : StudentType.academy;
  }

  void operator [](String other) {}
}
