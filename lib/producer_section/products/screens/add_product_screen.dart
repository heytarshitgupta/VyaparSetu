import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/services/pricing_api_service.dart';
import '../models/producer_product.dart';
import '../models/product_price_parser.dart';
import '../providers/add_product_provider.dart';
import '../services/producer_image_picker_service.dart';
import '../services/producer_product_enhancement_service.dart';
import '../services/producer_product_image_service.dart';
import '../services/producer_product_service.dart';

/// The responsive single-sheet Add Product modal for artisan producers.
///
/// Presents all product details (photos, name, category, unit, price, description)
/// in ONE focused form without wizard step navigation.
///
/// Responsive constraints:
/// - Narrow screens (<640px): Near full-height bottom sheet with rounded top corners.
/// - Tablet / Desktop / Web (>=640px): Centered modal card (max 840px width, max 90vh).
class AddProductScreen extends StatefulWidget {
  final ProducerProduct? existingProduct;
  final AddProductProvider? provider;
  final IProducerProductService? productService;
  final IProducerProductImageService? imageService;
  final IProducerImagePickerService? imagePickerService;
  final IProductPhotoEnhancementService? enhancementService;
  final String? pricingProfileId;
  final Future<PricingApiResponse?> Function(PricingRequestV2 request)? pricingFetcher;

  const AddProductScreen({
    super.key,
    this.existingProduct,
    this.provider,
    this.productService,
    this.imageService,
    this.imagePickerService,
    this.enhancementService,
    this.pricingProfileId,
    this.pricingFetcher,
  });

