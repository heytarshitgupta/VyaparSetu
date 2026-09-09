import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/location/indian_states.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../producer_onboarding_provider.dart';

class YourBusinessStep extends StatefulWidget {
  final ProducerOnboardingProvider provider;

  const YourBusinessStep({
    super.key,
    required this.provider,
  });

  @override
  State<YourBusinessStep> createState() => _YourBusinessStepState();
}

class _YourBusinessStepState extends State<YourBusinessStep> {
  late final TextEditingController _businessNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _pincodeController;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.provider.businessName);
    _bioController = TextEditingController(text: widget.provider.bio);
    _districtController = TextEditingController(text: widget.provider.district);
    _cityController = TextEditingController(text: widget.provider.city);
    _pincodeController = TextEditingController(text: widget.provider.pincode);

    _businessNameController.addListener(() {
      if (widget.provider.businessName != _businessNameController.text) {
        widget.provider.setBusinessName(_businessNameController.text);
      }
    });

    _bioController.addListener(() {
      if (widget.provider.bio != _bioController.text) {
        widget.provider.setBio(_bioController.text);
      }
    });

    _districtController.addListener(() {
      if (widget.provider.district != _districtController.text) {
        widget.provider.setDistrict(_districtController.text);
      }
    });

    _cityController.addListener(() {
      if (widget.provider.city != _cityController.text) {
        widget.provider.setCity(_cityController.text);
      }
    });

    _pincodeController.addListener(() {
      if (widget.provider.pincode != _pincodeController.text) {
        widget.provider.setPincode(_pincodeController.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant YourBusinessStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.provider.businessName != _businessNameController.text) {
      _businessNameController.text = widget.provider.businessName;
    }
    if (widget.provider.bio != _bioController.text) {
      _bioController.text = widget.provider.bio;
    }
    if (widget.provider.district != _districtController.text) {
      _districtController.text = widget.provider.district;
    }
    if (widget.provider.city != _cityController.text) {
      _cityController.text = widget.provider.city;
    }
    if (widget.provider.pincode != _pincodeController.text) {
      _pincodeController.text = widget.provider.pincode;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _bioController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getCategories(AppLocalizations? l10n) {
    return [
      {
        'key': 'food_homemade',
        'label': l10n?.categoryFoodHomemade ?? 'Food & Homemade Products',
        'icon': Icons.restaurant_outlined,
      },
      {
        'key': 'handicrafts',
        'label': l10n?.categoryHandicrafts ?? 'Handicrafts',
        'icon': Icons.palette_outlined,
      },
      {
        'key': 'clothing_textiles',
        'label': l10n?.categoryClothingTextiles ?? 'Clothing & Textiles',
        'icon': Icons.checkroom_outlined,
      },
      {
        'key': 'jewellery_accessories',
        'label': l10n?.categoryJewelleryAccessories ?? 'Jewellery & Accessories',
        'icon': Icons.diamond_outlined,
      },
      {
        'key': 'home_decor',
        'label': l10n?.categoryHomeDecor ?? 'Home & Decor',
        'icon': Icons.chair_outlined,
      },
      {
        'key': 'agriculture_products',
        'label': l10n?.categoryAgricultureProducts ?? 'Agriculture-based Products',
        'icon': Icons.agriculture_outlined,
      },
      {
        'key': 'beauty_personal_care',
        'label': l10n?.categoryBeautyPersonalCare ?? 'Beauty & Personal Care',
        'icon': Icons.spa_outlined,
      },
      {
        'key': 'other',
        'label': l10n?.categoryOtherCraft ?? 'Other',
        'icon': Icons.category_outlined,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final categories = _getCategories(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Error banner if any
        if (widget.provider.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.provider.errorMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // --------------------------------------------------------------------
        // BUSINESS / BRAND NAME (Direct under title, no redundant card)
        // --------------------------------------------------------------------
        Text(
          l10n?.businessBrandNameLabel ?? 'Business / Brand Name',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          key: const Key('producer_onboarding_business_name_field'),
          controller: _businessNameController,
          decoration: InputDecoration(
            hintText: l10n?.businessBrandNameHint ?? 'e.g. Ramesh Handlooms or Ramesh Kumar',
            helperText: l10n?.businessBrandNameHelper ??
                'No brand name? You can use your own name.',
            helperMaxLines: 1,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: const Icon(Icons.storefront_outlined, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),

        // --------------------------------------------------------------------
        // BUSINESS CATEGORY (Compact responsive chips)
        // --------------------------------------------------------------------
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 2,
          children: [
            Text(
              l10n?.businessCategoryLabel ?? 'Business Category *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              l10n?.selectCategoryHint ?? 'Select a category',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth;
            final int crossAxisCount;
            if (maxWidth >= 540) {
              crossAxisCount = 4;
            } else if (maxWidth >= 380) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 2;
            }
            const double spacing = 8.0;
            final double itemWidth =
                (maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: categories.map((cat) {
                final key = cat['key'] as String;
                final label = cat['label'] as String;
                final icon = cat['icon'] as IconData;
                final isSelected = widget.provider.craftCategory == key;

                return SizedBox(
                  width: itemWidth,
                  child: InkWell(
                    key: Key('category_card_$key'),
                    onTap: () {
                      widget.provider.setCraftCategory(key);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      constraints: const BoxConstraints(minHeight: 42),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 17,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.check_circle,
                              size: 15,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 12),

        // --------------------------------------------------------------------
        // WHAT DO YOU MAKE? (Optional, compact height)
        // --------------------------------------------------------------------
        Text(
          l10n?.whatDoYouMakeLabel ?? 'What do you make? (Optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          key: const Key('producer_onboarding_bio_field'),
          controller: _bioController,
          minLines: 2,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: l10n?.whatDoYouMakeHint ?? 'Describe what you make and sell',
            helperText: l10n?.whatDoYouMakeHelper ??
                'For example: homemade pickles, phulkari suits, wooden toys...',
            helperMaxLines: 1,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: Icon(Icons.create_outlined, size: 18),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 14),

        // --------------------------------------------------------------------
        // BUSINESS LOCATION (Lightweight heading + responsive grid/rows)
        // --------------------------------------------------------------------
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              l10n?.businessLocationTitle ?? l10n?.workshopLocationLabel ?? 'Business Location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWideLocation = constraints.maxWidth >= 460;
            if (isWideLocation) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row 1: State / Union Territory | PIN Code
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildStateDropdown(context, locale, l10n, theme),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _buildPincodeField(l10n, theme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 2: District | Area / Village / City
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildDistrictField(l10n, theme),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCityField(l10n, theme),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Phone: Single-column layout
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStateDropdown(context, locale, l10n, theme),
                  const SizedBox(height: 8),
                  _buildDistrictField(l10n, theme),
                  const SizedBox(height: 8),
                  _buildCityField(l10n, theme),
                  const SizedBox(height: 8),
                  _buildPincodeField(l10n, theme),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildStateDropdown(
    BuildContext context,
    Locale locale,
    AppLocalizations? l10n,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.stateLabel ?? 'State / Union Territory *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: const Key('producer_onboarding_state_dropdown'),
          initialValue: widget.provider.selectedIndianState?.englishName ??
              (widget.provider.state.isNotEmpty ? widget.provider.state : null),
          isExpanded: true,
          decoration: InputDecoration(
            hintText: l10n?.selectStateHint ?? 'Select your State / UT',
            prefixIcon: const Icon(Icons.map_outlined, size: 18),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: IndianStates.allStates.map((stateObj) {
            final displayName = stateObj.getLocalizedName(locale);
            return DropdownMenuItem<String>(
              value: stateObj.englishName,
              child: Text(displayName, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              widget.provider.setStateValue(val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDistrictField(AppLocalizations? l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.districtLabel ?? 'District *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          key: const Key('producer_onboarding_district_field'),
          controller: _districtController,
          decoration: InputDecoration(
            hintText: l10n?.districtHint ?? 'e.g. Amritsar, Jaipur',
            prefixIcon: const Icon(Icons.location_searching_outlined, size: 18),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildCityField(AppLocalizations? l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.areaVillageCityLabel ?? 'Area / Village / City *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          key: const Key('producer_onboarding_city_field'),
          controller: _cityController,
          decoration: InputDecoration(
            hintText: l10n?.areaVillageCityHint ?? 'e.g. Rampur Village or Sanganer',
            prefixIcon: const Icon(Icons.location_city_outlined, size: 18),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildPincodeField(AppLocalizations? l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.pincodeLabel ?? 'Pincode *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          key: const Key('producer_onboarding_pincode_field'),
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            hintText: l10n?.pincodeHint ?? '6-digit PIN',
            prefixIcon: const Icon(Icons.pin_drop_outlined, size: 18),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
