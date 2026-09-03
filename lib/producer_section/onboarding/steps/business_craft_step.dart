import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../producer_onboarding_provider.dart';

class BusinessCraftStep extends StatefulWidget {
  final ProducerOnboardingProvider provider;

  const BusinessCraftStep({
    super.key,
    required this.provider,
  });

  @override
  State<BusinessCraftStep> createState() => _BusinessCraftStepState();
}

class _BusinessCraftStepState extends State<BusinessCraftStep> {
  late final TextEditingController _businessNameController;
  late final TextEditingController _customCategoryController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.provider.businessName);
    _customCategoryController = TextEditingController(text: widget.provider.customCategory);
    _descriptionController = TextEditingController(text: widget.provider.businessDescription);
  }

  @override
  void didUpdateWidget(covariant BusinessCraftStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.provider.businessName != _businessNameController.text) {
      _businessNameController.text = widget.provider.businessName;
    }
    if (widget.provider.customCategory != _customCategoryController.text) {
      _customCategoryController.text = widget.provider.customCategory;
    }
    if (widget.provider.businessDescription != _descriptionController.text) {
      _descriptionController.text = widget.provider.businessDescription;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _customCategoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Homemade Products':
        return Icons.restaurant;
      case 'Handicrafts':
        return Icons.palette_outlined;
      case 'Handloom & Textiles':
        return Icons.texture;
      case 'Clothing & Embroidery':
        return Icons.checkroom;
      case 'Jewellery & Accessories':
        return Icons.diamond_outlined;
      case 'Woodwork':
        return Icons.carpenter_outlined;
      case 'Metal Craft':
        return Icons.hardware_outlined;
      case 'Home Decor':
        return Icons.chair_outlined;
      case 'Beauty / Personal Care':
        return Icons.spa_outlined;
      case 'Other':
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header Icon & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Business & Craft Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text(
            'Tell buyers about your enterprise, workshop, or home-based artisanal work.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Error banner if any
          if (provider.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      provider.errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ------------------------------------------------------------------
          // 1. BUSINESS / WORKSHOP NAME
          // ------------------------------------------------------------------
          const Text(
            'Business / Workshop Name *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('producer_onboarding_business_name_field'),
            controller: _businessNameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (val) => provider.setBusinessName(val),
            decoration: InputDecoration(
              hintText: 'e.g. Sharma Pickles, Punjab Phulkari Works',
              prefixIcon: const Icon(Icons.store_outlined, size: 20),
              helperText: 'Name of your business, workshop, or home-based work',
              helperMaxLines: 2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ------------------------------------------------------------------
          // 2. CRAFT / PRODUCT CATEGORY
          // ------------------------------------------------------------------
          const Text(
            'Craft / Product Category *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select your main product category so commercial buyers can find you easily',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ProducerOnboardingProvider.standardCategories.map((category) {
              final isSelected = provider.craftCategory == category;
              return ChoiceChip(
                key: Key('category_chip_${category.replaceAll(' ', '_')}'),
                avatar: Icon(
                  _getCategoryIcon(category),
                  size: 16,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                label: Text(
                  category,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (selected) {
                  if (selected) {
                    provider.setCraftCategory(category);
                  }
                },
              );
            }).toList(),
          ),

          // If "Other" selected, show custom category field
          if (provider.craftCategory == 'Other') ...[
            const SizedBox(height: 16),
            const Text(
              'Specify Your Category *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              key: const Key('producer_onboarding_custom_category_field'),
              controller: _customCategoryController,
              textCapitalization: TextCapitalization.words,
              onChanged: (val) => provider.setCustomCategory(val),
              decoration: InputDecoration(
                hintText: 'e.g. Bamboo Crafts, Clay Pottery, Stone Carving',
                prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                helperText: 'Enter your custom artisanal or product category',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // ------------------------------------------------------------------
          // 3. SHORT DESCRIPTION (BIO)
          // ------------------------------------------------------------------
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Short Description (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${provider.businessDescription.length}/500',
                style: TextStyle(
                  fontSize: 12,
                  color: provider.businessDescription.length > 500
                      ? AppColors.error
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('producer_onboarding_description_field'),
            controller: _descriptionController,
            maxLines: 4,
            minLines: 3,
            maxLength: 500,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                const SizedBox.shrink(),
            onChanged: (val) => provider.setBusinessDescription(val),
            decoration: InputDecoration(
              hintText: 'Tell buyers what you make in a few words (e.g. handwoven cotton stoles using organic natural dyes)',
              helperText: 'Tell buyers what you make in a few words',
              helperMaxLines: 2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
