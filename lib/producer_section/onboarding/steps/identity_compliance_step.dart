import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../verification/producer_verification_service.dart';
import '../producer_onboarding_provider.dart';
import '../widgets/verification_status_badge.dart';

class IdentityComplianceStep extends StatefulWidget {
  final ProducerOnboardingProvider provider;
  final ProducerVerificationService? verificationService;

  const IdentityComplianceStep({
    super.key,
    required this.provider,
    this.verificationService,
  });

  @override
  State<IdentityComplianceStep> createState() => _IdentityComplianceStepState();
}

class _IdentityComplianceStepState extends State<IdentityComplianceStep> {
  late final TextEditingController _panController;
  late final TextEditingController _panNameController;
  DateTime? _selectedDob;

  bool _isVerifying = false;
  bool _isVerified = false;
  String? _maskedPan;
  String? _panLocalError;
  String? _panLocalSuccessInfo;
  VerificationBadgeState _badgeState = VerificationBadgeState.notVerified;

  static final RegExp _panFormatRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

  // GST State
  late bool _isGstRegistered;
  late final TextEditingController _gstinController;
  String? _gstinError;
  String? _gstinInfoMessage;

  static final RegExp _gstinFormatRegex =
      RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');

  @override
  void initState() {
    super.initState();
    // Raw PAN is transient and strictly kept in the local controller
    _panController = TextEditingController();
    // Prefill Name as per PAN from the Producer's display full name
    _panNameController = TextEditingController(text: widget.provider.fullName);

    // GST Initialization
    _isGstRegistered = widget.provider.gstRegistered;
    _gstinController = TextEditingController(text: widget.provider.gstin);

    // If already verified from backend profile
    final existingPanStatus = widget.provider.producerProfile?['pan_verification_status'];
    final existingLast4 = widget.provider.producerProfile?['pan_last4'];
    if (existingPanStatus == 'verified' && existingLast4 != null) {
      _isVerified = true;
      _maskedPan = '******$existingLast4';
      _badgeState = VerificationBadgeState.verified;
    }
  }

