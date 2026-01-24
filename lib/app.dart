import 'app_libs.dart';
import 'package:legend/data/services/billing/billing_engine.dart';

class KwaLegendApp extends StatefulWidget {
  const KwaLegendApp({super.key});

  @override
  State<KwaLegendApp> createState() => _KwaLegendAppState();
}

class _KwaLegendAppState extends State<KwaLegendApp> with WidgetsBindingObserver {
  // We store the router here so it doesn't get recreated on every build
  late final LegendRouter _legendRouter;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    // Read auth service once to initialize router
    _authService = context.read<AuthService>();
    _legendRouter = LegendRouter(_authService);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final schoolId = _authService.activeSchool?.id;
    if (schoolId == null) return;
    BillingEngine().runDaily(schoolId);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KwaLegend',
      debugShowCheckedModeBanner: false,
      
      // Theme Config
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundBlack,
        primaryColor: AppColors.primaryBlue,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryBlue,
          secondary: AppColors.primaryBlueLight,
          surface: AppColors.surfaceDarkGrey,
        ),
        useMaterial3: true,
      ),

      // CONNECT THE SMART ROUTER
      routerConfig: _legendRouter.router,
    );
  }
}
