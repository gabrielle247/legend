class AppRoutes {
  // Auth & Legal
  static const login = '/login';
  static const signup = '/signup';
  static const resetPassword = '/reset-password';
  static const tos = '/tos';
  static const offlineSetup = '/offline-setup';

  // Shell roots
  static const dashboard = '/dashboard';
  static const students = '/students';
  static const finance = '/finance';
  static const settings = '/settings';

  // Dashboard children
  static const notifications = 'notifications';
  static const notificationDetail = 'notifications/detail';
  static const statistics = 'statistics';

  // Student children
  static const addStudent = 'add';
  static const viewStudent = 'view/:studentId';
  static const studentLogs = 'logs/:studentId';

  // Finance children
  static const createInvoice = 'invoice/new';
  static const viewInvoice = 'invoice/:invoiceId';
  static const recordPayment = 'payment/new';
  static const loggingPayments = 'payment/log/:studentId'; // <-- include this

  // Settings children
  static const contactDev = 'contact-dev';
}
