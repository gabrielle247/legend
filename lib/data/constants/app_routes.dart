class AppRoutes {
  // Auth & Legal
  static const login = '/login';
  static const signup = '/signup';
  static const resetPassword = '/reset-password';
  static const tos = '/tos';
  static const profileSetup = '/profile-setup';
  static const createSchool = '/create-school';
  static const splash = '/';

  // Shell roots
  static const dashboard = '/dashboard';
  static const students = '/students';
  static const finance = '/finance';
  static const settings = '/settings';

  // Dashboard children
  static const notifications = 'notifications';
  static const notificationDetail = 'notifications/detail';
  static const statistics = 'statistics';
  static const outstanding = 'outstanding';
  static const received = 'received';
  static const activity = 'activity';

  // Student children
  static const addStudent = 'add';
  static const viewStudent = 'view/:studentId';
  static const studentLogs = 'logs/:studentId';
  static const studentInvoices = 'invoices/:studentId';

  // Finance children
  static const createInvoice = 'invoice/new';
  static const viewInvoice = 'invoice/:invoiceId';
  static const recordPayment = 'payment/new';
  static const loggingPayments = 'payment/log/:studentId'; // <-- include this

  // Settings children
  static const contactDev = 'contact-dev';
  static const academicPeriods = 'academic-periods';
}
