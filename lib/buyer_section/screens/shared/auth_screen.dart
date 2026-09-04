import 'package:flutter/material.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_top_bar_controls.dart';
import 'widgets/buyer_auth_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('VyaparSetu', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          AppTopBarControls(showLabels: false),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Persona Tag
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.highlightAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.highlightAccent.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.accent),
                          SizedBox(width: 6),
                          Text(
                            'I Source & Buy Products',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Heading
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to source high-quality products directly from local producers.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: Theme.of(context).textTheme.titleMedium,
                      unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium,
                      tabs: const [
                        Tab(text: 'Mobile Number'),
                        Tab(text: 'Email'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Mobile Tab
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            BuyerAuthTextField(
                              controller: _mobileController,
                              label: 'Mobile Number',
                              hint: 'Enter your 10-digit number',
                              prefixIcon: Icons.phone_android_outlined,
                              keyboardType: TextInputType.phone,
                              prefixText: '+91 ',
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 32),
                            _buildPrimaryButton(
                              text: 'Send OTP',
                              icon: Icons.message_outlined,
                              enabled: _mobileController.text.isNotEmpty,
                              onPressed: () => Navigator.pushNamed(context, AppRouter.otpRoute),
                            ),
                          ],
                        ),
                        
                        // Email Tab
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            BuyerAuthTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'buyer@example.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            BuyerAuthTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Enter your password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 32),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            _buildPrimaryButton(
                              text: 'Sign In',
                              icon: Icons.arrow_forward,
                              enabled: _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty,
                              onPressed: () => Navigator.pushNamed(context, AppRouter.homeRoute),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: Theme.of(context).textTheme.bodySmall),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRouter.buyerOnboardingRoute);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({required String text, required IconData icon, required bool enabled, required VoidCallback onPressed}) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 18),
          ],
        ),
      ),
    );
  }
}
