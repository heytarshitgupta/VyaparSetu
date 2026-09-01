import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  int get currentStep => _currentStep;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get errorMessage => _errorMessage;

  bool get isFirstStep => _currentStep == 0;
  bool get isLastStep => _currentStep == totalSteps - 1;
  double get progressPercentage => (_currentStep + 1) / totalSteps;

  String get fullName => _fullName;
  String get contactPhone => _contactPhone;
  String get displayEmail => _displayEmail;
  bool get isAuthPhone => _isAuthPhone;
  String get authPhone => _authPhone;

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
  // PREFILL INITIAL DATA FROM PROFILES & AUTH.USERS
  // --------------------------------------------------------------------------
  void initializeFromProfile({
    required Map<String, dynamic>? profile,
    required User? user,
  }) {
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

    notifyListeners();
  }

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
  // STEP 1 PERSISTENCE: Save to public.profiles
  // --------------------------------------------------------------------------
  Future<void> Function({required String fullName, String? phone})? step1Saver;

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

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to save basic details. Please check your connection and try again.';
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
    _isSubmitting = false;
    _isLoadingProfile = false;
    _errorMessage = null;
    notifyListeners();
  }
}
