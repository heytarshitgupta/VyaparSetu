import 'package:supabase_flutter/supabase_flutter.dart';
import 'producer_product_image_service.dart';
import 'producer_product_service.dart';

/// Result of an AI photo improvement operation.
class EnhancementResult {
  /// The newly created stable Storage path for the improved candidate image.
  /// Formatted as `<auth_uid>/<product_id>/<random_filename>.<ext>`.
  final String improvedStoragePath;

  /// The original source Storage path that was improved.
  final String sourceStoragePath;

  const EnhancementResult({
    required this.improvedStoragePath,
    required this.sourceStoragePath,
  });
}

/// Abstract contract for AI photo enhancement operations.
/// Enables 100% offline, deterministic testing without calling live AI endpoints.
abstract class IProductPhotoEnhancementService {
  /// Requests the AI service to generate a marketplace-ready version of [sourceStoragePath].
  ///
  /// Invariants:
  /// - Does NOT mutate public.products or canonical product.images.
  /// - Stores the enhanced photo as a new immutable object in Storage.
  /// - Returns the new candidate [EnhancementResult].
  Future<EnhancementResult> improvePhoto({
    required String productId,
    required String sourceStoragePath,
  });

  /// Best-effort cleanup of an unused candidate improved image from Storage.
  Future<void> discardCandidateImage(String candidateStoragePath);
}

/// Production implementation calling the Supabase Edge Function `improve-product-photo`.
///
/// Security:
/// - AI API secrets remain isolated strictly on the server (Edge Function).
/// - Client passes only authenticated JWT, productId, and sourceStoragePath.
/// - Edge Function verifies ownership and RLS before processing.
class ProducerProductEnhancementService implements IProductPhotoEnhancementService {
  final SupabaseClient? client;
  final IProducerProductImageService? imageService;

  ProducerProductEnhancementService({
    this.client,
    this.imageService,
  });

  SupabaseClient get _supabaseClient {
    final c = client ?? Supabase.instance.client;
    return c;
  }

  IProducerProductImageService get _imageService {
    return imageService ?? ProducerProductImageService(client: _supabaseClient);
  }

  @override
  Future<EnhancementResult> improvePhoto({
    required String productId,
    required String sourceStoragePath,
  }) async {
    final cleanProductId = productId.trim();
    final cleanSourcePath = sourceStoragePath.trim();

    if (cleanProductId.isEmpty) {
      throw const ProductOperationException('Product ID cannot be empty');
    }
    if (cleanSourcePath.isEmpty) {
      throw const ProductOperationException('Source storage path cannot be empty');
    }

    try {
      final response = await _supabaseClient.functions.invoke(
        'improve-product-photo',
        body: {
          'productId': cleanProductId,
          'sourceStoragePath': cleanSourcePath,
        },
      );

      if (response.status != 200) {
        String errorMessage = 'Failed to improve photo. Please try again.';
        if (response.data is Map && response.data['error'] != null) {
          errorMessage = response.data['error'].toString();
        }
        throw ProductOperationException(errorMessage);
      }

      final data = response.data;
      if (data is! Map) {
        throw const ProductOperationException('Invalid response format from enhancement service');
      }

      final improvedPath = data['improvedStoragePath'] as String?;
      final returnedSourcePath = data['sourceStoragePath'] as String?;

      if (improvedPath == null || improvedPath.trim().isEmpty) {
        throw const ProductOperationException('No improved photo path returned');
      }

      return EnhancementResult(
        improvedStoragePath: improvedPath.trim(),
        sourceStoragePath: returnedSourcePath?.trim() ?? cleanSourcePath,
      );
    } on FunctionException catch (e) {
      String message = 'Photo improvement service is temporarily unavailable. Please try again.';
      if (e.details is Map && e.details['error'] != null) {
        message = e.details['error'].toString();
      }
      throw ProductOperationException(message, e);
    } on ProductOperationException {
      rethrow;
    } catch (e) {
      throw ProductOperationException('Could not connect to photo enhancement service', e);
    }
  }

  @override
  Future<void> discardCandidateImage(String candidateStoragePath) async {
    final cleanPath = candidateStoragePath.trim();
    if (cleanPath.isEmpty) return;

    try {
      await _imageService.deleteProductImage(cleanPath);
    } catch (_) {
      // Best-effort cleanup; failures do not block the user
    }
  }
}
