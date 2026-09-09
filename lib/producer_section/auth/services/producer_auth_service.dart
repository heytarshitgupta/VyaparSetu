import 'package:flutter/foundation.dart';
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
    };

    if (phone != null) {
      data['phone'] = phone.trim().isNotEmpty ? phone.trim() : null;
    }

    await _client.from('profiles').update(data).eq('id', user.id);
  }

  /// Updates public.producer_profiles (business_name, craft_category, bio) for the current user.
  Future<void> updateBusinessProfile({
    required String businessName,
    required String craftCategory,
    String? bio,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final data = <String, dynamic>{
      'business_name': businessName.trim(),
      'craft_category': craftCategory.trim(),
      'bio': bio != null && bio.trim().isNotEmpty ? bio.trim() : null,
    };

    await _client.from('producer_profiles').update(data).eq('id', user.id);
  }

  /// Updates public.producer_profiles (state, district, city, pincode, address) for the current user.
  Future<void> updateLocationProfile({
    required String state,
    required String district,
    required String city,
    required String pincode,
    required String address,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final data = <String, dynamic>{
      'state': state.trim(),
      'district': district.trim(),
      'city': city.trim(),
      'pincode': pincode.trim(),
      'address': address.trim(),
    };

    await _client.from('producer_profiles').update(data).eq('id', user.id);
  }

  /// Updates public.producer_profiles with mandatory "Your Business" attributes for Onboarding V2.
  /// Persists business_name, canonical craft_category, optional bio, state, district, city, and pincode.
  Future<void> updateYourBusiness({
    required String businessName,
    required String craftCategory,
    String? bio,
    required String state,
    required String district,
    required String city,
    required String pincode,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final data = <String, dynamic>{
      'business_name': businessName.trim(),
      'craft_category': craftCategory.trim(),
      'bio': bio != null && bio.trim().isNotEmpty ? bio.trim() : null,
      'state': state.trim(),
      'district': district.trim(),
      'city': city.trim(),
      'pincode': pincode.trim(),
    };

    await _client.from('producer_profiles').update(data).eq('id', user.id);
  }

  /// Updates public.producer_profiles with optional "About Your Business" attributes for Onboarding V2 Pass 3B.
  /// Persists team_size, typical_monthly_sales, production capacity, and selling_channels.
  /// Uses authenticated user.id as the strict ownership authority.
  Future<void> updateAboutYourBusiness({
    String? teamSize,
    String? typicalMonthlySales,
    double? productionCapacityQuantity,
    String? productionCapacityUnit,
    String? productionCapacityPeriod,
    List<String>? sellingChannels,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final data = <String, dynamic>{
      'team_size': teamSize,
      'typical_monthly_sales': typicalMonthlySales,
      'production_capacity_quantity': productionCapacityQuantity,
      'production_capacity_unit': productionCapacityUnit,
      'production_capacity_period': productionCapacityPeriod,
      'selling_channels': sellingChannels ?? [],
    };

    await _client.from('producer_profiles').update(data).eq('id', user.id);
  }

  /// Calls the trusted PostgreSQL SECURITY DEFINER RPC complete_producer_onboarding().
  /// Enforces server-side rule: Step 1 (account/email) + Step 2 (business/location) completed.
  /// Sets onboarding_status = 'completed' and onboarding_step = 3.
  Future<Map<String, dynamic>> completeProducerOnboarding() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      final response = await _client.rpc('complete_producer_onboarding');
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'success': true, 'status': 'completed'};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProducerAuthService] complete_producer_onboarding error: $e');
      }
      rethrow;
    }
  }

  /// Advances public.producer_profiles.onboarding_step via trusted SECURITY DEFINER RPC.
  /// Forward-only, monotonic, and idempotent.
  Future<void> advanceOnboardingStep({
    required int expectedCurrentStep,
    required int nextStep,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      await _client.rpc(
        'advance_producer_onboarding_step',
        params: {
          'expected_current_step': expectedCurrentStep,
          'next_step': nextStep,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProducerAuthService] advance_producer_onboarding_step error: $e');
      }
      rethrow;
    }
  }

  /// Validates that the authenticated user possesses the Producer role and
  /// that their domain profile exists.
  /// Only explicit role violations (e.g. Buyer/Admin account) sign out the user session.
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
      final profile = await fetchProfile();

      if (profile == null) {
        return const ProducerAuthValidationResult(
          status: ProducerAuthStatus.incompleteSetup,
          message: 'Producer account setup is incomplete. Please sign up to create your Producer profile.',
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
        return const ProducerAuthValidationResult(
          status: ProducerAuthStatus.error,
          message: 'Account role is not recognized as a Producer.',
        );
      }

      final producerProfile = await fetchProducerProfile();
      if (producerProfile == null) {
        return ProducerAuthValidationResult(
          status: ProducerAuthStatus.incompleteSetup,
          message: 'Producer profile setup is incomplete. Please complete onboarding.',
          profile: profile,
        );
      }

      return ProducerAuthValidationResult(
        status: ProducerAuthStatus.success,
        message: 'Signed in as Producer successfully.',
        profile: profile,
        producerProfile: producerProfile,
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('already registered as buyer')) {
        await _client.auth.signOut();
        return const ProducerAuthValidationResult(
          status: ProducerAuthStatus.buyerRejected,
          message: 'This account is registered as a Buyer. Role conversion to Producer is not supported.',
        );
      }
      if (errStr.contains('admin accounts cannot register')) {
        await _client.auth.signOut();
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
