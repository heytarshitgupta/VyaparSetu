import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/location/indian_states.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../auth/services/producer_auth_service.dart';

class ProducerOnboardingProvider extends ChangeNotifier {
  /// Total steps in Onboarding V2:
  /// Step 0: Your Business (Mandatory)
  /// Step 1: About Your Business (Optional — Pass 3B transition architecture)
  static const int totalSteps = 2;

  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isLoadingProfile = false;
  String? _errorMessage;

  // --------------------------------------------------------------------------
  // ONBOARDING V2 STEP 1 (YOUR BUSINESS) STATE
  // --------------------------------------------------------------------------
  String _businessName = '';
  String _craftCategory = ''; // Canonical key: e.g. food_homemade, handicrafts, etc.
  String _rawCraftCategory = ''; // Preserved raw historical/legacy value from producer_profiles
  String _customCategory = '';
  String _businessDescription = ''; // Optional bio ("What do you make?")
  String _state = '';
  String _district = '';
  String _city = ''; // Area / Village / City
  String _pincode = '';
  String _address = '';

  // --------------------------------------------------------------------------
  // STEP 3: ABOUT YOUR BUSINESS (OPTIONAL ATTRIBUTES - PASS 3B)
  // --------------------------------------------------------------------------
  String? _teamSize;
  String? _typicalMonthlySales;
  String _productionCapacityQuantity = '';
  String? _productionCapacityUnit;
  String? _productionCapacityPeriod;
  List<String> _sellingChannels = [];

  String? get teamSize => _teamSize;
  String? get typicalMonthlySales => _typicalMonthlySales;
  String get productionCapacityQuantity => _productionCapacityQuantity;
  String? get productionCapacityUnit => _productionCapacityUnit;
  String? get productionCapacityPeriod => _productionCapacityPeriod;
  List<String> get sellingChannels => List.unmodifiable(_sellingChannels);

  /// Canonical Team Size values matching database check constraint chk_producer_team_size.
  static const List<String> canonicalTeamSizes = [
    'solo',
    '2_5',
    '6_10',
    '11_25',
    '25_plus',
  ];

  /// Canonical Typical Monthly Sales values matching database check constraint chk_producer_monthly_sales.
  static const List<String> canonicalMonthlySales = [
    'below_10k',
    '10k_50k',
    '50k_1l',
    '1l_5l',
    'above_5l',
    'prefer_not_to_say',
  ];

  /// Canonical Production Capacity Units matching database check constraint chk_producer_capacity_unit.
  static const List<String> canonicalCapacityUnits = [
    'pieces',
    'kg',
    'litres',
    'packs',
    'boxes',
    'other',
  ];

  /// Canonical Production Capacity Periods matching database check constraint chk_producer_capacity_period.
  static const List<String> canonicalCapacityPeriods = [
    'week',
    'month',
    'year',
  ];

  /// Canonical Selling Channels matching database check constraint chk_producer_selling_channels_valid.
  static const List<String> canonicalSellingChannels = [
    'local_customers',
    'local_shops',
    'whatsapp',
    'social_media',
    'online_marketplaces',
    'exhibitions_fairs',
    'not_selling_yet',
  ];
  // --------------------------------------------------------------------------
  // ACCOUNT / PROFILE LEGACY ATTRIBUTES (Preserved for compatibility)
  // --------------------------------------------------------------------------
  String _fullName = '';
  String _contactPhone = '';
  String _displayEmail = '';
  bool _isAuthPhone = false;
  String _authPhone = '';

  // --------------------------------------------------------------------------
  // COMPLIANCE / GST ATTRIBUTES (Decoupled from active onboarding journey)
  // --------------------------------------------------------------------------
  bool _gstRegistered = false;
  String _gstin = '';

  bool get gstRegistered => _gstRegistered;
  String get gstin => _gstin;

  int _persistedServerStep = 1;
  int get persistedServerStep => _persistedServerStep;

  /// Optional custom RPC handler for advancing server step in tests
  Future<void> Function({required int expectedCurrentStep, required int nextStep})? stepAdvancer;

