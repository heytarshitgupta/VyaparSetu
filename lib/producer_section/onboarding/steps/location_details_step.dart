import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/location/indian_states.dart';
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final provider = widget.provider;

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
          // Step Header Icon & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n?.step3Header ?? 'Workshop Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            l10n?.step3Description ??
                'Provide your workshop or home production address so commercial buyers can calculate logistics and pickup.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
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
          Text(
            l10n?.stateLabel ?? 'State / Union Territory *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: const Key('producer_onboarding_state_dropdown'),
            initialValue: provider.stateCode.isNotEmpty &&
                    IndianStates.findByCode(provider.stateCode) != null
                ? provider.stateCode
                : null,
            isExpanded: true,
            hint: Text(
              l10n?.selectStateHint ?? 'Select your state or union territory',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            dropdownColor: theme.colorScheme.surface,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            items: IndianStates.allStates.map((indianState) {
              return DropdownMenuItem<String>(
                value: indianState.code,
                child: Text(
                  indianState.getLocalizedName(Localizations.localeOf(context)),
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
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
              helperText: l10n?.selectStateHint ?? 'Select your state or union territory',
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
          const SizedBox(height: 20),

          // ------------------------------------------------------------------
          // 2. DISTRICT
          // ------------------------------------------------------------------
          Text(
            l10n?.districtLabel ?? 'District *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('producer_onboarding_district_field'),
            controller: _districtController,
            textCapitalization: TextCapitalization.words,
            onChanged: (val) => provider.setDistrict(val),
            decoration: InputDecoration(
              hintText: l10n?.districtHint ?? 'e.g. Jaipur, Ludhiana',
              prefixIcon: const Icon(Icons.holiday_village_outlined, size: 20),
              helperText: l10n?.districtHelper ?? 'District where you make your products',
              helperMaxLines: 2,
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
          const SizedBox(height: 20),

          // ------------------------------------------------------------------
          // 3. CITY / VILLAGE
          // ------------------------------------------------------------------
          Text(
            l10n?.cityVillageLabel ?? 'City / Village *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('producer_onboarding_city_field'),
            controller: _cityController,
            textCapitalization: TextCapitalization.words,
            onChanged: (val) => provider.setCity(val),
            decoration: InputDecoration(
              hintText: l10n?.cityVillageHint ?? 'e.g. Sanganer, Khanna',
              prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
              helperText: l10n?.cityVillageHelper ?? 'Your city, town, or village',
              helperMaxLines: 2,
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
          const SizedBox(height: 20),

          // ------------------------------------------------------------------
          // 4. PINCODE
          // ------------------------------------------------------------------
          Text(
            l10n?.pincodeLabel ?? 'Pincode *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
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
              hintText: l10n?.pincodeHint ?? 'e.g. 302029',
              prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
              helperText: l10n?.pincodeHelper ?? '6-digit postal PIN code (cannot start with 0)',
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
          const SizedBox(height: 20),

          // ------------------------------------------------------------------
          // 5. WORKSHOP / BUSINESS ADDRESS
          // ------------------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.addressLabel ?? 'Workshop / Business Address *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
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
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
              hintText: l10n?.addressHint ?? 'Street, landmark, lane, or house/unit details...',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(Icons.home_work_outlined, size: 20),
              ),
              helperText: l10n?.addressHelper ?? 'Where you make or manage your products',
              helperMaxLines: 2,
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
        ],
      ),
    );
  }
}
