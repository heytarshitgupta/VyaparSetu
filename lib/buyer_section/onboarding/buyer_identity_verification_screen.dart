import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_top_bar_controls.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../producer_section/verification/producer_verification_service.dart';
import 'buyer_profile_provider.dart';

class BuyerIdentityVerificationScreen extends StatefulWidget {
  const BuyerIdentityVerificationScreen({super.key});

  @override
  State<BuyerIdentityVerificationScreen> createState() => _BuyerIdentityVerificationScreenState();
}

class _BuyerIdentityVerificationScreenState extends State<BuyerIdentityVerificationScreen> {
  late final TextEditingController _panController;
  late final TextEditingController _panNameController;
  DateTime? _selectedDob;

  bool _isVerifying = false;
  bool _isVerified = false;
  String? _maskedPan;
  String? _panLocalError;
  String? _panLocalSuccessInfo;

  static final RegExp _panFormatRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

  @override
  void initState() {
    super.initState();
    _panController = TextEditingController();
    
    final profile = context.read<BuyerProfileProvider>().profile;
    _panNameController = TextEditingController(text: profile?.name ?? '');

    // Check if already verified
    if (profile?.isBusinessVerified == true) {
      _isVerified = true;
      _maskedPan = '******XXXX';
    }
  }

  @override
  void dispose() {
    _panController.dispose();
    _panNameController.dispose();
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
      });
    }
  }

  Future<void> _handleVerifyPan() async {
    if (_isVerifying || _isVerified) return;

    final trimmedPan = _panController.text.trim().toUpperCase();
    final trimmedName = _panNameController.text.trim();

    setState(() {
      _panLocalSuccessInfo = null;
      _panLocalError = null;
    });

    if (trimmedPan.isEmpty) {
      setState(() => _panLocalError = 'Please enter your 10-character PAN number.');
      return;
    }
    if (!_panFormatRegex.hasMatch(trimmedPan)) {
      setState(() => _panLocalError = 'Please enter a valid 10-character PAN (e.g. ABCDE1234F).');
      return;
    }
    if (trimmedName.isEmpty) {
      setState(() => _panLocalError = 'Please enter your name as per PAN.');
      return;
    }
    if (_selectedDob == null) {
      setState(() => _panLocalError = 'Please select your Date of Birth as on PAN.');
      return;
    }

    setState(() => _isVerifying = true);

    // Mocking the verification for the prototype without hitting Supabase backend
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Simulate success response
    final bool isSuccess = true; 
    
    if (isSuccess) {
      _panController.clear();
      
      // Update the buyer profile to mark as verified
      final provider = context.read<BuyerProfileProvider>();
      final currentProfile = provider.profile;
      if (currentProfile != null) {
        provider.saveProfile(currentProfile.copyWith(isBusinessVerified: true));
      }

      setState(() {
        _isVerifying = false;
        _isVerified = true;
        _maskedPan = '******${trimmedPan.substring(6)}';
        _panLocalSuccessInfo = 'PAN verified successfully.';
      });
    } else {
      setState(() {
        _isVerifying = false;
        _panLocalError = 'PAN could not be verified. Please check your details.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.panVerification ?? 'Identity Verification'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: const [
          AppTopBarControls(showLabels: false),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n?.secureIdentityVerification ?? 'Verify your Identity',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.step4Description ?? 'Enter your PAN details to complete verification.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  
                  if (_panLocalError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(_panLocalError!, style: const TextStyle(color: AppColors.error)),
                    ),
                  ],
                  
                  if (_panLocalSuccessInfo != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(_panLocalSuccessInfo!, style: const TextStyle(color: Colors.green)),
                    ),
                  ],
                  
                  if (_isVerified) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.verified, color: Colors.green, size: 48),
                          const SizedBox(height: 16),
                          const Text('Identity Verified successfully.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('PAN: $_maskedPan', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Return to Verification Center', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ] else ...[
                    Text(l10n?.panNumberLabel ?? 'PAN Number *', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _panController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        hintText: l10n?.panNumberHint ?? 'ABCDE1234F',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Text(l10n?.nameAsPerPanLabel ?? 'Name as per PAN *', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _panNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: l10n?.nameAsPerPanHint ?? 'Enter name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Text(l10n?.dobLabel ?? 'Date of Birth *', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickDateOfBirth(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _selectedDob != null 
                            ? '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}'
                            : (l10n?.selectDobHint ?? 'Select Date of Birth (DD/MM/YYYY)'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _handleVerifyPan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isVerifying 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(l10n?.checkingDetails ?? 'Verify Identity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