  /// Optional custom persistence handler for Your Business step
  Future<void> Function({
    required String businessName,
    required String craftCategory,
    String? bio,
    required String state,
    required String district,
    required String city,
    required String pincode,
  })? yourBusinessSaver;

  /// Optional custom persistence handler for About Your Business step (Pass 3B)
  Future<void> Function({
    String? teamSize,
    String? typicalMonthlySales,
    double? productionCapacityQuantity,
    String? productionCapacityUnit,
    String? productionCapacityPeriod,
    List<String>? sellingChannels,
  })? aboutYourBusinessSaver;

  /// Optional custom RPC handler for completing onboarding in tests
  Future<Map<String, dynamic>> Function()? onboardingCompleter;

  /// Legacy step savers preserved for compatibility
  Future<void> Function({required String fullName, String? phone})? step1Saver;
  Future<void> Function({
    required String businessName,
    required String craftCategory,
    String? bio,
  })? step2Saver;
  Future<void> Function({
    required String state,
    required String district,
    required String city,
    required String pincode,
    required String address,
  })? step3Saver;

  Map<String, dynamic>? _producerProfile;
  Map<String, dynamic>? get producerProfile => _producerProfile;

  /// Canonical craft categories supported by Onboarding V2.
  /// Strictly these 8 keys are stored in the database.
  static const List<String> canonicalCategories = [
    'food_homemade',
    'handicrafts',
    'clothing_textiles',
    'jewellery_accessories',
    'home_decor',
    'agriculture_products',
    'beauty_personal_care',
    'other',
  ];

  /// Normalizes arbitrary or legacy craft category strings into canonical keys.
  /// Returns null if the category is unknown (does not match canonical or known legacy patterns).
  /// Unknown categories must not silently map to 'other'.
  static String? normalizeCategoryToCanonical(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (canonicalCategories.contains(trimmed)) return trimmed;

    final lower = trimmed.toLowerCase();
    if (lower.contains('food') ||
        lower.contains('homemade') ||
        lower.contains('खाद्य') ||
        lower.contains('घरेलू') ||
        lower.contains('ਭੋਜਨ')) {
      return 'food_homemade';
    }
    if (lower.contains('handicraft') ||
        lower.contains('हस्तशिल्प') ||
        lower.contains('ਦਸਤਕਾਰੀ')) {
      return 'handicrafts';
    }
    if (lower.contains('cloth') ||
        lower.contains('textile') ||
        lower.contains('handloom') ||
        lower.contains('embroidery') ||
        lower.contains('वस्त्र') ||
        lower.contains('परिधान') ||
        lower.contains('ਕੱਪੜੇ')) {
      return 'clothing_textiles';
    }
    if (lower.contains('jewel') || lower.contains('आभूषण') || lower.contains('ਗਹਿਣੇ')) {
      return 'jewellery_accessories';
    }
    if (lower.contains('decor') ||
        lower.contains('wood') ||
        lower.contains('metal') ||
        lower.contains('सज्जा') ||
        lower.contains('ਸਜਾਵਟ')) {
      return 'home_decor';
    }
    if (lower.contains('agri') || lower.contains('कृषि') || lower.contains('ਖੇਤੀ')) {
      return 'agriculture_products';
    }
    if (lower.contains('beauty') ||
        lower.contains('care') ||
        lower.contains('सौंदर्य') ||
        lower.contains('ਸੁੰਦਰਤਾ')) {
      return 'beauty_personal_care';
    }
    if (lower == 'other' || lower == 'अन्य' || lower == 'ਹੋਰ') {
      return 'other';
    }

    return null;
  }

  static const List<String> standardCategories = [
    'Food & Homemade Products',
    'Handicrafts',
    'Handloom & Textiles',
    'Clothing & Embroidery',
    'Jewellery & Accessories',
    'Woodwork',
    'Metal Craft',
    'Home Decor',
    'Beauty / Personal Care',
    'Other',
  ];

  static const List<String> indianStatesAndUTs = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  int get currentStep => _currentStep;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get errorMessage => _errorMessage;

