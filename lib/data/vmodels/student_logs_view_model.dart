import 'package:flutter/foundation.dart';
import 'package:legend/data/models/all_models.dart';
import 'package:legend/data/repo/student_repo.dart';

class StudentLogsViewModel extends ChangeNotifier {
  final StudentRepository _repo;
  final String studentId;
  
  List<LogEntry> _logs = [];
  bool _isLoading = true;
  String? _error;

  // Getters
  List<LogEntry> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StudentLogsViewModel(this._repo, this.studentId);

  Future<void> loadLogs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logs = await _repo.getStudentLogs(studentId);
    } catch (e) {
      _error = "Failed to load logs: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}