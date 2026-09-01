import 'package:flutter/material.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';

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

  String _selectedRole = 'Buyer';

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
      appBar: AppBar(
        title: Text('VyaparSetu', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              
              // Premium Role Toggle
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Continue as:', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _selectedRole,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                        style: Theme.of(context).textTheme.titleMedium,
                        items: const [
                          DropdownMenuItem(value: 'Buyer', child: Text('Buyer')),
                          DropdownMenuItem(value: 'Seller', child: Text('Seller')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Container(
                decoration: BoxDecoration(
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
                height: 250,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Mobile Tab
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Mobile Number',
                            prefixText: '+91 ',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          text: 'Send OTP',
                          onPressed: _mobileController.text.isNotEmpty
                              ? () => Navigator.pushNamed(context, AppRouter.otpRoute)
                              : null,
                        ),
                      ],
                    ),
                    
                    // Email Tab
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(hintText: 'Email Address'),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(hintText: 'Password'),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Forgot Password?'),
                          ),
                        ),
                        const Spacer(),
                        PrimaryButton(
                          text: 'Login',
                          onPressed: (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty)
                              ? () => Navigator.pushNamed(context, AppRouter.homeRoute)
                              : null,
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
              SecondaryButton(
                text: 'Continue with Google',
                onPressed: () {}, 
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?", style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.buyerOnboardingRoute);
                    },
                    child: const Text('Create Account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
