import 'package:flutter/material.dart';
import 'package:legend/services/auth/auth_serv.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'constants/app_constants.dart';

class KwaLegendApp extends StatefulWidget {
  const KwaLegendApp({super.key});

  @override
  State<KwaLegendApp> createState() => _KwaLegendAppState();
}

class _KwaLegendAppState extends State<KwaLegendApp> {
  // We store the router here so it doesn't get recreated on every build
  late final LegendRouter _legendRouter;

  @override
  void initState() {
    super.initState();
    // Read auth service once to initialize router
    final authService = context.read<AuthService>();
    _legendRouter = LegendRouter(authService);
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