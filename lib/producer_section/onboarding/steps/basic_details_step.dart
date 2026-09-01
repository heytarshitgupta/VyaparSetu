import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../producer_onboarding_provider.dart';

class BasicDetailsStep extends StatefulWidget {
  final ProducerOnboardingProvider provider;

  const BasicDetailsStep({
    super.key,
    required this.provider,
  });

  @override
  State<BasicDetailsStep> createState() => _BasicDetailsStepState();
}

class _BasicDetailsStepState extends State<BasicDetailsStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.provider.fullName);
    _phoneController = TextEditingController(text: widget.provider.contactPhone);
  }

  @override
  void didUpdateWidget(covariant BasicDetailsStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.provider.fullName != _nameController.text) {
      _nameController.text = widget.provider.fullName;
    }
    if (widget.provider.contactPhone != _phoneController.text) {
      _phoneController.text = widget.provider.contactPhone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header Icon & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Artisan Basic Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text(
            'Confirm your primary business name and contact information for buyer communications.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Error banner if any
          if (provider.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      provider.errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ------------------------------------------------------------------
          // 1. FULL NAME INPUT
          // ------------------------------------------------------------------
          const Text(
            'Full Name *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('producer_onboarding_name_field'),
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (val) => provider.setFullName(val),
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
              helperText: 'Your name as you want it shown on VyaparSetu',
              helperMaxLines: 2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ------------------------------------------------------------------
          // 2. EMAIL (READ-ONLY)
          // ------------------------------------------------------------------
          const Text(
            'Email Address (Login)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.displayEmail.isNotEmpty ? provider.displayEmail : 'Not provided',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Read Only',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Your login email is managed through your Supabase account',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 20),

          // ------------------------------------------------------------------
          // 3. PHONE NUMBER (AUTH OR CONTACT)
          // ------------------------------------------------------------------
          Text(
            provider.isAuthPhone ? 'Verified Login Phone' : 'Contact Phone Number',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          if (provider.isAuthPhone) ...[
            // Read-only Authenticated Phone
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_android, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.authPhone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Verified Auth',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4, left: 4),
              child: Text(
                'This phone number is verified and tied to your login credentials',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ] else ...[
            // Editable Contact Phone
            TextFormField(
              key: const Key('producer_onboarding_phone_field'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: (val) => provider.setContactPhone(val),
              decoration: InputDecoration(
                hintText: 'Enter 10-digit mobile number',
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                prefixText: '+91 ',
                prefixStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                helperText: 'Used to contact you about your business (Contact phone only)',
                helperMaxLines: 2,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
