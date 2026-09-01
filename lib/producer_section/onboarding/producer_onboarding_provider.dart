import 'package:flutter/foundation.dart';

class ProducerOnboardingProvider extends ChangeNotifier {
  static const int totalSteps = 5;

  int _currentStep = 0;
  bool _isSubmitting = false;

  int get currentStep => _currentStep;
  bool get isSubmitting => _isSubmitting;
  bool get isFirstStep => _currentStep == 0;
  bool get isLastStep => _currentStep == totalSteps - 1;
  double get progressPercentage => (_currentStep + 1) / totalSteps;

  // Step Step Names & Metadata
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

  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void reset() {
    _currentStep = 0;
    _isSubmitting = false;
    notifyListeners();
  }
}
