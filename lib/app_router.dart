import 'package:legend/app_libs.dart';
import 'package:legend/data/constants/app_routes.dart';
import 'package:legend/screens/finance/logging_payments.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class LegendRouter {
  final AuthService authService;

  LegendRouter(this.authService);

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,

    // -------------------------------------------------------------------------
    // THE MAGIC LINK: Listens to Auth changes
    // -------------------------------------------------------------------------
    refreshListenable: authService,

    // -------------------------------------------------------------------------
    // THE BOUNCER: Security Logic
    // -------------------------------------------------------------------------
    redirect: (context, state) {
      final isLoggedIn = authService.isAuthenticated;
      final requiresSetup = authService.requiresOnlineSetup;
      final location = state.uri.toString();

      final isAuthRoute =
          location == AppRoutes.login ||
          location == AppRoutes.signup ||
          location == AppRoutes.resetPassword;
      final isSetupRoute = location == '/offline-setup';

      // 1. If NOT logged in...
      if (!isLoggedIn) {
        if (!isAuthRoute) return AppRoutes.login;
      }

      // 2. If LOGGED IN...
      if (isLoggedIn) {
        // A. SECURITY CHECK: Do we need online verification?
        if (requiresSetup) {
          if (!isSetupRoute) return '/offline-setup';
          return null;
        }

        // B. If verified, prevent going back to Login/Setup
        if (isAuthRoute || isSetupRoute) return AppRoutes.dashboard;
      }

      return null;
    },

    errorBuilder: (context, state) => const Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Center(
        child: Text('Route Error', style: TextStyle(color: Colors.white)),
      ),
    ),

    routes: [
      // =========================================================================
      // 1. AUTH & PUBLIC
      // =========================================================================
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.loggingPayments,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LoggingPaymentsScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),

      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.tos,
        builder: (context, state) => const TosScreen(),
      ),
      GoRoute(
        path: '/offline-setup',
        builder: (context, state) => const OfflineSetupScreen(),
      ),

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
                  // UPDATED: Notifications now has a sub-route for details
                  GoRoute(
                    path: AppRoutes.notifications,
                    builder: (context, state) => const NotificationsScreen(),
                    routes: [
                      GoRoute(
                        path: 'detail', // Path: /dashboard/notifications/detail
                        parentNavigatorKey:
                            _rootNavigatorKey, // Covers bottom nav
                        builder: (context, state) {
                          // Pass the notification object via 'extra'
                          final noti = state.extra as LegendNotification;
                          return NotificationDetailScreen(notification: noti);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: AppRoutes.statistics,
                    builder: (context, state) => const StatisticsScreen(),
                  ),
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
                    builder: (context, state) => ViewStudentScreen(
                      // FIX: Add '!'
                      studentId: state.pathParameters['studentId']!,
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.studentLogs,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => StudentLogsScreen(
                      studentId: state.pathParameters['studentId']!,
                    ),
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
                    builder: (context, state) => ViewInvoiceScreen(
                      invoiceId: state.pathParameters['invoiceId'],
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.recordPayment,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => RecordPaymentScreen(
                      studentId: state.uri.queryParameters['studentId'],
                    ),
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
          border: Border(
            top: BorderSide(color: AppColors.surfaceLightGrey, width: 0.5),
          ),
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
                GButton(
                  icon: Icons.dashboard_outlined,
                  text: AppStrings.dashboardTitle,
                ),
                GButton(
                  icon: Icons.people_outline,
                  text: AppStrings.studentsTitle,
                ),
                GButton(
                  icon: Icons.account_balance_wallet_outlined,
                  text: AppStrings.financeTitle,
                ),
                GButton(
                  icon: Icons.person_outline,
                  text: AppStrings.settingsTitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
