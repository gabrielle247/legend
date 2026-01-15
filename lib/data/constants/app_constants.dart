import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// -----------------------------------------------------------------------------
// APP COLORS (Slate & Blue)
// -----------------------------------------------------------------------------
class AppColors {
  // Backgrounds
  static const Color backgroundBlack = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDarkGrey = Color(0xFF1E293B); // Slate 800
  static const Color surfaceLightGrey = Color(0xFF334155); // Slate 700

  // Brand
  static const Color primaryBlue = Color(0xFF3B82F6); // Blue 500
  static const Color primaryBlueDark = Color(0xFF2563EB); // Blue 600
  static const Color primaryBlueLight = Color(0xFF60A5FA); // Blue 400

  // Text
  static const Color textWhite = Color(0xFFF8FAFC); // Slate 50
  static const Color textGrey = Color(0xFF94A3B8); // Slate 400
  
  // Functional
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
}

// -----------------------------------------------------------------------------
// APP THEME
// -----------------------------------------------------------------------------
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundBlack,
      primaryColor: AppColors.primaryBlue,
      fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        onPrimary: Colors.white,
        secondary: AppColors.surfaceDarkGrey,
        onSecondary: Colors.white,
        surface: AppColors.surfaceDarkGrey,
        error: AppColors.errorRed,
        background: AppColors.backgroundBlack,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ROUTES
// -----------------------------------------------------------------------------
class AppRoutes {
  // --- 1. Auth & Legal ---
  static const String login = '/login';
  static const String signup = '/signup';
  static const String resetPassword = '/reset-password';
  static const String tos = '/tos'; // Terms of Service

  // --- 2. Shell (Main Tabs) ---
  static const String dashboard = '/dashboard';
  static const String students = '/students';
  static const String finance = '/finance';
  static const String settings = '/settings';

  // --- 3. Dashboard Features ---
  static const String notifications = 'notifications'; // /dashboard/notifications
  static const String statistics = 'statistics'; // /dashboard/statistics

  // --- 4. Student Features ---
  static const String addStudent = 'add'; // /students/add
  static const String viewStudent = 'view/:studentId'; // /students/view/123
  static const String studentLogs = 'logs/:studentId'; // /students/logs/123

  // --- 5. Finance Features ---
  static const String createInvoice = 'invoice/new'; // /finance/invoice/new
  static const String viewInvoice = 'invoice/:invoiceId'; // /finance/invoice/INV-001
  static const String recordPayment = 'payment/new'; // /finance/payment/new

  // --- 6. Settings Features ---
  static const String contactDev = 'contact-dev'; // /settings/contact-dev
}