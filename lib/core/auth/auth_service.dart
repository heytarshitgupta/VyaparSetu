import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _client => SupabaseService.client;

  /// Returns the currently authenticated Supabase user, or null if unauthenticated.
  User? get currentUser => _client.auth.currentUser;

  /// Returns the current active session, or null.
  Session? get currentSession => _client.auth.currentSession;

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

  /// Signs in an existing user with email and password.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return response;
  }

  /// Terminates the current Supabase session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
