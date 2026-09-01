import 'package:flutter/material.dart';

class BuyerProfile {
  // A. Basic Info
  final String name;
  final String? businessName;
  final String mobile;
  final String email;
  
  // B. Buyer Type
  final String buyerType;

  // C. Business Details
  final String? businessCategory;
  final String? gstin;
  final String address;
  final String city;
  final String state;
  final String pincode;

  // Verification Flags
  final bool isMobileVerified;
  final bool isEmailVerified;
  final bool isBusinessVerified;

  BuyerProfile({
    required this.name,
    this.businessName,
    required this.mobile,
    required this.email,
    required this.buyerType,
    this.businessCategory,
    this.gstin,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.isMobileVerified = false,
    this.isEmailVerified = false,
    this.isBusinessVerified = false,
  });
}

class BuyerProfileProvider extends ChangeNotifier {
  BuyerProfile? _profile;

  BuyerProfile? get profile => _profile;

  void saveProfile(BuyerProfile newProfile) {
    _profile = newProfile;
    notifyListeners();
  }
}
