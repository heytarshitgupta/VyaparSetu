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

  /// Requests simulated PAN verification via trusted backend RPC.
  ///
  /// Raw PAN is strictly transient and NEVER logged, printed, or persisted locally.
  Future<PanVerificationResult> verifyPan({
    required String pan,
    required String nameAsPerPan,
    required DateTime dateOfBirth,
  }) async {
    final trimmedPan = pan.trim().toUpperCase();
    final trimmedName = nameAsPerPan.trim();
    final dobIso =
        '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';

    try {
      final params = <String, dynamic>{
        'p_pan': trimmedPan,
        'p_name': trimmedName,
        'p_dob': dobIso,
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
}
