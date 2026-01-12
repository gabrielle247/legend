import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:legend/constants/app_constants.dart';
import 'package:legend/screens/contact_dev_screen.dart';
import 'package:legend/screens/settings/tos_screen.dart';
import 'package:legend/services/auth/auth_serv.dart';

// Import Screens
import 'package:legend/screens/all_screens_export.dart';
import 'package:legend/screens/finance/create_invoice_screen.dart';
import 'package:legend/screens/finance/record_payment_screen.dart';
import 'package:legend/screens/finance/view_invoice_screen.dart';
import 'package:legend/screens/students/add_student_screen.dart';
import 'package:legend/screens/students/student_logs_screen.dart';
import 'package:legend/screens/students/view_student_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class LegendRouter {
  final AuthService authService;

  LegendRouter(this.authService);

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard, // We aim for dashboard, redirect handles the rest
    
    // -------------------------------------------------------------------------
    // THE MAGIC LINK: This listens to AuthService.notifyListeners()
    // -------------------------------------------------------------------------
    refreshListenable: authService,

    // -------------------------------------------------------------------------
    // THE BOUNCER: Security Logic
    // -------------------------------------------------------------------------
    redirect: (context, state) {
      final isLoggedIn = authService.isAuthenticated;
      final location = state.uri.toString();

      // Define public routes
      final isAuthRoute = location == AppRoutes.login || 
                          location == AppRoutes.signup || 
                          location == AppRoutes.resetPassword;

      // 1. If NOT logged in...
      if (!isLoggedIn) {
        // ...and trying to go to a protected route -> Redirect to Login
        if (!isAuthRoute) return AppRoutes.login;
      }

      // 2. If LOGGED IN...
      if (isLoggedIn) {
        // ...and trying to go to Login/Signup -> Redirect to Dashboard
        if (isAuthRoute) return AppRoutes.dashboard;
      }

      // 3. Otherwise, let them pass
      return null;
    },

    errorBuilder: (context, state) => const Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Center(child: Text('Route Error', style: TextStyle(color: Colors.white))),
    ),

    routes: [
      // =========================================================================
      // 1. AUTH & PUBLIC
      // =========================================================================
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (context, state) => const SignupScreen()),
      GoRoute(path: AppRoutes.resetPassword, builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.tos, builder: (context, state) => const TosScreen()),

      // =========================================================================
      // 2. SHELL ROUTES (Bottom Navigation)
      // =========================================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // --- BRANCH 0: DASHBOARD ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(path: AppRoutes.notifications, builder: (context, state) => const NotificationsScreen()),
                  GoRoute(path: AppRoutes.statistics, builder: (context, state) => const StatisticsScreen()),
                ],
              ),
            ],
          ),

          // --- BRANCH 1: STUDENTS ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.students,
                builder: (context, state) => const StudentsScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.addStudent,
                    parentNavigatorKey: _rootNavigatorKey, 
                    builder: (context, state) => const AddStudentScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.viewStudent,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => ViewStudentScreen(studentId: state.pathParameters['studentId']),
                  ),
                  GoRoute(
                    path: AppRoutes.studentLogs,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => StudentLogsScreen(studentId: state.pathParameters['studentId']),
                  ),
                ],
              ),
            ],
          ),

          // --- BRANCH 2: FINANCE ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.finance,
                builder: (context, state) => const FinanceScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.createInvoice,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const CreateInvoiceScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.viewInvoice,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => ViewInvoiceScreen(invoiceId: state.pathParameters['invoiceId']),
                  ),
                  GoRoute(
                    path: AppRoutes.recordPayment,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => RecordPaymentScreen(studentId: state.uri.queryParameters['studentId']),
                  ),
                ],
              ),
            ],
          ),

          // --- BRANCH 3: SETTINGS ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.contactDev,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ContactDevScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// =============================================================================
// APP SHELL
// =============================================================================
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({required this.navigationShell, super.key});

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          border: Border(top: BorderSide(color: AppColors.surfaceLightGrey, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: GNav(
              backgroundColor: AppColors.surfaceDarkGrey,
              tabBackgroundColor: AppColors.primaryBlueLight.withAlpha(50),
              color: AppColors.textGrey,
              activeColor: AppColors.textWhite,
              gap: 8,
              tabBorderRadius: 12,
              iconSize: 22,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              selectedIndex: navigationShell.currentIndex,
              onTabChange: _onTabSelected,
              tabs: const [
                GButton(icon: Icons.dashboard_outlined, text: AppStrings.dashboardTitle),
                GButton(icon: Icons.people_outline, text: AppStrings.studentsTitle),
                GButton(icon: Icons.account_balance_wallet_outlined, text: AppStrings.financeTitle),
                GButton(icon: Icons.person_outline, text: AppStrings.settingsTitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}