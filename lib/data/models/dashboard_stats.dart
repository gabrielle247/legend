// lib/models/screen_models.dart

/// Dashboard Statistics (Aggregated).
class DashboardStats {
  final int totalStudents;
  final double totalOwed;
  final double collectedToday;
  final int pendingInvoices;

  DashboardStats({
    this.totalStudents = 0,
    this.totalOwed = 0.0,
    this.collectedToday = 0.0,
    this.pendingInvoices = 0,
  });
}
