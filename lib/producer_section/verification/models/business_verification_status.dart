import 'package:supabase_flutter/supabase_flutter.dart';
import '../../home/models/producer_shell_profile.dart';

enum GstComponentStatus {
  notProvided,
  pending,
  verified,
  rejected,
}

class BusinessVerificationStatus {
  final bool isEmailVerified;
  final String? email;
  final bool isPanVerified;
  final String? panLast4;
  final String panVerificationStatus;
  final bool gstRegistered;
  final String? gstin;
  final String gstVerificationStatus;

  const BusinessVerificationStatus({
    required this.isEmailVerified,
    this.email,
    required this.isPanVerified,
    this.panLast4,
    this.panVerificationStatus = 'unverified',
    required this.gstRegistered,
    this.gstin,
    this.gstVerificationStatus = 'not_applicable',
  });

  /// Factory creating status from ProducerShellProfile and Supabase Auth User.
  factory BusinessVerificationStatus.fromProfile({
    required ProducerShellProfile? profile,
    User? currentUser,
    bool? overrideEmailVerified,
  }) {
    // 1. Email status derived strictly from authenticated user confirmation
    final bool emailVerified = overrideEmailVerified ??
        (currentUser != null && currentUser.emailConfirmedAt != null);

    final panStatus = profile?.panVerificationStatus.toLowerCase() ?? 'unverified';
    final isPan = panStatus == 'verified';

    final isGst = profile?.gstRegistered ?? false;
    final gstStatus = profile?.gstVerificationStatus.toLowerCase() ?? 'not_applicable';

    return BusinessVerificationStatus(
      isEmailVerified: emailVerified,
      email: currentUser?.email ?? profile?.email,
      isPanVerified: isPan,
      panLast4: profile?.panLast4,
      panVerificationStatus: panStatus,
      gstRegistered: isGst,
      gstin: profile?.gstin,
      gstVerificationStatus: gstStatus,
    );
  }

  /// Masked PAN representation (e.g. •••• 1234)
  String? get maskedPan {
    if (panLast4 != null && panLast4!.trim().length == 4) {
      return '•••• ${panLast4!.trim()}';
    }
    return null;
  }

  /// Core business verification requires Email + Business Identity (PAN).
  bool get isCoreComplete => isEmailVerified && isPanVerified;

  /// GST is verified only if registered and status is 'verified'.
  bool get isGstVerified =>
      gstRegistered && gstVerificationStatus.toLowerCase() == 'verified';

  /// GstComponentStatus breakdown for UI rendering.
  GstComponentStatus get gstStatus {
    if (!gstRegistered || gstVerificationStatus == 'not_applicable') {
      return GstComponentStatus.notProvided;
    }
    switch (gstVerificationStatus.toLowerCase()) {
      case 'verified':
        return GstComponentStatus.verified;
      case 'rejected':
        return GstComponentStatus.rejected;
      case 'unverified':
      default:
        return GstComponentStatus.pending;
    }
  }

  /// Total applicable verification steps.
  /// Non-GST producer: 2 steps (Email + PAN).
  /// GST-registered producer: 3 steps (Email + PAN + GST).
  int get totalApplicableSteps => gstRegistered ? 3 : 2;

  /// Count of completed applicable steps.
  int get completedStepsCount {
    int count = 0;
    if (isEmailVerified) count++;
    if (isPanVerified) count++;
    if (gstRegistered && isGstVerified) count++;
    return count;
  }

  /// Remaining steps to reach full applicable verification.
  int get remainingStepsCount {
    final remaining = totalApplicableSteps - completedStepsCount;
    return remaining > 0 ? remaining : 0;
  }

  /// Whether all applicable business verification components are complete.
  /// If non-GST, completing Email + PAN makes it complete.
  bool get isOverallComplete =>
      isCoreComplete && (!gstRegistered || isGstVerified);

  /// Home banner visibility condition:
  /// True when core verification is incomplete, OR when GST is registered but unverified.
  /// Note: A non-GST producer with Email and PAN verified is complete; banner is hidden.
  bool get shouldShowHomeBanner =>
      !isEmailVerified || !isPanVerified || (gstRegistered && !isGstVerified);
}