  bool get isFirstStep => _currentStep == 0;
  bool get isLastStep => _currentStep == totalSteps - 1;
  double get progressPercentage => (_currentStep + 1) / totalSteps;

  // Account / Contact Getters
  String get fullName => _fullName;
  String get contactPhone => _contactPhone;
  String get displayEmail => _displayEmail;
  bool get isAuthPhone => _isAuthPhone;
  String get authPhone => _authPhone;

  // Your Business Getters
  String get businessName => _businessName;
  String get craftCategory => _craftCategory;
  String get rawCraftCategory => _rawCraftCategory;
  String get customCategory => _customCategory;
  String get businessDescription => _businessDescription;
  String get bio => _businessDescription;

  // Location Getters
  String get state => _state;
  String get stateCode => IndianStates.getCanonicalCode(_state);
  IndianState? get selectedIndianState => IndianStates.findByCodeOrName(_state);
  String get district => _district;
  String get city => _city;
  String get areaVillageCity => _city;
  String get pincode => _pincode;
  String get address => _address;

  // Step Metadata for V2
  static const List<Map<String, String>> stepMetadata = [
    {
      'title': 'Your Business',
      'subtitle': 'Tell us a little about what you make and where your business is based.',
    },
    {
      'title': 'About Your Business',
      'subtitle': 'Help us understand your business better. You can skip this step.',
    },
  ];

  String get currentStepTitle =>
      _currentStep < stepMetadata.length ? (stepMetadata[_currentStep]['title'] ?? '') : '';
  String get currentStepSubtitle =>
      _currentStep < stepMetadata.length ? (stepMetadata[_currentStep]['subtitle'] ?? '') : '';

