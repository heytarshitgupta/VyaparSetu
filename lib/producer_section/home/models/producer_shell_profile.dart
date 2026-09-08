class ProducerShellProfile {
  final String fullName;
  final String email;
  final String? phone;
  final String? businessName;
  final String? craftCategory;
  final String? bio;
  final String? state;
  final String? district;
  final String? city;
  final String? pincode;
  final String? address;
  final String? panLast4;
  final String panVerificationStatus;
  final bool gstRegistered;
  final String? gstin;
  final String gstVerificationStatus;
  final int onboardingStep;

  const ProducerShellProfile({
    this.fullName = '',
    this.email = '',
    this.phone,
    this.businessName,
    this.craftCategory,
    this.bio,
    this.state,
    this.district,
    this.city,
    this.pincode,
    this.address,
    this.panLast4,
    this.panVerificationStatus = 'unverified',
    this.gstRegistered = false,
    this.gstin,
    this.gstVerificationStatus = 'not_applicable',
    this.onboardingStep = 1,
  });

  /// Short initials for avatar (e.g., "TG" from "Tarshit Gupta", or "P")
  String get initials {
    final clean = fullName.trim();
    if (clean.isEmpty) return 'P';
    final parts = clean.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      final first = parts[0][0];
      final second = parts[1][0];
      return '$first$second'.toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  /// Compact location summary (e.g. "Patiala, Punjab" or "Punjab" or null)
  String? get locationSummary {
    final parts = <String>[];
    if (city != null && city!.trim().isNotEmpty) {
      parts.add(city!.trim());
    } else if (district != null && district!.trim().isNotEmpty) {
      parts.add(district!.trim());
    }
    if (state != null && state!.trim().isNotEmpty) {
      parts.add(state!.trim());
    }
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  /// Safe masked PAN for display only: never raw PAN
  String? get maskedPan {
    if (panLast4 != null && panLast4!.trim().length == 4) {
      return '•••• ${panLast4!.trim()}';
    }
    return null;
  }

  bool get isPanVerified => panVerificationStatus.toLowerCase() == 'verified';
  bool get isIdentityVerified => isPanVerified;
}

