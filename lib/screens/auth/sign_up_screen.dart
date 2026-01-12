import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legend/constants/app_constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // UI State
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _schoolNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    // PLACEBO: Navigate to Dashboard directly
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account Created! Welcome to the Academy.")),
    );
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Stack(
        children: [
          // -------------------------------------------------------------------
          // 1. HEADER (Gradient & Title)
          // -------------------------------------------------------------------
          Container(
            height: size.height * 0.35, // Slightly shorter header for Signup
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBlueLight,
                  AppColors.primaryBlue,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Back Button (Custom for aesthetics)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),
                  Text(
                    "Join the Academy",
                    style: GoogleFonts.dancingScript(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create your Legend",
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // 2. THE CARD (Form Body)
          // -------------------------------------------------------------------
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.80, // Taller card for more fields
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.backgroundBlack,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, -5)),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      "Register",
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ---------------------------------------------------------
                    // INPUT FIELDS
                    // ---------------------------------------------------------
                    _buildTextField(
                      controller: _nameController,
                      label: "Full Name",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _emailController,
                      label: "Email",
                      icon: Icons.email_outlined,
                      inputType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _schoolNameController,
                      label: "School Name (e.g. KwaLegend)",
                      icon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _passwordController,
                      label: "Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isVisible: _isPasswordVisible,
                      onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: "Confirm Password",
                      icon: Icons.lock_outline, // Different icon
                      isPassword: true,
                      isVisible: _isConfirmPasswordVisible,
                      onVisibilityToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),

                    const SizedBox(height: 40),

                    // ---------------------------------------------------------
                    // SIGN UP BUTTON
                    // ---------------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue, // Blue button for action
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: AppColors.primaryBlue.withAlpha(100),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ---------------------------------------------------------
                    // ALREADY HAVE ACCOUNT
                    // ---------------------------------------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an Account? ",
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.login), // Use go to reset stack if needed, or pop
                          child: const Text(
                            "Log in",
                            style: TextStyle(
                              color: AppColors.primaryBlueLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Bottom Spacer for scrolling
                    const SizedBox(height: 30),
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
              prefixIcon: Icon(icon, color: AppColors.textGrey, size: 22), // Added Prefix Icon
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