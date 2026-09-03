import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../producer_onboarding_provider.dart';

class LocationDetailsStep extends StatefulWidget {
  final ProducerOnboardingProvider provider;

  const LocationDetailsStep({
    super.key,
    required this.provider,
  });

  @override
  State<LocationDetailsStep> createState() => _LocationDetailsStepState();
}

class _LocationDetailsStepState extends State<LocationDetailsStep> {
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _districtController = TextEditingController(text: widget.provider.district);
    _cityController = TextEditingController(text: widget.provider.city);
    _pincodeController = TextEditingController(text: widget.provider.pincode);
    _addressController = TextEditingController(text: widget.provider.address);
  }

  @override
  void didUpdateWidget(covariant LocationDetailsStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.provider.district != _districtController.text) {
      _districtController.text = widget.provider.district;
    }
    if (widget.provider.city != _cityController.text) {
      _cityController.text = widget.provider.city;
    }
    if (widget.provider.pincode != _pincodeController.text) {
      _pincodeController.text = widget.provider.pincode;
    }
    if (widget.provider.address != _addressController.text) {
      _addressController.text = widget.provider.address;
    }
  }

  @override
  void dispose() {
    _districtController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _addressController.dispose();
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
                  Icons.location_on_outlined,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Workshop Location',
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
            'Provide your workshop or home production address so commercial buyers can calculate logistics and pickup.',
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
          // 1. STATE / UNION TERRITORY
          // ------------------------------------------------------------------
          const Text(
            'State / Union Territory *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: const Key('producer_onboarding_state_dropdown'),
            initialValue: provider.state.isNotEmpty &&
                    ProducerOnboardingProvider.indianStatesAndUTs.contains(provider.state)
                ? provider.state
                : null,
            isExpanded: true,
            hint: const Text('Select your state or union territory'),
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
            items: ProducerOnboardingProvider.indianStatesAndUTs.map((stateName) {
              return DropdownMenuItem<String>(
                value: stateName,
                child: Text(
                  stateName,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                provider.setStateValue(val);
              }
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.map_outlined, size: 20),
              helperText: 'Select your state or union territory',
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
          // 2. DISTRICT
          // ------------------------------------------------------------------
          const Text(
            'District *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('producer_onboarding_district_field'),
            controller: _districtController,
            textCapitalization: TextCapitalization.words,
            onChanged: (val) => provider.setDistrict(val),
            decoration: InputDecoration(
              hintText: 'e.g. Jaipur, Ludhiana',
              prefixIcon: const Icon(Icons.holiday_village_outlined, size: 20),
              helperText: 'District where you make your products',
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
          // 3. CITY / VILLAGE
          // ------------------------------------------------------------------
          const Text(
            'City / Village *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('producer_onboarding_city_field'),
            controller: _cityController,
            textCapitalization: TextCapitalization.words,
            onChanged: (val) => provider.setCity(val),
            decoration: InputDecoration(
              hintText: 'e.g. Sanganer, Khanna',
              prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
              helperText: 'Your city, town, or village',
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
          // 4. PINCODE
          // ------------------------------------------------------------------
          const Text(
            'Pincode *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('producer_onboarding_pincode_field'),
            controller: _pincodeController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (val) => provider.setPincode(val),
            decoration: InputDecoration(
              hintText: 'e.g. 302029',
              prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
              helperText: '6-digit postal PIN code (cannot start with 0)',
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
          // 5. WORKSHOP / BUSINESS ADDRESS
          // ------------------------------------------------------------------
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Workshop / Business Address *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${provider.address.length}/300',
                style: TextStyle(
                  fontSize: 12,
                  color: provider.address.length > 300
                      ? AppColors.error
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('producer_onboarding_address_field'),
            controller: _addressController,
            maxLines: 3,
            minLines: 2,
            maxLength: 300,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                const SizedBox.shrink(),
            onChanged: (val) => provider.setAddress(val),
            decoration: InputDecoration(
              hintText: 'Street, landmark, lane, or house/unit details...',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(Icons.home_work_outlined, size: 20),
              ),
              helperText: 'Where you make or manage your products',
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
      ),
    );
  }
}
