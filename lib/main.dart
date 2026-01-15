import 'app_libs.dart';

void main() async {
  // ---------------------------------------------------------------------------
  // 1. SYSTEM INITIALIZATION
  // ---------------------------------------------------------------------------
  await AppInit.initialize(); // Ensures Flutter binding & Env load
  final supabaseClient = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // 2. BUILD DATA LAYER (Repositories)
  // ---------------------------------------------------------------------------
  // These are stateless workers that talk to the DB/API.
  final authRepository = AuthRepository(supabaseClient);
  final schoolRepository = SchoolRepository(supabaseClient);
  
  final dashboardRepository = DashboardRepository();
  final studentRepository = StudentRepository(); // WIRED UP
  final financeRepository = PowerSyncFinanceRepository(); // WIRED UP

  // ---------------------------------------------------------------------------
  // 3. BUILD SERVICE LAYER (Business Logic)
  // ---------------------------------------------------------------------------
  // AuthService holds the "Session State" (Who is logged in?)
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
        // Accessible to ViewModels for data fetching.
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
        
        // 1. SETTINGS VM
        // Needs Auth & Dashboard Repo
        ChangeNotifierProvider<SettingsViewModel>(
          create: (context) => SettingsViewModel(
            context.read<AuthService>(),
            context.read<DashboardRepository>(),
          ),
        ),

        // 2. FINANCE VM
        // Needs Finance Repo & Auth Service
        ChangeNotifierProvider<FinanceViewModel>(
          create: (context) => FinanceViewModel(
            context.read<FinanceRepository>(),
            context.read<AuthService>(),
          ),
        ),

        // 3. DASHBOARD VM
        // Needs Dashboard Repo & Auth Service
        ChangeNotifierProvider<DashboardViewModel>(
          create: (context) => DashboardViewModel(
             context.read<DashboardRepository>(),
             context.read<AuthService>(),
          ),
        ),

        // 4. STUDENT LIST VM (The Tricky One)
        // It needs 'schoolId' which lives inside AuthService.
        // We use ProxyProvider to rebuild this VM if Auth changes.
        ChangeNotifierProxyProvider<AuthService, StudentListViewModel>(
          create: (context) => StudentListViewModel(
            context.read<StudentRepository>(), 
            context.read<AuthService>().activeSchool?.id ?? '',
          ),
          update: (context, auth, previous) => StudentListViewModel(
            context.read<StudentRepository>(),
            auth.activeSchool?.id ?? '',
          ),
        ),

        ChangeNotifierProvider<StatsViewModel>(
          create: (context) => StatsViewModel(
            context.read<DashboardRepository>(),
            context.read<AuthService>(),
          ),
        ),

        Provider<AuthRepository>(create: (_) => authRepository), 
      ],
      child: const KwaLegendApp(),
    ),
  );
}