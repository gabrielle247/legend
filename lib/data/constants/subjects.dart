// File: lib/models/subjects.dart

class ZimsecSubject {
  static const Map<int, String> _codeMap = {
    // --- FORM 1 - 4 (O-LEVEL) CORE ---
    // These are the "Must-Haves" for almost every student.
    4005: 'English Language',
    4004: 'Mathematics',
    4003: 'Combined Science', // Replaces Integrated Science
    4006: 'Heritage Studies',
    4007: 'Shona',
    4068: 'Ndebele',
    4001: 'Agriculture',

    // --- FORM 1 - 4 (O-LEVEL) POPULAR ELECTIVES ---
    // Commercials & Arts
    4049: 'Commerce',
    4037: 'Geography',
    4044: 'History',
    4047: 'Family & Religious Studies', // F.R.S (formerly Divinity/R.E)
    4048: 'Business Enterprise Skills',
    4051: 'Principles of Accounting',

    // Sciences & Tech
    4029: 'Computer Science',
    4025: 'Biology',
    4023: 'Physics',
    4024:
        'Chemistry', // Often listed as 5070/5071 in older systems, but 4024 in new curriculum maps
    4059: 'Wood Technology and Design',

    // --- FORM 5 - 6 (A-LEVEL) ---
    // Commercials
    6001: 'Accounting (A-Level)',
    6025: 'Business Studies',
    6073: 'Economics',

    // Arts / Humanities
    6022: 'Geography (A-Level)',
    6006: 'History (A-Level)',
    6003: 'Divinity',
    6009: 'Literature in English',
    6081: 'Heritage Studies (A-Level)',

    // Sciences
    6042: 'Pure Mathematics',
    6030: 'Biology (A-Level)',
    6031: 'Chemistry (A-Level)',
    6032: 'Physics (A-Level)',
    6046: 'Statistics',
    6008: 'Computer Science (A-Level)',
  };

  // This is the getter your Registration Page is looking for:
  static List<String> get allNames => _codeMap.values.toList();

  static String nameFromCode(int code) => _codeMap[code] ?? 'Unknown';
}

class EnrolledSubject {
  final String subjectName;
  final String studentId;

  EnrolledSubject({required this.subjectName, required this.studentId});

  Map<String, dynamic> toJson() => {
    'subjectName': subjectName,
    'studentId': studentId,
  };

  factory EnrolledSubject.fromJson(Map<String, dynamic> json) {
    return EnrolledSubject(
      subjectName: json['subjectName'],
      studentId: json['studentId'],
    );
  }
}
