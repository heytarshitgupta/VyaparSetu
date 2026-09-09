import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthExceptionHandler {
  AuthExceptionHandler._();

  /// Converts Supabase and network errors into clean, user-friendly messages.
  /// Never leaks database queries, stack traces, or internal server errors.
  static String getErrorMessage(dynamic error) {
    if (kDebugMode) {
      debugPrint('### AUTH ERROR: $error');
    }
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
        return 'This email is already registered. Try signing in.';
      }

      if (message.contains('signups not allowed for otp') ||
          message.contains('user not found') ||
          message.contains('user_not_found')) {
        return 'No account found with this email. Try signing up.';
      }

      if (message.contains('same_password') ||
          message.contains('should be different from the old password')) {
        return 'New password must be different from your old password.';
      }

      if (message.contains('token has expired') ||
          message.contains('otp expired') ||
          message.contains('invalid otp') ||
          message.contains('token is invalid') ||
          message.contains('bad_token') ||
          message.contains('invalid token') ||
          message.contains('token_expired') ||
          message.contains('token not found') ||
          message.contains('otp_expired')) {
        return 'That code is incorrect or has expired.';
      }

      if (message.contains('email not confirmed') ||
          message.contains('email_not_confirmed')) {
        return 'Please verify your email address before signing in.';
      }

      if (message.contains('over_email_send_rate_limit') ||
          (message.contains('rate limit') && message.contains('resend'))) {
        return 'We couldn\'t send a new code. Please wait a moment and try again.';
      }

      if (message.contains('rate limit') ||
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
      
      if (message.contains('provider is not configured') || message.contains('sms provider')) {
        return 'SMS Provider not configured in Supabase. Add a Test Phone Number in your dashboard to test this feature.';
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
