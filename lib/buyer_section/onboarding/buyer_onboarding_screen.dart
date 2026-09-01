import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_router.dart';
import 'buyer_profile_provider.dart';

class BuyerOnboardingScreen extends StatefulWidget {
  const BuyerOnboardingScreen({super.key});

  @override
  State<BuyerOnboardingScreen> createState() => _BuyerOnboardingScreenState();
}

class _BuyerOnboardingScreenState extends State<BuyerOnboardingScreen> {
  int _currentStep = 0;

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
  final _gstinController = TextEditingController();
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
    _gstinController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _onComplete() {
    final profile = BuyerProfile(
      name: _nameController.text,
      businessName: _businessNameController.text,
      mobile: _mobileController.text,
      email: _emailController.text,
      buyerType: _selectedBuyerType ?? 'Unknown',
      businessCategory: _businessCategoryController.text,
      gstin: _gstinController.text,
      address: _addressController.text,
      city: _cityController.text,
      state: _stateController.text,
      pincode: _pincodeController.text,
      isMobileVerified: true, 
    );

    context.read<BuyerProfileProvider>().saveProfile(profile);
    Navigator.pushReplacementNamed(context, AppRouter.buyerVerificationRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Setup'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 1) { // Only 2 steps now (0 and 1)
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
        steps: [
          Step(
            title: const Text('Basic Information'),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(controller: _businessNameController, decoration: const InputDecoration(labelText: 'Business / Organization Name (Optional)')),
                const SizedBox(height: 12),
                TextField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Mobile Number'), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address'), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Buyer Type'),
                  value: _selectedBuyerType,
                  items: _buyerTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => _selectedBuyerType = val),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Business Details'),
            isActive: _currentStep >= 1,
            content: Column(
              children: [
                TextField(controller: _businessCategoryController, decoration: const InputDecoration(labelText: 'Business Category')),
                const SizedBox(height: 12),
                TextField(
                  controller: _gstinController, 
                  decoration: const InputDecoration(
                    labelText: 'GSTIN',
                    helperText: 'Verification paused for now',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Business Address')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'City'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _stateController, decoration: const InputDecoration(labelText: 'State'))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: _pincodeController, decoration: const InputDecoration(labelText: 'Pincode'), keyboardType: TextInputType.number),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
