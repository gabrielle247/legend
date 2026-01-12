import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. INIT & APP
import 'package:legend/app_init.dart';
import 'package:legend/app.dart';

// 2. REPOSITORIES
import 'package:legend/repo/auth/auth_repo.dart';
import 'package:legend/repo/auth/school_repo.dart';
import 'package:legend/repo/dashboard_repo.dart';
import 'package:legend/vmodels/students_vmodel.dart'; // Contains PowerSyncStudentRepository
import 'package:legend/vmodels/finance_vmodel.dart';  // Contains PowerSyncFinanceRepository

// 3. SERVICES & VIEW MODELS
import 'package:legend/services/auth/auth_serv.dart';
import 'package:legend/vmodels/settings_vmodel.dart';

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