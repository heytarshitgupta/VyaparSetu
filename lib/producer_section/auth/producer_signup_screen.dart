import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/auth_exception_handler.dart';
import '../../core/auth/auth_service.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_top_bar_controls.dart';
import 'services/producer_auth_service.dart';
import 'widgets/producer_auth_text_field.dart';
import 'widgets/producer_otp_input_field.dart';

enum _SignupStage {
  details,
  otpVerification,
}

class ProducerSignupScreen extends StatefulWidget {
  final Future<AuthResponse> Function({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  })? signUpHandler;

  final Future<AuthResponse> Function({
    required String email,
    required String otp,
  })? verifyOtpHandler;

  final Future<void> Function({
    required String email,
  })? resendOtpHandler;

  final Future<String> Function({
    required String fullName,
  })? profileRegistrationHandler;

  final Future<ProducerAuthValidationResult> Function({
    String? fallbackFullName,
  })? accessValidationHandler;

  const ProducerSignupScreen({
    super.key,
    this.signUpHandler,
    this.verifyOtpHandler,
    this.resendOtpHandler,
    this.profileRegistrationHandler,
    this.accessValidationHandler,
  });

  @override
  State<ProducerSignupScreen> createState() => _ProducerSignupScreenState();
}

class _ProducerSignupScreenState extends State<ProducerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  _SignupStage _stage = _SignupStage.details;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isResending = false;

  Timer? _resendTimer;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCooldown([int seconds = 45]) {
    _resendTimer?.cancel();
    setState(() {
      _resendCooldown = seconds;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown > 1) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _resendCooldown = 0;
        });
      }
    });
  }

  String _maskEmail(String email) {
    final trimmed = email.trim();
    final parts = trimmed.split('@');
    if (parts.length != 2) return trimmed;
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 2) {
      return '${username.substring(0, 1)}***@$domain';
    }
    return '${username.substring(0, 2)}***@$domain';
  }

  Future<void> _handleInitiateSignup() async {
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _fullNameController.text.trim();

    try {
      final response = widget.signUpHandler != null
          ? await widget.signUpHandler!(
              email: email,
              password: password,
              data: {'full_name': fullName},
            )
          : await AuthService.instance.signUpWithEmail(
              email: email,
              password: password,
              data: {'full_name': fullName},
            );

      if (!mounted) return;

      // If user is already immediately confirmed (e.g. email confirmation disabled in project),
      // proceed directly with profile registration
      if (response.session != null) {
        await _completeRegistrationAndNavigate(fullName);
        return;
      }

      // Transition to OTP verification stage
      _otpController.clear();
      setState(() {
        _stage = _SignupStage.otpVerification;
        _isLoading = false;
      });
      _startResendCooldown(AuthConstants.emailOtpCooldownSeconds);
    } catch (error) {
      if (!mounted) return;
      final errorMessage = AuthExceptionHandler.getErrorMessage(error);
      _showError(errorMessage);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    final l10n = AppLocalizations.of(context);

    if (otp.length != 6) {
      _showError(l10n?.otpInvalidLength ?? 'Please enter a valid 6-digit code');
      return;
    }

    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final fullName = _fullNameController.text.trim();

    try {
      final response = widget.verifyOtpHandler != null
          ? await widget.verifyOtpHandler!(email: email, otp: otp)
          : await AuthService.instance.verifyEmailOtp(email: email, otp: otp);

      if (!mounted) return;

      if (response.session != null || AuthService.instance.currentSession != null) {
        await _completeRegistrationAndNavigate(fullName);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError(l10n?.otpIncorrectOrExpired ?? 'That code is incorrect or has expired.');
      }
    } catch (error) {
      if (!mounted) return;
      final errorMessage = AuthExceptionHandler.getErrorMessage(error);
      _showError(errorMessage);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCooldown > 0 || _isResending || _isLoading) return;

    final l10n = AppLocalizations.of(context);
    setState(() {
      _isResending = true;
    });

    final email = _emailController.text.trim();

    try {
      if (widget.resendOtpHandler != null) {
        await widget.resendOtpHandler!(email: email);
      } else {
        await AuthService.instance.resendEmailOtp(email: email);
      }

      if (!mounted) return;

      _startResendCooldown(AuthConstants.emailOtpCooldownSeconds);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.otpSentSuccess ?? 'A new 6-digit code has been sent to your email.',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final errorMessage = AuthExceptionHandler.getErrorMessage(error);
      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _completeRegistrationAndNavigate(String fullName) async {
    try {
      // 1. Register Producer Profile via secure database RPC
      if (widget.profileRegistrationHandler != null) {
        await widget.profileRegistrationHandler!(fullName: fullName);
      } else {
        await ProducerAuthService.instance.registerProducerProfile(fullName: fullName);
      }

      // 2. Validate Producer domain access & load producer_profiles
      final validation = widget.accessValidationHandler != null
          ? await widget.accessValidationHandler!(fallbackFullName: fullName)
          : await ProducerAuthService.instance.validateProducerAccess(fallbackFullName: fullName);

      if (!mounted) return;

      if (validation.isSuccess) {
        final onboardingStatus = validation.producerProfile?['onboarding_status']?.toString();
        if (onboardingStatus == 'completed') {
          Navigator.pushReplacementNamed(
            context,
            AppRouter.producerHomeRoute,
          );
        } else {
          // Intended next route: Producer Onboarding (Step 2 in next pass)
          Navigator.pushReplacementNamed(
            context,
            AppRouter.producerOnboardingRoute,
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError(validation.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError(AuthExceptionHandler.getErrorMessage(e));
    }
  }

  void _handleChangeEmail() {
    _resendTimer?.cancel();
    setState(() {
      _stage = _SignupStage.details;
      _otpController.clear();
      _resendCooldown = 0;
      _isLoading = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
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
            if (_stage == _SignupStage.otpVerification) {
              _handleChangeEmail();
            } else if (Navigator.canPop(context)) {
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
              child: _stage == _SignupStage.details
                  ? _buildDetailsForm(theme, l10n)
                  : _buildOtpVerificationView(theme, l10n),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STEP 1 STATE A: DETAILS FORM (Full Name, Email, Password)
  // --------------------------------------------------------------------------
  Widget _buildDetailsForm(ThemeData theme, AppLocalizations? l10n) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('details_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Persona Badge
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

          // Header
          Text(
            l10n?.createYourAccountTitle ?? 'Create Your Account',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.createAccountSupportingCopy ?? 'Start setting up your business on VyaparSetu.',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // 1. Full Name Field
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

          // 2. Email Field
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

          // 3. Password Field
          ProducerAuthTextField(
            controller: _passwordController,
            label: l10n?.password ?? 'Password',
            hint: l10n?.createPasswordHint ?? 'Create a password (min 6 characters)',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleInitiateSignup(),
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
          const SizedBox(height: 28),

          // Primary CTA: Continue
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleInitiateSignup,
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
                          l10n?.continueButton ?? 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 28),

          // Sign In Navigation Link
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
    );
  }

  // --------------------------------------------------------------------------
  // STEP 1 STATE B: OTP VERIFICATION VIEW
  // --------------------------------------------------------------------------
  Widget _buildOtpVerificationView(ThemeData theme, AppLocalizations? l10n) {
    final maskedEmail = _maskEmail(_emailController.text);

    return Column(
      key: const ValueKey('otp_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Security Shield Badge
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n?.verifyYourEmailTitle ?? 'Verify Your Email',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          l10n?.verifyYourEmailTitle ?? 'Verify Your Email',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle with Masked Email
        Text(
          l10n?.verifyYourEmailSubtitle(maskedEmail) ??
              'We sent a 6-digit code to $maskedEmail.',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        // OTP Label
        Text(
          l10n?.enterOtpPrompt ?? 'Enter 6-digit verification code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // 6-Digit OTP Input
        ProducerOtpInputField(
          controller: _otpController,
          enabled: !_isLoading,
          autoFocus: true,
          onCompleted: (val) {
            FocusScope.of(context).unfocus();
          },
        ),
        const SizedBox(height: 28),

        // Primary Action: Verify & Continue
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
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
                        l10n?.verifyAndContinue ?? 'Verify & Continue',
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
        const SizedBox(height: 16),

        // Secondary Actions: Resend Code & Change Email
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            // Resend Code with Cooldown
            TextButton.icon(
              onPressed: (_resendCooldown > 0 || _isResending || _isLoading)
                  ? null
                  : _handleResendOtp,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: _isResending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: Text(
                _resendCooldown > 0
                    ? (l10n?.resendCodeIn(_resendCooldown) ?? 'Resend Code in ${_resendCooldown}s')
                    : (l10n?.resendCode ?? 'Resend Code'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _resendCooldown > 0
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                      : theme.colorScheme.primary,
                ),
              ),
            ),

            // Change Email
            TextButton.icon(
              onPressed: _isLoading ? null : _handleChangeEmail,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: Text(
                l10n?.changeEmail ?? 'Change Email',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
