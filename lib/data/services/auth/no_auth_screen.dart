import 'package:legend/app_libs.dart';

class OfflineSetupScreen extends StatelessWidget {
  const OfflineSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: AppColors.primaryBlue),
            const SizedBox(height: 32),
            const Text(
              "Security Check Required",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              "For your security, KwaLegend requires an internet connection for the initial setup. This ensures your school's data is verified directly from the server.\n\nOnce verified, you can work offline for up to 7 days.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white.withAlpha(180), height: 1.5),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Trigger a retry via AuthService
                  context.read<AuthService>().login(
                    "RETRY_MODE", 
                    "RETRY_MODE",
                  ); 
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                child: const Text("I'm Online Now - Retry", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text("Back to Login", style: TextStyle(color: AppColors.textGrey)),
            )
          ],
        ),
      ),
    );
  }
}