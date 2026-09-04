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
  final bool isGstVerified;

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
    this.isGstVerified = false,
  });

  BuyerProfile copyWith({
    String? name,
    String? businessName,
    String? mobile,
    String? email,
    String? buyerType,
    String? businessCategory,
    String? gstin,
    String? address,
    String? city,
    String? state,
    String? pincode,
    bool? isMobileVerified,
    bool? isEmailVerified,
    bool? isBusinessVerified,
    bool? isGstVerified,
  }) {
    return BuyerProfile(
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      buyerType: buyerType ?? this.buyerType,
      businessCategory: businessCategory ?? this.businessCategory,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isMobileVerified: isMobileVerified ?? this.isMobileVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isBusinessVerified: isBusinessVerified ?? this.isBusinessVerified,
      isGstVerified: isGstVerified ?? this.isGstVerified,
    );
  }
}

class BuyerProfileProvider extends ChangeNotifier {
  BuyerProfile? _profile;

  BuyerProfile? get profile => _profile;

  void saveProfile(BuyerProfile newProfile) {
    _profile = newProfile;
    notifyListeners();
  }
}