  // --------------------------------------------------------------------------
  // PREFILL INITIAL DATA FROM PROFILES, PRODUCER_PROFILES & AUTH.USERS
  // --------------------------------------------------------------------------
  void initializeFromProfile({
    required Map<String, dynamic>? profile,
    Map<String, dynamic>? producerProfile,
    required User? user,
  }) {
    _producerProfile = producerProfile;

    // 1. Full Name
    final profileName = (profile?['full_name'] as String?)?.trim() ?? '';
    final metaName = (user?.userMetadata?['full_name'] as String?)?.trim() ?? '';
    _fullName = profileName.isNotEmpty ? profileName : metaName;

    // 2. Email
    _displayEmail = user?.email ?? (profile?['email'] as String?) ?? '';

    // 3. Contact Phone (Preserved, not required for V2 onboarding)
    final authPhoneNumber = user?.phone?.trim() ?? '';
    if (authPhoneNumber.isNotEmpty) {
      _isAuthPhone = true;
      _authPhone = authPhoneNumber;
      _contactPhone = authPhoneNumber;
    } else {
      _isAuthPhone = false;
      _authPhone = '';
      _contactPhone = (profile?['phone'] as String?)?.trim() ?? '';
    }

    // 4. Business Name & Bio
    _businessName = (producerProfile?['business_name'] as String?)?.trim() ?? '';
    _businessDescription = (producerProfile?['bio'] as String?)?.trim() ?? '';

    // 5. Craft Category (Preserve raw historical value; normalize to canonical key if known)
    final existingCategory = (producerProfile?['craft_category'] as String?)?.trim() ?? '';
    _rawCraftCategory = existingCategory;
    final canonical = normalizeCategoryToCanonical(existingCategory);
    _craftCategory = canonical ?? '';

    // 6. Location Details
    _state = (producerProfile?['state'] as String?)?.trim() ?? '';
    _district = (producerProfile?['district'] as String?)?.trim() ?? '';
    _city = (producerProfile?['city'] as String?)?.trim() ?? '';
    _pincode = (producerProfile?['pincode'] as String?)?.trim() ?? '';
    _address = (producerProfile?['address'] as String?)?.trim() ?? '';

    // 7. Compliance / GST
    final rawGstReg = producerProfile?['gst_registered'];
    _gstRegistered = rawGstReg is bool ? rawGstReg : false;
    _gstin = (producerProfile?['gstin'] as String?)?.trim().toUpperCase() ?? '';

    // 8. Step 3: About Your Business (Optional Attributes - Pass 3B)
    final existingTeamSize = (producerProfile?['team_size'] as String?)?.trim();
    if (existingTeamSize != null && canonicalTeamSizes.contains(existingTeamSize)) {
      _teamSize = existingTeamSize;
    }

    final existingSales = (producerProfile?['typical_monthly_sales'] as String?)?.trim();
    if (existingSales != null && canonicalMonthlySales.contains(existingSales)) {
      _typicalMonthlySales = existingSales;
    }

    final existingCapQty = producerProfile?['production_capacity_quantity'];
    if (existingCapQty != null) {
      if (existingCapQty is num) {
        _productionCapacityQuantity = existingCapQty == existingCapQty.toInt()
            ? existingCapQty.toInt().toString()
            : existingCapQty.toString();
      } else {
        _productionCapacityQuantity = existingCapQty.toString().trim();
      }
    }

    final existingCapUnit = (producerProfile?['production_capacity_unit'] as String?)?.trim();
    if (existingCapUnit != null && canonicalCapacityUnits.contains(existingCapUnit)) {
      _productionCapacityUnit = existingCapUnit;
    }

    final existingCapPeriod = (producerProfile?['production_capacity_period'] as String?)?.trim();
    if (existingCapPeriod != null && canonicalCapacityPeriods.contains(existingCapPeriod)) {
      _productionCapacityPeriod = existingCapPeriod;
    }

    final existingChannels = producerProfile?['selling_channels'];
    if (existingChannels is List) {
      _sellingChannels = existingChannels
          .map((c) => c.toString().trim())
          .map((c) => c == 'instagram_facebook' ? 'social_media' : c)
          .where((c) => canonicalSellingChannels.contains(c))
          .toList();
    }

    // 9. Server Step Restoration
    final rawServerStep = (producerProfile?['onboarding_step'] as num?)?.toInt() ?? 1;
    _persistedServerStep = rawServerStep.clamp(1, 5);

    // If producer already completed onboarding, preserve completed state
    final onboardingStatus = producerProfile?['onboarding_status']?.toString();
    if (onboardingStatus == 'completed') {
      _currentStep = totalSteps - 1;
    } else {
      _currentStep = (_persistedServerStep - 1).clamp(0, totalSteps - 1);
    }

    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // SETTERS
  // --------------------------------------------------------------------------
  void setBusinessName(String value) {
    _businessName = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setCraftCategory(String value) {
    _craftCategory = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setCustomCategory(String value) {
    _customCategory = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setBusinessDescription(String value) {
    _businessDescription = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setBio(String value) => setBusinessDescription(value);

  void setStateValue(String value) {
    _state = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setDistrict(String value) {
    _district = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setCity(String value) {
    _city = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setAreaVillageCity(String value) => setCity(value);

  void setPincode(String value) {
    _pincode = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setAddress(String value) {
    _address = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setFullName(String value) {
    _fullName = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setContactPhone(String value) {
    _contactPhone = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setGstRegistered(bool value) {
    _gstRegistered = value;
    if (!value) _gstin = '';
    notifyListeners();
  }

  void setGstin(String value) {
    _gstin = value.trim().toUpperCase();
    notifyListeners();
  }

  // Step 3 Setters
  void setTeamSize(String? value) {
    _teamSize = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setTypicalMonthlySales(String? value) {
    _typicalMonthlySales = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setProductionCapacityQuantity(String value) {
    _productionCapacityQuantity = value.trim();
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setProductionCapacityUnit(String? value) {
    _productionCapacityUnit = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setProductionCapacityPeriod(String? value) {
    _productionCapacityPeriod = value;
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void toggleSellingChannel(String channel) {
    if (channel == 'not_selling_yet') {
      if (_sellingChannels.contains('not_selling_yet')) {
        _sellingChannels.remove('not_selling_yet');
      } else {
        _sellingChannels.clear();
        _sellingChannels.add('not_selling_yet');
      }
    } else {
      _sellingChannels.remove('not_selling_yet');
      if (_sellingChannels.contains(channel)) {
        _sellingChannels.remove(channel);
      } else {
        _sellingChannels.add(channel);
      }
    }
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void setSellingChannels(List<String> channels) {
    _sellingChannels = List<String>.from(channels);
    if (_errorMessage != null) _errorMessage = null;
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // VALIDATION: ONBOARDING V2 "ABOUT YOUR BUSINESS" (PASS 3B)
  // --------------------------------------------------------------------------
  String? validateAboutYourBusiness({AppLocalizations? l10n}) {
    final qtyStr = _productionCapacityQuantity.trim();
    final hasQty = qtyStr.isNotEmpty;
    final hasUnit = _productionCapacityUnit != null && _productionCapacityUnit!.isNotEmpty;
    final hasPeriod = _productionCapacityPeriod != null && _productionCapacityPeriod!.isNotEmpty;

    // All-or-none rule
    if (hasQty || hasUnit || hasPeriod) {
      if (!hasQty || !hasUnit || !hasPeriod) {
        return l10n?.capacityAllOrNoneRequired ??
            'Please specify quantity, unit, and period for production capacity, or leave all three empty.';
      }
      final qty = double.tryParse(qtyStr);
      if (qty == null || qty <= 0) {
        return l10n?.capacityPositiveRequired ??
            'Production capacity quantity must be a positive number.';
      }
    }
    return null;
  }

  // --------------------------------------------------------------------------
  // VALIDATION: ONBOARDING V2 "YOUR BUSINESS"
  // --------------------------------------------------------------------------
  String? validateYourBusiness({AppLocalizations? l10n}) {
    final trimmedBusiness = _businessName.trim();
    if (trimmedBusiness.isEmpty || trimmedBusiness.length < 2) {
      return l10n?.businessNameRequired ??
          'Please enter your business or brand name (at least 2 characters).';
    }
    if (trimmedBusiness.length > 120) {
      return 'Business name cannot exceed 120 characters.';
    }

    if (_craftCategory.trim().isEmpty) {
      return l10n?.categoryRequired ?? 'Please select your primary product category.';
    }

    if (_businessDescription.trim().length > 500) {
      return 'Description cannot exceed 500 characters.';
    }

    if (_state.trim().isEmpty) {
      return l10n?.stateRequired ?? 'Please select your state or union territory.';
    }

    final trimmedDistrict = _district.trim();
    if (trimmedDistrict.isEmpty || trimmedDistrict.length < 2) {
      return l10n?.districtRequired ?? 'Please enter your district (at least 2 characters).';
    }
    if (trimmedDistrict.length > 100) {
      return 'District cannot exceed 100 characters.';
    }

    final trimmedCity = _city.trim();
    if (trimmedCity.isEmpty || trimmedCity.length < 2) {
      return l10n?.cityRequired ??
          'Please enter your area, village, or city (at least 2 characters).';
    }
    if (trimmedCity.length > 100) {
      return 'Area, village, or city cannot exceed 100 characters.';
    }

    final trimmedPincode = _pincode.trim();
    if (trimmedPincode.isEmpty || !RegExp(r'^[1-9][0-9]{5}$').hasMatch(trimmedPincode)) {
      return l10n?.pincodeInvalid ?? 'Please enter a valid 6-digit Indian PIN code.';
    }

    return null;
  }

  // --------------------------------------------------------------------------
  // PERSISTENCE: ONBOARDING V2 "YOUR BUSINESS"
  // --------------------------------------------------------------------------
  Future<bool> saveYourBusiness({AppLocalizations? l10n}) async {
    final validationError = validateYourBusiness(l10n: l10n);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final stateToSave = selectedIndianState?.englishName ?? _state.trim();

      if (yourBusinessSaver != null) {
        await yourBusinessSaver!(
          businessName: _businessName.trim(),
          craftCategory: _craftCategory.trim(),
          bio: _businessDescription.trim().isNotEmpty ? _businessDescription.trim() : null,
          state: stateToSave,
          district: _district.trim(),
          city: _city.trim(),
          pincode: _pincode.trim(),
        );
      } else {
        await ProducerAuthService.instance.updateYourBusiness(
          businessName: _businessName.trim(),
          craftCategory: _craftCategory.trim(),
          bio: _businessDescription.trim().isNotEmpty ? _businessDescription.trim() : null,
          state: stateToSave,
          district: _district.trim(),
          city: _city.trim(),
          pincode: _pincode.trim(),
        );
      }

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProducerOnboarding] Exception on Your Business save: $e');
      }
      _isSubmitting = false;
      _errorMessage = 'Failed to save business details. Please check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // PERSISTENCE & COMPLETION: ABOUT YOUR BUSINESS (PASS 3B)
  // --------------------------------------------------------------------------
  Future<bool> saveAboutYourBusiness({AppLocalizations? l10n}) async {
    final validationError = validateAboutYourBusiness(l10n: l10n);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final qtyStr = _productionCapacityQuantity.trim();
      final double? qty = qtyStr.isNotEmpty ? double.tryParse(qtyStr) : null;

      if (aboutYourBusinessSaver != null) {
        await aboutYourBusinessSaver!(
          teamSize: _teamSize,
          typicalMonthlySales: _typicalMonthlySales,
          productionCapacityQuantity: qty,
          productionCapacityUnit: _productionCapacityUnit,
          productionCapacityPeriod: _productionCapacityPeriod,
          sellingChannels: _sellingChannels,
        );
      } else {
        await ProducerAuthService.instance.updateAboutYourBusiness(
          teamSize: _teamSize,
          typicalMonthlySales: _typicalMonthlySales,
          productionCapacityQuantity: qty,
          productionCapacityUnit: _productionCapacityUnit,
          productionCapacityPeriod: _productionCapacityPeriod,
          sellingChannels: _sellingChannels,
        );
      }

      // Authoritative database completion RPC
      if (onboardingCompleter != null) {
        await onboardingCompleter!();
      } else {
        await ProducerAuthService.instance.completeProducerOnboarding();
      }

      if (_producerProfile != null) {
        _producerProfile!['onboarding_status'] = 'completed';
      }

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProducerOnboarding] Exception on About Your Business save / complete: $e');
      }
      _isSubmitting = false;
      _errorMessage = 'Failed to complete setup. Please check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> skipAboutYourBusiness() async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // "Skip for now" completes onboarding without requiring or writing Step 3 optional data,
      // discarding any unsaved or partial values and preserving existing database profile data.
      if (onboardingCompleter != null) {
        await onboardingCompleter!();
      } else {
        await ProducerAuthService.instance.completeProducerOnboarding();
      }

      if (_producerProfile != null) {
        _producerProfile!['onboarding_status'] = 'completed';
      }

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProducerOnboarding] Exception on About Your Business skip / complete: $e');
      }
      _isSubmitting = false;
      _errorMessage = 'Failed to complete setup. Please check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // LEGACY STEP VALIDATIONS & SAVERS (Preserved for compatibility)
  // --------------------------------------------------------------------------
  String? validateStep1() {
    final trimmedName = _fullName.trim();
    if (trimmedName.isEmpty) return 'Please enter your full name.';
    if (trimmedName.length < 2) return 'Full name must be at least 2 characters.';
    if (trimmedName.length > 120) return 'Full name cannot exceed 120 characters.';
    return null;
  }

  String? validateStep2() {
    final trimmedBusiness = _businessName.trim();
    if (trimmedBusiness.isEmpty) return 'Please enter your business or workshop name.';
    if (trimmedBusiness.length < 2) return 'Business name must be at least 2 characters.';
    if (_craftCategory.isEmpty) return 'Please select a primary craft or product category.';
    return null;
  }

  String? validateStep3() {
    if (_state.trim().isEmpty) return 'Please select your state or union territory.';
    final trimmedDistrict = _district.trim();
    if (trimmedDistrict.isEmpty) return 'Please enter your district.';
    if (trimmedDistrict.length < 2 || trimmedDistrict.length > 100) {
      return 'District must be between 2 and 100 characters.';
    }
    final trimmedCity = _city.trim();
    if (trimmedCity.isEmpty) return 'Please enter your city, town, or village.';
    if (trimmedCity.length < 2 || trimmedCity.length > 100) {
      return 'City or village must be between 2 and 100 characters.';
    }
    final trimmedPincode = _pincode.trim();
    if (trimmedPincode.isEmpty) return 'Please enter your 6-digit postal PIN code.';
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(trimmedPincode)) {
      return 'Please enter a valid 6-digit Indian PIN code (cannot start with 0).';
    }
    final trimmedAddress = _address.trim();
    if (trimmedAddress.isEmpty) return 'Please enter your workshop or business address.';
    if (trimmedAddress.length < 5 || trimmedAddress.length > 300) {
      return 'Address must be between 5 and 300 characters.';
    }
    return null;
  }

  Future<void> _advanceServerProgress({
    required int expectedCurrentStep,
    required int nextStep,
  }) async {
    try {
      if (stepAdvancer != null) {
        await stepAdvancer!(
          expectedCurrentStep: expectedCurrentStep,
          nextStep: nextStep,
        );
      } else {
        await ProducerAuthService.instance.advanceOnboardingStep(
          expectedCurrentStep: expectedCurrentStep,
          nextStep: nextStep,
        );
      }
      if (nextStep > _persistedServerStep) {
        _persistedServerStep = nextStep;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProducerOnboardingProvider] Non-blocking step advance warning: $e');
      }
    }
  }

  Future<bool> saveStep1() async {
    final err = validateStep1();
    if (err != null) {
      _errorMessage = err;
      notifyListeners();
      return false;
    }
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final digitsOnly = _contactPhone.replaceAll(RegExp(r'\D'), '');
      if (step1Saver != null) {
        await step1Saver!(
          fullName: _fullName.trim(),
          phone: _isAuthPhone ? null : digitsOnly,
        );
      } else {
        await ProducerAuthService.instance.updateBasicProfile(
          fullName: _fullName.trim(),
          phone: _isAuthPhone ? null : digitsOnly,
        );
      }
      await _advanceServerProgress(expectedCurrentStep: 1, nextStep: 2);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to save basic details.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveStep2() async {
    final err = validateStep2();
    if (err != null) {
      _errorMessage = err;
      notifyListeners();
      return false;
    }
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (step2Saver != null) {
        await step2Saver!(
          businessName: _businessName.trim(),
          craftCategory: _craftCategory.trim(),
          bio: _businessDescription.trim(),
        );
      } else {
        await ProducerAuthService.instance.updateBusinessProfile(
          businessName: _businessName.trim(),
          craftCategory: _craftCategory.trim(),
          bio: _businessDescription.trim(),
        );
      }
      await _advanceServerProgress(expectedCurrentStep: 2, nextStep: 3);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to save business details.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveStep3() async {
    final err = validateStep3();
    if (err != null) {
      _errorMessage = err;
      notifyListeners();
      return false;
    }
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final stateToSave = selectedIndianState?.englishName ?? _state.trim();
      if (step3Saver != null) {
        await step3Saver!(
          state: stateToSave,
          district: _district.trim(),
          city: _city.trim(),
          pincode: _pincode.trim(),
          address: _address.trim(),
        );
      } else {
        await ProducerAuthService.instance.updateLocationProfile(
          state: stateToSave,
          district: _district.trim(),
          city: _city.trim(),
          pincode: _pincode.trim(),
          address: _address.trim(),
        );
      }
      await _advanceServerProgress(expectedCurrentStep: 3, nextStep: 4);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to save location details.';
      notifyListeners();
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // STEP NAVIGATION
  // --------------------------------------------------------------------------
  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void reset() {
    _currentStep = 0;
    _businessName = '';
    _craftCategory = '';
    _rawCraftCategory = '';
    _customCategory = '';
    _businessDescription = '';
    _state = '';
    _district = '';
    _city = '';
    _pincode = '';
    _address = '';
    _isSubmitting = false;
    _isLoadingProfile = false;
    _errorMessage = null;
    notifyListeners();
  }
}
