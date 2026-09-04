import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/app_top_bar_controls.dart';
import '../screens/shared/widgets/buyer_auth_text_field.dart';
import 'buyer_profile_provider.dart';

class BuyerOnboardingScreen extends StatefulWidget {
  const BuyerOnboardingScreen({super.key});

  @override
  State<BuyerOnboardingScreen> createState() => _BuyerOnboardingScreenState();
}

class _BuyerOnboardingScreenState extends State<BuyerOnboardingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Basic Info
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedBuyerType;

  final List<String> _buyerTypes = [
    'Retailer', 'Wholesaler', 'Distributor', 'E-commerce Seller',
    'Corporate / Institutional Buyer', 'Individual Bulk Buyer', 'Exporter'
  ];

  // Step 2: Business Details
  final _businessCategoryController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _businessCategoryController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _onComplete() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Mock async
    
    if (!mounted) return;
    
    final profile = BuyerProfile(
      name: _nameController.text,
      businessName: _businessNameController.text,
      mobile: _mobileController.text,
      email: _emailController.text,
      buyerType: _selectedBuyerType ?? 'Unknown',
      businessCategory: _businessCategoryController.text,
      address: _addressController.text,
      city: _cityController.text,
      state: _stateController.text,
      pincode: _pincodeController.text,
      isMobileVerified: true, 
    );

    context.read<BuyerProfileProvider>().saveProfile(profile);
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, AppRouter.buyerVerificationRoute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Buyer Setup',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: const [
          AppTopBarControls(showLabels: false),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading ? const Center(child: LoadingIndicator()) : SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 1) { 
                  setState(() => _currentStep += 1);
                } else {
                  _onComplete();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                } else {
                  Navigator.pop(context);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _currentStep == 1 ? 'Complete Setup' : 'Continue',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 52,
                          child: TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Back'),
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: Text('Basic Information', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  isActive: _currentStep >= 0,
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BuyerAuthTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          prefixIcon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        BuyerAuthTextField(
                          controller: _businessNameController,
                          label: 'Business / Organization Name',
                          hint: 'Optional',
                          prefixIcon: Icons.business_outlined,
                        ),
                        const SizedBox(height: 16),
                        BuyerAuthTextField(
                          controller: _mobileController,
                          label: 'Mobile Number',
                          hint: 'Enter 10-digit mobile number',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        BuyerAuthTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Enter your email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          'Buyer Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Select buyer type',
                            prefixIcon: Icon(Icons.category_outlined, color: theme.colorScheme.primary, size: 22),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
                          ),
                          value: _selectedBuyerType,
                          items: _buyerTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) => setState(() => _selectedBuyerType = val),
                        ),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: Text('Business Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  isActive: _currentStep >= 1,
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BuyerAuthTextField(
                          controller: _businessCategoryController,
                          label: 'Business Category',
                          hint: 'E.g. Spices, Textiles',
                          prefixIcon: Icons.storefront_outlined,
                        ),
                        const SizedBox(height: 16),
                        BuyerAuthTextField(
                          controller: _addressController,
                          label: 'Business Address',
                          hint: 'Enter full address',
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: BuyerAuthTextField(
                                controller: _cityController,
                                label: 'City',
                                hint: 'City',
                                prefixIcon: Icons.location_city_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: BuyerAuthTextField(
                                controller: _stateController,
                                label: 'State',
                                hint: 'State',
                                prefixIcon: Icons.map_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        BuyerAuthTextField(
                          controller: _pincodeController,
                          label: 'Pincode',
                          hint: '6-digit pincode',
                          prefixIcon: Icons.pin_drop_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
