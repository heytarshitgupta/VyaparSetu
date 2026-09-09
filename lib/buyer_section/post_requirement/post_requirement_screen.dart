import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/buyer_colors.dart';
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: BuyerColors.of(context).primary,
              onPrimary: Colors.white,
              onSurface: BuyerColors.of(context).textPrimary,
            ),
          ),
          child: child!,
        );
      },
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
        backgroundColor: BuyerColors.of(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: BuyerColors.of(context).badgeGreen),
            const SizedBox(width: 8),
            Text('Success', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: BuyerColors.of(context).textPrimary)),
          ],
        ),
        content: Text(
          'Your requirement has been posted. Producers matching your requirement will be notified.',
          style: GoogleFonts.inter(color: BuyerColors.of(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context, AppRouter.myRequestsRoute);
            },
            child: Text('View My Requests', style: GoogleFonts.inter(color: BuyerColors.of(context).primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: BuyerColors.of(context).textPrimary),
        children: [
          TextSpan(
            text: ' (Optional)',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: BuyerColors.of(context).textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: BuyerColors.of(context).textPrimary),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: BuyerColors.of(context).textSecondary.withOpacity(0.5)),
      filled: true,
      fillColor: BuyerColors.of(context).surface,
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: BuyerColors.of(context).borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: BuyerColors.of(context).borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: BuyerColors.of(context).primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuyerColors.of(context).background,
      appBar: AppBar(
        title: Text('Post Requirement', style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        backgroundColor: BuyerColors.of(context).surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: BuyerColors.of(context).textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BuyerColors.of(context).primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: BuyerColors.of(context).primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.campaign_outlined, color: BuyerColors.of(context).primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Describe what you need and get quotes directly from verified producers.',
                              style: GoogleFonts.inter(fontSize: 13, color: BuyerColors.of(context).primary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildRequiredLabel('Product / Category'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _categoryController,
                      style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary),
                      decoration: _buildInputDecoration('e.g. Organic Cotton, Handwoven Baskets...'),
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
                            style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary),
                            decoration: _buildInputDecoration('Amount'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            dropdownColor: BuyerColors.of(context).surface,
                            iconEnabledColor: BuyerColors.of(context).primary,
                            style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary),
                            decoration: _buildInputDecoration(''),
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
                      style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary),
                      decoration: _buildInputDecoration('City, State', prefixIcon: Icon(Icons.location_on, color: BuyerColors.of(context).textSecondary)),
                    ),
                    const SizedBox(height: 24),

                    _buildRequiredLabel('Required By'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: _buildInputDecoration('', prefixIcon: Icon(Icons.calendar_today, color: BuyerColors.of(context).textSecondary)),
                        child: Text(
                          _requiredByDate == null
                              ? 'Select Date'
                              : DateFormat('MMM dd, yyyy').format(_requiredByDate!),
                          style: GoogleFonts.inter(
                            color: _requiredByDate == null ? BuyerColors.of(context).textSecondary : BuyerColors.of(context).textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildOptionalLabel('Estimated Budget'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary),
                      decoration: _buildInputDecoration('Enter estimated budget').copyWith(
                        prefixText: '₹ ',
                        prefixStyle: GoogleFonts.inter(fontSize: 16, color: BuyerColors.of(context).textSecondary),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildOptionalLabel('Specifications'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _specsController,
                      maxLines: 3,
                      style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary),
                      decoration: _buildInputDecoration('Provide details about quality, packaging, etc.'),
                    ),
                    const SizedBox(height: 24),

                    _buildOptionalLabel('Customization'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customizationController,
                      maxLines: 3,
                      style: GoogleFonts.inter(color: BuyerColors.of(context).textPrimary),
                      decoration: _buildInputDecoration('Any specific customization needed?'),
                    ),
                    const SizedBox(height: 24),

                    _buildOptionalLabel('Reference Image'),
                    const SizedBox(height: 4),
                    Text(
                      'Optional, skip if you don\'t have one',
                      style: GoogleFonts.inter(fontSize: 12, color: BuyerColors.of(context).textSecondary),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image picker opens...')));
                      },
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: BuyerColors.of(context).surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: BuyerColors.of(context).borderLight, style: BorderStyle.solid),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 40, color: BuyerColors.of(context).textSecondary),
                              const SizedBox(height: 8),
                              Text('Tap to upload image', style: GoogleFonts.inter(color: BuyerColors.of(context).textSecondary)),
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
          
          // Sticky Bottom Submit Button
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: BuyerColors.of(context).surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isFormValid ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BuyerColors.of(context).primary,
                  disabledBackgroundColor: BuyerColors.of(context).borderLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Submit Requirement',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
