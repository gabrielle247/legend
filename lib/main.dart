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
  // These are stateless or singleton-like workers that talk to DB/API.
  final authRepository = AuthRepository(supabaseClient);
  final schoolRepository = SchoolRepository(supabaseClient);
  final dashboardRepository = DashboardRepository();
  final studentRepository = PowerSyncStudentRepository();
  final financeRepository = PowerSyncFinanceRepository();

  // ---------------------------------------------------------------------------
  // 3. BUILD SERVICE LAYER (Business Logic)
  // ---------------------------------------------------------------------------
  // AuthService needs Repos to function.
  final authService = AuthService(authRepository, schoolRepository);

  // ---------------------------------------------------------------------------
  // 4. LAUNCH APP WITH PROVIDERS
  // ---------------------------------------------------------------------------
  runApp(
    MultiProvider(
      providers: [
        // --- LEVEL 1: CORE SERVICES ---
        // Accessible everywhere. Handles User Session.
        ChangeNotifierProvider<AuthService>(
          create: (_) => authService,
        ),

        // --- LEVEL 2: REPOSITORIES ---
        // Accessible to ViewModels and Screens for direct data fetching.
        Provider<DashboardRepository>(
          create: (_) => dashboardRepository,
        ),
        Provider<StudentRepository>(
          create: (_) => studentRepository,
        ),
        Provider<FinanceRepository>(
          create: (_) => financeRepository,
        ),

        // --- LEVEL 3: GLOBAL VIEW MODELS ---
        // State that persists across screens or is needed by the Shell.
        
        // Settings needs Auth & Dashboard Repo (for profile)
        ChangeNotifierProvider<SettingsViewModel>(
          create: (context) => SettingsViewModel(
            context.read<AuthService>(),
            context.read<DashboardRepository>(),
          ),
        ),

        // Finance VM is heavy, better to instantiate it here if we want 
        // state to persist between tab switches.
        ChangeNotifierProvider<FinanceViewModel>(
          create: (context) => FinanceViewModel(
            context.read<FinanceRepository>(),
            context.read<AuthService>(),
          ),
        ),
      ],
      child: const KwaLegendApp(),
    ),
  );
}