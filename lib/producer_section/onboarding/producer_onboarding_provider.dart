import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/location/indian_states.dart';
import '../auth/services/producer_auth_service.dart';

class ProducerOnboardingProvider extends ChangeNotifier {
  static const int totalSteps = 5;

  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isLoadingProfile = false;
  String? _errorMessage;

  // --------------------------------------------------------------------------
  // STEP 1 STATE: BASIC DETAILS
  // --------------------------------------------------------------------------
  String _fullName = '';
  String _contactPhone = '';
  String _displayEmail = '';
  bool _isAuthPhone = false;
  String _authPhone = '';

  // --------------------------------------------------------------------------
  // STEP 2 STATE: BUSINESS / CRAFT DETAILS
  // --------------------------------------------------------------------------
  String _businessName = '';
  String _craftCategory = '';
  String _customCategory = '';
  String _businessDescription = '';

  // --------------------------------------------------------------------------
  // STEP 3 STATE: LOCATION DETAILS
  // --------------------------------------------------------------------------
  String _state = '';
  String _district = '';
  String _city = '';
  String _pincode = '';
  String _address = '';

  // --------------------------------------------------------------------------
  // STEP 4 STATE: COMPLIANCE / GST
  // --------------------------------------------------------------------------
  bool _gstRegistered = false;
  String _gstin = '';

  bool get gstRegistered => _gstRegistered;
  String get gstin => _gstin;

  int _persistedServerStep = 1;
  int get persistedServerStep => _persistedServerStep;

  /// Optional custom RPC handler for advancing server step in tests
  Future<void> Function({required int expectedCurrentStep, required int nextStep})? stepAdvancer;

  Map<String, dynamic>? _producerProfile;
  Map<String, dynamic>? get producerProfile => _producerProfile;

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

  // Step 1 Getters
  String get fullName => _fullName;
  String get contactPhone => _contactPhone;
  String get displayEmail => _displayEmail;
  bool get isAuthPhone => _isAuthPhone;
  String get authPhone => _authPhone;

  // Step 2 Getters
  String get businessName => _businessName;
  String get craftCategory => _craftCategory;
  String get customCategory => _customCategory;
  String get businessDescription => _businessDescription;

  // Step 3 Getters
  String get state => _state;

  /// Canonical Indian state/UT code based on standard 2-letter abbreviations (e.g. 'PB', 'RJ', 'DL').
  String get stateCode => IndianStates.getCanonicalCode(_state);

  /// Resolved IndianState model for the currently selected state, if any.
  IndianState? get selectedIndianState => IndianStates.findByCodeOrName(_state);
  String get district => _district;
  String get city => _city;
  String get pincode => _pincode;
  String get address => _address;

  // Step Names & Subtitles
  static const List<Map<String, String>> stepMetadata = [
    {
      'title': 'Basic Details',
      'subtitle': 'Your name and contact info',
    },
    {
      'title': 'Craft & Business',
      'subtitle': 'What you make and sell',
    },
    {
      'title': 'Location Details',
      'subtitle': 'Where your workshop is based',
    },
    {
      'title': 'Identity & Compliance',
      'subtitle': 'Artisan verification details',
    },
    {
      'title': 'Review & Submit',
      'subtitle': 'Confirm and start selling',
    },
  ];

  String get currentStepTitle => stepMetadata[_currentStep]['title'] ?? '';
  String get currentStepSubtitle => stepMetadata[_currentStep]['subtitle'] ?? '';

