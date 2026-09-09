import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PanVerificationResult {
  final bool success;
  final String status;
  final String message;
  final String? panLast4;
  final String? maskedPan;

  const PanVerificationResult({
    required this.success,
    required this.status,
    required this.message,
    this.panLast4,
    this.maskedPan,
  });

  factory PanVerificationResult.fromJson(Map<String, dynamic> json) {
    return PanVerificationResult(
      success: json['success'] as bool? ?? false,
      status: json['status'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      panLast4: json['pan_last4'] as String?,
      maskedPan: json['masked_pan'] as String?,
    );
  }

  factory PanVerificationResult.failure(String message) {
    return PanVerificationResult(
      success: false,
      status: 'error',
      message: message,
    );
  }
}

class GstVerificationResult {
  final bool success;
  final String status;
  final String message;
  final String? maskedGstin;
  final String? marketAccessScope;

  const GstVerificationResult({
    required this.success,
    required this.status,
    required this.message,
    this.maskedGstin,
    this.marketAccessScope,
  });

  factory GstVerificationResult.fromJson(Map<String, dynamic> json) {
    return GstVerificationResult(
      success: json['success'] as bool? ?? false,
      status: json['status'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      maskedGstin: json['masked_gstin'] as String?,
      marketAccessScope: json['market_access_scope'] as String?,
    );
  }

  factory GstVerificationResult.failure(String message) {
    return GstVerificationResult(
      success: false,
      status: 'error',
      message: message,
    );
  }
}

class ProducerVerificationService {
  final SupabaseClient? client;

  /// Optional custom RPC handler for dependency injection in tests
  Future<dynamic> Function(String fnName, Map<String, dynamic> params)? rpcHandler;

  ProducerVerificationService({
    this.client,
    this.rpcHandler,
  });

  SupabaseClient get supabaseClient => client ?? Supabase.instance.client;

  static ProducerVerificationService? _instance;
  static ProducerVerificationService get instance =>
      _instance ??= ProducerVerificationService();

  @visibleForTesting
  static void setMockInstance(ProducerVerificationService? mock) {
    _instance = mock;
  }

  /// Records and validates a 10-character PAN via the trusted backend RPC.
  ///
  /// Prototype validation note: The backend RPC `verify_producer_pan_prototype`
  /// performs format validation and demo simulation. It does NOT contact an external government registry.
  ///
  /// Aligned with Migration 014: takes only `p_pan`. Legacy `p_name` and `p_dob`
  /// parameters have been eliminated.
  ///
  /// Raw PAN is strictly transient and NEVER logged, printed, or persisted locally.
  Future<PanVerificationResult> verifyPan({
    required String pan,
  }) async {
    final trimmedPan = pan.trim().toUpperCase();

    try {
      final params = <String, dynamic>{
        'p_pan': trimmedPan,
      };

      final response = rpcHandler != null
          ? await rpcHandler!('verify_producer_pan_prototype', params)
          : await supabaseClient.rpc('verify_producer_pan_prototype', params: params);

      if (response is Map<String, dynamic>) {
        return PanVerificationResult.fromJson(response);
      } else if (response is Map) {
        return PanVerificationResult.fromJson(Map<String, dynamic>.from(response));
      }

      return PanVerificationResult.failure('Invalid response format from verification service.');
    } catch (e) {
      if (kDebugMode) {
        if (e is PostgrestException) {
          debugPrint(
            '[ProducerVerification] PostgrestException on PAN verification: '
            'code=${e.code}, message=${e.message}, hint=${e.hint}',
          );
        } else {
          debugPrint('[ProducerVerification] Exception on PAN verification: $e');
        }
      }
      return PanVerificationResult.failure(
        'Unable to complete verification at this time. Please try again.',
      );
    }
  }

  /// Requests simulated GST verification via trusted backend RPC.
  ///
  /// Raw GSTIN is strictly transient and written only by the authoritative backend RPC.
  Future<GstVerificationResult> verifyGst({
    required String gstin,
  }) async {
    final trimmedGstin = gstin.trim().toUpperCase();

    try {
      final params = <String, dynamic>{
        'p_gstin': trimmedGstin,
      };

      final response = rpcHandler != null
          ? await rpcHandler!('verify_producer_gst_prototype', params)
          : await supabaseClient.rpc('verify_producer_gst_prototype', params: params);

      if (response is Map<String, dynamic>) {
        return GstVerificationResult.fromJson(response);
      } else if (response is Map) {
        return GstVerificationResult.fromJson(Map<String, dynamic>.from(response));
      }

      return GstVerificationResult.failure('Invalid response format from verification service.');
    } catch (e) {
      if (kDebugMode) {
        if (e is PostgrestException) {
          debugPrint(
            '[ProducerVerification] PostgrestException on GST verification: '
            'code=${e.code}, message=${e.message}, hint=${e.hint}',
          );
        } else {
          debugPrint('[ProducerVerification] Exception on GST verification: $e');
        }
      }
      return GstVerificationResult.failure(
        'Unable to complete verification at this time. Please try again.',
      );
    }
  }
}
