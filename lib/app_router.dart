import 'package:legend/app_libs.dart'; // Assumes this exports all your Screens and Models




final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
// ignore: unused_element
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class LegendRouter {
  final AuthService authService;

  LegendRouter(this.authService);

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    
    // 1. AUTH LISTENER
    refreshListenable: authService,

    // 2. REDIRECT LOGIC
    redirect: (context, state) {
      final isLoggedIn = authService.isAuthenticated;
      final isLoading = authService.isLoading;
      final requiresProfile = authService.requiresProfileSetup;
      final requiresSetup = authService.requiresOnlineSetup;
      final location = state.uri.toString();

      final isAuthRoute = location == AppRoutes.login || 
                          location == AppRoutes.signup || 
                          location == AppRoutes.resetPassword ||
                          location == AppRoutes.tos;
      
      final isProfileRoute = location == AppRoutes.profileSetup;
      final isSetupRoute = location == AppRoutes.createSchool;
      final isSplashRoute = location == AppRoutes.splash;

      // A. Still loading? Stay on splash.
      if (isLoading) {
        return isSplashRoute ? null : AppRoutes.splash;
      }

      // B. Not Logged In? -> Go Login
      if (!isLoggedIn) {
        if (isSplashRoute) return AppRoutes.login;
        if (!isAuthRoute) return AppRoutes.login;
        return null;
      }

      // C. Logged In?
      if (requiresProfile) {
        if (!isProfileRoute) return AppRoutes.profileSetup;
        return null;
      }

      // i. Security Check
      if (requiresSetup) {
        if (isSplashRoute) return AppRoutes.createSchool;
        if (!isSetupRoute) return AppRoutes.createSchool;
        return null;
      }

      // ii. Already Auth? -> Go Dashboard
      if (isSplashRoute || isAuthRoute || isSetupRoute || isProfileRoute) {
        return AppRoutes.dashboard;
      }

      return null;
    },

    errorBuilder: (context, state) => const Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Center(child: Text(AppStrings.routeError, style: TextStyle(color: Colors.white))),
    ),

    routes: [
      // =======================================================================
      // PUBLIC / AUTH ROUTES (Root Navigator)
      // =======================================================================
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
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
        path: AppRoutes.profileSetup,
        builder: (context, state) => const CreateProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.createSchool,
        builder: (context, state) => const CreateSchoolScreen(),
      ),

      // =======================================================================
      // SHELL ROUTE (The Fixed Bottom Nav Wrapper)
      // =======================================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          
          // BRANCH 1: DASHBOARD
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.notifications, // "notifications"
                    builder: (context, state) => const NotificationsScreen(),
                    routes: [
                      GoRoute(
                        path: 'detail',
                        parentNavigatorKey: _rootNavigatorKey, // Fullscreen
                        builder: (context, state) {
                          final noti = state.extra as LegendNotification;
                          return NotificationDetailScreen(notification: noti);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: AppRoutes.statistics, // "statistics"
                    builder: (context, state) => const StatisticsScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.outstanding,
                    builder: (context, state) => const OutstandingStudentsScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.received,
                    builder: (context, state) => const ReceivedPaymentsScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.activity,
                    builder: (context, state) => const DashboardActivityScreen(),
                  ),
                ],
              ),
            ],
          ),

          // BRANCH 2: STUDENTS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.students,
                builder: (context, state) => const StudentsScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.addStudent,
                    parentNavigatorKey: _rootNavigatorKey, // Hide Nav Bar
                    builder: (context, state) => const AddStudentScreen(),
                  ),
                  GoRoute(
                    // Ensure AppRoutes.viewStudent contains ":studentId" 
                    // e.g. "view/:studentId"
                    path: AppRoutes.viewStudent, 
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => ViewStudentScreen(
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
                  GoRoute(
                    path: AppRoutes.studentInvoices,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => StudentInvoicesScreen(
                      studentId: state.pathParameters['studentId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // BRANCH 3: FINANCE
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
                  // Wired Logging Payments here so it relates to Finance flow
                  GoRoute(
                    path: AppRoutes.loggingPayments,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => LoggingPaymentsScreen(
                      studentId: state.pathParameters['studentId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // BRANCH 4: SETTINGS
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
// APP SHELL WIDGET
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
      body: navigationShell, // The current branch content
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          boxShadow: [
            BoxShadow(
              color: Colors.black26, 
              blurRadius: 10, 
              offset: Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: GNav(
              backgroundColor: AppColors.surfaceDarkGrey,
              color: AppColors.textGrey,
              activeColor: Colors.white,
              tabBackgroundColor: AppColors.primaryBlue.withAlpha(40),
              gap: 8,
              padding: const EdgeInsets.all(12),
              iconSize: 24,
              textSize: 14,
              selectedIndex: navigationShell.currentIndex,
              onTabChange: _onTabSelected,
              tabs: const [
                GButton(
                  icon: Icons.dashboard_outlined,
                  text: 'Dashboard',
                ),
                GButton(
                  icon: Icons.people_outline,
                  text: 'Students',
                ),
                GButton(
                  icon: Icons.account_balance_wallet_outlined,
                  text: 'Finance',
                ),
                GButton(
                  icon: Icons.settings_outlined,
                  text: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