  // --------------------------------------------------------------------------
  // PREFILL INITIAL DATA FROM PROFILES, PRODUCER_PROFILES & AUTH.USERS
  // --------------------------------------------------------------------------
  void initializeFromProfile({
    required Map<String, dynamic>? profile,
    Map<String, dynamic>? producerProfile,
    required User? user,
  }) {
    _producerProfile = producerProfile;

    // 1. Full Name: profile.full_name -> user metadata full_name -> empty
    final profileName = (profile?['full_name'] as String?)?.trim() ?? '';
    final metaName = (user?.userMetadata?['full_name'] as String?)?.trim() ?? '';
    _fullName = profileName.isNotEmpty ? profileName : metaName;

    // 2. Email: Authoritative from Supabase Auth user.email
    _displayEmail = user?.email ?? (profile?['email'] as String?) ?? '';

    // 3. Phone: If user has an authenticated phone in auth.users, mark as auth phone
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

    // 4. Step 2 Business / Craft Details
    _businessName = (producerProfile?['business_name'] as String?)?.trim() ?? '';
    _businessDescription = (producerProfile?['bio'] as String?)?.trim() ?? '';

    final existingCategory = (producerProfile?['craft_category'] as String?)?.trim() ?? '';
    if (existingCategory.isNotEmpty) {
      if (standardCategories.contains(existingCategory) && existingCategory != 'Other') {
        _craftCategory = existingCategory;
        _customCategory = '';
      } else {
        _craftCategory = 'Other';
        _customCategory = existingCategory;
      }
    }

    // 5. Step 3 Location Details
    _state = (producerProfile?['state'] as String?)?.trim() ?? '';
    _district = (producerProfile?['district'] as String?)?.trim() ?? '';
    _city = (producerProfile?['city'] as String?)?.trim() ?? '';
    _pincode = (producerProfile?['pincode'] as String?)?.trim() ?? '';
    _address = (producerProfile?['address'] as String?)?.trim() ?? '';

    // 6. Step 4 Compliance / GST
    final rawGstReg = producerProfile?['gst_registered'];
    _gstRegistered = rawGstReg is bool ? rawGstReg : false;
    _gstin = (producerProfile?['gstin'] as String?)?.trim().toUpperCase() ?? '';

    // 7. Restore Server-Backed Onboarding Step (1 to 5)
    final rawServerStep = (producerProfile?['onboarding_step'] as num?)?.toInt() ?? 1;
    _persistedServerStep = rawServerStep.clamp(1, totalSteps);
    _currentStep = _persistedServerStep - 1;

    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // STEP 4 SETTERS: GST
  // --------------------------------------------------------------------------
  void setGstRegistered(bool value) {
    _gstRegistered = value;
    if (!value) {
      _gstin = '';
    }
    notifyListeners();
  }

  void setGstin(String value) {
    _gstin = value.trim().toUpperCase();
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // STEP 1 SETTERS
  // --------------------------------------------------------------------------
  void setFullName(String value) {
    _fullName = value;
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void setContactPhone(String value) {
    _contactPhone = value;
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // STEP 2 SETTERS
  // --------------------------------------------------------------------------
  void setBusinessName(String value) {
    _businessName = value;
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void setCraftCategory(String value) {
    _craftCategory = value;
    if (value != 'Other') {
      _customCategory = '';
    }
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void setCustomCategory(String value) {
    _customCategory = value;
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void setBusinessDescription(String value) {
    _businessDescription = value;
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // STEP 3 SETTERS
  // --------------------------------------------------------------------------
  void setStateValue(String value) {
    _state = value;
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void setDistrict(String value) {
    _district = value;
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void setCity(String value) {
    _city = value;
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void setPincode(String value) {
    _pincode = value;
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void setAddress(String value) {
    _address = value;
    if (_errorMessage != null) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // STEP 1 VALIDATION HELPER
  // --------------------------------------------------------------------------
  String? validateStep1() {
    final trimmedName = _fullName.trim();
    if (trimmedName.isEmpty) {
      return 'Please enter your full name.';
    }
    if (trimmedName.length < 2) {
      return 'Full name must be at least 2 characters.';
    }
    if (trimmedName.length > 120) {
      return 'Full name cannot exceed 120 characters.';
    }

    // Contact phone validation if user is entering a non-auth contact phone
    if (!_isAuthPhone && _contactPhone.trim().isNotEmpty) {
      final digitsOnly = _contactPhone.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(digitsOnly)) {
        return 'Please enter a valid 10-digit Indian mobile number.';
      }
    }

    return null;
  }

  // --------------------------------------------------------------------------
  // STEP 2 VALIDATION HELPER
  // --------------------------------------------------------------------------
  String? validateStep2() {
    final trimmedBusiness = _businessName.trim();
    if (trimmedBusiness.isEmpty) {
      return 'Please enter your business or workshop name.';
    }
    if (trimmedBusiness.length < 2) {
      return 'Business name must be at least 2 characters.';
    }
    if (trimmedBusiness.length > 120) {
      return 'Business name cannot exceed 120 characters.';
    }

    if (_craftCategory.isEmpty) {
      return 'Please select a primary craft or product category.';
    }

    if (_craftCategory == 'Other') {
      final trimmedCustom = _customCategory.trim();
      if (trimmedCustom.isEmpty) {
        return 'Please specify your craft category.';
      }
      if (trimmedCustom.length < 2) {
        return 'Custom category must be at least 2 characters.';
      }
      if (trimmedCustom.length > 60) {
        return 'Custom category cannot exceed 60 characters.';
      }
    }

    if (_businessDescription.trim().length > 500) {
      return 'Short description cannot exceed 500 characters.';
    }

    return null;
  }

  // --------------------------------------------------------------------------
  // STEP 3 VALIDATION HELPER
  // --------------------------------------------------------------------------
  String? validateStep3() {
    if (_state.trim().isEmpty) {
      return 'Please select your state or union territory.';
    }

    final trimmedDistrict = _district.trim();
    if (trimmedDistrict.isEmpty) {
      return 'Please enter your district.';
    }
    if (trimmedDistrict.length < 2 || trimmedDistrict.length > 100) {
      return 'District must be between 2 and 100 characters.';
    }

    final trimmedCity = _city.trim();
    if (trimmedCity.isEmpty) {
      return 'Please enter your city, town, or village.';
    }
    if (trimmedCity.length < 2 || trimmedCity.length > 100) {
      return 'City or village must be between 2 and 100 characters.';
    }

    final trimmedPincode = _pincode.trim();
    if (trimmedPincode.isEmpty) {
      return 'Please enter your 6-digit postal PIN code.';
    }
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(trimmedPincode)) {
      return 'Please enter a valid 6-digit Indian PIN code (cannot start with 0).';
    }

    final trimmedAddress = _address.trim();
    if (trimmedAddress.isEmpty) {
      return 'Please enter your workshop or business address.';
    }
    if (trimmedAddress.length < 5 || trimmedAddress.length > 300) {
      return 'Address must be between 5 and 300 characters.';
    }

    return null;
  }

  // --------------------------------------------------------------------------
  // STEP 1 PERSISTENCE: Save to public.profiles
  // --------------------------------------------------------------------------
  Future<void> Function({required String fullName, String? phone})? step1Saver;

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
    final validationError = validateStep1();
    if (validationError != null) {
      _errorMessage = validationError;
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
      if (kDebugMode) {
        if (e is PostgrestException) {
          debugPrint('[ProducerOnboarding] PostgrestException on Step 1 save: code=${e.code}, message=${e.message}, hint=${e.hint}, details=${e.details}');
        } else {
          debugPrint('[ProducerOnboarding] Exception on Step 1 save: $e');
        }
      }
      _isSubmitting = false;
      _errorMessage = 'Failed to save basic details. Please check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // STEP 2 PERSISTENCE: Save to public.producer_profiles
  // --------------------------------------------------------------------------
  Future<void> Function({
    required String businessName,
    required String craftCategory,
    String? bio,
  })? step2Saver;

  Future<bool> saveStep2() async {
    final validationError = validateStep2();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final finalCategory = _craftCategory == 'Other'
        ? _customCategory.trim()
        : _craftCategory.trim();

    try {
      if (step2Saver != null) {
        await step2Saver!(
          businessName: _businessName.trim(),
          craftCategory: finalCategory,
          bio: _businessDescription.trim(),
        );
      } else {
        await ProducerAuthService.instance.updateBusinessProfile(
          businessName: _businessName.trim(),
          craftCategory: finalCategory,
          bio: _businessDescription.trim(),
        );
      }

      await _advanceServerProgress(expectedCurrentStep: 2, nextStep: 3);

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        if (e is PostgrestException) {
          debugPrint('[ProducerOnboarding] PostgrestException on Step 2 save: code=${e.code}, message=${e.message}, hint=${e.hint}, details=${e.details}');
        } else {
          debugPrint('[ProducerOnboarding] Exception on Step 2 save: $e');
        }
      }
      _isSubmitting = false;
      _errorMessage = 'Failed to save business details. Please check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // STEP 3 PERSISTENCE: Save to public.producer_profiles
  // --------------------------------------------------------------------------
  Future<void> Function({
    required String state,
    required String district,
    required String city,
    required String pincode,
    required String address,
  })? step3Saver;

  Future<bool> saveStep3() async {
    final validationError = validateStep3();
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
      if (kDebugMode) {
        if (e is PostgrestException) {
          debugPrint('[ProducerOnboarding] PostgrestException on Step 3 save: code=${e.code}, message=${e.message}, hint=${e.hint}, details=${e.details}');
        } else {
          debugPrint('[ProducerOnboarding] Exception on Step 3 save: $e');
        }
      }
      _isSubmitting = false;
      _errorMessage = 'Failed to save location details. Please check your connection and try again.';
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
    _persistedServerStep = 1;
    _gstRegistered = false;
    _gstin = '';
    _isSubmitting = false;
    _isLoadingProfile = false;
    _errorMessage = null;
    notifyListeners();
  }
}
