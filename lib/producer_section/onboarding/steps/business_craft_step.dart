import 'package:flutter/material.dart';
import '../../../core/localization/generated/app_localizations.dart';
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

  String _getLocalizedCategoryName(String category, AppLocalizations? l10n) {
    if (l10n == null) return category;
    switch (category) {
      case 'Food & Homemade Products':
        return l10n.catFood;
      case 'Handicrafts':
        return l10n.catHandicrafts;
      case 'Handloom & Textiles':
        return l10n.catHandloom;
      case 'Clothing & Embroidery':
        return l10n.catClothing;
      case 'Jewellery & Accessories':
        return l10n.catJewellery;
      case 'Woodwork':
        return l10n.catWoodwork;
      case 'Metal Craft':
        return l10n.catMetalCraft;
      case 'Home Decor':
        return l10n.catHomeDecor;
      case 'Beauty / Personal Care':
        return l10n.catBeauty;
      case 'Other':
        return l10n.catOther;
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final provider = widget.provider;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n?.step2Header ?? 'Business & Craft Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            l10n?.step2Description ??
                'Tell buyers about your enterprise, workshop, or home-based artisanal work.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
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
          Text(
            l10n?.businessNameLabel ?? 'Business / Workshop Name *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('producer_onboarding_business_name_field'),
            controller: _businessNameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (val) => provider.setBusinessName(val),
            decoration: InputDecoration(
              hintText: l10n?.businessNameHint ?? 'e.g. Sharma Pickles, Punjab Phulkari Works',
              prefixIcon: const Icon(Icons.store_outlined, size: 20),
              helperText: l10n?.businessNameHelper ?? 'Name of your business, workshop, or home-based work',
              helperMaxLines: 2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ------------------------------------------------------------------
          // 2. CRAFT / PRODUCT CATEGORY
          // ------------------------------------------------------------------
          Text(
            l10n?.craftCategoryLabel ?? 'Craft / Product Category *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.craftCategoryHelper ??
                'Select your main product category so commercial buyers can find you easily',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ProducerOnboardingProvider.standardCategories.map((category) {
              final isSelected = provider.craftCategory == category;
              final localizedCategory = _getLocalizedCategoryName(category, l10n);
              return ChoiceChip(
                key: Key('category_chip_${category.replaceAll(' ', '_')}'),
                avatar: Icon(
                  _getCategoryIcon(category),
                  size: 16,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                label: Text(
                  localizedCategory,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ),
                ),
                selected: isSelected,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                backgroundColor: theme.colorScheme.surface,
                side: BorderSide(
                  color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
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
            Text(
              l10n?.specifyCategory ?? 'Specify Your Category *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              key: const Key('producer_onboarding_custom_category_field'),
              controller: _customCategoryController,
              textCapitalization: TextCapitalization.words,
              onChanged: (val) => provider.setCustomCategory(val),
              decoration: InputDecoration(
                hintText: l10n?.specifyCategoryHint ?? 'e.g. Bamboo Crafts, Clay Pottery, Stone Carving',
                prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                helperText: l10n?.specifyCategoryHelper ?? 'Enter your custom artisanal or product category',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
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
              Expanded(
                child: Text(
                  l10n?.shortDescriptionLabel ?? 'Short Description (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
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
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
              hintText: l10n?.shortDescriptionHint ??
                  'Tell buyers what you make in a few words (e.g. handwoven cotton stoles using organic natural dyes)',
              helperText: l10n?.shortDescriptionHelper ?? 'Tell buyers what you make in a few words',
              helperMaxLines: 2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
