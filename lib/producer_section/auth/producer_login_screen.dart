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

enum _LoginStage {
  passwordLogin,
  otpEmailEntry,
  otpVerification,
  forgotPasswordEmail,
  forgotPasswordOtp,
  createNewPassword,
}

class ProducerLoginScreen extends StatefulWidget {
  final Future<AuthResponse> Function({
    required String email,
    required String password,
  })? signInHandler;

  final Future<void> Function({
    required String email,
  })? signInWithOtpHandler;

  final Future<AuthResponse> Function({
    required String email,
    required String otp,
  })? verifyLoginOtpHandler;

  final Future<void> Function({
    required String email,
  })? sendRecoveryOtpHandler;

  final Future<AuthResponse> Function({
    required String email,
    required String otp,
  })? verifyRecoveryOtpHandler;

  final Future<UserResponse> Function({
    required String newPassword,
  })? updatePasswordHandler;

  final Future<ResendResponse> Function({
    required String email,
    required OtpType type,
  })? resendOtpHandler;

  final Future<ProducerAuthValidationResult> Function({
    String? fallbackFullName,
  })? accessValidationHandler;

  const ProducerLoginScreen({
    super.key,
    this.signInHandler,
    this.signInWithOtpHandler,
    this.verifyLoginOtpHandler,
    this.sendRecoveryOtpHandler,
    this.verifyRecoveryOtpHandler,
    this.updatePasswordHandler,
    this.resendOtpHandler,
    this.accessValidationHandler,
  });

  @override
  State<ProducerLoginScreen> createState() => _ProducerLoginScreenState();
}

