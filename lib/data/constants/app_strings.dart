class AppStrings {
  static const String appName = "KwaLegend Manager";

  // Shell Titles
  static const String dashboardTitle = "Dashboard";
  static const String studentsTitle = "Students";
  static const String financeTitle = "Finance";
  static const String settingsTitle =
      "Profile"; // Combined Settings/Profile for Sir Legend

  // Screen Titles
  static const String statsTitle = "Statistics";
  static const String notificationsTitle = "Notifications";
  static const String invoicesTitle = "Invoices";
  static const String createInvoiceTitle = "New Invoice";
  static const String logsTitle = "Activity Logs";
  static const String tosTitle = "Terms of Service";
  static const String contactDevTitle = "Contact Developer";
  static const String devContactName = "Nyasha Gabriel";
  static const String devContactMessage =
      "Contact the developer when ever the app \nmisbehaves so that data can be preserved \nand a solution can be found";
  static const String devWhatsAppUrl = "https://wa.me/263785930886";
  static const String devEmailUrl = "mailto:gabwixgamesite2024@gmail.com";
  static const String devBuildLabel = "BUILD: KWALEGEND \nALPHA 0.9.2";

  //Rando Strings
  static const String savingSubjects = "Saving Subjects:";

  //Success Messages
  static const String studentRegisterSuccess =
      "Student Registered Successfully";

  static const String newAdmission = "Student Registered Successfully";

  static const String save = "SAVE";
  static const String identity = "Identity";
  static const String fieldFirstName = "First Name";
  static const String fieldLastName = "Last Name";
  static const String required = "Required";

  static const String genderMale = "M";
  static const String genderFemale = "F";
  static const String gender = "Gender";

  static const String studentTypeAcademy = "ACADEMY";
  static const String studentTypePrivate = "PRIVATE";
  static const String studentType = "Student Type";

  static const String placement = "Placement";
  static const String gLevel = "Level";

  static const String gContact = "Guardian Contact";
  static const String gName = "Guardian Name";
  static const String gPhone = "Guardian Phone";

  static const String bEssentials = "Billing Essentials";
  static const String bSchedule = "Billing Schedule";
  static const String selectBDate = "Select Billing Date";
  static const String defaultB = 'Monthly (Custom Date)';
  static const String prevTuition = "PREVIOUS TUITION CHARGES";
  static const String amntOwing = "Amount (Owing)";
  static const String description = "Description";
  static const String generateInvoice = "Generate Current Invoice?";
  static const String standardAction = "Will apply standard fees immediately.";
  static const String dateFormat = "MMM d, yyyy";

  static const List<String> grades = [
    'Form 1',
    'Form 2',
    'Form 3',
    'Form 4',
    'Lower 6',
    'Upper 6',
  ];
  static const billingTypes = [
    'Standard Termly',
    'Monthly (Fixed)',
    'Monthly (Custom Date)',
  ];
  static const balBroughtDown = "Balance Brought Forward";

  static const String strNew = "New";
  static const String exampleStuId = "STU00-000-000";
  static const logsF = "Financials";
  static const logsS = "System";
  static const logsA = "Alerts";

  static const activityHistory = "Activity History";
  static const exportLogs = "Export Logs";
  static const actionMessageExporting = "Exporting audit trail to CSV...";
  static const strAll = "All";
  static const mmm = "MMM";
  static const String dd = "dd";
  static const String hhmm = "HH:mm";

  static const String errLogsNotFound = "Error logs not found";
  static const String errNoStu= "No Students Found";
  static const noActiveSchool = "No active school found";
  static const logInAgain = "Please LogIn Again";
  static const stuDir = "Student Directory";

  static const comingSoon= "Coming Soon Feature";
  static const plusStudent = "Add Student";
  static const search = "Search";
  static const name = "name";
  static const threeDots = "...";
  static const searchByName = "$search $name $threeDots";
  static const outstanding = "Outstanding Debt";

  static const fontFamily = "JetBrains Mono";
  static const owing = "Owing";
  static const paid = "Paid";


  static const errLoadingStu = "Error loading Students";
  static const retry = "Retry";
  static const noStuFound = "No Students found";
  static const noStuId = "No STU-ID";



  static const String pageTitle = "Student Profile";

  // Status Labels
  static const String statusActive = "ACTIVE";
  static const String statusArrears = "ARREARS";

  // Tabs
  static const String tabOverview = "Overview";
  static const String tabFinance = "Finance";
  static const String tabAcademic = "Academic";

  // Actions
  static const String actCall = "Call Guardian";
  static const String actWhatsApp = "WhatsApp";
  static const String actLogPayment = "Log Payment";

  // Section Headers
  static const String secIdentity = "Identity & Class";
  static const String secGuardian = "Guardian / Payer";
  static const String secSubjects = "Enrolled Subjects";
  static const String secLedger = "Recent Transactions";

  // Labels
  static const String lblAdmNum = "ID";
  static const String lblDob = "DOB";
  static const String lblGender = "Gender";
  static const String lblType = "Type";
  static const String lblPhone = "Phone";
  static const String lblRelation = "Relation";

  // Finance
  static const String lblOwed = "Outstanding Balance";
  static const String lblPaid = "Paid YTD";

  // Fallbacks
  static const String noSubjects = "No subjects registered";
  static const String loading = "Loading student profile...";
  static const String error = "Could not load student data.";

  static const String pageTitleSet = "Profile & Settings";

  static const String secApp = "Application";
  static const String secData = "Data & Sync";
  static const String secSupport = "Support";

  // Items
  static const String itemEditProfile = "Edit Profile";
  static const String subEditProfile = "Update name and role";

  static const String itemSchool = "School Details";
  static const String subSchool = "Logo, address, and contact";

  static const String itemTheme = "Dark Mode";
  static const String itemNotifs = "Notifications";

  static const String itemSync = "Sync Status";
  static const String subSyncUnknown = "Sync status unavailable";
  static const String itemAutoBilling = "Auto Billing";
  static const String subAutoBilling = "Run billing once per day on this device";

  static const String itemContactDev = "Contact Developer";
  static const String subContactDev = "Report bugs or request features";

  static const String itemLogout = "Log Out";
  static const String unavailable = "Unavailable";

    static const String backToLogin = "Back to Login";
  
  // Step 1: Request
  static const String headRequest = "Forgot Password?";
  static const String subRequest = "Enter your email address to receive a verification code.";
  static const String btnSend = "Send Reset Code";
  
  // Step 2: Verify & Reset
  static const String headReset = "Secure Your Account";
  static const String subReset = "Enter the code sent to your email and set your new password.";
  static const String hintCode = "123456";
  static const String btnReset = "Reset Password";
  static const String resendLink = "Didn't receive code? Resend";
  
  // Messages
  static const String msgSent = "Code sent to your email";
  static const String msgSuccess = "Password reset successfully. Please login.";
  static const String errMatch = "Passwords do not match";
  static const String errCode = "Invalid code format";
  static const String cancel = "Cancel";
  static const String close = "Close";
  static const String delete = "Delete";

  // Contact Dev
  static const String devUplinkFailed = "UPLINK FAILED. CHECK SIGNAL.";
  static const String devSystemOnline = "SYSTEM ONLINE";
  static const String devWhatsAppUplink = "WHATSAPP_UPLINK";
  static const String devEmailPayload = "EMAIL_PAYLOAD";
  static const String devEmailPayloadSub = "Formal // Detailed";
  static const String devDirectUplink = "Direct uplink established.\nSelect transmission protocol.";
  static const String devWhatsAppUplinkSub = "Encrypted // Instant";
  static const String devFingerprintIdPrefix = "ID: ";
  static const String routeError = "Route Error";

  // Settings
  static const String subManageProfile = "Manage your personal details";
  static const String subSchoolConfig = "School configuration";
  static const String subThemeFixed = "Always active in Legend";
  static const String subPushAlerts = "Push alerts for updates";
  static const String subAutoBillingDesc = "Generate invoices automatically";
  static const String itemAutoBillingErrors = "Auto-billing errors";
  static const String subAutoBillingErrors = "View the last 50 engine errors";
  static const String secDangerZone = "Danger Zone";
  static const String itemDeleteAllStudentData = "Delete all student data";
  static const String subDeleteAllStudentData = "Removes students, enrollments, invoices, and payments";
  static const String autoBillingLockedTitle = "Auto-billing locked";
  static const String autoBillingLockedBody =
      "Another device holds the billing lock. You can take over and run billing here.";
  static const String autoBillingTakeOver = "Take Over";
  static const String autoBillingNoErrors = "No auto-billing errors recorded.";
  static const String autoBillingErrorsTitle = "Auto-billing errors";
  static const String autoBillingClearLog = "Clear Log";
  static const String deleteAllDataTitle = "Delete all student data";
  static const String deleteAllDataBody =
      "This will delete all students, enrollments, invoices, payments, allocations, and ledger entries for this school.";
  static const String deleteAllDataPrompt = "Type DELETE to confirm.";
  static const String deleteAllDataHint = "DELETE";
  static const String deleteAllDataSuccess = "All student data deleted.";
  static const String unknownUser = "Unknown User";
  static const String locked = "LOCKED";
  static const String syncDisconnected = "Disconnected";
  static const String syncSynchronized = "Synchronized";
  static const String syncStatusPrefix = "Status: ";
  static const String initialsFallback = "?";

  // Sync status
  static const String syncError = "Sync error";
  static const String syncConnecting = "Connecting...";
  static const String syncSyncing = "Syncing...";
  static const String syncConnected = "Connected";
  static const String syncOfflineCached = "Offline (cached)";
  static const String syncOffline = "Offline";
  static const String syncLastSyncedPrefix = "Last synced: ";
  static const String autoBillingLockHeld = "Auto-billing lock held by another device.";
  static const String autoBillingFailedPrefix = "Auto-billing failed: ";
  static const String autoBillingErrMissingTuition = "Missing tuition amount for enrollment.";
  static const String autoBillingErrMissingEnrollmentDate = "Missing enrollment date for monthly custom.";
  static const String autoBillingErrNoActiveTermMonthlyFixed = "Active term not found for monthly fixed.";
  static const String autoBillingErrNoActiveTermTermly = "Active term not found for termly billing.";
  static const String autoBillingErrNoActiveYearYearly = "Active academic year not found for yearly billing.";
}
