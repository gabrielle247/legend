class PaymentViewModel {
  // Student Context
  final String? studentId;
  String studentName = "Select Student...";
  String grade = "";
  double currentDebt = 0.0;
  
  // Payment Data
  double amount = 0.0;
  String method = "Cash"; // Cash, EcoCash, Bank
  String reference = "";
  DateTime date = DateTime.now();
  String receiptNumber = "RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

  // Logic State
  bool isLoading = false;

  PaymentViewModel({this.studentId});

  Future<void> loadContext() async {
    isLoading = true;
    await Future.delayed(const Duration(milliseconds: 500)); // Sim network
    
    if (studentId != null) {
      // Mock fetch
      studentName = "Nyasha Gabriel";
      grade = "Form 4A";
      currentDebt = 150.00;
    }
    isLoading = false;
  }

  // Smart Allocation: Suggests what this payment covers
  String get allocationPreview {
    if (amount <= 0) return "Pending input...";
    if (amount >= currentDebt && currentDebt > 0) return "Clears Full Balance";
    return "Partially covers Outstanding Balance";
  }
}
