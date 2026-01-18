import 'package:legend/app_libs.dart';
import 'package:legend/data/constants/app_routes.dart';

// -----------------------------------------------------------------------------
// 1. LOCAL STRINGS
// -----------------------------------------------------------------------------


// -----------------------------------------------------------------------------
// 2. SCREEN IMPLEMENTATION
// -----------------------------------------------------------------------------
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // State
  int _currentStep = 0; // 0 = Request, 1 = Reset
  bool _isLoading = false;
  bool _isObscure1 = true;
  bool _isObscure2 = true;
  bool _isLoggedInUser = false;

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

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthRepository>().currentUser;
    if (user?.email != null && user!.email!.trim().isNotEmpty) {
      _isLoggedInUser = true;
      _emailController.text = user.email!;
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- Logic: Step 1 (Send Code) ---
  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack("Please enter a valid email", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // WIRED: Trigger Supabase OTP Recovery
      await context.read<AuthRepository>().sendRecoveryOtp(email);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = 1; // Move to next step
        });
        _showSnack(AppStrings.msgSent);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack(e.toString(), isError: true);
      }
    }
  }

  // --- Logic: Step 2 (Reset) ---
  Future<void> _handleReset() async {
    final code = _codeController.text.trim();
    final pass = _passController.text;
    final confirm = _confirmController.text;
    final email = _emailController.text.trim();

    // Validation
    if (code.length != 6) {
       _showSnack(AppStrings.errCode, isError: true);
      return;
    }
    if (pass != confirm) {
       _showSnack(AppStrings.errMatch, isError: true);
      return;
    }
    if (pass.length < 6) {
      _showSnack("Password must be at least 6 characters", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = context.read<AuthRepository>();

      // WIRED: 1. Verify OTP (gets temporary session)
      await repo.verifyOtp(email, code, OtpType.recovery);
      
      // WIRED: 2. Update Password (uses that session)
      await repo.updatePassword(pass);

      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack(AppStrings.msgSuccess);
        if (_isLoggedInUser) {
          context.pop();
        } else {
          context.go(AppRoutes.login);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack(e.toString(), isError: true);
      }
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
                      _currentStep == 0 ? AppStrings.headRequest : AppStrings.headReset,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentStep == 0 ? AppStrings.subRequest : AppStrings.subReset,
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
                        readOnly: _isLoggedInUser,
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
                              : const Text(AppStrings.btnSend, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                              : const Text(AppStrings.btnReset, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _handleSendCode, // Resend logic reuses step 1
                        child: const Text(AppStrings.resendLink, style: TextStyle(color: AppColors.primaryBlueLight)),
                      ),
                    ],

                    const SizedBox(height: 24),
                    
                    // Back to Login Link
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: const Text(
                        AppStrings.backToLogin,
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
    bool readOnly = false,
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
            readOnly: readOnly,
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
