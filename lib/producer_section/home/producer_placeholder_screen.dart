import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../auth/services/producer_auth_service.dart';

class ProducerPlaceholderScreen extends StatefulWidget {
  const ProducerPlaceholderScreen({super.key});

  @override
  State<ProducerPlaceholderScreen> createState() => _ProducerPlaceholderScreenState();
}

class _ProducerPlaceholderScreenState extends State<ProducerPlaceholderScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _producerProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await ProducerAuthService.instance.fetchProfile();
      final producerProfile = await ProducerAuthService.instance.fetchProducerProfile();

      if (mounted) {
        setState(() {
          _profile = profile;
          _producerProfile = producerProfile;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.producerLoginRoute,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final fullName = _profile?['full_name'] as String? ?? user?.userMetadata?['full_name'] as String? ?? 'Producer';
    final email = user?.email ?? _profile?['email'] as String? ?? 'Not available';
    final role = _profile?['role'] as String? ?? 'producer';
    final onboardingStatus = _producerProfile?['onboarding_status'] as String? ?? 'not_started';
    final verificationStatus = _producerProfile?['verification_status'] as String? ?? 'unverified';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Producer Portal',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
            tooltip: 'Sign Out',
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Success Badge
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        const Text(
                          'Producer Account Ready',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          'Welcome, $fullName!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Text(
                          'You are signed in to the Producer portal. Producer onboarding and catalog management will continue here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Account Details Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Account Details',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Divider(height: 20),
                              _buildDetailRow('Email', email),
                              const SizedBox(height: 10),
                              _buildDetailRow('Role', role.toUpperCase()),
                              const SizedBox(height: 10),
                              _buildDetailRow('Onboarding Status', onboardingStatus.replaceAll('_', ' ').toUpperCase()),
                              const SizedBox(height: 10),
                              _buildDetailRow('Verification Status', verificationStatus.toUpperCase()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Sign Out Button
                        OutlinedButton.icon(
                          onPressed: _handleSignOut,
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Sign Out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
