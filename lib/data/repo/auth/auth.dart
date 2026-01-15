import 'package:supabase_flutter/supabase_flutter.dart';

/// Custom Exception for UI consumption
class AppAuthException implements Exception {
  final String message;
  final String? code;
  AppAuthException(this.message, [this.code]);
  
  @override
  String toString() => message;
}

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // ---------------------------------------------------------------------------
  // SESSION MANAGEMENT
  // ---------------------------------------------------------------------------
  
  User? get currentUser => _supabase.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // AUTH ACTIONS
  // ---------------------------------------------------------------------------

  /// Login with Email & Password
  Future<AuthResponse> signInWithPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw AppAuthException(_mapAuthError(e.message), e.code);
    } catch (e) {
      throw AppAuthException('An unexpected error occurred during login.');
    }
  }

  /// Sign Up (Triggers OTP/Confirmation Email)
  Future<AuthResponse> signUp(String email, String password, String fullName) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName}, // Stored in raw_user_meta_data
      );
      return response;
    } on AuthException catch (e) {
      throw AppAuthException(e.message, e.code);
    } catch (e) {
      throw AppAuthException('Sign up failed. Please try again.');
    }
  }

  /// Login with OTP (Magic Link / Code)
  Future<void> signInWithOtp(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.flutter://login-callback/',
      );
    } on AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }

  /// Verify OTP (Email or Phone) - Used for Login OR Recovery
  Future<AuthResponse> verifyOtp(String email, String token, OtpType type) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );
      return response;
    } on AuthException {
      throw AppAuthException('Invalid Code. Please check and try again.');
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Fail silently on logout errors, just clear local state usually
    }
  }

  /// Password Reset Request (Step 1: Send Email)
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AppAuthException(e.message);
    }
  }

  /// Update User Password (Step 2: Save New Password)
  /// Requires an active session (which verifyOtp provides)
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw AppAuthException("Failed to update password: ${e.message}");
    }
  }

  // ---------------------------------------------------------------------------
  // HELPER: Error Mapping
  // ---------------------------------------------------------------------------
  String _mapAuthError(String rawMessage) {
    if (rawMessage.contains("Invalid login credentials")) {
      return "Incorrect email or password.";
    }
    if (rawMessage.contains("Email not confirmed")) {
      return "Please confirm your email address first.";
    }
    return rawMessage;
  }
}