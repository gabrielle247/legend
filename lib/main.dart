import 'app_libs.dart';

void main() async {
  // ---------------------------------------------------------------------------
  // 1. SYSTEM INITIALIZATION
  // ---------------------------------------------------------------------------
  await AppInit.initialize();
  final supabaseClient = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // 2. BUILD DATA LAYER (Repositories)
  // ---------------------------------------------------------------------------
  final authRepository = AuthRepository(supabaseClient);
  final schoolRepository = SchoolRepository(supabaseClient);

  final dashboardRepository = DashboardRepository();
  final studentRepository = StudentRepository();
  final financeRepository = PowerSyncFinanceRepository();

  // ---------------------------------------------------------------------------
  // 3. BUILD SERVICE LAYER
  // ---------------------------------------------------------------------------
  final authService = AuthService(authRepository, schoolRepository);

  // ---------------------------------------------------------------------------
  // 4. LAUNCH APP WITH PROVIDERS
  // ---------------------------------------------------------------------------
  runApp(
    MultiProvider(
      providers: [
        // =========================
        // CORE SERVICE
        // =========================
        ChangeNotifierProvider<AuthService>(
          create: (_) => authService,
        ),

        // =========================
        // REPOSITORIES
        // =========================
        Provider<AuthRepository>(create: (_) => authRepository),
        Provider<SchoolRepository>(create: (_) => schoolRepository),
        Provider<DashboardRepository>(create: (_) => dashboardRepository),
        Provider<StudentRepository>(create: (_) => studentRepository),
        Provider<FinanceRepository>(create: (_) => financeRepository),

        // =========================
        // GLOBAL VIEW MODELS
        // =========================

        ChangeNotifierProvider<SettingsViewModel>(
          create: (context) => SettingsViewModel(
            context.read<AuthService>(),
            context.read<DashboardRepository>(),
          ),
        ),

        ChangeNotifierProvider<FinanceViewModel>(
          create: (context) => FinanceViewModel(
            context.read<FinanceRepository>(),
            context.read<AuthService>(),
          ),
        ),

        ChangeNotifierProvider<DashboardViewModel>(
          create: (context) => DashboardViewModel(
            context.read<DashboardRepository>(),
            context.read<AuthService>(),
          ),
        ),

        // Student list depends on schoolId (from AuthService)
        ChangeNotifierProxyProvider<AuthService, StudentListViewModel>(
          create: (context) => StudentListViewModel(
            context.read<StudentRepository>(),
            context.read<AuthService>().activeSchool?.id ?? '',
          ),
          update: (context, auth, previous) {
            final schoolId = auth.activeSchool?.id ?? '';

            // Reuse existing VM if schoolId unchanged
            if (previous != null && previous.schoolId == schoolId) {
              return previous;
            }

            return StudentListViewModel(
              context.read<StudentRepository>(),
              schoolId,
            );
          },
        ),

        // StatsViewModel now requires FinanceRepository too
        ChangeNotifierProvider<StatsViewModel>(
          create: (context) => StatsViewModel(
            context.read<DashboardRepository>(),
            context.read<FinanceRepository>(),
            context.read<AuthService>(),
          ),
        ),
      ],
      child: const KwaLegendApp(),
    ),
  );
}
