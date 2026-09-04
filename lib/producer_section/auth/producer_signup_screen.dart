import 'package:flutter/material.dart';
import '../../core/auth/auth_exception_handler.dart';
import '../../core/auth/auth_service.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_top_bar_controls.dart';
import 'services/producer_auth_service.dart';
import 'widgets/producer_auth_text_field.dart';

class ProducerSignupScreen extends StatefulWidget {
  const ProducerSignupScreen({super.key});

  @override
  State<ProducerSignupScreen> createState() => _ProducerSignupScreenState();
}

class _ProducerSignupScreenState extends State<ProducerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.instance.signUpWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        data: {
          'full_name': _fullNameController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response.session != null) {
        // Register the Producer profile via secure RPC
        await ProducerAuthService.instance.registerProducerProfile(
          fullName: _fullNameController.text,
        );

        // Verify that the Producer profile and producer_profiles record are in place
        final validation = await ProducerAuthService.instance.validateProducerAccess(
          fallbackFullName: _fullNameController.text,
        );

        if (!mounted) return;

        if (validation.isSuccess) {
          final onboardingStatus = validation.producerProfile?['onboarding_status']?.toString();
          if (onboardingStatus == 'completed') {
            Navigator.pushReplacementNamed(
              context,
              AppRouter.producerHomeRoute,
            );
          } else {
            Navigator.pushReplacementNamed(
              context,
              AppRouter.producerOnboardingRoute,
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validation.message),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created. Please verify your email, then sign in to complete Producer setup.',
            ),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      final errorMessage = AuthExceptionHandler.getErrorMessage(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPhoneSignupPlaceholder(AppLocalizations? l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.phoneFeatureUpcoming ?? 'Phone login will be available in the next update.'),
        backgroundColor: AppColors.primaryLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: const [
          AppTopBarControls(),
          SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Persona Tag / Chip
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.highlightAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.highlightAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.handshake_outlined,
                              size: 16,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n?.roleProducerTitle ?? 'I Make & Sell Products',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Heading
                    Text(
                      l10n?.createAccountTitle ?? 'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.createAccountSubtitle ?? 'Start your journey as an artisan producer and reach direct commercial buyers.',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Full Name Field
                    ProducerAuthTextField(
                      controller: _fullNameController,
                      label: l10n?.fullName ?? 'Full Name',
                      hint: l10n?.fullNameHint ?? 'e.g. Ramesh Kumar',
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n?.enterFullName ?? 'Please enter your full name';
                        }
                        if (value.trim().length < 2) {
                          return l10n?.nameTooShort ?? 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Email Field
                    ProducerAuthTextField(
                      controller: _emailController,
                      label: l10n?.emailAddress ?? 'Email Address',
                      hint: l10n?.emailHint ?? 'producer@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n?.enterEmail ?? 'Please enter your email address';
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return l10n?.enterValidEmail ?? 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Password Field
                    ProducerAuthTextField(
                      controller: _passwordController,
                      label: l10n?.password ?? 'Password',
                      hint: l10n?.createPasswordHint ?? 'Create a password (min 6 characters)',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n?.createPassword ?? 'Please create a password';
                        }
                        if (value.length < 6) {
                          return l10n?.passwordTooShort ?? 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Confirm Password Field
                    ProducerAuthTextField(
                      controller: _confirmPasswordController,
                      label: l10n?.confirmPassword ?? 'Confirm Password',
                      hint: l10n?.confirmPasswordHint ?? 'Re-enter your password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSignup(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n?.confirmYourPassword ?? 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return l10n?.passwordsDoNotMatch ?? 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Primary Submit Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l10n?.createAccountTitle ?? 'Create Account',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check_circle_outline, size: 18),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Alternate Auth Method (Phone OTP Placeholder)
                    OutlinedButton.icon(
                      onPressed: () => _showPhoneSignupPlaceholder(l10n),
                      icon: const Icon(Icons.phone_android_outlined, size: 18),
                      label: Text(l10n?.signUpWithPhone ?? 'Sign up with Phone OTP'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                        side: BorderSide(color: theme.dividerColor),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Login Navigation Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n?.alreadyHaveAccount ?? 'Already have an account? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRouter.producerLoginRoute,
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n?.signInTitle ?? 'Sign In',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
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
