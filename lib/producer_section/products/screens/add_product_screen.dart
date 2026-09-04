import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../models/product_price_parser.dart';
import '../providers/add_product_provider.dart';
import '../services/producer_product_service.dart';

/// The 3-step guided Add Product screen for grassroots artisan producers.
///
/// Steps:
/// 1. What do you make? (Name, Category, Unit)
/// 2. Price & Details (Price in Rupees, Description)
/// 3. Add Photos & Save (Visual photo slots, Save Draft, Mark Ready)
class AddProductScreen extends StatefulWidget {
  final AddProductProvider? provider;
  final IProducerProductService? productService;

  const AddProductScreen({
    super.key,
    this.provider,
    this.productService,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  late final AddProductProvider _provider;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _customCategoryController;

  String? _step1Error;
  String? _priceError;

  // Canonical categories for Step 1 chips
  static const List<String> _categories = [
    'food',
    'handicraft',
    'clothing',
    'home',
    'beauty',
    'jewellery',
    'other',
  ];

  // Canonical units for Step 1 dropdown
  static const List<String> _units = [
    'piece',
    'kg',
    'gram',
    'litre',
    'ml',
    'pack',
    'dozen',
  ];

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ??
        AddProductProvider(
          productService: widget.productService,
        );

    _nameController = TextEditingController(text: _provider.draft.name);
    _priceController = TextEditingController(
      text: _provider.draft.pricePaise != null
          ? ProductPriceParser.paiseToDecimalString(_provider.draft.pricePaise) ?? ''
          : '',
    );
    _descriptionController =
        TextEditingController(text: _provider.draft.description);
    _customCategoryController = TextEditingController(
      text: _categories.contains(_provider.draft.category) ||
              _provider.draft.category.isEmpty
          ? ''
          : _provider.draft.category,
    );

    _provider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    if (widget.provider == null) {
      _provider.dispose();
    }
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Category & Unit Localized Helpers
  // ---------------------------------------------------------------------------

  String _getCategoryLabel(String category, AppLocalizations l10n) {
    switch (category) {
      case 'food':
        return l10n.categoryFood;
      case 'handicraft':
        return l10n.categoryHandicraft;
      case 'clothing':
        return l10n.categoryClothing;
      case 'home':
        return l10n.categoryHome;
      case 'beauty':
        return l10n.categoryBeauty;
      case 'jewellery':
        return l10n.categoryJewellery;
      case 'other':
        return l10n.categoryOther;
      default:
        return category;
    }
  }

  String _getUnitLabel(String unit, AppLocalizations l10n) {
    switch (unit) {
      case 'piece':
        return l10n.unitPiece;
      case 'kg':
        return l10n.unitKg;
      case 'gram':
        return l10n.unitGram;
      case 'litre':
        return l10n.unitLitre;
      case 'ml':
        return l10n.unitMl;
      case 'pack':
        return l10n.unitPack;
      case 'dozen':
        return l10n.unitDozen;
      default:
        return unit;
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation & Form Actions
  // ---------------------------------------------------------------------------

  void _onContinueFromStep1(AppLocalizations l10n) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _step1Error = l10n.productNameRequired;
      });
      return;
    }

    setState(() {
      _step1Error = null;
    });

    _provider.setName(_nameController.text);
    _provider.goToStep(2);
  }

  Future<void> _onContinueFromStep2() async {
    // Validate price format if provided
    if (_priceController.text.trim().isNotEmpty) {
      try {
        ProductPriceParser.parseRupeesTextStrict(_priceController.text);
        setState(() {
          _priceError = null;
        });
      } on FormatException catch (e) {
        setState(() {
          _priceError = e.message;
        });
        return;
      }
    }

    // Call goToStep(3) which automatically persists the product draft
    final success = await _provider.goToStep(3);
    if (!success && mounted && _provider.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? ''),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _onSaveDraft(AppLocalizations l10n) async {
    final success = await _provider.saveDraft();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.draftSavedMessage),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? l10n.saveDraftFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _onMarkReady(AppLocalizations l10n) async {
    final success = await _provider.markReady();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.productMarkedReadyMessage),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? l10n.markReadyFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addProduct),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isNarrow = width < 640;
            final maxWidth = isNarrow ? double.infinity : (width < 1024 ? 640.0 : 720.0);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 16.0 : 24.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStepIndicator(l10n, colorScheme, theme),
                      const SizedBox(height: 24),
                      if (_provider.currentStep == 1)
                        _buildStep1(l10n, colorScheme, theme)
                      else if (_provider.currentStep == 2)
                        _buildStep2(l10n, colorScheme, theme)
                      else
                        _buildStep3(l10n, colorScheme, theme),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step Indicator Widget
  // ---------------------------------------------------------------------------