  @override
  void dispose() {
    _panController.dispose();
    _panNameController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth(BuildContext context) async {
    if (_isVerified || _isVerifying) return;

    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth as on PAN',
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _panLocalError = null;
        _panLocalSuccessInfo = null;
        if (_badgeState == VerificationBadgeState.couldNotVerify) {
          _badgeState = VerificationBadgeState.notVerified;
        }
      });
    }
  }

  Future<void> _handleVerifyPan() async {
    // Guard against duplicate taps
    if (_isVerifying || _isVerified) return;

    final trimmedPan = _panController.text.trim().toUpperCase();
    final trimmedName = _panNameController.text.trim();

    setState(() {
      _panLocalSuccessInfo = null;
      _panLocalError = null;
    });

    // 1. Client format validations
    if (trimmedPan.isEmpty) {
      setState(() {
        _panLocalError = 'Please enter your 10-character PAN number.';
        _badgeState = VerificationBadgeState.couldNotVerify;
      });
      return;
    }

    if (!_panFormatRegex.hasMatch(trimmedPan)) {
      setState(() {
        _panLocalError = 'Please enter a valid 10-character PAN (e.g. ABCDE1234F).';
        _badgeState = VerificationBadgeState.couldNotVerify;
      });
      return;
    }

    if (trimmedName.isEmpty) {
      setState(() {
        _panLocalError = 'Please enter your name as per PAN.';
        _badgeState = VerificationBadgeState.couldNotVerify;
      });
      return;
    }

    if (trimmedName.length < 2 || trimmedName.length > 120) {
      setState(() {
        _panLocalError = 'Name as per PAN must be between 2 and 120 characters.';
        _badgeState = VerificationBadgeState.couldNotVerify;
      });
      return;
    }

    if (_selectedDob == null) {
      setState(() {
        _panLocalError = 'Please select your Date of Birth as on PAN.';
        _badgeState = VerificationBadgeState.couldNotVerify;
      });
      return;
    }

    if (_selectedDob!.isAfter(DateTime.now())) {
      setState(() {
        _panLocalError = 'Date of Birth cannot be in the future.';
        _badgeState = VerificationBadgeState.couldNotVerify;
      });
      return;
    }

    // 2. Begin simulated verification workflow
    setState(() {
      _isVerifying = true;
      _badgeState = VerificationBadgeState.checking;
    });

    final verifier = widget.verificationService ?? ProducerVerificationService.instance;
    final result = await verifier.verifyPan(
      pan: trimmedPan,
      nameAsPerPan: trimmedName,
      dateOfBirth: _selectedDob!,
    );

    if (!mounted) return;

    if (result.success && (result.status == 'verified' || result.status == 'already_verified')) {
      // SUCCESS: Clear raw PAN from memory immediately; retain only masked PAN
      _panController.clear();
      setState(() {
        _isVerifying = false;
        _isVerified = true;
        _badgeState = VerificationBadgeState.verified;
        _maskedPan = result.maskedPan ?? ('******${result.panLast4 ?? trimmedPan.substring(6)}');
        _panLocalError = null;
        _panLocalSuccessInfo = result.message.isNotEmpty
            ? result.message
            : 'PAN verified successfully in demo environment.';
      });
    } else {
      // FAILURE / REJECTION: Never store raw PAN
      setState(() {
        _isVerifying = false;
        _badgeState = VerificationBadgeState.couldNotVerify;
        _panLocalError = result.message.isNotEmpty
            ? result.message
            : 'PAN could not be verified. Please check details and try again.';
        _panLocalSuccessInfo = null;
      });
    }
  }

  void _handleResetPan() {
    setState(() {
      _isVerified = false;
      _maskedPan = null;
      _badgeState = VerificationBadgeState.notVerified;
      _panLocalError = null;
      _panLocalSuccessInfo = null;
      _panController.clear();
    });
  }

  void _showAadhaarInfoDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.fingerprint, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                l10n?.aadhaarVerification ?? 'Aadhaar Verification',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            l10n?.aadhaarDialogContent ??
                'Aadhaar verification will be available through an authorized verification service. It is not enabled in this prototype.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              key: const Key('producer_onboarding_aadhaar_dialog_ok_button'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                l10n?.gotIt ?? 'Got It',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleGstSelection(bool registered) {
    setState(() {
      _isGstRegistered = registered;
      _gstinError = null;
      _gstinInfoMessage = null;
      widget.provider.setGstRegistered(registered);
      if (!registered) {
        _gstinController.clear();
      }
    });
  }

  void _handleVerifyGstin() {
    final trimmed = _gstinController.text.trim().toUpperCase();
    setState(() {
      _gstinError = null;
      _gstinInfoMessage = null;
    });

    if (trimmed.isEmpty) {
      setState(() {
        _gstinError = 'Please enter your 15-character GSTIN.';
      });
      return;
    }

    if (trimmed.length != 15 || !_gstinFormatRegex.hasMatch(trimmed)) {
      setState(() {
        _gstinError =
            'Please enter a valid 15-character GSTIN (e.g. 07AAAAA0000A1Z5).';
      });
      return;
    }

    // Valid format: update draft gstin in provider
    widget.provider.setGstin(trimmed);

    // Provide informational feedback (prototype does NOT fake verification)
    setState(() {
      _gstinInfoMessage = 'GST verification integration will be added next.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n?.step4Header ?? 'Identity & Compliance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            l10n?.step4Description ?? 'Verify your details to build trust with buyers.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Prototype Subtle Disclosure Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n?.demoDisclosure ??
                        'Demo verification environment • Verification is simulated in this prototype.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ------------------------------------------------------------------
          // 1. PAN VERIFICATION CARD (ACTIVE)
          // ------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isVerified
                    ? Colors.green.shade300
                    : theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _isVerified ? Icons.verified : Icons.credit_card,
                      size: 22,
                      color: _isVerified ? Colors.green.shade700 : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isVerified
                                ? (l10n?.panVerified ?? 'PAN Verified')
                                : (l10n?.panVerification ?? 'PAN Verification'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isVerified
                                ? (l10n?.verifiedInDemoEnvironment ??
                                    'Verified in demo verification environment')
                                : (l10n?.secureIdentityVerification ??
                                    'Secure identity verification'),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    VerificationStatusBadge(state: _badgeState),
                  ],
                ),
                const SizedBox(height: 18),

                // Error banner (e.g. Could not verify)
                if (_panLocalError != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _panLocalError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Success Info banner
                if (_panLocalSuccessInfo != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _panLocalSuccessInfo!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ------------------------------------------------------------
                // STATE: VERIFIED (Masked presentation, Raw PAN hidden)
                // ------------------------------------------------------------
                if (_isVerified) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n?.verifiedPan ?? 'Verified PAN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _handleResetPan,
                              icon: const Icon(Icons.edit, size: 14),
                              label: Text(
                                l10n?.editDetails ?? 'Edit Details',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _maskedPan ?? '******XXXX',
                          key: const Key('producer_onboarding_masked_pan_text'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _panNameController.text.trim(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n?.panSecurityNote ??
                                'Your PAN details are securely verified. Plaintext PAN is never stored.',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // ------------------------------------------------------------
                  // STATE: EDITABLE FORM (Unverified / Failed)
                  // ------------------------------------------------------------
                  Text(
                    l10n?.panNumberLabel ?? 'PAN Number *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('producer_onboarding_pan_field'),
                    controller: _panController,
                    enabled: !_isVerifying,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      LengthLimitingTextInputFormatter(10),
                      _UpperCaseTextFormatter(),
                    ],
                    onChanged: (_) {
                      if (_panLocalError != null || _panLocalSuccessInfo != null) {
                        setState(() {
                          _panLocalError = null;
                          _panLocalSuccessInfo = null;
                          _badgeState = VerificationBadgeState.notVerified;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: l10n?.panNumberHint ?? 'ABCDE1234F',
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      helperText: l10n?.panNumberHelper ?? '10-character alphanumeric PAN',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name as per PAN Input
                  Text(
                    l10n?.nameAsPerPanLabel ?? 'Name as per PAN *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('producer_onboarding_pan_name_field'),
                    controller: _panNameController,
                    enabled: !_isVerifying,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) {
                      if (_panLocalError != null || _panLocalSuccessInfo != null) {
                        setState(() {
                          _panLocalError = null;
                          _panLocalSuccessInfo = null;
                          _badgeState = VerificationBadgeState.notVerified;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: l10n?.nameAsPerPanHint ?? 'Enter name as shown on PAN card',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      helperText: l10n?.nameAsPerPanHelper ?? 'Must match official PAN records',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth Input
                  Text(
                    l10n?.dobLabel ?? 'Date of Birth *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    key: const Key('producer_onboarding_pan_dob_button'),
                    onTap: _isVerifying ? null : () => _pickDateOfBirth(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDob != null
                                  ? '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}'
                                  : (l10n?.selectDobHint ?? 'Select Date of Birth (DD/MM/YYYY)'),
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedDob != null
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: _selectedDob != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Privacy Shield Note
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n?.panPrivacyShield ??
                                'Your PAN number is used only for verification and is not stored in plain text.',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Verify PAN Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const Key('producer_onboarding_verify_pan_button'),
                      onPressed: _isVerifying ? null : _handleVerifyPan,
                      icon: _isVerifying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        _isVerifying
                            ? (l10n?.checkingDetails ?? 'Checking Details...')
                            : _badgeState == VerificationBadgeState.couldNotVerify
                                ? (l10n?.tryAgain ?? 'Try Again')
                                : (l10n?.verifyPan ?? 'Verify PAN'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ------------------------------------------------------------------
          // 2. AADHAAR VERIFICATION CARD
          // ------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.fingerprint,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.aadhaarVerification ?? 'Aadhaar Verification',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n?.aadhaarSubtitle ??
                                'Identity verification via authorized service',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const VerificationStatusBadge(
                      state: VerificationBadgeState.notVerified,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.aadhaarDescription ??
                      'Verify your identity using Aadhaar. Fast, secure, and helps build trust with commercial buyers.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('producer_onboarding_verify_aadhaar_button'),
                    onPressed: _showAadhaarInfoDialog,
                    icon: const Icon(Icons.verified_user_outlined, size: 18),
                    label: Text(
                      l10n?.verifyAadhaar ?? 'Verify Aadhaar',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ------------------------------------------------------------------
          // 3. GST REGISTRATION CARD
          // ------------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.gstRegistration ?? 'GST Registration',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isGstRegistered
                                ? (l10n?.gstDeclared ?? 'Declared GST registration')
                                : (l10n?.gstStatusSubtitle ??
                                    'Business tax registration status'),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    VerificationStatusBadge(
                      state: VerificationBadgeState.notVerified,
                      customLabel: _isGstRegistered
                          ? (l10n?.badgeNotVerified ?? 'Not Verified')
                          : (l10n?.badgeNotRegistered ?? 'Not Registered'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  l10n?.areYouGstRegistered ?? 'Are you registered for GST? *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                // Yes / No options
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        key: const Key('producer_onboarding_gst_no_option'),
                        onTap: () => _handleGstSelection(false),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isGstRegistered
                                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                : theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !_isGstRegistered
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                              width: !_isGstRegistered ? 1.5 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n?.no ?? 'No',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: !_isGstRegistered
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        key: const Key('producer_onboarding_gst_yes_option'),
                        onTap: () => _handleGstSelection(true),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isGstRegistered
                                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                : theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isGstRegistered
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                              width: _isGstRegistered ? 1.5 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n?.yes ?? 'Yes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isGstRegistered
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (!_isGstRegistered) ...[
                  // Simple informational state for No
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n?.gstNotRegisteredNotice ??
                                'GST not registered. Micro-producers below registration thresholds can continue without GST.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // If YES: Show GSTIN field
                  Text(
                    l10n?.gstinNumberLabel ?? 'GSTIN Number *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('producer_onboarding_gstin_field'),
                    controller: _gstinController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      LengthLimitingTextInputFormatter(15),
                      _UpperCaseTextFormatter(),
                    ],
                    onChanged: (val) {
                      widget.provider.setGstin(val);
                      if (_gstinError != null || _gstinInfoMessage != null) {
                        setState(() {
                          _gstinError = null;
                          _gstinInfoMessage = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: l10n?.gstinHint ?? '07AAAAA0000A1Z5',
                      prefixIcon: const Icon(Icons.business_outlined, size: 20),
                      helperText: l10n?.gstinHelper ?? '15-character alphanumeric GSTIN',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_gstinError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _gstinError!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_gstinInfoMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _gstinInfoMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('producer_onboarding_verify_gstin_button'),
                      onPressed: _handleVerifyGstin,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        l10n?.verifyGstin ?? 'Verify GSTIN',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
