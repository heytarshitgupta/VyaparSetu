import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../models/product_price_parser.dart';
import '../providers/add_product_provider.dart';
import '../services/producer_image_picker_service.dart';
import '../services/producer_product_image_service.dart';
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
  final IProducerProductImageService? imageService;
  final IProducerImagePickerService? imagePickerService;

  const AddProductScreen({
    super.key,
    this.provider,
    this.productService,
    this.imageService,
    this.imagePickerService,
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
          imageService: widget.imageService,
          imagePickerService: widget.imagePickerService,
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

  Future<void> _onPickImage(ImageSourceOption source, AppLocalizations l10n) async {
    final success = await _provider.pickAndUploadImage(source);
    if (!success && mounted && _provider.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? l10n.photoUploadFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _onRemoveImage(String storagePath, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removePhotoAction),
        content: Text(l10n.removePhotoConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.deletePhoto),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _provider.removeImage(storagePath);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.photoRemovedMessage),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (_provider.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_provider.errorMessage ?? l10n.photoUploadFailed),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _showPhotoSourceBottomSheet(AppLocalizations l10n, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Text(
                    l10n.choosePhotoSource,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(Icons.camera_alt_outlined, color: colorScheme.primary),
                  ),
                  title: Text(
                    l10n.takePhotoAction,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _onPickImage(ImageSourceOption.camera, l10n);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.secondaryContainer,
                    child: Icon(Icons.photo_library_outlined, color: colorScheme.secondary),
                  ),
                  title: Text(
                    l10n.chooseFromGalleryAction,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _onPickImage(ImageSourceOption.gallery, l10n);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoTile(
    String storagePath,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    final signedUrl = _provider.signedUrls[storagePath];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (signedUrl != null)
            Image.network(
              signedUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 32,
                  color: colorScheme.error,
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                );
              },
            )
          else
            FutureBuilder<String?>(
              future: _provider.getOrFetchSignedUrl(storagePath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final url = snapshot.data;
                if (url != null) {
                  return Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 32,
                        color: colorScheme.error,
                      ),
                    ),
                  );
                }
                return Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 32,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                );
              },
            ),
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: (_provider.isSaving || _provider.isUploadingImage)
                    ? null
                    : () => _onRemoveImage(storagePath, l10n),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingTile(ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              l10n.uploadingPhotoProgress,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoTile(ColorScheme colorScheme, AppLocalizations l10n) {
    final isBlocked = _provider.isSaving || _provider.isUploadingImage;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isBlocked ? null : () => _showPhotoSourceBottomSheet(l10n, colorScheme),
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
              size: 34,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addPhotosHeading,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
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
    final images = _provider.draft.images;
    final isFull = images.length >= 4;

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
            if (index < images.length) {
              return _buildPhotoTile(images[index], l10n, colorScheme);
            }
            if (_provider.isUploadingImage && index == images.length) {
              return _buildUploadingTile(colorScheme, l10n);
            }
            if (!_provider.isUploadingImage && !isFull && index == images.length) {
              return _buildAddPhotoTile(colorScheme, l10n);
            }
            // Empty placeholder slot
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 32,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            );
          },
        ),

        // Max photos reached badge
        if (isFull) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.maxPhotosReached,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

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
            final isBusy = _provider.isSaving || _provider.isUploadingImage;

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: (isBusy || !_provider.canMarkActive)
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
                    onPressed: isBusy ? null : () => _onSaveDraft(l10n),
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
                    onPressed: isBusy ? null : () => _provider.goToStep(2),
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
                    onPressed: isBusy ? null : () => _provider.goToStep(2),
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
                    onPressed: isBusy ? null : () => _onSaveDraft(l10n),
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
                    onPressed: (isBusy || !_provider.canMarkActive)
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
