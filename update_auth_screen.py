import re

filepath = r'f:\Utthaan\lib\buyer_section\screens\shared\auth_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Add _handleForgotPassword and _handleOtpLogin
methods_to_add = """
  Future<void> _handleOtpLogin() async {
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
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email address first.'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.sendPasswordResetOtp(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to your email!'), backgroundColor: AppColors.success));
      Navigator.pushNamed(context, AppRouter.buyerOtpVerificationRoute, arguments: {
        'email': email,
        'mode': 'resetPassword',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AuthExceptionHandler.getErrorMessage(e)), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

"""

if '_handleOtpLogin' not in content:
    content = content.replace('  @override\n  Widget build(BuildContext context) {', methods_to_add + '  @override\n  Widget build(BuildContext context) {')

# Replace Forgot Password onPressed
forgot_password_replacement = """
                        onPressed: _handleForgotPassword,
                        style: TextButton.styleFrom(
"""
content = re.sub(r'onPressed: \(\) \{\s*ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(content: Text\(l10n\?\.forgotPasswordUpcoming \?\? \'Password recovery will be available in a future update\.\'\), backgroundColor: AppColors\.primaryLight\),\s*\);\s*\},', 'onPressed: _handleForgotPassword,', content)

# Add OR divider and Sign in with OTP button
buttons_replacement = """
                    // Login Button
                    _buildPrimaryButton(
                      text: l10n?.signInTitle ?? 'Sign In',
                      icon: Icons.arrow_forward,
                      enabled: _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty,
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleOtpLogin,
                      icon: const Icon(Icons.mark_email_unread_outlined),
                      label: const Text('Sign in with OTP'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 24),
"""

if 'Sign in with OTP' not in content:
    # We replace from Login Button to Wrap
    content = re.sub(
        r'// Login Button\s*_buildPrimaryButton\(\s*text: l10n\?\.signInTitle \?\? \'Sign In\',\s*icon: Icons\.arrow_forward,\s*enabled: _emailController\.text\.isNotEmpty && _passwordController\.text\.isNotEmpty,\s*isLoading: _isLoading,\s*onPressed: _handleLogin,\s*\),\s*const SizedBox\(height: 20\),\s*Wrap\(',
        buttons_replacement + '\n                  Wrap(',
        content
    )


with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
