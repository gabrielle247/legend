import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/student_repo.dart';

class StudentLogsViewModel extends ChangeNotifier {
  final StudentRepository _repo;
  final String studentId;

  List<LogEntry> _logs = [];
  double _totalDebits = 0.0;
  double _totalCredits = 0.0;
  double _balance = 0.0;
  bool _isLoading = true;
  String? _error;

  List<LogEntry> get logs => _logs;
  double get totalDebits => _totalDebits;
  double get totalCredits => _totalCredits;
  double get balance => _balance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StudentLogsViewModel(this._repo, this.studentId);

  Future<void> loadLogs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.getStudentLogs(studentId),
        _repo.getStudentLedgerSummary(studentId),
      ]);

      _logs = results[0] as List<LogEntry>;
      final summary = results[1] as Map<String, double>;
      _totalDebits = summary['debits'] ?? 0.0;
      _totalCredits = summary['credits'] ?? 0.0;
      _balance = summary['balance'] ?? 0.0;
    } catch (e) {
      _error = "Failed to load logs: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadLogs();
}