  Widget _buildStepIndicator(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final current = _provider.currentStep;
    final String stepTitle;
    if (current == 1) {
      stepTitle = l10n.addProductStep1Title;
    } else if (current == 2) {
      stepTitle = l10n.addProductStep2Title;
    } else {
      stepTitle = l10n.addProductStep3Title;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step count and title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.stepCount(current, 3),
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                stepTitle,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Visual progress bar with step numbers
        Row(
          children: [
            _buildStepCircle(1, current, colorScheme),
            Expanded(child: _buildStepLine(1 < current, colorScheme)),
            _buildStepCircle(2, current, colorScheme),
            Expanded(child: _buildStepLine(2 < current, colorScheme)),
            _buildStepCircle(3, current, colorScheme),
          ],
        ),
      ],
    );
  }

  Widget _buildStepCircle(int step, int currentStep, ColorScheme colorScheme) {
    final isDone = step < currentStep;
    final isCurrent = step == currentStep;

    final Color bgColor;
    final Color fgColor;
    final Border? border;

    if (isDone) {
      bgColor = colorScheme.primary;
      fgColor = colorScheme.onPrimary;
      border = null;
    } else if (isCurrent) {
      bgColor = colorScheme.primaryContainer;
      fgColor = colorScheme.onPrimaryContainer;
      border = Border.all(color: colorScheme.primary, width: 2.5);
    } else {
      bgColor = colorScheme.surfaceContainerHighest;
      fgColor = colorScheme.onSurfaceVariant;
      border = Border.all(color: colorScheme.outlineVariant, width: 1);
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Center(
        child: isDone
            ? Icon(Icons.check, size: 20, color: fgColor)
            : Text(
                '$step',
                style: TextStyle(
                  color: fgColor,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }

  Widget _buildStepLine(bool isDone, ColorScheme colorScheme) {
    return Container(
      height: 3,
      color: isDone ? colorScheme.primary : colorScheme.outlineVariant,
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1 — WHAT DO YOU MAKE?
  // ---------------------------------------------------------------------------

  Widget _buildStep1(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isOtherSelected = _provider.draft.category == 'other' ||
        (!_categories.contains(_provider.draft.category) &&
            _provider.draft.category.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Product Name Field
        Text(
          l10n.productNameLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: l10n.productNameHint,
            prefixIcon: const Icon(Icons.shopping_bag_outlined),
            errorText: _step1Error,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) {
            _provider.setName(val);
            if (_step1Error != null) {
              setState(() {
                _step1Error = null;
              });
            }
          },
        ),
        const SizedBox(height: 24),

        // Category Selector Chips
        Text(
          l10n.categoryLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 10.0,
          children: _categories.map((cat) {
            final isSelected = _provider.draft.category == cat ||
                (cat == 'other' && isOtherSelected);

            return ChoiceChip(
              label: Text(
                _getCategoryLabel(cat, l10n),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
              selected: isSelected,
              avatar: isSelected ? const Icon(Icons.check, size: 18) : null,
              onSelected: (selected) {
                if (selected) {
                  if (cat == 'other') {
                    _provider.setCategory(_customCategoryController.text.trim().isEmpty
                        ? 'other'
                        : _customCategoryController.text.trim());
                  } else {
                    _provider.setCategory(cat);
                  }
                }
              },
            );
          }).toList(),
        ),

        // Custom Category text if "Other" is chosen
        if (isOtherSelected) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customCategoryController,
            decoration: InputDecoration(
              labelText: l10n.customCategoryLabel,
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) {
              _provider.setCategory(val.trim().isEmpty ? 'other' : val.trim());
            },
          ),
        ],
        const SizedBox(height: 24),

        // Unit Selector
        Text(
          l10n.unitLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _units.contains(_provider.draft.unit)
              ? _provider.draft.unit
              : 'piece',
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.straighten_outlined),
          ),
          items: _units.map((unit) {
            return DropdownMenuItem<String>(
              value: unit,
              child: Text(
                _getUnitLabel(unit, l10n),
                style: const TextStyle(fontSize: 15),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              _provider.setUnit(val);
            }
          },
        ),
        const SizedBox(height: 32),

        // Continue Button
        FilledButton(
          onPressed: () => _onContinueFromStep1(l10n),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
          child: Text(
            l10n.continueButton,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2 — PRICE & DETAILS
  // ---------------------------------------------------------------------------

  Widget _buildStep2(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Price Field
        Text(
          l10n.priceLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            hintText: '250',
            helperText: l10n.priceHelper,
            errorText: _priceError,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) {
            final valid = _provider.setPriceFromRupeesText(val);
            setState(() {
              _priceError = valid ? null : _provider.errorMessage;
            });
          },
        ),
        const SizedBox(height: 24),

        // Description Field
        Text(
          l10n.descriptionLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _descriptionController,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.descriptionHelper,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) {
            _provider.setDescription(val);
          },
        ),
        const SizedBox(height: 32),

        // Navigation Row: Back + Continue
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _provider.isSaving ? null : () => _provider.goToStep(1),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                ),
                child: Text(l10n.back),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: _provider.isSaving ? null : _onContinueFromStep2,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 52),
                ),
                child: _provider.isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.continueButton,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3 — ADD PHOTOS & SAVE
  // ---------------------------------------------------------------------------

  Widget _buildStep3(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Heading & Subtitle
        Text(
          l10n.addPhotosHeading,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.addPhotosSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),

        // Photo Grid (4 slots)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            if (index == 0) {
              // Add Photo action tile
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Truthful temporary feedback: photo picker is in next step (6C.6)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.photoUploadComingNext),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 36,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.addPhotosHeading,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Other placeholder slots
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 32,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Truthful coming-next banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.photoUploadComingNext,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Mark Ready Guidance if not yet ready
        if (!_provider.canMarkActive) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.markReadyGuidance,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Action Buttons: Back, Save Draft, Mark Ready
        LayoutBuilder(
          builder: (context, buttonConstraints) {
            final isCompact = buttonConstraints.maxWidth < 360;

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: (_provider.isSaving || !_provider.canMarkActive)
                        ? null
                        : () => _onMarkReady(l10n),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _provider.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.markReadyAction,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _provider.isSaving ? null : () => _onSaveDraft(l10n),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _provider.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.saveDraftAction),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _provider.isSaving ? null : () => _provider.goToStep(2),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(l10n.back),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _provider.isSaving ? null : () => _provider.goToStep(2),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
                    child: Text(l10n.back),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: _provider.isSaving ? null : () => _onSaveDraft(l10n),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
                    child: _provider.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.saveDraftAction),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: (_provider.isSaving || !_provider.canMarkActive)
                        ? null
                        : () => _onMarkReady(l10n),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
                    child: _provider.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.markReadyAction,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