class _ProducerLoginScreenState extends State<ProducerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _LoginStage _stage = _LoginStage.passwordLogin;

  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendCooldown([int seconds = AuthConstants.emailOtpCooldownSeconds]) {
    _resendTimer?.cancel();
    setState(() {
      _resendCooldown = seconds;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() {
          _resendCooldown = 0;
        });
      } else {
        setState(() {
          _resendCooldown--;
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // FLOW A: NORMAL EMAIL / PASSWORD LOGIN
  // --------------------------------------------------------------------------
  Future<void> _handlePasswordLogin() async {
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final response = widget.signInHandler != null
          ? await widget.signInHandler!(email: email, password: password)
          : await AuthService.instance.signInWithEmail(
              email: email,
              password: password,
            );

      if (!mounted) return;

      if (response.user != null || response.session != null) {
        await _validateAndNavigate();
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError('Sign in failed. Please check your credentials.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError(AuthExceptionHandler.getErrorMessage(e));
    }
  }

  // --------------------------------------------------------------------------
  // FLOW B: SIGN IN WITH EMAIL OTP
  // --------------------------------------------------------------------------
  Future<void> _handleSendLoginOtp() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.signInWithOtpHandler != null) {
        await widget.signInWithOtpHandler!(email: email);
      } else {
        await AuthService.instance.signInWithEmailOtp(email: email);
      }

      if (!mounted) return;

      _otpController.clear();
      setState(() {
        _stage = _LoginStage.otpVerification;
        _isLoading = false;
      });
      _startResendCooldown(AuthConstants.emailOtpCooldownSeconds);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError(AuthExceptionHandler.getErrorMessage(e));
    }
  }

  Future<void> _handleVerifyLoginOtp() async {
    final otp = _otpController.text.trim();
    final l10n = AppLocalizations.of(context);

    if (otp.length != AuthConstants.otpLength) {
      _showError(l10n?.otpInvalidLength ?? 'Please enter a valid 6-digit code');
      return;
    }

    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();

    try {
      final response = widget.verifyLoginOtpHandler != null
          ? await widget.verifyLoginOtpHandler!(email: email, otp: otp)
          : await AuthService.instance.verifyEmailLoginOtp(email: email, otp: otp);

      if (!mounted) return;

      if (response.session != null || AuthService.instance.currentSession != null) {
        await _validateAndNavigate();
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError(l10n?.otpIncorrectOrExpired ?? 'That code is incorrect or has expired.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError(AuthExceptionHandler.getErrorMessage(e));
    }
  }

  // --------------------------------------------------------------------------
  // FLOW C: FORGOT PASSWORD & RECOVERY OTP
  // --------------------------------------------------------------------------
  Future<void> _handleSendRecoveryOtp() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final l10n = AppLocalizations.of(context);

    try {
      if (widget.sendRecoveryOtpHandler != null) {
        await widget.sendRecoveryOtpHandler!(email: email);
      } else {
        await AuthService.instance.sendPasswordRecoveryOtp(email: email);
      }

      if (!mounted) return;

      // Account enumeration protection:
      // When the recovery request succeeds operationally, show the neutral message
      // and proceed to OTP entry.
      _otpController.clear();
      setState(() {
        _stage = _LoginStage.forgotPasswordOtp;
        _isLoading = false;
      });
      _startResendCooldown(AuthConstants.emailOtpCooldownSeconds);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.recoveryEmailSentNeutralNotice ??
                'If an account exists for this email, we\'ve sent a verification code.',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      // Operational failure (e.g. rate limit, offline, server error)
      _showError(AuthExceptionHandler.getErrorMessage(e));
    }
  }

  Future<void> _handleVerifyRecoveryOtp() async {
    final otp = _otpController.text.trim();
    final l10n = AppLocalizations.of(context);

    if (otp.length != AuthConstants.otpLength) {
      _showError(l10n?.otpInvalidLength ?? 'Please enter a valid 6-digit code');
      return;
    }

    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();

    try {
      final response = widget.verifyRecoveryOtpHandler != null
          ? await widget.verifyRecoveryOtpHandler!(email: email, otp: otp)
          : await AuthService.instance.verifyRecoveryOtp(email: email, otp: otp);

      if (!mounted) return;

      if (response.session != null || AuthService.instance.currentSession != null) {
        _resendTimer?.cancel();
        setState(() {
          _stage = _LoginStage.createNewPassword;
          _isLoading = false;
          _resendCooldown = 0;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError(l10n?.otpIncorrectOrExpired ?? 'That code is incorrect or has expired.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError(AuthExceptionHandler.getErrorMessage(e));
    }
  }

  Future<void> _handleUpdatePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final l10n = AppLocalizations.of(context);

    if (newPassword.isEmpty) {
      _showError(l10n?.enterPassword ?? 'Please enter your password');
      return;
    }

    if (newPassword.length < 6) {
      _showError(l10n?.passwordTooShort ?? 'Password must be at least 6 characters');
      return;
    }

    if (newPassword != confirmPassword) {
      _showError(l10n?.passwordsDoNotMatch ?? 'Passwords do not match');
      return;
    }

    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.updatePasswordHandler != null) {
        await widget.updatePasswordHandler!(newPassword: newPassword);
      } else {
        await AuthService.instance.updatePassword(newPassword: newPassword);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.passwordUpdatedSuccess ?? 'Your password has been updated.',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );

      // Inspect active session state after password update
      if (AuthService.instance.currentSession != null) {
        await _validateAndNavigate();
      } else {
        // Return to login stage with updated password
        setState(() {
          _stage = _LoginStage.passwordLogin;
          _isLoading = false;
          _passwordController.text = newPassword;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError(AuthExceptionHandler.getErrorMessage(e));
    }
  }

  // --------------------------------------------------------------------------
  // RESEND OTP DISPATCHER
  // --------------------------------------------------------------------------
  Future<void> _handleResendOtp(OtpType type) async {
    if (_resendCooldown > 0 || _isResending || _isLoading) return;

    final l10n = AppLocalizations.of(context);
    setState(() {
      _isResending = true;
    });

    final email = _emailController.text.trim();

    try {
      if (type == OtpType.recovery) {
        if (widget.sendRecoveryOtpHandler != null) {
          await widget.sendRecoveryOtpHandler!(email: email);
        } else {
          await AuthService.instance.sendPasswordRecoveryOtp(email: email);
        }
      } else {
        if (widget.resendOtpHandler != null) {
          await widget.resendOtpHandler!(email: email, type: type);
        } else {
          await AuthService.instance.resendEmailOtp(email: email, type: type);
        }
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

  Future<void> _safeSignOut() async {
    try {
      if (AuthService.instance.currentUser != null || AuthService.instance.currentSession != null) {
        await AuthService.instance.signOut();
      }
    } catch (_) {
      // Gracefully ignore in mock/test environments
    }
  }

  // --------------------------------------------------------------------------
  // PRODUCER AUTHORIZATION & ROUTING
  // --------------------------------------------------------------------------
  Future<void> _validateAndNavigate() async {
    try {
      final validation = widget.accessValidationHandler != null
          ? await widget.accessValidationHandler!()
          : await ProducerAuthService.instance.validateProducerAccess();

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
        // Unauthorized (e.g. buyer or admin account) -> signed out safely
        await _safeSignOut();
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        _showError(validation.message);
      }
    } catch (e) {
      await _safeSignOut();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError(AuthExceptionHandler.getErrorMessage(e));
    }
  }

  void _resetToPasswordLogin() {
    _resendTimer?.cancel();
    setState(() {
      _stage = _LoginStage.passwordLogin;
      _otpController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _resendCooldown = 0;
      _isLoading = false;
    });
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
            if (_stage != _LoginStage.passwordLogin) {
              _resetToPasswordLogin();
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
              child: _buildCurrentStageView(theme, l10n),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStageView(ThemeData theme, AppLocalizations? l10n) {
    switch (_stage) {
      case _LoginStage.passwordLogin:
        return _buildPasswordLoginForm(theme, l10n);
      case _LoginStage.otpEmailEntry:
        return _buildOtpEmailEntryView(theme, l10n);
      case _LoginStage.otpVerification:
        return _buildOtpVerificationView(theme, l10n);
      case _LoginStage.forgotPasswordEmail:
        return _buildForgotPasswordEmailView(theme, l10n);
      case _LoginStage.forgotPasswordOtp:
        return _buildForgotPasswordOtpView(theme, l10n);
      case _LoginStage.createNewPassword:
        return _buildCreateNewPasswordView(theme, l10n);
    }
  }

  // --------------------------------------------------------------------------
  // STAGE 1: PASSWORD LOGIN FORM
  // --------------------------------------------------------------------------
  Widget _buildPasswordLoginForm(ThemeData theme, AppLocalizations? l10n) {
    return Form(
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
                    Icons.storefront_outlined,
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
            l10n?.signInTitle ?? 'Sign In',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.signInSubtitle ?? 'Sign in to manage your products, view buyer needs, and track orders.',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

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
            hint: l10n?.passwordHint ?? 'Enter your password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handlePasswordLogin(),
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
                return l10n?.enterPassword ?? 'Please enter your password';
              }
              if (value.length < 6) {
                return l10n?.passwordTooShort ?? 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _stage = _LoginStage.forgotPasswordEmail;
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n?.forgotPassword ?? 'Forgot Password?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Primary Submit Button: Sign In
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handlePasswordLogin,
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
                          l10n?.signInTitle ?? 'Sign In',
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
          const SizedBox(height: 20),

          // OR Divider
          Row(
            children: [
              Expanded(child: Divider(color: theme.dividerColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n?.orDivider ?? 'OR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Expanded(child: Divider(color: theme.dividerColor)),
            ],
          ),
          const SizedBox(height: 20),

          // Alternate Auth Method: Sign in with Email OTP
          OutlinedButton.icon(
            onPressed: () {
              final email = _emailController.text.trim();
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (email.isNotEmpty && emailRegex.hasMatch(email)) {
                _handleSendLoginOtp();
              } else {
                setState(() {
                  _stage = _LoginStage.otpEmailEntry;
                });
              }
            },
            icon: const Icon(Icons.mail_lock_outlined, size: 18),
            label: Text(l10n?.signInWithEmailOtp ?? 'Sign in with OTP'),
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

          // Signup Navigation Link
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n?.newHere ?? 'New here? ',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.producerSignupRoute);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n?.createAccountTitle ?? 'Create Account',
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
  // STAGE 2: OTP EMAIL ENTRY
  // --------------------------------------------------------------------------
  Widget _buildOtpEmailEntryView(ThemeData theme, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.signInWithEmailOtp ?? 'Sign in with OTP',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your registered email to receive a 6-digit login code.',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        ProducerAuthTextField(
          controller: _emailController,
          label: l10n?.emailAddress ?? 'Email Address',
          hint: l10n?.emailHint ?? 'producer@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleSendLoginOtp(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSendLoginOtp,
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
                : const Text(
                    'Send Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _resetToPasswordLogin,
            child: const Text('Back to Password Login'),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // STAGE 3: OTP VERIFICATION (LOGIN)
  // --------------------------------------------------------------------------
  Widget _buildOtpVerificationView(ThemeData theme, AppLocalizations? l10n) {
    final maskedEmail = _maskEmail(_emailController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                Icon(Icons.mark_email_read_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  l10n?.checkYourEmailTitle ?? 'Check Your Email',
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
        Text(
          l10n?.checkYourEmailTitle ?? 'Check Your Email',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.checkYourEmailSubtitle(maskedEmail) ??
              'We sent a verification code to $maskedEmail',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          l10n?.enterOtpPrompt ?? 'Enter 6-digit verification code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ProducerOtpInputField(
          controller: _otpController,
          enabled: !_isLoading,
          autoFocus: true,
          onCompleted: (_) {
            FocusScope.of(context).unfocus();
          },
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyLoginOtp,
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
                : Text(
                    l10n?.verifyAndSignIn ?? 'Verify & Sign In',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: (_resendCooldown > 0 || _isResending || _isLoading)
                  ? null
                  : () => _handleResendOtp(OtpType.email),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: _isResending
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
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
            TextButton.icon(
              onPressed: _isLoading ? null : _resetToPasswordLogin,
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

  // --------------------------------------------------------------------------
  // STAGE 4: FORGOT PASSWORD EMAIL ENTRY
  // --------------------------------------------------------------------------
  Widget _buildForgotPasswordEmailView(ThemeData theme, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.forgotPasswordTitle ?? 'Reset Your Password',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.forgotPasswordSubtitle ??
              'Enter your email address to receive a recovery code.',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        ProducerAuthTextField(
          controller: _emailController,
          label: l10n?.emailAddress ?? 'Email Address',
          hint: l10n?.emailHint ?? 'producer@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleSendRecoveryOtp(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSendRecoveryOtp,
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
                : Text(
                    l10n?.sendRecoveryCode ?? 'Send Recovery Code',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _resetToPasswordLogin,
            child: const Text('Back to Sign In'),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // STAGE 5: FORGOT PASSWORD OTP VERIFICATION
  // --------------------------------------------------------------------------
  Widget _buildForgotPasswordOtpView(ThemeData theme, AppLocalizations? l10n) {
    final maskedEmail = _maskEmail(_emailController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                Icon(Icons.shield_outlined, size: 16, color: theme.colorScheme.primary),
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
        Text(
          l10n?.enterRecoveryCodeSubtitle(maskedEmail) ??
              'Enter the verification code sent to $maskedEmail',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          l10n?.enterOtpPrompt ?? 'Enter 6-digit verification code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ProducerOtpInputField(
          controller: _otpController,
          enabled: !_isLoading,
          autoFocus: true,
          onCompleted: (_) {
            FocusScope.of(context).unfocus();
          },
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyRecoveryOtp,
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
                : Text(
                    l10n?.verifyCode ?? 'Verify Code',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: (_resendCooldown > 0 || _isResending || _isLoading)
                  ? null
                  : () => _handleResendOtp(OtpType.recovery),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: _isResending
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
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
            TextButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _stage = _LoginStage.forgotPasswordEmail;
                      });
                    },
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

  // --------------------------------------------------------------------------
  // STAGE 6: CREATE NEW PASSWORD
  // --------------------------------------------------------------------------
  Widget _buildCreateNewPasswordView(ThemeData theme, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.createNewPasswordTitle ?? 'Create New Password',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n?.createNewPasswordSubtitle ??
              'Create a new strong password for your account.',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        ProducerAuthTextField(
          controller: _newPasswordController,
          label: l10n?.newPassword ?? 'New Password',
          hint: l10n?.newPasswordHint ?? 'Enter new password (min 6 characters)',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureNewPassword,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            onPressed: () {
              setState(() {
                _obscureNewPassword = !_obscureNewPassword;
              });
            },
          ),
        ),
        const SizedBox(height: 18),
        ProducerAuthTextField(
          controller: _confirmPasswordController,
          label: l10n?.confirmPassword ?? 'Confirm Password',
          hint: l10n?.confirmPasswordHint ?? 'Re-enter your password',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleUpdatePassword(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleUpdatePassword,
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
                : Text(
                    l10n?.updatePassword ?? 'Update Password',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
