import 'package:legend/models/log_entry.dart';
import 'package:legend/models/log_type.dart';

class StudentLogsViewModel {
  final String studentId;
  List<LogEntry> logs = [];
  bool isLoading = true;

  StudentLogsViewModel(this.studentId);

  Future<void> loadLogs() async {
    // Simulate Network Delay
    await Future.delayed(const Duration(milliseconds: 800));

    final now = DateTime.now();
    
    // MOCK DATA: In production, fetch WHERE student_id = x ORDER BY created_at DESC
    //TODO Make a real view model
    logs = [
      LogEntry(
        id: "1",
        title: "Payment Received",
        description: "Guardian paid \$450.00 via EcoCash (Ref: EC-9982).",
        timestamp: now.subtract(const Duration(minutes: 45)),
        type: LogType.financial,
        performedBy: "System (Auto)",
      ),
      LogEntry(
        id: "2",
        title: "Invoice Generated",
        description: "Term 1 2026 Tuition fees posted (\$600.00).",
        timestamp: now.subtract(const Duration(hours: 3)),
        type: LogType.financial,
        performedBy: "Admin (Sir Legend)",
      ),
      LogEntry(
        id: "3",
        title: "Profile Updated",
        description: "Guardian phone number changed from +263... to +263...",
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        type: LogType.system,
        performedBy: "Admin",
      ),
      LogEntry(
        id: "4",
        title: "Academic Warning",
        description: "Missed 3 consecutive Math assignments.",
        timestamp: now.subtract(const Duration(days: 2)),
        type: LogType.alert,
        performedBy: "Teacher (Mr. Moyo)",
      ),
      LogEntry(
        id: "5",
        title: "Subject Enrollment",
        description: "Added to 'Computer Science' class list.",
        timestamp: now.subtract(const Duration(days: 5)),
        type: LogType.academic,
        performedBy: "Admin",
      ),
      LogEntry(
        id: "6",
        title: "Admission Created",
        description: "Student profile created and set to ACTIVE.",
        timestamp: now.subtract(const Duration(days: 10)),
        type: LogType.system,
        performedBy: "Admin",
      ),
    ];
    
    isLoading = false;
  }
}