  /// Opens the Add Product screen as a responsive modal bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    ProducerProduct? existingProduct,
    AddProductProvider? provider,
    IProducerProductService? productService,
    IProducerProductImageService? imageService,
    IProducerImagePickerService? imagePickerService,
    IProductPhotoEnhancementService? enhancementService,
    String? pricingProfileId,
    Future<PricingApiResponse?> Function(PricingRequestV2 request)? pricingFetcher,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AddProductScreen(
            existingProduct: existingProduct,
            provider: provider,
            productService: productService,
            imageService: imageService,
            imagePickerService: imagePickerService,
            enhancementService: enhancementService,
            pricingProfileId: pricingProfileId,
            pricingFetcher: pricingFetcher,
          ),
        ),
      ),
    );
  }

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  late final AddProductProvider _provider;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _customCategoryController;
  late final FocusNode _nameFocusNode;
  final SpeechToText _speech = SpeechToText();

  String? _nameError;
  String? _categoryError;
  String? _priceError;
  bool _isListening = false;
  String _spokenText = '';
  bool _isLoading = false;
  bool _isPricingLoading = false;
  String? _hindiTitle;
  String? _hindiDescription;

  // Canonical categories
  static const List<String> _categories = [
    'food',
    'handicraft',
    'clothing',
    'home',
    'beauty',
    'jewellery',
    'other',
  ];

  // Canonical units
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
    _provider =
        widget.provider ??
        (widget.existingProduct != null
            ? AddProductProvider.forExistingProduct(
                product: widget.existingProduct!,
                productService: widget.productService,
                imageService:
                    widget.imageService ?? widget.productService?.imageService,
                imagePickerService: widget.imagePickerService,
                enhancementService: widget.enhancementService,
              )
            : AddProductProvider(
                productService: widget.productService,
                imageService:
                    widget.imageService ?? widget.productService?.imageService,
                imagePickerService: widget.imagePickerService,
                enhancementService: widget.enhancementService,
              ));

    _nameController = TextEditingController(text: _provider.draft.name);
    _priceController = TextEditingController(
      text: _provider.draft.pricePaise != null
          ? ProductPriceParser.paiseToDecimalString(
                  _provider.draft.pricePaise,
                ) ??
                ''
          : '',
    );
    _descriptionController = TextEditingController(
      text: _provider.draft.description,
    );
    _customCategoryController = TextEditingController(
      text:
          _categories.contains(_provider.draft.category) ||
              _provider.draft.category.isEmpty
          ? ''
          : _provider.draft.category,
    );
    _nameFocusNode = FocusNode();

    _provider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _speech.stop();
    _provider.removeListener(_onProviderChanged);
    if (widget.provider == null) {
      _provider.dispose();
    }
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    if (_isLoading) return;

    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
      await _generateCatalog();
      return;
    }

    final available = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not access speech recognition: ${error.errorMsg}',
            ),
          ),
        );
      },
    );

    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available on this device.'),
        ),
      );
      return;
    }

    setState(() {
      _spokenText = '';
      _isListening = true;
      _hindiTitle = null;
      _hindiDescription = null;
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _spokenText = result.recognizedWords);
      },
    );
  }

  Future<void> _generateCatalog() async {
    final transcript = _spokenText.trim();
    if (transcript.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await http
          .post(
            Uri.parse(
              'http://${kIsWeb || defaultTargetPlatform != TargetPlatform.android ? 'localhost' : '10.0.2.2'}:8000/api/generate-catalog',
            ),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'transcript': transcript}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Catalog service returned HTTP ${response.statusCode}.',
        );
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const FormatException('Invalid catalog response.');
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Catalog data is missing.');
      }

      final english = data['english'];
      final hindi = data['hindi'];
      final englishTitle = english is Map
          ? english['title']?.toString().trim()
          : null;
      final englishDescription = english is Map
          ? english['description']?.toString().trim()
          : null;
      final hindiTitle = hindi is Map
          ? hindi['title']?.toString().trim()
          : null;
      final hindiDescription = hindi is Map
          ? hindi['description']?.toString().trim()
          : null;

      if (englishTitle == null ||
          englishTitle.isEmpty ||
          englishDescription == null ||
          englishDescription.isEmpty) {
        throw const FormatException('English catalog fields are missing.');
      }

      if (!mounted) return;
      _nameController
        ..text = englishTitle
        ..selection = TextSelection.collapsed(offset: englishTitle.length);
      _descriptionController
        ..text = englishDescription
        ..selection = TextSelection.collapsed(
          offset: englishDescription.length,
        );
      _provider.setName(englishTitle);
      _provider.setDescription(englishDescription);
      setState(() {
        _hindiTitle = hindiTitle;
        _hindiDescription = hindiDescription;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to generate catalog. Please try again. ($error)',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
  // Photo Selection & Actions
  // ---------------------------------------------------------------------------

  String _resolveErrorMessage(AppLocalizations l10n) {
    final code = _provider.lastErrorCode;
    if (code != null) {
      switch (code) {
        case ProductPhotoErrorCode.pickerUnavailable:
          return l10n.pickerUnavailableError;
        case ProductPhotoErrorCode.storageUnavailable:
          return l10n.storageUnavailableError;
        case ProductPhotoErrorCode.unsupportedFormat:
          return l10n.unsupportedPhotoFormat;
        case ProductPhotoErrorCode.imageTooLarge:
          return l10n.photoTooLarge;
        case ProductPhotoErrorCode.maxPhotosExceeded:
          return l10n.maxPhotosReached;
        case ProductPhotoErrorCode.uploadFailed:
          return l10n.photoUploadFailed;
        case ProductPhotoErrorCode.nameRequired:
          return l10n.addPhotosNameFirst;
        case ProductPhotoErrorCode.authRequired:
        case ProductPhotoErrorCode.operationFailed:
          return _provider.errorMessage ?? l10n.photoUploadFailed;
      }
    }
    return _provider.errorMessage ?? l10n.photoUploadFailed;
  }

  Future<void> _onPickImage(
    ImageSourceOption source,
    AppLocalizations l10n,
  ) async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = l10n.addPhotosNameFirst;
      });
      _nameFocusNode.requestFocus();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addPhotosNameFirst)));
      return;
    }

    if (_provider.isUploadingImage || _provider.isSaving) {
      return;
    }

    final success = await _provider.pickAndUploadImage(source);
    if (!mounted) return;

    if (!success && _provider.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_resolveErrorMessage(l10n))));
    }
  }

  void _showPhotoSourceSelector(AppLocalizations l10n) {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = l10n.addPhotosNameFirst;
      });
      _nameFocusNode.requestFocus();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addPhotosNameFirst)));
      return;
    }

    if (_provider.isUploadingImage || _provider.isSaving) {
      return;
    }

    final pickerSvc = widget.imagePickerService ?? _provider.imagePickerService;

    // If camera is unsupported (e.g. web), directly choose photo from gallery/file input
    if (!pickerSvc.isCameraSupported) {
      _onPickImage(ImageSourceOption.gallery, l10n);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  l10n.choosePhotoSource,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.takePhotoAction),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _onPickImage(ImageSourceOption.camera, l10n);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.chooseFromGalleryAction),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _onPickImage(ImageSourceOption.gallery, l10n);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onRemovePhoto(String storagePath, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.removePhotoAction),
        content: Text(l10n.removePhotoConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.exit),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deletePhoto),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _provider.removeImage(storagePath);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.photoRemovedMessage)));
      }
    }
  }

  Future<void> _onImprovePhoto(
    String storagePath,
    AppLocalizations l10n,
  ) async {
    final success = await _provider.improvePhoto(storagePath);
    if (!mounted) return;

    if (success) {
      _showComparisonModal(storagePath, l10n);
    } else {
      final msg = _provider.errorMessage ?? l10n.photoImproveFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          action: SnackBarAction(
            label: l10n.tryAgain,
            onPressed: () => _onImprovePhoto(storagePath, l10n),
          ),
        ),
      );
    }
  }

  void _showComparisonModal(String storagePath, AppLocalizations l10n) {
    final candidatePath = _provider.getCandidateForPhoto(storagePath);
    if (candidatePath == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        final colorScheme = Theme.of(modalContext).colorScheme;
        final theme = Theme.of(modalContext);

        return ListenableBuilder(
          listenable: _provider,
          builder: (context, _) {
            final originalUrl = _provider.signedUrls[storagePath];
            final candidateUrl = _provider.signedUrls[candidatePath];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.photoImprovedTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.aiImproveDisclaimer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.aiImproveHelpText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Side-by-side or stacked preview cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 360;

                      final originalCard = _buildComparisonCard(
                        title: l10n.originalPhotoLabel,
                        url: originalUrl,
                        storagePath: storagePath,
                        colorScheme: colorScheme,
                        theme: theme,
                      );

                      final improvedCard = _buildComparisonCard(
                        title: l10n.improvedPhotoLabel,
                        url: candidateUrl,
                        storagePath: candidatePath,
                        colorScheme: colorScheme,
                        theme: theme,
                        isImproved: true,
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            originalCard,
                            const SizedBox(height: 12),
                            improvedCard,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: originalCard),
                          const SizedBox(width: 12),
                          Expanded(child: improvedCard),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Action buttons: Keep Original vs Use Improved Photo
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final navigator = Navigator.of(modalContext);
                            if (modalContext.mounted) {
                              navigator.pop();
                            }
                            await _provider.keepOriginalPhoto(storagePath);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: Text(l10n.keepOriginalAction),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(l10n.useImprovedAction),
                          onPressed: () async {
                            final navigator = Navigator.of(modalContext);
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await _provider.useImprovedPhoto(
                              storagePath,
                            );
                            if (modalContext.mounted) {
                              navigator.pop();
                            }
                            if (mounted) {
                              if (success) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.photoImproveSuccessMessage,
                                    ),
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _provider.errorMessage ??
                                          l10n.photoImproveFailed,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required String? url,
    required String storagePath,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool isImproved = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isImproved ? colorScheme.primary : colorScheme.outlineVariant,
          width: isImproved ? 2.0 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            color: isImproved
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isImproved) ...[
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isImproved
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1.0,
            child: url != null
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: colorScheme.error,
                      ),
                    ),
                  )
                : FutureBuilder<String?>(
                    future: _provider.getOrFetchSignedUrl(storagePath),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      final fetched = snapshot.data;
                      if (fetched != null) {
                        return Image.network(
                          fetched,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: colorScheme.error,
                            ),
                          ),
                        );
                      }
                      return Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Save & Mark Ready Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onSaveDraft(AppLocalizations l10n) async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = l10n.productNameRequired;
      });
      _nameFocusNode.requestFocus();
      return;
    }

    final success = await _provider.saveDraft();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.draftSavedMessage)));
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_provider.errorMessage ?? l10n.saveDraftFailed)),
      );
    }
  }

  Future<void> _onSaveChanges(AppLocalizations l10n) async {
    bool hasValidationError = false;

    if (_nameController.text.trim().length < 2) {
      setState(() {
        _nameError = l10n.productNameRequired;
      });
      _nameFocusNode.requestFocus();
      hasValidationError = true;
    }

    if (_provider.existingStatus == ProductStatus.active) {
      if (_provider.draft.category.trim().length < 2) {
        setState(() {
          _categoryError = l10n.categoryLabel;
        });
        hasValidationError = true;
      }
      if (_provider.draft.pricePaise == null ||
          _provider.draft.pricePaise! <= 0) {
        setState(() {
          _priceError = l10n.priceInvalidError;
        });
        hasValidationError = true;
      }
    }

    if (hasValidationError) {
      return;
    }

    final success = await _provider.saveChanges();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.productUpdatedSuccess)));
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? l10n.couldNotUpdateProduct),
        ),
      );
    }
  }

  Future<void> _onAddProduct(AppLocalizations l10n) async {
    bool hasValidationError = false;

    if (_nameController.text.trim().length < 2) {
      setState(() {
        _nameError = l10n.productNameRequired;
      });
      _nameFocusNode.requestFocus();
      hasValidationError = true;
    }

    if (_provider.draft.category.trim().length < 2) {
      setState(() {
        _categoryError = l10n.categoryLabel;
      });
      hasValidationError = true;
    }

    if (_provider.draft.pricePaise == null ||
        _provider.draft.pricePaise! <= 0) {
      setState(() {
        _priceError = l10n.priceInvalidError;
      });
      hasValidationError = true;
    }

    if (hasValidationError) {
      return;
    }

    final success = await _provider.markReady();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.productMarkedReadyMessage)));
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_provider.errorMessage ?? l10n.markReadyFailed)),
      );
    }
  }

  Future<bool?> _showDiscardConfirmationDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.discardChangesTitle),
        content: Text(l10n.discardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l10n.keepEditingAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(l10n.discardAction),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_provider.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _showDiscardConfirmationDialog(
          context,
          l10n,
        );
        if (shouldDiscard == true && context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          final screenHeight = MediaQuery.of(context).size.height;
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;

          final sheetDecoration = BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          );

          Widget content = Material(
            color: Colors.transparent,
            child: Container(
              decoration: sheetDecoration,
              constraints: BoxConstraints(
                maxHeight: isWide ? screenHeight * 0.88 : screenHeight * 0.92,
                maxWidth: isWide ? 840 : double.infinity,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Drag handle & Header
                  _buildHeader(l10n, colorScheme, theme),

                  // 2. Scrollable single form
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        16 + bottomInset,
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Photos Section
                          _buildPhotosSection(l10n, colorScheme, theme),
                          const SizedBox(height: 20),

                          // Product Name
                          _buildNameField(l10n, colorScheme),
                          const SizedBox(height: 16),

                          // Category & Unit (2-column on wide screens)
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildCategorySection(
                                    l10n,
                                    colorScheme,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: _buildUnitDropdown(l10n, colorScheme),
                                ),
                              ],
                            )
                          else ...[
                            _buildCategorySection(l10n, colorScheme),
                            const SizedBox(height: 16),
                            _buildUnitDropdown(l10n, colorScheme),
                          ],
                          const SizedBox(height: 16),

                          // Price & Description
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildPriceField(l10n, colorScheme),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: _buildDescriptionField(
                                    l10n,
                                    colorScheme,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _buildPriceField(l10n, colorScheme),
                            const SizedBox(height: 16),
                            _buildDescriptionField(l10n, colorScheme),
                          ],
                          const SizedBox(height: 20),

                          // Error Banner if provider has active error
                          if (_provider.hasError) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: colorScheme.onErrorContainer,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _provider.errorMessage!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onErrorContainer,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Actions: Save Draft & Add Product
                          _buildActionButtons(l10n, colorScheme),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          content = Stack(
            fit: StackFit.passthrough,
            children: [
              content,
              if (_isLoading)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black12,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              CircularProgressIndicator(),
                              SizedBox(height: 10),
                              Text('Generating catalog...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );

          if (isWide) {
            return Align(alignment: Alignment.bottomCenter, child: content);
          }

          return content;
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Component Builders
  // ---------------------------------------------------------------------------

  Widget _buildHeader(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _provider.isEditMode
                          ? l10n.editProductTitle
                          : l10n.addProduct,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _provider.isEditMode
                          ? l10n.editProductHelper
                          : l10n.addProductHelper,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('add_product_close_button'),
                icon: const Icon(Icons.close),
                tooltip: l10n.exit,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final images = _provider.draft.images;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.productPhotosTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${images.length}/4)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Uploaded Photo Thumbnails
              for (final path in images)
                _buildPhotoThumbnail(path, l10n, colorScheme, theme),

              // Compact Add Photo Tile (if < 4 photos)
              if (images.length < 4)
                _buildAddPhotoTile(l10n, colorScheme, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(
    String storagePath,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final signedUrl = _provider.signedUrls[storagePath];
    final isBeingImproved = _provider.isPhotoBeingImproved(storagePath);
    final hasCandidate = _provider.hasCandidateForPhoto(storagePath);

    return Container(
      width: 80,
      height: 98,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasCandidate
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    width: hasCandidate ? 2.0 : 1.0,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: signedUrl != null
                    ? Image.network(
                        signedUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 24,
                            color: colorScheme.error,
                          ),
                        ),
                      )
                    : FutureBuilder<String?>(
                        future: _provider.getOrFetchSignedUrl(storagePath),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          if (snap.data != null) {
                            return Image.network(
                              snap.data!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 24,
                                      color: colorScheme.error,
                                    ),
                                  ),
                            );
                          }
                          return Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 24,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
              ),
              if (isBeingImproved)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 2,
                right: 2,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    key: Key('remove_photo_$storagePath'),
                    customBorder: const CircleBorder(),
                    onTap: isBeingImproved
                        ? null
                        : () => _onRemovePhoto(storagePath, l10n),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // AI Improve Photo action link
          InkWell(
            key: Key('improve_photo_$storagePath'),
            onTap: isBeingImproved
                ? null
                : () {
                    if (hasCandidate) {
                      _showComparisonModal(storagePath, l10n);
                    } else {
                      _onImprovePhoto(storagePath, l10n);
                    }
                  },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasCandidate ? Icons.check_circle : Icons.auto_awesome,
                    size: 11,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      hasCandidate
                          ? l10n.comparePhotosTitle
                          : l10n.improvePhotoAction,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoTile(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return InkWell(
      key: const Key('add_product_photo_button'),
      onTap: () => _showPhotoSourceSelector(l10n),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outlineVariant,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 2),
            Text(
              l10n.addPhotosHeading,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField(AppLocalizations l10n, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            key: const Key('add_product_name_field'),
            controller: _nameController,
            focusNode: _nameFocusNode,
            decoration: InputDecoration(
              labelText: '${l10n.productNameLabel} *',
              hintText: l10n.productNameHint,
              errorText: _nameError,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (val) {
              _provider.setName(val);
              if (_nameError != null) {
                setState(() {
                  _nameError = null;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          key: const Key('add_product_voice_catalog_button'),
          tooltip: _isListening
              ? 'Stop voice catalog'
              : 'Create catalog from voice',
          onPressed: _isLoading ? null : _listen,
          icon: Icon(
            _isListening ? Icons.stop_circle_outlined : Icons.mic_none_outlined,
          ),
          color: _isListening ? colorScheme.error : colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildCategorySection(AppLocalizations l10n, ColorScheme colorScheme) {
    final selectedCategory = _categories.contains(_provider.draft.category)
        ? _provider.draft.category
        : (_provider.draft.category.isNotEmpty ? 'other' : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('add_product_category_dropdown'),
          isExpanded: true,
          initialValue: selectedCategory,
          decoration: InputDecoration(
            labelText: '${l10n.categoryLabel} *',
            errorText: _categoryError,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: _categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat,
              child: Text(_getCategoryLabel(cat, l10n)),
            );
          }).toList(),
          onChanged: (val) {
            if (val == null) return;
            if (val == 'other') {
              _provider.setCategory(_customCategoryController.text.trim());
            } else {
              _provider.setCategory(val);
            }
            if (_categoryError != null) {
              setState(() {
                _categoryError = null;
              });
            }
          },
        ),
        if (selectedCategory == 'other') ...[
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('add_product_custom_category_field'),
            controller: _customCategoryController,
            decoration: InputDecoration(
              labelText: l10n.customCategoryLabel,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (val) {
              _provider.setCategory(val);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildUnitDropdown(AppLocalizations l10n, ColorScheme colorScheme) {
    final selectedUnit = _units.contains(_provider.draft.unit)
        ? _provider.draft.unit
        : (_provider.draft.unit.isNotEmpty ? _provider.draft.unit : 'piece');

    return DropdownButtonFormField<String>(
      key: const Key('add_product_unit_dropdown'),
      isExpanded: true,
      initialValue: _units.contains(selectedUnit) ? selectedUnit : null,
      decoration: InputDecoration(
        labelText: l10n.unitLabel,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: _units.map((unit) {
        return DropdownMenuItem<String>(
          value: unit,
          child: Text(_getUnitLabel(unit, l10n)),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          _provider.setUnit(val);
        }
      },
    );
  }

  Widget _buildPriceField(AppLocalizations l10n, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          key: const Key('add_product_price_field'),
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: '${l10n.priceLabel} *',
            prefixText: '₹ ',
            helperText: l10n.priceHelper,
            errorText: _priceError,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (val) {
            if (val.trim().isEmpty) {
              _provider.setPriceFromRupeesText('');
              if (_priceError != null) setState(() => _priceError = null);
              return;
            }

            final success = _provider.setPriceFromRupeesText(val);
            if (success) {
              if (_priceError != null) setState(() => _priceError = null);
            } else {
              setState(() {
                _priceError = l10n.priceInvalidError;
              });
            }
          },
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('set_good_price_button'),
            onPressed: _isPricingLoading ? null : _handleSetGoodPrice,
            icon: _isPricingLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.price_check, size: 20),
            label: Text(
              _isPricingLoading
                  ? l10n.setGoodPriceLoading
                  : l10n.setGoodPriceButton,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSetGoodPrice() async {
    final l10n = AppLocalizations.of(context);
    final category = _provider.draft.category.trim().isNotEmpty
        ? _provider.draft.category.trim()
        : _customCategoryController.text.trim();
    final description = _descriptionController.text.trim();
    final productName = _nameController.text.trim();

    // Require category and description; product_id is no longer required
    if (category.isEmpty || description.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.setGoodPriceMissingInfo ??
                'Add a product category and description first so we can suggest a price.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Open cost input sheet first, then fetch when Producer taps Get Price Suggestion
    _showCostInputSheet(
      productName: productName.isEmpty ? description : productName,
      category: category,
      description: description,
    );
  }

  void _showCostInputSheet({
    required String productName,
    required String category,
    required String description,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Cost controllers - local to this sheet
    final rawMatCtrl = TextEditingController();
    final packCtrl = TextEditingController();
    final labourCtrl = TextEditingController();
    final otherCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final marginCtrl = TextEditingController();
    String? costError;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.price_check,
                            color: colorScheme.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n?.priceGuidanceTitle ?? 'Price Guidance',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      productName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Cost inputs section
                    Text(
                      l10n?.pricingCostInputsTitle ?? 'Your making cost (optional)',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildCostField(
                            key: const Key('pricing_raw_material_field'),
                            controller: rawMatCtrl,
                            label: l10n?.pricingRawMaterialCost ?? 'Raw material cost (₹)',
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCostField(
                            key: const Key('pricing_packaging_field'),
                            controller: packCtrl,
                            label: l10n?.pricingPackagingCost ?? 'Packaging cost (₹)',
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCostField(
                            key: const Key('pricing_labour_field'),
                            controller: labourCtrl,
                            label: l10n?.pricingLabourCost ?? 'Labour cost (₹)',
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCostField(
                            key: const Key('pricing_other_cost_field'),
                            controller: otherCtrl,
                            label: l10n?.pricingOtherCost ?? 'Other cost (₹)',
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCostField(
                            key: const Key('pricing_quantity_field'),
                            controller: qtyCtrl,
                            label: l10n?.pricingProductionQuantity ?? 'Quantity made',
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCostField(
                            key: const Key('pricing_margin_field'),
                            controller: marginCtrl,
                            label: l10n?.pricingDesiredMargin ?? 'Desired profit %',
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    ),

                    if (costError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        costError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    FilledButton.icon(
                      key: const Key('pricing_get_suggestion_button'),
                      icon: const Icon(Icons.price_check, size: 18),
                      label: Text(
                        l10n?.pricingGetSuggestion ?? 'Get Price Suggestion',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () async {
                        // Client-side validation
                        double? parseOptional(TextEditingController c) {
                          final t = c.text.trim();
                          if (t.isEmpty) return null;
                          return double.tryParse(t);
                        }

                        final rawMat = parseOptional(rawMatCtrl);
                        final pack = parseOptional(packCtrl);
                        final labour = parseOptional(labourCtrl);
                        final other = parseOptional(otherCtrl);
                        final qty = parseOptional(qtyCtrl);
                        final margin = parseOptional(marginCtrl);

                        // Validate negatives
                        final hasBadCost = [rawMat, pack, labour, other].any(
                          (v) => v != null && v < 0,
                        );
                        if (hasBadCost) {
                          setSheetState(() {
                            costError = l10n?.pricingNegativeCostError ??
                                'Cost values cannot be negative';
                          });
                          return;
                        }

                        // Validate quantity
                        if (qty != null && qty <= 0) {
                          setSheetState(() {
                            costError = l10n?.pricingInvalidQuantityError ??
                                'Quantity must be greater than zero';
                          });
                          return;
                        }

                        if (margin != null && margin < 0) {
                          setSheetState(() {
                            costError = l10n?.pricingNegativeCostError ??
                                'Desired profit cannot be negative';
                          });
                          return;
                        }

                        setSheetState(() => costError = null);

                        // Build V2 request
                        final request = PricingRequestV2(
                          productName: productName,
                          category: category,
                          description: description,
                          productId: widget.pricingProfileId,
                          unit: _provider.draft.unit.isNotEmpty
                              ? _provider.draft.unit
                              : null,
                          currentPrice: _provider.draft.pricePaise != null
                              ? _provider.draft.pricePaise! / 100.0
                              : null,
                          rawMaterialCost: rawMat,
                          packagingCost: pack,
                          laborCost: labour,
                          otherCost: other,
                          productionQuantity: qty,
                          desiredMarginPercent: margin,
                        );

                        // Dismiss cost sheet, then show loading + result
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (!mounted) return;

                        setState(() => _isPricingLoading = true);
                        try {
                          final fetcher = widget.pricingFetcher ??
                              (PricingRequestV2 req) =>
                                  PricingApiService.fetchPrice(req);
                          final response = await fetcher(request);

                          if (!mounted) return;

                          if (response == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n?.priceGuidanceUnavailable ??
                                      'Price guidance is temporarily unavailable. You can enter your price manually.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          _showPriceGuidanceSheet(response);
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n?.priceGuidanceUnavailable ??
                                    'Price guidance is temporarily unavailable. You can enter your price manually.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => _isPricingLoading = false);
                        }
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCostField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  void _showPriceGuidanceSheet(PricingApiResponse response) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Confidence label
    String confidenceLabel;
    switch (response.confidence) {
      case 'high':
        confidenceLabel = l10n?.pricingConfidenceStrong ?? 'Strong estimate';
        break;
      case 'medium':
        confidenceLabel = l10n?.pricingConfidenceGood ?? 'Good estimate';
        break;
      default:
        confidenceLabel = l10n?.pricingConfidenceBasic ?? 'Basic estimate';
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.price_check,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.priceGuidanceTitle ?? 'Price Guidance',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            confidenceLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Primary: Suggested Price (prominent)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n?.priceSuggested ?? 'Suggested price',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${response.suggestedPrice.toStringAsFixed(0)}',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary metrics card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      // Market range
                      _buildGuidanceMetricRow(
                        label: l10n?.pricingSimilarItemsRange ?? 'Similar items sell for',
                        value: '₹${response.suggestedPriceLow.toStringAsFixed(0)}'
                            ' – ₹${response.suggestedPriceHigh.toStringAsFixed(0)}',
                        textStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      // Cost to make — only when available
                      if (response.estimatedUnitCost != null) ...[
                        const Divider(height: 16),
                        _buildGuidanceMetricRow(
                          label: l10n?.priceCostToMake ?? 'Cost to make',
                          value: '₹${response.estimatedUnitCost!.toStringAsFixed(0)}',
                          textStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],

                      // Minimum sustainable price — only when available
                      if (response.costFloor != null) ...[
                        const Divider(height: 16),
                        _buildGuidanceMetricRow(
                          label: l10n?.pricingMinSustainable ?? 'Minimum sustainable price',
                          value: '₹${response.costFloor!.toStringAsFixed(0)}',
                          textStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],

                      // Bulk price — only when available
                      if (response.bulkPrice != null) ...[
                        const Divider(height: 16),
                        _buildGuidanceMetricRow(
                          label: l10n?.pricingBulkPrice ?? 'Bulk price',
                          value: '₹${response.bulkPrice!.toStringAsFixed(0)}',
                          textStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Why this price? (reason)
                if (response.reason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.pricingWhyThisPrice ?? 'Why this price?',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                response.reason,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Disclosure
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 15,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n?.priceGuidanceDisclosure ??
                            'Prototype guidance based on sample market data. Final price is your choice.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),

                // Actions
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('cancel_price_guidance_button'),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(l10n?.cancel ?? 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        key: const Key('use_this_price_button'),
                        onPressed: () {
                          final price = response.suggestedPrice;
                          final formattedPrice = price > 0
                              ? (price == price.roundToDouble()
                                  ? price.toInt().toString()
                                  : price.toStringAsFixed(2))
                              : '0';
                          _priceController.text = formattedPrice;
                          _provider.setPriceFromRupeesText(formattedPrice);
                          if (_priceError != null) {
                            setState(() => _priceError = null);
                          }
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(l10n?.useThisPriceButton ?? 'Use This Price'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuidanceMetricRow({
    required String label,
    required String value,
    required TextStyle? textStyle,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isHighlight
              ? textStyle?.copyWith(fontWeight: FontWeight.w700)
              : textStyle,
        ),
        Text(
          value,
          style: isHighlight
              ? textStyle?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                )
              : textStyle?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const Key('add_product_description_field'),
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.descriptionLabel,
            hintText: l10n.descriptionHelper,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (val) {
            _provider.setDescription(val);
          },
        ),
        _buildHindiCatalogCard(colorScheme),
      ],
    );
  }

  Widget _buildHindiCatalogCard(ColorScheme colorScheme) {
    if ((_hindiTitle == null || _hindiTitle!.isEmpty) &&
        (_hindiDescription == null || _hindiDescription!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: ExpansionTile(
        dense: true,
        leading: Icon(Icons.translate, color: colorScheme.primary),
        title: const Text('Hindi SEO content'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (_hindiTitle != null && _hindiTitle!.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _hindiTitle!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          if (_hindiDescription != null && _hindiDescription!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_hindiDescription!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n, ColorScheme colorScheme) {
    final isBusy = _provider.isSaving || _provider.isUploadingImage;

    // For existing active or inactive products: single prominent "Save Changes" button
    if (_provider.isEditMode &&
        _provider.existingStatus != ProductStatus.draft) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          key: const Key('add_product_save_changes_button'),
          onPressed: isBusy ? null : () => _onSaveChanges(l10n),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          child: isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(l10n.saveChangesAction),
        ),
      );
    }

    return Row(
      children: [
        // Save Draft button
        Expanded(
          child: OutlinedButton(
            key: const Key('add_product_save_draft_button'),
            onPressed: isBusy ? null : () => _onSaveDraft(l10n),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            child: _provider.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.saveDraftAction),
          ),
        ),
        const SizedBox(width: 12),

        // Add Product button
        Expanded(
          child: FilledButton(
            key: const Key('add_product_mark_ready_button'),
            onPressed: isBusy ? null : () => _onAddProduct(l10n),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(l10n.addProduct),
          ),
        ),
      ],
    );
  }
}
