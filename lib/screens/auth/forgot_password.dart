// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legend/constants/app_constants.dart';

// -----------------------------------------------------------------------------
// 1. LOCAL STRINGS
// -----------------------------------------------------------------------------
class _ForgotStrings {
  _ForgotStrings();
  static const String backToLogin = "Back to Login";
  
  // Step 1: Request
  static const String headRequest = "Forgot Password?";
  static const String subRequest = "Enter your email address to receive a 6-digit verification code.";
  static const String btnSend = "Send Reset Code";
  
  // Step 2: Verify & Reset
  static const String headReset = "Secure Your Account";
  static const String subReset = "Enter the code sent to your email and set your new password.";
  static const String hintCode = "123456";
  static const String btnReset = "Reset Password";
  static const String resendLink = "Didn't receive code? Resend";
  
  // Messages
  static const String msgSent = "Code sent to your email";
  static const String msgSuccess = "Password reset successfully. Please login.";
  static const String errMatch = "Passwords do not match";
  static const String errCode = "Invalid code format";
}

// -----------------------------------------------------------------------------
// 2. SCREEN IMPLEMENTATION
// -----------------------------------------------------------------------------
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // State
  int _currentStep = 0; // 0 = Request, 1 = Reset
  bool _isLoading = false;
  bool _isObscure1 = true;
  bool _isObscure2 = true;

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // --- Logic: Step 1 (Send Code) ---
  Future<void> _handleSendCode() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email"), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulate API Call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentStep = 1; // Move to next step
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_ForgotStrings.msgSent), backgroundColor: AppColors.successGreen),
      );
    }
  }

  // --- Logic: Step 2 (Reset) ---
  Future<void> _handleReset() async {
    // Basic validation logic...
    if (_codeController.text.length != 6) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_ForgotStrings.errCode), backgroundColor: AppColors.errorRed),
      );
      return;
    }
    if (_passController.text != _confirmController.text) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_ForgotStrings.errMatch), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API Call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_ForgotStrings.msgSuccess), backgroundColor: AppColors.successGreen),
      );
      context.go(AppRoutes.login); 
    }
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
            height: size.height * 0.35,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryBlueLight, AppColors.primaryBlue],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
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
                  const SizedBox(height: 10),
                  // Animated Icon based on Step
                  Icon(
                    _currentStep == 0 ? Icons.mark_email_unread_outlined : Icons.lock_reset,
                    size: 64,
                    color: Colors.white.withAlpha(200),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Recovery",
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
              height: size.height * 0.75,
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
                      _currentStep == 0 ? _ForgotStrings.headRequest : _ForgotStrings.headReset,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentStep == 0 ? _ForgotStrings.subRequest : _ForgotStrings.subReset,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                    ),
                    const SizedBox(height: 40),

                    // ================= STEP 0: EMAIL INPUT =================
                    if (_currentStep == 0) ...[
                      _buildTextField(
                        controller: _emailController,
                        label: "Email Address",
                        icon: Icons.email_outlined,
                        inputType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSendCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(_ForgotStrings.btnSend, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],

                    // ================= STEP 1: VERIFY & RESET =================
                    if (_currentStep == 1) ...[
                      // Code Input
                      _buildTextField(
                        controller: _codeController,
                        label: "6-Digit Code",
                        icon: Icons.vpn_key_outlined,
                        inputType: TextInputType.number,
                        isCodeInput: true, // Special styling
                      ),
                      const SizedBox(height: 20),

                      // New Password
                      _buildTextField(
                        controller: _passController,
                        label: "New Password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isVisible: !_isObscure1,
                        onVisibilityToggle: () => setState(() => _isObscure1 = !_isObscure1),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      _buildTextField(
                        controller: _confirmController,
                        label: "Confirm Password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isVisible: !_isObscure2,
                        onVisibilityToggle: () => setState(() => _isObscure2 = !_isObscure2),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleReset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(_ForgotStrings.btnReset, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text(_ForgotStrings.msgSent), backgroundColor: AppColors.surfaceLightGrey)
                           );
                        },
                        child: const Text(_ForgotStrings.resendLink, style: TextStyle(color: AppColors.primaryBlueLight)),
                      ),
                    ],

                    const SizedBox(height: 24),
                    
                    // Back to Login Link
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: const Text(
                        _ForgotStrings.backToLogin,
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
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
    bool isCodeInput = false,
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
            textAlign: isCodeInput ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: Colors.white, 
              fontSize: isCodeInput ? 20 : 16,
              letterSpacing: isCodeInput ? 8.0 : 0,
              fontWeight: isCodeInput ? FontWeight.bold : FontWeight.normal,
            ),
            maxLength: isCodeInput ? 6 : null,
            decoration: InputDecoration(
              hintText: isCodeInput ? "000000" : label,
              hintStyle: TextStyle(color: AppColors.textGrey.withAlpha(100), letterSpacing: 0),
              counterText: "", // Hide counter for code input
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: isCodeInput ? null : Icon(icon, color: AppColors.textGrey, size: 22),
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