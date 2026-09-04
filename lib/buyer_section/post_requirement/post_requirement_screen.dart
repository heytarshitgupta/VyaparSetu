import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/mock_data/requests.dart';
import '../../../core/routes/app_router.dart';
import 'requests_provider.dart';

class PostRequirementScreen extends StatefulWidget {
  final String? prefilledCategory;

  const PostRequirementScreen({super.key, this.prefilledCategory});

  @override
  State<PostRequirementScreen> createState() => _PostRequirementScreenState();
}

class _PostRequirementScreenState extends State<PostRequirementScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _categoryController;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController(text: 'New Delhi, India');
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _specsController = TextEditingController();
  final TextEditingController _customizationController = TextEditingController();
  
  String _selectedUnit = 'kg';
  DateTime? _requiredByDate;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.prefilledCategory ?? '');
    
    _categoryController.addListener(_validateForm);
    _quantityController.addListener(_validateForm);
    _locationController.addListener(_validateForm);
    _specsController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _specsController.dispose();
    _customizationController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid = _categoryController.text.trim().isNotEmpty &&
        _quantityController.text.trim().isNotEmpty &&
        _locationController.text.trim().isNotEmpty &&
        _requiredByDate != null;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _requiredByDate = picked;
      });
      _validateForm();
    }
  }

  void _submit() {
    if (!_isFormValid) return;

    final newRequest = BuyerRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Requirement for ${_categoryController.text.trim()}',
      status: 'Open',
      date: 'Just Now',
      quantity: '${_quantityController.text.trim()} $_selectedUnit',
    );

    Provider.of<RequestsProvider>(context, listen: false).addRequest(newRequest);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: const Text('Your request has been posted. Producers matching your requirement will be notified.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context, AppRouter.myRequestsRoute);
            },
            child: const Text('View My Requests'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        children: [
          TextSpan(
            text: ' (Optional)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post Requirement', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildRequiredLabel('Product / Category'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Organic Cotton, Handwoven Baskets...',
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildRequiredLabel('Quantity'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Amount',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            items: ['kg', 'pcs', 'liters', 'tons'].map((unit) {
                              return DropdownMenuItem(value: unit, child: Text(unit));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedUnit = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildRequiredLabel('Location'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildRequiredLabel('Required By'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.calendar_today, color: AppColors.textSecondary),
                        ),
                        child: Text(
                          _requiredByDate == null
                              ? 'Select Date'
                              : DateFormat('MMM dd, yyyy').format(_requiredByDate!),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _requiredByDate == null ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildOptionalLabel('Budget'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        hintText: 'Enter estimated budget',
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildOptionalLabel('Specifications'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _specsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Provide details about quality, packaging, etc.',
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildOptionalLabel('Customization'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customizationController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Any specific customization needed?',
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildOptionalLabel('Reference Image'),
                    const SizedBox(height: 4),
                    Text(
                      'Optional, skip if you don\'t have one',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image picker opens...')));
                      },
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 40, color: AppColors.textSecondary),
                              SizedBox(height: 8),
                              Text('Tap to upload image', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
          
          // Sticky Bottom Submit Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: PrimaryButton(
                    text: 'Submit Requirement',
                    onPressed: _isFormValid ? _submit : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
