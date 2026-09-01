import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

enum ProducerAuthStatus {
  success,
  buyerRejected,
  adminRejected,
  incompleteSetup,
  error,
}

class ProducerAuthValidationResult {
  final ProducerAuthStatus status;
  final String message;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? producerProfile;

  const ProducerAuthValidationResult({
    required this.status,
    required this.message,
    this.profile,
    this.producerProfile,
  });

  bool get isSuccess => status == ProducerAuthStatus.success;
}

class ProducerAuthService {
  ProducerAuthService._();

  static final ProducerAuthService instance = ProducerAuthService._();

  SupabaseClient get _client => SupabaseService.client;

  /// Calls the secure database RPC register_producer_profile to initialize or verify
  /// the Producer profile for the currently authenticated user.
  Future<String> registerProducerProfile({required String fullName}) async {
    final response = await _client.rpc(
      'register_producer_profile',
      params: {
        'p_full_name': fullName.trim(),
      },
    );
    return response.toString();
  }

  /// Fetches the public.profiles record for the current authenticated user.
  Future<Map<String, dynamic>?> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  /// Fetches the public.producer_profiles record for the current authenticated user.
  Future<Map<String, dynamic>?> fetchProducerProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('producer_profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  /// Updates public.profiles (full_name and optional contact phone) for the current user.
  /// Note: phone stored here is strictly a contact phone, not an authenticated phone.
  Future<void> updateBasicProfile({
    required String fullName,
    String? phone,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final data = <String, dynamic>{
      'full_name': fullName.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (phone != null) {
      data['phone'] = phone.trim();
    }

    await _client.from('profiles').update(data).eq('id', user.id);
  }

  /// Validates that the authenticated user possesses the Producer role and
  /// that their domain profile exists.
  /// If authorization fails for any reason (e.g. Buyer/Admin account or incomplete setup),
  /// the session is safely terminated (signed out) so no unauthorized active state persists.
  Future<ProducerAuthValidationResult> validateProducerAccess({
    String? fallbackFullName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const ProducerAuthValidationResult(
        status: ProducerAuthStatus.error,
        message: 'No authenticated user session found.',
      );
    }

    try {
      var profile = await fetchProfile();

      // If no profile row exists, attempt initialization with user metadata or fallback name
      if (profile == null) {
        final metadataName = (user.userMetadata?['full_name'] as String?)?.trim() ??
            fallbackFullName?.trim() ??
            '';

        if (metadataName.length >= 2) {
          await registerProducerProfile(fullName: metadataName);
          profile = await fetchProfile();
        } else {
          await _client.auth.signOut();
          return const ProducerAuthValidationResult(
            status: ProducerAuthStatus.incompleteSetup,
            message: 'Producer account setup is incomplete. Please sign up to create your Producer profile.',
          );
        }
      }

      if (profile == null) {
        await _client.auth.signOut();
        return const ProducerAuthValidationResult(
          status: ProducerAuthStatus.incompleteSetup,
          message: 'Unable to load your profile. Please try signing in again.',
        );
      }

      final role = profile['role']?.toString().toLowerCase();

      if (role == 'buyer') {
        await _client.auth.signOut();
        return const ProducerAuthValidationResult(
          status: ProducerAuthStatus.buyerRejected,
          message: 'This account is registered as a Buyer. Access to the Producer portal is restricted.',
        );
      }

      if (role == 'admin') {
        await _client.auth.signOut();
        return const ProducerAuthValidationResult(
          status: ProducerAuthStatus.adminRejected,
          message: 'Admin accounts cannot access the Producer portal.',
        );
      }

      if (role != 'producer') {
        await _client.auth.signOut();
        return const ProducerAuthValidationResult(
          status: ProducerAuthStatus.error,
          message: 'Account role is not recognized as a Producer.',
        );
      }

      // Fetch or ensure producer_profiles exists
      var producerProfile = await fetchProducerProfile();
      if (producerProfile == null) {
        // Idempotent recovery
        final name = (profile['full_name'] as String?)?.trim() ?? 'Producer';
        await registerProducerProfile(fullName: name);
        producerProfile = await fetchProducerProfile();
      }

      return ProducerAuthValidationResult(
        status: ProducerAuthStatus.success,
        message: 'Signed in as Producer successfully.',
        profile: profile,
        producerProfile: producerProfile,
      );
    } catch (e) {
      await _client.auth.signOut();

      final errStr = e.toString().toLowerCase();
      if (errStr.contains('already registered as buyer')) {
        return const ProducerAuthValidationResult(
          status: ProducerAuthStatus.buyerRejected,
          message: 'This account is registered as a Buyer. Role conversion to Producer is not supported.',
        );
      }
      if (errStr.contains('admin accounts cannot register')) {
        return const ProducerAuthValidationResult(
          status: ProducerAuthStatus.adminRejected,
          message: 'Admin accounts cannot access the Producer portal.',
        );
      }

      return const ProducerAuthValidationResult(
        status: ProducerAuthStatus.error,
        message: 'Failed to verify Producer profile. Please check your connection and try again.',
      );
    }
  }
}
