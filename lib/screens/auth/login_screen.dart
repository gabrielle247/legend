import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legend/constants/app_constants.dart';
import 'package:legend/services/auth/auth_serv.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // UI State
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // 1. Input Validation
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both email and password."),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // 2. Set Loading State
    setState(() => _isLoading = true);

    try {
      // 3. Call Auth Service (This handles Supabase Login + School Fetch)
      // Note: We use context.read because we are inside a callback, not build()
      await context.read<AuthService>().login(email, password);

      if (mounted) {
        // 4. Success -> Navigate
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      // 5. Error Handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")), // Clean up error msg
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // 6. Reset Loading State (if still on screen)
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$provider Login is coming soon!"),
        backgroundColor: AppColors.surfaceLightGrey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Screen Height for responsive layout
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primaryBlue, // Top Background Color
      body: Stack(
        children: [
          // -------------------------------------------------------------------
          // 1. HEADER (Gradient & Logo)
          // -------------------------------------------------------------------
          Container(
            height: size.height * 0.4,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBlueLight, // Lighter Blue top
                  AppColors.primaryBlue,      // Brand Blue bottom
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.05),
                  Text(
                    "KwaLegend",
                    style: GoogleFonts.dancingScript( 
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // 2. THE CARD (Curved Body)
          // -------------------------------------------------------------------
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.75, // Occupies bottom 75%
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.backgroundBlack, // Dark Theme Body
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title
                    const SizedBox(height: 16),
                    Text(
                      "Welcome back",
                      style: GoogleFonts.jetBrainsMono( 
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ---------------------------------------------------------
                    // INPUT FIELDS
                    // ---------------------------------------------------------
                    _buildTextField(
                      controller: _emailController,
                      label: "Email Address",
                      icon: Icons.email_outlined,
                      inputType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _passwordController,
                      label: "Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isVisible: _isPasswordVisible,
                      onVisibilityToggle: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),

                    // ---------------------------------------------------------
                    // FORGOT PASSWORD LINK
                    // ---------------------------------------------------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : () => context.push(AppRoutes.resetPassword),
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: AppColors.primaryBlueLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ---------------------------------------------------------
                    // LOG IN BUTTON (With Loading State)
                    // ---------------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceLightGrey, // Dark button on dark bg
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: AppColors.surfaceDarkGrey,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Log in",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ---------------------------------------------------------
                    // SOCIAL LOGIN (Divider & Icons)
                    // ---------------------------------------------------------
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.surfaceLightGrey)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("OR", style: TextStyle(color: AppColors.textGrey)),
                        ),
                        Expanded(child: Divider(color: AppColors.surfaceLightGrey)),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialIcon(
                          icon: Icons.g_mobiledata, 
                          color: Colors.red,
                          onTap: () => _handleSocialLogin("Google"),
                        ),
                        const SizedBox(width: 20),
                        _SocialIcon(
                          icon: Icons.facebook,
                          color: Colors.blue,
                          onTap: () => _handleSocialLogin("Facebook"),
                        ),
                        const SizedBox(width: 20),
                        _SocialIcon(
                          icon: Icons.apple,
                          color: Colors.white,
                          onTap: () => _handleSocialLogin("Apple"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ---------------------------------------------------------
                    // CREATE ACCOUNT LINK
                    // ---------------------------------------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an Account? ",
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                        GestureDetector(
                          onTap: _isLoading ? null : () => context.push(AppRoutes.signup),
                          child: const Text(
                            "Create Account",
                            style: TextStyle(
                              color: AppColors.primaryBlueLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Bottom Spacer
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType inputType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLightGrey),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !isVisible,
            keyboardType: inputType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(color: AppColors.textGrey.withAlpha(100)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.textGrey,
                      ),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkGrey,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceLightGrey),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}