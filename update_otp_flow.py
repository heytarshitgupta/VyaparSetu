import os
import re

# 1. Create buyer_signin_email_screen.dart
screen_content = """import 'package:flutter/material.dart';
import '../../core/auth/auth_exception_handler.dart';
import '../../core/auth/auth_service.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../screens/shared/widgets/buyer_auth_text_field.dart';

class BuyerSignInEmailScreen extends StatefulWidget {
  const BuyerSignInEmailScreen({super.key});

  @override
  State<BuyerSignInEmailScreen> createState() => _BuyerSignInEmailScreenState();
}

class _BuyerSignInEmailScreenState extends State<BuyerSignInEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      await AuthService.instance.sendEmailOtp(email);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to your email!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      Navigator.pushReplacementNamed(
        context,
        AppRouter.buyerOtpVerificationRoute,
        arguments: {
          'email': email,
          'mode': 'signIn',
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
        title: Text('Sign In with OTP', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
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
                      'Enter your Email',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We will send a 6-digit verification code to your registered email address.',
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
                      onFieldSubmitted: (_) => _handleSendOtp(),
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
                      text: 'Send OTP',
                      onPressed: _emailController.text.isNotEmpty ? _handleSendOtp : null,
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

with open(r'f:\Utthaan\lib\buyer_section\auth\buyer_signin_email_screen.dart', 'w', encoding='utf-8') as f:
    f.write(screen_content)


# 2. Update app_router.dart
router_path = r'f:\Utthaan\lib\core\routes\app_router.dart'
with open(router_path, 'r', encoding='utf-8') as f:
    router_content = f.read()

# Add route constant
if 'buyerSignInEmailRoute' not in router_content:
    router_content = router_content.replace(
        "static const String buyerResetPasswordRoute = '/buyer_reset_password';",
        "static const String buyerResetPasswordRoute = '/buyer_reset_password';\n  static const String buyerSignInEmailRoute = '/buyer_signin_email';"
    )

# Add import
if 'buyer_signin_email_screen.dart' not in router_content:
    router_content = router_content.replace(
        "import '../../buyer_section/auth/buyer_signup_screen.dart';",
        "import '../../buyer_section/auth/buyer_signup_screen.dart';\nimport '../../buyer_section/auth/buyer_signin_email_screen.dart';"
    )

# Add case
if 'case buyerSignInEmailRoute:' not in router_content:
    router_content = router_content.replace(
        "case buyerResetPasswordRoute:",
        "case buyerSignInEmailRoute:\n        return MaterialPageRoute(builder: (_) => const BuyerSignInEmailScreen());\n      case buyerResetPasswordRoute:"
    )

with open(router_path, 'w', encoding='utf-8') as f:
    f.write(router_content)


# 3. Update auth_screen.dart
auth_screen_path = r'f:\Utthaan\lib\buyer_section\screens\shared\auth_screen.dart'
with open(auth_screen_path, 'r', encoding='utf-8') as f:
    auth_content = f.read()

# Replace _handleOtpLogin implementation
old_handle_otp = """  Future<void> _handleOtpLogin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email address first.'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.sendEmailOtp(email);
      if (!mounted) return;
      Navigator.pushNamed(context, AppRouter.buyerOtpVerificationRoute, arguments: {
        'email': email,
        'mode': 'signIn',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AuthExceptionHandler.getErrorMessage(e)), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }"""

new_handle_otp = """  void _handleOtpLogin() {
    Navigator.pushNamed(context, AppRouter.buyerSignInEmailRoute);
  }"""

# Since the formatting might differ slightly, let's use regex
import re
auth_content = re.sub(
    r'Future<void> _handleOtpLogin\(\) async \{.*?\s*if \(mounted\) setState\(\(\) => _isLoading = false\);\s*\}\s*\}',
    new_handle_otp,
    auth_content,
    flags=re.DOTALL
)

with open(auth_screen_path, 'w', encoding='utf-8') as f:
    f.write(auth_content)

print("Updates applied successfully.")
