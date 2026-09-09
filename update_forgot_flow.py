import os
import re

# 1. Create buyer_forgot_password_email_screen.dart
screen_content = """import 'package:flutter/material.dart';
import '../../core/auth/auth_exception_handler.dart';
import '../../core/auth/auth_service.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../screens/shared/widgets/buyer_auth_text_field.dart';

class BuyerForgotPasswordEmailScreen extends StatefulWidget {
  const BuyerForgotPasswordEmailScreen({super.key});

  @override
  State<BuyerForgotPasswordEmailScreen> createState() => _BuyerForgotPasswordEmailScreenState();
}

class _BuyerForgotPasswordEmailScreenState extends State<BuyerForgotPasswordEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetOtp() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      await AuthService.instance.sendPasswordResetOtp(email);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset OTP sent to your email!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      Navigator.pushReplacementNamed(
        context,
        AppRouter.buyerOtpVerificationRoute,
        arguments: {
          'email': email,
          'mode': 'resetPassword',
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthExceptionHandler.getErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Forgot Password', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your registered email address and we will send you an OTP to reset your password.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    BuyerAuthTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'Enter your registered email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSendResetOtp(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: 'Send Reset OTP',
                      onPressed: _emailController.text.isNotEmpty ? _handleSendResetOtp : null,
                      isLoading: _isLoading,
                      icon: Icons.send_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
"""

with open(r'f:\Utthaan\lib\buyer_section\auth\buyer_forgot_password_email_screen.dart', 'w', encoding='utf-8') as f:
    f.write(screen_content)


# 2. Update app_router.dart
router_path = r'f:\Utthaan\lib\core\routes\app_router.dart'
with open(router_path, 'r', encoding='utf-8') as f:
    router_content = f.read()

# Add route constant
if 'buyerForgotPasswordEmailRoute' not in router_content:
    router_content = router_content.replace(
        "static const String buyerResetPasswordRoute = '/buyer_reset_password';",
        "static const String buyerForgotPasswordEmailRoute = '/buyer_forgot_password_email';\n    static const String buyerResetPasswordRoute = '/buyer_reset_password';"
    )

# Add import
if 'buyer_forgot_password_email_screen.dart' not in router_content:
    router_content = router_content.replace(
        "import '../../buyer_section/auth/buyer_signup_screen.dart';",
        "import '../../buyer_section/auth/buyer_signup_screen.dart';\nimport '../../buyer_section/auth/buyer_forgot_password_email_screen.dart';"
    )

# Add case
if 'case buyerForgotPasswordEmailRoute:' not in router_content:
    router_content = router_content.replace(
        "case buyerResetPasswordRoute:",
        "case buyerForgotPasswordEmailRoute:\n        return MaterialPageRoute(settings: settings, builder: (_) => const BuyerForgotPasswordEmailScreen());\n      case buyerResetPasswordRoute:"
    )

with open(router_path, 'w', encoding='utf-8') as f:
    f.write(router_content)


# 3. Update auth_screen.dart
auth_screen_path = r'f:\Utthaan\lib\buyer_section\screens\shared\auth_screen.dart'
with open(auth_screen_path, 'r', encoding='utf-8') as f:
    auth_content = f.read()

# Replace _handleForgotPassword implementation
new_handle_forgot = """  void _handleForgotPassword() {
    Navigator.pushNamed(context, AppRouter.buyerForgotPasswordEmailRoute);
  }"""

import re
auth_content = re.sub(
    r'Future<void> _handleForgotPassword\(\) async \{.*?\s*if \(mounted\) setState\(\(\) => _isLoading = false\);\s*\}\s*\}',
    new_handle_forgot,
    auth_content,
    flags=re.DOTALL
)

with open(auth_screen_path, 'w', encoding='utf-8') as f:
    f.write(auth_content)

print("Updates applied successfully.")
