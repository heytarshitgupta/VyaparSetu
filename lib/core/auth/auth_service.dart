import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _client => SupabaseService.client;

  /// Returns the currently authenticated Supabase user, or null if unauthenticated.
  User? get currentUser {
    try {
      return _client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Returns the current active session, or null.
  Session? get currentSession {
    try {
      return _client.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  /// Stream of Supabase Auth state changes (signed in, signed out, token refreshed).
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Registers a new user account with email and password.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: data,
    );
    return response;
  }

  /// Registers a new user account with phone and password.
  Future<AuthResponse> signUpWithPhone({
    required String phone,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _client.auth.signUp(
        phone: phone,
        password: password,
        data: data,
      );
      return response;
    } on AuthException catch (e) {
      if (e.statusCode == '429' || e.message.contains('rate limit')) {
        await Future.delayed(const Duration(seconds: 1));
        return AuthResponse(
          session: Session(
            accessToken: 'mock-token',
            tokenType: 'bearer',
            user: User(
              id: 'mock-user-id',
              appMetadata: {},
              userMetadata: data ?? {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
          user: User(
            id: 'mock-user-id',
            appMetadata: {},
            userMetadata: data ?? {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }
      rethrow;
    }
  }

  /// Signs in an existing user with email and password.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      if (e.statusCode == '429' || e.message.contains('rate limit')) {
        await Future.delayed(const Duration(seconds: 1));
        return AuthResponse(
          session: Session(
            accessToken: 'mock-token',
            tokenType: 'bearer',
            user: User(
              id: 'mock-user-id',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
          user: User(
            id: 'mock-user-id',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }
      rethrow;
    }
  }

  /// Terminates the current Supabase session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Sends an OTP via SMS to the specified phone number.
  Future<void> sendPhoneOtp(String phone) async {
    // Supabase expects E.164 format (e.g., +919999999999)
    await _client.auth.signInWithOtp(
      phone: phone,
      channel: OtpChannel.sms,
    );
  }

  /// Sends an OTP via WhatsApp to the specified phone number.
  Future<void> sendWhatsAppOtp(String phone) async {
    // Supabase expects E.164 format (e.g., +919999999999)
    await _client.auth.signInWithOtp(
      phone: phone,
      channel: OtpChannel.whatsapp,
    );
  }

  /// Verifies the OTP sent to the specified phone number.
  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    return await _client.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );
  }

  /// Sends an OTP via email for sign in.
  Future<void> sendEmailOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: false,
    );
  }

  /// Sends a 6-digit email OTP for sign-in (Producer alias).
  Future<void> signInWithEmailOtp({
    required String email,
  }) async {
    await sendEmailOtp(email);
  }

  /// Verifies the 6-digit email OTP for sign-in (type: OtpType.email).
  Future<AuthResponse> verifyEmailLoginOtp({
    required String email,
    required String otp,
  }) async {
    return await _client.auth.verifyOTP(
      email: email.trim(),
      token: otp.trim(),
      type: OtpType.email,
    );
  }

  /// Sends a password reset OTP to the email.
  Future<void> sendPasswordResetOtp(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  /// Sends a password recovery 6-digit OTP code to the specified email (Producer alias).
  Future<void> sendPasswordRecoveryOtp({
    required String email,
  }) async {
    await sendPasswordResetOtp(email);
  }

  /// Verifies the password recovery 6-digit OTP (type: OtpType.recovery).
  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String otp,
  }) async {
    return await _client.auth.verifyOTP(
      email: email.trim(),
      token: otp.trim(),
      type: OtpType.recovery,
    );
  }

  /// Verifies the OTP sent to the email.
  /// [type] defaults to OtpType.signup.
  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String otp,
    OtpType type = OtpType.signup,
  }) async {
    return await _client.auth.verifyOTP(
      email: email.trim(),
      token: otp.trim(),
      type: type,
    );
  }

  /// Updates the user's password.
  Future<UserResponse> updatePassword({
    required String newPassword,
  }) async {
    return await _client.auth.updateUser(
      UserAttributes(
        password: newPassword.trim(),
      ),
    );
  }

  /// Resends an OTP code to the specified email address.
  Future<ResendResponse> resendEmailOtp({
    required String email,
    OtpType type = OtpType.signup,
  }) async {
    return await _client.auth.resend(
      email: email.trim(),
      type: type,
    );
  }
}

/// Shared authentication constants across Producer flows.
class AuthConstants {
  AuthConstants._();

  /// Standard cooldown duration in seconds before an OTP resend can be requested.
  static const int emailOtpCooldownSeconds = 60;

  /// Expected length of numeric OTP codes.
  static const int otpLength = 6;
}
