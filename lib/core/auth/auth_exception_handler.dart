import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthExceptionHandler {
  AuthExceptionHandler._();

  /// Converts Supabase and network errors into clean, user-friendly messages.
  /// Never leaks database queries, stack traces, or internal server errors.
  static String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      final statusCode = error.statusCode;

      if (message.contains('invalid login credentials') ||
          message.contains('invalid_grant') ||
          message.contains('invalid credentials')) {
        return 'Email or password is incorrect.';
      }

      if (message.contains('user already registered') ||
          message.contains('already exists') ||
          message.contains('user_already_exists')) {
        return 'An account with this email already exists. Please log in.';
      }

      if (message.contains('email not confirmed') ||
          message.contains('email_not_confirmed')) {
        return 'Please verify your email address before signing in.';
      }

      if (message.contains('rate limit') ||
          message.contains('over_email_send_rate_limit') ||
          statusCode == '429') {
        return 'Too many attempts. Please wait a few moments and try again.';
      }

      if (message.contains('password should be at least') ||
          message.contains('weak_password')) {
        return 'Password is too weak. Please use at least 6 characters.';
      }

      if (message.contains('invalid email') ||
          message.contains('unable to validate email address')) {
        return 'Please enter a valid email address.';
      }

      return 'Authentication failed. Please check your details and try again.';
    }

    if (error is SocketException) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('network') ||
        errStr.contains('failed to connect') ||
        errStr.contains('clientexception')) {
      return 'Unable to connect. Please check your internet connection.';
    }

    return 'An unexpected error occurred. Please try again later.';
  }
}
