import re

filepath = r'f:\Utthaan\lib\core\auth\auth_service.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

new_methods = """
  /// Sends an OTP via email for sign in.
  Future<void> sendEmailOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: false,
    );
  }

  /// Sends a password reset OTP to the email.
  Future<void> sendPasswordResetOtp(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  /// Verifies the OTP sent to the email.
  /// [type] can be OtpType.magiclink (for sign in), OtpType.signup (for signup), or OtpType.recovery (for password reset).
  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String otp,
    required OtpType type,
  }) async {
    return await _client.auth.verifyOTP(
      email: email.trim(),
      token: otp,
      type: type,
    );
  }

  /// Updates the user's password (typically used after verifying a recovery OTP).
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(
      UserAttributes(
        password: newPassword,
      ),
    );
  }
"""

if 'Future<void> sendEmailOtp' not in content:
    # Insert before the last closing brace
    content = content[:content.rfind('}')] + new_methods + '\n}\n'
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Added new methods to AuthService.")
else:
    print("Methods already exist.")
